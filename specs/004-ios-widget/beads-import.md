# iOS Home Screen Widget - Beads Import

**Feature**: 004-ios-widget
**Generated**: 2025-01-09
**Source**: specs/004-ios-widget/tasks.md

## Epic Structure

```
iOS Home Screen Widget (epic)
├── Setup (epic) - 7 tasks
├── Foundational (epic) - 9 tasks ← blocks all US*
├── US1: View Current Weight (epic) - 17 tasks 🎯 MVP
├── US2: Goal Progress (epic) - 13 tasks
├── US3: Quick Entry (epic) - 11 tasks
└── Polish (epic) - 10 tasks ← depends on US1-3
```

## Create Commands

Run these commands to create the beads hierarchy:

```bash
# =============================================================================
# ROOT EPIC
# =============================================================================
bd create "iOS Home Screen Widget" -t epic -p 1 -d "Add iOS home screen widget displaying current weight and goal progress with tap-to-open functionality"

# =============================================================================
# PHASE 1: SETUP (7 tasks)
# =============================================================================
bd create "Setup: Project Infrastructure" -t epic -p 1 -d "Create widget extension target and configure App Groups"

bd create "Add Widget Extension target W8TrackrWidget to W8Trackr.xcodeproj" -t task -p 1 -d "File → New → Target → Widget Extension"
bd create "Configure App Groups for W8Trackr target" -t task -p 1 -d "group.com.saults.W8Trackr in Signing & Capabilities"
bd create "Configure App Groups for W8TrackrWidget target" -t task -p 1 -d "group.com.saults.W8Trackr in Signing & Capabilities"
bd create "Create Shared/ folder at project root" -t task -p 1 -d "Shared code between targets"
bd create "Add WeightEntry.swift to W8TrackrWidget target membership" -t task -p 1 -d "File Inspector → Target Membership"
bd create "Add WeightUnit enum to W8TrackrWidget target membership" -t task -p 1 -d "Already in WeightEntry.swift"
bd create "Configure URL scheme w8trackr in Info.plist" -t task -p 1 -d "W8Trackr/Info.plist CFBundleURLTypes"

# =============================================================================
# PHASE 2: FOUNDATIONAL (9 tasks) - BLOCKS ALL USER STORIES
# =============================================================================
bd create "Foundational: Shared Data Access" -t epic -p 1 -d "Core data sharing infrastructure. Blocks all user stories."

# Tests first (TDD)
bd create "Create SharedModelContainerTests.swift with failing tests" -t task -p 1 -d "W8TrackrTests/SharedModelContainerTests.swift"
bd create "Create PreferenceMigrationTests.swift with failing tests" -t task -p 1 -d "W8TrackrTests/PreferenceMigrationTests.swift"

# Implementation
bd create "Create SharedModelContainer.swift with App Group config" -t task -p 1 -d "Shared/DataAccess/SharedModelContainer.swift"
bd create "Create WeightEntry+Widget.swift with computed properties" -t task -p 1 -d "Shared/Extensions/WeightEntry+Widget.swift"
bd create "Update W8TrackrApp.swift to use SharedModelContainer.shared" -t task -p 1 -d "W8TrackrApp.swift"
bd create "Add preference migration call in W8TrackrApp.init()" -t task -p 1 -d "W8TrackrApp.swift"
bd create "Add SharedModelContainer.swift to both targets" -t task -p 1 -d "Target membership configuration"
bd create "Add WeightEntry+Widget.swift to both targets" -t task -p 1 -d "Target membership configuration"
bd create "Verify foundational tests pass" -t task -p 1 -d "Run T008, T009 tests"

# =============================================================================
# PHASE 3: US1 - VIEW CURRENT WEIGHT (17 tasks) 🎯 MVP
# =============================================================================
bd create "US1: View Current Weight at a Glance" -t epic -p 1 -d "Display current weight on home screen widget in user's preferred unit. MVP milestone."

# Tests first (TDD)
bd create "US1: Create WidgetProviderTests.swift - placeholder entry test" -t task -p 1 -d "W8TrackrTests/WidgetProviderTests.swift"
bd create "US1: Add test for snapshot with weight data" -t task -p 1 -d "W8TrackrTests/WidgetProviderTests.swift"
bd create "US1: Add test for snapshot with empty data" -t task -p 1 -d "W8TrackrTests/WidgetProviderTests.swift"
bd create "US1: Add test for unit conversion display" -t task -p 1 -d "W8TrackrTests/WidgetProviderTests.swift"

# Implementation
bd create "US1: Create WidgetEntry.swift with WeightWidgetEntry struct" -t task -p 1 -d "W8TrackrWidget/Models/WidgetEntry.swift"
bd create "US1: Create WeightWidgetProvider.swift with TimelineProvider" -t task -p 1 -d "W8TrackrWidget/Provider/WeightWidgetProvider.swift"
bd create "US1: Implement placeholder(in:) method" -t task -p 1 -d "W8TrackrWidget/Provider/WeightWidgetProvider.swift"
bd create "US1: Implement getSnapshot(in:completion:) method" -t task -p 1 -d "W8TrackrWidget/Provider/WeightWidgetProvider.swift"
bd create "US1: Implement getTimeline with 4-hour refresh" -t task -p 1 -d "W8TrackrWidget/Provider/WeightWidgetProvider.swift"
bd create "US1: Implement fetchCurrentEntry() to query SwiftData" -t task -p 1 -d "W8TrackrWidget/Provider/WeightWidgetProvider.swift"
bd create "US1: Create SmallWidgetView.swift with weight display" -t task -p 1 -d "W8TrackrWidget/Views/SmallWidgetView.swift"
bd create "US1: Add empty state view in SmallWidgetView" -t task -p 1 -d "W8TrackrWidget/Views/SmallWidgetView.swift"
bd create "US1: Add entry timestamp display" -t task -p 1 -d "W8TrackrWidget/Views/SmallWidgetView.swift"
bd create "US1: Create W8TrackrWidget.swift with Widget config" -t task -p 1 -d "W8TrackrWidget/W8TrackrWidget.swift"
bd create "US1: Add containerBackground for light/dark mode" -t task -p 1 -d "W8TrackrWidget/Views/SmallWidgetView.swift"
bd create "US1: Add accessibility labels for VoiceOver" -t task -p 1 -d "W8TrackrWidget/Views/SmallWidgetView.swift"
bd create "US1: Verify US1 tests pass" -t task -p 1 -d "Run T017-T020 tests"

# =============================================================================
# PHASE 4: US2 - GOAL PROGRESS (13 tasks)
# =============================================================================
bd create "US2: See Progress Toward Goal" -t epic -p 2 -d "Show goal progress on widget when user has goal weight set"

# Tests first (TDD)
bd create "US2: Add test for goal progress calculation" -t task -p 2 -d "W8TrackrTests/WidgetProviderTests.swift"
bd create "US2: Add test for goal reached state" -t task -p 2 -d "W8TrackrTests/WidgetProviderTests.swift"
bd create "US2: Add test for no goal set (nil)" -t task -p 2 -d "W8TrackrTests/WidgetProviderTests.swift"

# Implementation
bd create "US2: Add goalWeight and distanceToGoal properties" -t task -p 2 -d "W8TrackrWidget/Models/WidgetEntry.swift"
bd create "US2: Add goalReached computed property" -t task -p 2 -d "W8TrackrWidget/Models/WidgetEntry.swift"
bd create "US2: Update fetchCurrentEntry() for goal weight" -t task -p 2 -d "W8TrackrWidget/Provider/WeightWidgetProvider.swift"
bd create "US2: Add goal progress section to SmallWidgetView" -t task -p 2 -d "W8TrackrWidget/Views/SmallWidgetView.swift"
bd create "US2: Add goal reached indicator" -t task -p 2 -d "W8TrackrWidget/Views/SmallWidgetView.swift"
bd create "US2: Create MediumWidgetView.swift with goal progress" -t task -p 2 -d "W8TrackrWidget/Views/MediumWidgetView.swift"
bd create "US2: Add systemMedium to supportedFamilies" -t task -p 2 -d "W8TrackrWidget/W8TrackrWidget.swift"
bd create "US2: Create WeightWidgetEntryView.swift for size routing" -t task -p 2 -d "W8TrackrWidget/Views/WeightWidgetEntryView.swift"
bd create "US2: Add accessibility labels for goal progress" -t task -p 2 -d "SmallWidgetView.swift and MediumWidgetView.swift"
bd create "US2: Verify US2 tests pass" -t task -p 2 -d "Run T034-T036 tests"

# =============================================================================
# PHASE 5: US3 - QUICK ENTRY (11 tasks)
# =============================================================================
bd create "US3: Quick Weight Entry from Widget" -t epic -p 3 -d "Tap widget to open app directly to weight entry screen"

# Tests first (TDD)
bd create "US3: Create DeepLinkHandlerTests.swift - URL parsing" -t task -p 3 -d "W8TrackrTests/DeepLinkHandlerTests.swift"
bd create "US3: Add test for addWeight route navigation" -t task -p 3 -d "W8TrackrTests/DeepLinkHandlerTests.swift"

# Implementation
bd create "US3: Create DeepLinkHandler.swift with route enum" -t task -p 3 -d "W8Trackr/Navigation/DeepLinkHandler.swift"
bd create "US3: Create NavigationState.swift ObservableObject" -t task -p 3 -d "W8Trackr/Navigation/NavigationState.swift"
bd create "US3: Add widgetURL to SmallWidgetView" -t task -p 3 -d "W8TrackrWidget/Views/SmallWidgetView.swift"
bd create "US3: Add Link elements to MediumWidgetView" -t task -p 3 -d "W8TrackrWidget/Views/MediumWidgetView.swift"
bd create "US3: Update ContentView.swift with NavigationState" -t task -p 3 -d "W8Trackr/Views/ContentView.swift"
bd create "US3: Add onOpenURL handler to W8TrackrApp" -t task -p 3 -d "W8TrackrApp.swift"
bd create "US3: Add reloadTimelines after weight save" -t task -p 3 -d "W8Trackr/Views/WeightEntryView.swift"
bd create "US3: Add reloadTimelines after weight delete" -t task -p 3 -d "Relevant delete views"
bd create "US3: Verify US3 tests pass" -t task -p 3 -d "Run T047-T048 tests"

# =============================================================================
# PHASE 6: POLISH (10 tasks)
# =============================================================================
bd create "Polish: Cross-Cutting Concerns" -t epic -p 4 -d "Final improvements affecting all user stories"

bd create "Add trend calculation using 7-day window" -t task -p 4 -d "W8TrackrWidget/Provider/WeightWidgetProvider.swift"
bd create "Add trend indicator arrows to widget views" -t task -p 4 -d "SmallWidgetView.swift and MediumWidgetView.swift"
bd create "Create widget preview with #Preview macro" -t task -p 4 -d "W8TrackrWidget/W8TrackrWidget.swift"
bd create "Add preview for MediumWidgetView" -t task -p 4 -d "W8TrackrWidget/Views/MediumWidgetView.swift"
bd create "Update SettingsView to reload widget on goal change" -t task -p 4 -d "W8Trackr/Views/SettingsView.swift"
bd create "Update SettingsView to reload widget on unit change" -t task -p 4 -d "W8Trackr/Views/SettingsView.swift"
bd create "Run SwiftLint and fix warnings" -t task -p 4 -d "All new files"
bd create "Manual test: widget gallery and sizes" -t task -p 4 -d "Light/dark mode verification"
bd create "Manual test: deep link from widget tap" -t task -p 4 -d "Both widget sizes"
bd create "Validate against quickstart.md checklist" -t task -p 4 -d "Success criteria validation"
```

