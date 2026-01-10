# Implementation Plan: iOS Home Screen Widget

**Branch**: `004-ios-widget` | **Date**: 2025-01-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-ios-widget/spec.md`

## Summary

Add an iOS home screen widget that displays the user's current weight and goal progress at a glance. The widget will be a WidgetKit extension that shares data with the main app via App Groups, supporting small and medium sizes with tap-to-open functionality.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: WidgetKit, SwiftUI, SwiftData
**Storage**: SwiftData via App Group shared container
**Testing**: XCTest (unit tests only - no UI tests per constitution)
**Target Platform**: iOS 18.0+
**Project Type**: Mobile (iOS app with widget extension)
**Performance Goals**: Widget timeline generation < 100ms, smooth 60fps rendering
**Constraints**: Widget must work offline with cached data, respect system appearance
**Scale/Scope**: Single widget with 2 size variants (small, medium)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status |
|-----------|-------------|--------|
| I. Simplicity-First | No ViewModels, no unnecessary abstractions | ✅ Widget uses direct SwiftData access |
| I. Simplicity-First | Direct data flow | ✅ @Query-equivalent for widget timeline |
| II. TDD | Tests before implementation | ✅ Will write widget data provider tests first |
| II. TDD | No UI tests (XCUITest) | ✅ Manual widget testing only |
| III. User-Centered | Accessibility (VoiceOver, Dynamic Type) | ✅ Widget will support both |
| III. User-Centered | Light/dark mode | ✅ System appearance respected |
| Technical Standards | iOS 18.0+ | ✅ Target platform matches |
| Technical Standards | SwiftUI for UI | ✅ Widgets are SwiftUI-native |
| Technical Standards | SwiftData for persistence | ✅ Shared container access |

**Gate Status**: ✅ PASSED - No violations

## Project Structure

### Documentation (this feature)

```text
specs/004-ios-widget/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
W8Trackr/                        # Main app (existing)
├── Models/
│   └── WeightEntry.swift        # Existing model (to be shared)
├── Views/                       # Existing views
├── Managers/                    # Existing managers
└── W8TrackrApp.swift           # Entry point

W8TrackrWidget/                  # NEW: Widget extension target
├── W8TrackrWidget.swift         # Widget configuration & entry point
├── W8TrackrWidgetBundle.swift   # Widget bundle (if multiple widgets)
├── Provider/
│   └── WeightWidgetProvider.swift  # Timeline provider
├── Views/
│   ├── SmallWidgetView.swift    # Small size layout
│   └── MediumWidgetView.swift   # Medium size layout
├── Models/
│   └── WidgetEntry.swift        # Timeline entry model
└── Assets.xcassets              # Widget assets

Shared/                          # NEW: Shared code between app & widget
├── DataAccess/
│   └── SharedModelContainer.swift  # App Group container configuration
└── Extensions/
    └── WeightEntry+Widget.swift    # Widget-specific helpers

W8TrackrTests/                   # Existing test target
├── TrendCalculatorTests.swift   # Existing
├── W8TrackrTests.swift          # Existing
└── WidgetProviderTests.swift    # NEW: Widget timeline tests
```

**Structure Decision**: Mobile app with widget extension. Shared code extracted to `Shared/` folder for App Group data access. Widget extension follows Apple's recommended WidgetKit structure.

## Complexity Tracking

> No violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | - | - |
