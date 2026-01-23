# Phase 23: HealthKit Import - Research

**Researched:** 2026-01-22
**Domain:** HealthKit data import, background sync, HKObserverQuery, HKAnchoredObjectQuery
**Confidence:** HIGH

## Summary

This research covers importing weight data from Apple Health into W8Trackr with automatic background sync. The app already has HealthKit export functionality via `HealthSyncManager`, so this phase extends it with read capabilities using anchored queries for incremental updates and observer queries for background delivery.

The standard approach uses:
1. **HKAnchoredObjectQuery** for initial bulk import and incremental foreground updates
2. **HKObserverQuery + enableBackgroundDelivery** for background notifications
3. **HKQueryAnchor persistence** to track sync state and avoid re-importing
4. **HKSource/HKSourceRevision** to identify and display data sources

The key constraint from user decisions is "both sources coexist" - no conflict resolution needed. Health entries are imported alongside manual entries, distinguished by a source indicator.

**Primary recommendation:** Extend `HealthSyncManager` with read operations, add `HKObserverQuery` setup in app launch, and mark imported entries with `source` field set to the Health source name.

## Standard Stack

The established frameworks/APIs for this domain:

### Core
| Framework | Class/API | Purpose | Why Standard |
|-----------|-----------|---------|--------------|
| HealthKit | `HKAnchoredObjectQuery` | Incremental data fetch with anchor | Returns added/deleted samples since last sync |
| HealthKit | `HKAnchoredObjectQueryDescriptor` | Modern Swift concurrency API | Async/await support, cleaner API |
| HealthKit | `HKObserverQuery` | Background delivery notifications | Only way to receive updates when app suspended |
| HealthKit | `enableBackgroundDelivery` | Register for background updates | Required for HKIT-05 automatic sync |
| HealthKit | `HKQueryAnchor` | Track sync position | Enables incremental sync, persists across launches |
| HealthKit | `HKSource`/`HKSourceRevision` | Identify data source | Distinguish manual vs Health entries (HKIT-03) |

### Supporting
| Class | Purpose | When to Use |
|-------|---------|-------------|
| `NSKeyedArchiver`/`NSKeyedUnarchiver` | Persist HKQueryAnchor | Anchor serialization to UserDefaults |
| `HKSampleQuery` | One-time fetch | Initial permission validation, fallback queries |
| `HKSourceQuery` | List data sources | Debug/UI showing where data came from |

### Entitlements Required
| Entitlement | Purpose | Setup |
|-------------|---------|-------|
| `com.apple.developer.healthkit` | Basic HealthKit access | Already configured for export |
| `com.apple.developer.healthkit.background-delivery` | Background observer updates | NEW - must add for HKIT-05 |

**Info.plist Addition:**
```xml
<key>NSHealthShareUsageDescription</key>
<string>W8Trackr reads your weight data from Apple Health to keep all your measurements in one place.</string>
```

## Architecture Patterns

### Recommended Project Structure
```
W8Trackr/
├── Managers/
│   ├── HealthSyncManager.swift     # Extend with import operations
│   ├── HealthStoreProtocol.swift   # Add query protocol methods
│   └── HealthImportService.swift   # NEW: Dedicated import logic (optional)
├── Models/
│   └── WeightEntry.swift           # Already has source field
└── W8TrackrApp.swift               # Add background delivery setup
```

### Pattern 1: Anchored Query for Incremental Import
**What:** Use HKAnchoredObjectQuery to fetch only new/changed data since last sync
**When to use:** Initial import and foreground app launches
**Example:**
```swift
// Source: Apple Developer Documentation, DevFright tutorials
func importWeightFromHealth() async throws -> [HKQuantitySample] {
    guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
        return []
    }

    let descriptor = HKAnchoredObjectQueryDescriptor(
        predicates: [.quantitySample(type: weightType)],
        anchor: loadAnchor()  // nil on first run
    )

    let result = try await descriptor.result(for: healthStore)

    // Persist anchor for next incremental sync
    saveAnchor(result.newAnchor)

    // Process added samples (creates WeightEntry for each)
    // Handle deleted samples (remove if imported entry still exists)
    return result.addedSamples.compactMap { $0 as? HKQuantitySample }
}
```

