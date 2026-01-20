---
plan: 02-01
status: complete
completed_at: 2026-01-20T12:00:00Z
---

## Summary

Fixed chart animation jank by replacing UUID-based identity with stable date-based identity in the `ChartEntry` struct, plus improved interpolation and animation curve.

## Changes Made

### W8Trackr/Views/WeightTrendChartView.swift

**1. Stable Identity (lines 102-120):**
```swift
// Before
private struct ChartEntry: Identifiable {
    let id = UUID()
    ...
}

// After
private struct ChartEntry: Identifiable {
    var id: String {
        let timestamp = Int(date.timeIntervalSince1970)
        if isSmoothed { return "smoothed-\(timestamp)" }
        else if isPrediction { return "prediction-\(timestamp)" }
        else { return "entry-\(timestamp)" }
    }
    ...
}
```

**2. Interpolation Method:**
- Changed from `.catmullRom` to `.monotone` - prevents curve overshooting during transitions

**3. Animation Curve:**
- Changed from `.easeInOut` to `.snappy` - quicker, more responsive feel

**4. X-Axis Labels:**
- Fixed 30D+ ranges to show months instead of days

## Why This Works

SwiftUI uses `Identifiable.id` to track items across state changes. With `UUID()`, each render created new IDs, so SwiftUI saw entirely new data and couldn't animate. With date-based IDs, the same data point keeps its identity across renders.

The `.monotone` interpolation prevents the curve from overshooting between points, and `.snappy` provides a responsive animation feel.

## Verification

- [x] Build succeeds
- [x] All tests pass
- [x] Manual verification: smooth animation when switching date segments
- [x] X-axis labels show months for 30D+ ranges
