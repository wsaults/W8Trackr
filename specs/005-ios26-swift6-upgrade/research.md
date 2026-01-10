# Research: iOS 26 and Swift 6 Platform Upgrade

**Feature Branch**: `005-ios26-swift6-upgrade`
**Completed**: 2025-01-10

## Research Summary

This document captures technical decisions for upgrading W8Trackr from iOS 18/Swift 5.9 to iOS 26/Swift 6.

---

## 1. Swift 6 Strict Concurrency Adoption

**Decision**: Full Swift 6 strict concurrency mode with incremental migration

**Rationale**: Swift 6's data race safety prevents entire classes of bugs at compile time. The strict mode ensures the codebase is future-proof and benefits from compiler guarantees.

**Migration Path**:
1. Enable complete concurrency checking in Swift 5 mode first
2. Fix all warnings incrementally
3. Switch to Swift 6 language mode when clean

**Alternatives Considered**:
- Stay on Swift 5 mode indefinitely - Rejected: Defers technical debt, misses safety benefits
- Swift 5 with targeted checking only - Rejected: Inconsistent enforcement

---

## 2. ObservableObject → @Observable Migration

**Decision**: Migrate all `ObservableObject` classes to `@Observable` macro

**Rationale**:
- `@Observable` provides property-level tracking (more efficient than whole-object invalidation)
- Simpler syntax (no `@Published` needed)
- Better nested object support
- Required for optimal Swift 6 concurrency integration

**Implementation Pattern**:
```swift
// Before
class NotificationManager: ObservableObject {
    @Published var isReminderEnabled = false
}

// After
@Observable
@MainActor
class NotificationManager {
    var isReminderEnabled = false
}
```

**View Updates Required**:
```swift
// Before
@StateObject private var manager = NotificationManager()

// After
@State private var manager = NotificationManager()
```

**Alternatives Considered**:
- Keep `ObservableObject` with `@MainActor` only - Rejected: Misses performance benefits
- Gradual migration (some files Observable, others not) - Rejected: Inconsistent patterns

---

## 3. MainActor Isolation Strategy

**Decision**: Explicit `@MainActor` annotation on service classes; rely on implicit isolation for views in iOS 26

**Rationale**:
- SwiftUI views are implicitly `@MainActor` in iOS 26
- Service classes (managers) need explicit `@MainActor` for compile-time guarantees
- This approach works whether or not default MainActor isolation is enabled

**Implementation Pattern**:
```swift
@Observable
@MainActor
class HealthKitManager {
    static let shared = HealthKitManager()
    var isAuthorized = false
}
```

**Alternatives Considered**:
- Enable default MainActor isolation project-wide - Deferred: Can adopt later for new code
- Use `nonisolated(unsafe)` for statics - Rejected: Bypasses safety guarantees

---

## 4. Async/Await Migration

**Decision**: Convert completion handler APIs to async/await

**Rationale**:
- Cleaner code with structured concurrency
- Better error handling with try/catch
- Required for proper `@MainActor` integration

**Example Migration**:
```swift
// Before
func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
        DispatchQueue.main.async {
            self.isReminderEnabled = granted
            completion(granted)
        }
    }
}

// After
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
```

**Alternatives Considered**:
- Keep completion handlers with `MainActor.run` - Rejected: More complex, less readable

---

## 5. SwiftData Concurrency

**Decision**: No changes needed for existing `@Model` classes

**Rationale**:
- `@Model` classes handle concurrency internally
- `@Query` is already MainActor-safe
- Widget data access via `ModelContainer` is Sendable

**Key Rules**:
- `@Model` classes are NOT Sendable (cannot cross actor boundaries)
- `ModelContainer` and `PersistentIdentifier` ARE Sendable
- Use `PersistentIdentifier` to pass references across actors if needed

---

## 6. Test Updates

**Decision**: Add `@MainActor` to test methods that test MainActor-isolated classes

**Rationale**: Swift 6 requires test methods to be on the same actor as the code they test.

**Implementation Pattern**:
```swift
final class NotificationManagerTests: XCTestCase {
    @MainActor
    func testRequestPermission() async throws {
        let manager = NotificationManager()
        let granted = await manager.requestNotificationPermission()
        XCTAssertFalse(granted) // Simulator denies
    }
}
```

---

## 7. Minimum Deployment Target

**Decision**: Update minimum deployment target from iOS 18.0 to iOS 26.0

**Rationale**:
- Required to use Swift 6 features fully
- Enables iOS 26 SwiftUI and SwiftData improvements
- App is actively developed; supporting older iOS versions not a priority

**Impact**:
- Users on iOS 18-25 cannot update to new app version
- App Store will serve last compatible version to older devices

---

## 8. SwiftUI Changes (iOS 26)

**Decision**: Adopt liquid glass design automatically; defer explicit customization

**New Features Available** (optional adoption):
| Feature | Description | Adoption |
|---------|-------------|----------|
| Liquid Glass | Auto-applied to TabView, Navigation | Automatic |
| `glassEffect` modifier | Custom glass styling | Defer |
| 6x faster list loading | Performance improvement | Automatic |
| Chart3D | 3D chart support | Defer (not needed) |

**Rationale**: Let the system apply default styling first; customize only if needed.

---

## 9. Widget Extension Concurrency

**Decision**: Update `TimelineProvider` methods for Swift 6 concurrency

**Key Changes**:
- `TimelineProvider` methods may need `@MainActor` or `nonisolated` markers
- Ensure `SharedModelContainer` access is properly isolated

---

## Technical Decisions Summary

| Area | Decision | Complexity |
|------|----------|------------|
| Concurrency Mode | Swift 6 strict | Medium |
| Observable | Migrate to @Observable | Medium |
| MainActor | Explicit on services | Low |
| Async/Await | Convert all completion handlers | Medium |
| SwiftData | No changes | None |
| Tests | Add @MainActor annotations | Low |
| Deployment Target | iOS 26.0 | Low |
| SwiftUI | Auto-adopt new styling | None |

**Overall Assessment**: Medium complexity upgrade. Primary work is in two service classes (NotificationManager, HealthKitManager) and their associated view updates.

---

## Sources

- [Adopting Swift 6 - Apple Developer Documentation](https://developer.apple.com/documentation/swift/adoptingswift6)
- [Updating an App to Use Strict Concurrency - Apple](https://developer.apple.com/documentation/swift/updating-an-app-to-use-strict-concurrency)
- [Swift.org Migration Strategy](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/migrationstrategy/)
- [Migrating from ObservableObject to Observable - Apple](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [How SwiftData Works with Swift Concurrency - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-swiftdata-works-with-swift-concurrency)
