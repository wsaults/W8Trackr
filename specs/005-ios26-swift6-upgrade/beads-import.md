# iOS 26 and Swift 6 Platform Upgrade - Beads Import

**Feature**: 005-ios26-swift6-upgrade
**Generated**: 2025-01-10
**Source**: specs/005-ios26-swift6-upgrade/tasks.md

## Epic Structure

```
iOS 26 Swift 6 Upgrade (epic)
├── Setup (epic) - 4 tasks
├── Foundational (epic) - 17 tasks ← blocks all US*
├── US1: App Continues Working (epic) - 9 tasks 🎯 MVP
├── US2: Clean Build (epic) - 12 tasks
├── US3: Modern Patterns (epic) - 6 tasks
└── Polish (epic) - 10 tasks ← depends on US1-3
```

## Create Commands

Run these commands to create the beads hierarchy:

```bash
# =============================================================================
# ROOT EPIC
# =============================================================================
bd create "iOS 26 Swift 6 Upgrade" -t epic -p 1 -d "Upgrade W8Trackr from iOS 18/Swift 5.9 to iOS 26/Swift 6 with strict concurrency and @Observable migration"

# =============================================================================
# PHASE 1: SETUP (4 tasks)
# =============================================================================
bd create "Setup: Build Configuration" -t epic -p 1 -d "Configure project for Swift 6 migration path"

bd create "Enable complete concurrency checking in W8Trackr.xcodeproj" -t task -p 1 -d "Build Settings → Strict Concurrency Checking → Complete"
bd create "Enable complete concurrency checking for W8TrackrTests target" -t task -p 1 -d "W8Trackr.xcodeproj test target"
bd create "Build project and capture concurrency warnings" -t task -p 1 -d "Save to migration-warnings.txt"
bd create "Run existing test suite and verify all tests pass" -t task -p 1 -d "Baseline verification before migration"

# =============================================================================
# PHASE 2: FOUNDATIONAL (17 tasks) - BLOCKS ALL USER STORIES
# =============================================================================
bd create "Foundational: Core Service Migration" -t epic -p 1 -d "Migrate ObservableObject classes to @Observable + @MainActor. Blocks view updates."

# NotificationManager Migration
bd create "Add @MainActor to NotificationManager class" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "Replace ObservableObject with @Observable macro" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "Remove all @Published property wrappers" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "Convert requestNotificationPermission to async" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "Replace DispatchQueue.main.async with direct assignment" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "Update init() to use Task for async operations" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"
bd create "Convert scheduleNotification to async if needed" -t task -p 1 -d "W8Trackr/Managers/NotificationManager.swift"

# HealthKitManager Migration
bd create "Add @MainActor to HealthKitManager class" -t task -p 1 -d "W8Trackr/Managers/HealthKitManager.swift"
bd create "Replace ObservableObject with @Observable in HealthKitManager" -t task -p 1 -d "W8Trackr/Managers/HealthKitManager.swift"
bd create "Remove @Published property wrappers from HealthKitManager" -t task -p 1 -d "W8Trackr/Managers/HealthKitManager.swift"
bd create "Convert requestAuthorization to async" -t task -p 1 -d "W8Trackr/Managers/HealthKitManager.swift"
bd create "Convert syncWeightToHealthKit to async" -t task -p 1 -d "W8Trackr/Managers/HealthKitManager.swift"
bd create "Replace DispatchQueue.main.async in HealthKitManager" -t task -p 1 -d "W8Trackr/Managers/HealthKitManager.swift"
bd create "Verify static let shared is safe with @MainActor" -t task -p 1 -d "W8Trackr/Managers/HealthKitManager.swift"

# Other Managers
bd create "Review NotificationScheduler for Sendable conformance" -t task -p 1 -d "W8Trackr/Managers/NotificationScheduler.swift"
bd create "Review DataExporter for concurrency safety" -t task -p 1 -d "W8Trackr/Managers/DataExporter.swift"
bd create "Review TrendCalculator for Sendable conformance" -t task -p 1 -d "W8Trackr/Analytics/TrendCalculator.swift"

# =============================================================================
# PHASE 3: US1 - APP CONTINUES WORKING (9 tasks) 🎯 MVP
# =============================================================================
bd create "US1: App Continues Working" -t epic -p 1 -d "Ensure all existing functionality works identically after migration. Zero regression."

bd create "US1: Update SettingsView @StateObject to @State for notificationManager" -t task -p 1 -d "W8Trackr/Views/SettingsView.swift"
bd create "US1: Update SettingsView @ObservedObject to @State for healthKitManager" -t task -p 1 -d "W8Trackr/Views/SettingsView.swift"
bd create "US1: Update async calls in SettingsView to Task pattern" -t task -p 1 -d "W8Trackr/Views/SettingsView.swift"
bd create "US1: Search and update other @StateObject/@ObservedObject usage" -t task -p 1 -d "W8Trackr/Views/"
bd create "US1: Build and verify zero errors in main app" -t task -p 1 -d "Build verification"
bd create "US1: Run all unit tests - verify 100% pass rate" -t task -p 1 -d "Test verification"
bd create "US1: Verify WeightEntry model requires no changes" -t task -p 1 -d "W8Trackr/Models/WeightEntry.swift"
bd create "US1: Verify @Query usage requires no changes" -t task -p 1 -d "SwiftData views verification"
bd create "US1: Test with existing user data - verify all entries display" -t task -p 1 -d "Data preservation test"

# =============================================================================
# PHASE 4: US2 - CLEAN BUILD (12 tasks)
# =============================================================================
bd create "US2: Clean Build" -t epic -p 2 -d "Build with zero errors and zero warnings on Swift 6"

bd create "US2: Address remaining Sendable warnings" -t task -p 2 -d "W8Trackr/"
bd create "US2: Address remaining actor isolation warnings" -t task -p 2 -d "W8Trackr/"
bd create "US2: Add nonisolated to non-MainActor methods" -t task -p 2 -d "Where appropriate"
bd create "US2: Verify no deprecated API warnings for iOS 26" -t task -p 2 -d "Deprecation check"
bd create "US2: Add @MainActor to NotificationManager tests" -t task -p 2 -d "W8TrackrTests/"
bd create "US2: Add @MainActor to HealthKitManager tests" -t task -p 2 -d "W8TrackrTests/"
bd create "US2: Convert test methods to async throws where needed" -t task -p 2 -d "W8TrackrTests/"
bd create "US2: Build test target and verify zero errors" -t task -p 2 -d "Test target build"
bd create "US2: Update deployment target to iOS 26.0" -t task -p 2 -d "W8Trackr.xcodeproj all targets"
bd create "US2: Update Swift Language Version to Swift 6" -t task -p 2 -d "W8Trackr.xcodeproj all targets"
bd create "US2: Clean build folder and full rebuild" -t task -p 2 -d "Cmd+Shift+K then Cmd+B"
bd create "US2: Verify zero warnings in first-party code" -t task -p 2 -d "Final build verification"

# =============================================================================
# PHASE 5: US3 - MODERN PATTERNS (6 tasks)
# =============================================================================
bd create "US3: Modern Patterns" -t epic -p 3 -d "Adopt modern Swift 6 patterns where beneficial"

bd create "US3: Review and simplify DispatchQueue patterns" -t task -p 3 -d "W8Trackr/"
bd create "US3: Ensure structured concurrency (no detached tasks)" -t task -p 3 -d "Code review"
bd create "US3: Verify @Observable property-level UI updates" -t task -p 3 -d "Simulator testing"
bd create "US3: Update constitution.md platform requirements" -t task -p 3 -d ".specify/memory/constitution.md"
bd create "US3: Update CLAUDE.md technical standards" -t task -p 3 -d "CLAUDE.md"
bd create "US3: Update code comments referencing old patterns" -t task -p 3 -d "Documentation cleanup"

# =============================================================================
# PHASE 6: POLISH (10 tasks)
# =============================================================================
bd create "Polish: Final Validation" -t epic -p 4 -d "Final verification and cleanup"

bd create "Run SwiftLint and fix warnings" -t task -p 4 -d "Lint check"
bd create "Delete migration-warnings.txt" -t task -p 4 -d "Cleanup"
bd create "Manual smoke test: App launch and weight entry" -t task -p 4 -d "Manual test"
bd create "Manual smoke test: Chart display and scrolling" -t task -p 4 -d "Manual test"
bd create "Manual smoke test: Settings and notifications" -t task -p 4 -d "Manual test"
bd create "Manual smoke test: HealthKit sync" -t task -p 4 -d "Manual test"
bd create "Manual smoke test: Widget" -t task -p 4 -d "Manual test"
bd create "Manual smoke test: Light and dark mode" -t task -p 4 -d "Manual test"
bd create "Final test suite run - all tests must pass" -t task -p 4 -d "Final verification"
bd create "Archive build for App Store" -t task -p 4 -d "Production archive"
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

# US1 blocks US2 and US3 (must verify app works before changing build settings)
bd dep add <US2-epic-id> <US1-epic-id> --type blocks
bd dep add <US3-epic-id> <US1-epic-id> --type blocks

# Polish depends on all user stories
bd dep add <Polish-epic-id> <US1-epic-id> --type blocks
bd dep add <Polish-epic-id> <US2-epic-id> --type blocks
bd dep add <Polish-epic-id> <US3-epic-id> --type blocks
```

