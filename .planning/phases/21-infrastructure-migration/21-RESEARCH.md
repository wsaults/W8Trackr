# Phase 21: Infrastructure & Migration - Research

**Researched:** 2026-01-22
**Domain:** SwiftData App Group migration with CloudKit sync
**Confidence:** MEDIUM

## Summary

This phase involves migrating an existing SwiftData store to an App Group container to enable widget data sharing, while preserving CloudKit sync integrity. The research reveals that SwiftData has built-in automatic migration capabilities when App Groups are added, but the CloudKit integration adds significant complexity that requires careful handling.

The key finding is that SwiftData will automatically copy existing data to the App Group container when the entitlement is added and the app launches. However, for apps with CloudKit sync enabled, the migration approach must use `replacePersistentStore` instead of `migratePersistentStore` to avoid data duplication. The migration must run before `loadPersistentStores` completes.

For the HealthKit settings link (INFRA-03), there is no public API to deep-link directly to the Health app's Sources/permissions page. The best available option is `prefs:root=Privacy&path=HEALTH` which opens the Privacy Health settings, or `x-apple-health://` which opens the Health app itself.

**Primary recommendation:** Implement a manual migration check at app launch that uses `replacePersistentStore` before initializing the SwiftData ModelContainer, with CloudKit sync temporarily disabled during migration.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 26+ | Data persistence | Native Apple framework with App Group support |
| FileManager | Foundation | Migration file operations | Required for checking/moving store files |
| ModelConfiguration | SwiftData | App Group configuration | `groupContainer` parameter enables shared access |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| WidgetKit | iOS 26+ | Widget timeline reload | Call after migration completes |
| UserDefaults | Foundation | Shared preferences | App Group suite for widget preferences |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual migration | SwiftData automatic copy | Automatic is simpler but less controllable for CloudKit apps |
| `prefs:root=Privacy&path=HEALTH` | `x-apple-health://` | Privacy settings shows permissions; Health app shows data |

**Installation:**
No additional dependencies required - all frameworks are built into iOS.

## Architecture Patterns

### Recommended Project Structure
```
W8Trackr/
├── Shared/
│   └── SharedModelContainer.swift   # Shared container config (both targets)
├── Managers/
│   └── MigrationManager.swift       # Migration logic (main app only)
├── W8TrackrApp.swift                # Migration check at launch
└── W8TrackrWidget/
    └── W8TrackrWidget.swift         # Uses SharedModelContainer
```

### Pattern 1: Shared ModelContainer Configuration
**What:** A single source of truth for ModelContainer setup shared between app and widget
**When to use:** Always, for App Group data sharing

**Example:**
```swift
// Source: Official SwiftData patterns + Hacking with Swift
import SwiftData

enum SharedModelContainer {
    static let appGroupIdentifier = "group.com.saults.W8Trackr"

    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([WeightEntry.self, CompletedMilestone.self])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()

    static let sharedDefaults: UserDefaults? = {
        UserDefaults(suiteName: appGroupIdentifier)
    }()
}
```

### Pattern 2: Pre-Launch Migration Check (CloudKit-Safe)
**What:** Check for and perform migration before SwiftData initialization
**When to use:** When migrating existing CloudKit-synced data to App Group

**Example:**
```swift
// Source: Apple Developer Forums + polpiella.dev
// CRITICAL: Run BEFORE creating ModelContainer
func migrateToAppGroupIfNeeded() -> Bool {
    let fileManager = FileManager.default

    // Old store location (default SwiftData location)
    let oldStoreURL = URL.applicationSupportDirectory
        .appendingPathComponent("default.store")

    // New App Group location
    guard let appGroupURL = fileManager.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.saults.W8Trackr"
    )?.appendingPathComponent("default.store") else {
        return false
    }

    // Check if migration needed
    guard fileManager.fileExists(atPath: oldStoreURL.path),
          !fileManager.fileExists(atPath: appGroupURL.path) else {
        return true // Already migrated or fresh install
    }

    // Perform migration using replacePersistentStore (not migratePersistentStore!)
    // This preserves CloudKit record metadata and prevents duplicates
    do {
        let container = NSPersistentContainer(name: "default")

        // Temporarily disable CloudKit during migration
        let description = NSPersistentStoreDescription(url: oldStoreURL)
        description.cloudKitContainerOptions = nil // CRITICAL
        container.persistentStoreDescriptions = [description]

        try container.persistentStoreCoordinator.replacePersistentStore(
            at: appGroupURL,
            withPersistentStoreFrom: oldStoreURL,
            type: .sqlite
        )

        return true
    } catch {
        print("Migration failed: \(error)")
        return false
    }
}
```

