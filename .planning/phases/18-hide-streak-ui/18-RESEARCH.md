# Phase 18: Hide Streak UI - Research

**Researched:** 2026-01-21
**Domain:** SwiftUI UI hiding/removal, notification management
**Confidence:** HIGH

## Summary

This phase involves hiding streak-related UI elements from the app for launch while preserving the underlying code for future use. The codebase has well-isolated streak functionality that can be hidden with minimal risk.

The streak UI exists in three main areas:
1. **Dashboard QuickStatsRow** - Streak card showing consecutive logging days
2. **Notifications** - Streak warning notifications in NotificationManager/Scheduler
3. **SettingsView** - Help text mentioning "streak warnings"

Additionally, `StreakCelebrationView` exists in AnimationModifiers.swift but is **already unused** - it was created for potential future use but never integrated into the app flow.

**Primary recommendation:** Hide streak UI through direct code removal/modification rather than feature flags - simpler for a launch-focused change with intent to potentially bring back later.

## Standard Stack

No additional libraries needed. This is pure SwiftUI view modification and notification scheduling changes.

### Core Technologies Used
| Technology | Version | Purpose | Notes |
|------------|---------|---------|-------|
| SwiftUI | iOS 26+ | UI framework | View composition patterns |
| UNUserNotificationCenter | System | Notifications | Already in use |

## Architecture Patterns

### Current Streak Code Organization

The streak functionality is well-organized:

```
W8Trackr/
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift        # Uses streak computed property
│   │   └── QuickStatsRow.swift        # Contains streak card + calculateStreak()
│   ├── Animations/
│   │   └── AnimationModifiers.swift   # StreakCelebrationView (UNUSED)
│   └── SettingsView.swift             # "streak warnings" in help text
└── Managers/
    ├── NotificationManager.swift      # Calls streak warning scheduling
    └── NotificationScheduler.swift    # calculateStreak(), scheduleStreakWarning()
```

### Pattern 1: Component Removal in QuickStatsRow

**What:** Remove streak card from HStack while keeping This Week and To Goal cards
**Where:** `QuickStatsRow.swift` lines 28-35
**Current code:**
```swift
HStack(spacing: 12) {
    // Streak card - REMOVE THIS
    QuickStatCard(
        title: "Streak",
        value: "\(streak)",
        subtitle: streak == 1 ? "day" : "days",
        icon: "flame.fill",
        iconColor: streak >= 7 ? AppColors.warning : AppColors.secondary
    )

    // This week card - KEEP
    // To goal card - KEEP
}
```

### Pattern 2: Remove Unused Computed Properties

**What:** Remove `streak` computed property from DashboardView since it won't be used
**Where:** `DashboardView.swift` lines 61-63
**Current code:**
```swift
private var streak: Int {
    QuickStatsRow.calculateStreak(from: entries)
}
```

### Pattern 3: Disable Notification Scheduling

**What:** Remove streak warning scheduling from updateSmartNotifications()
**Where:** `NotificationManager.swift` lines 167-171
**Current code:**
```swift
// Schedule streak warning if needed
let (shouldWarn, streak) = NotificationScheduler.shouldSendStreakWarning(entries: entries)
if shouldWarn {
    NotificationScheduler.scheduleStreakWarning(streak: streak)
}
```

### Anti-Patterns to Avoid
- **Feature flags for simple hide:** Overkill for a launch-focused change with no A/B testing needs
- **Deleting calculation code:** Keep streak calculation functions in NotificationScheduler and QuickStatsRow for future use
- **Removing tests:** Keep NotificationTests.swift streak tests intact - they validate preserved code

## Don't Hand-Roll

Not applicable for this phase. All changes are straightforward view/notification modifications.

## Common Pitfalls

### Pitfall 1: Breaking QuickStatsRow API
**What goes wrong:** Removing `streak` parameter from QuickStatsRow could break callers
**Why it happens:** DashboardView passes streak to QuickStatsRow
**How to avoid:** Remove the parameter AND update DashboardView call site together
**Warning signs:** Compiler errors about missing arguments

### Pitfall 2: Leaving Orphaned Code
**What goes wrong:** streak property in DashboardView still calculated but unused
**Why it happens:** Removing UI but forgetting computed property that feeds it
**How to avoid:** Remove both the UI AND the computed property in same commit
**Warning signs:** Code review catches unused variables

### Pitfall 3: Incomplete Settings Text Update
**What goes wrong:** Users see "streak warnings" mentioned but can't access feature
**Why it happens:** Only removing notifications, not updating help text
**How to avoid:** Search for all "streak" text in SettingsView
**Warning signs:** User confusion reported

### Pitfall 4: StreakCelebrationView Confusion
**What goes wrong:** Time wasted trying to find where StreakCelebrationView is used
**Why it happens:** It exists but was never integrated
**How to avoid:** Verify it's unused (grep confirms no usage outside its definition)
**Warning signs:** Can't find any view that presents it

## Code Examples

### Example 1: Updated QuickStatsRow (streak removed)
```swift
// Source: QuickStatsRow.swift - proposed change
struct QuickStatsRow: View {
    // Remove: let streak: Int
    let weeklyChange: Double?
    let toGoal: Double
    let weightUnit: WeightUnit

    var body: some View {
        HStack(spacing: 12) {
            // Streak card REMOVED

            // This week card (unchanged)
            if let change = weeklyChange {
                // ... existing code
            }

            // To goal card (unchanged)
            // ... existing code
        }
    }
}
```

