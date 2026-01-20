# Phase 2: Chart Animation - Research

**Researched:** 2026-01-20
**Domain:** SwiftUI Charts animation, view identity, computed property performance
**Confidence:** HIGH

## Summary

The chart animation jank when changing date segments has two root causes that have been verified through codebase analysis:

1. **Unstable Identity**: `ChartEntry` uses `let id = UUID()` which generates a new UUID every time the struct is instantiated. When the computed property `chartData` is recalculated, all entries get new identities, causing SwiftUI to treat them as entirely new items rather than animated transitions of existing items.

2. **Computed Property Recalculation**: The `chartData` computed property is recalculated on every body evaluation during animation frames. Combined with unstable UUIDs, this creates the "squiggling" effect as SwiftUI repeatedly sees all-new data.

**Primary recommendation:** Replace UUID-based identity with date-based stable identity, and optionally cache the chart data to prevent unnecessary recalculation during animation.

## Standard Stack

No additional libraries needed. This is a fix using existing SwiftUI Charts patterns.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI Charts | iOS 16+ | Chart rendering | Apple's built-in solution |

### Alternatives Considered
None - this is a bug fix in existing code, not a library selection decision.

## Architecture Patterns

### Root Cause Analysis

**Current Implementation (WeightTrendChartView.swift lines 102-110):**
```swift
private struct ChartEntry: Identifiable {
    let id = UUID()  // PROBLEM: New UUID every instantiation
    let date: Date
    let weight: Double
    let isPrediction: Bool
    let showPoint: Bool
    let isIndividualEntry: Bool
    let isSmoothed: Bool
}
```

**Current Data Flow (lines 153-209):**
```swift
private var chartData: [ChartEntry] {  // PROBLEM: Computed property
    // Creates new ChartEntry instances on every access
    // Each access generates new UUIDs
}
```

### Pattern 1: Date-Based Stable Identity

**What:** Use the date (combined with entry type) as the stable identifier instead of UUID.

**When to use:** When chart data points have a natural unique identifier (like timestamps).

**Example:**
```swift
private struct ChartEntry: Identifiable {
    // Computed stable ID from date + type
    var id: String {
        let dateString = date.timeIntervalSince1970.description
        let typeString = isSmoothed ? "smoothed" : (isPrediction ? "prediction" : "entry")
        return "\(dateString)-\(typeString)"
    }

    let date: Date
    let weight: Double
    let isPrediction: Bool
    let showPoint: Bool
    let isIndividualEntry: Bool
    let isSmoothed: Bool
}
```

### Pattern 2: Index-Based Identity (Alternative)

**What:** Use array enumeration with offset as identifier.

**When to use:** When data points don't have natural unique identifiers.

**Example:**
```swift
ForEach(Array(chartData.enumerated()), id: \.offset) { index, entry in
    LineMark(...)
}
```

**Note:** This is less ideal for charts where data points move/change, as the index-based identity would cause different animation behavior.

### Anti-Patterns to Avoid

- **UUID() in Identifiable structs for animated content:** Generates new IDs on each instantiation, breaking animation continuity.
- **Heavy computed properties accessed during animation:** Recalculated every frame, compounding the identity problem.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stable chart identity | Custom animation system | Date-based id property | SwiftUI handles animation automatically with stable IDs |
| Chart data caching | Manual memoization | Consider @State if needed | SwiftUI's declarative model handles most cases |

## Common Pitfalls

### Pitfall 1: UUID() in Identifiable Computed Data

**What goes wrong:** Chart lines squiggle and jank during animation.

**Why it happens:** Each time the computed property is accessed (every animation frame), new UUIDs are generated. SwiftUI sees completely new data and can't interpolate between old and new positions.

**How to avoid:** Use stable identifiers derived from the data itself (date, index, or a combination of properties that uniquely identify the entry).

**Warning signs:** Animation that looks like data is being replaced rather than transitioning smoothly.

### Pitfall 2: Expensive Computed Properties in View Body

**What goes wrong:** Performance degradation during animations, dropped frames.

**Why it happens:** Computed properties are recalculated every time they're accessed. During a 0.3 second animation at 60fps, that's 18+ recalculations.

