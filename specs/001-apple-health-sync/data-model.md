# Data Model: Apple Health Integration

**Feature**: 001-apple-health-sync
**Date**: 2025-01-09

## Entity Changes

### WeightEntry (Extended)

The existing `WeightEntry` SwiftData model is extended with sync-related fields. No new models are required.

**Existing Fields** (unchanged):
| Field | Type | Description |
|-------|------|-------------|
| `weightValue` | `Double` | Weight in original unit |
| `weightUnit` | `String` | Unit at time of entry ("lb" or "kg") |
| `date` | `Date` | Entry timestamp |
| `note` | `String?` | User's optional note |
| `bodyFatPercentage` | `Decimal?` | Optional body fat % |
| `modifiedDate` | `Date?` | Last edit timestamp |

**New Fields** (for sync):
| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `healthKitUUID` | `String?` | `nil` | HealthKit sample UUID for correlation |
| `source` | `String` | `"W8Trackr"` | Entry origin: "W8Trackr", "Apple Health", or external app name |
| `syncVersion` | `Int` | `1` | Incremented on each update for conflict resolution |
| `pendingHealthSync` | `Bool` | `false` | True if export to HealthKit is queued |

**Computed Properties**:
```swift
var isImported: Bool { source != "W8Trackr" }
var needsSync: Bool { pendingHealthSync }
```

### Migration Notes

- **Non-destructive**: All new fields have defaults, no data loss
- **Existing entries**: `source = "W8Trackr"`, `syncVersion = 1`, `healthKitUUID = nil`
- **Lightweight migration**: SwiftData handles automatically

## State Management

### HealthSyncState (UserDefaults-backed)

Sync preferences and state stored in UserDefaults (not SwiftData) to match existing pattern for `goalWeight`, `preferredWeightUnit`, etc.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `healthSyncEnabled` | `Bool` | `false` | User's sync preference |
| `healthSyncAnchor` | `Data?` | `nil` | Encoded `HKQueryAnchor` for incremental sync |
| `lastHealthSyncDate` | `Date?` | `nil` | Timestamp of last successful sync |
| `pendingExportCount` | `Int` | `0` | Entries queued for export (offline support) |

**Access via `@AppStorage`**:
```swift
@AppStorage("healthSyncEnabled") var healthSyncEnabled = false
```

## Relationships

```
┌─────────────────┐
│   WeightEntry   │
├─────────────────┤      correlates via
│ healthKitUUID ──┼───────────────────────► HKQuantitySample.uuid
│ source          │                         (in Apple Health)
│ syncVersion     │
└─────────────────┘
```

## Validation Rules

### WeightEntry Sync Fields

| Field | Rule | Error |
|-------|------|-------|
| `healthKitUUID` | Must be valid UUID string if non-nil | Invalid sync state |
| `source` | Non-empty string | Required field |
| `syncVersion` | ≥ 1 | Invalid version |
| `pendingHealthSync` | Must be false if sync disabled | Inconsistent state |

### State Invariants

1. If `healthSyncEnabled = false`, all `pendingHealthSync` must be false
2. If `healthKitUUID` is set, entry has been synced to Health at least once
3. `syncVersion` increments monotonically (never decreases)

## Source Attribution Values

| Value | Meaning | Display |
|-------|---------|---------|
| `"W8Trackr"` | Created in this app | No badge |
| `"Apple Health"` | Imported from Health (unknown source) | Health badge |
| `"<App Name>"` | Imported from Health with source bundle ID resolved | App-specific badge |

## Query Patterns

### Entries Pending Export
```swift
#Predicate<WeightEntry> { $0.pendingHealthSync == true }
```

### Imported Entries Only
```swift
#Predicate<WeightEntry> { $0.source != "W8Trackr" }
```

### Find by HealthKit UUID
```swift
#Predicate<WeightEntry> { $0.healthKitUUID == targetUUID }
```

## Conflict Resolution Data Flow

```
W8Trackr Edit                    External Health Edit
     │                                    │
     ▼                                    ▼
syncVersion++                    Detected via HKAnchoredObjectQuery
modifiedDate = now                        │
pendingHealthSync = true                  ▼
     │                           Compare syncVersion
     ▼                                    │
Export to HealthKit              ┌────────┴────────┐
(HKMetadataKeySyncVersion)       │                 │
                            Higher wins      Lower discarded
                                 │
                                 ▼
                         Update local entry
                         healthKitUUID = sample.uuid
                         pendingHealthSync = false
```
