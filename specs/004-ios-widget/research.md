# Research: iOS Home Screen Widget

**Feature Branch**: `004-ios-widget`
**Completed**: 2025-01-09

## Research Summary

This document captures technical decisions made during the planning phase for the iOS widget feature.

---

## 1. SwiftData Sharing Between App and Widget

**Decision**: Use App Groups with shared ModelContainer

**Rationale**: WidgetKit extensions run in a separate process from the main app. SwiftData requires explicit configuration to share the database file between processes using App Groups.

**Implementation Pattern**:
```swift
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    groupContainer: .identifier("group.com.yourcompany.W8Trackr")
)
```

**Alternatives Considered**:
- UserDefaults for simple data sync - Rejected: Would duplicate data and require sync logic
- File-based JSON export - Rejected: Loses SwiftData benefits and adds complexity
- Network sync - Rejected: Overkill for local widget, requires online connectivity

---

## 2. Timeline Provider Pattern

**Decision**: Use `TimelineProvider` (non-configurable) for initial implementation

**Rationale**: The widget displays fixed content (current weight, goal progress) without user-configurable options. The simpler `TimelineProvider` is sufficient and reduces complexity.

**Implementation Pattern**:
- Create timeline entries every 4-6 hours
- Use `.atEnd` or `.after(Date)` refresh policy
- Call `WidgetCenter.shared.reloadTimelines(ofKind:)` when app data changes

**Alternatives Considered**:
- `AppIntentTimelineProvider` - Deferred: Would enable configuration but adds complexity for v1
- `IntentTimelineProvider` (legacy) - Rejected: Deprecated in favor of AppIntents

---

## 3. Widget Refresh Strategy

**Decision**: App-triggered refresh with timeline fallback

**Rationale**: Weight entries are user-initiated and infrequent. Calling `reloadTimelines()` after each entry provides immediate updates while timeline entries provide periodic refreshes.

**Implementation Pattern**:
```swift
// After inserting/updating weight entry:
WidgetCenter.shared.reloadTimelines(ofKind: "WeightWidget")
```

**Refresh Budget**: Widgets get ~40-70 system refreshes per day. Using app-triggered reloads plus 4-hour timeline entries stays well within budget.

**Alternatives Considered**:
- Frequent timeline entries (every hour) - Rejected: Unnecessary for weight tracking cadence
- Push notification triggered - Rejected: Overkill for local-only app

---

## 4. Deep Linking Implementation

**Decision**: Custom URL scheme (`w8trackr://`) with path-based routing

**Rationale**: Allows widget taps to navigate to specific screens (add weight, logbook) with minimal setup. URL schemes are simpler than Universal Links for app-internal navigation.

**URL Mapping**:
| URL | Destination |
|-----|-------------|
| `w8trackr://addWeight` | Weight entry sheet (modal) |
| `w8trackr://logbook` | Logbook tab |
| `w8trackr://summary` | Summary tab |

**Alternatives Considered**:
- Universal Links - Rejected: Requires web domain configuration, overkill for widget-to-app navigation
- Scene-based navigation - Rejected: More complex, same result

---

## 5. Widget Size Support

**Decision**: Support Small and Medium sizes

**Rationale**:
- **Small**: Shows current weight + goal progress (4 items max)
- **Medium**: Adds "Log Weight" action button and more detail

Large size deferred: Current feature doesn't have enough content to justify large widget (no chart, no extended history).

**Size Dimensions** (iPhone):
| Size | Dimensions |
|------|------------|
| Small | ~155x155 pt |
| Medium | ~338x155 pt |

---

## 6. UserDefaults Sharing for Preferences

**Decision**: Share UserDefaults via App Group for preferences (unit, goal weight)

**Rationale**: `@AppStorage` uses standard UserDefaults. Widget needs access to `preferredWeightUnit` and `goalWeight` to display data correctly. App Group UserDefaults enables this sharing.

**Implementation Pattern**:
```swift
// In main app (wrap AppStorage usage):
UserDefaults(suiteName: "group.com.yourcompany.W8Trackr")?.set(unit, forKey: "preferredWeightUnit")

// In widget:
let defaults = UserDefaults(suiteName: "group.com.yourcompany.W8Trackr")
let unit = defaults?.string(forKey: "preferredWeightUnit") ?? "lb"
```

**Migration Note**: Existing `@AppStorage` values in the main app use standard UserDefaults. A one-time migration to App Group UserDefaults is needed for existing users.

---

## 7. Accessibility

**Decision**: Full VoiceOver and Dynamic Type support

**Rationale**: Constitution requires accessibility support. WidgetKit uses SwiftUI, which provides built-in accessibility when using standard components.

**Implementation Pattern**:
- Use `.accessibilityLabel()` for custom descriptions
- Use system fonts (`.font(.title)`) for Dynamic Type scaling
- Ensure minimum 44x44pt tap targets

---

## Technical Decisions Summary

| Area | Decision | Complexity |
|------|----------|------------|
| Data Sharing | App Groups + SwiftData | Low |
| Timeline | Non-configurable TimelineProvider | Low |
| Refresh | App-triggered + 4hr timeline | Low |
| Deep Linking | Custom URL scheme | Low |
| Sizes | Small + Medium | Medium |
| Preferences | App Group UserDefaults | Low |

**Overall Assessment**: Standard WidgetKit patterns apply. No novel technical challenges identified.
