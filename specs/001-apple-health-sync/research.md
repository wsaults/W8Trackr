# Research: Apple Health Integration

**Feature**: 001-apple-health-sync
**Date**: 2025-01-09
**Status**: Complete

## Research Questions Resolved

### 1. Authorization Pattern

**Decision**: Request authorization in Settings when user enables Health sync toggle

**Rationale**:
- Contextual permission requests have higher acceptance rates
- User understands why access is needed when they're actively enabling the feature
- Follows Apple HIG for just-in-time permission requests

**Alternatives Considered**:
- App launch: Rejected - users haven't expressed intent for health features
- First weight entry: Rejected - disruptive to primary workflow

**Implementation Notes**:
- Use `HKHealthStore.requestAuthorization(toShare:read:)` with async/await
- The completion boolean only indicates user responded, not whether granted
- Cannot distinguish "denied" from "not asked" for read permissions (privacy)
- Required Info.plist keys: `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`

### 2. Writing Weight Data

**Decision**: Use `HKQuantitySample` with sync metadata for deduplication

**Rationale**:
- `HKMetadataKeySyncIdentifier` and `HKMetadataKeySyncVersion` provide native dedup
- HealthKit automatically prevents duplicates with same sync ID
- Version number enables conflict resolution (higher version wins)

**Code Pattern**:
```swift
let metadata: [String: Any] = [
    HKMetadataKeySyncIdentifier: "w8trackr-\(entry.id)",  // Stable ID from SwiftData
    HKMetadataKeySyncVersion: entry.syncVersion          // Increment on each update
]

let sample = HKQuantitySample(
    type: HKQuantityType(.bodyMass),
    quantity: HKQuantity(unit: .pound(), doubleValue: weight),
    start: date,
    end: date,
    metadata: metadata
)
```

### 3. Reading Weight Data

**Decision**: Use `HKAnchoredObjectQuery` for incremental sync with persistent anchor

**Rationale**:
- Returns only changes since last sync (efficient for ongoing sync)
- Includes deletions (required for bidirectional sync)
- Anchor can be persisted in UserDefaults for cross-session continuity

**Alternatives Considered**:
- `HKSampleQuery`: Rejected - fetches all data every time, no deletion tracking
- `HKStatisticsQuery`: Rejected - aggregates only, not individual samples

**Implementation Notes**:
- Store `HKQueryAnchor` encoded as Data in UserDefaults
- On first run, anchor is nil → fetches all historical data
- Subsequent runs only fetch changes since last anchor

### 4. Background Sync

**Decision**: Use `HKObserverQuery` for external change detection, foreground sync on app open

**Rationale**:
- `HKObserverQuery` notifies when data changes from external sources
- Background delivery requires entitlement and has reliability limitations
- App foregrounding is reliable trigger for catch-up sync

**Limitations Documented**:
- Observer callbacks may not fire when app is force-quit
- Background budget shared with other tasks
- Must always call completion handler in observer callback

**Required Setup**:
1. Add entitlement: `com.apple.developer.healthkit.background-delivery`
2. Call `enableBackgroundDelivery(for:frequency:)` at app launch
3. Setup observer query that triggers `HKAnchoredObjectQuery`

### 5. Unit Handling

**Decision**: Store in original unit locally, convert at HealthKit boundary

**Rationale**:
- Matches existing WeightEntry pattern (stores unit with value)
- HealthKit handles conversion transparently via `HKQuantity.doubleValue(for:)`
- No loss of precision from double-conversion

**Conversion Pattern**:
```swift
// Writing: use user's preferred unit
let quantity = HKQuantity(unit: userPreferredUnit == .lb ? .pound() : .gramUnit(with: .kilo),
                          doubleValue: weightValue)

// Reading: convert to user's preferred unit
let weightInPreferredUnit = sample.quantity.doubleValue(for: preferredHKUnit)
```

### 6. Conflict Resolution

**Decision**: Most recently modified wins, using sync version numbers

**Rationale**:
- Matches spec requirement (FR-011)
- HealthKit's native sync version mechanism handles this automatically
- No need for custom conflict detection logic

**Algorithm**:
1. Each WeightEntry gets a `syncVersion` field (starts at 1)
2. Every edit increments `syncVersion` and updates `modifiedDate`
3. When saving to HealthKit, include version in metadata
4. HealthKit only accepts if version is higher than existing

**Edge Cases**:
- Same timestamp, different values: Higher sync version wins
- Deleted in one source: Deletion propagates (HKAnchoredObjectQuery tracks deletions)

### 7. Testing Strategy

**Decision**: Protocol-based dependency injection for HealthKit mocking

**Rationale**:
- HealthKit cannot be directly mocked in unit tests
- Protocol abstraction allows substituting mock implementation
- Simulator has limited HealthKit functionality

**Test Categories**:

| Category | Approach | Coverage |
|----------|----------|----------|
| Unit tests | Mock `HealthStoreProtocol` | Sync logic, conflict resolution, unit conversion |
| Integration tests | Real HealthKit on device | Permission flow, actual read/write |

*Note: UI tests (XCUITest) are prohibited per constitution. Manual device testing validates UI flows.*

**Protocol Design**:
```swift
protocol HealthStoreProtocol {
    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws -> Bool
    func save(_ sample: HKSample) async throws
    func execute(_ query: HKQuery)
}

extension HKHealthStore: HealthStoreProtocol { /* async wrappers */ }
```

## Technical Decisions Summary

| Decision Area | Choice | Constitution Alignment |
|---------------|--------|----------------------|
| Manager pattern | Single `HealthSyncManager` ObservableObject | ✅ Matches NotificationManager pattern |
| Storage extension | Add fields to existing WeightEntry | ✅ No new models needed |
| Sync identifier | Use SwiftData persistent ID | ✅ Simple, no UUID generation |
| Background delivery | Enable but rely on foreground for reliability | ✅ YAGNI - simple first |
| Testing | Protocol injection with mocks | ✅ TDD enabled |

## Dependencies

- **HealthKit.framework**: Native iOS framework, no external dependencies
- **XCTHealthKit** (dev only): Optional, for UI test health data injection

## References

- [Apple: Authorizing access to health data](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- [Apple: HKAnchoredObjectQuery](https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery)
- [Apple: HKMetadataKeySyncIdentifier](https://developer.apple.com/documentation/healthkit/hkmetadatakeysyncidentifier)
- [WWDC20: Synchronize health data with HealthKit](https://developer.apple.com/videos/play/wwdc2020/10184/)
