# Phase 17: Next Milestone UI - Research

**Researched:** 2026-01-21
**Domain:** SwiftUI Progress Indicators, UI Design, Milestone Visualization
**Confidence:** HIGH

## Summary

This phase improves the `MilestoneProgressView` with a redesigned visual approach. The current implementation uses a circular progress ring with `.trim(from: 0, to: progress)`, but the success criteria explicitly requires a "progress bar fills left-to-right (not right-to-left)" which indicates a shift to a **linear horizontal progress bar** design.

The codebase has an established design system from Phase 5/6 (AppColors, AppGradients, AppTheme) that should be leveraged for consistency. The `GoalPredictionView` and `HeroCardView` provide design language references for card styling, and `TrendCalculator` already computes velocity data that can inform additional contextual information.

**Primary recommendation:** Replace the circular progress ring with a horizontal linear progress bar using SwiftUI's `Gauge` with `.linearCapacity` style or a custom capsule-based progress bar. Enhance with contextual information like days-to-milestone estimate and weekly rate display.

## Standard Stack

All requirements use built-in SwiftUI - no additional libraries needed.

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SwiftUI Gauge | iOS 16+ | Linear progress display | Native component with .linearCapacity style |
| AppColors | Custom | Semantic colors | Established Phase 5, light/dark adaptive |
| AppGradients | Custom | Background gradients | Established pattern for visual polish |
| AppTheme | Custom | Spacing, typography, radii | Consistent design system |

### Supporting
| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| LinearGradient | Progress bar fill | Gradient from start to progress point |
| Capsule() | Progress bar shape | Rounded ends for modern iOS feel |
| @ScaledMetric | Dynamic sizing | Accessibility-friendly sizing |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Gauge | Custom capsule progress | More customization control, more code |
| Custom ProgressView | Gauge | Gauge has built-in range labels |
| Circular ring | Linear bar | Requirement specifies left-to-right (linear) |

**Installation:** No additional packages required.

## Architecture Patterns

### Recommended Approach: Linear Progress Bar

The current `MilestoneProgressView` uses a circular ring. The requirement "progress bar fills left-to-right" clearly indicates a linear horizontal design.

**Current (circular):**
```swift
Circle()
    .trim(from: 0, to: animatedProgress)
    .stroke(progressGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
    .rotationEffect(.degrees(-90))
```

**Recommended (linear):**
```swift
GeometryReader { geometry in
    ZStack(alignment: .leading) {
        // Background track
        Capsule()
            .fill(AppColors.surfaceSecondary)

        // Filled progress
        Capsule()
            .fill(progressGradient)
            .frame(width: geometry.size.width * progress)
    }
}
.frame(height: 12)
```

### Recommended Project Structure
```
Views/Goals/
├── MilestoneProgressView.swift    # Redesigned with linear bar
├── MilestoneCelebrationView.swift # Unchanged
└── (existing files)
```

### Pattern 1: Linear Progress Bar with Gradient
**What:** Horizontal capsule that fills left-to-right with gradient
**When to use:** Showing progress toward next milestone
**Example:**
```swift
// Source: iOS HIG recommends linear progress for determinate tasks
private var progressBar: some View {
    GeometryReader { geometry in
        ZStack(alignment: .leading) {
            // Background track
            Capsule()
                .fill(AppColors.surfaceSecondary)

            // Filled progress with animation
            Capsule()
                .fill(AppGradients.progressPositive)
                .frame(width: max(0, geometry.size.width * animatedProgress))
                .animation(.easeOut(duration: 0.5), value: animatedProgress)
        }
    }
    .frame(height: barHeight)
}
```

### Pattern 2: SwiftUI Gauge with Linear Style
**What:** Native Gauge component with linearCapacity style
**When to use:** When you need built-in min/max labels
**Example:**
```swift
// Source: SwiftUI documentation for Gauge
Gauge(value: progress.progressToNextMilestone) {
    Text("Progress")
} currentValueLabel: {
    Text(progress.weightToNextMilestone, format: .number.precision(.fractionLength(1)))
} minimumValueLabel: {
    Text(progress.previousMilestone, format: .number.precision(.fractionLength(0)))
} maximumValueLabel: {
    Text(progress.nextMilestone, format: .number.precision(.fractionLength(0)))
}
.gaugeStyle(.linearCapacity)
.tint(AppGradients.success)
```

