# Phase 10: Weight Entry UI Redesign - Research

**Researched:** 2026-01-20
**Domain:** iOS Weight Entry UI/UX, SwiftUI Input Controls
**Confidence:** MEDIUM

## Summary

Research into weight entry UI patterns reveals that the most effective approaches combine **direct numeric input** with **rapid adjustment controls** - exactly what the current implementation attempts, but with better visual design. The fitness app ecosystem shows three dominant patterns: (1) wheel pickers for selection from discrete values, (2) sliding ruler controls for continuous values with precision, and (3) enhanced text fields with stepper buttons.

The current W8Trackr implementation uses pattern #3 (TextField + adjustment buttons) which is fundamentally sound for weight entry where users need 0.1 unit precision across a large range. The issue is purely visual - the media transport icons (backward.circle.fill, forward.end.circle.fill) are semantically wrong for weight adjustment.

**Primary recommendation:** Enhance the existing TextField + stepper button pattern with proper visual design (plus/minus icons with clear increment labels), rather than switching to a wheel picker or slider which would trade off precision and accessibility.

## Standard Stack

### Core (Native SwiftUI - No External Dependencies)

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| TextField | iOS 18+ | Direct numeric input | Precise entry, accessibility-ready, supports keyboard |
| Button | iOS 18+ | Increment/decrement actions | Clear touch targets, haptic feedback |
| UIImpactFeedbackGenerator | iOS 18+ | Haptic feedback | Native feel, already used in app |
| @ScaledMetric | iOS 18+ | Dynamic Type support | Already used in app, required for accessibility |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom buttons | Picker (.wheel) | Wheel picker requires discrete values; cannot do 0.1 precision across 1-1500 lb range without 15,000 options |
| Custom buttons | Stepper | SwiftUI Stepper has fixed tiny touch targets, poor accessibility, limited customization |
| Custom buttons | Slider | Slider lacks precision for 0.1 increments; difficult to hit exact values |
| Custom buttons | SlidingRuler (3rd party) | Good UX but adds external dependency; beta status; accessibility incomplete |
| TextField | Multi-component Picker | Requires UIKit wrapper; complex for lb.oz or kg precision; overkill for decimal weights |

**No external dependencies recommended.** All solutions achievable with native SwiftUI.

## Architecture Patterns

### Recommended Component Structure

```
WeightInputControl/
├── WeightInputView.swift         # Main container with TextField + buttons
├── WeightAdjustmentButton.swift  # Reusable increment/decrement button
└── (shared with onboarding)      # FirstWeightStepView uses same control
```

### Pattern 1: Enhanced Stepper Control

**What:** A custom stepper-like control with variable increment buttons around a central TextField.

**When to use:** Weight entry requiring 0.1 unit precision across large range.

**Visual Layout:**
```
        ┌─────────────────────────────────┐
        │         175.4 lb                │  <- Large, tappable TextField
        └─────────────────────────────────┘
    [-1]    [-0.1]         [+0.1]    [+1]   <- Clearly labeled buttons
```

**Key design elements:**
- Large central display (current 64pt scaled font is appropriate)
- Four buttons with CLEAR increment labels (not abstract icons)
- Light haptic for 0.1 changes, medium haptic for 1.0 changes (already implemented)
- Visual distinction between fine and coarse adjustments

### Pattern 2: Button Visual Hierarchy

**What:** Use SF Symbols and colors to distinguish adjustment magnitudes.

| Adjustment | Icon | Style | Haptic |
|------------|------|-------|--------|
| -1.0 | minus.circle.fill | Larger, AppColors.primary | Medium |
| -0.1 | minus.circle | Smaller, AppColors.secondary | Light |
| +0.1 | plus.circle | Smaller, AppColors.secondary | Light |
| +1.0 | plus.circle.fill | Larger, AppColors.primary | Medium |

**Why:** Plus/minus icons are universally understood; filled vs outline indicates magnitude.

### Pattern 3: Optional Long-Press Acceleration

**What:** Hold increment button to continue adjusting automatically with increasing speed.

**Implementation hints:**
- Start at 0.5s delay, then accelerate
- Stop on touch up or boundary reached
- Consider DragGesture for scrubbing behavior

### Anti-Patterns to Avoid

- **Media transport icons:** backward.circle.fill suggests "rewind" not "decrease" - semantically confusing
- **Wheel picker for continuous values:** Would need 15,000+ options for 0.1 precision; laggy scrolling
- **Slider without snap points:** Too imprecise for weight tracking
- **Hiding increment values:** Users should see what each button does (+1, +0.1) without guessing
- **Small touch targets:** Buttons must be at least 44x44 points per Apple HIG

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Haptic feedback | Custom haptic patterns | UIImpactFeedbackGenerator (.light, .medium) | Already works, native feel |
| Dynamic Type | Manual font scaling | @ScaledMetric | System handles all cases |
| Number formatting | String interpolation | .number.precision(.fractionLength(1)) | Locale-aware, handles edge cases |
| Keyboard dismissal | Custom gestures | .scrollDismissesKeyboard(.interactively) | Native behavior expected |
| Input validation | Manual range checks | WeightUnit.isValidWeight() | Already exists in codebase |

