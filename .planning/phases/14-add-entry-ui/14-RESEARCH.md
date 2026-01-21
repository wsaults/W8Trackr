# Phase 14: Add Entry UI - Research

**Researched:** 2026-01-21
**Domain:** iOS 26 SwiftUI TabView Bottom Accessory / Liquid Glass
**Confidence:** HIGH

## Summary

iOS 26 introduces the `.tabViewBottomAccessory()` modifier for placing custom views above the tab bar, similar to Apple Music's "Now Playing" control. The accessory automatically receives Liquid Glass styling with a capsule background. When combined with `.tabBarMinimizeBehavior(.onScrollDown)`, the tab bar collapses during scrolling and the accessory slides inline with the minimized tab button.

The current W8Trackr implementation has a floating action button (FAB) in `DashboardView.swift` (lines 100-104, 208-223) that needs to be removed and replaced with a tab bar accessory in `ContentView.swift`. The existing `WeightEntryView` sheet presentation pattern will be preserved.

**Primary recommendation:** Apply `.tabViewBottomAccessory` and `.tabBarMinimizeBehavior(.onScrollDown)` to the TabView in ContentView.swift, move state management for the sheet there, and remove the FAB from DashboardView.swift.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 26 | Tab bar accessory API | Native Apple API for this exact use case |
| UIKit | iOS 26 | Haptic feedback | `UIImpactFeedbackGenerator` for button feedback |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SF Symbols | System | Icons | "plus" symbol for add button |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `.tabViewBottomAccessory` | Custom overlay/FAB | FAB doesn't integrate with tab bar minimize, feels dated on iOS 26 |
| `.onScrollDown` minimize | No minimize | Wastes screen real estate during content scrolling |

**Installation:**
No additional packages required - pure SwiftUI/UIKit.

## Architecture Patterns

### Recommended Project Structure

The tab bar accessory should be applied at the TabView level (ContentView.swift), not at individual tab views.

```
ContentView.swift         # TabView + .tabViewBottomAccessory + sheet
  |-- DashboardView       # Remove FAB overlay
  |-- LogbookView         # Keep toolbar + button (different context)
  |-- SettingsView        # No changes
```

### Pattern 1: Tab Bar Bottom Accessory

**What:** A custom view placed above the tab bar that gets automatic Liquid Glass styling.

**When to use:** For actions relevant across all tabs (like Apple Music's Now Playing).

**Example:**
```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-tabview-accessory
TabView {
    Tab("Dashboard", systemImage: "gauge") {
        DashboardView()
    }
    // ... more tabs
}
.tabViewBottomAccessory {
    Button {
        showAddWeightView = true
    } label: {
        Image(systemName: "plus")
    }
}
.tabBarMinimizeBehavior(.onScrollDown)
```

### Pattern 2: State Management at TabView Level

**What:** Sheet presentation state must live in ContentView since the accessory is there.

**When to use:** When presenting sheets from tab bar accessories.

**Example:**
```swift
// Source: Verified pattern from multiple sources
struct ContentView: View {
    @State private var showAddWeightView = false

    var body: some View {
        TabView {
            // tabs...
        }
        .tabViewBottomAccessory {
            Button {
                showAddWeightView = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add weight entry")
        }
        .sheet(isPresented: $showAddWeightView) {
            WeightEntryView(entries: entries, weightUnit: preferredWeightUnit)
        }
    }
}
```

### Pattern 3: Minimize Behavior

**What:** Tab bar automatically collapses when user scrolls down, accessory slides inline.

**When to use:** Apps with scrollable content in tabs.

**Example:**
```swift
// Source: https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/
TabView {
    // tabs with scrollable content
}
.tabBarMinimizeBehavior(.onScrollDown)
```

### Anti-Patterns to Avoid

- **Applying accessory to individual tabs:** The accessory must be on the TabView, not nested views.
- **Custom Liquid Glass styling on accessory:** Let the system handle the capsule background automatically.
- **Using `.presentationBackground()` on sheets:** Prevents Liquid Glass styling from applying to iOS 26 sheets.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Capsule button background | Manual `.background()` with blur | Liquid Glass automatic styling | System handles material, blur, corner radius |
| Tab bar scroll collapse | Manual scroll detection + animation | `.tabBarMinimizeBehavior(.onScrollDown)` | Complex gesture coordination, spring animations |
| Accessory positioning | Manual ZStack overlay | `.tabViewBottomAccessory` | System handles safe area, orientation, minimize transitions |

**Key insight:** iOS 26 Liquid Glass design language handles visual complexity automatically. Manual styling will look inconsistent and won't animate correctly with system behaviors.

## Common Pitfalls

### Pitfall 1: Accessory Visible on All Tabs

**What goes wrong:** The tab bar accessory appears on every tab, not just one.
**Why it happens:** This is expected behavior - Apple's design intent (like Music app's Now Playing).
**How to avoid:** Accept this behavior. For W8Trackr, add entry is useful from any tab.
**Warning signs:** If you try conditional rendering, the accessory may flash or animate unexpectedly.

### Pitfall 2: Padding Issues When Minimized

**What goes wrong:** The button appears slightly cut off when the tab bar is minimized.
**Why it happens:** Known beta issue reported by multiple sources.
**How to avoid:** Accept current behavior; likely fixed in final iOS 26 release.
**Warning signs:** Visual clipping at bottom edge of accessory content.

### Pitfall 3: tabViewBottomAccessoryPlacement Not Working

**What goes wrong:** Trying to detect `.inline` vs `.expanded` placement fails.
**Why it happens:** API documented but not functioning in beta versions.
**How to avoid:** Don't rely on placement detection for conditional content.
**Warning signs:** Environment value always returns nil or inconsistent values.

### Pitfall 4: Sheet Presentation Scope