### Pattern 3: Migration Verification
**What:** Verify data integrity after migration before deleting old store
**When to use:** Per CONTEXT.md - atomic migration with verification

**Example:**
```swift
// Source: Community best practices
func verifyMigration(oldURL: URL, newURL: URL) -> Bool {
    // Count records in both stores
    let oldCount = countRecords(at: oldURL)
    let newCount = countRecords(at: newURL)

    // Verification passes if counts match
    return oldCount == newCount && newCount > 0
}

private func countRecords(at url: URL) -> Int {
    // Use FetchDescriptor to count without loading full objects
    // Implementation depends on accessing store directly
}
```

### Anti-Patterns to Avoid
- **Using `migratePersistentStore` with CloudKit:** Causes data duplication because CloudKit sees migrated records as new
- **Migrating after `loadPersistentStores`:** CloudKit sync may start before migration, causing duplicates
- **Moving only .sqlite file:** Must handle .sqlite-wal and .sqlite-shm files together (WAL journaling)
- **Deleting old store immediately:** Verify migration success first; keep backup briefly

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Store migration | Custom file copy | `replacePersistentStore` | Handles WAL files, preserves CloudKit metadata |
| App Group detection | Manual path building | `groupContainer: .identifier()` | SwiftData auto-detects properly |
| Widget data sharing | Separate database | Shared ModelContainer | Keeps single source of truth |
| CloudKit metadata | Custom sync tracking | SwiftData's built-in | Framework handles record zone/metadata |

**Key insight:** The migration APIs exist specifically because manual file operations lose critical metadata that CloudKit needs to avoid duplicating records.

## Common Pitfalls

### Pitfall 1: Data Duplication After Migration
**What goes wrong:** All records appear twice after migration
**Why it happens:** Using `migratePersistentStore` instead of `replacePersistentStore` strips CloudKit metadata
**How to avoid:** Always use `replacePersistentStore` for CloudKit-backed stores
**Warning signs:** Double entries appearing after app update

### Pitfall 2: Migration Freeze with iCloud Disabled
**What goes wrong:** App hangs at launch for users with iCloud disabled
**Why it happens:** CloudKit tries to connect during migration, blocks indefinitely
**How to avoid:** Set `cloudKitContainerOptions = nil` during migration
**Warning signs:** Timeout reports from users without iCloud

### Pitfall 3: WAL File Data Loss
**What goes wrong:** Recent data missing after migration
**Why it happens:** Only moving .sqlite file, ignoring .sqlite-wal and .sqlite-shm
**How to avoid:** Use `replacePersistentStore` which handles all files atomically
**Warning signs:** Missing entries from last session before update

### Pitfall 4: Widget Showing Stale Data
**What goes wrong:** Widget shows old/empty data after migration
**Why it happens:** Widget timeline not reloaded after migration completes
**How to avoid:** Call `WidgetCenter.shared.reloadAllTimelines()` after migration
**Warning signs:** Widget stuck on "Open app to complete setup"

### Pitfall 5: HealthKit Settings Opens Wrong Location
**What goes wrong:** User taps "Open Settings" but lands in app settings, not Health permissions
**Why it happens:** Using `UIApplication.openSettingsURLString` instead of Health-specific URL
**How to avoid:** Use `prefs:root=Privacy&path=HEALTH` for privacy settings
**Warning signs:** Users confused about where to change Health permissions

## Code Examples

### App Group Entitlement Configuration
```xml
<!-- W8Trackr.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.saults.W8Trackr</string>
    </array>
</dict>
</plist>
```

### ModelContainer with App Group (SwiftData Native)
```swift
// Source: Hacking with Swift / Apple Documentation
// For fresh installations, SwiftData automatically uses App Group
@main
struct W8TrackrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WeightEntry.self, CompletedMilestone.self],
                       inMemory: false,
                       isAutosaveEnabled: true,
                       isUndoEnabled: false)
    }
}

// SwiftData automatically detects App Group entitlement and uses it
```

### Explicit App Group Configuration (for widget sharing)
```swift
// Source: Apple Developer Forums patterns
import SwiftData

func createSharedContainer() throws -> ModelContainer {
    let schema = Schema([WeightEntry.self, CompletedMilestone.self])

    let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        groupContainer: .identifier("group.com.saults.W8Trackr"),
        cloudKitDatabase: .automatic
    )

    return try ModelContainer(for: schema, configurations: [configuration])
}
```

### Opening Health Privacy Settings
```swift
// Source: iOS Settings URL Schemes documentation
func openHealthPrivacySettings() {
    // Opens Settings > Privacy & Security > Health
    // This is where users manage app permissions for Health data
    if let url = URL(string: "App-prefs:Privacy&path=HEALTH") {
        UIApplication.shared.open(url)
    }
}

// Alternative: Open Health app directly
func openHealthApp() {
    if let url = URL(string: "x-apple-health://") {
        UIApplication.shared.open(url)
    }
}
```