**Key insight:** The existing WeightUnit type already handles all validation, conversion, and bounds checking. The redesign is purely visual/interaction - the data layer is solid.

## Common Pitfalls

### Pitfall 1: Wheel Picker Performance
**What goes wrong:** Creating a Picker with thousands of options causes scroll lag and memory issues.
**Why it happens:** Developers try to use wheel picker for weight (0.1 increments from 1-1500 = 14,990 options).
**How to avoid:** Use TextField + increment buttons for continuous ranges; wheel pickers only for small discrete sets.
**Warning signs:** Picker scrolling feels slow; memory warnings in console.

### Pitfall 2: Accessibility Afterthought
**What goes wrong:** VoiceOver users can't adjust weight or hear current value clearly.
**Why it happens:** Custom controls don't get automatic accessibility support.
**How to avoid:**
- Add `.accessibilityLabel()` to every button with clear description ("Decrease by 1 pound")
- Add `.accessibilityValue()` to display current weight
- Consider `.accessibilityAdjustableAction()` for swipe-to-adjust behavior
- Test with VoiceOver during development, not after
**Warning signs:** Buttons announce only "button" without context.

### Pitfall 3: Dynamic Type Breaks Layout
**What goes wrong:** Large text sizes cause buttons to overlap or text to truncate.
**Why it happens:** Fixed spacing values don't scale with text.
**How to avoid:**
- Use @ScaledMetric for all spacing and icon sizes (already done for fonts)
- Test with .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
- Prefer VStack layouts that can reflow
**Warning signs:** UI looks fine in default size but breaks at AX3 Large.

### Pitfall 4: TextField Focus Issues
**What goes wrong:** User taps adjustment buttons but keyboard stays open; or keyboard dismissed makes it hard to enter precise value.
**Why it happens:** Conflicting focus states between TextField and Button taps.
**How to avoid:**
- Consider @FocusState to manage keyboard visibility explicitly
- Buttons should work without dismissing keyboard
- Add done/dismiss button in keyboard toolbar
**Warning signs:** Erratic keyboard behavior during entry.

### Pitfall 5: Unit Conversion on Display
**What goes wrong:** Converting display value on unit change loses precision or shows wrong value.
**Why it happens:** Rounding errors in lb/kg conversion compound.
**How to avoid:** Store canonical value; only display converted. Current implementation is correct - WeightEntry stores value in original unit.
**Warning signs:** Switching lb/kg back and forth changes displayed value.

## Code Examples

### Example 1: Accessible Adjustment Button (Recommended Pattern)

```swift
// Source: Apple HIG + existing WeightAdjustButton pattern
struct WeightAdjustButton: View {
    let amount: Double  // e.g., 1.0 or 0.1
    let unitLabel: String  // e.g., "lb" or "kg"
    let isIncrease: Bool
    let action: () -> Void

    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 44
    @ScaledMetric(relativeTo: .caption) private var labelSize: CGFloat = 12

    private var iconName: String {
        if isIncrease {
            return amount >= 1.0 ? "plus.circle.fill" : "plus.circle"
        } else {
            return amount >= 1.0 ? "minus.circle.fill" : "minus.circle"
        }
    }

    private var accessibilityDescription: String {
        let direction = isIncrease ? "Increase" : "Decrease"
        return "\(direction) by \(amount.formatted()) \(unitLabel)"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: iconSize))
                    .foregroundStyle(amount >= 1.0 ? AppColors.primary : AppColors.secondary)

                Text(isIncrease ? "+\(amount.formatted())" : "-\(amount.formatted())")
                    .font(.system(size: labelSize, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double-tap to adjust weight")
    }
}
```

### Example 2: Weight Input Container Layout

```swift
// Source: Based on current WeightEntryView with improved layout
struct WeightInputSection: View {
    @Binding var weight: Double
    let weightUnit: WeightUnit

    @ScaledMetric(relativeTo: .largeTitle) private var weightFontSize: CGFloat = 64
    @State private var lightFeedback = UIImpactFeedbackGenerator(style: .light)
    @State private var mediumFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack(spacing: 20) {
            // Central weight display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("Weight", value: $weight, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: weightFontSize, weight: .medium))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .fixedSize()

                Text(weightUnit.rawValue)
                    .font(.title)
                    .foregroundStyle(.secondary)
            }

            // Adjustment buttons row
            HStack(spacing: 24) {
                WeightAdjustButton(amount: 1.0, unitLabel: weightUnit.rawValue, isIncrease: false) {
                    mediumFeedback.impactOccurred()
                    weight = max(weightUnit.minWeight, weight - 1.0)
                }

                WeightAdjustButton(amount: 0.1, unitLabel: weightUnit.rawValue, isIncrease: false) {
                    lightFeedback.impactOccurred()
                    weight = max(weightUnit.minWeight, weight - 0.1)
                }

                WeightAdjustButton(amount: 0.1, unitLabel: weightUnit.rawValue, isIncrease: true) {
                    lightFeedback.impactOccurred()
                    weight = min(weightUnit.maxWeight, weight + 0.1)
                }

                WeightAdjustButton(amount: 1.0, unitLabel: weightUnit.rawValue, isIncrease: true) {
                    mediumFeedback.impactOccurred()
                    weight = min(weightUnit.maxWeight, weight + 1.0)
                }
            }
        }
    }
}
```

