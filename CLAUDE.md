# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Rules

Detailed coding patterns and conventions are in `.claude/rules/`:

| File | Purpose |
|------|---------|
| `swift.md` | Swift language patterns, naming, error handling |
| `swiftui.md` | View architecture, state management, composition |
| `swiftdata.md` | Model definitions, queries, mutations |
| `ios.md` | Platform conventions, notifications, lifecycle |

**Always reference these rules** when writing or modifying code.

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

### Project Structure

```
W8Trackr/
├── W8TrackrApp.swift           # App entry point, ModelContainer config
├── Models/
│   └── WeightEntry.swift       # @Model with unit conversion logic
├── Views/
│   ├── ContentView.swift       # Root TabView
│   ├── SummaryView.swift       # Dashboard with chart
│   ├── LogbookView.swift       # History list
│   ├── SettingsView.swift      # User preferences
│   ├── AddWeightView.swift     # Entry modal
│   └── ...                     # Supporting views
└── Managers/
    └── NotificationManager.swift   # Daily reminders
```

### Data Flow Pattern

The app uses SwiftData with `@Query` for real-time data binding:
- Model container configured at app level (`W8TrackrApp.swift`)
- Views access data via `@Query` (read) and `@Environment(\.modelContext)` (write)
- User preferences use `@AppStorage` / `UserDefaults` (not SwiftData)

**Simulator vs Device**: `ContentView` uses `#if targetEnvironment(simulator)` to inject sample data for previews.

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

<<<<<<< HEAD
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
=======
## Code Style Quick Reference

- **Navigation**: Use `NavigationStack` (not NavigationView)
- **State**: `@State` for local, `@Binding` for passed, `@StateObject` for owned ObservableObject
- **Empty states**: Use `ContentUnavailableView`
- **Forms**: Structure with `Section` + header/footer
- **Alerts**: Use modern `.alert(title, isPresented:)` API
- **Previews**: Use iOS 18 `#Preview(traits:)` with `PreviewModifier`
>>>>>>> c0de58c (Add Claude Code rules for Swift/SwiftUI/iOS patterns)

## Active Technologies
- Swift 5.9+ + HealthKit framework, SwiftUI, SwiftData (001-apple-health-sync)
- SwiftData (existing WeightEntry model, extended with sync metadata) (001-apple-health-sync)
- Swift 5.9+ + SwiftUI, SwiftData, UserNotifications (002-goal-notifications)
- SwiftData for milestone achievements; @AppStorage for notification preferences (002-goal-notifications)
- Swift 5.9+ + SwiftUI, SwiftData, UIKit (for UIActivityViewController), Core Graphics (for image generation) (003-social-sharing)
- @AppStorage for sharing preferences; relies on MilestoneAchievement model from 002-goal-notifications (003-social-sharing)
- Swift 5.9+ + WidgetKit, SwiftUI, SwiftData (004-ios-widget)
- SwiftData via App Group shared container (004-ios-widget)
- Swift 6 (upgrading from Swift 5.9+) + SwiftUI, SwiftData, Swift Charts, WidgetKit, HealthKi (005-ios26-swift6-upgrade)
- SwiftData via ModelContainer (with App Group for widget) (005-ios26-swift6-upgrade)

## Recent Changes
- 001-apple-health-sync: Added Swift 5.9+ + HealthKit framework, SwiftUI, SwiftData