## Task Summary

| Phase | Epic | Tasks | Priority |
|-------|------|-------|----------|
| Setup | Build Configuration | 4 | P1 |
| Foundational | Core Service Migration | 17 | P1 |
| US1 | App Continues Working | 9 | P1 🎯 MVP |
| US2 | Clean Build | 12 | P2 |
| US3 | Modern Patterns | 6 | P3 |
| Polish | Final Validation | 10 | P4 |
| **Total** | | **58** | |

## MVP Scope

Complete through **US1: App Continues Working** for minimum viable upgrade:
- Setup (4 tasks)
- Foundational (17 tasks)
- US1 (9 tasks)
- **Total MVP: 30 tasks**

At MVP checkpoint:
- All service classes migrated to @Observable
- Views updated with new property wrappers
- All existing functionality verified working
- Can remain on Swift 5 language mode for stability if needed

## Dependency Graph

```
Setup (P1)
   │
   ▼
Foundational (P1) ─────────────────────┐
   │                                    │
   ▼                                    │
US1 (P1) 🎯 MVP ────────────────────────┤
   │                                    │
   ├──────────┬──────────┐              │
   ▼          ▼          │              │
US2 (P2)   US3 (P3)      │              │
   │          │          │              │
   └──────────┴──────────┘              │
              │                         │
              ▼                         │
         Polish (P4) ◄──────────────────┘
```

**Note**: US2 and US3 both depend on US1 (unlike typical features where user stories are independent). This is because the Swift 6 build settings change in US2 could mask issues that US1 is designed to catch.

## Notes

- **TDD Approach**: Existing test suite validates zero regression - no new failing tests needed
- **No UI Tests**: XCUITest prohibited per constitution - manual testing validates UI
- **SwiftLint**: All code must pass SwiftLint before merge
- **Rollback Strategy**: Keep commits granular for easy rollback at any phase
- This is a refactoring/migration task, not a feature addition

## Sources

- [Beads CLAUDE.md](https://github.com/steveyegge/beads/blob/main/CLAUDE.md)
- [Beads Quickstart](https://github.com/steveyegge/beads/blob/main/docs/QUICKSTART.md)
- [Gastown README](https://github.com/steveyegge/gastown)
