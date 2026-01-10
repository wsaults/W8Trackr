# Goal Progress Notifications - Beads Import

**Feature**: 002-goal-notifications
**Generated**: 2025-01-09
**Source**: specs/002-goal-notifications/tasks.md

## Epic Structure

```
Goal Progress Notifications (epic)
├── Setup (epic) - P1
├── Foundational (epic) - P1, blocks all US*
├── US1: Milestone Celebration Notifications (epic) - P1 🎯 MVP
├── US2: Approaching Goal Alerts (epic) - P2
├── US3: Progress Summary Notifications (epic) - P3
└── Polish (epic) - P4, depends on US1-3
```

## Create Commands

Run these commands to create the beads hierarchy:

```bash
# =============================================================================
# ROOT EPIC
# =============================================================================
bd create "Goal Progress Notifications" -t epic -p 1 -d "Motivational notifications at 25%/50%/75%/100% milestones, approaching goal alerts within 5lb, and weekly progress summaries"

# =============================================================================
# PHASE 1: SETUP (4 tasks)
# =============================================================================
bd create "Setup: Model Container & Shared Types" -t epic -p 1 -d "Model container configuration and shared type definitions"

bd create "Add MilestoneAchievement to ModelContainer" -t task -p 1 -d "W8Trackr/W8TrackrApp.swift"
bd create "Create MilestoneType enum" -t task -p 1 -d "W8Trackr/Models/MilestoneType.swift"
bd create "Add @AppStorage keys for goal notification preferences" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "Add @AppStorage key for goalSetDate tracking" -t task -p 1 -d "W8Trackr/Views/SettingsView.swift"

# =============================================================================
# PHASE 2: FOUNDATIONAL (16 tasks) - BLOCKS ALL USER STORIES
# =============================================================================
bd create "Foundational: Core Calculation Logic" -t epic -p 1 -d "Core calculation logic that ALL user stories depend on. TDD required. Blocks all user stories."

# Tests first (TDD)
bd create "Unit test for GoalProgressCalculator.calculateProgress()" -t task -p 1 -d "W8TrackrTests/GoalProgressCalculatorTests.swift"
bd create "Unit test for GoalProgressCalculator.determineStartWeight()" -t task -p 1 -d "W8TrackrTests/GoalProgressCalculatorTests.swift"
bd create "Unit test for GoalProgressCalculator.crossedMilestones()" -t task -p 1 -d "W8TrackrTests/GoalProgressCalculatorTests.swift"
bd create "Unit test for GoalProgressCalculator.isApproachingGoal()" -t task -p 1 -d "W8TrackrTests/GoalProgressCalculatorTests.swift"
bd create "Unit test for GoalProgressCalculator.newMilestones() duplicate prevention" -t task -p 1 -d "W8TrackrTests/GoalProgressCalculatorTests.swift"
bd create "Unit test for GoalProgressCalculator.highestMilestone()" -t task -p 1 -d "W8TrackrTests/GoalProgressCalculatorTests.swift"
bd create "Unit test for GoalProgressCalculator.hasGoalChangedSignificantly()" -t task -p 1 -d "W8TrackrTests/GoalProgressCalculatorTests.swift"

# Implementation
bd create "Create GoalProgressCalculator struct skeleton" -t task -p 1 -d "W8Trackr/Services/GoalProgressCalculator.swift"
bd create "Implement calculateProgress() for weight loss goals" -t task -p 1 -d "W8Trackr/Services/GoalProgressCalculator.swift"
bd create "Implement calculateProgress() for weight gain goals" -t task -p 1 -d "W8Trackr/Services/GoalProgressCalculator.swift"
bd create "Implement determineStartWeight() with goalSetDate logic" -t task -p 1 -d "W8Trackr/Services/GoalProgressCalculator.swift"
bd create "Implement crossedMilestones() threshold detection" -t task -p 1 -d "W8Trackr/Services/GoalProgressCalculator.swift"
bd create "Implement isApproachingGoal() with unit-aware threshold" -t task -p 1 -d "W8Trackr/Services/GoalProgressCalculator.swift"
bd create "Implement newMilestones() duplicate prevention logic" -t task -p 1 -d "W8Trackr/Services/GoalProgressCalculator.swift"
bd create "Implement highestMilestone() priority ordering" -t task -p 1 -d "W8Trackr/Services/GoalProgressCalculator.swift"
bd create "Implement hasGoalChangedSignificantly() 10% threshold" -t task -p 1 -d "W8Trackr/Services/GoalProgressCalculator.swift"

# =============================================================================
# PHASE 3: US1 - MILESTONE CELEBRATION NOTIFICATIONS (20 tasks) 🎯 MVP
# =============================================================================
bd create "US1: Milestone Celebration Notifications" -t epic -p 1 -d "Users receive encouraging notifications at 25%, 50%, 75%, and 100% progress milestones"

# Tests first (TDD)
bd create "US1: Unit test for MilestoneAchievement model" -t task -p 1 -d "W8TrackrTests/MilestoneAchievementTests.swift"
bd create "US1: Unit test for MilestoneTracker.recordAchievement()" -t task -p 1 -d "W8TrackrTests/MilestoneTrackerTests.swift"
bd create "US1: Unit test for MilestoneTracker.hasAchieved()" -t task -p 1 -d "W8TrackrTests/MilestoneTrackerTests.swift"
bd create "US1: Unit test for MilestoneTracker.achievements(forGoal:)" -t task -p 1 -d "W8TrackrTests/MilestoneTrackerTests.swift"
bd create "US1: Unit test for NotificationManager.scheduleMilestoneNotification() with mock" -t task -p 1 -d "W8TrackrTests/NotificationManagerMilestoneTests.swift"
bd create "US1: Unit test for NotificationManager.checkAndNotifyMilestones()" -t task -p 1 -d "W8TrackrTests/NotificationManagerMilestoneTests.swift"

# Implementation
bd create "US1: Create MilestoneAchievement @Model" -t task -p 1 -d "W8Trackr/Models/MilestoneAchievement.swift"
bd create "US1: Add sample data to MilestoneAchievement for previews" -t task -p 1 -d "W8Trackr/Models/MilestoneAchievement.swift"
bd create "US1: Create MilestoneTracker struct skeleton" -t task -p 1 -d "W8Trackr/Services/MilestoneTracker.swift"
bd create "US1: Implement MilestoneTracker.recordAchievement()" -t task -p 1 -d "W8Trackr/Services/MilestoneTracker.swift"
bd create "US1: Implement MilestoneTracker.markAsNotified()" -t task -p 1 -d "W8Trackr/Services/MilestoneTracker.swift"
bd create "US1: Implement MilestoneTracker.achievements(forGoal:)" -t task -p 1 -d "W8Trackr/Services/MilestoneTracker.swift"
bd create "US1: Implement MilestoneTracker.hasAchieved()" -t task -p 1 -d "W8Trackr/Services/MilestoneTracker.swift"
bd create "US1: Implement MilestoneTracker.mostRecentAchievement()" -t task -p 1 -d "W8Trackr/Services/MilestoneTracker.swift"
bd create "US1: Implement MilestoneTracker.handleGoalChange()" -t task -p 1 -d "W8Trackr/Services/MilestoneTracker.swift"
bd create "US1: Extend NotificationManager with areMilestoneNotificationsEnabled" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "US1: Implement scheduleMilestoneNotification()" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "US1: Implement checkAndNotifyMilestones() orchestration" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "US1: Hook checkAndNotifyMilestones() into weight entry save flow" -t task -p 1 -d "W8Trackr/Views/WeightEntryView.swift"
bd create "US1: Add goal notification toggles section to SettingsView" -t task -p 1 -d "W8Trackr/Views/SettingsView.swift"

# =============================================================================
# PHASE 4: US2 - APPROACHING GOAL ALERTS (10 tasks)
# =============================================================================
bd create "US2: Approaching Goal Alerts" -t epic -p 2 -d "Users receive a heads-up when within 5 lb (2.5 kg) of their goal weight"

# Tests first (TDD)
bd create "US2: Unit test for approaching goal detection (weight loss)" -t task -p 2 -d "W8TrackrTests/GoalProgressCalculatorTests.swift"
bd create "US2: Unit test for approaching goal detection (weight gain)" -t task -p 2 -d "W8TrackrTests/GoalProgressCalculatorTests.swift"
bd create "US2: Unit test for approaching notification duplicate prevention" -t task -p 2 -d "W8TrackrTests/MilestoneTrackerTests.swift"
bd create "US2: Unit test for approaching notification regression re-trigger" -t task -p 2 -d "W8TrackrTests/MilestoneTrackerTests.swift"
bd create "US2: Unit test for scheduleApproachingGoalNotification()" -t task -p 2 -d "W8TrackrTests/NotificationManagerMilestoneTests.swift"

# Implementation
bd create "US2: Extend NotificationManager with areApproachingNotificationsEnabled" -t task -p 2 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "US2: Implement scheduleApproachingGoalNotification()" -t task -p 2 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "US2: Add approaching goal detection to checkAndNotifyMilestones()" -t task -p 2 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "US2: Add approaching notification toggle to SettingsView" -t task -p 2 -d "W8Trackr/Views/SettingsView.swift"
bd create "US2: Implement regression detection for approaching milestone" -t task -p 2 -d "W8Trackr/Services/MilestoneTracker.swift"

# =============================================================================
# PHASE 5: US3 - PROGRESS SUMMARY NOTIFICATIONS (8 tasks)
# =============================================================================
bd create "US3: Progress Summary Notifications" -t epic -p 3 -d "Users receive periodic weekly summaries of their weight progress"

# Tests first (TDD)
bd create "US3: Unit test for weekly summary generation with entries" -t task -p 3 -d "W8TrackrTests/NotificationSchedulerTests.swift"
bd create "US3: Unit test for weekly summary when no entries" -t task -p 3 -d "W8TrackrTests/NotificationSchedulerTests.swift"
bd create "US3: Unit test for summary scheduling respects user preferences" -t task -p 3 -d "W8TrackrTests/NotificationSchedulerTests.swift"

# Implementation
bd create "US3: Add weeklySummaryEnabled preference check" -t task -p 3 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "US3: Implement user-configurable summary day/time picker" -t task -p 3 -d "W8Trackr/Views/SettingsView.swift"
bd create "US3: Update scheduleWeeklySummary() to use user preferences" -t task -p 3 -d "W8Trackr/Managers/NotificationScheduler.swift"
bd create "US3: Add gentle reminder message when no entries that week" -t task -p 3 -d "W8Trackr/Managers/NotificationScheduler.swift"
bd create "US3: Ensure summary includes goal progress percentage" -t task -p 3 -d "W8Trackr/Managers/NotificationScheduler.swift"

# =============================================================================
# PHASE 6: POLISH (7 tasks)
# =============================================================================
bd create "Polish: Cross-Cutting Concerns" -t epic -p 4 -d "Accessibility, quality, and performance validation"

bd create "Add accessibility labels to notification preference toggles" -t task -p 4 -d "W8Trackr/Views/SettingsView.swift"
bd create "Add VoiceOver announcements for milestone state changes" -t task -p 4 -d "W8Trackr/Views/SettingsView.swift"
bd create "Implement removeGoalNotifications() cleanup method" -t task -p 4 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "Add confirmation dialog when disabling all goal notifications" -t task -p 4 -d "W8Trackr/Views/SettingsView.swift"
bd create "Verify SwiftLint passes on all new files" -t task -p 4 -d "Run swiftlint, fix any warnings"
bd create "Performance validation: milestone check completes within 3 seconds" -t task -p 4 -d "SC-001 validation"
bd create "Run quickstart.md validation on device" -t task -p 4 -d "Full end-to-end test using quickstart checklist"
```