### Example 3: VoiceOver Adjustable Action

```swift
// Source: Apple Accessibility Documentation
// For power users who want swipe-to-adjust behavior
VStack {
    // ... weight display ...
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Weight")
.accessibilityValue("\(weight.formatted()) \(weightUnit.rawValue)")
.accessibilityAdjustableAction { direction in
    switch direction {
    case .increment:
        weight = min(weightUnit.maxWeight, weight + 0.1)
    case .decrement:
        weight = max(weightUnit.minWeight, weight - 0.1)
    @unknown default:
        break
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom keyboard views | Native .decimalPad + stepper buttons | iOS 15+ | Less code, better accessibility |
| UIPickerView wrapper | Pure SwiftUI where possible | iOS 17+ | Simpler, fewer bridging issues |
| Manual haptics | .sensoryFeedback modifier | iOS 17+ | Declarative, cleaner code |
| ObservableObject | @Observable macro | iOS 17+ | Already migrated in app |

**Deprecated/outdated:**
- **Custom number pad keyboards:** Unnecessary complexity; native keyboards work well with accessibility
- **SlidingRuler library:** Beta status, incomplete accessibility; not production-ready
- **Multi-component UIPickerView:** Overkill for decimal weight entry

## Open Questions

1. **Long-press acceleration**
   - What we know: Common pattern in iOS steppers for rapid adjustment
   - What's unclear: Whether it's worth the implementation complexity for weight entry (users rarely need to adjust by 50+ lbs)
   - Recommendation: Skip for v1; add later if user feedback requests it

2. **5-lb / 0.5-lb increments**
   - What we know: Current implementation has 1.0 and 0.1 increments
   - What's unclear: Whether users would benefit from additional increment options (5 lbs for larger adjustments)
   - Recommendation: Start with current 1.0/0.1 pattern; monitor feedback

3. **Visual styling details**
   - What we know: Need to match app's AppColors/AppTheme design system
   - What's unclear: Exact visual design (button backgrounds, spacing ratios, animations)
   - Recommendation: Iterate on visual design in implementation; keep UX pattern stable

## Sources

### Primary (HIGH confidence)
- Apple Human Interface Guidelines - Accessibility (touch targets, VoiceOver)
- Apple Developer Documentation - SwiftUI Picker, Stepper
- Existing W8Trackr codebase patterns (WeightUnit, AppColors, @ScaledMetric usage)

### Secondary (MEDIUM confidence)
- [iOS Accessibility Best Practices](https://medium.com/@david-auerbach/ios-accessibility-guidelines-best-practices-for-2025-6ed0d256200e) - Touch target guidelines
- [SwiftUI Picker Tutorial](https://www.rootstrap.com/blog/swiftui-picker-a-complete-tutorial) - Picker limitations for large ranges
- [SlidingRuler GitHub](https://github.com/Pyroh/SlidingRuler) - Alternative approach evaluated (beta, incomplete accessibility)
- [Hacking with Swift - Haptics](https://www.hackingwithswift.com/books/ios-swiftui/adding-haptic-effects) - Haptic feedback patterns
- [VoiceOver Best Practices](https://medium.com/capital-one-tech/ios-accessibility-best-practices-for-the-voiceover-user-experience-dc08112ef16) - accessibilityAdjustableAction patterns

### Tertiary (LOW confidence - industry observation)
- MyFitnessPal app - Uses "+" button on progress card, likely TextField-based entry
- Happy Scale app - Uses "+" button, imports from Health, simple logging UI
- Withings app - Primarily automated via smart scale sync; manual entry is secondary

**Note:** Direct UI inspection of competitor apps was not performed; conclusions based on support documentation and user descriptions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Native SwiftUI patterns, no external dependencies
- Architecture: HIGH - Evolution of existing working pattern
- Pitfalls: MEDIUM - Based on iOS accessibility guidelines and common patterns
- Visual design: LOW - Specific styling recommendations need iteration

**Research date:** 2026-01-20
**Valid until:** 2026-03-20 (60 days - patterns are stable)