### Example 2: Updated DashboardView Call Site
```swift
// Source: DashboardView.swift - proposed change
QuickStatsRow(
    // Remove: streak: streak,
    weeklyChange: weeklyChange,
    toGoal: toGoal,
    weightUnit: preferredWeightUnit
)
```

### Example 3: Disabled Streak Notifications
```swift
// Source: NotificationManager.swift - proposed change
func updateSmartNotifications(entries: [WeightEntry], goalWeight: Double, unit: WeightUnit) {
    guard isReminderEnabled && isSmartRemindersEnabled else { return }

    // Update suggested reminder time (unchanged)
    // ...

    // REMOVED: Streak warning scheduling
    // let (shouldWarn, streak) = NotificationScheduler.shouldSendStreakWarning(entries: entries)
    // if shouldWarn {
    //     NotificationScheduler.scheduleStreakWarning(streak: streak)
    // }

    // Milestone notification (unchanged)
    // Weekly summary (unchanged)
}
```

### Example 4: Updated Settings Help Text
```swift
// Source: SettingsView.swift - proposed change
Text("Get personalized notifications including milestone alerts and weekly summaries based on your logging habits.")
// Removed: "streak warnings, " from the text
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| N/A | First implementation | N/A | This is initial hiding |

**Design decision:** Hide rather than delete. The streak feature:
- Was implemented thoughtfully with proper calculation logic
- Has passing tests
- May be valuable for future engagement features
- Can be re-enabled by reversing these changes

## Scope Boundaries

### In Scope
1. Remove streak card from QuickStatsRow
2. Remove streak parameter from QuickStatsRow struct
3. Remove streak computed property from DashboardView
4. Remove streak parameter from DashboardView's QuickStatsRow call
5. Comment out/remove streak warning scheduling in NotificationManager
6. Update SettingsView help text to remove "streak warnings" mention
7. Update QuickStatsRow documentation comment showing layout
8. Update DashboardView documentation comment showing layout
9. Update QuickStatsRow previews to remove streak parameter

### Out of Scope (Keep for Future)
1. `calculateStreak()` in QuickStatsRow - KEEP (calculation logic)
2. `calculateStreak()` in NotificationScheduler - KEEP (calculation logic)
3. `shouldSendStreakWarning()` in NotificationScheduler - KEEP (logic)
4. `scheduleStreakWarning()` in NotificationScheduler - KEEP (scheduling logic)
5. `NotificationID.streakWarning` enum case - KEEP (identifier)
6. `StreakCelebrationView` in AnimationModifiers - KEEP (never was used anyway)
7. Streak-related tests in NotificationTests.swift - KEEP (validates preserved code)

### Verification: StreakCelebrationView Usage
```
# Grep results confirm it's only defined and previewed, never instantiated:
W8Trackr/Views/Animations/AnimationModifiers.swift:192:struct StreakCelebrationView: View {
W8Trackr/Views/Animations/AnimationModifiers.swift:427:    StreakCelebrationView(streakCount: 7) { }  # Preview only
W8Trackr/Views/Animations/AnimationModifiers.swift:431:    StreakCelebrationView(streakCount: 30) { }  # Preview only
```

**Conclusion:** StreakCelebrationView requires no changes - it's already unused.

## Open Questions

None. The scope is clear and implementation is straightforward.

## Sources

### Primary (HIGH confidence)
- Direct codebase analysis of:
  - `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/Dashboard/QuickStatsRow.swift`
  - `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/Dashboard/DashboardView.swift`
  - `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/SettingsView.swift`
  - `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Managers/NotificationManager.swift`
  - `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Managers/NotificationScheduler.swift`
  - `/Users/will/Projects/Saults/W8Trackr/W8Trackr/Views/Animations/AnimationModifiers.swift`
  - `/Users/will/Projects/Saults/W8Trackr/W8TrackrTests/NotificationTests.swift`

### Grep Analysis
- `streak` pattern search across entire codebase (15 files)
- `StreakCelebration` usage verification (confirmed unused)

## Metadata

**Confidence breakdown:**
- Scope identification: HIGH - direct code analysis
- Implementation approach: HIGH - straightforward view/API changes
- Risk assessment: HIGH - well-isolated changes

**Research date:** 2026-01-21
**Valid until:** N/A (codebase-specific, not library-dependent)

## Files to Modify

| File | Changes |
|------|---------|
| `QuickStatsRow.swift` | Remove streak parameter, remove streak card from body, update previews, update doc comment |
| `DashboardView.swift` | Remove streak computed property, remove streak from QuickStatsRow call, update doc comment |
| `NotificationManager.swift` | Remove/comment streak warning scheduling (lines 167-171) |
| `SettingsView.swift` | Update smartRemindersSection footer text (line 325) |

**Files to NOT modify (keep calculation code):**
- `NotificationScheduler.swift` - Keep all streak functions
- `AnimationModifiers.swift` - StreakCelebrationView already unused
- `NotificationTests.swift` - Keep streak tests
