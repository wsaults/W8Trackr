# Implementation Plan: iOS 26 and Swift 6 Platform Upgrade

**Branch**: `005-ios26-swift6-upgrade` | **Date**: 2025-01-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-ios26-swift6-upgrade/spec.md`

## Summary

Upgrade W8Trackr from iOS 18/Swift 5.9 to iOS 26/Swift 6 platform. Primary work involves adopting Swift 6 strict concurrency (data race safety), migrating `ObservableObject` services to `@Observable` macro, and ensuring all existing functionality continues working. The upgrade enables modern concurrency patterns and prepares codebase for default MainActor isolation.

## Technical Context

**Language/Version**: Swift 6 (upgrading from Swift 5.9+)
**Primary Dependencies**: SwiftUI, SwiftData, Swift Charts, WidgetKit, HealthKit
**Storage**: SwiftData via ModelContainer (with App Group for widget)
**Testing**: XCTest (unit tests only - no UI tests per constitution)
**Target Platform**: iOS 26+ (upgrading from iOS 18.0+)
**Project Type**: Mobile iOS application with widget extension
**Performance Goals**: 60fps chart rendering, zero regressions in existing behavior
**Constraints**: Zero data loss, backward-compatible data model
**Scale/Scope**: Single app with ~15 source files requiring concurrency updates

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status |
|-----------|-------------|--------|
| I. Simplicity-First | No ViewModels, no unnecessary abstractions | ✅ `@Observable` simpler than `ObservableObject` |
| I. Simplicity-First | Direct data flow | ✅ Preserved - @Query still binds directly |
| II. TDD | Tests before implementation | ✅ Existing tests validate zero regression |
| II. TDD | No UI tests (XCUITest) | ✅ Manual testing only |
| III. User-Centered | SwiftLint enforcement | ✅ Will update SwiftLint rules if needed |
| III. User-Centered | Accessibility | ✅ No accessibility regressions |
| Technical Standards | iOS 18.0+ minimum | ⚠️ **UPDATE REQUIRED**: Change to iOS 26+ |
| Technical Standards | Swift 5.9+ | ⚠️ **UPDATE REQUIRED**: Change to Swift 6 |
| Technical Standards | SwiftUI for all UI | ✅ No changes needed |
| Technical Standards | SwiftData for persistence | ✅ No changes needed |

**Gate Status**: ✅ PASSED with Constitution Update Required

**Constitution Update Required**:
```markdown
## Technical Standards

**Platform Requirements:**
- iOS 26.0+ minimum deployment target  (was: iOS 18.0+)
- Swift 6 with strict concurrency       (was: Swift 5.9+)
- SwiftUI for all UI
- SwiftData for persistence
- Swift Charts for visualization
```

## Project Structure

### Documentation (this feature)

```text
specs/005-ios26-swift6-upgrade/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── quickstart.md        # Migration checklist
├── constitution-update.md  # Proposed constitution changes
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
W8Trackr/                           # Main app
├── W8TrackrApp.swift               # Entry point - add @MainActor
├── Models/
│   └── WeightEntry.swift           # @Model - no changes needed
├── Views/
│   ├── ContentView.swift           # Views - may need @MainActor
│   ├── SummaryView.swift
│   ├── LogbookView.swift
│   ├── SettingsView.swift          # Uses NotificationManager
│   ├── WeightEntryView.swift
│   └── ...
├── Managers/
│   ├── NotificationManager.swift   # MAJOR: ObservableObject → @Observable
│   ├── HealthKitManager.swift      # MAJOR: ObservableObject → @Observable
│   └── NotificationScheduler.swift # Static struct - may need nonisolated
└── Analytics/
    └── TrendCalculator.swift       # Struct - may need Sendable

W8TrackrWidget/                     # Widget extension
├── Provider/
│   └── WeightWidgetProvider.swift  # Timeline provider - check concurrency
└── Views/
    └── ...

Shared/                             # Shared between app and widget
├── DataAccess/
│   └── SharedModelContainer.swift  # Check Sendable requirements
└── ...

W8TrackrTests/                      # Test target
├── TrendCalculatorTests.swift      # May need @MainActor annotations
└── ...
```

**Structure Decision**: Existing structure preserved. Changes are in-place refactoring of concurrency patterns, not structural reorganization.

## Key Migration Areas

### 1. ObservableObject → @Observable Migration

| File | Current Pattern | Target Pattern |
|------|-----------------|----------------|
| `NotificationManager.swift` | `class: ObservableObject` + `@Published` | `@Observable @MainActor class` |
| `HealthKitManager.swift` | `class: ObservableObject` + `@Published` | `@Observable @MainActor class` |

### 2. Async/Await Migration

| File | Current Pattern | Target Pattern |
|------|-----------------|----------------|
| `NotificationManager.swift` | Completion handlers + `DispatchQueue.main.async` | `async/await` |
| `HealthKitManager.swift` | Completion handlers | `async/await` |

### 3. View Property Wrapper Updates

| Current | New (with @Observable) |
|---------|------------------------|
| `@StateObject` | `@State` |
| `@ObservedObject` | Remove (use @State or @Environment) |

### 4. Test Updates

Tests for `@MainActor` classes require async test methods:
```swift
@MainActor
func testNotificationManager() async throws {
    let manager = NotificationManager()
    // ...
}
```

## Complexity Tracking

> No constitution violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | - | - |

## Migration Phases

### Phase 1: Preparation
- Enable Swift 5 complete concurrency checking
- Identify all warnings

### Phase 2: Core Services
- Migrate NotificationManager to @Observable + @MainActor
- Migrate HealthKitManager to @Observable + @MainActor

### Phase 3: Views
- Update @StateObject → @State for @Observable classes
- Add @MainActor where needed (may be automatic in iOS 26)

### Phase 4: Tests
- Update test methods for @MainActor classes

### Phase 5: Final
- Switch to Swift 6 language mode
- Update minimum deployment target to iOS 26
- Update constitution with new platform requirements
