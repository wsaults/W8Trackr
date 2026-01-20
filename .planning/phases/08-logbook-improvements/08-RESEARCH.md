# Phase 8: Logbook Improvements - Research

**Researched:** 2026-01-20
**Domain:** SwiftUI List sectioning, data calculations, filter menus
**Confidence:** HIGH

## Summary

This phase enhances the logbook with month-based sectioning, richer per-row data display (moving average, weekly rate, notes indicator), and a filter menu. Research shows that SwiftUI provides straightforward patterns for all requirements using `Dictionary(grouping:by:)` for sections, computed properties for derived metrics, and `Menu` with `Toggle` for filter UI.

The codebase already has `TrendCalculator` with exponential moving average (EWMA) implementation that can be leveraged. Weekly rate calculation follows the same pattern already used in `WeeklySummaryCard`. The filter system is the only net-new pattern, but SwiftUI's `Menu` + `Toggle` combination handles this elegantly.

**Primary recommendation:** Extend `HistorySectionView` to group entries by month using `Dictionary(grouping:by:)`, add computed helper types for row data, and add a toolbar `Menu` for filtering. Reuse existing `TrendCalculator` for moving averages.

## Standard Stack

This phase uses only existing codebase dependencies - no new libraries needed.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 18+ | List sections, Menu, Toggle | Built-in framework |
| Foundation | iOS 18+ | Calendar, DateComponents for grouping | Built-in framework |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| TrendCalculator (existing) | - | EWMA calculation for moving average | Already implemented in codebase |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dictionary grouping | @SectionedQuery (SwiftData) | @SectionedQuery requires @Query; logbook receives entries as parameter |
| Toggle in Menu | Picker | Picker better for single-select; Toggle needed for multi-select filters |

## Architecture Patterns

### Recommended Project Structure

No new files needed - extend existing structure:

```
W8Trackr/Views/
├── HistorySectionView.swift    # Extend with month sections, filter state
├── LogbookView.swift           # Add toolbar filter Menu
└── Components/
    └── LogbookRowView.swift    # NEW: Extract row as reusable component
```

### Pattern 1: Month-Based Dictionary Grouping

**What:** Group entries by month using `Calendar.current.dateComponents` and `Dictionary(grouping:by:)`
**When to use:** Any list that needs date-based sections
**Example:**
```swift
// Source: https://www.hackingwithswift.com/forums/swiftui/list-with-dynamic-sections-by-date/7516
private var entriesByMonth: [Date: [WeightEntry]] {
    Dictionary(grouping: entries) { entry in
        let components = Calendar.current.dateComponents([.year, .month], from: entry.date)
        return Calendar.current.date(from: components) ?? entry.date
    }
}

private var sortedMonths: [Date] {
    entriesByMonth.keys.sorted(by: >)  // Newest first
}

// In body:
List {
    ForEach(sortedMonths, id: \.self) { month in
        Section(header: Text(month, format: .dateTime.month(.wide).year())) {
            ForEach(entriesByMonth[month] ?? []) { entry in
                LogbookRowView(entry: entry, ...)
            }
        }
    }
}
```

### Pattern 2: Filter Menu with Toggle

**What:** Multi-select filter using `Menu` containing `Toggle` items
**When to use:** Toolbar filter buttons with multiple on/off options
**Example:**
```swift
// Source: https://bdewey.com/til/2023/08/13/creating-menu-items-with-checkmarks-in-swiftui/
@State private var showWeights = true
@State private var showNotes = true
@State private var selectedDays: Set<Int> = []  // 1=Sun, 2=Mon, etc.

Menu {
    Toggle("Weights", isOn: $showWeights)
    Toggle("Notes", isOn: $showNotes)

    Divider()

    Menu("Day of Week") {
        ForEach(1...7, id: \.self) { day in
            Toggle(dayName(day), isOn: Binding(
                get: { selectedDays.contains(day) },
                set: { isOn in
                    if isOn { selectedDays.insert(day) }
                    else { selectedDays.remove(day) }
                }
            ))
        }
    }
} label: {
    Image(systemName: "line.3.horizontal.decrease.circle")
}
```

### Pattern 3: Computed Row Data Struct

**What:** Pre-calculate derived values (moving average, weekly rate) for each row
**When to use:** When row display needs data derived from the full entries array
**Example:**
```swift
struct LogbookRowData: Identifiable {
    let id: UUID
    let entry: WeightEntry
    let movingAverage: Double?
    let weeklyRate: Double?
    let hasNote: Bool

    var weightChangeDirection: TrendDirection {
        guard let rate = weeklyRate else { return .stable }
        if abs(rate) < 0.1 { return .stable }
        return rate < 0 ? .down : .up
    }
}

enum TrendDirection {
    case up, down, stable

    var symbol: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }
}
```

### Pattern 4: Moving Average Calculation