## Dependencies

After creating all beads, run these to set up the dependency graph:

```bash
# Get the IDs from bd list output, then:

# Setup blocks Foundational
bd dep add <Foundational-epic-id> <Setup-epic-id> --type blocks

# Foundational blocks all user stories
bd dep add <US1-epic-id> <Foundational-epic-id> --type blocks
bd dep add <US2-epic-id> <Foundational-epic-id> --type blocks
bd dep add <US3-epic-id> <Foundational-epic-id> --type blocks

# User stories are independent (no inter-story dependencies)
# All can proceed in parallel after Foundational

# Polish depends on all user stories
bd dep add <Polish-epic-id> <US1-epic-id> --type blocks
bd dep add <Polish-epic-id> <US2-epic-id> --type blocks
bd dep add <Polish-epic-id> <US3-epic-id> --type blocks

# Parent-child relationships (optional - for hierarchy tracking)
# bd dep add <task-id> <epic-id> --type parent-child
# (Run for each task under its respective phase epic)
```

## Task Summary

| Phase | Epic | Tasks | Priority |
|-------|------|-------|----------|
| Setup | Project Infrastructure | 7 | P1 |
| Foundational | Shared Data Access | 9 | P1 |
| US1 | View Current Weight | 17 | P1 🎯 MVP |
| US2 | Goal Progress | 13 | P2 |
| US3 | Quick Entry | 11 | P3 |
| Polish | Cross-Cutting Concerns | 10 | P4 |
| **Total** | | **67** | |