### User Defaults Migration to Shared Container
```swift
// Source: SharedModelContainer contract (existing in codebase)
func migratePreferencesToSharedDefaults() {
    guard let shared = UserDefaults(suiteName: "group.com.saults.W8Trackr") else { return }
    let standard = UserDefaults.standard

    // Only migrate if shared is empty (first run after update)
    guard shared.string(forKey: "preferredWeightUnit") == nil else { return }

    // Migrate preferences
    if let unit = standard.string(forKey: "preferredWeightUnit") {
        shared.set(unit, forKey: "preferredWeightUnit")
    }
    if standard.object(forKey: "goalWeight") != nil {
        shared.set(standard.double(forKey: "goalWeight"), forKey: "goalWeight")
    }
}
```

### Migration Status Tracking
```swift
// Source: CONTEXT.md decisions
enum MigrationStatus {
    case notStarted
    case inProgress
    case completed
    case failed(Error)
}

@MainActor
@Observable
class MigrationManager {
    var status: MigrationStatus = .notStarted

    func performMigrationIfNeeded() async {
        // Check if migration needed
        guard needsMigration() else {
            status = .completed
            return
        }

        status = .inProgress

        do {
            try await performMigration()
            status = .completed

            // Notify widgets
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            status = .failed(error)
            // Per CONTEXT.md: Do NOT retry automatically
            // User must manually trigger retry
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `migratePersistentStore` | `replacePersistentStore` | CloudKit integration | Prevents data duplication |
| Manual file copy | SwiftData auto-migration | iOS 17+ | Simpler for non-CloudKit apps |
| `UIApplication.openSettingsURLString` | `prefs:root=Privacy&path=HEALTH` | iOS 10+ | Opens correct settings location |

**Deprecated/outdated:**
- **NSPersistentContainer without groupContainer**: Use SwiftData's `groupContainer` parameter
- **Manual WAL file handling**: Let `replacePersistentStore` handle atomicity

## Open Questions

1. **SwiftData Automatic Migration with CloudKit**
   - What we know: SwiftData auto-copies data to App Group on first launch
   - What's unclear: Whether this automatic copy preserves CloudKit metadata like `replacePersistentStore` does
   - Recommendation: Test on device with CloudKit before release; may need manual migration even with SwiftData

2. **`prefs:root` URL Scheme Reliability**
   - What we know: `prefs:root=Privacy&path=HEALTH` documented in community sources
   - What's unclear: Whether Apple considers this private API; stability across iOS versions
   - Recommendation: Wrap in `canOpenURL` check; provide fallback to `UIApplication.openSettingsURLString`

3. **Verification Record Count During Migration**
   - What we know: Count comparison is common verification approach
   - What's unclear: How to count records in SwiftData store before ModelContainer initialization
   - Recommendation: Could use NSPersistentContainer for pre-migration count, or verify post-migration by comparing with pre-stored count

## Sources

### Primary (HIGH confidence)
- [Hacking with Swift - SwiftData Widgets](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets) - App Group setup, automatic migration
- [polpiella.dev - Core Data App Group Migration](https://www.polpiella.dev/core-data-migration-app-group) - `replacePersistentStore` pattern, code examples
- [Apple Developer Forums - NSPersistentCloudKitContainer Duplication](https://developer.apple.com/forums/thread/653975) - CloudKit duplication root cause

### Secondary (MEDIUM confidence)
- [towa.co - App Group CloudKit Migration](https://towa.co/articles/2021.08.06-core-data-migrate-to-or-from-an-app-group-and-data-duplication-with-cloudkit.html) - Migration timing with CloudKit
- [iOS Settings URL Schemes](https://github.com/FifiTheBulldog/ios-settings-urls/blob/master/settings-urls.md) - `prefs:root=HEALTH` URLs
- [Apple Developer Forums - Health App URL](https://developer.apple.com/forums/thread/103147) - Health app deep linking limitations

### Tertiary (LOW confidence)
- Various blog posts on SwiftData automatic migration - Needs device testing verification
- `App-prefs:` URL schemes - Undocumented, may change between iOS versions

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - SwiftData/ModelConfiguration APIs are well-documented
- Architecture: MEDIUM - Migration pattern established for Core Data, SwiftData specifics need testing
- Pitfalls: HIGH - CloudKit duplication issue well-documented across multiple sources
- Health settings URL: MEDIUM - Community-documented but not officially supported

**Research date:** 2026-01-22
**Valid until:** 60 days (stable Apple frameworks, but test on iOS 26 beta)
