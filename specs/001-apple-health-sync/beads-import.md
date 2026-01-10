# Apple Health Integration - Beads Import

**Feature**: 001-apple-health-sync
**Generated**: 2025-01-09
**Source**: specs/001-apple-health-sync/tasks.md

## Epic Structure

```
Apple Health Integration (epic)
├── Setup (epic)
├── Foundational (epic) ← blocks all US*
├── US1: Export to Health (epic) 🎯 MVP
├── US2: Import from Health (epic)
├── US3: Bidirectional Sync (epic) ← depends on US1 + US2
└── Polish (epic) ← depends on US1-3
```

## Create Commands

Run these commands to create the beads hierarchy:

```bash
# =============================================================================
# ROOT EPIC
# =============================================================================
bd create "Apple Health Integration" -t epic -p 1 -d "Enable bidirectional sync between W8Trackr and Apple Health. P1: Export, P2: Import, P3: Bidirectional sync."

# =============================================================================
# PHASE 1: SETUP (5 tasks)
# =============================================================================
bd create "Setup: HealthKit Configuration" -t epic -p 1 -d "HealthKit capability configuration and testing infrastructure"

bd create "Add HealthKit capability to W8Trackr.xcodeproj" -t task -p 1 -d "Signing & Capabilities → Add HealthKit"
bd create "Add HealthKit background delivery entitlement" -t task -p 1 -d "W8Trackr/W8Trackr.entitlements"
bd create "Add NSHealthShareUsageDescription to Info.plist" -t task -p 1 -d "W8Trackr/Info.plist - read permission description"
bd create "Add NSHealthUpdateUsageDescription to Info.plist" -t task -p 1 -d "W8Trackr/Info.plist - write permission description"
bd create "Create HealthStoreProtocol for dependency injection" -t task -p 1 -d "W8Trackr/Managers/HealthStoreProtocol.swift - enables unit testing"

# =============================================================================
# PHASE 2: FOUNDATIONAL (8 tasks) - BLOCKS ALL USER STORIES
# =============================================================================
bd create "Foundational: Core Infrastructure" -t epic -p 1 -d "Core infrastructure that MUST be complete before ANY user story. TDD required."

# Tests first (TDD)
bd create "Unit test for WeightEntry sync fields" -t task -p 1 -d "W8TrackrTests/WeightEntryHealthTests.swift - test healthKitUUID, source, syncVersion, pendingHealthSync"
bd create "Unit test for HealthSyncManager initialization" -t task -p 1 -d "W8TrackrTests/HealthSyncManagerTests.swift - test init with mock protocol"

# Implementation
bd create "Extend WeightEntry with sync fields" -t task -p 1 -d "W8Trackr/Models/WeightEntry.swift - add healthKitUUID, source, syncVersion, pendingHealthSync"
bd create "Add WeightEntry computed properties" -t task -p 1 -d "W8Trackr/Models/WeightEntry.swift - add isImported, needsSync"
bd create "Create HealthSyncManager skeleton" -t task -p 1 -d "W8Trackr/Managers/HealthSyncManager.swift - ObservableObject with protocol injection"
bd create "Add @AppStorage keys for sync state" -t task -p 1 -d "HealthSyncManager - healthSyncEnabled, healthSyncAnchor, lastHealthSyncDate"
bd create "Implement HKHealthStore protocol conformance" -t task -p 1 -d "W8Trackr/Managers/HealthStoreProtocol.swift - extension for real HealthKit"
bd create "Add isHealthDataAvailable check" -t task -p 1 -d "W8Trackr/Managers/HealthSyncManager.swift - graceful degradation for iPad"

# =============================================================================
# PHASE 3: US1 - EXPORT TO HEALTH (15 tasks) 🎯 MVP
# =============================================================================
bd create "US1: Export Weight to Apple Health" -t epic -p 1 -d "MVP: Weight entries logged in W8Trackr automatically appear in Apple Health within 5 seconds"

# Tests first (TDD)
bd create "US1: Test requestAuthorization" -t task -p 1 -d "W8TrackrTests/HealthSyncManagerTests.swift - test auth flow with mock"
bd create "US1: Test saveWeightToHealth" -t task -p 1 -d "W8TrackrTests/HealthSyncManagerTests.swift - test export with sync metadata"
bd create "US1: Test updateWeightInHealth" -t task -p 1 -d "W8TrackrTests/HealthSyncManagerTests.swift - test update using syncVersion"
bd create "US1: Test deleteWeightFromHealth" -t task -p 1 -d "W8TrackrTests/HealthSyncManagerTests.swift - test delete using healthKitUUID"
bd create "US1: Test graceful degradation when auth denied" -t task -p 1 -d "W8TrackrTests/HealthSyncManagerTests.swift - test app works without Health"

# Implementation
bd create "US1: Implement requestAuthorization async" -t task -p 1 -d "W8Trackr/Managers/HealthSyncManager.swift"
bd create "US1: Implement saveWeightToHealth with sync metadata" -t task -p 1 -d "W8Trackr/Managers/HealthSyncManager.swift - HKMetadataKeySyncIdentifier"
bd create "US1: Implement updateWeightInHealth" -t task -p 1 -d "W8Trackr/Managers/HealthSyncManager.swift - use syncVersion for dedup"
bd create "US1: Implement deleteWeightFromHealth" -t task -p 1 -d "W8Trackr/Managers/HealthSyncManager.swift - delete by healthKitUUID"
bd create "US1: Add Health sync toggle to SettingsView" -t task -p 1 -d "W8Trackr/Views/SettingsView.swift - toggle section with auth flow"
bd create "US1: Hook save into weight entry creation" -t task -p 1 -d "Call HealthSyncManager.saveWeightToHealth on new entry"
bd create "US1: Hook update into weight entry edit" -t task -p 1 -d "Call HealthSyncManager.updateWeightInHealth on edit"
bd create "US1: Hook delete into weight entry removal" -t task -p 1 -d "Call HealthSyncManager.deleteWeightFromHealth on delete"
bd create "US1: Add error handling for auth denied" -t task -p 1 -d "HealthSyncManager - graceful degradation, no error shown"
bd create "US1: Add pendingHealthSync queue" -t task -p 1 -d "W8Trackr/Managers/HealthSyncManager.swift - offline support"

# =============================================================================
# PHASE 4: US2 - IMPORT FROM HEALTH (12 tasks)
# =============================================================================
bd create "US2: Import Weight from Apple Health" -t epic -p 2 -d "Import existing weight data from Apple Health into W8Trackr with source badges"

# Tests first (TDD)
bd create "US2: Test fetchHistoricalWeights" -t task -p 2 -d "W8TrackrTests/HealthSyncManagerTests.swift - test HKSampleQuery with mock"
bd create "US2: Test mapHealthSampleToWeightEntry" -t task -p 2 -d "W8TrackrTests/HealthSyncManagerTests.swift - test unit conversion"
bd create "US2: Test duplicate detection during import" -t task -p 2 -d "W8TrackrTests/HealthSyncManagerTests.swift - test healthKitUUID matching"
bd create "US2: Test source attribution mapping" -t task -p 2 -d "W8TrackrTests/WeightEntryHealthTests.swift - test source field values"

# Implementation
bd create "US2: Implement fetchHistoricalWeights" -t task -p 2 -d "W8Trackr/Managers/HealthSyncManager.swift - HKSampleQuery with date range"
bd create "US2: Implement mapHealthSampleToWeightEntry" -t task -p 2 -d "W8Trackr/Managers/HealthSyncManager.swift - unit conversion, source extraction"
bd create "US2: Implement duplicate detection" -t task -p 2 -d "W8Trackr/Managers/HealthSyncManager.swift - check healthKitUUID before insert"
bd create "US2: Create HealthImportView" -t task -p 2 -d "W8Trackr/Views/HealthImportView.swift - progress indicator, confirmation"
bd create "US2: Add import prompt on first sync enable" -t task -p 2 -d "SettingsView - show import dialog when enabling sync"
bd create "US2: Implement batch import with progress" -t task -p 2 -d "HealthSyncManager - import in batches, update progress"
bd create "US2: Add source attribution badge to LogbookView" -t task -p 2 -d "W8Trackr/Views/LogbookView.swift - Health icon for imported"
bd create "US2: Style imported entries distinctly" -t task -p 2 -d "LogbookView - visual differentiation from manual entries"

# =============================================================================
# PHASE 5: US3 - BIDIRECTIONAL SYNC (12 tasks)
# =============================================================================
bd create "US3: Ongoing Bidirectional Sync" -t epic -p 3 -d "Weight entries stay synchronized regardless of where they originate. Depends on US1 and US2."

# Tests first (TDD)
bd create "US3: Test HKAnchoredObjectQuery incremental sync" -t task -p 3 -d "W8TrackrTests/HealthSyncManagerTests.swift - test anchor-based fetch"
bd create "US3: Test conflict resolution (most recent wins)" -t task -p 3 -d "W8TrackrTests/HealthSyncManagerTests.swift - test syncVersion comparison"
bd create "US3: Test deletion sync from Health" -t task -p 3 -d "W8TrackrTests/HealthSyncManagerTests.swift - test deletedObjects handling"
bd create "US3: Test anchor persistence across sessions" -t task -p 3 -d "W8TrackrTests/HealthSyncManagerTests.swift - test UserDefaults anchor"

# Implementation
bd create "US3: Implement fetchChanges with HKAnchoredObjectQuery" -t task -p 3 -d "W8Trackr/Managers/HealthSyncManager.swift - incremental sync"
bd create "US3: Implement anchor persistence" -t task -p 3 -d "HealthSyncManager - save/restore HKQueryAnchor to UserDefaults"
bd create "US3: Implement conflict resolution" -t task -p 3 -d "W8Trackr/Managers/HealthSyncManager.swift - compare syncVersion, higher wins"
bd create "US3: Implement deletion sync handling" -t task -p 3 -d "HealthSyncManager - process deletedObjects from anchored query"
bd create "US3: Setup HKObserverQuery on app launch" -t task -p 3 -d "W8Trackr/Managers/HealthSyncManager.swift - background change detection"
bd create "US3: Enable background delivery" -t task -p 3 -d "W8TrackrApp.swift - enableBackgroundDelivery for bodyMass"
bd create "US3: Add foreground sync on app activation" -t task -p 3 -d "W8TrackrApp.swift - sync when app becomes active"
bd create "US3: Ensure chart includes all sources" -t task -p 3 -d "Trend calculations must include imported entries"

# =============================================================================
# PHASE 6: POLISH (8 tasks)
# =============================================================================
bd create "Polish: Cross-Cutting Concerns" -t epic -p 4 -d "Quality, accessibility, and performance validation"

bd create "Add accessibility labels to sync views" -t task -p 4 -d "Sync status, import progress - VoiceOver support"
bd create "Add VoiceOver announcements for sync state" -t task -p 4 -d "Announce sync enabled/disabled, import complete"
bd create "Verify SwiftLint passes on all new files" -t task -p 4 -d "Run swiftlint, fix any warnings"
bd create "Performance test: verify <10s import for 365 days" -t task -p 4 -d "SC-004 validation"
bd create "Performance test: verify <5s export for new entries" -t task -p 4 -d "SC-002 validation"
bd create "Add confirmation dialog when disabling sync" -t task -p 4 -d "Destructive action per constitution"
bd create "Handle permission revocation gracefully" -t task -p 4 -d "Show re-enable prompt, app continues working"
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

# US3 depends on US1 AND US2
bd dep add <US3-epic-id> <US1-epic-id> --type blocks
bd dep add <US3-epic-id> <US2-epic-id> --type blocks

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
| Setup | HealthKit Configuration | 5 | P1 |
| Foundational | Core Infrastructure | 8 | P1 |
| US1 | Export to Health | 15 | P1 🎯 MVP |
| US2 | Import from Health | 12 | P2 |
| US3 | Bidirectional Sync | 12 | P3 |
| Polish | Cross-Cutting | 8 | P4 |
| **Total** | | **60** | |

## MVP Scope

Complete through **US1: Export to Health** for minimum viable product:
- Setup (5 tasks)
- Foundational (8 tasks)
- US1 (15 tasks)
- **Total MVP: 28 tasks**

## Notes

- TDD is NON-NEGOTIABLE per constitution v1.1.0
- No UI tests (XCUITest) per constitution
- Tests must be written and fail before implementation
- Each user story is independently testable

## Sources

- [Beads CLAUDE.md](https://github.com/steveyegge/beads/blob/main/CLAUDE.md)
- [Beads Quickstart](https://github.com/steveyegge/beads/blob/main/docs/QUICKSTART.md)
- [Gastown README](https://github.com/steveyegge/gastown)