**What:** Leverage existing `TrendCalculator.exponentialMovingAverage()` for 7-day moving average
**When to use:** Calculating smoothed weight trend per entry
**Example:**
```swift
// Existing TrendCalculator returns TrendPoint with smoothedWeight
let trendPoints = TrendCalculator.exponentialMovingAverage(entries: entries, span: 7)

// Map to dictionary for O(1) lookup by date
let trendByDate: [Date: TrendPoint] = Dictionary(
    uniqueKeysWithValues: trendPoints.map {
        (Calendar.current.startOfDay(for: $0.date), $0)
    }
)

// In row data calculation:
let entryDay = Calendar.current.startOfDay(for: entry.date)
let movingAverage = trendByDate[entryDay]?.smoothedWeight(in: weightUnit)
```

### Pattern 5: Weekly Rate Calculation

**What:** Calculate weight change over past 7 days
**When to use:** Showing rate of change per row
**Example:**
```swift
// Based on existing WeeklySummaryCard pattern
func weeklyRate(for entry: WeightEntry, in entries: [WeightEntry], unit: WeightUnit) -> Double? {
    let calendar = Calendar.current
    let weekAgo = calendar.date(byAdding: .day, value: -7, to: entry.date)!

    // Find closest entry from ~7 days ago
    let olderEntries = entries.filter { $0.date <= weekAgo }
    guard let referenceEntry = olderEntries.max(by: { $0.date < $1.date }) else {
        return nil
    }

    let currentWeight = entry.weightValue(in: unit)
    let previousWeight = referenceEntry.weightValue(in: unit)

    return currentWeight - previousWeight  // Positive = gained, negative = lost
}
```

### Anti-Patterns to Avoid

- **Computing derived values in ForEach:** Calculate all row data before iterating, not during rendering
- **Calling TrendCalculator per row:** Calculate once, lookup by date for each row
- **Storing filter state in child views:** Keep filter state in parent (LogbookView) and pass filtered entries down
- **Using `@State` for derived data:** Use computed properties for filtered/grouped data, `@State` only for user input

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Moving average | Custom averaging loop | `TrendCalculator.exponentialMovingAverage()` | Already handles edge cases, unit conversion |
| Date grouping | Manual loops with if-statements | `Dictionary(grouping:by:)` | Standard Swift pattern, O(n) performance |
| Filter checkmarks | Custom button with checkmark image | `Toggle` in `Menu` | SwiftUI handles checkmark rendering automatically |
| Day-of-week names | Hardcoded strings | `DateFormatter().weekdaySymbols` | Respects user locale |

**Key insight:** The codebase already has `TrendCalculator` with EWMA and `WeeklySummaryCard` showing change calculation patterns. The logbook should reuse these, not duplicate logic.

## Common Pitfalls

### Pitfall 1: Date Grouping with Time Components
**What goes wrong:** Entries on the same day grouped separately because `Date` includes time
**Why it happens:** Using raw `Date` as dictionary key
**How to avoid:** Use `Calendar.current.dateComponents([.year, .month], from: date)` or `startOfDay(for:)`
**Warning signs:** Sections with single entries despite multiple entries per day

### Pitfall 2: Performance with Large Entry Lists
**What goes wrong:** UI lag when scrolling through months of data
**Why it happens:** Recalculating moving averages on every render
**How to avoid:** Pre-compute row data array once when entries change, use lazy computed properties
**Warning signs:** Stutter when scrolling, high CPU in Instruments

### Pitfall 3: Filter State Not Persisting
**What goes wrong:** Filters reset when navigating away and back
**Why it happens:** Using `@State` in child view that gets recreated
**How to avoid:** Store filter state in parent view (LogbookView) or use `@AppStorage` for session persistence
**Warning signs:** Filters reset on tab switch

### Pitfall 4: Missing Entries When "Heights" or "Milestones" Filter Active
**What goes wrong:** Empty list when filter selected because data doesn't exist
**Why it happens:** `WeightEntry` has no height property; milestones are separate model
**How to avoid:** Clarify requirements - "Heights" filter may need to be removed or show all entries; "Milestones" would filter to entries that crossed milestone thresholds
**Warning signs:** Filter produces empty results unexpectedly

### Pitfall 5: Incorrect Weekly Rate Sign Convention
**What goes wrong:** Down arrow shown when gaining weight, up arrow when losing
**Why it happens:** Inconsistent sign convention (positive = good vs positive = gained)
**How to avoid:** Document convention clearly: positive rate = weight gain; use direction enum that maps rate to semantic meaning
**Warning signs:** User confusion about what arrows mean

## Code Examples

Verified patterns adapted from official sources and existing codebase:

### Month Section Header Formatting
```swift
// Source: Apple's Date.FormatStyle documentation
Text(monthDate, format: .dateTime.month(.wide).year())
// Output: "January 2026"

// Alternative for abbreviated:
Text(monthDate, format: .dateTime.month(.abbreviated).year())
// Output: "Jan 2026"
```

