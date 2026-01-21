# Phase 11: Logbook Header & Cell Height - Research

**Researched:** 2026-01-21
**Domain:** SwiftUI List/ScrollView column headers, sticky headers, row density, accessibility
**Confidence:** HIGH

## Summary

This phase adds column headers to the logbook (Date, Weight, Avg, Rate, Notes) that remain pinned when scrolling, while reducing row height for better data density. The implementation requires balancing two competing header needs: a global column header row that explains each data column, and the existing month section headers that group entries.

SwiftUI provides two approaches for sticky headers: (1) `List` with `.plain` style where `Section` headers naturally pin, and (2) `ScrollView` + `LazyVStack` with `pinnedViews: [.sectionHeaders]`. Since the current implementation uses `List` and requires swipe actions, we need a hybrid approach: place a fixed column header row outside the List, above it in a VStack.

**Primary recommendation:** Create a fixed `LogbookHeaderView` component placed in a VStack above the List. Keep the List for row rendering (preserving swipe actions) and reduce vertical padding from 8pt to 4pt while maintaining 44pt minimum touch target height.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI List | iOS 18+ | Row rendering with swipe actions | Built-in, supports edit/delete swipe gestures |
| Section | iOS 14+ | Month grouping with sticky headers | Native List integration |
| VStack | iOS 13+ | Container for header + list layout | Simplest fixed-header pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| LazyVStack | iOS 14+ | Lazy loading with pinned views | Alternative if swipe actions not needed |
| ScrollView | iOS 13+ | Custom scrollable content | When List styling is too restrictive |
| HStack | iOS 13+ | Row and header layout | Column alignment |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| VStack + List | ScrollView + LazyVStack | Loses built-in swipe actions, must implement manually |
| Fixed header above List | Section header as first row | Header scrolls away with content |
| List | Table view | Table collapses to single column on iPhone |

**Installation:**
No additional dependencies required - all native SwiftUI.

## Architecture Patterns

### Recommended Project Structure
```
W8Trackr/Views/Components/
├── LogbookHeaderView.swift   # NEW: Column header row
├── LogbookRowView.swift      # MODIFY: Reduce padding
└── LogbookRowData.swift      # Unchanged
```

### Pattern 1: Fixed Header Above Scrolling List
**What:** Place column header in a VStack above the List, making it always visible.
**When to use:** When you need a single header row above a List that uses Section for grouping.
**Example:**
```swift
// Source: Community pattern for fixed headers
VStack(spacing: 0) {
    // Column header - always visible
    LogbookHeaderView()

    // Scrollable list with month sections
    List {
        ForEach(sortedMonths, id: \.self) { month in
            Section {
                ForEach(entriesByMonth[month] ?? []) { rowData in
                    LogbookRowView(rowData: rowData, weightUnit: weightUnit)
                }
            } header: {
                Text(month, format: .dateTime.month(.wide).year())
            }
        }
    }
    .listStyle(.plain)  // Enables sticky section headers
}
```

### Pattern 2: Compact Row with Accessibility
**What:** Reduce visual padding while maintaining touch target.
**When to use:** Dense data lists where users want to see more entries.
**Example:**
```swift
// Source: Apple HIG accessibility guidelines
HStack(spacing: 12) {
    // Column content...
}
.padding(.vertical, 4)           // Reduced visual padding
.frame(minHeight: 44)            // Maintain touch target
.contentShape(Rectangle())       // Ensure full area is tappable
```

### Pattern 3: Monospaced Numeric Columns
**What:** Use monospacedDigit font for numeric columns to ensure alignment.
**When to use:** Any column containing numbers that should align vertically.
**Example:**
```swift
// Already implemented in LogbookRowView
Text(value, format: .number.precision(.fractionLength(1)))
    .font(.body.monospacedDigit())
```

### Anti-Patterns to Avoid
- **Nesting ScrollViews:** Never put a List inside a ScrollView - causes unpredictable behavior
- **LazyVStack without pinnedViews:** Headers scroll away, defeating the purpose
- **Hard-coded row heights:** Use `minHeight` constraints, not fixed `height`, to respect Dynamic Type
- **Removing contentShape:** Touch targets become unpredictable without explicit content shape

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sticky section headers | Custom scroll offset tracking | List with `.listStyle(.plain)` | Built-in behavior, handles edge cases |
| Swipe-to-delete | Custom gesture recognizers | List `.swipeActions()` modifier | Handles iOS conventions, undo patterns |
| Column alignment | Manual frame calculations | HStack with fixed-width views | Simpler, respects Dynamic Type |
| Touch target sizing | Padding hacks | `.frame(minHeight: 44)` + `.contentShape()` | Explicit, accessible |

**Key insight:** List provides swipe actions that are difficult to replicate manually. Preserve List usage even though LazyVStack offers more header flexibility.

## Common Pitfalls

### Pitfall 1: List Default Style Has No Sticky Headers
**What goes wrong:** Section headers scroll away with content
**Why it happens:** Default and `.insetGrouped` list styles don't pin headers
**How to avoid:** Always use `.listStyle(.plain)` or `.listStyle(.inset)` for sticky headers
**Warning signs:** Headers disappearing when scrolling

