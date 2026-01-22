# Phase 20: Full Accessibility Support - Research

**Researched:** 2026-01-22
**Domain:** iOS accessibility (VoiceOver, Dynamic Type, WCAG compliance)
**Confidence:** HIGH

## Summary

W8Trackr already has **strong foundational accessibility work** in place. The app includes VoiceOver labels and hints on key components, chart accessibility descriptors, Dynamic Type support using `@ScaledMetric`, and semantic color definitions. However, Phase 20 requires comprehensive audit and enhancement to achieve **WCAG AA compliance** and ensure accessibility across all screens and user flows.

SwiftUI provides excellent built-in accessibility support that automatically applies traits and creates accessibility trees. The standard approach for iOS 26 accessibility involves:

1. **VoiceOver labels/hints** for all interactive elements using `.accessibilityLabel()`, `.accessibilityHint()`, and `.accessibilityValue()`
2. **Chart accessibility** via `AXChartDescriptorRepresentable` protocol (already implemented for WeightTrendChartView)
3. **Dynamic Type** using `@ScaledMetric` property wrapper for custom sizes
4. **Reduce Motion** detection via `@Environment(\.accessibilityReduceMotion)` to disable decorative animations
5. **Touch target verification** ensuring 44×44pt minimum for all interactive elements
6. **Color contrast audits** using Xcode Accessibility Inspector to ensure WCAG AA (4.5:1 for text, 3:1 for large text)
7. **Automated testing** with `performAccessibilityAudit()` in UI tests

**Primary recommendation:** Use Xcode Accessibility Inspector audit feature on all screens to identify issues, then systematically address VoiceOver labels, Dynamic Type edge cases, Reduce Motion support, and color contrast violations. Add automated accessibility tests to prevent regressions.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 26+ | Native accessibility APIs | Built-in accessibility support, automatic trait application |
| Accessibility framework | iOS 26+ | Chart descriptors, announcements | Required for `AXChartDescriptorRepresentable`, `UIAccessibility.post()` |
| XCTest | Xcode 15+ | Automated accessibility testing | `performAccessibilityAudit()` API for automated audits |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| WebAIM Contrast Checker | Web tool | Verify color contrast ratios | Manual verification during design phase |
| Xcode Accessibility Inspector | Xcode 15+ | Runtime accessibility audits | Screen-by-screen accessibility verification |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftUI native | Third-party a11y libraries | No need - SwiftUI provides comprehensive built-in support |
| Manual testing only | Automated accessibility tests | Automation catches regressions, but manual VoiceOver testing still essential |

**Installation:**
No additional packages needed - all accessibility APIs are built into SwiftUI and iOS SDK.

## Architecture Patterns

### Current Accessibility Implementation Status

**Already implemented:**
- Chart accessibility: `WeightTrendChartView` implements `AXChartDescriptorRepresentable`
- VoiceOver labels: 10 view files have accessibility labels/hints (26 occurrences found)
- Dynamic Type: `@ScaledMetric` used in HeroCardView, MilestoneCelebrationView, AnimationModifiers
- Semantic colors: 20 color definitions in Assets.xcassets/Colors/ supporting light/dark mode
- VoiceOver announcements: `UIAccessibility.post(.announcement)` used in MilestoneCelebrationView

**Views with existing accessibility work:**
- WeightTrendChartView (chart descriptor + accessibility summary)
- HeroCardView (`.accessibilityElement(children: .combine)` + descriptive labels)
- LogbookRowView (`.accessibilityLabel()`, `.accessibilityHint()`, `.accessibilityAddTraits(.isButton)`)
- MilestoneCelebrationView (accessibility labels + VoiceOver announcements)
- QuickStatsRow, CurrentWeightView, ToastView, EmptyStateView, SyncStatusView, MilestoneProgressView

### Recommended Patterns

