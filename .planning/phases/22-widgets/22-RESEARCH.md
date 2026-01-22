# Phase 22: Widgets - Research

**Researched:** 2026-01-22
**Domain:** WidgetKit with SwiftData integration for iOS 26
**Confidence:** HIGH

## Summary

This phase implements home screen widgets (small, medium, large) for W8Trackr that display current weight, progress toward goal, and a sparkline chart of recent entries. The foundation is already in place from Phase 21: App Group entitlements configured, SharedModelContainer for SwiftData sharing, and sharedDefaults for preferences.

iOS 26 introduces new WidgetKit features including glass presentation with accented rendering and a Level of Detail API for visionOS. For W8Trackr, the implementation uses SwiftUI-only views (UIKit not permitted in widgets), Swift Charts for the large widget sparkline, and the standard TimelineProvider pattern for data delivery. Widgets are read-only with the main app triggering timeline reloads via `WidgetCenter.shared.reloadTimelines(ofKind:)`.

The existing SharedModelContainer and App Group infrastructure means the widget extension can immediately access SwiftData and UserDefaults from the shared container. The widget will use `@Query` or direct `FetchDescriptor` calls to retrieve weight entries.

**Primary recommendation:** Create a new Widget Extension target in Xcode, configure it to share the existing App Group and SharedModelContainer, implement three widget sizes using StaticConfiguration with a shared TimelineProvider.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| WidgetKit | iOS 26+ | Widget framework | Apple's only supported widget framework |
| SwiftUI | iOS 26+ | Widget UI | Only UI framework allowed in widgets |
| SwiftData | iOS 26+ | Data access | Already configured for App Group sharing |
| Swift Charts | iOS 26+ | Sparkline chart | Apple's native charting framework |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| WidgetCenter | WidgetKit | Timeline refresh | Call from main app when data changes |
| UserDefaults | Foundation | Shared preferences | Read weight unit, goal from App Group |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Swift Charts | DSFSparkline | Third-party adds dependency; Swift Charts is native and sufficient |
| StaticConfiguration | AppIntentConfiguration | AppIntent needed only for user-configurable widgets; not required here |

**Installation:**
No additional dependencies required. Add Widget Extension target in Xcode:
1. File > New > Target > Widget Extension
2. Configure App Group entitlement matching main app
3. Add WeightEntry.swift and SharedModelContainer.swift to widget target

## Architecture Patterns

### Recommended Project Structure
```
W8Trackr/
├── Shared/
│   └── SharedModelContainer.swift   # Shared (both targets)
├── Models/
│   └── WeightEntry.swift            # Shared (both targets)
└── W8TrackrWidget/                  # New extension target
    ├── W8TrackrWidget.swift         # Widget entry point (@main)
    ├── WeightWidgetProvider.swift   # TimelineProvider
    ├── WeightWidgetEntry.swift      # Timeline entry model
    ├── Views/
    │   ├── SmallWidgetView.swift    # Small size UI
    │   ├── MediumWidgetView.swift   # Medium size UI
    │   └── LargeWidgetView.swift    # Large size UI with sparkline
    └── W8TrackrWidget.entitlements  # Must match main app App Group
```

### Pattern 1: Shared TimelineProvider with Size Routing
**What:** Single TimelineProvider fetches data, view routes to size-specific implementations
**When to use:** Always for multi-size widgets
**Example:**
```swift
// Source: Apple WidgetKit documentation patterns
struct WeightWidgetProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeightWidgetEntry>) -> Void) {
        let entry = fetchCurrentData()
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func fetchCurrentData() -> WeightWidgetEntry {
        let context = SharedModelContainer.sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        // Build entry from fetched data...
    }
}

struct WeightWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WeightWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            EmptyView()
        }
    }
}
```

