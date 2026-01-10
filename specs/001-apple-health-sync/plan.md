# Implementation Plan: Apple Health Integration

**Branch**: `001-apple-health-sync` | **Date**: 2025-01-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-apple-health-sync/spec.md`

## Summary

Enable bidirectional synchronization between W8Trackr weight entries and Apple Health. Users can export their W8Trackr entries to Health (P1), import existing Health data (P2), and maintain ongoing sync with external sources like smart scales (P3). The implementation uses HealthKit with an ObservableObject manager following the app's existing architecture patterns.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: HealthKit framework, SwiftUI, SwiftData
**Storage**: SwiftData (existing WeightEntry model, extended with sync metadata)
**Testing**: XCTest (unit tests for sync logic, integration tests for HealthKit interactions)
**Target Platform**: iOS 18.0+
**Project Type**: Mobile (single iOS app)
**Performance Goals**: <5s sync for new entries, <10s for 365-day historical import, 60fps UI maintained
**Constraints**: Requires HealthKit authorization, graceful degradation when unavailable, offline-capable with queued sync
**Scale/Scope**: Single user, unlimited weight entries, full historical sync

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Simplicity-First Architecture

| Rule | Status | Notes |
|------|--------|-------|
| No ViewModels | ✅ PASS | HealthSyncManager is an ObservableObject service, not a ViewModel |
| No unnecessary abstractions | ✅ PASS | Direct HealthKit calls from manager, no repository layer |
| Direct data flow | ✅ PASS | @Query for WeightEntry, manager for HealthKit operations |
| YAGNI | ✅ PASS | Only sync features specified, no speculative additions |

### II. Test-Driven Development (NON-NEGOTIABLE)

| Rule | Status | Notes |
|------|--------|-------|
| TDD cycle | ✅ REQUIRED | Tests written before implementation per constitution |
| Unit tests for logic | ✅ REQUIRED | Sync conflict resolution, unit conversion, duplicate detection |
| Integration tests | ✅ REQUIRED | HealthKit permission flow, import/export cycles |

### III. User-Centered Quality

| Rule | Status | Notes |
|------|--------|-------|
| SwiftLint enforcement | ✅ REQUIRED | All new code must pass |
| Accessibility | ✅ REQUIRED | Sync status, import progress must be accessible |
| Error states | ✅ REQUIRED | Permission denied, sync failed, offline states |
| Performance | ✅ REQUIRED | <10s import for 365 days per SC-004 |
| Destructive actions | ✅ REQUIRED | Import confirmation, disable sync confirmation |

**Gate Result**: ✅ PASS - No violations, proceed to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/001-apple-health-sync/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (HealthKit interactions)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
W8Trackr/
├── W8TrackrApp.swift           # Add HealthKit authorization check
├── Models/
│   └── WeightEntry.swift       # Extend with sync metadata fields
├── Managers/
│   ├── NotificationManager.swift   # Existing
│   └── HealthSyncManager.swift     # NEW: HealthKit sync logic
├── Views/
│   ├── SettingsView.swift      # Add Health sync toggle section
│   ├── LogbookView.swift       # Show source attribution badges
│   └── HealthImportView.swift  # NEW: Import progress/confirmation
└── Info.plist                  # HealthKit usage descriptions

W8TrackrTests/
├── HealthSyncManagerTests.swift    # NEW: Unit tests for sync logic
└── WeightEntryHealthTests.swift    # NEW: Unit tests for model extensions
```

**Structure Decision**: iOS mobile pattern. New files follow existing conventions:
- Manager in `Managers/` directory (like NotificationManager)
- Views in `Views/` directory
- Model extensions in existing `WeightEntry.swift`

## Complexity Tracking

> **No violations to justify** - design follows constitution principles