**How to avoid:** For expensive computations, consider:
- Moving to @State with explicit updates on data changes
- Ensuring the computation itself is fast (this codebase's computation is already lightweight)

**Warning signs:** Profiler showing repeated expensive calculations during animation.

### Pitfall 3: Multiple ForEach with Overlapping Filtered Data

**What goes wrong:** Potential identity collisions or unnecessary complexity.

**Why it happens:** Current code uses three separate ForEach loops filtering the same `chartData` array:
- `chartData.filter { $0.isSmoothed }`
- `chartData.filter { $0.isPrediction }`
- `chartData.filter { $0.showPoint }`

**How to avoid:** With stable identifiers, this pattern works fine. The filtering is O(n) but n is small (typically < 100 entries).

**Warning signs:** None currently - this is acceptable given the data size.

## Code Examples

### Recommended Fix: Date-Based Stable Identity

```swift
// Source: SwiftUI identity best practices
private struct ChartEntry: Identifiable {
    // Stable identifier computed from data properties
    var id: String {
        // Combine date timestamp with entry type for uniqueness
        let timestamp = Int(date.timeIntervalSince1970)
        if isSmoothed {
            return "smoothed-\(timestamp)"
        } else if isPrediction {
            return "prediction-\(timestamp)"
        } else {
            return "entry-\(timestamp)"
        }
    }

    let date: Date
    let weight: Double
    let isPrediction: Bool
    let showPoint: Bool
    let isIndividualEntry: Bool
    let isSmoothed: Bool
}
```

### Alternative: Custom Hashable ID

```swift
// If string concatenation is a concern, use a struct
private struct ChartEntryID: Hashable {
    let timestamp: TimeInterval
    let type: EntryType

    enum EntryType: Int {
        case entry = 0
        case smoothed = 1
        case prediction = 2
    }
}

private struct ChartEntry: Identifiable {
    var id: ChartEntryID {
        let type: ChartEntryID.EntryType = isSmoothed ? .smoothed :
                                           (isPrediction ? .prediction : .entry)
        return ChartEntryID(timestamp: date.timeIntervalSince1970, type: type)
    }
    // ... rest of properties
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UUID for all Identifiable | Stable, data-derived IDs | Always best practice | Smooth animations |
| Computed properties everywhere | Cached state for expensive ops | Performance focus | Better frame rates |

**Note:** The TrendPoint struct in TrendCalculator.swift already demonstrates the correct pattern:
```swift
struct TrendPoint: Identifiable, Equatable {
    var id: Date { date }  // Stable, data-derived identity
    // ...
}
```

This pattern should be applied to ChartEntry as well.

## Files to Modify

| File | Change Required | Confidence |
|------|-----------------|------------|
| `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/WeightTrendChartView.swift` | Replace `let id = UUID()` with date-based computed `id` | HIGH |

**Scope:** Single file, ~10 lines of code change.

## Open Questions

None - the root cause is clear and the fix is straightforward.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: WeightTrendChartView.swift (lines 102-110, 153-209)
- Codebase analysis: TrendCalculator.swift (lines 12-14) - existing correct pattern

### Secondary (MEDIUM confidence)
- [Demystify SwiftUI - WWDC21](https://developer.apple.com/videos/play/wwdc2021/10022/) - Identity and view lifetime
- [Demystify SwiftUI performance - WWDC23](https://developer.apple.com/videos/play/wwdc2023/10160/) - Identity and performance
- [SwiftUI Performance Deep Dive](https://dev.to/sebastienlato/swiftui-performance-deep-dive-rendering-identity-invalidations-elm) - Stable identity = stable performance
- [How the SwiftUI View Lifecycle and Identity work](https://careersatdoordash.com/blog/how-the-swiftui-view-lifecycle-and-identity-work/) - UUID in computed properties issue
- [Avoiding SwiftUI Value Recomputation](https://www.swiftbysundell.com/articles/avoiding-swiftui-value-recomputation/) - Computed property caching

### Tertiary (LOW confidence)
- [SwiftUI Charts animation discussion](https://developer.apple.com/forums/thread/731355) - Community patterns

## Metadata

**Confidence breakdown:**
- Root cause analysis: HIGH - Verified in codebase, matches known SwiftUI identity patterns
- Fix approach: HIGH - Standard SwiftUI pattern, already used in TrendPoint
- Files to modify: HIGH - Single file, isolated change

**Research date:** 2026-01-20
**Valid until:** Indefinite - SwiftUI identity fundamentals are stable