#### Pattern 1: VoiceOver Label Hierarchy
**What:** Combine multi-part UI elements into single accessibility element with descriptive label
**When to use:** Complex views with multiple text labels that should be read as one unit
**Example:**
```swift
// Source: W8Trackr HeroCardView.swift
VStack(spacing: 12) {
    Text("Current Weight")
    Text(formattedWeight)
    Text(weightUnit.displayName)
    Text(changeText)
}
.accessibilityElement(children: .combine)
.accessibilityLabel(accessibilityDescription)
```

**Best practices:**
- Use `.accessibilityElement(children: .combine)` to merge multiple text elements
- Use `.accessibilityElement(children: .ignore)` when providing custom label
- Always test with VoiceOver to ensure reading order makes sense

#### Pattern 2: Chart Accessibility with Audio Graphs
**What:** Implement `AXChartDescriptorRepresentable` to enable VoiceOver chart exploration
**When to use:** Any data visualization using Swift Charts
**Example:**
```swift
// Source: W8Trackr WeightTrendChartView.swift
extension WeightTrendChartView: AXChartDescriptorRepresentable {
    nonisolated func makeChartDescriptor() -> AXChartDescriptor {
        let dateAxis = AXNumericDataAxisDescriptor(
            title: "Date",
            range: minDate...maxDate,
            gridlinePositions: []
        ) { value in
            Date(timeIntervalSince1970: value).formatted(date: .abbreviated, time: .omitted)
        }

        let weightAxis = AXNumericDataAxisDescriptor(
            title: "Weight (\(weightUnit.displayName))",
            range: minWeight...maxWeight,
            gridlinePositions: []
        ) { value in
            "\(value.formatted(.number.precision(.fractionLength(1)))) \(weightUnit.displayName)"
        }

        let dataPoints = entries.map { entry in
            AXDataPoint(
                x: entry.date.timeIntervalSince1970,
                y: entry.weightValue(in: weightUnit),
                label: "\(entry.date.formatted()): \(entry.weightValue(in: weightUnit).formatted())"
            )
        }

        let series = AXDataSeriesDescriptor(
            name: "Weight entries",
            isContinuous: true,
            dataPoints: dataPoints
        )

        return AXChartDescriptor(
            title: "Weight Trend",
            summary: chartAccessibilitySummary,
            xAxis: dateAxis,
            yAxis: weightAxis,
            series: [series]
        )
    }
}

// Apply to chart view
Chart { /* ... */ }
    .accessibilityChartDescriptor(self)
```

**Best practices:**
- Provide meaningful summary string describing overall trend
- Use descriptive axis titles
- Label each data point clearly
- Swift Charts automatically creates audio graphs from this data

#### Pattern 3: Dynamic Type Scaling
**What:** Use `@ScaledMetric` for custom sizes that scale with user's text size preference
**When to use:** Custom font sizes, icon sizes, spacing values
**Example:**
```swift
// Source: W8Trackr HeroCardView.swift
struct HeroCardView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var heroFontSize: CGFloat = 56

    var body: some View {
        Text(formattedWeight)
            .font(.system(size: heroFontSize, weight: .bold, design: .rounded))
    }
}
```

**Best practices:**
- Always specify `relativeTo` parameter to link to text style
- Test at extreme sizes (XXXL accessibility sizes)
- Use `.lineLimit()` and `.minimumScaleFactor()` to prevent clipping
- Prefer SwiftUI's built-in text styles (`.title`, `.body`) over custom sizes when possible

#### Pattern 4: Reduce Motion Support
**What:** Detect Reduce Motion setting and disable decorative animations
**When to use:** All non-essential animations (decorative transitions, confetti, pulsing effects)
**Example:**
```swift
struct MilestoneCelebrationView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack {
            Image(systemName: "trophy.fill")
                .scaleEffect(showContent ? 1.0 : 0.5)
        }
        .animation(reduceMotion ? nil : .spring(), value: showContent)
        .confettiCannon(trigger: reduceMotion ? .constant(0) : $confettiTrigger)
    }
}
```