### Pattern 3: Enhanced Card with Contextual Info
**What:** Progress bar plus additional metrics (days estimate, rate)
**When to use:** Making the view more informative
**Example:**
```swift
// Source: Based on GoalPredictionView pattern
VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
    // Header
    Text("Next Milestone")
        .font(.headline)

    // Progress bar
    progressBar

    // Progress label row
    HStack {
        Text(progress.previousMilestone, format: .number.precision(.fractionLength(0)))
            .font(.caption)
            .foregroundStyle(.secondary)
        Spacer()
        Text("\(progress.weightToNextMilestone, specifier: "%.1f") \(progress.unit.rawValue) to go")
            .font(.caption)
            .fontWeight(.medium)
        Spacer()
        Text(progress.nextMilestone, format: .number.precision(.fractionLength(0)))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // Optional: Estimated days if trend data available
    if let estimatedDays = estimatedDaysToMilestone {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.caption2)
            Text("~\(estimatedDays) days at current pace")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}
.padding()
.background(AppColors.surface)
.clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
.cardShadow()
```

### Anti-Patterns to Avoid
- **Keeping circular ring:** Requirement explicitly says "left-to-right" which is linear
- **Right-to-left filling:** Ensure progress fills from leading edge toward trailing edge
- **Hardcoded colors:** Use AppColors/AppGradients for theme consistency
- **Fixed font sizes:** Use Dynamic Type for accessibility

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Progress bar styling | Custom gradient logic | AppGradients.progressPositive | Already defined, consistent |
| Card shadows | Manual shadow() values | .cardShadow() modifier | AppTheme consistency |
| Corner radii | Magic numbers (10, 12) | AppTheme.CornerRadius.md | Design system |
| Days calculation | Manual date math | TrendCalculator velocity data | Already computes rate |

**Key insight:** Phase 5/6 established the theming infrastructure. Use existing AppColors, AppGradients, AppTheme patterns rather than creating new styling.

## Common Pitfalls

### Pitfall 1: Progress Direction Confusion
**What goes wrong:** Bar fills right-to-left instead of left-to-right
**Why it happens:** Incorrect frame/alignment logic in custom progress bar
**How to avoid:**
- Use `ZStack(alignment: .leading)` with width-based frame
- Test with RTL languages to ensure proper behavior
**Warning signs:** Progress appears to shrink as user gets closer to goal

### Pitfall 2: Animation Jarring on Value Change
**What goes wrong:** Progress jumps instead of smooth transition
**Why it happens:** Missing animation modifier or wrong animation value
**How to avoid:**
- Use `@State private var animatedProgress` initialized to 0
- Animate in `onAppear` and `onChange(of: progress.progressToNextMilestone)`
- Use `.animation(.easeOut(duration: 0.5), value: animatedProgress)`
**Warning signs:** Test by adding entries that change progress

### Pitfall 3: Gauge Tint Not Showing Gradient
**What goes wrong:** Gauge shows solid color instead of gradient
**Why it happens:** Gauge's `.tint()` modifier accepts ShapeStyle but gradient may not render as expected
**How to avoid:**
- If using Gauge, test gradient rendering thoroughly
- If gradient is important, use custom Capsule-based progress bar instead
**Warning signs:** Visual doesn't match mockup/expectations

### Pitfall 4: Missing Accessibility
**What goes wrong:** VoiceOver doesn't convey progress meaningfully
**Why it happens:** No accessibility labels on custom views
**How to avoid:**
- Add `.accessibilityElement(children: .combine)`
- Add `.accessibilityLabel("Progress toward \(milestone) milestone: \(percentage)%")`
- Add `.accessibilityValue()` for progress value
**Warning signs:** Test with VoiceOver enabled

### Pitfall 5: Layout Issues on Different Screen Sizes
**What goes wrong:** Progress bar too wide or text truncated on small screens
**Why it happens:** Fixed widths or missing flexible layout
**How to avoid:**
- Use `frame(maxWidth: .infinity)` for full-width bars
- Use `.minimumScaleFactor(0.8)` for text that might truncate
- Test on iPhone SE and iPad
**Warning signs:** Check simulator with smallest and largest devices

## Code Examples