### Pattern 2: Background Delivery with Observer Query
**What:** Register for HealthKit updates to sync automatically when app suspended
**When to use:** HKIT-05 requirement - sync without user action
**Example:**
```swift
// Source: Apple Developer Documentation, GitHub gists
// Must be called in application:didFinishLaunchingWithOptions or early in app lifecycle
func setupBackgroundDelivery() {
    guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }

    // 1. Create observer query (notifies of changes)
    let observerQuery = HKObserverQuery(
        sampleType: weightType,
        predicate: nil
    ) { [weak self] _, completionHandler, error in
        defer {
            // CRITICAL: Always call completion handler
            completionHandler()
        }

        guard error == nil else { return }

        // 2. Run anchored query to get actual changes
        Task { @MainActor in
            try? await self?.importWeightFromHealth()
        }
    }

    healthStore.execute(observerQuery)

    // 3. Enable background delivery
    healthStore.enableBackgroundDelivery(
        for: weightType,
        frequency: .immediate
    ) { success, error in
        if let error = error {
            print("Background delivery failed: \(error)")
        }
    }
}
```

### Pattern 3: Anchor Persistence
**What:** Store HKQueryAnchor to UserDefaults for incremental sync across app launches
**When to use:** Always - avoids re-importing all data on every launch
**Example:**
```swift
// Source: DevFright, Apple Developer Forums
private static let anchorKey = "healthKitImportAnchor"

func saveAnchor(_ anchor: HKQueryAnchor?) {
    guard let anchor = anchor else { return }
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: anchor,
            requiringSecureCoding: true
        )
        SharedModelContainer.sharedDefaults?.set(data, forKey: Self.anchorKey)
    } catch {
        print("Failed to archive anchor: \(error)")
    }
}

func loadAnchor() -> HKQueryAnchor? {
    guard let data = SharedModelContainer.sharedDefaults?.data(forKey: Self.anchorKey) else {
        return nil
    }
    do {
        return try NSKeyedUnarchiver.unarchivedObject(
            ofClass: HKQueryAnchor.self,
            from: data
        )
    } catch {
        return nil
    }
}
```

### Pattern 4: Source Identification for Imported Entries
**What:** Set WeightEntry.source to the HealthKit source name
**When to use:** HKIT-03 requirement - distinguish manual vs Health entries
**Example:**
```swift
// Source: Apple Developer Documentation HKSource
func createEntryFromSample(_ sample: HKQuantitySample) -> WeightEntry {
    let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
    let weightInLb = weightInKg * WeightUnit.kgToLb

    let entry = WeightEntry(weight: weightInLb, date: sample.startDate)

    // Set source from HealthKit sample
    // sourceRevision.source.name gives human-readable name like "Withings Scale"
    entry.source = sample.sourceRevision.source.name
    entry.healthKitUUID = sample.uuid.uuidString
    entry.pendingHealthSync = false  // Already in Health

    return entry
}
```

### Anti-Patterns to Avoid
- **Re-querying all data on every launch:** Always use anchored queries with persisted anchor
- **Ignoring observer query completion handler:** Causes exponential backoff and eventual delivery halt
- **Checking read authorization status:** HealthKit intentionally hides read permissions for privacy
- **Assuming synchronous background delivery:** Background updates are best-effort, not guaranteed
- **Using HKSampleQuery for ongoing sync:** Use anchored queries instead for incremental updates
- **Sharing anchors between data types:** Each HKSampleType needs its own anchor

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Incremental sync | Custom timestamp tracking | HKAnchoredObjectQuery + HKQueryAnchor | HealthKit handles deletions, merges, edge cases |
| Background updates | Timer-based polling | HKObserverQuery + enableBackgroundDelivery | Only Apple-sanctioned way, respects system resources |
| Anchor serialization | Custom encoding | NSKeyedArchiver (HKQueryAnchor: NSSecureCoding) | Built-in conformance, forward-compatible |
| Duplicate detection | Date/value comparison | HKSample.uuid + WeightEntry.healthKitUUID | Apple's UUIDs are globally unique |
| Source identification | Bundle ID parsing | HKSource.name property | Human-readable, handles all source types |

**Key insight:** HealthKit's anchored query system handles the complexity of tracking what changed since last sync, including deletions and updates. Rolling your own timestamp-based sync will miss edge cases.

## Common Pitfalls

