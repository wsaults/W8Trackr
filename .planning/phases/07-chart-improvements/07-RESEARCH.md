# Phase 7: Chart Improvements - Research

**Researched:** 2026-01-20
**Domain:** Swift Charts interactivity (scrolling, selection, extended prediction)
**Confidence:** HIGH

## Summary

This phase addresses three chart interaction requirements: extending the prediction line from 1 day to 14 days ahead, enabling horizontal scrolling through historical data, and adding tap selection to show exact weight values. The existing Swift Charts implementation in WeightTrendChartView.swift provides a solid foundation using Holt's Double Exponential Smoothing for predictions and stable ChartEntry identifiers (fixed in Phase 2).

Swift Charts in iOS 17+ provides native APIs for all three requirements: `chartScrollableAxes(.horizontal)` for scrolling, `chartXVisibleDomain(length:)` for viewport control, and `chartXSelection(value:)` for tap selection. However, there is a **known iOS 18 bug** where scrolling and selection conflict - when both are enabled, one feature may stop working. The recommended workaround is using `chartGesture` with custom gesture handling or a ZStack overlay approach.

**Primary recommendation:** Implement extended prediction line (trivial change from `daysAhead = 1` to `daysAhead = 14`), add scrolling with `chartScrollableAxes`, and add tap selection with `chartXSelection`. Test thoroughly on iOS 26 to verify the scroll+selection bug is resolved, with ZStack workaround as fallback.

## Standard Stack

All requirements use built-in Swift Charts APIs - no additional libraries needed.

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Swift Charts | iOS 17+ | Chart rendering, scrolling, selection | Apple's built-in framework |
| SwiftUI | iOS 26 | View composition, state management | Project requirement |

### Key APIs
| API | Purpose | Availability |
|-----|---------|--------------|
| `chartScrollableAxes(.horizontal)` | Enable horizontal scrolling | iOS 17+ |
| `chartXVisibleDomain(length:)` | Control visible time window | iOS 17+ |
| `chartScrollPosition(x:)` | Track/control scroll position | iOS 17+ |
| `chartXSelection(value:)` | Tap-to-select binding | iOS 17+ |
| `chartGesture` | Custom gesture handling | iOS 17+ |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `chartXSelection` | `chartOverlay` + `DragGesture` | More control but more code |
| Native scrolling | ScrollView wrapper | Loss of chart axis awareness |
| 14-day prediction | User-configurable days | Complexity vs value |

## Architecture Patterns

### Current Implementation Analysis

**WeightTrendChartView.swift structure:**
```
Current Flow:
1. filteredEntries - applies DateRange filter
2. smoothedTrend - EWMA from TrendCalculator
3. prediction - Holt's method, currently 1 day ahead (line 85)
4. chartData - combines entries, smoothed, prediction
5. Chart renders with stable ChartEntry IDs (Phase 2 fix)
```

**Prediction calculation (lines 80-98):**
```swift
private var prediction: (...) {
    let daysAhead = 1  // <-- CHANGE THIS TO 14
    let predictedWeight = holtResult.forecast(daysAhead: daysAhead)
    // Returns start point and end point for prediction line
}
```

### Pattern 1: Extended Prediction Line
**What:** Extend prediction from 1 day to 14 days ahead
**When to use:** WeightTrendChartView.prediction computed property
**Example:**
```swift
// Source: WeightTrendChartView.swift line 85
// Change from:
let daysAhead = 1

// To:
let daysAhead = 14

// Additional consideration: generate intermediate points for smooth curve
private var predictionPoints: [ChartEntry] {
    guard let holtResult = TrendCalculator.calculateHolt(entries: filteredEntries) else {
        return []
    }

    var points: [ChartEntry] = []
    let startDate = holtResult.lastDate
    let startWeight = convertWeight(holtResult.level)

    // Add starting point (connects to actual data)
    points.append(ChartEntry(
        date: startDate,
        weight: startWeight,
        isPrediction: true,
        showPoint: false,
        isIndividualEntry: false,
        isSmoothed: false
    ))

    // Add intermediate and end points
    for day in [7, 14] {
        guard let futureDate = Calendar.current.date(byAdding: .day, value: day, to: startDate) else {
            continue
        }
        let futureWeight = convertWeight(holtResult.forecast(daysAhead: day))
        points.append(ChartEntry(
            date: futureDate,
            weight: futureWeight,
            isPrediction: true,
            showPoint: day == 14,  // Show point at end only
            isIndividualEntry: false,
            isSmoothed: false
        ))
    }

    return points
}
```

