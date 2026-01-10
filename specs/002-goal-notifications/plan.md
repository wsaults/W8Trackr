# Implementation Plan: Goal Progress Notifications

**Branch**: `002-goal-notifications` | **Date**: 2025-01-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-goal-notifications/spec.md`

## Summary

Goal progress notifications encourage users throughout their weight journey by celebrating milestones (25%, 50%, 75%, 100%), alerting when approaching target weight (within 5 lb/2.5 kg), and providing optional weekly summaries. Implementation leverages the existing `NotificationManager` pattern with new goal-aware logic and milestone tracking via SwiftData.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData, UserNotifications
**Storage**: SwiftData for milestone achievements; @AppStorage for notification preferences
**Testing**: XCTest with unit tests for progress calculations and milestone logic
**Target Platform**: iOS 18.0+
**Project Type**: iOS Mobile - single app
**Performance Goals**: Notifications triggered within 3 seconds of weight entry
**Constraints**: Local notifications only (no server infrastructure); must work offline
**Scale/Scope**: Single user, tracking up to 365+ days of weight data

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Simplicity-First | ✅ PASS | No new abstractions needed; extends existing NotificationManager pattern; progress calculation is pure functions |
| II. TDD (NON-NEGOTIABLE) | ✅ PASS | All progress calculations and milestone logic will have unit tests written first |
| III. User-Centered Quality | ✅ PASS | Notifications provide direct user value; accessible via VoiceOver; no destructive actions |

**Prohibited Patterns Check:**
- ❌ ViewModels: Not used - milestone state stored in SwiftData, preferences in @AppStorage
- ❌ NavigationView: Not applicable - notification feature has minimal UI
- ❌ Combine for UI: Not used - @Published only in service layer
- ❌ XCUITest: Not used - unit/integration tests only per constitution v1.1.0

## Project Structure

### Documentation (this feature)

```text
specs/002-goal-notifications/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
W8Trackr/
├── Models/
│   ├── WeightEntry.swift           # Existing - no changes needed
│   └── MilestoneAchievement.swift  # NEW - tracks achieved milestones
├── Managers/
│   └── NotificationManager.swift   # EXTEND - add goal notification logic
├── Views/
│   └── SettingsView.swift          # EXTEND - add notification preferences
└── Services/
    └── GoalProgressCalculator.swift # NEW - pure progress calculation logic

W8TrackrTests/
├── GoalProgressCalculatorTests.swift  # NEW - unit tests for calculations
├── MilestoneTrackerTests.swift        # NEW - unit tests for milestone logic
└── NotificationManagerTests.swift     # EXTEND - tests for goal notifications
```

**Structure Decision**: Extends existing iOS Mobile structure. New `MilestoneAchievement` model for SwiftData persistence. New `GoalProgressCalculator` service for testable pure functions. Extends `NotificationManager` for notification scheduling.

## Complexity Tracking

> No violations - feature aligns with all Constitution principles.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| (none) | — | — |

## Phase 0: Research (Next Step)

Research will focus on:
1. iOS UserNotifications best practices for motivational content
2. Weight tracking milestone patterns in similar apps
3. Optimal notification timing and frequency to avoid fatigue

## Phase 1: Design (After Research)

Design deliverables:
1. `data-model.md` - MilestoneAchievement schema, NotificationPreferences structure
2. `contracts/` - GoalProgressCalculator method signatures, NotificationManager extensions
3. `quickstart.md` - Manual testing checklist for all notification scenarios
