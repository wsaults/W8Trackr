# Tasks: iOS Home Screen Widget

**Input**: Design documents from `/specs/004-ios-widget/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: TDD required per constitution. Tests written first, must fail before implementation.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths included in descriptions

## Path Conventions (per plan.md)

```
W8Trackr/                    # Main app (existing)
W8TrackrWidget/              # Widget extension (new)
Shared/                      # Shared code (new)
W8TrackrTests/               # Tests (existing)
```

---

## Phase 1: Setup (Project Infrastructure)

**Purpose**: Create widget extension target and configure App Groups

- [ ] T001 Add Widget Extension target named "W8TrackrWidget" to W8Trackr.xcodeproj via Xcode (File → New → Target → Widget Extension)
- [ ] T002 Configure App Groups capability for W8Trackr target with identifier "group.com.saults.W8Trackr" in Signing & Capabilities
- [ ] T003 Configure App Groups capability for W8TrackrWidget target with same identifier "group.com.saults.W8Trackr"
- [ ] T004 Create Shared/ folder at project root for shared code between targets
- [ ] T005 Add WeightEntry.swift to W8TrackrWidget target membership (File Inspector → Target Membership)
- [ ] T006 Add WeightUnit enum to W8TrackrWidget target membership (already in WeightEntry.swift)
- [ ] T007 Configure URL scheme "w8trackr" in W8Trackr/Info.plist under CFBundleURLTypes

**Checkpoint**: Widget extension target exists, App Groups configured, shared model accessible

---

## Phase 2: Foundational (Shared Data Access)

**Purpose**: Core data sharing infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundational Phase

- [ ] T008 [P] Create test file W8TrackrTests/SharedModelContainerTests.swift with failing tests for shared container initialization
- [ ] T009 [P] Create test file W8TrackrTests/PreferenceMigrationTests.swift with failing tests for UserDefaults migration

### Implementation for Foundational Phase

- [ ] T010 [P] Create Shared/DataAccess/SharedModelContainer.swift with App Group container configuration
- [ ] T011 [P] Create Shared/Extensions/WeightEntry+Widget.swift with widget-specific computed properties
- [ ] T012 Update W8TrackrApp.swift to use SharedModelContainer.shared instead of inline container
- [ ] T013 Add preference migration call in W8TrackrApp.init() to migrate existing @AppStorage values
- [ ] T014 Add SharedModelContainer.swift to both W8Trackr and W8TrackrWidget target membership
- [ ] T015 Add WeightEntry+Widget.swift to both W8Trackr and W8TrackrWidget target membership
- [ ] T016 Verify tests T008, T009 pass after implementation

**Checkpoint**: Foundation ready - shared data access works between app and widget extension

---

## Phase 3: User Story 1 - View Current Weight at a Glance (Priority: P1) 🎯 MVP

**Goal**: Display current weight on home screen widget in user's preferred unit

**Independent Test**: Add widget to home screen, verify it shows most recent weight entry with correct unit

### Tests for User Story 1

> **TDD**: Write these tests FIRST, ensure they FAIL before implementation

- [ ] T017 [P] [US1] Create W8TrackrTests/WidgetProviderTests.swift with failing test for placeholder entry creation
- [ ] T018 [P] [US1] Add failing test in WidgetProviderTests.swift for snapshot with weight data
- [ ] T019 [P] [US1] Add failing test in WidgetProviderTests.swift for snapshot with empty data (no entries)
- [ ] T020 [P] [US1] Add failing test in WidgetProviderTests.swift for unit conversion (lb vs kg display)

### Implementation for User Story 1

- [ ] T021 [P] [US1] Create W8TrackrWidget/Models/WidgetEntry.swift with WeightWidgetEntry struct and WeightTrend enum
- [ ] T022 [US1] Create W8TrackrWidget/Provider/WeightWidgetProvider.swift implementing TimelineProvider protocol
- [ ] T023 [US1] Implement placeholder(in:) method in WeightWidgetProvider.swift
- [ ] T024 [US1] Implement getSnapshot(in:completion:) method in WeightWidgetProvider.swift
- [ ] T025 [US1] Implement getTimeline(in:completion:) method with 4-hour refresh policy in WeightWidgetProvider.swift
- [ ] T026 [US1] Implement fetchCurrentEntry() private method to query SwiftData in WeightWidgetProvider.swift
- [ ] T027 [P] [US1] Create W8TrackrWidget/Views/SmallWidgetView.swift with current weight display
- [ ] T028 [US1] Add empty state view in SmallWidgetView.swift for when no weight entries exist
- [ ] T029 [US1] Add entry timestamp display in SmallWidgetView.swift
- [ ] T030 [US1] Create W8TrackrWidget/W8TrackrWidget.swift with Widget configuration for systemSmall
- [ ] T031 [US1] Add .containerBackground(for: .widget) modifier for light/dark mode support in SmallWidgetView.swift
- [ ] T032 [US1] Add accessibility labels in SmallWidgetView.swift for VoiceOver support
- [ ] T033 [US1] Verify tests T017-T020 pass after implementation

**Checkpoint**: User Story 1 complete - Widget displays current weight, empty state works, unit preference respected

---

## Phase 4: User Story 2 - See Progress Toward Goal (Priority: P2)

**Goal**: Show goal progress on widget when user has goal weight set

**Independent Test**: Set goal weight in app, verify widget shows progress (e.g., "5 lbs to goal")

### Tests for User Story 2

- [ ] T034 [P] [US2] Add failing test in WidgetProviderTests.swift for goal progress calculation
- [ ] T035 [P] [US2] Add failing test in WidgetProviderTests.swift for goal reached state
- [ ] T036 [P] [US2] Add failing test in WidgetProviderTests.swift for no goal set (goalWeight nil)

### Implementation for User Story 2

- [ ] T037 [US2] Add goalWeight and distanceToGoal computed properties to WeightWidgetEntry in WidgetEntry.swift
- [ ] T038 [US2] Add goalReached computed property to WeightWidgetEntry in WidgetEntry.swift
- [ ] T039 [US2] Update fetchCurrentEntry() in WeightWidgetProvider.swift to include goal weight from shared UserDefaults
- [ ] T040 [US2] Add goal progress section to SmallWidgetView.swift (conditional on hasGoal)
- [ ] T041 [US2] Add goal reached indicator in SmallWidgetView.swift
- [ ] T042 [P] [US2] Create W8TrackrWidget/Views/MediumWidgetView.swift with extended goal progress display
- [ ] T043 [US2] Update W8TrackrWidget.swift to add .systemMedium to supportedFamilies
- [ ] T044 [US2] Create WeightWidgetEntryView.swift to route between Small and Medium views based on widgetFamily
- [ ] T045 [US2] Add accessibility labels for goal progress in SmallWidgetView.swift and MediumWidgetView.swift
- [ ] T046 [US2] Verify tests T034-T036 pass after implementation

**Checkpoint**: User Story 2 complete - Goal progress displays when set, hidden when not set, goal reached shows celebration

---

## Phase 5: User Story 3 - Quick Weight Entry from Widget (Priority: P3)

**Goal**: Tap widget to open app directly to weight entry screen

**Independent Test**: Tap widget, verify app opens to add weight modal

### Tests for User Story 3

- [ ] T047 [P] [US3] Create W8TrackrTests/DeepLinkHandlerTests.swift with failing test for URL parsing
- [ ] T048 [P] [US3] Add failing test in DeepLinkHandlerTests.swift for addWeight route navigation

### Implementation for User Story 3

- [ ] T049 [P] [US3] Create W8Trackr/Navigation/DeepLinkHandler.swift with DeepLinkRoute enum and route parsing
- [ ] T050 [P] [US3] Create W8Trackr/Navigation/NavigationState.swift as ObservableObject for navigation state
- [ ] T051 [US3] Add .widgetURL(DeepLinkRoute.addWeight.url) to SmallWidgetView.swift
- [ ] T052 [US3] Add Link elements with deep link URLs to MediumWidgetView.swift for multiple tap targets
- [ ] T053 [US3] Update ContentView.swift to use NavigationState for tab selection and sheet presentation
- [ ] T054 [US3] Add .onOpenURL handler in W8TrackrApp.swift to process deep links
- [ ] T055 [US3] Add WidgetCenter.shared.reloadTimelines(ofKind: "WeightWidget") call after weight entry save in WeightEntryView.swift
- [ ] T056 [US3] Add WidgetCenter.shared.reloadTimelines call after weight entry delete in relevant views
- [ ] T057 [US3] Verify tests T047-T048 pass after implementation

**Checkpoint**: User Story 3 complete - Tapping widget opens app to add weight, saving updates widget

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting all user stories

- [ ] T058 [P] Add trend calculation to WeightWidgetProvider.swift using 7-day window (calculateTrend method)
- [ ] T059 [P] Add trend indicator (arrow up/down/stable) to SmallWidgetView.swift and MediumWidgetView.swift
- [ ] T060 [P] Create widget preview in W8TrackrWidget.swift using #Preview(as: .systemSmall) macro
- [ ] T061 [P] Add preview for MediumWidgetView.swift with sample timeline entries
- [ ] T062 Update SettingsView.swift to call WidgetCenter.reloadTimelines when goal weight changes
- [ ] T063 Update SettingsView.swift to call WidgetCenter.reloadTimelines when preferred unit changes
- [ ] T064 Run SwiftLint on all new files and fix any warnings
- [ ] T065 Manual testing: Verify widget in widget gallery, both sizes, light/dark mode
- [ ] T066 Manual testing: Verify deep link from widget tap in both sizes
- [ ] T067 Validate against quickstart.md success criteria checklist

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup ──────────────────────────────┐
                                              │
Phase 2: Foundational ◄──────────────────────┘
         ▲
         │ BLOCKS all user stories
         │
    ┌────┴────┬────────────┐
    ▼         ▼            ▼
Phase 3   Phase 4      Phase 5
(US1)     (US2)        (US3)
  │         │            │
  │         │            │
  └────┬────┴────────────┘
       ▼
Phase 6: Polish
```

### User Story Dependencies

| Story | Depends On | Can Parallel With |
|-------|------------|-------------------|
| US1 (P1) | Foundational only | None (MVP) |
| US2 (P2) | Foundational only | US1, US3 |
| US3 (P3) | Foundational only | US1, US2 |

**Note**: All user stories can run in parallel after Foundational phase, but recommend sequential P1→P2→P3 for validation.

### Within Each User Story

1. Tests MUST be written and FAIL before implementation
2. Models before provider logic
3. Provider before views
4. Core display before enhancements
5. Verify tests pass before checkpoint

---

## Parallel Opportunities

### Phase 1 (Setup) - All sequential (Xcode operations)

### Phase 2 (Foundational)

```bash
# Parallel test creation:
T008: SharedModelContainerTests.swift
T009: PreferenceMigrationTests.swift

# Parallel implementation:
T010: SharedModelContainer.swift
T011: WeightEntry+Widget.swift
```

### Phase 3 (User Story 1)

```bash
# Parallel test creation:
T017, T018, T019, T020: All WidgetProviderTests.swift tests

# Parallel implementation:
T021: WidgetEntry.swift
T027: SmallWidgetView.swift (after T021)
```

### Phase 4 (User Story 2)

```bash
# Parallel test creation:
T034, T035, T036: Goal progress tests

# Parallel implementation:
T042: MediumWidgetView.swift
```