### Pattern 2: Area Chart with Gradient Fill (Large Widget)
**What:** Swift Charts AreaMark with LineMark for sparkline visualization
**When to use:** Large widget sparkline showing 7-day data
**Example:**
```swift
// Source: nilcoalescing.com/blog/AreaChartWithADimmingLayer
import Charts

struct SparklineChart: View {
    let entries: [WeightEntry]

    var body: some View {
        Chart(entries, id: \.date) { entry in
            AreaMark(
                x: .value("Date", entry.date),
                y: .value("Weight", entry.weightValue)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [.blue.opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.cardinal)

            LineMark(
                x: .value("Date", entry.date),
                y: .value("Weight", entry.weightValue)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.cardinal)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}
```

### Pattern 3: Widget URL for App Launch
**What:** Use widgetURL for tap-to-open behavior
**When to use:** All widget sizes (required for small, optional enhancement for medium/large)
**Example:**
```swift
// Source: Swift Senpai widget tap gestures guide
struct SmallWidgetView: View {
    let entry: WeightWidgetEntry

    var body: some View {
        VStack {
            // Widget content
        }
        .widgetURL(URL(string: "w8trackr://summary"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

### Pattern 4: Empty State Handling
**What:** Display helpful prompts when no data or no goal
**When to use:** When currentWeight is nil or goalWeight is nil
**Example:**
```swift
// Source: CONTEXT.md decisions
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "scalemass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Add your first weigh-in")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "w8trackr://addWeight"))
    }
}
```

### Anti-Patterns to Avoid
- **Using UIKit components:** WidgetKit only supports SwiftUI; UIViewRepresentable will crash
- **Using Buttons:** Buttons do not work in widgets; use widgetURL or Link instead
- **Expecting frequent refreshes:** System budgets ~40-70 refreshes/day; design for infrequent updates
- **Using Keychain:** Known bug causes `errSecInteractionNotAllowed`; use shared UserDefaults instead
- **Complex async operations in Provider:** Keep timeline generation fast and synchronous where possible

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sparkline chart | Custom Path/Shape | Swift Charts AreaMark + LineMark | Native framework, accessibility built-in |
| Gradient fill | Manual gradient code | LinearGradient with alignsMarkStylesWithPlotArea | Chart-aware gradient positioning |
| Timeline refresh | Custom timer/scheduling | WidgetCenter.shared.reloadTimelines | System manages refresh budget |
| Data sharing | File coordination | SharedModelContainer with App Group | SwiftData handles concurrency |
| Unit conversion | Duplicate logic | WeightEntry.weightValue(in:) | Model method already exists |

**Key insight:** Widgets are heavily constrained by the system. Use Apple's provided patterns and avoid complexity that could cause timeline generation to fail or timeout.

## Common Pitfalls

### Pitfall 1: Widget Shows Stale Data After App Update
**What goes wrong:** Widget displays old weight after user logs new entry
**Why it happens:** Timeline not reloaded after data change
**How to avoid:** Call `WidgetCenter.shared.reloadTimelines(ofKind: "WeightWidget")` in main app after any data mutation
**Warning signs:** Widget shows different data than app until hours pass

### Pitfall 2: Widget Crashes or Shows Error
**What goes wrong:** Widget displays blank or error state
**Why it happens:** Timeline provider fails to fetch data from App Group
**How to avoid:**
1. Ensure widget target has identical App Group entitlement
2. Add WeightEntry.swift and SharedModelContainer.swift to both targets
3. Use the same `groupContainer` identifier
**Warning signs:** "Unable to load" error in widget gallery

### Pitfall 3: Model Not Found in Widget Context
**What goes wrong:** Error "failed to find a currently active container for WeightEntry"
**Why it happens:** Widget doesn't have model files in its target membership
**How to avoid:**
1. Select WeightEntry.swift in Xcode
2. In File Inspector, check Target Membership for both main app AND widget
3. Do the same for SharedModelContainer.swift
**Warning signs:** Crash logs mentioning SwiftData schema errors

### Pitfall 4: Link Not Working in Small Widget
**What goes wrong:** Tapping Link view does nothing in small widget
**Why it happens:** Link views only work in medium and large widgets
**How to avoid:** Use `widgetURL(_:)` modifier for small widgets; Link is optional enhancement for medium/large
**Warning signs:** Small widget appears tappable but doesn't navigate

### Pitfall 5: Refresh Rate Disappointment
**What goes wrong:** Widget doesn't update as frequently as expected
**Why it happens:** System budgets 40-70 refreshes/day (~15-60 min intervals)
**How to avoid:**
1. Use `WidgetCenter.shared.reloadTimelines` from app for data-driven updates (not budgeted)
2. Set reasonable `.after` policy (4+ hours) as fallback
3. Don't rely on timeline for time-sensitive data
**Warning signs:** Timeline entries seem to be skipped

### Pitfall 6: iOS 26 Glass Rendering Issues
**What goes wrong:** Widget appearance doesn't match design in all contexts
**Why it happens:** iOS 26 automatically applies accented rendering and glass effects
**How to avoid:**
1. Use `.containerBackground()` modifier
2. Test with widgetAccentedRenderingMode
3. Design for both standard and accented appearances
**Warning signs:** Colors look washed out on Home Screen

## Code Examples

### Complete Widget Entry Point
```swift
// Source: Apple WidgetKit documentation + existing spec contracts
import WidgetKit
import SwiftUI
import SwiftData

