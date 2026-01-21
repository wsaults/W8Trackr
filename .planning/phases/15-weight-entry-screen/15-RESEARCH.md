# Phase 15: Weight Entry Screen - Research

**Researched:** 2026-01-21
**Domain:** SwiftUI forms, focus management, keyboard handling, sheet interaction
**Confidence:** HIGH

## Summary

This phase replaces the current plus/minus button-based weight entry UI with a clean, focused text input experience. The current `WeightEntryView.swift` uses `WeightAdjustmentButton` components for increment/decrement controls; these must be removed and replaced with direct text field input.

The expanded scope from CONTEXT.md includes: date navigation with arrows, weight text input with auto-focus, notes text area with character limit, and an expandable "More..." section for body fat and height fields. The sheet should prevent accidental dismissal when changes exist.

**Primary recommendation:** Use `@FocusState` with `.focused()` modifier and `.task {}` to auto-focus the weight TextField on sheet appear. Implement custom date navigation with left/right arrow buttons instead of DatePicker. Add `interactiveDismissDisabled(hasUnsavedChanges)` with confirmation dialog for discarding changes.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 26+ | Form UI, focus management | Native, first-party framework |
| Foundation | iOS 26+ | Date manipulation, Calendar | Native date operations |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UIKit (UIImpactFeedbackGenerator) | iOS 26+ | Haptic feedback | Already used in current impl for button taps |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom date arrows | DatePicker compact style | DatePicker adds calendar popup complexity; arrows are simpler for day-by-day navigation |
| TextEditor for notes | TextField with axis: .vertical | TextField with axis already used in codebase; provides better integration with Form styling |

## Architecture Patterns

### Recommended View Structure
```
WeightEntryView (sheet)
├── NavigationStack
│   ├── Toolbar (Cancel button)
│   └── ScrollView
│       ├── DateNavigationRow (date with left/right arrows)
│       ├── WeightInputSection (label + TextField + unit suffix)
│       ├── NotesSection (label + expandable TextField)
│       ├── MoreSection (expandable body fat/height fields)
│       └── SaveButton (full-width)
```

### Pattern 1: @FocusState for Auto-Focus
**What:** Property wrapper that enables programmatic focus control
**When to use:** Any view where a TextField should receive focus on appear
**Example:**
```swift
// Source: https://developer.apple.com/documentation/swiftui/view/focused(_:)
enum Field { case weight, notes, bodyFat, height }

@FocusState private var focusedField: Field?
@State private var weightText: String = ""

var body: some View {
    TextField("Weight", text: $weightText)
        .keyboardType(.decimalPad)
        .focused($focusedField, equals: .weight)
        .task {
            focusedField = .weight
        }
}
```

### Pattern 2: Custom Date Navigation with Arrows
**What:** HStack with arrow buttons and date label for day-by-day navigation
**When to use:** When users need simple previous/next day navigation without calendar UI
**Example:**
```swift
// Source: Apple Calendar API patterns
HStack {
    Button {
        date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
    } label: {
        Image(systemName: "chevron.left")
    }

    Text(date, format: .dateTime.weekday().month().day())
        .font(.headline)

    Button {
        guard date < Date.now else { return }
        date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
    } label: {
        Image(systemName: "chevron.right")
    }
    .disabled(Calendar.current.isDateInToday(date))
}
```

### Pattern 3: Expandable Section with Animation
**What:** Button that reveals additional fields with smooth animation
**When to use:** Secondary/optional fields that shouldn't clutter the primary interface
**Example:**
```swift
@State private var showMoreFields = false

if showMoreFields {
    VStack {
        // Body fat and height fields
    }
    .transition(.opacity.combined(with: .move(edge: .top)))
}

Button {
    withAnimation(.spring(duration: 0.3)) {
        showMoreFields.toggle()
    }
} label: {
    Text(showMoreFields ? "Less..." : "More...")
}
```

### Pattern 4: Unsaved Changes Detection
**What:** Track modifications to detect when to show discard confirmation
**When to use:** Any form where accidental dismissal would lose user data
**Example:**
```swift
// Source: https://developer.apple.com/documentation/swiftui/view/interactivedismissdisabled(_:)
@State private var initialWeight: Double
@State private var currentWeight: Double

private var hasUnsavedChanges: Bool {
    currentWeight != initialWeight ||
    note != initialNote ||
    date != initialDate
}

.interactiveDismissDisabled(hasUnsavedChanges)
.confirmationDialog("Discard Changes?", isPresented: $showDiscardDialog) {
    Button("Discard", role: .destructive) { dismiss() }
    Button("Cancel", role: .cancel) { }
}
```

