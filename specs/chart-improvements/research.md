# Chart Improvements Research

## Current W8Trackr Implementation Analysis

### What We Have

**WeightTrendChartView.swift:**
- Swift Charts framework with LineMark/PointMark/RuleMark
- EWMA smoothing (span=10, α = 2/(span+1))
- Holt's Double Exponential Smoothing for predictions
- Date range picker: 1W, 1M, 3M, 6M, 1Y, All
- Goal line visualization (dashed RuleMark)
- VoiceOver accessibility support
- Fixed height (300pt)

**TrendCalculator.swift:**
- `calculateEWMA()` - Hacker's Diet inspired smoothing (λ=0.1)
- `exponentialMovingAverage()` - Daily averaging + EMA
- `calculateHolt()` - Double exponential for trend-aware predictions (α=0.3, β=0.1)
- `predictGoalDate()` - Goal achievement estimation

### Current Limitations

| Issue | Location | Impact |
|-------|----------|--------|
| **Prediction only 1 day ahead** | Line 85: `let daysAhead = 1` | Users can't visualize long-term trajectory |
| **No scrolling** | No `chartScrollableAxes` | Can't explore historical data |
| **No zoom** | No gesture handlers | Can't focus on specific periods |
| **No tap selection** | No `chartSelection` | Can't see exact values on tap |
| **Static view window** | Fixed to selected DateRange | No continuous exploration |

---

## Competitor Research

### Happy Scale

**Smoothing Options:**
1. **Exponential Smoothing** - Simple EWMA (what W8Trackr currently uses)
2. **7-Day Moving Average** - Rolling window average
3. **Happy Scale Smoothing** - Proprietary multi-pass filter
4. **Double Exponential** - Holt's method (also implemented in W8Trackr)

**Prediction Features:**
- Shows "moving average trend line" projecting weeks/months ahead
- Displays predicted goal date prominently
- Celebrates milestones along the predicted path

**Key Insight:** Happy Scale inspired by "The Hacker's Diet" - focuses on trend over daily noise.

### Lose It!

**Chart Features:**
- Weekly/monthly aggregation views
- Calorie correlation overlays
- Progress toward goal visualization
- Historical data browsing

### Industry Best Practices (2025)

| Practice | Description | Benefit |
|----------|-------------|---------|
| **Scrollable timelines** | Pan through historical data | Exploration without mode switching |
| **Pinch-to-zoom** | Focus on specific periods | Detail when needed |
| **Tap selection** | Show exact value on tap | Precision without clutter |
| **Extended prediction** | 7-30 days forecast line | Builds confidence in trajectory |
| **Brushing & linking** | Highlight connected data | Multi-chart correlation |
| **Custom date ranges** | Drag-select arbitrary periods | Flexibility |
| **Annotation support** | Mark significant events | Context for spikes/drops |

---

## Technical Implementation Options

### 1. Scrollable Charts (iOS 17+)

```swift
Chart { ... }
    .chartScrollableAxes(.horizontal)
    .chartXVisibleDomain(length: 30 * 24 * 60 * 60) // 30 days visible
    .chartXSelection(value: $selectedDate)
```

**Pros:** Native SwiftUI, smooth performance
**Cons:** Requires iOS 17+, limited customization

### 2. MagnifyGesture for Zoom

```swift
Chart { ... }
    .gesture(
        MagnifyGesture()
            .onChanged { value in
                zoomLevel = value.magnification
            }
    )
```

**Pros:** Native gesture, intuitive
**Cons:** Needs custom domain recalculation

### 3. Combined Scroll + Zoom Pattern

```swift
@State private var visibleDomain: ClosedRange<Date>
@State private var zoomLevel: Double = 1.0

Chart { ... }
    .chartScrollableAxes(.horizontal)
    .chartXVisibleDomain(length: baseDays / zoomLevel * 86400)
    .chartXSelection(value: $selectedValue)
    .gesture(MagnifyGesture().onChanged { ... })
```

### 4. DomainGesture (from danielsaidi/ScrollKit)

Third-party approach with pan + pinch + double-tap reset. More control but adds dependency.

---

## Recommendation Priority

### P0: Critical (User's Main Concerns)

1. **Extend prediction line** - Change from 1 day to 14-30 days
   - Directly addresses "doesn't show a long enough prediction line"
   - Low effort, high impact

2. **Add horizontal scrolling** - `chartScrollableAxes(.horizontal)`
   - Directly addresses "can't be scrolled"
   - Medium effort, high impact

### P1: High Value

3. **Add tap selection** - Show value on chart tap
   - Builds confidence by showing exact numbers
   - Medium effort, medium impact

4. **Extended visible domain** - Show more data by default
   - Makes chart feel less "rigid"
   - Low effort, medium impact

### P2: Nice to Have

5. **Pinch-to-zoom** - Dynamic time window
   - Power user feature
   - Higher complexity

6. **Multiple smoothing options** - Let user choose algorithm
   - Matches Happy Scale
   - Medium effort, niche value

---

## iOS Version Considerations

| Feature | Minimum iOS | Notes |
|---------|-------------|-------|
| `chartScrollableAxes` | iOS 17 | Core scrolling |
| `chartXSelection` | iOS 17 | Tap selection |
| `chartXVisibleDomain` | iOS 17 | Scroll window size |
| MagnifyGesture | iOS 17 | Zoom gestures |

W8Trackr targets **iOS 26+**, so all modern Chart APIs are available.

---

## References

- [The Hacker's Diet](https://www.fourmilab.ch/hackdiet/) - EWMA trend theory
- [Apple WWDC 2023: Swift Charts](https://developer.apple.com/videos/play/wwdc2023/10037/) - Scrolling charts
- Happy Scale App Store description
- Lose It! feature documentation
