# Tasks: Apple Health Integration

**Input**: Design documents from `/specs/001-apple-health-sync/`
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

**Purpose**: HealthKit capability configuration and testing infrastructure

- [ ] T001 Add HealthKit capability to W8Trackr.xcodeproj (Signing & Capabilities)
- [ ] T002 Add HealthKit background delivery entitlement to W8Trackr/W8Trackr.entitlements
- [ ] T003 [P] Add NSHealthShareUsageDescription to W8Trackr/Info.plist
- [ ] T004 [P] Add NSHealthUpdateUsageDescription to W8Trackr/Info.plist
- [ ] T005 Create HealthStoreProtocol for dependency injection in W8Trackr/Managers/HealthStoreProtocol.swift

**Checkpoint**: HealthKit configured, testing infrastructure ready

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundational (TDD Required)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T006 [P] Unit test for WeightEntry sync fields in W8TrackrTests/WeightEntryHealthTests.swift
- [ ] T007 [P] Unit test for HealthSyncManager initialization in W8TrackrTests/HealthSyncManagerTests.swift

### Implementation for Foundational

- [ ] T008 Extend WeightEntry model with sync fields (healthKitUUID, source, syncVersion, pendingHealthSync) in W8Trackr/Models/WeightEntry.swift
- [ ] T009 Add computed properties (isImported, needsSync) to WeightEntry in W8Trackr/Models/WeightEntry.swift
- [ ] T010 Create HealthSyncManager skeleton with protocol injection in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T011 Add @AppStorage keys for sync state (healthSyncEnabled, healthSyncAnchor, lastHealthSyncDate) in HealthSyncManager
- [ ] T012 Implement HKHealthStore extension conforming to HealthStoreProtocol in W8Trackr/Managers/HealthStoreProtocol.swift
- [ ] T013 Add isHealthDataAvailable() check to HealthSyncManager in W8Trackr/Managers/HealthSyncManager.swift

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Export Weight to Apple Health (Priority: P1) 🎯 MVP

**Goal**: Weight entries logged in W8Trackr automatically appear in Apple Health

**Independent Test**: Log a weight entry in W8Trackr → verify it appears in Apple Health app within 5 seconds

### Tests for User Story 1 (TDD Required)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T014 [P] [US1] Unit test for requestAuthorization() in W8TrackrTests/HealthSyncManagerTests.swift
- [ ] T015 [P] [US1] Unit test for saveWeightToHealth() with mock in W8TrackrTests/HealthSyncManagerTests.swift
- [ ] T016 [P] [US1] Unit test for updateWeightInHealth() with mock in W8TrackrTests/HealthSyncManagerTests.swift
- [ ] T017 [P] [US1] Unit test for deleteWeightFromHealth() with mock in W8TrackrTests/HealthSyncManagerTests.swift
- [ ] T018 [P] [US1] Unit test for graceful degradation when auth denied in W8TrackrTests/HealthSyncManagerTests.swift

### Implementation for User Story 1

- [ ] T019 [US1] Implement requestAuthorization() async method in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T020 [US1] Implement saveWeightToHealth(entry:) with sync metadata in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T021 [US1] Implement updateWeightInHealth(entry:) using syncVersion in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T022 [US1] Implement deleteWeightFromHealth(entry:) using healthKitUUID in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T023 [US1] Add Health sync toggle section to SettingsView in W8Trackr/Views/SettingsView.swift
- [ ] T024 [US1] Hook HealthSyncManager.saveWeightToHealth() into weight entry creation flow
- [ ] T025 [US1] Hook HealthSyncManager.updateWeightInHealth() into weight entry edit flow
- [ ] T026 [US1] Hook HealthSyncManager.deleteWeightFromHealth() into weight entry delete flow
- [ ] T027 [US1] Add error handling for auth denied with graceful degradation in HealthSyncManager
- [ ] T028 [US1] Add pendingHealthSync queue for offline support in W8Trackr/Managers/HealthSyncManager.swift

**Checkpoint**: User Story 1 complete - entries export to Health, app works without Health access

---

## Phase 4: User Story 2 - Import Weight from Apple Health (Priority: P2)

**Goal**: Users can import existing weight data from Apple Health into W8Trackr

**Independent Test**: Have weight entries in Apple Health → enable sync → verify historical entries appear in W8Trackr logbook with source badges

### Tests for User Story 2 (TDD Required)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T029 [P] [US2] Unit test for fetchHistoricalWeights() with mock in W8TrackrTests/HealthSyncManagerTests.swift
- [ ] T030 [P] [US2] Unit test for mapHealthSampleToWeightEntry() in W8TrackrTests/HealthSyncManagerTests.swift
- [ ] T031 [P] [US2] Unit test for duplicate detection during import in W8TrackrTests/HealthSyncManagerTests.swift
- [ ] T032 [P] [US2] Unit test for source attribution mapping in W8TrackrTests/WeightEntryHealthTests.swift

### Implementation for User Story 2

