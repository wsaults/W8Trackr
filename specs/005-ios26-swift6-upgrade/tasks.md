# Tasks: iOS 26 and Swift 6 Platform Upgrade

**Input**: Design documents from `/specs/005-ios26-swift6-upgrade/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, quickstart.md ✅

**Tests**: Existing test suite validates zero regression. No new tests required unless migration breaks existing tests.

**Organization**: Tasks grouped by user story (P1: Zero Regression, P2: Clean Build, P3: Modern Patterns).

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths included in descriptions

## Path Conventions (existing structure)

```
W8Trackr/                    # Main app
├── W8TrackrApp.swift
├── Managers/
│   ├── NotificationManager.swift
│   ├── HealthKitManager.swift
│   ├── NotificationScheduler.swift
│   └── DataExporter.swift
├── Views/                   # ~12 view files
├── Models/
│   └── WeightEntry.swift
└── Analytics/
    └── TrendCalculator.swift

W8TrackrTests/               # Test target
├── TrendCalculatorTests.swift
└── W8TrackrTests.swift
```

---

## Phase 1: Setup (Build Configuration)

**Purpose**: Configure project for Swift 6 migration path

- [ ] T001 Enable complete concurrency checking in W8Trackr.xcodeproj: Build Settings → Strict Concurrency Checking → Complete
- [ ] T002 Enable complete concurrency checking for W8TrackrTests target in W8Trackr.xcodeproj
- [ ] T003 Build project and capture list of all concurrency warnings (save to migration-warnings.txt)
- [ ] T004 Run existing test suite and verify all tests pass before migration

**Checkpoint**: Baseline established - all warnings identified, all tests passing

---

## Phase 2: Foundational (Core Service Migration)

**Purpose**: Migrate ObservableObject classes to @Observable + @MainActor. This blocks view updates.

**⚠️ CRITICAL**: Views cannot be updated until services are migrated

### NotificationManager Migration

- [ ] T005 Add `@MainActor` annotation to NotificationManager class in W8Trackr/Managers/NotificationManager.swift
- [ ] T006 Replace `ObservableObject` protocol with `@Observable` macro in W8Trackr/Managers/NotificationManager.swift
- [ ] T007 Remove all `@Published` property wrappers in W8Trackr/Managers/NotificationManager.swift
- [ ] T008 Convert `requestNotificationPermission(completion:)` to async in W8Trackr/Managers/NotificationManager.swift
- [ ] T009 Replace `DispatchQueue.main.async` with direct property assignment (MainActor-safe) in W8Trackr/Managers/NotificationManager.swift
- [ ] T010 Update `init()` to use Task for async operations in W8Trackr/Managers/NotificationManager.swift
- [ ] T011 Convert `scheduleNotification(at:)` to async if using completion handlers in W8Trackr/Managers/NotificationManager.swift

### HealthKitManager Migration

- [ ] T012 [P] Add `@MainActor` annotation to HealthKitManager class in W8Trackr/Managers/HealthKitManager.swift
- [ ] T013 Replace `ObservableObject` protocol with `@Observable` macro in W8Trackr/Managers/HealthKitManager.swift
- [ ] T014 Remove all `@Published` property wrappers in W8Trackr/Managers/HealthKitManager.swift
- [ ] T015 Convert `requestAuthorization(completion:)` to async in W8Trackr/Managers/HealthKitManager.swift
- [ ] T016 Convert `syncWeightToHealthKit(entry:completion:)` to async in W8Trackr/Managers/HealthKitManager.swift
- [ ] T017 Replace `DispatchQueue.main.async` with direct property assignment in W8Trackr/Managers/HealthKitManager.swift
- [ ] T018 Verify `static let shared` is safe with @MainActor isolation in W8Trackr/Managers/HealthKitManager.swift

### Other Managers

- [ ] T019 [P] Review NotificationScheduler.swift for Sendable conformance in W8Trackr/Managers/NotificationScheduler.swift
- [ ] T020 [P] Review DataExporter.swift for concurrency safety in W8Trackr/Managers/DataExporter.swift
- [ ] T021 [P] Review TrendCalculator.swift for Sendable conformance in W8Trackr/Analytics/TrendCalculator.swift

**Checkpoint**: All service classes migrated - view updates can now proceed

---

## Phase 3: User Story 1 - App Continues Working (Priority: P1) 🎯 MVP

**Goal**: Ensure all existing functionality works identically after migration

**Independent Test**: Run full test suite + manual smoke test of all features

### View Property Wrapper Updates

- [ ] T022 [US1] Update SettingsView.swift: Change `@StateObject private var notificationManager` to `@State private var notificationManager` in W8Trackr/Views/SettingsView.swift
- [ ] T023 [US1] Update SettingsView.swift: Change `@ObservedObject private var healthKitManager` to `@State private var healthKitManager` in W8Trackr/Views/SettingsView.swift
- [ ] T024 [US1] Update async calls in SettingsView.swift to use Task { await ... } pattern in W8Trackr/Views/SettingsView.swift
- [ ] T025 [P] [US1] Search for any other `@StateObject` or `@ObservedObject` usage in W8Trackr/Views/ and update
- [ ] T026 [US1] Build and verify zero errors in main app target
- [ ] T027 [US1] Run all unit tests and verify 100% pass rate

### Data Preservation Verification

- [ ] T028 [US1] Verify WeightEntry model requires no changes in W8Trackr/Models/WeightEntry.swift
- [ ] T029 [US1] Verify @Query usage in views requires no changes
- [ ] T030 [US1] Test with existing user data - verify all entries display correctly

**Checkpoint**: User Story 1 complete - All existing functionality verified working

---

## Phase 4: User Story 2 - Clean Build (Priority: P2)

**Goal**: Build with zero errors and zero warnings on Swift 6

**Independent Test**: Build command completes with zero diagnostics

### Warning Resolution

- [ ] T031 [US2] Address any remaining Sendable warnings in W8Trackr/
- [ ] T032 [US2] Address any remaining actor isolation warnings in W8Trackr/
- [ ] T033 [US2] Add `nonisolated` to any methods that should not be MainActor-isolated
- [ ] T034 [US2] Verify no deprecated API warnings (iOS 26 deprecations)

### Test Target Updates

- [ ] T035 [P] [US2] Add `@MainActor` annotation to test methods testing NotificationManager in W8TrackrTests/
- [ ] T036 [P] [US2] Add `@MainActor` annotation to test methods testing HealthKitManager in W8TrackrTests/
- [ ] T037 [US2] Convert relevant test methods to `async throws` where testing async code in W8TrackrTests/
- [ ] T038 [US2] Build test target and verify zero errors

### Build Settings Finalization

- [ ] T039 [US2] Update deployment target to iOS 26.0 in W8Trackr.xcodeproj (all targets)
- [ ] T040 [US2] Update Swift Language Version to Swift 6 in W8Trackr.xcodeproj (all targets)
- [ ] T041 [US2] Clean build folder and perform full rebuild
- [ ] T042 [US2] Verify build completes with zero warnings (first-party code)

**Checkpoint**: User Story 2 complete - Clean build on Swift 6 / iOS 26

---

## Phase 5: User Story 3 - Modern Patterns (Priority: P3)

**Goal**: Adopt modern Swift 6 patterns where beneficial

**Independent Test**: Code review confirms modern patterns in use

### Code Modernization

- [ ] T043 [P] [US3] Review and simplify any complex DispatchQueue patterns in W8Trackr/
- [ ] T044 [P] [US3] Ensure all async functions use structured concurrency (no detached tasks unless necessary)
- [ ] T045 [US3] Verify @Observable provides expected property-level UI updates (test in simulator)

### Documentation Updates

- [ ] T046 [US3] Update constitution.md platform requirements: iOS 26.0+, Swift 6 in .specify/memory/constitution.md
- [ ] T047 [US3] Update CLAUDE.md technical standards to reflect Swift 6 in CLAUDE.md
- [ ] T048 [US3] Update any code comments referencing old patterns

**Checkpoint**: User Story 3 complete - Modern patterns adopted, documentation updated

---

## Phase 6: Polish & Validation

**Purpose**: Final verification and cleanup

- [ ] T049 Run SwiftLint and fix any new warnings
- [ ] T050 Delete migration-warnings.txt (no longer needed)
- [ ] T051 Manual smoke test: App launch and weight entry
- [ ] T052 Manual smoke test: Chart display and scrolling performance
- [ ] T053 Manual smoke test: Settings and notifications
- [ ] T054 Manual smoke test: HealthKit sync (if enabled)
- [ ] T055 Manual smoke test: Widget (if installed)
- [ ] T056 Manual smoke test: Light and dark mode
- [ ] T057 Final test suite run - all tests must pass
- [ ] T058 Archive build for App Store (verify successful archive)

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup ─────────────────────────────────┐
                                                 │
Phase 2: Foundational ◄──────────────────────────┘
         (Services)
         ▲
         │ BLOCKS view updates
         │
    ┌────┴────┬────────────┐
    ▼         ▼            ▼
Phase 3   Phase 4      Phase 5
(US1)     (US2)        (US3)
  │         │            │
  └────┬────┴────────────┘
       ▼
Phase 6: Polish
```