### Pitfall 1: Not Calling Observer Query Completion Handler
**What goes wrong:** HealthKit uses exponential backoff. After 3 failures, background delivery stops entirely.
**Why it happens:** Error handling paths skip the completion call, or async operations don't await properly.
**How to avoid:** Use `defer { completionHandler() }` at the start of the handler.
**Warning signs:** Background sync works initially, then stops after a few days.

### Pitfall 2: Misunderstanding Read Authorization Status
**What goes wrong:** App shows "no permission" when user actually denied read access, confusing them.
**Why it happens:** HealthKit intentionally returns `notDetermined` for read permissions to protect privacy.
**How to avoid:** Never try to detect read authorization. If query returns no data, treat it as "no data available."
**Warning signs:** UI shows "no Health data" when user intentionally denied access (this is correct behavior).

### Pitfall 3: Blocking App Launch on HealthKit Queries
**What goes wrong:** App takes too long to launch, especially on first import with years of data.
**Why it happens:** Running initial import synchronously in app launch path.
**How to avoid:** Run import in background Task, show placeholder UI immediately.
**Warning signs:** Launch time exceeds 10 seconds with large Health databases.

### Pitfall 4: Background Delivery Entitlement Missing
**What goes wrong:** Observer queries work in foreground but never fire in background.
**Why it happens:** Forgot to add `com.apple.developer.healthkit.background-delivery` entitlement.
**How to avoid:** Add entitlement in Xcode Signing & Capabilities.
**Warning signs:** HKIT-05 test fails (background sync doesn't work).

### Pitfall 5: Re-importing Duplicates
**What goes wrong:** Same Health entry imported multiple times, cluttering the logbook.
**Why it happens:** Anchor not persisted, or using wrong query type.
**How to avoid:** Always persist anchor to UserDefaults, use anchored queries not sample queries.
**Warning signs:** Duplicate entries in logbook after app restart.

### Pitfall 6: Assuming Immediate Background Delivery
**What goes wrong:** Tests expect instant sync, but updates arrive hours later.
**Why it happens:** `HKUpdateFrequency.immediate` means "as soon as possible," not "instantly." Some types are limited to hourly.
**How to avoid:** Design UI/tests to handle delayed updates gracefully.
**Warning signs:** Flaky integration tests that depend on timing.

## Code Examples

Verified patterns from official sources and established tutorials:

### Initial Bulk Import (First Permission Grant - HKIT-04)
```swift
// Source: Apple Developer Documentation, DevFright
func performInitialImport(modelContext: ModelContext) async throws {
    guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
        return
    }

    // No anchor = fetch all historical data
    let descriptor = HKAnchoredObjectQueryDescriptor(
        predicates: [.quantitySample(type: weightType)],
        anchor: nil
    )

    let result = try await descriptor.result(for: healthStore)

    // Save anchor for incremental sync
    saveAnchor(result.newAnchor)

    // Import samples as WeightEntry
    for sample in result.addedSamples {
        guard let quantitySample = sample as? HKQuantitySample else { continue }

        // Skip if we already have this entry (by healthKitUUID)
        let existingEntries = try modelContext.fetch(
            FetchDescriptor<WeightEntry>(
                predicate: #Predicate { $0.healthKitUUID == quantitySample.uuid.uuidString }
            )
        )
        guard existingEntries.isEmpty else { continue }

        let entry = createEntryFromSample(quantitySample)
        modelContext.insert(entry)
    }

    try modelContext.save()
    lastHealthSyncDate = Date()
}
```

### Background Delivery Setup (App Launch)
```swift
// Source: Apple Developer Documentation, Medium articles
// Called from W8TrackrApp.init() or body's task modifier
func setupHealthKitBackgroundDelivery() {
    guard HealthSyncManager.isHealthDataAvailable,
          isHealthSyncEnabled,
          let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
        return
    }

    let query = HKObserverQuery(
        sampleType: weightType,
        predicate: nil
    ) { [weak self] _, completionHandler, error in
        defer { completionHandler() }

        guard error == nil else { return }

        Task { @MainActor in
            do {
                try await self?.syncIncrementalChanges()
            } catch {
                print("Background sync failed: \(error)")
            }
        }
    }

    healthStore.execute(query)

    healthStore.enableBackgroundDelivery(
        for: weightType,
        frequency: .immediate
    ) { success, error in
        if !success, let error = error {
            print("enableBackgroundDelivery failed: \(error)")
        }
    }
}
```

### Authorization Request (Extended for Read - HKIT-01)
```swift
// Source: Existing HealthSyncManager.swift pattern, extended
func requestImportAuthorization() async throws -> Bool {
    guard Self.isHealthDataAvailable,
          let weightType = weightType else {
        return false
    }

    // Request both read AND write permissions
    let typesToShare: Set<HKSampleType> = [weightType]
    let typesToRead: Set<HKObjectType> = [weightType]

    let success = try await healthStore.requestAuthorization(
        toShare: typesToShare,
        read: typesToRead
    )

    // Note: We cannot check read permission status
    // success only means dialog was shown, not permission granted
    checkAuthorizationStatus()  // Updates write status

    return success
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| HKAnchoredObjectQuery (callback) | HKAnchoredObjectQueryDescriptor (async) | iOS 15.4 | Cleaner Swift concurrency, AsyncSequence support |
| Manual background refresh | enableBackgroundDelivery + entitlement | iOS 15 | Required entitlement for background observer queries |
| HKSource | HKSourceRevision | iOS 9 | Additional version/OS info available |
| Manual duplicate checking | Sync identifier metadata | iOS 10 | HKMetadataKeySyncIdentifier for conflict resolution |

**Deprecated/outdated:**
- `HKAnchoredObjectQuery` init without descriptor is legacy but still works
- Background delivery without entitlement no longer works as of iOS 15

## Open Questions

Things that couldn't be fully resolved:

1. **Exact background delivery timing for weight samples**
   - What we know: `.immediate` frequency works for some sample types
   - What's unclear: Apple doesn't document per-type frequency limits
   - Recommendation: Use `.immediate`, accept delays gracefully, document behavior to users

2. **SwiftData transaction boundaries for bulk import**
   - What we know: ModelContext.save() works for moderate batch sizes
   - What's unclear: Performance with 1000+ entries in single transaction
   - Recommendation: Test with large datasets, consider batching if needed

3. **watchOS 26 HKObserverQuery issues**
   - What we know: Some reports of background delivery stopping on watchOS 26
   - What's unclear: Whether iOS 26 is affected
   - Recommendation: Not blocking (app is iOS-only), but monitor Apple forums

## Sources

### Primary (HIGH confidence)
- [Apple Developer: HKObserverQuery](https://developer.apple.com/documentation/healthkit/hkobserverquery) - observer query fundamentals
- [Apple Developer: enableBackgroundDelivery](https://developer.apple.com/documentation/healthkit/hkhealthstore/enablebackgrounddelivery(for:frequency:withcompletion:)) - background delivery API
- [Apple Developer: com.apple.developer.healthkit.background-delivery](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.healthkit.background-delivery) - required entitlement
- [Apple Developer: HKAnchoredObjectQueryDescriptor](https://developer.apple.com/documentation/healthkit/hkanchoredobjectquerydescriptor) - modern async API
- [Apple Developer: HKSource](https://developer.apple.com/documentation/healthkit/hksource) - source identification

### Secondary (MEDIUM confidence)
- [DevFright: How to Use HealthKit HKAnchoredObjectQuery](https://www.devfright.com/how-to-use-healthkit-hkanchoredobjectquery/) - anchor persistence patterns
- [iTwenty: Read workouts using HealthKit](https://itwenty.me/posts/09-healthkit-workout-updates/) - comprehensive query patterns
- [Medium: Mastering HealthKit Common Pitfalls](https://medium.com/mobilepeople/mastering-healthkit-common-pitfalls-and-solutions-b4f46729f28e) - pitfall documentation
- [GitHub: HKObserverQuery background delivery example](https://gist.github.com/phatblat/654ab2b3a135edf905f4a854fdb2d7c8) - working implementation

### Tertiary (LOW confidence)
- [Apple Developer Forums: watchOS 26 HKObserverQuery issues](https://developer.apple.com/forums/thread/801627) - potential iOS 26 issues to monitor

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Apple's official HealthKit APIs, well-documented
- Architecture: HIGH - Patterns verified across multiple authoritative sources
- Pitfalls: HIGH - Common issues documented in Apple forums and community tutorials

**Research date:** 2026-01-22
**Valid until:** 2026-02-22 (30 days - stable Apple framework, minor watchOS concerns)