**Best practices:**
- Use `nil` animation when Reduce Motion is enabled
- Keep essential animations (like navigation transitions)
- Remove repeating/infinite animations completely
- Test with Settings > Accessibility > Motion > Reduce Motion enabled

#### Pattern 5: Touch Target Sizing
**What:** Ensure all interactive elements meet 44×44pt minimum
**When to use:** All buttons, taps, custom controls
**Example:**
```swift
Button("Delete") {
    deleteEntry()
}
.frame(minWidth: 44, minHeight: 44)
.contentShape(Rectangle())
```

**Best practices:**
- Use `.frame(minWidth: 44, minHeight: 44)` on small buttons
- Use `.contentShape(Rectangle())` to expand tap area beyond visible bounds
- Test with Accessibility Inspector's "Show Hit Regions" feature
- Consider larger targets (48-64pt) for critical actions

#### Pattern 6: VoiceOver Announcements for Dynamic Changes
**What:** Post accessibility announcements for important state changes
**When to use:** Milestones, errors, completions, new content loading
**Example:**
```swift
// Source: W8Trackr MilestoneCelebrationView.swift
.onAppear {
    UIAccessibility.post(
        notification: .announcement,
        argument: "Congratulations! You've reached \(Int(milestoneWeight)) \(unit.rawValue) milestone!"
    )
}
```

**Best practices:**
- Keep announcements concise and relevant
- Don't announce every small UI change
- Use `.announcement` for alerts, `.screenChanged` for major navigation
- Test that announcements don't interrupt important VoiceOver reading

### Anti-Patterns to Avoid

- **Using `GeometryReader` for Dynamic Type**: Don't rely on `GeometryReader` for text sizing - use `@ScaledMetric` or built-in text styles
- **Vague accessibility labels**: "Button" is useless - use "Delete weight entry" or "Save changes"
- **Ignoring Reduce Motion**: Always respect this setting - decorative animations can cause motion sickness
- **Small touch targets**: Don't rely on SwiftUI defaults for small icons - explicitly set minimum 44pt
- **Testing only with VoiceOver off**: Accessibility bugs only appear with assistive technologies enabled

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Chart accessibility | Custom audio description strings | `AXChartDescriptorRepresentable` protocol | Swift Charts automatically generates audio graphs, handles exploration gestures |
| Color contrast checking | Manual eyeballing | Xcode Accessibility Inspector audit | Inspector calculates exact contrast ratios, identifies WCAG violations |
| Dynamic Type testing | Manual font size changes | Xcode Accessibility Inspector + Canvas variants | Inspector tests all 12 text size categories, Canvas shows multiple sizes at once |
| Touch target verification | Guessing pixel sizes | Accessibility Inspector "Show Hit Regions" | Visualizes actual tap areas, highlights too-small targets |
| VoiceOver flow testing | Assuming it works | Manual VoiceOver navigation of full flows | Only way to verify reading order, label quality, navigation logic |

**Key insight:** iOS accessibility tools are mature and comprehensive. The hard part is knowing they exist and using them systematically, not building custom solutions.

## Common Pitfalls

### Pitfall 1: Dynamic Type Clipping at Extreme Sizes
**What goes wrong:** Text clips or overflows container at XXXL accessibility text sizes
**Why it happens:** Developers test only at default size, fixed frame heights, horizontal stacks with multiple texts
**How to avoid:**
- Test with largest accessibility sizes (Settings > Accessibility > Display & Text Size > Larger Text)
- Use `.minimumScaleFactor()` as last resort for critical single-line text
- Prefer vertical stacks over horizontal for multi-label layouts
- Use `.lineLimit()` with `.truncationMode()` for long labels
**Warning signs:** Text disappearing, ellipsis appearing where full text should show, horizontal scrolling appearing

