# W8Trackr

A modern iOS weight tracking application built with SwiftUI and SwiftData.

## Overview

W8Trackr is a clean, intuitive weight tracking application that helps users monitor their weight progress over time. The app features a beautiful, modern UI with interactive charts and a comprehensive history view.

## Features

- 📊 Interactive weight tracking charts
- 📅 Historical weight entry view
- ➕ Easy weight entry addition
- 🔄 Real-time data updates
- 💾 Persistent data storage using SwiftData
- 🎨 Modern, clean UI design

## Requirements

- iOS 18.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/wsaults/W8Trackr.git
```

2. Open `W8Trackr.xcodeproj` in Xcode

3. Build and run the project (⌘R)

## Build Commands

Build, test, and run from the command line using `xcodebuild`:

```bash
# Build for simulator
xcodebuild -scheme W8Trackr -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests
xcodebuild -scheme W8Trackr -destination 'platform=iOS Simulator,name=iPhone 17' test

# Archive for distribution
xcodebuild -scheme W8Trackr -archivePath ./build/W8Trackr.xcarchive archive

# Build and run on simulator
xcrun simctl boot "iPhone 17"
xcodebuild -scheme W8Trackr -destination 'platform=iOS Simulator,name=iPhone 17' build
xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/W8Trackr.app
xcrun simctl launch booted com.willsaults.W8Trackr
```

## Project Structure

```
W8Trackr/
├── W8Trackr/
│   ├── W8TrackrApp.swift     # App entry point with ModelContainer
│   ├── ContentView.swift     # Root tab navigation
│   ├── Models/               # SwiftData @Model types
│   ├── Views/                # SwiftUI views
│   ├── Managers/             # Service managers (HealthKit, Notifications)
│   ├── Algorithms/           # Trend smoothing, predictions
│   └── Preview Content/      # Preview modifiers and sample data
└── W8TrackrTests/            # Unit tests
```

## Architecture

W8Trackr uses a **View-first SwiftUI architecture** that leverages SwiftUI's built-in state management:

- **SwiftUI Views** - Declarative UI with `@State`, `@Binding`, and `@Environment`
- **SwiftData** - Persistence via `@Model` types and `@Query` for reactive data fetching
- **Service Managers** - Singleton managers (`HealthKitManager`, `NotificationManager`) for external integrations
- **Pure Functions** - Algorithm logic (trend smoothing, predictions) in testable, stateless functions

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI Views                     │
│         (State management via @State, @Query)        │
├─────────────────────────────────────────────────────┤
│   SwiftData ModelContext    │   Service Managers    │
│   (@Environment, @Query)    │   (HealthKit, etc.)   │
├─────────────────────────────────────────────────────┤
│              @Model Types (WeightEntry)              │
└─────────────────────────────────────────────────────┘
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

Will Saults

## Acknowledgments

- Built with SwiftUI and SwiftData
- Charts powered by Swift Charts 