### Pitfall 2: Touch Targets Below 44pt
**What goes wrong:** Users with motor impairments can't reliably tap rows
**Why it happens:** Reducing padding without maintaining minimum height
**How to avoid:** Use `.frame(minHeight: 44)` combined with `.contentShape(Rectangle())`
**Warning signs:** Accidental taps on wrong rows, accessibility audit failures

### Pitfall 3: Column Misalignment
**What goes wrong:** Header columns don't align with row data
**Why it happens:** Different spacing, padding, or font sizes between header and rows
**How to avoid:** Extract column widths to shared constants; use identical HStack spacing
**Warning signs:** Visual misalignment when scrolling

### Pitfall 4: Lost Safe Area in Headers
**What goes wrong:** Fixed header overlaps navigation bar or status bar
**Why it happens:** Not accounting for safe area in VStack layout
**How to avoid:** Let SwiftUI handle safe area automatically; don't use `.ignoresSafeArea()`
**Warning signs:** Content hidden behind navigation elements

### Pitfall 5: Separator Line Styling
**What goes wrong:** Header looks disconnected from list rows
**Why it happens:** List has built-in separators; header does not
**How to avoid:** Add a subtle divider below the header, or style header background to match
**Warning signs:** Jarring visual break between header and first row

## Code Examples

Verified patterns from official sources:

### Column Header View Component
```swift
// Pattern for fixed column header
struct LogbookHeaderView: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("Date")
                .frame(width: 40, alignment: .leading)

            Spacer()

            Text("Weight")
            Text("Avg")
            Text("Rate")
            Text("Notes")
                .frame(width: 24)  // Match notes icon width
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppColors.background)
    }
}
```

### Compact Row with Accessibility
```swift
// Source: Apple HIG + existing LogbookRowView pattern
HStack(spacing: 12) {
    dateColumn
    Spacer()
    weightColumn
    movingAverageColumn
    weeklyRateColumn
    notesIndicator
}
.padding(.vertical, 4)           // Reduced from 8
.frame(minHeight: 44)            // Accessibility minimum
.contentShape(Rectangle())
.accessibilityElement(children: .ignore)
.accessibilityLabel(accessibilityLabel)
```

### List Style for Sticky Section Headers
```swift
// Source: SwiftUI documentation
List {
    ForEach(sortedMonths, id: \.self) { month in
        Section {
            // Row content
        } header: {
            Text(month, format: .dateTime.month(.wide).year())
        }
    }
}
.listStyle(.plain)  // Critical for sticky headers
```

### Reducing Row Insets
```swift
// Source: SwiftUI listRowInsets documentation
ForEach(items) { item in
    RowView(item: item)
        .listRowInsets(EdgeInsets(
            top: 0, leading: 16, bottom: 0, trailing: 16
        ))
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UITableView section headers | List Section with `.plain` style | iOS 14 | Native SwiftUI sticky headers |
| Fixed 44pt row height | `minHeight: 44` with content-based sizing | iOS 14 | Flexible rows with accessibility |
| Custom sticky header via GeometryReader | VStack + List combo | iOS 15+ | Simpler, more reliable |

**Deprecated/outdated:**
- `PlainListStyle()` struct syntax - use `.plain` modifier instead
- Manual scroll offset tracking for sticky headers - unnecessary with proper List styles

## Open Questions

Things that couldn't be fully resolved:

1. **Column width alignment across header and rows**
   - What we know: HStack spacing must match, fixed widths for Date column
   - What's unclear: Optimal widths for Weight, Avg, Rate columns without truncation
   - Recommendation: Test with sample data; use flexible Spacer() between Date and numeric columns

2. **Header background in dark mode**
   - What we know: AppColors.background adapts to light/dark
   - What's unclear: Whether header needs visual distinction from list background
   - Recommendation: Test both modes; consider subtle Surface color for header

3. **Edit mode interaction**
   - What we know: List EditButton is in toolbar
   - What's unclear: Whether fixed header affects edit mode visual appearance
   - Recommendation: Test edit mode with fixed header in place

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation - List styles and Section headers
- Apple HIG - Accessibility touch targets (44x44pt minimum)
- SwiftUI listRowInsets documentation

### Secondary (MEDIUM confidence)
- [SwiftUI Recipes - Sticky List Header](https://swiftuirecipes.com/blog/sticky-list-header-in-swiftui) - VStack + List pattern
- [SwiftUI Recipes - List Row Insets](https://swiftuirecipes.com/blog/swiftui-list-change-row-padding-insets) - listRowInsets usage
- [YoSwift - PinnedScrollableViews](https://yoswift.dev/swiftui/pinnedScrollableViews/) - LazyVStack pinnedViews pattern

### Tertiary (LOW confidence)
- Community forum discussions on fixed headers above Lists

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Native SwiftUI, well-documented
- Architecture: HIGH - VStack + List is established pattern
- Pitfalls: HIGH - Based on Apple HIG and documented issues
- Column alignment: MEDIUM - Requires testing with actual data

**Research date:** 2026-01-21
**Valid until:** 60 days (stable SwiftUI patterns, no expected changes)