### Pitfall 2: Missing VoiceOver Context for Icons
**What goes wrong:** Image-only buttons announce as "Button" with no description
**Why it happens:** SwiftUI can't infer meaning from SF Symbol names
**How to avoid:**
```swift
// Bad
Button {
    deleteEntry()
} label: {
    Image(systemName: "trash")
}

// Good
Button("Delete entry") {
    deleteEntry()
} label: {
    Image(systemName: "trash")
}
// OR
Button {
    deleteEntry()
} label: {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete entry")
```
**Warning signs:** VoiceOver announces "Button" with no context, user can't tell what button does

### Pitfall 3: Animations Causing Motion Sickness
**What goes wrong:** Users with vestibular disorders experience nausea from animations
**Why it happens:** Developers don't test with Reduce Motion enabled, decorative animations run unconditionally
**How to avoid:**
- Always check `@Environment(\.accessibilityReduceMotion)`
- Disable spring animations, scaling effects, rotation, confetti, pulsing
- Keep essential animations (navigation transitions) but reduce intensity
**Warning signs:** Infinite `.repeatForever()` animations, particle effects, 3D rotations without Reduce Motion check

### Pitfall 4: Poor Color Contrast
**What goes wrong:** Text unreadable for users with low vision or color blindness
**Why it happens:** Designing for aesthetics over accessibility, not testing in both light/dark mode
**How to avoid:**
- Run Accessibility Inspector audit on every screen
- Ensure 4.5:1 ratio for normal text (< 18pt or < 14pt bold)
- Ensure 3:1 ratio for large text (≥ 18pt or ≥ 14pt bold)
- Use WebAIM Contrast Checker during design phase
- Test both light and dark mode color combinations
**Warning signs:** Audit fails with "Text Contrast" violations, secondary text hard to read

### Pitfall 5: Ignoring Accessibility Traits
**What goes wrong:** Custom interactive views not recognized as buttons/adjustable controls
**Why it happens:** Using `.onTapGesture()` instead of `Button`, not adding `.accessibilityAddTraits()`
**How to avoid:**
```swift
// Bad - VoiceOver doesn't know this is tappable
Text("Delete")
    .onTapGesture { delete() }

// Good - VoiceOver announces as button
Button("Delete") { delete() }

// Custom control - add trait explicitly
Rectangle()
    .onTapGesture { toggle() }
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel("Toggle setting")
```
**Warning signs:** VoiceOver doesn't say "button", "adjustable", or "header" when expected

### Pitfall 6: Confetti and ConfettiSwiftUI Package with Reduce Motion
**What goes wrong:** W8Trackr uses ConfettiSwiftUI package for milestone celebrations, but it may not respect Reduce Motion
**Why it happens:** Third-party packages may not implement accessibility features
**How to avoid:**
- Conditionally disable confetti cannon when Reduce Motion enabled
- Pass constant binding to prevent trigger when `reduceMotion == true`
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.confettiCannon(
    trigger: reduceMotion ? .constant(0) : $confettiTrigger,
    num: reduceMotion ? 0 : 50
)
```
**Warning signs:** Confetti still animates when Reduce Motion is on

## Code Examples

Verified patterns from W8Trackr codebase and official documentation:

### Complete Accessibility Implementation for Custom Card
```swift
// Source: W8Trackr/Views/Dashboard/HeroCardView.swift
struct HeroCardView: View {
    let currentWeight: Double
    let weightUnit: WeightUnit
    let weeklyChange: Double?

    @ScaledMetric(relativeTo: .largeTitle) private var heroFontSize: CGFloat = 56

    private var accessibilityDescription: String {
        var description = "Current weight: \(formattedWeight) \(weightUnit.displayName)"

        if let changeText = formattedChange {
            let direction = trendDirection == .down ? "down" :
                          trendDirection == .up ? "up" : "stable"
            description += ". \(direction) \(changeText) \(weightUnit.displayName) this week"
        }

        return description
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Current Weight")
                .font(.subheadline)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formattedWeight)
                    .font(.system(size: heroFontSize, weight: .bold, design: .rounded))
                Text(weightUnit.displayName)
                    .font(.title2)
            }
            .fixedSize(horizontal: true, vertical: false)

            if let changeText = formattedChange {
                HStack(spacing: 6) {
                    Image(systemName: trendDirection.icon)
                    Text("\(changeText) \(weightUnit.displayName) this week")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
}
```

### Reduce Motion for Celebration Animations
```swift
// Example for W8Trackr animation views
struct MilestoneCelebrationView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var confettiTrigger: Int = 0
    @State private var showContent = false

    var body: some View {
        VStack {
            Image(systemName: "trophy.fill")
                .scaleEffect(showContent ? 1.0 : 0.5)
                .animation(reduceMotion ? nil : .spring(), value: showContent)
        }
        .confettiCannon(
            trigger: reduceMotion ? .constant(0) : $confettiTrigger,
            num: reduceMotion ? 0 : 50
        )
        .onAppear {
            // Reduce or eliminate animation delays
            let animationDelay = reduceMotion ? 0 : 0.3
            if reduceMotion {
                // Instantly show content
                showContent = true
            } else {
                withAnimation(.spring()) {
                    showContent = true
                }
            }
        }
    }
}
```

### Accessibility-Friendly List Row
```swift
// Source: W8Trackr/Views/Components/LogbookRowView.swift
struct LogbookRowView: View {
    let rowData: LogbookRowData
    var onEdit: (() -> Void)?

    private var accessibilityLabel: String {
        let dateString = rowData.entry.date.formatted(date: .abbreviated, time: .omitted)
        let weightString = "\(rowData.entry.weightValue(in: weightUnit).formatted(.number.precision(.fractionLength(1)))) \(weightUnit.displayName)"

        var label = "\(dateString), \(weightString)"

        if let avg = rowData.movingAverage {
            label += ", 7-day average \(avg.formatted(.number.precision(.fractionLength(1))))"
        }

        if let rate = rowData.weeklyRate {
            let direction = rate > 0 ? "gaining" : "losing"
            label += ", \(direction) \(abs(rate).formatted(.number.precision(.fractionLength(1)))) per week"
        }

        if rowData.hasNote {
            label += ", has note"
        }

        return label
    }

    var body: some View {
        HStack(spacing: 8) {
            dateColumn
            weightColumn
            movingAverageColumn
            weeklyRateColumn
            notesIndicator
        }
        .padding(.vertical, LogbookLayout.rowVerticalPadding)
        .frame(minHeight: LogbookLayout.minRowHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Swipe right to edit, swipe left to delete")
        .accessibilityAddTraits(.isButton)
    }
}
```

### Automated Accessibility Testing
```swift
// Example UI test for W8Trackr
import XCTest

final class W8TrackrAccessibilityTests: XCTestCase {
    func testDashboardAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.exists)
        dashboardTab.tap()