Verified patterns from existing codebase:

### Example 1: Full MilestoneProgressView Redesign
```swift
// Source: Based on existing MilestoneProgressView.swift and HeroCardView patterns
struct MilestoneProgressView: View {
    let progress: MilestoneProgress
    let onMilestoneReached: (() -> Void)?

    @State private var animatedProgress: Double = 0
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 12

    init(progress: MilestoneProgress, onMilestoneReached: (() -> Void)? = nil) {
        self.progress = progress
        self.onMilestoneReached = onMilestoneReached
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header row
            HStack {
                Text("Next Milestone")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Text(progress.nextMilestone, format: .number.precision(.fractionLength(0)))
                        .fontWeight(.bold)
                    Text(progress.unit.rawValue)
                }
                .font(.subheadline)
                .foregroundStyle(AppColors.primary)
            }

            // Linear progress bar
            progressBar

            // Labels row
            HStack {
                Text(progress.previousMilestone, format: .number.precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Text(progress.weightToNextMilestone, format: .number.precision(.fractionLength(1)))
                        .fontWeight(.semibold)
                    Text("\(progress.unit.rawValue) to go")
                }
                .font(.caption)
                Spacer()
                Text(progress.nextMilestone, format: .number.precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
        .cardShadow()
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress.progressToNextMilestone
            }
        }
        .onChange(of: progress.progressToNextMilestone) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
            if newValue >= 1.0 {
                onMilestoneReached?()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next milestone \(Int(progress.nextMilestone)) \(progress.unit.rawValue). \(Int(animatedProgress * 100))% complete. \(progress.weightToNextMilestone.formatted(.number.precision(.fractionLength(1)))) \(progress.unit.rawValue) remaining.")
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(AppColors.surfaceSecondary)

                // Filled progress with gradient
                Capsule()
                    .fill(AppGradients.progressPositive)
                    .frame(width: max(0, geometry.size.width * animatedProgress))
            }
        }
        .frame(height: barHeight)
    }
}
```

### Example 2: Compact Variant with Linear Bar
```swift
// Source: Based on existing MilestoneProgressCompactView
struct MilestoneProgressCompactView: View {
    let progress: MilestoneProgress

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(progress.weightToNextMilestone, specifier: "%.1f") \(progress.unit.rawValue) to next milestone")
                    .font(.subheadline)
                    .fontWeight(.medium)

                // Compact progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.surfaceSecondary)
                        Capsule()
                            .fill(AppColors.primary)
                            .frame(width: geometry.size.width * progress.progressToNextMilestone)
                    }
                }
                .frame(height: 6)

                Text("Goal: \(progress.nextMilestone, specifier: "%.0f") \(progress.unit.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
        .cardShadow()
        .padding(.horizontal)
    }
}
```

