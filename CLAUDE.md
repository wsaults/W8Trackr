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
- **Composable Architecture** (dependency added, migration pending)

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

Modal: `AddWeightView` (sheet from SummaryView/LogbookView)

### Notification System
`NotificationManager` is an `ObservableObject` handling daily reminder scheduling via `UNUserNotificationCenter`. Instantiated as `@StateObject` in `SettingsView`.
