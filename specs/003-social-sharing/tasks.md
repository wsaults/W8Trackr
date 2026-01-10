# Tasks: Social Sharing

**Input**: Design documents from `/specs/003-social-sharing/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

**TDD**: Tests are MANDATORY per Constitution v1.1.0. Write tests FIRST, verify they FAIL, then implement.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- **⚠️ RED**: Test task - must fail before implementation
- **✅ GREEN**: Implementation that makes tests pass

## Path Conventions

- **Models**: `W8Trackr/Models/`
- **Services**: `W8Trackr/Services/`
- **Views**: `W8Trackr/Views/`
- **Tests**: `W8TrackrTests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create foundational types and @AppStorage keys for sharing preferences

- [ ] T001 [P] Create `W8Trackr/Models/ShareType.swift` with ShareType enum per data-model.md
- [ ] T002 [P] Create `W8Trackr/Models/SharingPreferences.swift` with @AppStorage property wrapper keys
- [ ] T003 [P] Create `W8Trackr/Models/ShareableContent.swift` stub with Transferable conformance placeholder
- [ ] T004 [P] Create `W8Trackr/Models/ShareMessageTemplate.swift` with message template enum per data-model.md

**Checkpoint**: Core types exist but are not yet implemented

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement ShareContentGenerator service with full TDD - this blocks ALL user stories

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests ⚠️ RED (Write First)

- [ ] T005 [P] Create `W8TrackrTests/ShareContentGeneratorTests.swift` with tests for:
  - `testGenerateMilestoneMessage_PrivacyMode_HidesWeight()`
  - `testGenerateMilestoneMessage_FullMode_ShowsWeight()`
  - `testGenerateMilestoneMessage_25PercentMilestone()`
  - `testGenerateMilestoneMessage_50PercentMilestone()`
  - `testGenerateMilestoneMessage_75PercentMilestone()`
  - `testGenerateMilestoneMessage_100PercentMilestone()`
  - `testCanShareMilestone_WithMilestone_ReturnsTrue()`
  - `testCanShareMilestone_NilMilestone_ReturnsFalse()`

- [ ] T006 [P] Add tests to `ShareContentGeneratorTests.swift` for:
  - `testFormatDuration_UnderOneMonth_ShowsDays()`
  - `testFormatDuration_OverOneMonth_ShowsMonths()`
  - `testFormatDuration_OverOneYear_ShowsYears()`
  - `testFormatDuration_HideDates_ShowsRelative()`

- [ ] T007 [P] Create `W8TrackrTests/ShareableContentTests.swift` with tests for:
  - `testShareableContent_FullText_IncludesEmoji()`
  - `testShareableContent_Preview_HasCorrectTitle()`
  - `testTransferRepresentation_ExportsPlainText()`

### Implementation ✅ GREEN

- [ ] T008 Implement `ShareContentGenerator.generateMilestoneMessage()` in `W8Trackr/Services/ShareContentGenerator.swift`
- [ ] T009 Implement `ShareContentGenerator.formatDuration()` in `W8Trackr/Services/ShareContentGenerator.swift`
- [ ] T010 Implement `ShareContentGenerator.canShareMilestone()` in `W8Trackr/Services/ShareContentGenerator.swift`
- [ ] T011 Implement `ShareableContent` Transferable conformance in `W8Trackr/Models/ShareableContent.swift`
- [ ] T012 Add sample data extensions to `ShareableContent` for previews

**Checkpoint**: Foundation ready - ShareContentGenerator passes all tests, user story implementation can begin

---

## Phase 3: User Story 1 - Share Milestone Achievement (Priority: P1) 🎯 MVP

**Goal**: Users can share milestone achievements via native share sheet within 2 taps (SC-001)

**Independent Test**: Achieve a 50% milestone → tap Share → see preview → share sheet appears with formatted message

### Tests ⚠️ RED (Write First)

- [ ] T013 [P] [US1] Create `W8TrackrTests/ShareMilestoneTests.swift` with tests for:
  - `testGenerateMilestoneContent_CreatesShareableContent()`
  - `testGenerateMilestoneContent_RespectsPrivacySettings()`
  - `testGenerateMilestoneContent_IncludesProgressPercentage()`
  - `testGenerateMilestoneContent_SetsCorrectShareType()`

