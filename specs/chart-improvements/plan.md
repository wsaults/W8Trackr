# Chart Improvement Plan

## Problem Statement

The current chart implementation has these user-reported issues:
1. **"Too rigid"** - Static view with no exploration capability
2. **"Can't be scrolled"** - No horizontal navigation through history
3. **"Doesn't show a long enough prediction line"** - Only 1 day forecast
4. **"Don't have much confidence"** - Limited interactivity reduces trust

## Goals

1. Enable horizontal scrolling through weight history
2. Extend prediction line to show meaningful trajectory
3. Add tap-to-select for viewing exact values
4. Maintain smooth animations and accessibility

---

## Implementation Tasks

### Task 1: Extend Prediction Line

**File:** `WeightTrendChartView.swift`

**Current:** Line 85 - `let daysAhead = 1`

**Change:** Extend to 14 days (2 weeks) for meaningful trajectory visualization

```swift
// Before
let daysAhead = 1

// After
let daysAhead = 14
```

**Additional changes needed:**
- Update x-axis domain to include prediction dates
- Extend prediction line styling (lighter opacity toward end)
- Ensure prediction doesn't exceed goal weight

**Acceptance:**
- [ ] Prediction line extends 14 days beyond last entry
- [ ] X-axis domain accommodates prediction dates
- [ ] Prediction stops at goal weight (doesn't overshoot)

---

### Task 2: Add Horizontal Scrolling

**File:** `WeightTrendChartView.swift`

**Add to Chart:**
```swift
Chart { ... }
    .chartScrollableAxes(.horizontal)
    .chartXVisibleDomain(length: visibleDaysForRange * 86400) // seconds per day
```

**Compute visible domain based on DateRange:**
```swift
private var visibleDaysForRange: Int {
    switch selectedRange {
    case .oneWeek: return 7
    case .oneMonth: return 30
    case .threeMonth: return 45  // Show subset, scroll for more
    case .sixMonth: return 60
    case .oneYear: return 90
    case .allTime: return 120
    }
}
```

**Acceptance:**
- [ ] Chart scrolls horizontally when data exceeds visible domain
- [ ] Scroll position preserves during range changes
- [ ] Smooth scrolling without jank

---

### Task 3: Add Tap Selection

**Files:** `WeightTrendChartView.swift`, `ChartSectionView.swift`

**Add state and binding:**
```swift
@State private var selectedDate: Date?
@State private var selectedWeight: Double?
```

**Add to Chart:**
```swift
Chart { ... }
    .chartXSelection(value: $selectedDate)
```

**Add selection indicator overlay:**
```swift
if let selected = selectedDate,
   let entry = findClosestEntry(to: selected) {
    RuleMark(x: .value("Selected", entry.date))
        .foregroundStyle(.secondary.opacity(0.3))

    PointMark(x: .value("Date", entry.date),
              y: .value("Weight", entry.weight))
        .symbol(.circle)
        .symbolSize(100)
}
```

**Add value display above chart:**
```swift
if let date = selectedDate, let weight = selectedWeight {
    HStack {
        Text(date, format: .dateTime.month().day())
        Spacer()
        Text("\(weight, format: .number.precision(.fractionLength(1))) \(weightUnit.rawValue)")
            .bold()
    }
    .font(.caption)
    .padding(.horizontal)
}
```

**Acceptance:**
- [ ] Tapping chart selects nearest data point
- [ ] Selected point highlighted with larger symbol
- [ ] Date and weight displayed above chart
- [ ] Tapping empty area clears selection

---

### Task 4: Improve Default Visible Range

**File:** `ChartSectionView.swift`

**Change default from 1W to 1M:**
```swift
// Before
@State private var selectedRange: DateRange = .oneWeek

// After
@State private var selectedRange: DateRange = .oneMonth
```

**Rationale:** One week is often too narrow to see meaningful trends. One month provides better context while still showing detail.

**Acceptance:**
- [ ] Chart defaults to 1M view
- [ ] Sufficient data visible to establish trend confidence

---

## Visual Mockup

```
┌─────────────────────────────────────────────┐
│  Jan 15: 172.3 lb                    [x]    │  ← Selected value display
├─────────────────────────────────────────────┤
│     ^                                       │
│ 175 │      ●                                │
│     │    ●   ●                              │
│ 170 │  ●       ●───────────────────→        │  ← Extended prediction
│     │            ●   ●  ●                   │
│ 165 │─────────────────────────── Goal ───── │
│     │                                       │
│     └───────────────────────────────────────│
│       Dec        Jan        Feb        Mar  │
│                  ← scroll →                 │
├─────────────────────────────────────────────┤
│   [1W] [1M] [3M] [6M] [1Y] [All]            │
└─────────────────────────────────────────────┘
```

---

## Testing Checklist

### Functional Tests
- [ ] Scroll works with 7 days of data
- [ ] Scroll works with 365+ days of data
- [ ] Prediction line renders correctly at all zoom levels
- [ ] Selection works on points, trend line, and prediction
- [ ] Accessibility labels update for selection

### Edge Cases
- [ ] Empty data shows appropriate empty state
- [ ] Single entry shows point without trend
- [ ] At-goal state stops prediction at goal line
- [ ] Wrong-direction trend doesn't show prediction extending wrong way

### Performance
- [ ] Smooth scrolling with 1000+ entries
- [ ] No jank when switching date ranges
- [ ] Selection response < 100ms

---

## Migration Notes

No breaking changes. All improvements are additive to existing chart functionality.

## Dependencies

None - uses only iOS 17+ Swift Charts APIs (W8Trackr requires iOS 26+).

---

## Summary

| Task | Effort | Impact | Priority |
|------|--------|--------|----------|
| Extend prediction line | Low | High | P0 |
| Add horizontal scrolling | Medium | High | P0 |
| Add tap selection | Medium | Medium | P1 |
| Change default range | Low | Low | P2 |

Total estimated scope: 4 tasks, focused on addressing user's stated concerns.