### Anti-Patterns to Avoid
- **Using DatePicker with calendar popup:** Per CONTEXT.md, use arrows only, no calendar
- **Showing validation errors inline:** Per CONTEXT.md, disable save button instead of showing inline error messages
- **Tap-to-dismiss keyboard:** Per CONTEXT.md, keyboard stays visible until save/cancel
- **Using DispatchQueue.main.async:** Project uses strict Swift concurrency; use `.task {}` modifier instead

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Focus management | Custom first responder logic | @FocusState + .focused() | Native SwiftUI solution since iOS 15 |
| Keyboard avoidance | Manual padding/offset calculations | ScrollView (automatic in iOS 14+) | SwiftUI handles keyboard avoidance automatically |
| Date navigation | Custom date math | Calendar.current.date(byAdding:) | Handles edge cases (month boundaries, DST) |
| Character limit | Manual string slicing in binding | .onChange + String.prefix() | Clean, reactive pattern |
| Haptic feedback | Custom UIKit integration | UIImpactFeedbackGenerator (already in project) | Consistent with existing code |

**Key insight:** The current WeightEntryView already has haptic feedback generators, unit validation logic, and HealthKit sync patterns that should be preserved; the redesign is primarily a UI restructuring, not a logic rewrite.

## Common Pitfalls

### Pitfall 1: FocusState Not Working on Appear
**What goes wrong:** TextField doesn't receive focus when sheet opens
**Why it happens:** FocusState set in onAppear may run before TextField is in view hierarchy
**How to avoid:** Use `.task {}` modifier instead of `.onAppear {}` for setting focus
**Warning signs:** Focus works sometimes but not consistently, especially on first appear

### Pitfall 2: Keyboard Avoidance with ScrollView
**What goes wrong:** Content doesn't scroll to keep focused TextField visible above keyboard
**Why it happens:** SwiftUI's automatic keyboard avoidance requires content to be in ScrollView
**How to avoid:** Wrap form content in ScrollView; current implementation already does this
**Warning signs:** Notes field at bottom gets hidden by keyboard

### Pitfall 3: Invalid Weight Text Input
**What goes wrong:** User can type non-numeric characters or multiple decimal points
**Why it happens:** decimalPad keyboard allows paste operations with any text
**How to avoid:** Use TextField with numeric format binding; current implementation uses `.number.precision(.fractionLength(1))` which handles this
**Warning signs:** App crashes on save or shows unexpected values

### Pitfall 4: Date Arrow Allows Future Dates
**What goes wrong:** User navigates to tomorrow and enters weight
**Why it happens:** Right arrow button not properly disabled for current/future dates
**How to avoid:** Check `Calendar.current.isDateInToday(date)` or `date >= Calendar.current.startOfDay(for: Date())`
**Warning signs:** Entries with future timestamps in logbook

### Pitfall 5: Unsaved Changes False Positive
**What goes wrong:** Discard confirmation shows even when user made no real changes
**Why it happens:** Floating point comparison issues or initial value capture timing
**How to avoid:** Capture initial values after view fully initializes; use rounded comparison for weights
**Warning signs:** Users seeing "discard changes?" when they just opened and closed the sheet

### Pitfall 6: interactiveDismissDisabled Without Feedback
**What goes wrong:** User tries to swipe-dismiss, nothing happens, they're confused
**Why it happens:** interactiveDismissDisabled prevents dismiss but provides no visual feedback
**How to avoid:** Show confirmation dialog when dismiss is attempted with unsaved changes
**Warning signs:** Users force-quitting app to exit stuck sheet

## Code Examples

Verified patterns from official sources and existing codebase:

### Auto-Focus Weight TextField on Appear
```swift
// Source: https://developer.apple.com/documentation/swiftui/view/focused(_:)
enum EntryField: Hashable { case weight, notes, bodyFat, height }

@FocusState private var focusedField: EntryField?
@State private var weight: Double

TextField("Weight", value: $weight, format: .number.precision(.fractionLength(1)))
    .font(.system(size: weightFontSize, weight: .medium))
    .keyboardType(.decimalPad)
    .focused($focusedField, equals: .weight)
    .task {
        focusedField = .weight
    }
```

### Weight Input with Unit Suffix Inside Field
```swift
// Source: Current WeightEntryView.swift pattern
HStack(alignment: .firstTextBaseline, spacing: 4) {
    TextField("Weight", value: $weight, format: .number.precision(.fractionLength(1)))
        .font(.system(size: weightFontSize, weight: .medium))
        .keyboardType(.decimalPad)
        .fixedSize()
        .multilineTextAlignment(.trailing)
        .focused($focusedField, equals: .weight)

    Text(weightUnit.rawValue)
        .font(.title)
        .foregroundStyle(.secondary)
}
```

### Notes Field with Character Limit and Counter
```swift
// Source: https://hackingwithswift.com/quick-start/swiftui
private let noteCharacterLimit = 500

@State private var note: String = ""

var charactersRemaining: Int { noteCharacterLimit - note.count }

VStack(alignment: .leading, spacing: 8) {
    Text("Notes")
        .font(.headline)
        .foregroundStyle(.secondary)

    TextField("", text: $note, axis: .vertical)
        .lineLimit(3...6)
        .onChange(of: note) { _, newValue in
            if newValue.count > noteCharacterLimit {
                note = String(newValue.prefix(noteCharacterLimit))
            }
        }

    if charactersRemaining < 50 {
        Text("\(charactersRemaining) characters remaining")
            .font(.caption)
            .foregroundStyle(charactersRemaining < 10 ? .red : .secondary)
    }
}
```