### Example 3: Adding Estimated Days (Optional Enhancement)
```swift
// Source: TrendCalculator already provides velocity data
// This shows how to compute estimated days to milestone
private var estimatedDaysToMilestone: Int? {
    // This would require passing TrendCalculator data or computing from entries
    // For now, could be added as optional enhancement
    guard let weeklyVelocity = trendVelocity, weeklyVelocity < 0 else { return nil }
    let dailyVelocity = abs(weeklyVelocity) / 7
    guard dailyVelocity > 0 else { return nil }
    return Int(progress.weightToNextMilestone / dailyVelocity)
}

// Usage in view:
if let days = estimatedDaysToMilestone {
    HStack(spacing: 4) {
        Image(systemName: "calendar")
            .font(.caption2)
        Text("~\(days) days at current pace")
            .font(.caption)
    }
    .foregroundStyle(.secondary)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Circular progress rings | Linear progress bars | iOS design trend | Better for goal tracking, clearer "toward goal" visual |
| Single progress value | Progress with context | UX best practice | More informative (estimated time, rate) |
| Static colors | Trend-based coloring | Phase 6 | Visual feedback at a glance |

**Deprecated/outdated:**
- Circular rings for goal progress: Linear bars more clearly show "journey from A to B"
- Progress without context: Modern apps show estimated time, rate, additional metrics

## Existing Infrastructure

### AppColors Available
- `AppColors.primary` - Friendly sky blue
- `AppColors.success` - Fresh green (#2ECC71)
- `AppColors.warning` - Amber (#F39C12)
- `AppColors.surface` - Card background
- `AppColors.surfaceSecondary` - Progress track background

### AppGradients Available
- `AppGradients.progressPositive` - Coral to green (ideal for milestone progress)
- `AppGradients.success` - Green gradient
- `AppGradients.primary` - Coral gradient

### AppTheme Available
- `AppTheme.Spacing.sm` (12pt), `.md` (16pt)
- `AppTheme.CornerRadius.md` (12pt)
- `.cardShadow()` view modifier

### TrendCalculator Available
- `TrendCalculator.calculateHolt()` - Returns velocity for predictions
- `GoalPrediction.weeklyVelocity` - Already computed in dashboard

## Open Questions

1. **Estimated Days Display**
   - What we know: TrendCalculator already computes weekly velocity
   - What's unclear: Should MilestoneProgressView receive velocity data or compute it?
   - Recommendation: For v1, show progress bar only. Estimated days can be a future enhancement requiring additional prop or TrendCalculator integration.

2. **Compact vs Full Variant**
   - What we know: Both `MilestoneProgressView` and `MilestoneProgressCompactView` exist
   - What's unclear: Should compact also get linear bar?
   - Recommendation: Update both for consistency. Compact uses shorter bar height (6pt vs 12pt).

3. **Progress Bar Height**
   - What we know: Current circular ring uses 12pt stroke
   - What's unclear: Optimal height for linear bar
   - Recommendation: Use @ScaledMetric with base 12pt for full, 6pt for compact

## Sources

### Primary (HIGH confidence)
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/Goals/MilestoneProgressView.swift` - Current implementation
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Theme/Colors.swift` - AppColors definitions
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Theme/Gradients.swift` - AppGradients definitions
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Theme/AppTheme.swift` - Design system
- `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/Dashboard/HeroCardView.swift` - Design pattern reference
- [Apple HIG - Progress Indicators](https://developer.apple.com/design/human-interface-guidelines/progress-indicators) - "Progress bars include a track that fills from the leading side to the trailing side"
- [SwiftUI Gauge Documentation](https://developer.apple.com/documentation/swiftui/gauge)

### Secondary (MEDIUM confidence)
- [Hacking with Swift - ProgressView](https://www.hackingwithswift.com/quick-start/swiftui/how-to-show-progress-on-a-task-using-progressview) - SwiftUI progress patterns
- [Sarunw - SwiftUI Circular Progress Bar](https://sarunw.com/posts/swiftui-circular-progress-bar/) - Custom progress implementation patterns
- [AppCoda - SwiftUI Gauge](https://www.appcoda.com/swiftui-gauge/) - Gauge styling options

### Tertiary (LOW confidence)
- Fitness app UI design patterns from Dribbble/Figma - Visual inspiration

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All changes use existing SwiftUI patterns and established design system
- Architecture: HIGH - Simple replacement of circular with linear, existing patterns apply
- Pitfalls: HIGH - Based on direct SwiftUI knowledge and existing codebase patterns

**Research date:** 2026-01-21
**Valid until:** Stable (SwiftUI layout patterns unlikely to change)

## Planning Recommendations

### Suggested Plan Structure

**Single Plan Recommended:** This is a focused UI component redesign with clear scope.

**Task Order:**
1. Update `MilestoneProgressView` with linear progress bar
2. Update `MilestoneProgressCompactView` with linear progress bar
3. Add accessibility labels
4. Test animations and edge cases
5. Verify dark mode appearance

**Estimated Complexity:**
- MilestoneProgressView redesign: Medium (replace circular with linear, update layout)
- MilestoneProgressCompactView: Low (same pattern, smaller)
- Accessibility: Low (add labels)
- Testing: Low (verify animations, dark mode)

**Total estimated effort:** 1-2 hours implementation + testing

### Verification Steps
1. Build and run - no compile errors
2. Verify progress bar fills left-to-right as weight decreases toward milestone
3. Verify animation is smooth on progress change
4. Verify card styling matches app design language (AppColors, shadows, radii)
5. Test in both light and dark mode
6. Verify VoiceOver reads progress information correctly
7. Test on iPhone SE (smallest) and iPad (largest) screen sizes
8. Run SwiftLint - zero warnings
