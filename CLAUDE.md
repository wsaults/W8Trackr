# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Build from command line
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -configuration Debug -sdk iphonesimulator build

# Run tests
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -sdk iphonesimulator test

# Run a specific test class
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -sdk iphonesimulator \
  -only-testing:W8TrackrTests/W8TrackrTests test
```

For development, open `W8Trackr.xcodeproj` in Xcode and use Cmd+R to build/run.

## Architecture Overview

### Core Stack
- **SwiftUI** + **SwiftData** (iOS 18.0+)
- **Swift Charts** for weight visualization

### Architectural Approach: Pure SwiftUI

This app uses native SwiftUI patterns without external architecture frameworks.

**State Management:**
- `@State` / `@Binding` for local view state
- `@Environment(\.modelContext)` for SwiftData access
- `@Query` for reactive data fetching
- `@AppStorage` for user preferences (persisted to UserDefaults)

**Service Layer:**
- `ObservableObject` managers for stateful services (e.g., `NotificationManager`)
- Instantiated as `@StateObject` where needed

**Design Principles:**
- **No ViewModels** - views own their state directly
- **Simple over clever** - avoid abstraction until needed
- **Direct @Query binding** - let SwiftData drive the UI
- **Minimal layers** - data flows from model to view without intermediaries

### Data Flow Pattern
The app uses SwiftData with `@Query` for real-time data binding. The model container is configured at the app level (`W8TrackrApp.swift`) and accessed via `@Environment(\.modelContext)`.

**Simulator vs Device**: `ContentView` uses `#if targetEnvironment(simulator)` to inject sample data for previews, while device builds use live `@Query` data.

### Key Architectural Decisions

**Weight Unit Handling**: `WeightEntry` stores values in original units with a `weightUnit` string field. Conversion happens at display time via `weightValue(in:)` method. User preference stored in `@AppStorage("preferredWeightUnit")`.

**Chart Data Pipeline** (`WeightTrendChartView`):
1. Entries filtered by date range
2. Grouped by day for trend line (daily averages)
3. Linear regression for 1-day-ahead prediction
4. Combined into `[ChartEntry]` with type flags for rendering

**Settings Persistence**: User preferences (`goalWeight`, `preferredWeightUnit`, `reminderTime`) use `@AppStorage` and `UserDefaults` rather than SwiftData.

### View Hierarchy
```
W8TrackrApp
└── ContentView (TabView)
    ├── SummaryView → CurrentWeightView, ChartSectionView → WeightTrendChartView
    ├── LogbookView → HistorySectionView
    └── SettingsView
```

Modal: `WeightEntryView` (sheet from SummaryView/LogbookView for add/edit)

### Notification System
`NotificationManager` is an `ObservableObject` handling daily reminder scheduling via `UNUserNotificationCenter`. Instantiated as `@StateObject` in `SettingsView`.

## Code Quality

### SwiftLint
The project uses [SwiftLint](https://github.com/realm/SwiftLint) for code style enforcement and catching common issues.

**Installation:**
```bash
brew install swiftlint
```

**Usage:**
- SwiftLint runs automatically during Xcode builds (via Run Script build phase)
- Run manually: `swiftlint lint --config .swiftlint.yml`

**Configuration:** `.swiftlint.yml` is tuned for SwiftUI/SwiftData patterns:
- Relaxed line length (150 warning, 200 error) for SwiftUI modifier chains
- Disabled rules that conflict with SwiftUI patterns (nesting, function_body_length)
- Custom rule to warn about print statements in production code

## Additional Guidelines

### SwiftUI Conventions
See [.claude/rules/swiftui.md](.claude/rules/swiftui.md) for:
- Preview patterns (iOS 18+ PreviewModifier)
- Available preview modifiers
- Creating new preview modifiers
