# Tasks: Goal Progress Notifications

**Input**: Design documents from `/specs/002-goal-notifications/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: TDD is REQUIRED per constitution v1.1.0. Tests MUST be written and FAIL before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **iOS Mobile**: `W8Trackr/` for source, `W8TrackrTests/` for tests

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Model container configuration and shared type definitions

- [ ] T001 Add MilestoneAchievement to ModelContainer in W8Trackr/W8TrackrApp.swift
- [ ] T002 [P] Create MilestoneType enum in W8Trackr/Models/MilestoneType.swift
- [ ] T003 [P] Add @AppStorage keys for goal notification preferences in W8Trackr/Managers/NotificationManager.swift
- [ ] T004 [P] Add @AppStorage key for goalSetDate tracking in W8Trackr/Views/SettingsView.swift

**Checkpoint**: Model container and shared types ready

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core calculation logic that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundational (TDD Required)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T005 [P] Unit test for GoalProgressCalculator.calculateProgress() in W8TrackrTests/GoalProgressCalculatorTests.swift
- [ ] T006 [P] Unit test for GoalProgressCalculator.determineStartWeight() in W8TrackrTests/GoalProgressCalculatorTests.swift
- [ ] T007 [P] Unit test for GoalProgressCalculator.crossedMilestones() in W8TrackrTests/GoalProgressCalculatorTests.swift
- [ ] T008 [P] Unit test for GoalProgressCalculator.isApproachingGoal() in W8TrackrTests/GoalProgressCalculatorTests.swift
- [ ] T009 [P] Unit test for GoalProgressCalculator.newMilestones() duplicate prevention in W8TrackrTests/GoalProgressCalculatorTests.swift
- [ ] T010 [P] Unit test for GoalProgressCalculator.highestMilestone() in W8TrackrTests/GoalProgressCalculatorTests.swift
- [ ] T011 [P] Unit test for GoalProgressCalculator.hasGoalChangedSignificantly() in W8TrackrTests/GoalProgressCalculatorTests.swift

### Implementation for Foundational

- [ ] T012 Create GoalProgressCalculator struct skeleton in W8Trackr/Services/GoalProgressCalculator.swift
- [ ] T013 Implement calculateProgress() for weight loss goals in W8Trackr/Services/GoalProgressCalculator.swift
- [ ] T014 Implement calculateProgress() for weight gain goals in W8Trackr/Services/GoalProgressCalculator.swift
- [ ] T015 Implement determineStartWeight() with goalSetDate logic in W8Trackr/Services/GoalProgressCalculator.swift
- [ ] T016 Implement crossedMilestones() threshold detection in W8Trackr/Services/GoalProgressCalculator.swift
- [ ] T017 Implement isApproachingGoal() with unit-aware threshold in W8Trackr/Services/GoalProgressCalculator.swift
- [ ] T018 Implement newMilestones() duplicate prevention logic in W8Trackr/Services/GoalProgressCalculator.swift
- [ ] T019 Implement highestMilestone() priority ordering in W8Trackr/Services/GoalProgressCalculator.swift
- [ ] T020 Implement hasGoalChangedSignificantly() 10% threshold in W8Trackr/Services/GoalProgressCalculator.swift

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Milestone Celebration Notifications (Priority: P1) 🎯 MVP

**Goal**: Users receive encouraging notifications at 25%, 50%, 75%, and 100% progress milestones

**Independent Test**: Log weight entries that cross milestone thresholds → verify celebration notifications appear within 3 seconds

### Tests for User Story 1 (TDD Required)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T021 [P] [US1] Unit test for MilestoneAchievement model in W8TrackrTests/MilestoneAchievementTests.swift
- [ ] T022 [P] [US1] Unit test for MilestoneTracker.recordAchievement() in W8TrackrTests/MilestoneTrackerTests.swift
- [ ] T023 [P] [US1] Unit test for MilestoneTracker.hasAchieved() in W8TrackrTests/MilestoneTrackerTests.swift
- [ ] T024 [P] [US1] Unit test for MilestoneTracker.achievements(forGoal:) in W8TrackrTests/MilestoneTrackerTests.swift
- [ ] T025 [P] [US1] Unit test for NotificationManager.scheduleMilestoneNotification() with mock in W8TrackrTests/NotificationManagerMilestoneTests.swift
- [ ] T026 [P] [US1] Unit test for NotificationManager.checkAndNotifyMilestones() in W8TrackrTests/NotificationManagerMilestoneTests.swift

### Implementation for User Story 1

- [ ] T027 [US1] Create MilestoneAchievement @Model in W8Trackr/Models/MilestoneAchievement.swift
- [ ] T028 [US1] Add sample data to MilestoneAchievement for previews in W8Trackr/Models/MilestoneAchievement.swift
- [ ] T029 [US1] Create MilestoneTracker struct skeleton in W8Trackr/Services/MilestoneTracker.swift
- [ ] T030 [US1] Implement MilestoneTracker.recordAchievement() in W8Trackr/Services/MilestoneTracker.swift
- [ ] T031 [US1] Implement MilestoneTracker.markAsNotified() in W8Trackr/Services/MilestoneTracker.swift
- [ ] T032 [US1] Implement MilestoneTracker.achievements(forGoal:) in W8Trackr/Services/MilestoneTracker.swift
- [ ] T033 [US1] Implement MilestoneTracker.hasAchieved() in W8Trackr/Services/MilestoneTracker.swift
- [ ] T034 [US1] Implement MilestoneTracker.mostRecentAchievement() in W8Trackr/Services/MilestoneTracker.swift
- [ ] T035 [US1] Implement MilestoneTracker.handleGoalChange() in W8Trackr/Services/MilestoneTracker.swift
- [ ] T036 [US1] Extend NotificationManager with areMilestoneNotificationsEnabled in W8Trackr/Managers/NotificationManager.swift
- [ ] T037 [US1] Implement scheduleMilestoneNotification() in W8Trackr/Managers/NotificationManager.swift
- [ ] T038 [US1] Implement checkAndNotifyMilestones() orchestration in W8Trackr/Managers/NotificationManager.swift
- [ ] T039 [US1] Hook checkAndNotifyMilestones() into weight entry save flow in W8Trackr/Views/WeightEntryView.swift
- [ ] T040 [US1] Add goal notification toggles section to SettingsView in W8Trackr/Views/SettingsView.swift

**Checkpoint**: User Story 1 complete - milestone celebrations trigger on weight entry

---

## Phase 4: User Story 2 - Approaching Goal Alerts (Priority: P2)

**Goal**: Users receive a heads-up when within 5 lb (2.5 kg) of their goal weight

**Independent Test**: Log weight entry within approaching threshold → verify "approaching goal" notification appears

### Tests for User Story 2 (TDD Required)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T041 [P] [US2] Unit test for approaching goal detection (weight loss) in W8TrackrTests/GoalProgressCalculatorTests.swift
- [ ] T042 [P] [US2] Unit test for approaching goal detection (weight gain) in W8TrackrTests/GoalProgressCalculatorTests.swift
- [ ] T043 [P] [US2] Unit test for approaching notification duplicate prevention in W8TrackrTests/MilestoneTrackerTests.swift
- [ ] T044 [P] [US2] Unit test for approaching notification regression re-trigger in W8TrackrTests/MilestoneTrackerTests.swift
- [ ] T045 [P] [US2] Unit test for scheduleApproachingGoalNotification() in W8TrackrTests/NotificationManagerMilestoneTests.swift

### Implementation for User Story 2

- [ ] T046 [US2] Extend NotificationManager with areApproachingNotificationsEnabled in W8Trackr/Managers/NotificationManager.swift
- [ ] T047 [US2] Implement scheduleApproachingGoalNotification() in W8Trackr/Managers/NotificationManager.swift
- [ ] T048 [US2] Add approaching goal detection to checkAndNotifyMilestones() in W8Trackr/Managers/NotificationManager.swift
- [ ] T049 [US2] Add approaching notification toggle to SettingsView in W8Trackr/Views/SettingsView.swift
- [ ] T050 [US2] Implement regression detection for approaching milestone in W8Trackr/Services/MilestoneTracker.swift

**Checkpoint**: User Story 2 complete - approaching goal alerts fire once per threshold crossing

---

## Phase 5: User Story 3 - Progress Summary Notifications (Priority: P3)

**Goal**: Users receive periodic weekly summaries of their weight progress

**Independent Test**: Enable weekly summaries → wait for scheduled time → verify summary notification with accurate progress data

### Tests for User Story 3 (TDD Required)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T051 [P] [US3] Unit test for weekly summary generation with entries in W8TrackrTests/NotificationSchedulerTests.swift
- [ ] T052 [P] [US3] Unit test for weekly summary when no entries in W8TrackrTests/NotificationSchedulerTests.swift
- [ ] T053 [P] [US3] Unit test for summary scheduling respects user preferences in W8TrackrTests/NotificationSchedulerTests.swift

### Implementation for User Story 3

- [ ] T054 [US3] Add weeklySummaryEnabled preference check in W8Trackr/Managers/NotificationManager.swift
- [ ] T055 [US3] Implement user-configurable summary day/time picker in W8Trackr/Views/SettingsView.swift
- [ ] T056 [US3] Update scheduleWeeklySummary() to use user preferences in W8Trackr/Managers/NotificationScheduler.swift
- [ ] T057 [US3] Add gentle reminder message when no entries that week in W8Trackr/Managers/NotificationScheduler.swift
- [ ] T058 [US3] Ensure summary includes goal progress percentage in W8Trackr/Managers/NotificationScheduler.swift

**Checkpoint**: User Story 3 complete - weekly summaries scheduled per user preferences

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Accessibility, quality, and performance validation

- [ ] T059 [P] Add accessibility labels to notification preference toggles in W8Trackr/Views/SettingsView.swift
- [ ] T060 [P] Add VoiceOver announcements for milestone state changes in W8Trackr/Views/SettingsView.swift
- [ ] T061 Implement removeGoalNotifications() cleanup method in W8Trackr/Managers/NotificationManager.swift
- [ ] T062 Add confirmation dialog when disabling all goal notifications in W8Trackr/Views/SettingsView.swift
- [ ] T063 Verify SwiftLint passes on all new files
- [ ] T064 Performance validation: milestone check completes within 3 seconds (SC-001)
- [ ] T065 Run quickstart.md validation on device

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 can proceed independently after Foundational
  - US2 can proceed after Foundational (uses same MilestoneTracker)
  - US3 can proceed after Foundational (extends existing NotificationScheduler)
- **Polish (Phase 6)**: Depends on US1, US2, US3 being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Shares MilestoneTracker with US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Independent of US1/US2, extends existing scheduler

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD required by constitution)
- Models before services
- Services before NotificationManager integration
- Core implementation before SettingsView integration
- Commit after each task or logical group

### Parallel Opportunities

- T002, T003, T004 can run in parallel (different files)
- T005-T011 can run in parallel (independent test cases)
- T021-T026 can run in parallel (independent test cases)
- T041-T045 can run in parallel (independent test cases)
- T051-T053 can run in parallel (independent test cases)
- T059, T060 can run in parallel (different accessibility concerns)

---

## Parallel Example: Foundational Tests

```bash
# Launch all Foundational tests together (TDD):
Task T005: "Unit test for calculateProgress()"
Task T006: "Unit test for determineStartWeight()"
Task T007: "Unit test for crossedMilestones()"
Task T008: "Unit test for isApproachingGoal()"
Task T009: "Unit test for newMilestones()"
Task T010: "Unit test for highestMilestone()"
Task T011: "Unit test for hasGoalChangedSignificantly()"
```

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all US1 tests together (TDD):
Task T021: "Unit test for MilestoneAchievement model"
Task T022: "Unit test for recordAchievement()"
Task T023: "Unit test for hasAchieved()"
Task T024: "Unit test for achievements(forGoal:)"
Task T025: "Unit test for scheduleMilestoneNotification()"
Task T026: "Unit test for checkAndNotifyMilestones()"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Milestone Celebrations)
4. **STOP and VALIDATE**: Test milestone notifications on device
5. Ship MVP - users get milestone celebrations

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Test milestones → Ship (MVP!)
3. Add User Story 2 → Test approaching alerts → Ship
4. Add User Story 3 → Test weekly summaries → Ship
5. Each story adds value without breaking previous stories

### Recommended Order for Solo Developer

1. Phase 1 (Setup): ~15 min
2. Phase 2 (Foundational): ~2-3 tasks/session, TDD cycle
3. Phase 3 (US1 Milestones): MVP milestone
4. Phase 4 (US2 Approaching): Approaching alerts
5. Phase 5 (US3 Summaries): Weekly summaries
6. Phase 6 (Polish): Accessibility and validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- TDD is NON-NEGOTIABLE per constitution - write failing tests first
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Existing NotificationScheduler has weekly summary logic - extend, don't replace