**What goes wrong:** Sheet doesn't present when triggered from accessory.
**Why it happens:** `.sheet()` modifier placed on wrong view in hierarchy.
**How to avoid:** Place `.sheet()` modifier on the TabView or at same level as accessory.
**Warning signs:** Button tap does nothing, no sheet appears.

### Pitfall 5: Missing Data for WeightEntryView

**What goes wrong:** WeightEntryView needs `entries` and `weightUnit` which are currently in individual tabs.
**Why it happens:** State scoping - DashboardView has the data, ContentView needs it for the accessory.
**How to avoid:** ContentView already has `@Query` for entries and `@AppStorage` for unit - pass these to the sheet.
**Warning signs:** Compiler errors about missing arguments.

## Code Examples

Verified patterns from official sources:

### Basic Tab Bar Accessory with Button
```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-tabview-accessory
TabView {
    Tab("Tab 1", systemImage: "1.circle") {
        List(0..<100) { i in
            Text("Row \(i)")
        }
    }
}
.tabViewBottomAccessory {
    Button("Add exercise") {
        // action
    }
}
```

### Icon-Only Accessory Button with Accessibility
```swift
// Source: Synthesized from multiple verified sources
.tabViewBottomAccessory {
    Button {
        showAddWeightView = true
    } label: {
        Image(systemName: "plus")
            .font(.title2)
            .fontWeight(.semibold)
    }
    .accessibilityLabel("Add weight entry")
    .accessibilityHint("Opens form to log a new weight measurement")
}
```

### Full TabView with Minimize Behavior
```swift
// Source: https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/
TabView {
    Tab("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent") {
        DashboardView(/* ... */)
    }
    Tab("Logbook", systemImage: "book") {
        LogbookView(/* ... */)
    }
    Tab("Settings", systemImage: "gear") {
        SettingsView(/* ... */)
    }
}
.tabViewBottomAccessory {
    Button { /* action */ } label: {
        Image(systemName: "plus")
    }
}
.tabBarMinimizeBehavior(.onScrollDown)
.sheet(isPresented: $showAddWeightView) {
    WeightEntryView(entries: entries, weightUnit: preferredWeightUnit)
}
```

### Current FAB Implementation (To Be Removed)
```swift
// Location: DashboardView.swift lines 208-223
// This entire section will be removed:
private var fabButton: some View {
    Button {
        showAddWeightView.toggle()
    } label: {
        Image(systemName: "plus")
            .font(.title3)
            .foregroundStyle(.white)
            .fontWeight(.bold)
            .padding()
            .background(AppGradients.blue)
            .clipShape(Circle())
            .shadow(color: Color(hex: "#4A90D9").opacity(0.4), radius: 8, x: 0, y: 4)
    }
    .accessibilityLabel("Add weight entry")
    .accessibilityHint("Opens form to log a new weight measurement")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| FAB overlay in ZStack | Tab bar bottom accessory | iOS 26 (2025) | Native integration with tab bar, Liquid Glass styling |
| Static tab bar | `.tabBarMinimizeBehavior(.onScrollDown)` | iOS 26 (2025) | More content visible when scrolling |
| Manual blur effects | Liquid Glass automatic | iOS 26 (2025) | Consistent system appearance |

**Deprecated/outdated:**
- Manual FAB implementations: Tab bar accessory is the iOS 26 standard pattern
- Custom blur backgrounds: Liquid Glass supersedes manual material styling

## Open Questions

Things that couldn't be fully resolved:

1. **Haptic Feedback on Accessory Button Tap**
   - What we know: The existing FAB doesn't have haptic feedback; WeightEntryView has it for +/- buttons
   - What's unclear: Whether iOS 26 provides system haptics for Liquid Glass buttons automatically
   - Recommendation: Test without custom haptics first; add UIImpactFeedbackGenerator if needed

2. **Accent Color in Liquid Glass Context**
   - What we know: Context specifies "Match app's accent color for the icon tint"
   - What's unclear: Whether `.tint()` or `.foregroundStyle()` works correctly in Liquid Glass capsule
   - Recommendation: Use `.tint(AppColors.primary)` or `.foregroundStyle(AppColors.primary)` and verify visually

3. **SummaryView.swift Status**
   - What we know: SummaryView also has a FAB (lines 101-112) but may not be in active use
   - What's unclear: Whether SummaryView is still part of the app or legacy code
   - Recommendation: Verify with DashboardView being the active tab; remove SummaryView FAB if it exists

## Sources

### Primary (HIGH confidence)
- [Hacking with Swift - TabView Bottom Accessory](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-tabview-accessory) - Complete API reference and examples
- [Donny Wals - Tab Bars on iOS 26 with Liquid Glass](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/) - Minimize behavior, design philosophy
- [Nil Coalescing - Liquid Glass Sheets in SwiftUI](https://nilcoalescing.com/blog/PresentingLiquidGlassSheetsInSwiftUI/) - Sheet presentation patterns

### Secondary (MEDIUM confidence)
- [Create with Swift - Tab Bar Bottom Accessory](https://www.createwithswift.com/enhancing-the-tab-bar-with-a-bottom-accessory/) - Additional examples, placement API notes
- WebSearch results - Multiple sources confirming API behavior

### Tertiary (LOW confidence)
- `tabViewBottomAccessoryPlacement` environment key - Documented but reportedly not working in beta

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Native SwiftUI APIs verified across multiple authoritative sources
- Architecture: HIGH - Pattern consistent across all sources, clear placement requirements
- Pitfalls: MEDIUM - Some issues (padding, placement detection) may be resolved in final iOS 26

**Research date:** 2026-01-21
**Valid until:** 2026-02-21 (30 days - stable iOS 26 API, may need update if beta issues are fixed)
