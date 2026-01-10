# Quickstart: iOS 26 and Swift 6 Migration

**Feature Branch**: `005-ios26-swift6-upgrade`
**Created**: 2025-01-10

## Prerequisites

- Xcode 26 (beta or release)
- macOS supporting Xcode 26
- iOS 26 Simulator or device

## Migration Checklist

### Phase 1: Enable Concurrency Checking

1. **Enable complete concurrency checking**:
   - In Xcode: Build Settings → "Strict Concurrency Checking" → "Complete"
   - Build and note all warnings

2. **Review warning categories**:
   - `Sendable` conformance warnings
   - Actor isolation warnings
   - `@MainActor` requirement warnings

### Phase 2: Migrate Service Classes

#### NotificationManager.swift

```swift
// Step 1: Add @Observable and @MainActor
@Observable
@MainActor
class NotificationManager {
    // Step 2: Remove @Published (not needed with @Observable)
    var isReminderEnabled = false
    var isSmartRemindersEnabled = false
    var suggestedReminderTime: Date?

    // Step 3: Convert init to use Task for async operations
    init() {
        isSmartRemindersEnabled = UserDefaults.standard.bool(forKey: Self.smartRemindersKey)
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            self.isReminderEnabled = settings.authorizationStatus == .authorized
        }
    }

    // Step 4: Convert completion handlers to async
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            self.isReminderEnabled = granted
            return granted
        } catch {
            return false
        }
    }
}
```

#### HealthKitManager.swift

```swift
@Observable
@MainActor
class HealthKitManager {
    static let shared = HealthKitManager()

    var isAuthorized = false
    var lastSyncStatus: SyncStatus = .none

    func requestAuthorization() async -> (Bool, Error?) {
        guard Self.isHealthKitAvailable else {
            return (false, nil)
        }

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: [])
            self.isAuthorized = true
            return (true, nil)
        } catch {
            return (false, error)
        }
    }
}
```

### Phase 3: Update Views

#### Update Property Wrappers

```swift
// Before
@StateObject private var notificationManager = NotificationManager()
@ObservedObject private var healthKitManager = HealthKitManager.shared

// After
@State private var notificationManager = NotificationManager()
@State private var healthKitManager = HealthKitManager.shared
```

#### Update Async Calls

```swift
// Before
Button("Enable Notifications") {
    notificationManager.requestNotificationPermission { granted in
        // handle result
    }
}

// After
Button("Enable Notifications") {
    Task {
        let granted = await notificationManager.requestNotificationPermission()
        // handle result
    }
}
```

### Phase 4: Update Tests

```swift
final class NotificationManagerTests: XCTestCase {
    @MainActor
    func testRequestPermission() async throws {
        let manager = NotificationManager()
        let granted = await manager.requestNotificationPermission()
        XCTAssertFalse(granted) // Simulator typically denies
    }

    @MainActor
    func testReminderEnabled() async throws {
        let manager = NotificationManager()
        XCTAssertFalse(manager.isReminderEnabled)
    }
}
```

### Phase 5: Update Build Settings

1. **Update deployment target**:
   - Build Settings → "iOS Deployment Target" → "26.0"
   - For both main app and widget extension targets

2. **Switch to Swift 6 language mode**:
   - Build Settings → "Swift Language Version" → "Swift 6"

3. **Verify build**:
   - Clean build folder (Cmd+Shift+K)
   - Build (Cmd+B)
   - Should complete with zero errors and zero warnings

### Phase 6: Update Constitution

Update `.specify/memory/constitution.md`:

```markdown
## Technical Standards

**Platform Requirements:**
- iOS 26.0+ minimum deployment target
- Swift 6 with strict concurrency
- SwiftUI for all UI
- SwiftData for persistence
- Swift Charts for visualization
```

## Verification Steps

### Build Verification

```bash
# Build from command line
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr \
  -configuration Debug -sdk iphonesimulator build
```

### Test Verification

```bash
# Run all tests
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr \
  -sdk iphonesimulator test
```

### Manual Smoke Test

1. [ ] App launches successfully
2. [ ] Existing weight entries display correctly
3. [ ] Can add new weight entry
4. [ ] Chart displays and scrolls smoothly
5. [ ] Settings preferences are preserved
6. [ ] Notifications work (if previously enabled)
7. [ ] Widget displays correctly (if installed)
8. [ ] Light and dark mode work correctly

## Common Issues

### "Reference to captured var in concurrently-executing code"

**Fix**: Capture the value explicitly:
```swift
// Before
Task {
    self.someProperty = value
}

// After (if self needs to be captured)
Task { @MainActor in
    self.someProperty = value
}
```

### "Sending 'self' risks causing data races"

**Fix**: Ensure the class is `@MainActor` isolated:
```swift
@MainActor
class MyManager {
    // ...
}
```

### "@Published property cannot be isolated to actor"

**Fix**: This happens when using `@Published` with `@MainActor`. Migrate to `@Observable` instead.

### "Static property is not concurrency-safe"

**Fix**: Isolate to MainActor:
```swift
@MainActor
class Manager {
    static let shared = Manager() // Now safe
}
```

## Files Changed Summary

| File | Change Type |
|------|-------------|
| `NotificationManager.swift` | Major - migrate to @Observable |
| `HealthKitManager.swift` | Major - migrate to @Observable |
| `SettingsView.swift` | Update property wrappers + async calls |
| `ContentView.swift` | Update property wrappers if needed |
| `W8TrackrTests/*.swift` | Add @MainActor to test methods |
| `*.xcodeproj` | Update deployment target, Swift version |
| `constitution.md` | Update platform requirements |

## Success Criteria

- [ ] Build completes with zero errors
- [ ] Build completes with zero warnings (first-party code)
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Manual smoke test passes
- [ ] No runtime crashes or data loss