## Dependencies

After creating all beads, run these to set up the dependency graph:

```bash
# Get the IDs from bd list output, then:

# Foundational blocks all user stories
bd dep add <US1-epic-id> <Foundational-epic-id> --type blocks
bd dep add <US2-epic-id> <Foundational-epic-id> --type blocks
bd dep add <US3-epic-id> <Foundational-epic-id> --type blocks

# User stories are independent (can run in parallel after Foundational)
# No inter-story dependencies for this feature

# Polish depends on all user stories
bd dep add <Polish-epic-id> <US1-epic-id> --type blocks
bd dep add <Polish-epic-id> <US2-epic-id> --type blocks
bd dep add <Polish-epic-id> <US3-epic-id> --type blocks

# Parent-child relationships (epics contain their tasks)
# bd dep add <task-id> <epic-id> --type parent-child
# (Run for each task under its respective phase epic)
```

## Task Summary

| Phase | Epic | Tasks | Priority |
|-------|------|-------|----------|
| Setup | Model Container & Shared Types | 4 | P1 |
| Foundational | Core Calculation Logic | 16 | P1 |
| US1 | Milestone Celebration Notifications | 20 | P1 🎯 MVP |
| US2 | Approaching Goal Alerts | 10 | P2 |
| US3 | Progress Summary Notifications | 8 | P3 |
| Polish | Cross-Cutting Concerns | 7 | P4 |
| **Total** | | **65** | |