### Pattern 2: Horizontal Scrolling
**What:** Enable scrolling through historical data
**When to use:** When data exceeds visible domain
**Example:**
```swift
// Source: Swift Charts documentation, Swift with Majid blog
Chart { ... }
    .chartScrollableAxes(.horizontal)
    .chartXVisibleDomain(length: visibleDomainSeconds)

// Compute visible domain based on selected range
private var visibleDomainSeconds: TimeInterval {
    let days: Double
    switch selectedRange {
    case .oneWeek: days = 10      // Slightly more than week for context
    case .oneMonth: days = 35     // ~1 month
    case .threeMonth: days = 45   // Subset of 3 months, scroll for more
    case .sixMonth: days = 60     // Subset of 6 months
    case .oneYear: days = 90      // Subset of year
    case .allTime: days = 120     // Reasonable default
    }
    return days * 24 * 60 * 60  // Convert to seconds
}
```

### Pattern 3: Tap Selection with Value Display
**What:** Show exact weight/date when tapping chart
**When to use:** User taps on chart to see precise values
**Example:**
```swift
// Source: Swift Charts WWDC23, Swift with Majid
@State private var selectedDate: Date?

Chart { ... }
    .chartXSelection(value: $selectedDate)

// Find closest entry to selected date
private var selectedEntry: (date: Date, weight: Double)? {
    guard let selected = selectedDate else { return nil }

    let closest = chartData
        .filter { !$0.isPrediction }
        .min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) })

    guard let entry = closest else { return nil }
    return (entry.date, entry.weight)
}

// Add selection indicator in Chart body
if let selected = selectedDate, let entry = selectedEntry {
    RuleMark(x: .value("Selected", entry.date))
        .foregroundStyle(.secondary.opacity(0.3))
        .lineStyle(StrokeStyle(lineWidth: 1))

    PointMark(x: .value("Date", entry.date), y: .value("Weight", entry.weight))
        .symbol(.circle)
        .symbolSize(100)
        .foregroundStyle(AppColors.accent)
}

// Display selected value above chart
if let entry = selectedEntry {
    HStack {
        Text(entry.date, format: .dateTime.month().day())
        Spacer()
        Text("\(entry.weight, format: .number.precision(.fractionLength(1))) \(weightUnit.rawValue)")
            .bold()
    }
    .font(.caption)
    .foregroundStyle(AppColors.textSecondary)
    .padding(.horizontal)
}
```

### Pattern 4: iOS 18 Bug Workaround (ZStack Approach)
**What:** Workaround for scroll+selection conflict in iOS 18
**When to use:** If testing reveals the bug persists in iOS 26
**Example:**
```swift
// Source: Apple Developer Forums, community discussions
// Use ZStack with two charts: one for selection, one for scrolling
ZStack {
    // Background chart: non-scrollable, handles selection and annotations
    Chart { ... }
        .chartXSelection(value: $selectedDate)
        // Draws RuleMark and annotation for selection

    // Foreground chart: scrollable, draws actual data
    Chart { ... }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: visibleDomainSeconds)
}
```

### Anti-Patterns to Avoid
- **Hardcoded prediction days:** Use constant or config, not magic number
- **Blocking scroll gesture with overlay:** Don't use chartOverlay that captures all gestures
- **Recalculating Holt on every scroll frame:** Cache prediction result

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Chart scrolling | Custom ScrollView wrapper | `chartScrollableAxes` | Native integration with axes |
| Tap detection on chart | Custom gesture recognizer | `chartXSelection` | Handles coordinate conversion |
| Prediction calculation | Simple linear projection | `TrendCalculator.calculateHolt` | Already implemented with proper smoothing |
| Date formatting | Custom formatters | `dateFormatForRange` | Already handles all ranges |

**Key insight:** The existing TrendCalculator already has Holt's method implemented - just need to call `forecast(daysAhead: 14)` instead of `forecast(daysAhead: 1)`.

## Common Pitfalls

### Pitfall 1: iOS 18 Scroll + Selection Conflict
**What goes wrong:** Scrolling disabled when chartXSelection applied, or selection stops working
**Why it happens:** Known iOS 18 bug (FB13993465) - gesture recognizers conflict
**How to avoid:**
- Test on iOS 26 target first - bug may be fixed
- If persists, use ZStack workaround with two overlaid charts
- Alternative: use long-press for selection instead of tap
**Warning signs:** Chart suddenly stops scrolling after adding chartXSelection