- [ ] T014 [P] [US1] Add to `ShareContentGeneratorTests.swift`:
  - `testGenerateMilestoneContent_WithHideWeights_OmitsWeightValue()`
  - `testGenerateMilestoneContent_WithShowWeights_IncludesWeightValue()`
  - `testGenerateMilestoneContent_WeightGainGoal_UsesNeutralLanguage()`

### Implementation ✅ GREEN

- [ ] T015 [US1] Implement `ShareContentGenerator.generateMilestoneContent()` per contracts/ShareContentGenerator.swift
- [ ] T016 [US1] Create `W8Trackr/Views/SharePreviewView.swift` showing share preview with message and optional image
- [ ] T017 [US1] Create `W8Trackr/Views/ShareButton.swift` reusable component with ShareLink
- [ ] T018 [US1] Add share button to milestone celebration view (integrate with 002-goal-notifications)
- [ ] T019 [US1] Add "Copy to Clipboard" fallback in SharePreviewView (FR-011)

### Image Rendering ✅ GREEN

- [ ] T020 [P] [US1] Create `W8TrackrTests/ProgressImageRendererTests.swift` with tests for:
  - `testRenderMilestoneImage_ReturnsUIImage()`
  - `testRenderMilestoneImage_RespectsStandardSize()`
  - `testMilestoneGraphicView_DisplaysProgressRing()`

- [ ] T021 [US1] Implement `MilestoneGraphicView` in `W8Trackr/Services/ProgressImageRenderer.swift`
- [ ] T022 [US1] Implement `ProgressImageRenderer.renderMilestoneImage()` using ImageRenderer
- [ ] T023 [US1] Integrate image rendering into SharePreviewView when `includeGraphic` preference is true

**Checkpoint**: User Story 1 complete - users can share milestones with privacy controls

---

## Phase 4: User Story 2 - Share Progress Summary (Priority: P2)

**Goal**: Users can share overall journey progress from summary view

**Independent Test**: Track weight for 7+ days → tap "Share Progress" on summary → see progress summary with trend

### Tests ⚠️ RED (Write First)

- [ ] T024 [P] [US2] Add tests to `ShareContentGeneratorTests.swift`:
  - `testGenerateProgressContent_CalculatesWeightChange()`
  - `testGenerateProgressContent_IncludesTrendDirection()`
  - `testGenerateProgressContent_RespectsPrivacySettings()`
  - `testGenerateProgressMessage_PositiveDirection_UsesEncouragingTone()`
  - `testGenerateProgressMessage_Regression_RemainsPositive()`

- [ ] T025 [P] [US2] Add tests for validation:
  - `testCanShareProgress_Under7Days_ReturnsFalse()`
  - `testCanShareProgress_Under2Entries_ReturnsFalse()`
  - `testCanShareProgress_MeetsMinimum_ReturnsTrue()`

### Implementation ✅ GREEN

- [ ] T026 [US2] Implement `ShareContentGenerator.generateProgressContent()` per contract
- [ ] T027 [US2] Implement `ShareContentGenerator.generateProgressMessage()` with weight-neutral language
- [ ] T028 [US2] Implement `ShareContentGenerator.canShareProgress()` validation (7+ days, 2+ entries)
- [ ] T029 [US2] Add "Share Progress" button to SummaryView.swift
- [ ] T030 [US2] Show "Log more entries" guidance when canShareProgress returns false

### Image Rendering ✅ GREEN

- [ ] T031 [P] [US2] Add tests to `ProgressImageRendererTests.swift`:
  - `testRenderProgressImage_ReturnsUIImage()`
  - `testProgressGraphicView_DisplaysProgressBar()`
  - `testProgressGraphicView_ShowsDuration()`

- [ ] T032 [US2] Implement `ProgressGraphicView` in `W8Trackr/Services/ProgressImageRenderer.swift`
- [ ] T033 [US2] Implement `ProgressImageRenderer.renderProgressImage()` using ImageRenderer
- [ ] T034 [US2] Integrate progress image into share flow when `includeGraphic` preference is true

**Checkpoint**: User Story 2 complete - users can share progress summaries

---

## Phase 5: User Story 3 - Privacy Controls (Priority: P3)

**Goal**: Users can configure sharing privacy settings in Settings

