# Phase 9: Milestone Intervals - Research

**Researched:** 2026-01-20
**Domain:** SwiftUI Settings, @AppStorage persistence, milestone calculation
**Confidence:** HIGH

## Summary

This phase adds user customization for milestone celebration intervals. The current implementation uses a hardcoded 5 lb / 2 kg interval in `MilestoneCalculator.interval(for:)`. The feature requires:

1. A new enum `MilestoneInterval` to represent interval choices
2. `@AppStorage` persistence following existing patterns
3. A segmented Picker in SettingsView (matching existing UI patterns)
4. Updates to `MilestoneCalculator` to use the stored preference

The implementation is straightforward because the codebase already has established patterns for enum-based `@AppStorage` preferences (see `WeightUnit` usage) and segmented pickers (see Weight Unit, Date Range selectors).

**Primary recommendation:** Use a simple enum with preset intervals (5 lb, 10 lb, 15 lb) stored via `@AppStorage`, avoiding "custom" free-form input to minimize complexity.

## Standard Stack

The existing codebase stack handles all requirements - no new dependencies needed.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 26+ | UI and @AppStorage | Native framework, already used throughout |
| SwiftData | iOS 26+ | CompletedMilestone persistence | Already configured for milestones |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation | iOS 26+ | UserDefaults backing for @AppStorage | Automatic |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Preset enum | Stepper for custom values | Custom adds complexity, edge cases, no clear user need |
| @AppStorage | SwiftData model | Overkill for single preference value |

## Architecture Patterns

### Recommended File Structure
```
W8Trackr/Models/
├── Milestone.swift          # Add MilestoneInterval enum here
│   ├── MilestoneInterval    # NEW: enum with preset intervals
│   ├── CompletedMilestone   # Existing: no changes needed
│   ├── MilestoneProgress    # Existing: no changes needed
│   └── MilestoneCalculator  # UPDATE: use stored interval
W8Trackr/Views/
└── SettingsView.swift       # ADD: milestoneIntervalSection
```

### Pattern 1: Enum with @AppStorage (Existing Pattern)

**What:** Store enum preference using rawValue-based @AppStorage
**When to use:** Simple preferences with fixed options
**Example:**
```swift
// Source: ContentView.swift, OnboardingView.swift - existing pattern
enum MilestoneInterval: String, CaseIterable {
    case five = "5"
    case ten = "10"
    case fifteen = "15"

    var pounds: Double {
        switch self {
        case .five: return 5.0
        case .ten: return 10.0
        case .fifteen: return 15.0
        }
    }

    /// Equivalent kg value (rounded for clean display)
    var kilograms: Double {
        switch self {
        case .five: return 2.0    // 5 lb ≈ 2.27 kg, rounded to 2
        case .ten: return 5.0     // 10 lb ≈ 4.54 kg, rounded to 5
        case .fifteen: return 7.0 // 15 lb ≈ 6.80 kg, rounded to 7
        }
    }

    func value(for unit: WeightUnit) -> Double {
        switch unit {
        case .lb: return pounds
        case .kg: return kilograms
        }
    }

    /// Display label for picker
    func displayLabel(for unit: WeightUnit) -> String {
        let value = self.value(for: unit)
        return "\(Int(value)) \(unit.rawValue)"
    }
}

// Usage in view:
@AppStorage("milestoneInterval") var milestoneInterval: MilestoneInterval = .five
```

### Pattern 2: Segmented Picker in Settings Form (Existing Pattern)

**What:** Use segmented picker for small number of options
**When to use:** 2-5 options in a settings context
**Example:**
```swift
// Source: SettingsView.swift - Weight Unit picker pattern
Section {
    Picker("Milestone Interval", selection: $milestoneInterval) {
        ForEach(MilestoneInterval.allCases, id: \.self) { interval in
            Text(interval.displayLabel(for: weightUnit))
        }
    }
    .pickerStyle(.segmented)
} header: {
    Text("Milestones")
} footer: {
    Text("How often you'll receive milestone celebrations as you progress toward your goal.")
}
```

### Anti-Patterns to Avoid
- **Free-form TextField for interval:** Too many edge cases (0, negative, very large values)
- **Storing interval per-unit separately:** Unnecessary complexity - single enum handles both units
- **Migrating existing CompletedMilestones on interval change:** Completed milestones are historical records - do not delete or modify them

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Enum persistence | Custom UserDefaults code | `@AppStorage` with `String` rawValue enum | Built-in, type-safe |
| Picker UI in Form | Custom toggle/buttons | `Picker` with `.segmented` style | Native, accessible, consistent |
| Unit conversion in display | Manual string formatting | `displayLabel(for:)` method on enum | Centralized, testable |

**Key insight:** The codebase already has the exact patterns needed - follow `WeightUnit` and the Weight Unit picker exactly.

## Common Pitfalls

### Pitfall 1: Changing Interval Invalidates Progress Ring

**What goes wrong:** User at 178 lb with 5 lb intervals (next: 175). Changes to 10 lb intervals. Now next milestone jumps to 170, breaking UX.
**Why it happens:** `MilestoneCalculator.generateMilestones()` regenerates based on new interval.
**How to avoid:** This is acceptable behavior. The progress ring shows progress toward the NEXT milestone with the current settings. Document this in UI footer text.
**Warning signs:** User confusion if not explained in footer text.

