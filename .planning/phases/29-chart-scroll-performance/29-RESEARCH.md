# Phase 29: Chart Scroll Performance - Research

**Researched:** 2026-02-10
**Domain:** Swift Charts horizontal scrolling performance in SwiftUI
**Confidence:** MEDIUM (core pattern verified across multiple sources; iOS 26-specific selection+scroll behavior is LOW confidence)

## Summary

This research investigates how to enable smooth 60fps horizontal scrolling in a Swift Charts weight trend chart. The project has attempted this four times, each failing due to the same root cause: using `chartScrollPosition(x: $binding)` which triggers SwiftUI body re-evaluation on every scroll frame, causing jank.

The solution is well-documented across Apple's developer community: use `chartScrollPosition(initialX:)` (non-reactive) instead of the binding variant, combined with `chartScrollableAxes(.horizontal)` and `chartXVisibleDomain(length:)`. However, several important interactions and limitations must be handled correctly for this to work in the project's context, particularly: (1) `initialX` becomes inert after the user scrolls, requiring `.id()` to reset on DateRange change, (2) `chartXSelection` may conflict with `chartScrollableAxes` on iOS 18+ (needs validation on iOS 26), and (3) the `.animation()` modifier can interfere with scroll performance.

**Primary recommendation:** Use `chartScrollPosition(initialX:)` with `.id(selectedRange)` on the chart to force re-creation when DateRange changes, load ALL data into the chart at all times, and use `chartXVisibleDomain` to control the visible window width.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift Charts | iOS 17+ built-in | Chart rendering & scrolling | Apple's first-party framework; `chartScrollableAxes` is the official API for scrollable charts |
| SwiftUI | iOS 26+ | View lifecycle & state management | Framework-level control over body re-evaluation; `@State` caching prevents recomputation |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none) | - | - | No third-party libraries needed; this is entirely first-party API |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `chartScrollPosition(initialX:)` | `chartScrollPosition(x: $binding)` | Binding version allows programmatic scroll control but causes per-frame body re-evaluation = jank. Only consider if you absolutely need to read/control scroll position programmatically and can extract chart to isolated subview. |
| Swift Charts scrolling | `ScrollView` wrapping a wide Chart | Manual approach from iOS 16 era; no built-in snap behavior, no `chartXVisibleDomain`, more gesture conflicts. Avoid. |

## Architecture Patterns

### Recommended Architecture

```
WeightTrendChartView
├── @State cachedData (PreparedChartData)     ← Recomputed only on data/settings change
├── @State cachedYMin/cachedYMax              ← From ALL data, not visible window
├── recomputeChartData()                      ← Uses ALL entries (no range filtering)
│   ├── Triggered by: dataFingerprint, weightUnit, showSmoothing
│   └── NOT triggered by: selectedRange (range only affects visible domain)
├── visibleDomainSeconds (computed)           ← From selectedRange.days
├── initialScrollDate (computed)              ← From selectedRange + last entry date
└── chart (private var, extracted View)
    ├── .chartScrollableAxes(.horizontal)
    ├── .chartXVisibleDomain(length: visibleDomainSeconds)
    ├── .chartScrollPosition(initialX: initialScrollDate)
    ├── .chartXSelection(value: $selectedDate)  ← May conflict; see Open Questions
    ├── .id(selectedRange)                      ← Forces chart re-creation on range change
    └── NO .animation() modifier                ← Removed to prevent scroll interference
```

### Pattern 1: Non-Reactive Scroll Position
**What:** Use `chartScrollPosition(initialX:)` instead of `chartScrollPosition(x: $binding)` to set the initial scroll position without creating a reactive binding that triggers body re-evaluation on every scroll frame.
**When to use:** Always, when you don't need to programmatically read or change the scroll position during scrolling.
**Why it works:** The `initialX` variant tells Charts where to start scrolling from but does not create a two-way binding. Once the user scrolls, Charts handles the scroll internally without notifying SwiftUI state, so `body` is never re-evaluated during scroll.

