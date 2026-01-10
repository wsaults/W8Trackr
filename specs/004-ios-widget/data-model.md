# Data Model: iOS Home Screen Widget

**Feature Branch**: `004-ios-widget`
**Created**: 2025-01-09

## Overview

The widget feature uses **existing models** from the main app with minimal additions. No new SwiftData models are required - only WidgetKit-specific data structures for timeline entries.

---

## Existing Models (Reused)

### WeightEntry (SwiftData)

**Location**: `W8Trackr/Models/WeightEntry.swift`

Already exists. Widget reads this model via shared App Group container.

| Field | Type | Description |
|-------|------|-------------|
| weightValue | Double | Weight value in original unit |
| weightUnit | String | Unit code ("lb" or "kg") |
| date | Date | Entry timestamp |
| note | String? | Optional user note |
| bodyFatPercentage | Decimal? | Optional body fat % |
| modifiedDate | Date? | Last modification time |

**Widget Usage**: Read-only access via `FetchDescriptor` in timeline provider.

---

## New Models (Widget-Specific)

### WeightWidgetEntry (WidgetKit Timeline Entry)

**Location**: `W8TrackrWidget/Models/WidgetEntry.swift`

Represents a snapshot of data for widget display at a specific time.

| Field | Type | Description |
|-------|------|-------------|
| date | Date | Timeline entry date (required by WidgetKit) |
| currentWeight | Double? | Most recent weight value (nil if no entries) |
| weightUnit | WeightUnit | User's preferred unit |
| goalWeight | Double? | User's goal weight (nil if not set) |
| entryDate | Date? | Timestamp of the weight entry |
| trend | WeightTrend | 7-day trend direction |

**State Enum: WeightTrend**

| Case | Description |
|------|-------------|
| .up | Weight increasing over 7 days |
| .down | Weight decreasing over 7 days |
| .stable | Weight change < 0.5 units |
| .unknown | Insufficient data (< 2 entries) |

---

## Shared Preferences (UserDefaults via App Group)

Existing preferences accessed by widget:

| Key | Type | Default | Source |
|-----|------|---------|--------|
| `preferredWeightUnit` | String | "lb" | `@AppStorage` in SettingsView |
| `goalWeight` | Double | 160.0 | `@AppStorage` in SettingsView |

**Migration Required**: Main app must migrate existing `@AppStorage` values to App Group UserDefaults on first launch after widget feature ships.

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        Main App                                  │
│                                                                  │
│   WeightEntry ──── SwiftData ──── App Group Container            │
│                                          │                       │
│   @AppStorage ──── UserDefaults ──── App Group UserDefaults      │
│                                          │                       │
│   On save: WidgetCenter.reloadTimelines(ofKind: "WeightWidget")  │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │     App Group         │
                    │  (Shared Container)   │
                    └───────────┬───────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────┐
│                      Widget Extension                             │
│                                                                   │
│   TimelineProvider ──── Fetch WeightEntry[] ──── SwiftData       │
│         │                                                         │
│         └──── Read preferences ──── App Group UserDefaults        │
│         │                                                         │
│         └──── Create WeightWidgetEntry ──── Timeline              │
└───────────────────────────────────────────────────────────────────┘
```

---

## Validation Rules

### WeightWidgetEntry

| Rule | Validation |
|------|------------|
| date | Must be non-nil (WidgetKit requirement) |
| currentWeight | nil allowed (empty state) |
| weightUnit | Must be valid WeightUnit case |
| goalWeight | nil allowed (no goal set) |

### Timeline Generation

| Rule | Behavior |
|------|----------|
| No weight entries | Display empty state message |
| No goal weight | Hide goal progress section |
| < 2 entries | Trend shows `.unknown` |

---

## Entity Relationships

```
WeightEntry (SwiftData, main app)
     │
     │ read-only fetch
     ▼
WeightWidgetEntry (struct, widget extension)
     │
     │ passed to
     ▼
Widget Views (SmallWidgetView, MediumWidgetView)
```

**Key Insight**: No bidirectional relationship exists. Widget is read-only consumer of main app data.
