# HealthKit Interaction Contracts

**Feature**: 001-apple-health-sync
**Date**: 2025-01-09

## Overview

This document defines the contracts between W8Trackr and Apple HealthKit. These are not REST APIs but HealthKit framework interactions that must be implemented consistently.

## Data Types

### Body Mass (Weight)

**HealthKit Type**: `HKQuantityType(.bodyMass)`
**Identifier**: `HKQuantityTypeIdentifierBodyMass`

**Units Supported**:
| Unit | HKUnit | Notes |
|------|--------|-------|
| Pounds | `.pound()` | US default |
| Kilograms | `.gramUnit(with: .kilo)` | Metric default |
| Stones | `.stone()` | UK (not used in W8Trackr) |

## Authorization Contract

### Request Permissions

**When**: User enables Health sync in Settings

**Types Requested**:
```swift
let readTypes: Set<HKObjectType> = [HKQuantityType(.bodyMass)]
let shareTypes: Set<HKSampleType> = [HKQuantityType(.bodyMass)]
```

**Info.plist Requirements**:
```xml
<key>NSHealthShareUsageDescription</key>
<string>W8Trackr reads your weight data to show a complete history including entries from other apps and devices.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>W8Trackr saves your weight entries to Apple Health so they're available to other health apps and your healthcare providers.</string>
```

**Response Handling**:
| Outcome | App Behavior |
|---------|--------------|
| User grants both read+write | Enable full sync |
| User grants write only | Export works, import shows no data |
| User denies both | Show graceful message, disable sync toggle |
| User cancels | Same as deny |

## Write Contract (Export)

### Save Weight Sample

**Input**:
| Field | Type | Required | Source |
|-------|------|----------|--------|
| `weight` | `Double` | Yes | `WeightEntry.weightValue` |
| `unit` | `HKUnit` | Yes | Derived from `WeightEntry.weightUnit` |
| `date` | `Date` | Yes | `WeightEntry.date` |
| `syncIdentifier` | `String` | Yes | `"w8trackr-\(entry.persistentModelID)"` |
| `syncVersion` | `Int` | Yes | `WeightEntry.syncVersion` |

**Metadata**:
```swift
[
    HKMetadataKeySyncIdentifier: syncIdentifier,
    HKMetadataKeySyncVersion: syncVersion
]
```

**Output**:
| Outcome | Result |
|---------|--------|
| Success | Sample UUID returned, store in `healthKitUUID` |
| Duplicate (same syncId, lower version) | No-op, HealthKit ignores |
| Unauthorized | Throw error, queue for retry |

### Delete Weight Sample

**Precondition**: `healthKitUUID` is non-nil

**Input**:
| Field | Type | Source |
|-------|------|--------|
| `sampleUUID` | `UUID` | `WeightEntry.healthKitUUID` |

**Behavior**:
- Use `HKHealthStore.delete(_:)` with sample fetched by UUID
- If sample not found (already deleted externally), succeed silently

## Read Contract (Import)

### Query Weight Samples (Incremental)

**Input**:
| Field | Type | Source |
|-------|------|--------|
| `anchor` | `HKQueryAnchor?` | `UserDefaults["healthSyncAnchor"]` |

**Output**:
| Field | Type | Description |
|-------|------|-------------|
| `addedSamples` | `[HKQuantitySample]` | New/updated samples since anchor |
| `deletedObjects` | `[HKDeletedObject]` | Deleted sample UUIDs since anchor |
| `newAnchor` | `HKQueryAnchor` | Store for next query |

**Sample Mapping**:
```swift
HKQuantitySample → WeightEntry
├── quantity.doubleValue(for:) → weightValue (converted to preferred unit)
├── startDate → date
├── uuid.uuidString → healthKitUUID
├── sourceRevision.source.name → source
├── metadata[HKMetadataKeySyncVersion] → syncVersion (if present)
└── (none) → note, bodyFatPercentage (Health doesn't have these)
```

### Query Weight Samples (Historical)

**When**: First-time import after user enables sync

**Input**:
| Field | Type | Default |
|-------|------|---------|
| `startDate` | `Date` | `Date.distantPast` (all history) |
| `endDate` | `Date` | `Date()` |
| `limit` | `Int` | `HKObjectQueryNoLimit` |

**Sorting**: By `HKSampleSortIdentifierEndDate`, descending (newest first)

## Observer Contract (Background Sync)

### Setup Observer Query

**When**: App launch if sync enabled

**Type**: `HKObserverQuery` on `HKQuantityType(.bodyMass)`

**Callback Behavior**:
1. Receive notification that weight data changed
2. Execute `HKAnchoredObjectQuery` to get actual changes
3. **Must** call `completionHandler()` when done

### Enable Background Delivery

**Entitlement**: `com.apple.developer.healthkit.background-delivery`

**Frequency**: `.immediate` (notify as soon as possible)

```swift
healthStore.enableBackgroundDelivery(
    for: HKQuantityType(.bodyMass),
    frequency: .immediate,
    withCompletion: { success, error in ... }
)
```

## Error Handling

| Error | User-Facing Message | Recovery Action |
|-------|---------------------|-----------------|
| `HKError.errorAuthorizationDenied` | "Health access not granted" | Show Settings link |
| `HKError.errorAuthorizationNotDetermined` | "Please grant Health access" | Re-request authorization |
| `HKError.errorDatabaseInaccessible` | "Health data unavailable" | Retry on next foreground |
| `HKError.errorHealthDataUnavailable` | (iPad) | Hide Health sync option |
| Network/timeout | "Sync delayed" | Queue and retry |

## Testing Contract

### Mock Protocol

```swift
protocol HealthStoreProtocol {
    static func isHealthDataAvailable() -> Bool
    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws -> Bool
    func save(_ sample: HKSample) async throws
    func delete(_ sample: HKSample) async throws
    func execute(_ query: HKQuery)
}
```

### Test Scenarios (Unit/Integration Only)

*Note: UI tests are prohibited per constitution. These scenarios are validated via unit tests with mocks and integration tests on device.*

| Scenario | Mock Setup | Expected Behavior |
|----------|------------|-------------------|
| Happy path export | `save` succeeds | Entry marked synced |
| Export unauthorized | `save` throws auth error | Entry queued, user notified |
| Import empty | `execute` returns empty | No entries added |
| Import with data | `execute` returns samples | Entries created with source |
| Conflict resolution | Local v2, remote v3 | Remote wins |
| Deletion sync | `deletedObjects` has UUID | Local entry deleted |