## MVP Scope

Complete through **US1: View Current Weight at a Glance** for minimum viable product:
- Setup (7 tasks)
- Foundational (9 tasks)
- US1 (17 tasks)
- **Total MVP: 33 tasks**

## Dependency Graph

```
Setup (P1)
   │
   ▼
Foundational (P1) ─────────────────┐
   │                               │
   ├──────────┬──────────┐         │
   ▼          ▼          ▼         │
US1 (P1)   US2 (P2)   US3 (P3)     │
 🎯 MVP       │          │         │
   │          │          │         │
   └──────────┴──────────┘         │
              │                    │
              ▼                    │
         Polish (P4) ◄─────────────┘
```

## Notes

- **TDD Required**: Tests must be written and fail before implementation (constitution requirement)
- **No UI Tests**: XCUITest prohibited per constitution - manual testing only
- **SwiftLint**: All code must pass SwiftLint before merge
- **Accessibility**: VoiceOver and Dynamic Type support required
- Each user story is independently testable after Foundational phase
- Epics should be completed in priority order unless parallelizing with multiple agents

## Sources

- [Beads CLAUDE.md](https://github.com/steveyegge/beads/blob/main/CLAUDE.md)
- [Beads Quickstart](https://github.com/steveyegge/beads/blob/main/docs/QUICKSTART.md)
- [Gastown README](https://github.com/steveyegge/gastown)