@main
struct W8TrackrWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeightWidget()
    }
}

struct WeightWidget: Widget {
    let kind: String = "WeightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeightWidgetProvider()) { entry in
            WeightWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Weight Tracker")
        .description("See your current weight and progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

### Timeline Entry with Trend Calculation
```swift
// Source: Existing spec contracts + CONTEXT.md decisions
struct WeightWidgetEntry: TimelineEntry {
    let date: Date
    let currentWeight: Int?  // Whole numbers per CONTEXT.md
    let weightUnit: String   // "lb" or "kg"
    let goalWeight: Int?
    let trend: WeightTrend
    let recentEntries: [ChartDataPoint]  // For large widget sparkline

    enum WeightTrend {
        case up, down, neutral, unknown

        var systemImage: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            case .unknown: return "minus"
            }
        }
    }

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
    }
}
```

### Fetching Data with Trend Calculation
```swift
// Source: Phase 21 SharedModelContainer + WidgetKit patterns
private func fetchCurrentEntry() -> WeightWidgetEntry {
    let context = SharedModelContainer.sharedModelContainer.mainContext

    // Fetch entries sorted by date (newest first)
    var descriptor = FetchDescriptor<WeightEntry>(
        sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    descriptor.fetchLimit = 30  // Enough for 7-day trend

    guard let entries = try? context.fetch(descriptor), !entries.isEmpty else {
        return emptyEntry()
    }

    // Read preferences from shared defaults
    let defaults = SharedModelContainer.sharedDefaults
    let unitString = defaults?.string(forKey: "preferredWeightUnit") ?? "lb"
    let unit = WeightUnit(rawValue: unitString) ?? .lb
    let goalWeight = defaults?.object(forKey: "goalWeight") != nil
        ? Int(defaults!.double(forKey: "goalWeight"))
        : nil

    // Get current weight (most recent entry)
    let currentEntry = entries[0]
    let currentWeight = Int(currentEntry.weightValue(in: unit))

    // Calculate trend from 7-day window (per CONTEXT.md)
    let trend = calculateTrend(entries: entries, unit: unit)

    // Prepare chart data (last 7 days for large widget)
    let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
    let chartEntries = entries.filter { $0.date >= sevenDaysAgo }
        .map { WeightWidgetEntry.ChartDataPoint(date: $0.date, weight: $0.weightValue(in: unit)) }
        .reversed()  // Oldest first for chart

    return WeightWidgetEntry(
        date: .now,
        currentWeight: currentWeight,
        weightUnit: unitString,
        goalWeight: goalWeight,
        trend: trend,
        recentEntries: Array(chartEntries)
    )
}

private func calculateTrend(entries: [WeightEntry], unit: WeightUnit) -> WeightWidgetEntry.WeightTrend {
    let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
    let recentEntries = entries.filter { $0.date >= sevenDaysAgo }

    guard recentEntries.count >= 2,
          let newest = recentEntries.first,
          let oldest = recentEntries.last else {
        return .unknown
    }

    let diff = newest.weightValue(in: unit) - oldest.weightValue(in: unit)

    // Neutral threshold: less than 0.5 unit change (per spec contract)
    if abs(diff) < 0.5 {
        return .neutral
    }

    return diff > 0 ? .up : .down
}
```

### Main App Widget Reload Integration
```swift
// Source: Existing SharedModelContainer + Apple documentation
// Add to WeightEntry save/delete operations in main app

import WidgetKit

extension SharedModelContainer {
    /// Notify widget to reload its timeline
    /// Call after: add entry, edit entry, delete entry, change unit, change goal
    static func reloadWidgetTimeline() {
        WidgetCenter.shared.reloadTimelines(ofKind: "WeightWidget")
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| IntentConfiguration | AppIntentConfiguration | iOS 17 | New App Intents framework; StaticConfiguration still valid for non-configurable widgets |
| TimelineProvider | RelevanceEntriesProvider | iOS 26/watchOS 26 | For relevance-based widgets; TimelineProvider still standard |
| Default background | containerBackground modifier | iOS 17 | Required for proper glass rendering |

**Deprecated/outdated:**
- **showsIndicators** parameter: Use `.scrollIndicators(.hidden)` instead
- **foregroundColor**: Use `.foregroundStyle()` instead
- **cornerRadius**: Use `.clipShape(.rect(cornerRadius:))` instead

## Open Questions

1. **Accented Rendering on iOS 26**
   - What we know: iOS 26 applies automatic glass effects and color tinting
   - What's unclear: Exact behavior with custom gradients in sparkline chart
   - Recommendation: Test on iOS 26 device; may need widgetAccentedRenderingMode adjustments

2. **SwiftData Concurrent Access**
   - What we know: Widget and app can safely read/write simultaneously
   - What's unclear: Performance impact of simultaneous access during migration
   - Recommendation: Migration completed in Phase 21; should be non-issue now

3. **Exact Neutral Threshold**
   - What we know: Spec suggests 0.5 unit change threshold
   - What's unclear: Whether this should scale with unit (0.5 lb vs 0.5 kg)
   - Recommendation: Use 0.5 for both units; visually consistent

## Sources

### Primary (HIGH confidence)
- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit) - Widget architecture, TimelineProvider
- [WWDC 2025 - WidgetKit in iOS 26](https://dev.to/arshtechpro/wwdc-2025-widgetkit-in-ios-26-a-complete-guide-to-modern-widget-development-1cjp) - Glass presentation, level of detail API
- [Hacking with Swift - SwiftData Widget Access](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets) - App Group setup, shared container
- Phase 21 Research - SharedModelContainer, migration patterns

### Secondary (MEDIUM confidence)
- [Swift Senpai - Widget Tap Gestures](https://swiftsenpai.com/development/widget-tap-gestures/) - widgetURL, Link usage by size
- [nilcoalescing.com - Area Chart with Gradient](https://nilcoalescing.com/blog/AreaChartWithADimmingLayer/) - AreaMark + LineMark patterns
- [Swift Senpai - Widget Refresh](https://swiftsenpai.com/development/refreshing-widget/) - Timeline policies, reloadTimelines

### Tertiary (LOW confidence)
- Community discussions on iOS 26 widget bugs - Needs monitoring

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - WidgetKit/SwiftUI/SwiftData well-documented Apple frameworks
- Architecture: HIGH - Patterns verified against Apple docs and existing spec contracts
- Pitfalls: HIGH - Common issues documented across multiple sources
- iOS 26 specifics: MEDIUM - New features, limited real-world testing data

**Research date:** 2026-01-22
**Valid until:** 60 days (stable Apple frameworks)