### Compact Row Layout (matches spec)
```swift
// Layout: "16 Tue | 170.0 | 171.1 | down-arrow 0.2 | checkmark"
HStack {
    // Date column (day + weekday stacked)
    VStack(alignment: .leading, spacing: 2) {
        Text(entry.date, format: .dateTime.day())
            .font(.headline)
        Text(entry.date, format: .dateTime.weekday(.abbreviated))
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .frame(width: 32)

    Spacer()

    // Weight value
    Text(entry.weightValue(in: unit), format: .number.precision(.fractionLength(1)))
        .font(.body.monospacedDigit())

    Spacer()

    // Moving average
    if let avg = rowData.movingAverage {
        Text(avg, format: .number.precision(.fractionLength(1)))
            .font(.body.monospacedDigit())
            .foregroundStyle(.secondary)
    }

    Spacer()

    // Weekly rate with arrow
    if let rate = rowData.weeklyRate {
        HStack(spacing: 2) {
            Image(systemName: rowData.weightChangeDirection.symbol)
                .foregroundStyle(rowData.weightChangeDirection.color)
            Text(abs(rate), format: .number.precision(.fractionLength(1)))
                .font(.caption.monospacedDigit())
        }
    }

    // Notes indicator
    if rowData.hasNote {
        Image(systemName: "note.text")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
```

### Filter Application
```swift
// Source: Existing HistorySectionView.visibleEntries pattern
private var filteredEntries: [WeightEntry] {
    var result = entries

    // Filter by notes
    if !showAllWithoutNotes && showOnlyWithNotes {
        result = result.filter { $0.note != nil && !$0.note!.isEmpty }
    }

    // Filter by day of week
    if !selectedDays.isEmpty {
        result = result.filter { entry in
            let weekday = Calendar.current.component(.weekday, from: entry.date)
            return selectedDays.contains(weekday)
        }
    }

    return result
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UITableView sections | SwiftUI List + Section | iOS 14+ | Declarative, less boilerplate |
| UIMenu | SwiftUI Menu | iOS 14+ | Native SwiftUI integration |
| NSFetchedResultsController | @Query + Dictionary grouping | iOS 17+ | SwiftData-native |

**Deprecated/outdated:**
- `UITableViewDiffableDataSource`: Not needed with SwiftUI's automatic diffing
- `listStyle(.grouped)`: Default is `.insetGrouped` on iOS which looks better

## Open Questions

Things that couldn't be fully resolved:

1. **"Heights" Filter Purpose**
   - What we know: WeightEntry model has no `height` property
   - What's unclear: What should "Heights" filter show? Is this for future height tracking feature?
   - Recommendation: Clarify with product owner; if undefined, omit from initial implementation

2. **"Milestones" Filter Implementation**
   - What we know: `CompletedMilestone` is a separate SwiftData model
   - What's unclear: Should filter show entries that triggered milestone completion, or entries near milestone weights?
   - Recommendation: Show entries where weight crossed a milestone threshold (e.g., 175 lb when milestone was 175 lb)

3. **Filter Persistence Scope**
   - What we know: Spec says "persists during session"
   - What's unclear: Does "session" mean app foreground session, or until app terminates?
   - Recommendation: Use `@State` in LogbookView (clears on app restart) per spec; can upgrade to `@AppStorage` later if needed

4. **Moving Average Window Size**
   - What we know: Existing chart uses 10-day span
   - What's unclear: Should logbook use same 10-day window or standard 7-day?
   - Recommendation: Use 7-day (1 week) for intuitive "weekly average" understanding; document choice

## Sources

### Primary (HIGH confidence)
- Existing codebase: `TrendCalculator.swift` - EWMA implementation
- Existing codebase: `WeeklySummaryCard.swift` - Change calculation pattern
- Existing codebase: `HistorySectionView.swift` - Current row layout, delete handling

### Secondary (MEDIUM confidence)
- [Hacking with Swift Forums: List with dynamic sections by date](https://www.hackingwithswift.com/forums/swiftui/list-with-dynamic-sections-by-date/7516) - Dictionary grouping pattern with `startOfDay`
- [Brian DeWey: Creating Menu Items with Checkmarks in SwiftUI](https://bdewey.com/til/2023/08/13/creating-menu-items-with-checkmarks-in-swiftui/) - Toggle in Menu pattern
- [Sarunw: SwiftUI List section header and footer](https://sarunw.com/posts/swiftui-list-section-header-footer/) - Section styling

### Tertiary (LOW confidence)
- WebSearch results for SwiftUI Menu/Toggle combinations - general pattern confirmation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Uses only existing codebase patterns and built-in SwiftUI
- Architecture: HIGH - Patterns proven in existing WeeklySummaryView and HistorySectionView
- Calculations: HIGH - TrendCalculator already implements EWMA; weekly rate follows same pattern
- Filter UI: MEDIUM - Toggle in Menu is documented but less commonly shown in tutorials
- Pitfalls: MEDIUM - Based on common SwiftUI issues, not project-specific bugs

**Research date:** 2026-01-20
**Valid until:** 2026-02-20 (30 days - stable SwiftUI patterns)