        // Run accessibility audit
        try app.performAccessibilityAudit { issue in
            // Filter out known acceptable issues if needed
            // Return false to mark as failure
            return true
        }
    }

    func testLogbookAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Logbook"].tap()

        // Audit logbook screen
        try app.performAccessibilityAudit()
    }

    func testDynamicTypeScaling() {
        let app = XCUIApplication()
        app.launch()

        // Test with largest accessibility text size
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"]
        app.launch()

        // Verify key elements are still visible and not clipped
        XCTAssertTrue(app.staticTexts["Current Weight"].exists)
        XCTAssertTrue(app.buttons["Add Weight Entry"].exists)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual audio graph creation | `AXChartDescriptorRepresentable` protocol | iOS 15 (2021) | Swift Charts automatically generates audio graphs from descriptor |
| `UIAccessibility` framework only | SwiftUI accessibility modifiers | SwiftUI 1.0 (2019) | Declarative API, automatic trait inference |
| `.accessibility()` single modifier | Specific modifiers (`.accessibilityLabel()`, etc.) | SwiftUI 2.0 (2020) | Better autocomplete, clearer intent |
| `.onTapGesture()` for buttons | `Button` with accessibility built-in | SwiftUI 1.0 (2019) | Automatic button trait, better VoiceOver support |
| `@ObservedObject` for state | `@Observable` macro | iOS 17 (2023) | Cleaner syntax, better performance |
| Manual contrast checking | Accessibility Inspector audit | Xcode 12 (2020) | Automated WCAG violation detection |
| `performAccessibilityAudit()` in UI tests | Added in Xcode 15 (2023) | Catches accessibility issues in CI/CD |

**Deprecated/outdated:**
- `.accessibility(label:)` → Use `.accessibilityLabel()`
- `.accessibility(value:)` → Use `.accessibilityValue()`
- `.accessibility(hint:)` → Use `.accessibilityHint()`
- Manual WCAG calculation → Use Accessibility Inspector for automated audits
- Testing only with VoiceOver → Also use automated `performAccessibilityAudit()` in tests

## Open Questions

Things that couldn't be fully resolved:

1. **ConfettiSwiftUI Package Reduce Motion Compatibility**
   - What we know: W8Trackr uses `ConfettiSwiftUI` for milestone celebrations
   - What's unclear: Whether the package internally respects Reduce Motion settings
   - Recommendation: Test manually with Reduce Motion enabled; if confetti still animates, conditionally disable by passing `.constant(0)` binding and `num: 0` when `reduceMotion == true`

2. **Actual Color Contrast Ratios**
   - What we know: App defines semantic colors in Assets.xcassets/Colors/ with light/dark variants
   - What's unclear: Whether current color combinations meet WCAG AA 4.5:1 ratio
   - Recommendation: Run Accessibility Inspector audit on every screen to identify violations; use fallback hex values in Colors.swift for manual WebAIM Contrast Checker testing

3. **Accessibility Inspector False Positives**
   - What we know: Accessibility Inspector may report false positives
   - What's unclear: Which violations in W8Trackr are real vs. false positives
   - Recommendation: Manually verify each Inspector finding with actual VoiceOver testing before dismissing as false positive

4. **Large Content Viewer for Tab Bar Icons**
   - What we know: iOS 26 supports Large Content Viewer for small UI elements
   - What's unclear: Whether W8Trackr's tab bar icons should implement `.accessibilityShowsLargeContentViewer()`
   - Recommendation: Test tab bar at XXXL text sizes; if icons don't scale, add Large Content Viewer support

## Sources

### Primary (HIGH confidence)
- [Apple Developer Documentation: SwiftUI Accessibility Fundamentals](https://developer.apple.com/documentation/swiftui/accessibility-fundamentals)
- [Apple Developer Documentation: SwiftUI Accessibility Modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [Apple Developer Documentation: Accessibility Inspector](https://developer.apple.com/documentation/accessibility/accessibility-inspector)
- [Apple Developer Documentation: Performing Accessibility Audits](https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app)
- [W3C: WCAG 2.1 Understanding Contrast (Minimum)](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [Apple Developer Documentation: accessibilityChartDescriptor](https://developer.apple.com/documentation/swiftui/view/accessibilitychartdescriptor(_:))
- [Apple Developer Documentation: accessibilityReduceMotion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion)
- [Apple Developer Documentation: AccessibilityTraits](https://developer.apple.com/documentation/swiftui/accessibilitytraits)

### Secondary (MEDIUM confidence)
- [WWDC24: Catch up on accessibility in SwiftUI](https://developer.apple.com/videos/play/wwdc2024/10073/) - Latest SwiftUI accessibility features
- [WWDC23: Perform accessibility audits for your app](https://developer.apple.com/videos/play/wwdc2023/10035/) - Automated audit API introduction
- [WWDC22: Hello Swift Charts](https://developer.apple.com/videos/play/wwdc2022/10136/) - Chart accessibility introduction
- [Create with Swift: Making Charts Accessible](https://www.createwithswift.com/making-charts-accessible-with-swift-charts/) - Chart accessibility tutorial
- [Create with Swift: Supporting Dynamic Type](https://www.createwithswift.com/supporting-dynamic-type-and-larger-text-in-your-app-to-enhance-accessibility/) - Dynamic Type best practices
- [Create with Swift: Reduce Motion Preferences](https://www.createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/) - Reduce Motion implementation
- [Create with Swift: Accessibility Inspector Testing](https://www.createwithswift.com/testing-you-apps-accessibilty-with-the-accessibility-inspector/) - Inspector usage guide
- [Hacking with Swift: Detect Reduce Motion](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting) - Reduce Motion tutorial
- [Hacking with Swift: Preview at Different Dynamic Type Sizes](https://www.hackingwithswift.com/quick-start/swiftui/how-to-preview-your-layout-at-different-dynamic-type-sizes) - Testing Dynamic Type in previews
- [SwiftUI Field Guide: Dynamic Type](https://www.swiftuifieldguide.com/layout/dynamic-type/) - Comprehensive Dynamic Type guide
- [Swift with Majid: Mastering Charts Accessibility](https://swiftwithmajid.com/2023/02/28/mastering-charts-in-swiftui-accessibility/) - Chart accessibility deep dive
- [Orange A11y Guidelines: Swift Charts](https://a11y-guidelines.orange.com/en/mobile/ios/wwdc/nota11y/2022/22Charts/) - Chart accessibility reference
- [GitHub: CVS Health iOS SwiftUI Accessibility Techniques](https://github.com/cvs-health/ios-swiftui-accessibility-techniques) - Practical accessibility examples
- [iOS and iPadOS 26 Accessibility Updates - American Foundation for the Blind](https://afb.org/blog/entry/ios-26-accessibility-features) - iOS 26 accessibility features
- [AppleVis: What's New in iOS 26 Accessibility](https://www.applevis.com/blog/whats-new-ios-26-accessibility-blind-deafblind-users) - VoiceOver updates in iOS 26

### Tertiary (LOW confidence)
- [WebAIM: Contrast Checker](https://webaim.org/resources/contrastchecker/) - Manual contrast ratio verification tool
- [WebAIM: Contrast and Color Accessibility](https://webaim.org/articles/contrast/) - WCAG contrast requirements explained
- [LogRocket: All Accessible Touch Target Sizes](https://blog.logrocket.com/ux-design/all-accessible-touch-target-sizes/) - Touch target sizing across platforms
- [Medium: Mastering SwiftUI Accessibility](https://medium.com/@GetInRhythm/mastering-swiftui-accessibility-a-comprehensive-guide-919358e9c01a) - Comprehensive guide
- [Medium: iOS Accessibility Guidelines 2025](https://medium.com/@david-auerbach/ios-accessibility-guidelines-best-practices-for-2025-6ed0d256200e) - Best practices compilation
- [BBC: VoiceOver Testing Steps](https://bbc.github.io/accessibility-news-and-you/assistive-technology/testing-steps/voiceover-ios.html) - VoiceOver testing methodology
- [BrowserStack: iOS Accessibility Testing](https://www.browserstack.com/guide/accessibility-ios) - Testing guide and tools

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - SwiftUI accessibility APIs are official Apple framework with extensive documentation
- Architecture: HIGH - Existing W8Trackr implementation follows Apple best practices; patterns verified in codebase
- Pitfalls: HIGH - Based on official documentation, community best practices, and real issues found in iOS apps
- Color contrast: MEDIUM - WCAG ratios are definitive, but W8Trackr's actual colors need Accessibility Inspector verification
- iOS 26 features: MEDIUM - iOS 26 accessibility features documented by Apple and accessibility community, but some features not yet fully tested in W8Trackr context
- Third-party package compatibility: LOW - ConfettiSwiftUI package Reduce Motion behavior needs manual testing

**Research date:** 2026-01-22
**Valid until:** 60 days (March 2026) - iOS accessibility APIs are stable; WCAG standards don't change frequently