```swift
// GOOD: Non-reactive, no body re-evaluation during scroll
.chartScrollPosition(initialX: initialScrollDate)

// BAD: Reactive binding, body re-evaluates every scroll frame
.chartScrollPosition(x: $scrollPosition)
```
Source: [Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/view/chartscrollposition(initialx:)), [Apple Developer Forums](https://developer.apple.com/forums/thread/735687)

### Pattern 2: Force Chart Re-creation with `.id()`
**What:** Apply `.id(selectedRange)` to the Chart view so SwiftUI destroys and re-creates it when the DateRange picker changes.
**When to use:** When using `chartScrollPosition(initialX:)` and you need the initial position to reset when a parameter changes.
**Why it's needed:** `chartScrollPosition(initialX:)` only takes effect when the chart is first created. Once the user scrolls, changing the `initialX` value has no effect. By applying `.id(selectedRange)`, changing the range forces SwiftUI to treat it as a new chart, re-applying `initialX`.

```swift
chart
    .chartScrollPosition(initialX: initialScrollDate)
    .chartXVisibleDomain(length: visibleDomainSeconds)
    .id(selectedRange)  // Forces re-creation when range changes
```
Source: [Community pattern](https://www.hackingwithswift.com/forums/swiftui/changing-chartxvisibledomain-length-causes-the-chart-to-move-to-another-position-how-to-stop-this/25796) + SwiftUI `.id()` semantics

### Pattern 3: Data Layer Decoupled from Scroll Layer
**What:** The chart ALWAYS contains ALL weight entries. The DateRange only controls `chartXVisibleDomain` (how wide the visible window is) and `initialScrollDate` (where the chart starts scrolled to). `recomputeChartData()` never references `selectedRange`.
**When to use:** Always for scrollable charts where you want to see all data by scrolling.
**Why it matters:** Prior attempts failed because `recomputeChartData()` filtered entries by `selectedRange.days`, meaning the chart only contained visible-range data. This made scrolling pointless (nothing to scroll to) and caused data-layer recomputation when the range changed.

### Pattern 4: Stable Y-Axis from ALL Data
**What:** Compute `cachedYMin`/`cachedYMax` from ALL data points (entries + smoothed + predictions), not just the currently visible window.
**When to use:** Always for horizontally scrollable charts.
**Why it matters:** If Y-axis bounds are computed from visible data, scrolling through regions with different weight ranges causes the Y-axis to jump, triggering chart re-layout and visual instability.

```swift
// Y-axis from ALL data (stable during scroll)
let allWeights = points.map(\.weight) + smoothed.map(\.weight) + predictions.map(\.weight)
if let minVal = allWeights.min(), let maxVal = allWeights.max() {
    cachedYMin = minVal - yAxisPadding
    cachedYMax = maxVal + yAxisPadding
}
```

### Pattern 5: Extract Chart to Isolated View Property
**What:** Move the `Chart { ... }` block and its modifiers out of `body` into a `private var chart: some View` computed property.
**When to use:** Always for charts with scroll position or selection bindings.
**Why it helps:** Even with `initialX` (non-binding), the chart should be extracted. If `selectedDate` (from `chartXSelection`) changes, only the chart computed property re-evaluates, not the entire body including `selectionDisplay` and parent `VStack`. This is the pattern used in attempt 4 (8846ff5) and recommended by Apple Developer Forums.

Source: [Apple Developer Forums](https://developer.apple.com/forums/thread/735687) "Move charts into subviews, so their bodies won't be called on markerValue change"

### Anti-Patterns to Avoid
- **`chartScrollPosition(x: $binding)`**: Causes per-frame body re-evaluation. The binding updates on every scroll frame, triggering SwiftUI state changes. Console shows: "onChange(of: Optional<CGRect>) action tried to update multiple times per frame."
- **Computing Y-axis from visible entries only**: Prior attempts used `visibleEntries` and `visibleTrendPoints` to compute Y bounds. This requires reading the scroll position (reactive binding) and causes axis jumping.
- **`.animation(.snappy, value: selectedRange)` on a scrollable chart**: Animation modifiers that watch state changes can interfere with the internal scroll animation. Attempt 2 identified this as a contributor to jank. Remove or scope carefully.
- **Range-filtering data inside `recomputeChartData()`**: If `recomputeChartData()` uses `selectedRange` to filter entries, then: (a) changing the range recomputes data unnecessarily, and (b) the chart doesn't contain data outside the range to scroll to.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Horizontal scrolling | `ScrollView` wrapper around wide Chart | `chartScrollableAxes(.horizontal)` | Built-in gesture handling, snap behavior, deceleration, and integration with `chartXVisibleDomain` |
| Visible window control | Manual date filtering of chart data | `chartXVisibleDomain(length:)` | Framework handles rendering optimization; only the visible region is drawn at full detail |
| Initial scroll position | Manual `ScrollViewReader.scrollTo()` | `chartScrollPosition(initialX:)` | Purpose-built for Charts; handles coordinate mapping automatically |
| Scroll target snapping | Custom gesture recognizer with snapping | `chartScrollTargetBehavior(.valueAligned)` | Optional but useful; snaps to data point boundaries after scroll deceleration |

**Key insight:** All four failed attempts tried to add scrolling while keeping the data-filtering approach. The correct architecture is: load ALL data, let Charts handle scroll rendering, and only control the visible window width.

## Common Pitfalls

### Pitfall 1: Reactive Scroll Position Binding
**What goes wrong:** Chart stutters/janks during horizontal scrolling.
**Why it happens:** `chartScrollPosition(x: $scrollPosition)` updates `@State scrollPosition` on every frame (60Hz). Each state mutation triggers `body` re-evaluation. If `body` references computed properties or does any work, the re-evaluation takes >16ms and frames are dropped.
**How to avoid:** Use `chartScrollPosition(initialX:)` exclusively. Accept that you cannot programmatically read the current scroll position.
**Warning signs:** Console message "onChange(of: Optional<CGRect>) action tried to update multiple times per frame". Instruments shows `body` called at 60Hz during scroll.

### Pitfall 2: `initialX` Becomes Inert After First Scroll
**What goes wrong:** User changes DateRange picker, but chart doesn't scroll to the new position.
**Why it happens:** Apple documentation states: "once the user scrolls the scroll view, the value provided to this modifier will have no effect."
**How to avoid:** Apply `.id(selectedRange)` to the chart view. When the id changes, SwiftUI destroys and re-creates the chart, re-applying the `initialX` value.
**Warning signs:** Changing the DateRange picker doesn't move the chart to show recent data.

### Pitfall 3: chartXSelection May Not Work with chartScrollableAxes on iOS 18+
**What goes wrong:** Tap-to-select stops working when scrolling is enabled, or scrolling stops working when selection is enabled.
**Why it happens:** There is a documented regression/limitation in iOS 18 where `chartXSelection` and `chartScrollableAxes` conflict. On iOS 17 both worked together; on iOS 18+ they may not.
**How to avoid:** Test on iOS 26 simulator first. If selection breaks, use `.chartGesture()` modifier (iOS 18+) with a `SpatialTapGesture` to manually implement selection via `ChartProxy`. Alternative workaround: ZStack two charts (one scrollable, one non-scrollable for selection overlay).
**Warning signs:** Tapping on the chart does nothing when scrolling is also enabled.

### Pitfall 4: .animation() Modifier Interferes with Scroll
**What goes wrong:** Scroll feels sluggish or triggers unexpected animations.
**Why it happens:** `.animation(.snappy, value: selectedRange)` on the chart means any change to `selectedRange` animates the chart transition. With `.id(selectedRange)` this might cause a transition animation on re-creation. During scrolling, if any state change triggers animation, it compounds with the scroll.
**How to avoid:** Remove `.animation(.snappy, value: selectedRange)` from the chart entirely. If you want range-change animation, use `withAnimation` in the picker's onChange handler instead, and test that it doesn't conflict with scroll. With `.id()` forcing re-creation, animation on the transition may look wrong anyway.
**Warning signs:** Visual glitch when changing DateRange. Scroll feels "heavy" or has momentum issues.

### Pitfall 5: chartXVisibleDomain Change Causes Position Jump
**What goes wrong:** When user changes the visible domain length (via DateRange picker), the chart scroll position jumps to an unexpected location.
**Why it happens:** Documented Apple bug/behavior: changing `chartXVisibleDomain` while the chart has been scrolled causes the scroll position to shift unexpectedly.
**How to avoid:** Using `.id(selectedRange)` to force chart re-creation avoids this entirely, since the chart is destroyed and re-created with the new `initialX` and `visibleDomain` together.
**Warning signs:** After changing DateRange, the chart shows an unexpected date range instead of recent data.

### Pitfall 6: Gesture Conflict with Parent ScrollView
**What goes wrong:** Horizontal chart scrolling blocks vertical page scrolling, or vertical page scrolling prevents horizontal chart scrolling.
**Why it happens:** When a chart with `chartScrollableAxes(.horizontal)` is inside a vertical `ScrollView`, iOS must decide which gesture takes priority. Swift Charts' built-in scroll uses UIScrollView internally, which has its own gesture disambiguation.
**How to avoid:** This generally works correctly with Apple's built-in `chartScrollableAxes` because it uses the same UIScrollView gesture priority system as regular ScrollViews. Horizontal-first gestures go to the chart; vertical-first gestures go to the parent. The previous commit message (5cf5c77) mentioned "nested horizontal/vertical scroll views caused gesture ambiguity lag" but that was with the reactive binding approach which was already causing per-frame jank. Test with the non-reactive approach.
**Warning signs:** Diagonal swipes feel uncertain. Vertical scrolling near the chart area feels delayed.

## Code Examples

### Complete Scroll Modifier Stack
```swift
// Source: Verified pattern from multiple community sources and Apple docs
private var chart: some View {
    Chart {
        // ... chart marks using cachedData ...
    }
    .chartYScale(domain: cachedYMin...cachedYMax)          // Stable Y from ALL data
    .chartXScale(domain: cachedData.dateDomain)            // Full date range
    .chartScrollableAxes(.horizontal)                       // Enable horizontal scroll
    .chartXVisibleDomain(length: visibleDomainSeconds)     // Window width from DateRange
    .chartScrollPosition(initialX: initialScrollDate)      // Start position (non-reactive)
    .chartXSelection(value: $selectedDate)                  // Tap selection (test on iOS 26)
    .id(selectedRange)                                      // Force re-creation on range change
    // NO .animation() modifier here
}
```

### visibleDomainSeconds Computed Property
```swift
// Source: Project-specific calculation
private var visibleDomainSeconds: TimeInterval {
    guard let days = selectedRange.days else {
        // "All" mode: show entire data span + predictions
        let sorted = entries.sorted { $0.date < $1.date }
        guard let first = sorted.first?.date, let last = sorted.last?.date else {
            return 604_800 // fallback: 7 days in seconds
        }
        let predictionEnd = Calendar.current.date(byAdding: .day, value: 14, to: last) ?? last
        return predictionEnd.timeIntervalSince(first)
    }
    // Range days + 14 days for prediction visibility at scroll end
    return TimeInterval((days + 14) * 86_400)
}
```

### initialScrollDate Computed Property
```swift
// Source: Project-specific calculation
private var initialScrollDate: Date {
    let sorted = entries.sorted { $0.date < $1.date }
    guard let lastDate = sorted.last?.date else { return Date() }
    guard let days = selectedRange.days else {
        // "All" mode: start from beginning
        return sorted.first?.date ?? Date()
    }
    // Position chart so latest data is visible on the right side
    return Calendar.current.date(byAdding: .day, value: -(days + 14), to: lastDate) ?? lastDate
}
```

### recomputeChartData() (No Range Filtering)
```swift
// Source: Corrected pattern based on prior attempt analysis
private func recomputeChartData() {
    // ALL entries, not filtered by selectedRange
    let sortedEntries = entries.sorted { $0.date < $1.date }

    let trend = TrendCalculator.exponentialMovingAverage(entries: entries, span: 10)

    var smoothed: [ChartEntry] = []
    if showSmoothing {
        // ALL trend points, not filtered
        smoothed = trend.map { point in
            ChartEntry(
                date: point.date,
                weight: point.smoothedWeight(in: weightUnit),
                isPrediction: false, showPoint: false,
                isIndividualEntry: false, isSmoothed: true
            )
        }
    }

    let points = sortedEntries.map { entry in
        ChartEntry(
            date: entry.date,
            weight: entry.weightValue(in: weightUnit),
            isPrediction: false, showPoint: true,
            isIndividualEntry: true, isSmoothed: false
        )
    }

    let predictions = makePredictionPoints(trend: trend)

    // Date domain spans ALL data + predictions
    let dateDomain: ClosedRange<Date>
    if let firstDate = sortedEntries.first?.date {
        let lastDate = sortedEntries.last?.date ?? firstDate
        let predictionEnd = Calendar.current.date(byAdding: .day, value: 14, to: lastDate) ?? lastDate
        dateDomain = firstDate...predictionEnd
    } else {
        dateDomain = Date()...Date()
    }

    cachedData = PreparedChartData(
        smoothed: smoothed, predictions: predictions,
        points: points, dateDomain: dateDomain
    )

    // Y-axis from ALL data (stable during scroll)
    let allWeights = points.map(\.weight) + smoothed.map(\.weight) + predictions.map(\.weight)
    if let minVal = allWeights.min(), let maxVal = allWeights.max() {
        cachedYMin = minVal - yAxisPadding
        cachedYMax = maxVal + yAxisPadding
    }
}
```

### onChange Handlers (selectedRange Removed)
```swift
// Source: Corrected pattern
.onAppear { recomputeChartData() }
.onChange(of: dataFingerprint) { _, _ in recomputeChartData() }
.onChange(of: weightUnit) { _, _ in recomputeChartData() }
.onChange(of: showSmoothing) { _, _ in recomputeChartData() }
// NO onChange(of: selectedRange) — range only affects computed properties
// The .id(selectedRange) on the chart handles range changes
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `chartScrollPosition(x: $binding)` | `chartScrollPosition(initialX:)` | iOS 17 launch (both available from start) | Non-reactive version avoids per-frame body re-evaluation |
| Filter data to visible range | Load ALL data + `chartXVisibleDomain` | Conceptual shift, not API change | Charts framework handles rendering optimization internally |
| `.animation()` on Chart | `withAnimation` at call site or `.id()` transitions | Best practice evolution | Prevents animation interference with scroll gesture |
| `chartXSelection` + `chartScrollableAxes` (iOS 17) | May need `.chartGesture()` workaround (iOS 18+) | iOS 18 regression | Selection and scrolling may conflict on iOS 18+ |

**Deprecated/outdated:**
- Using `ScrollView` to wrap a wide Chart for scrolling (pre-iOS 17 approach). Use `chartScrollableAxes` instead.
- Computing Y-axis from visible window only. Use fixed Y-axis from all data.

## Open Questions

1. **`chartXSelection` + `chartScrollableAxes` compatibility on iOS 26**
   - What we know: iOS 17 supported both. iOS 18 introduced a regression where they conflict. Some reports say selection is disabled when scrolling is enabled.
   - What's unclear: Whether iOS 26 fixes this regression, or if the new `.chartGesture()` API is required.
   - Recommendation: Implement with `chartXSelection(value: $selectedDate)` first. Test on iOS 26 simulator. If tapping doesn't work during/after scroll, implement fallback using `.chartGesture()` with `SpatialTapGesture`. **This is the highest-risk unknown** and must be validated during the human verification step.
   - Confidence: LOW

2. **Gesture conflict between horizontal chart scroll and vertical page scroll**
   - What we know: The chart is inside a vertical `ScrollView` (DashboardView). Prior attempt 3 commit message mentioned "gesture ambiguity lag." Apple's built-in `chartScrollableAxes` should handle gesture disambiguation correctly.
   - What's unclear: Whether the jank in prior attempts was caused by the gesture conflict or by the reactive binding (likely the binding, since removing scrolling entirely fixed it). The non-reactive approach hasn't been tested with the vertical ScrollView parent.
   - Recommendation: Test with the non-reactive approach. If gesture conflicts persist, consider adding `scrollBounceBehavior(.basedOnSize)` to the parent ScrollView or adjusting chart frame height. Should work out of the box.
   - Confidence: MEDIUM

3. **Performance with large datasets**
   - What we know: The performant chart gist uses windowing (only ~140 data points rendered) for 7,283 entries. This project likely has hundreds, not thousands.
   - What's unclear: At what data volume Swift Charts' built-in rendering optimization breaks down when using `chartScrollableAxes`.
   - Recommendation: For the expected data volume (<1000 entries over a few years of daily tracking), loading ALL data should be fine. If performance degrades with very large datasets in the future, consider the windowing approach from the Midbin gist.
   - Confidence: MEDIUM

4. **Equatable conformance on chart data structs**
   - What we know: Attempt 4 added `Equatable` to `ChartEntry` and `PreparedChartData`. This enables SwiftUI to skip re-evaluation when data hasn't changed.
   - What's unclear: Whether `Equatable` conformance meaningfully improves performance when using `@State` cached data (SwiftUI already does reference equality checks on `@State`).
   - Recommendation: Add `Equatable` conformance anyway. It's cheap, correct, and provides an additional optimization signal to SwiftUI's diffing system.
   - Confidence: MEDIUM

## Sources

### Primary (HIGH confidence)
- [Apple Developer Documentation: chartScrollPosition(initialX:)](https://developer.apple.com/documentation/swiftui/view/chartscrollposition(initialx:)) - API exists and sets initial position; becomes inert after user scrolls
- [Apple Developer Documentation: chartScrollableAxes(_:)](https://developer.apple.com/documentation/swiftui/view/chartscrollableaxes(_:)) - Enables horizontal/vertical chart scrolling
- [Apple Developer Forums: poor performance with chartScrollPosition](https://developer.apple.com/forums/thread/735687) - Confirms binding version causes per-frame body re-evaluation; recommends subview extraction

### Secondary (MEDIUM confidence)
- [Swift with Majid: Mastering Charts - Scrolling](https://swiftwithmajid.com/2023/07/25/mastering-charts-in-swiftui-scrolling/) - Documents both `initialX` and binding variants with code examples
- [SwiftyLion: Scrollable SwiftUI Charts](https://swiftylion.com/articles/scrollable-swiftui-charts) - Confirms `initialX` pattern and visible domain usage
- [Midbin's Performant Chart Gist](https://gist.github.com/Midbin/c275098ed1151e51a0f3441ea69f921f) - Windowing approach for 7,283 data points; pre-calculated axis marks
- [Hacking with Swift Forums: chartXVisibleDomain position jump](https://www.hackingwithswift.com/forums/swiftui/changing-chartxvisibledomain-length-causes-the-chart-to-move-to-another-position-how-to-stop-this/25796) - Documents the visibleDomain change causing scroll position jump
- [Apple Developer Forums: chartXVisibleDomain issue](https://developer.apple.com/forums/thread/757099) - Confirms position jump when changing visible domain length

### Tertiary (LOW confidence)
- iOS 18 `chartXSelection` + `chartScrollableAxes` conflict reports - Multiple community reports but no official Apple documentation confirming or denying the regression
- `.id()` force-recreation pattern - Standard SwiftUI pattern but not officially documented for Charts scroll position reset specifically

## Prior Attempt Analysis

| Attempt | Commit | What Was Tried | Why It Failed | Key Lesson |
|---------|--------|----------------|---------------|------------|
| 1 | 347938d | Added `chartScrollPosition(x: $scrollPosition)` + `chartScrollableAxes` + `chartXVisibleDomain` | Reactive binding triggered body re-evaluation every scroll frame = jank | Never use the binding variant for scroll position |
| 2 | 139d9ad | Removed `.animation(scrollPosition)`, pre-split chart data into typed arrays, cached EMA | Still used `chartScrollPosition(x: $scrollPosition)` binding; Y-axis still computed from visible window | Caching data helps but doesn't fix the binding problem |
| 3 | 87fae0c | Moved EMA and chart data to `@State` with fingerprint-based recomputation, stable Y-axis from all data | Still used `chartScrollPosition(x: $scrollPosition)` binding; the fundamental binding re-evaluation issue remained | Even with perfect caching, the binding itself is the problem |
| 4 | 8846ff5 | Switched to `chartScrollPosition(initialX:)`, extracted chart to `private var chart`, added Equatable | Still filtered data to `selectedRange.days` in `recomputeChartData()`, so chart only contained range-filtered data (nothing to scroll to). Reverted because "previous attempt only showed entries from the selected range instead of the full data range." | `initialX` was correct but data layer still coupled to range |

**Synthesis:** Each attempt fixed one layer of the problem but missed another. The complete fix requires ALL of: (1) non-reactive `initialX`, (2) ALL data loaded (no range filtering), (3) stable Y-axis from all data, (4) `visibleDomain` from DateRange, (5) `.id(selectedRange)` for range-change reset, (6) no `.animation()` on chart.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Apple first-party API, well-documented
- Architecture patterns: MEDIUM - Core pattern verified across multiple sources; `.id()` reset pattern is standard SwiftUI but not Charts-specific documentation
- Pitfalls: HIGH for binding jank (confirmed by Apple forums), MEDIUM for gesture conflicts, LOW for iOS 26 selection+scroll compatibility
- Code examples: MEDIUM - Based on verified patterns adapted to project context

**Research date:** 2026-02-10
**Valid until:** 2026-03-10 (stable APIs; iOS 26-specific behavior may need revalidation with new betas)