### Pitfall 2: Kg Intervals Don't Match Lb Exactly

**What goes wrong:** 5 lb = 2.27 kg, not 2 kg. Users switching units see different interval spacing.
**Why it happens:** Metric system doesn't align perfectly with imperial.
**How to avoid:** Use rounded kg values (2, 5, 7 kg) that are meaningful in metric. Users understand these are "roughly equivalent" intervals.
**Warning signs:** Users who switch units frequently may notice milestones at slightly different weights.

### Pitfall 3: Storing Interval as Double Instead of Enum

**What goes wrong:** Future maintenance burden - arbitrary values, no type safety.
**Why it happens:** Seems simpler to just store `5.0` or `10.0`.
**How to avoid:** Use enum with preset cases. Enums are future-proof (can add cases, rename, etc.).
**Warning signs:** If you're tempted to use TextField or Stepper, reconsider.

### Pitfall 4: Breaking @AppStorage Key Naming

**What goes wrong:** Key mismatch between views causes inconsistent state.
**Why it happens:** Typos or inconsistent naming.
**How to avoid:** Use a single source of truth - define the key as a constant or use identical string in all locations.
**Warning signs:** Settings not persisting or reverting unexpectedly.

## Code Examples

### Complete MilestoneInterval Enum

```swift
// Source: Project convention - matches WeightUnit pattern
/// Configurable interval for milestone celebrations
enum MilestoneInterval: String, CaseIterable {
    case five = "5"
    case ten = "10"
    case fifteen = "15"

    /// Interval value in pounds
    var pounds: Double {
        switch self {
        case .five: return 5.0
        case .ten: return 10.0
        case .fifteen: return 15.0
        }
    }

    /// Interval value in kilograms (rounded for clean UX)
    var kilograms: Double {
        switch self {
        case .five: return 2.0    // ~2.27 kg
        case .ten: return 5.0     // ~4.54 kg
        case .fifteen: return 7.0 // ~6.80 kg
        }
    }

    /// Get interval value for the specified unit
    func value(for unit: WeightUnit) -> Double {
        switch unit {
        case .lb: return pounds
        case .kg: return kilograms
        }
    }

    /// Display label showing value and unit
    func displayLabel(for unit: WeightUnit) -> String {
        let value = Int(self.value(for: unit))
        return "\(value) \(unit.rawValue)"
    }
}
```

### Updated MilestoneCalculator.interval(for:)

```swift
// Source: Existing Milestone.swift - modify to accept interval parameter
enum MilestoneCalculator {
    /// Milestone interval by unit, using user preference
    static func interval(for unit: WeightUnit, preference: MilestoneInterval = .five) -> Double {
        preference.value(for: unit)
    }

    /// Generate all milestone targets between start and goal weights
    static func generateMilestones(
        startWeight: Double,
        goalWeight: Double,
        unit: WeightUnit,
        intervalPreference: MilestoneInterval = .five
    ) -> [Double] {
        let interval = interval(for: unit, preference: intervalPreference)
        // ... rest of existing logic unchanged
    }
}
```

### Settings Section

```swift
// Source: SettingsView.swift pattern
private var milestoneSection: some View {
    Section {
        Picker("Celebration Interval", selection: $milestoneInterval) {
            ForEach(MilestoneInterval.allCases, id: \.self) { interval in
                Text(interval.displayLabel(for: weightUnit))
            }
        }
        .pickerStyle(.segmented)
    } header: {
        Text("Milestones")
    } footer: {
        Text("Celebrate every \(milestoneInterval.displayLabel(for: weightUnit)) of progress toward your goal.")
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded 5 lb / 2 kg | User-selectable interval | This phase | Core feature addition |

**Deprecated/outdated:**
- None - this is a new feature

## Open Questions

Things that couldn't be fully resolved:

1. **Should the picker update labels when unit changes?**
   - What we know: Picker is bound to `milestoneInterval`, labels call `displayLabel(for: weightUnit)`
   - What's unclear: Does SwiftUI automatically re-render picker options when `weightUnit` changes?
   - Recommendation: Test this during implementation. If not automatic, add `.id(weightUnit)` modifier to force re-render.

2. **Should interval change trigger recalculation of "near milestone" badges?**
   - What we know: The 0.5 lb tolerance (from Phase 8) is for detection, not interval-dependent
   - What's unclear: UX when user changes interval mid-journey
   - Recommendation: Keep tolerance fixed at 0.5 lb regardless of interval. Document behavior.

## Sources

### Primary (HIGH confidence)
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Models/Milestone.swift` - Current implementation
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/SettingsView.swift` - Existing settings patterns
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Models/WeightEntry.swift` - `WeightUnit` enum pattern
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/ContentView.swift` - `@AppStorage` usage

### Secondary (MEDIUM confidence)
- [SwiftUI @AppStorage with Enums](https://developermemos.com/posts/enums-appstorage-swiftui/) - Verified pattern matches codebase usage
- [SwiftUI Picker Best Practices](https://sarunw.com/posts/swiftui-form-picker-styles/) - Segmented style recommendation

### Tertiary (LOW confidence)
- None - all patterns verified against codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using only existing frameworks
- Architecture: HIGH - Follows exact patterns from codebase
- Pitfalls: MEDIUM - Some edge cases need implementation-time verification

**Research date:** 2026-01-20
**Valid until:** 60 days (stable feature, no external dependencies)
