# Technology Stack

**Analysis Date:** 2026-01-20

## Languages

**Primary:**
- Swift 5.0 (Xcode target) / Swift 6.2+ (project standard) - All application code

**Secondary:**
- Ruby 3.2 - Fastlane automation scripts

## Runtime

**Environment:**
- iOS 18.4+ (deployment target in Xcode)
- Xcode 16.3 (created with tooling version 1630)

**Package Manager:**
- Swift Package Manager (SPM) - No external packages currently used
- Bundler (Ruby) - Fastlane dependencies
- Lockfile: Gemfile present, no SPM Package.resolved (no dependencies)

## Frameworks

**Core:**
- SwiftUI - All UI components
- SwiftData - Persistence layer (iOS 18+ modern replacement for Core Data)
- HealthKit - Apple Health integration for weight/body fat sync

**System Integration:**
- CloudKit - iCloud sync via SwiftData automatic CloudKit backing
- UserNotifications - Daily reminders and smart notifications
- Network (NWPathMonitor) - Network connectivity monitoring
- AppIntents - Siri Shortcuts integration

**Testing:**
- XCTest - Unit and UI testing (built-in)

**Build/Dev:**
- SwiftLint - Code style linting (build phase)
- Fastlane - CI/CD automation, screenshots, TestFlight deployment

## Key Dependencies

**Critical (Apple Frameworks):**
- SwiftData - Data persistence, CloudKit sync
- HealthKit - Health app integration
- CloudKit - Cross-device data sync

**Infrastructure:**
- No third-party dependencies - Pure Apple frameworks

## Configuration

**Environment:**
- UserDefaults - User preferences (weight unit, goal weight, reminder time)
- App entitlements for iCloud/HealthKit
- `.env.default` - Fastlane build settings

**Key env vars (Fastlane):**
- `PROJECT_NAME` - W8Trackr
- `BUNDLE_ID` - com.saults.W8Trackr
- `API_KEY_PATH` - App Store Connect API key location

**Build:**
- `W8Trackr.xcodeproj/project.pbxproj` - Xcode project configuration
- `.swiftlint.yml` - Linting rules
- `fastlane/Fastfile` - Build lanes

## Platform Requirements

**Development:**
- macOS with Xcode 16.3+
- SwiftLint installed (`brew install swiftlint`)
- Ruby 3.2+ with Bundler for Fastlane

**Production:**
- App Store (iOS 18.4+)
- TestFlight for beta distribution
- GitHub Actions for CI/CD

## Build Commands

```bash
# Build
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -configuration Debug -sdk iphonesimulator build

# Run all tests
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -sdk iphonesimulator test

# Via Fastlane
bundle exec fastlane ios test
bundle exec fastlane ios build
bundle exec fastlane ios beta
```

---

*Stack analysis: 2026-01-20*