### User Story Dependencies

| Story | Depends On | Can Parallel With |
|-------|------------|-------------------|
| US1 (P1) | Foundational (services migrated) | None - must complete first |
| US2 (P2) | US1 (app works) | US3 |
| US3 (P3) | US1 (app works) | US2 |

**Note**: US1 must complete before US2/US3 because build settings change in US2 could affect US1 verification.

### Within Foundational Phase

1. NotificationManager and HealthKitManager can be migrated in parallel
2. Other managers (T019-T021) can run in parallel with service migration
3. All services must complete before view updates begin

---

## Parallel Opportunities

### Phase 2 (Foundational)

```bash
# Parallel service migration:
T012-T018: HealthKitManager migration
T005-T011: NotificationManager migration (separate file)

# Parallel manager reviews:
T019: NotificationScheduler.swift
T020: DataExporter.swift
T021: TrendCalculator.swift
```

### Phase 3-5 (User Stories)

```bash
# After US1 foundation is set:
T031-T034: US2 warning resolution (can parallel with US3)
T043-T045: US3 modernization (can parallel with US2)

# Parallel test updates:
T035: NotificationManager tests
T036: HealthKitManager tests
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (4 tasks)
2. Complete Phase 2: Foundational (17 tasks)
3. Complete Phase 3: User Story 1 (9 tasks)
4. **STOP and VALIDATE**: App works identically to before
5. Can ship at this point if needed (still on Swift 5 mode)

### Full Migration

1. Setup → Foundational → US1 (MVP checkpoint)
2. US2: Switch to Swift 6, resolve all warnings
3. US3: Modern patterns, documentation updates
4. Polish: Final validation

### Rollback Strategy

If issues arise:
1. After Phase 2: Can revert service changes independently
2. After US1: App should work, can pause migration
3. After US2 (Swift 6 switch): Most complex rollback point
4. Keep git commits granular for easy rollback

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Tasks** | 58 |
| **Phase 1 (Setup)** | 4 |
| **Phase 2 (Foundational)** | 17 |
| **Phase 3 (US1)** | 9 |
| **Phase 4 (US2)** | 12 |
| **Phase 5 (US3)** | 6 |
| **Phase 6 (Polish)** | 10 |
| **Parallelizable** | 12 |

### Independent Test Criteria

| Story | How to Verify Independently |
|-------|---------------------------|
| US1 | All tests pass + manual smoke test of features |
| US2 | Build with zero errors and zero warnings |
| US3 | Code review confirms @Observable, async/await patterns |

### Suggested MVP Scope

**Through User Story 1** (T001-T030, 30 tasks)
- Migrates services to @Observable
- Updates views for new property wrappers
- Validates all functionality works
- Can remain on Swift 5 mode if needed for stability