- [ ] T033 [US2] Implement fetchHistoricalWeights(from:to:) using HKSampleQuery in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T034 [US2] Implement mapHealthSampleToWeightEntry() with unit conversion in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T035 [US2] Implement duplicate detection by healthKitUUID in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T036 [US2] Create HealthImportView with progress indicator in W8Trackr/Views/HealthImportView.swift
- [ ] T037 [US2] Add import prompt on first sync enable in SettingsView flow
- [ ] T038 [US2] Implement batch import with progress updates in HealthSyncManager
- [ ] T039 [US2] Add source attribution badge to LogbookView entries in W8Trackr/Views/LogbookView.swift
- [ ] T040 [US2] Style imported entries visually distinct from manual entries in LogbookView

**Checkpoint**: User Story 2 complete - historical Health data imports with source attribution

---

## Phase 5: User Story 3 - Ongoing Bidirectional Sync (Priority: P3)

**Goal**: Weight entries stay synchronized between W8Trackr and Apple Health regardless of where they originate

**Independent Test**: Add entry in Apple Health via another app → W8Trackr shows it within 1 minute; edit in W8Trackr → Health updates

### Tests for User Story 3 (TDD Required)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T041 [P] [US3] Unit test for HKAnchoredObjectQuery incremental sync in W8TrackrTests/HealthSyncManagerTests.swift
- [ ] T042 [P] [US3] Unit test for conflict resolution (most recent wins) in W8TrackrTests/HealthSyncManagerTests.swift
- [ ] T043 [P] [US3] Unit test for deletion sync from Health in W8TrackrTests/HealthSyncManagerTests.swift
- [ ] T044 [P] [US3] Unit test for anchor persistence across sessions in W8TrackrTests/HealthSyncManagerTests.swift

### Implementation for User Story 3

- [ ] T045 [US3] Implement fetchChanges(since:) using HKAnchoredObjectQuery in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T046 [US3] Implement anchor persistence to UserDefaults in HealthSyncManager
- [ ] T047 [US3] Implement conflict resolution comparing syncVersion in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T048 [US3] Implement deletion sync handling from deletedObjects in HealthSyncManager
- [ ] T049 [US3] Setup HKObserverQuery on app launch when sync enabled in W8Trackr/Managers/HealthSyncManager.swift
- [ ] T050 [US3] Enable background delivery in W8TrackrApp.swift
- [ ] T051 [US3] Add foreground sync on app activation in W8TrackrApp.swift
- [ ] T052 [US3] Ensure chart data includes all sources in trend calculations

**Checkpoint**: User Story 3 complete - full bidirectional sync with conflict resolution

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T053 [P] Add accessibility labels to sync status and import progress views
- [ ] T054 [P] Add VoiceOver announcements for sync state changes
- [ ] T055 Verify SwiftLint passes on all new files
- [ ] T056 Performance test: verify <10s import for 365 days of data
- [ ] T057 Performance test: verify <5s export for new entries
- [ ] T058 Add confirmation dialog when disabling sync (destructive action)
- [ ] T059 Handle permission revocation gracefully with re-enable prompt
- [ ] T060 Run quickstart.md validation on device

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 can proceed independently after Foundational
  - US2 can proceed after Foundational (imports work even without export)
  - US3 depends on both US1 and US2 being complete (needs export AND import logic)
- **Polish (Phase 6)**: Depends on US1, US2, US3 being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independent of US1
- **User Story 3 (P3)**: Depends on US1 AND US2 - requires both export and import to exist

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD required by constitution)
- Protocol/infrastructure before business logic
- Manager methods before View integration
- Core implementation before UI polish

### Parallel Opportunities

- T003, T004 can run in parallel (different plist keys)
- T006, T007 can run in parallel (different test files)
- T014-T018 can run in parallel (independent test cases)
- T029-T032 can run in parallel (independent test cases)
- T041-T044 can run in parallel (independent test cases)
- T053, T054 can run in parallel (different accessibility concerns)

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all US1 tests together:
Task T014: "Unit test for requestAuthorization()"
Task T015: "Unit test for saveWeightToHealth()"
Task T016: "Unit test for updateWeightInHealth()"
Task T017: "Unit test for deleteWeightFromHealth()"
Task T018: "Unit test for graceful degradation"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Export)
4. **STOP and VALIDATE**: Test export flow on device
5. Ship MVP - users can export to Health

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Test export → Ship (MVP!)
3. Add User Story 2 → Test import → Ship
4. Add User Story 3 → Test bidirectional → Ship
5. Each story adds value without breaking previous stories

### Recommended Order for Solo Developer

1. Phase 1 (Setup): ~30 min
2. Phase 2 (Foundational): ~2-3 tasks/session
3. Phase 3 (US1 Export): MVP milestone
4. Phase 4 (US2 Import): Historical data support
5. Phase 5 (US3 Bidirectional): Full sync experience
6. Phase 6 (Polish): Quality and accessibility

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- TDD is NON-NEGOTIABLE per constitution - write failing tests first
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- MockHealthStore from HealthStoreProtocol enables unit testing without device