### Pitfall 2: X-Axis Domain Not Including Prediction
**What goes wrong:** Prediction line gets cut off at edge of chart
**Why it happens:** Chart domain calculated from data points, not including future dates
**How to avoid:**
- Extend domain calculation to include prediction end date
- Add `chartXScale(domain:)` that includes prediction dates
**Warning signs:** Prediction line stops abruptly at chart edge

### Pitfall 3: Prediction Overshooting Goal
**What goes wrong:** Prediction line extends past goal weight (wrong direction)
**Why it happens:** Linear projection doesn't cap at goal
**How to avoid:**
- Clamp prediction weight to not cross goal line
- Stop prediction line at intersection with goal
**Warning signs:** Prediction shows weight loss continuing forever past goal

### Pitfall 4: Selection Snapping to Wrong Point
**What goes wrong:** Tapping between points selects unexpected entry
**Why it happens:** Raw selection value doesn't account for point density
**How to avoid:**
- Find closest actual data point to selection
- Consider using `chartOverlay` with `ChartProxy.value(atX:)` for precision
**Warning signs:** Selection highlight jumps unexpectedly

### Pitfall 5: Visible Domain Too Large
**What goes wrong:** Chart feels cramped, data points too dense to distinguish
**Why it happens:** Visible domain shows all data instead of subset
**How to avoid:**
- Use `chartXVisibleDomain(length:)` to limit visible window
- Allow scrolling to reveal more data
**Warning signs:** All points crammed together, chart unreadable

## Code Examples

### Example 1: Extended Prediction (Minimal Change)
```swift
// Source: WeightTrendChartView.swift prediction computed property
// BEFORE: line 85
let daysAhead = 1

// AFTER:
let daysAhead = 14
```

### Example 2: Full Scrolling + Selection Implementation
```swift
// Source: Swift Charts documentation pattern
struct WeightTrendChartView: View {
    // Add state for selection
    @State private var selectedDate: Date?

    // Existing properties...

    var body: some View {
        VStack {
            // Selection value display
            selectionDisplay

            Chart {
                // Existing chart marks...

                // Selection indicator
                if let selectedDate, let entry = findClosestEntry(to: selectedDate) {
                    RuleMark(x: .value("Selected", entry.date))
                        .foregroundStyle(.secondary.opacity(0.3))

                    PointMark(x: .value("Date", entry.date), y: .value("Weight", entry.weight))
                        .symbol(.circle)
                        .symbolSize(100)
                        .foregroundStyle(AppColors.chartEntry)
                }
            }
            // Existing modifiers...
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: visibleDomainSeconds)
            .chartXSelection(value: $selectedDate)
        }
    }

    @ViewBuilder
    private var selectionDisplay: some View {
        if let selectedDate, let entry = findClosestEntry(to: selectedDate) {
            HStack {
                Text(entry.date, format: .dateTime.month().day())
                Spacer()
                Text("\(entry.weight, format: .number.precision(.fractionLength(1))) \(weightUnit.rawValue)")
                    .bold()
            }
            .font(.caption)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal)
            .transition(.opacity)
        }
    }

    private func findClosestEntry(to date: Date) -> ChartEntry? {
        chartData
            .filter { !$0.isPrediction && $0.showPoint }
            .min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    private var visibleDomainSeconds: TimeInterval {
        // Based on selectedRange, return appropriate window size
        let days: Double = switch selectedRange {
        case .oneWeek: 10
        case .oneMonth: 35
        case .threeMonth: 45
        case .sixMonth: 60
        case .oneYear: 90
        case .allTime: 120
        }
        return days * 86400  // seconds per day
    }
}
```