### Date Navigation with Arrows
```swift
// Source: Calendar API + SF Symbols
@State private var date = Date()

private var canNavigateForward: Bool {
    !Calendar.current.isDateInToday(date)
}

HStack {
    Button {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: date) {
            date = newDate
        }
    } label: {
        Image(systemName: "chevron.left")
    }

    Text(date, format: .dateTime.weekday().month().day())
        .font(.headline)
        .frame(maxWidth: .infinity)

    Button {
        if canNavigateForward,
           let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date) {
            date = newDate
        }
    } label: {
        Image(systemName: "chevron.right")
    }
    .disabled(!canNavigateForward)
}
```

### Discard Unsaved Changes Pattern
```swift
// Source: https://developer.apple.com/documentation/swiftui/view/interactivedismissdisabled(_:)
@State private var showDiscardAlert = false

private var hasUnsavedChanges: Bool {
    weight != initialWeight ||
    note != initialNote ||
    !Calendar.current.isDate(date, inSameDayAs: initialDate)
}

.interactiveDismissDisabled(hasUnsavedChanges)
.onChange(of: hasUnsavedChanges) { _, newValue in
    // Track for potential discard alert trigger
}
.alert("Discard Changes?", isPresented: $showDiscardAlert) {
    Button("Discard", role: .destructive) {
        dismiss()
    }
    Button("Keep Editing", role: .cancel) { }
} message: {
    Text("You have unsaved changes that will be lost.")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| WeightAdjustmentButton (+/-) | Direct TextField input | Phase 15 (this redesign) | Simpler, faster weight entry |
| .onAppear for focus | .task modifier | iOS 15+ best practice | More reliable focus timing |
| DispatchQueue.main.async | strict Swift concurrency | Project standard | Thread safety, modern patterns |
| GeometryReader for sizing | containerRelativeFrame | iOS 17+ | Cleaner layout code |

**Deprecated/outdated:**
- WeightAdjustmentButton.swift: Component will be deleted after this phase
- Plus/minus increment controls: Replaced by direct text entry

## Open Questions

Things that couldn't be fully resolved:

1. **Height field unit handling**
   - What we know: WeightUnit exists for lb/kg but no HeightUnit equivalent exists
   - What's unclear: Should height use feet+inches (US) vs cm (metric)? No existing height storage in WeightEntry model
   - Recommendation: Defer height implementation to a follow-up phase; CONTEXT.md mentions body fat and height in "More..." but model doesn't support height yet

2. **interactiveDismissDisabled user feedback**
   - What we know: Modifier prevents swipe dismiss but gives no indication why
   - What's unclear: Best UX for informing user they have unsaved changes when they try to swipe
   - Recommendation: Use presentation detent workaround or show automatic alert when dismiss is attempted

3. **Edit mode date handling**
   - What we know: Current edit mode uses DatePicker with date+time components
   - What's unclear: Should edit mode use the new arrow navigation or keep existing DatePicker?
   - Recommendation: Keep DatePicker for edit mode (allows any date), use arrows only for new entries (day-by-day)

## Sources

### Primary (HIGH confidence)
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/WeightEntryView.swift` - Current implementation analyzed
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/Components/WeightAdjustmentButton.swift` - Component to be removed
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Models/WeightEntry.swift` - Data model reference
- [Apple focused(_:) documentation](https://developer.apple.com/documentation/swiftui/view/focused(_:)) - Official FocusState API
- [Apple interactiveDismissDisabled documentation](https://developer.apple.com/documentation/swiftui/view/interactivedismissdisabled(_:)) - Sheet dismiss control
- [Apple scrollDismissesKeyboard documentation](https://developer.apple.com/documentation/swiftui/view/scrolldismisseskeyboard(_:)) - Keyboard dismiss behavior

### Secondary (MEDIUM confidence)
- [Hacking with Swift - FocusState](https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-focusstate-property-wrapper) - FocusState best practices
- [Hacking with Swift - Character limits](https://www.hackingwithswift.com/forums/swiftui/limit-characters-in-a-textfield/15017) - TextField character limiting
- [Livsy Code - Intercepting Sheet Dismissal](https://livsycode.com/swiftui/intercepting-swiftui-sheet-dismissal/) - Modern dismiss interception patterns
- [Fatbobman - TextField Advanced](https://fatbobman.com/en/posts/textfield-event-focus-keyboard/) - Keyboard and focus patterns

### Tertiary (LOW confidence)
- WebSearch results for date arrow navigation - Community patterns, verify implementation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using only native SwiftUI and Foundation
- Architecture: HIGH - Building on existing codebase patterns
- Pitfalls: HIGH - Based on documented issues and official docs
- Height field: LOW - Model doesn't support height; needs design decision

**Research date:** 2026-01-21
**Valid until:** 2026-02-21 (30 days - stable SwiftUI patterns)