### Phase 5 (User Story 3)

```bash
# Parallel test creation:
T047, T048: DeepLinkHandlerTests.swift

# Parallel implementation:
T049: DeepLinkHandler.swift
T050: NavigationState.swift
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. ✅ Complete Phase 1: Setup (7 tasks)
2. ✅ Complete Phase 2: Foundational (9 tasks)
3. ✅ Complete Phase 3: User Story 1 (17 tasks)
4. **STOP and VALIDATE**: Widget shows current weight, test on device
5. Deploy MVP if ready

### Incremental Delivery

| Milestone | What's Deliverable | Task Range |
|-----------|-------------------|------------|
| Foundation | Data sharing works | T001-T016 |
| MVP | Basic widget with weight | T001-T033 |
| Goal Progress | Progress toward goal | T001-T046 |
| Full Feature | Deep linking complete | T001-T057 |
| Polished | Trends, previews, validated | T001-T067 |

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Tasks** | 67 |
| **Phase 1 (Setup)** | 7 |
| **Phase 2 (Foundational)** | 9 |
| **Phase 3 (US1)** | 17 |
| **Phase 4 (US2)** | 13 |
| **Phase 5 (US3)** | 11 |
| **Phase 6 (Polish)** | 10 |
| **Test Tasks** | 14 |
| **Parallelizable** | 28 |

### Independent Test Criteria

| Story | How to Verify Independently |
|-------|---------------------------|
| US1 | Add widget to home screen, shows current weight in correct unit |
| US2 | Set goal in app, widget shows "X lbs to goal" |
| US3 | Tap widget, app opens to add weight screen |

### Suggested MVP Scope

**User Story 1 only** (T001-T033, 33 tasks)
- Provides core widget value
- Can ship and gather feedback before adding goal progress and deep linking