### Example 3: Initial Scroll Position (Start at Most Recent)
```swift
// Source: Swift Charts documentation
@State private var scrollPosition: Date = Date()

Chart { ... }
    .chartScrollableAxes(.horizontal)
    .chartXVisibleDomain(length: visibleDomainSeconds)
    .chartScrollPosition(x: $scrollPosition)
    .onAppear {
        // Position scroll at most recent data
        if let lastEntry = entries.first {
            scrollPosition = lastEntry.date
        }
    }
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fixed date ranges only | Scrollable + date ranges | iOS 17 (WWDC23) | Continuous exploration |
| chartOverlay gestures | chartXSelection binding | iOS 17 | Simpler selection code |
| Manual coordinate math | ChartProxy.value(atX:) | iOS 16+ | Easier hit testing |
| 1-day prediction | 14+ day extended forecast | Best practice | Better user confidence |

**Current issues:**
- iOS 18 scroll+selection conflict (FB13993465) - may be fixed in iOS 26
- Annotation overflow resolution broken with scrollable axes

**Deprecated/outdated:**
- Using chartOverlay with DragGesture for selection (replaced by chartXSelection)
- Manual gesture recognizers for chart interaction

## Files to Modify

| File | Change Required | Complexity |
|------|-----------------|------------|
| `WeightTrendChartView.swift` | Extended prediction, scrolling, selection | Medium |
| `ChartSectionView.swift` | Pass selection state if displaying value outside chart | Low |

**Scope:** Primary changes in WeightTrendChartView.swift. ChartSectionView may need updates if selection display moves to parent.

## Open Questions

1. **iOS 18 Bug Status on iOS 26**
   - What we know: Scroll+selection conflict documented in iOS 18
   - What's unclear: Whether Apple fixed it in iOS 26
   - Recommendation: Test early; have ZStack workaround ready

2. **Prediction Line Styling**
   - What we know: Currently uses dashed line for prediction
   - What's unclear: Should 14-day prediction fade in opacity toward end?
   - Recommendation: Keep simple initially; gradient opacity is enhancement

3. **Selection on Prediction Points**
   - What we know: Prediction points are in chartData
   - What's unclear: Should tapping prediction show predicted value?
   - Recommendation: Filter out predictions from selection (show actual data only)

4. **X-Axis Labels During Scroll**
   - What we know: Current labels based on selectedRange
   - What's unclear: How labels update during scroll
   - Recommendation: Test behavior; may need `chartScrollTargetBehavior` for snapping

## Sources

### Primary (HIGH confidence)
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/WeightTrendChartView.swift` - Current implementation
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Analytics/TrendCalculator.swift` - Holt prediction method
- `/Users/will/Projects/Saults/W8Trackr/specs/chart-improvements/research.md` - Prior research
- `/Users/will/Projects/Saults/W8Trackr/specs/chart-improvements/plan.md` - Prior planning
- [Mastering charts in SwiftUI. Scrolling.](https://swiftwithmajid.com/2023/07/25/mastering-charts-in-swiftui-scrolling/) - Scrolling patterns
- [Mastering charts in SwiftUI. Selection.](https://swiftwithmajid.com/2023/07/18/mastering-charts-in-swiftui-selection/) - Selection patterns

### Secondary (MEDIUM confidence)
- [SwiftyLion: Scrollable SwiftUI Charts](https://swiftylion.com/articles/scrollable-swiftui-charts) - API overview
- [WWDC23: Explore pie charts and interactivity](https://developer.apple.com/videos/play/wwdc2023/10037/) - Official Apple guidance

### Tertiary (LOW confidence)
- Apple Developer Forums discussions on iOS 18 scroll+selection bug
- Community workarounds (ZStack overlay approach)

## Metadata

**Confidence breakdown:**
- Extended prediction: HIGH - Simple parameter change, API already exists
- Horizontal scrolling: HIGH - Native iOS 17+ API, well-documented
- Tap selection: MEDIUM - Native API but iOS 18 bug risk, needs testing
- Bug workaround: LOW - May not be needed if iOS 26 fixes issue

**Research date:** 2026-01-20
**Valid until:** ~30 days (iOS 26 behavior should be verified on device)

## Planning Recommendations

### Suggested Plan Structure

**Single Plan Recommended:** All three requirements are related chart enhancements. Implement sequentially to verify each feature works before adding next.

**Task Order:**
1. CHART-01: Extended prediction line (simplest, no API changes)
2. CHART-02: Horizontal scrolling (foundation for exploration)
3. CHART-03: Tap selection (depends on scrolling working)
4. Verification: Test scroll+selection together

**Estimated Complexity:**
- CHART-01: Low (change 1 to 14)
- CHART-02: Medium (add modifiers, compute visible domain)
- CHART-03: Medium (add state, selection display, closest entry logic)
- Bug workaround: Medium (if needed)

**Total estimated effort:** 1-2 hours implementation + testing

### Verification Steps
1. Build and run - no compile errors
2. Verify prediction line extends 14 days beyond last entry
3. Verify chart scrolls horizontally to reveal historical data
4. Verify tapping chart shows exact weight value for date
5. Verify selection clears when tapping empty area
6. Test scrolling AND selection work together (iOS 18 bug check)
7. Verify prediction line doesn't extend past goal weight
8. Run SwiftLint - zero warnings
9. Test with various date ranges (1W through All)