## MVP Scope

Complete through **US1: Milestone Celebration Notifications** for minimum viable product:
- Setup (4 tasks)
- Foundational (16 tasks)
- US1 (20 tasks)
- **Total MVP: 40 tasks**

## Parallel Execution Opportunities

Within each phase, tasks marked [P] in tasks.md can run in parallel:

| Phase | Parallel Groups |
|-------|-----------------|
| Setup | T002, T003, T004 (3 tasks) |
| Foundational | T005-T011 tests (7 tasks) |
| US1 | T021-T026 tests (6 tasks) |
| US2 | T041-T045 tests (5 tasks) |
| US3 | T051-T053 tests (3 tasks) |
| Polish | T059, T060 (2 tasks) |

## Notes

- TDD is NON-NEGOTIABLE per constitution v1.1.0
- No UI tests (XCUITest) per constitution
- Tests must be written and fail before implementation
- Each user story is independently testable
- Epics should be completed in priority order unless parallelizing
- User stories US1, US2, US3 can be parallelized after Foundational phase

## Sources

- [Beads CLAUDE.md](https://github.com/steveyegge/beads/blob/main/CLAUDE.md)
- [Beads Quickstart](https://github.com/steveyegge/beads/blob/main/docs/QUICKSTART.md)
- [Gastown README](https://github.com/steveyegge/gastown)
