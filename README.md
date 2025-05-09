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

## Project Structure

```
W8Trackr/
├── W8Trackr/              # Main app directory
│   ├── W8TrackrApp.swift  # App entry point
│   ├── ContentView.swift  # Main view
│   └── Models/           # Data models
├── W8TrackrTests/        # Unit tests
└── W8TrackrUITests/      # UI tests
```

## Architecture

The app is built using:
- SwiftUI for the user interface
- SwiftData for data persistence
- MVVM architecture pattern (TODO)
- Swift's latest features including Observation framework

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

Will Saults

## Acknowledgments

- Built with SwiftUI and SwiftData
- Charts powered by Swift Charts 