**Independent Test**: Change "Hide Exact Weights" toggle → share milestone → verify weight is hidden/shown per setting

### Tests ⚠️ RED (Write First)

- [ ] T035 [P] [US3] Create `W8TrackrTests/SharingPreferencesTests.swift` with tests for:
  - `testSharingPreferences_DefaultValues_PrivacyFirst()`
  - `testSharingPreferences_HideExactWeights_DefaultTrue()`
  - `testSharingPreferences_PersistsAcrossSessions()`

- [ ] T036 [P] [US3] Add integration tests:
  - `testShareContent_HideWeightsEnabled_NoWeightInOutput()`
  - `testShareContent_HideDatesEnabled_RelativeDatesOnly()`
  - `testShareContent_IncludeGraphicDisabled_NoImageGenerated()`

### Implementation ✅ GREEN

- [ ] T037 [US3] Create `SharingPreferencesSection` view component for SettingsView
- [ ] T038 [US3] Add sharing preferences section to SettingsView.swift with:
  - Toggle for "Hide Exact Weights" (default: ON)
  - Toggle for "Hide Dates" (default: OFF)
  - Toggle for "Include Graphic" (default: ON)
  - TextField for custom hashtag (default: "#W8Trackr")
- [ ] T039 [US3] Verify SharePreviewView updates instantly when settings change
- [ ] T040 [US3] Add VoiceOver labels to all sharing preference controls (FR-008 accessibility)

**Checkpoint**: User Story 3 complete - users have full privacy control

---

## Phase 6: Integration & Polish

**Purpose**: Connect all components, add milestone history sharing, final polish

### Milestone History Integration

- [ ] T041 [P] Add share button to milestone detail view in milestone history
- [ ] T042 [P] Ensure past milestones can be shared (US1 Scenario 1.2)

### Edge Cases

- [ ] T043 Test and handle: No achievements yet → share option hidden/disabled
- [ ] T044 Test and handle: Weight gain goal → neutral language verification
- [ ] T045 Test and handle: No goal set → progress shares disabled
- [ ] T046 Test and handle: Profile name not set → generic message (no placeholders)

### Performance & Polish

- [ ] T047 Verify share preview loads in under 1 second (SC-002)
- [ ] T048 Verify 2-tap share initiation path (SC-001)
- [ ] T049 Add haptic feedback on successful share
- [ ] T050 Run quickstart.md full validation checklist

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup ─────────────────┐
                                ├─► Phase 2: Foundational (BLOCKS all US)
Phase 1 completes ──────────────┘
                                        │
                                        ▼
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
            Phase 3: US1        Phase 4: US2        Phase 5: US3
            (Share Milestone)   (Share Progress)    (Privacy Controls)
                    │                   │                   │
                    └───────────────────┼───────────────────┘
                                        │
                                        ▼
                               Phase 6: Integration
```

### TDD Order Within Each Phase

1. **Write Tests** → Verify they **FAIL** (RED)
2. **Implement** → Tests **PASS** (GREEN)
3. **Refactor** if needed (keep tests passing)

### Parallel Opportunities

- **Phase 1**: All T001-T004 can run in parallel (different files)
- **Phase 2 Tests**: T005-T007 can run in parallel
- **US1 Tests**: T013-T014 can run in parallel
- **US2 Tests**: T024-T025 can run in parallel
- **US3 Tests**: T035-T036 can run in parallel
- **After Phase 2**: US1, US2, US3 can proceed in parallel (if staffed)

---

## MVP Scope

**Minimum for launch**: Phase 1 + Phase 2 + Phase 3 (US1)

This delivers:
- ✅ Share milestone achievements via native share sheet
- ✅ Privacy-first defaults (hide exact weights)
- ✅ Copy to clipboard fallback
- ✅ Progress graphic generation
- ✅ 2-tap share flow

**Task Count**:
- Total: 50 tasks
- MVP (Setup + Foundational + US1): 23 tasks
- US2 adds: 11 tasks
- US3 adds: 6 tasks
- Polish: 10 tasks

---

## Notes

- Constitution v1.1.0 mandates TDD - tests MUST fail before implementation
- No XCUITest per constitution - unit/integration tests only
- @AppStorage for preferences, not SwiftData (simplicity principle)
- Uses existing MilestoneAchievement from 002-goal-notifications
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
