# Testing Patterns

**Analysis Date:** 2026-01-20

## Test Framework

**Runner:**
- Swift Testing framework (not XCTest for unit tests)
- XCTest for UI tests only
- Config: Xcode project settings (no separate config file)

**Assertion Library:**
- Swift Testing `#expect()` macro
- XCTest `XCTAssert*` functions for UI tests

**Run Commands:**
```bash
# Run all tests
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -sdk iphonesimulator test

# Run specific test class
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -sdk iphonesimulator \
  -only-testing:W8TrackrTests/W8TrackrTests test

# Run UI tests only
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -sdk iphonesimulator \
  -only-testing:W8TrackrUITests test
```

## Test File Organization

**Location:**
- Unit tests: `W8TrackrTests/` (separate directory)
- UI tests: `W8TrackrUITests/` (separate directory)

**Naming:**
- Unit test files: `{Feature}Tests.swift` (e.g., `TrendCalculatorTests.swift`)
- UI test files: `{Purpose}Tests.swift` (e.g., `ScreenshotTests.swift`)

**Structure:**
```
W8TrackrTests/
├── W8TrackrTests.swift          # Core model/unit tests
├── TrendCalculatorTests.swift    # Algorithm tests
├── HealthSyncManagerTests.swift  # Manager tests with mocks
└── WeightEntryHealthTests.swift  # Model field tests

W8TrackrUITests/
├── ScreenshotTests.swift         # Fastlane screenshot automation
└── SnapshotHelper.swift          # Fastlane helper utilities
```

## Test Structure

**Suite Organization:**
```swift
import Testing
import Foundation
@testable import W8Trackr

// MARK: - Feature Area Tests

struct FeatureNameTests {

    // MARK: - Category of Tests

    @Test func specificBehaviorDescription() {
        // Arrange
        let input = ...

        // Act
        let result = ...

        // Assert
        #expect(result == expected)
    }
}
```

**Patterns:**
- Group related tests in `struct` containers
- Use `// MARK: -` to separate test categories within a struct
- One test per behavior/scenario
- Descriptive function names: `func testNameDescribesBehavior()`

**Example from `W8TrackrTests/TrendCalculatorTests.swift`:**
```swift
struct EWMAHandCalculatedTests {

    // MARK: - Helper to create entries with specific dates

    private func makeEntry(weight: Double, daysAgo: Int = 0) -> WeightEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return WeightEntry(weight: weight, unit: .lb, date: date)
    }

    @Test func ewmaFirstPointEqualsFirstWeight() {
        let entries = [makeEntry(weight: 180.0, daysAgo: 0)]
        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.1)
        #expect(result.count == 1)
        #expect(result[0].smoothedWeight == 180.0)
    }

    @Test func ewmaWithLambdaPointOne() {
        // Hand-calculated EWMA with lambda = 0.1
        // weights: [180, 182, 179]
        // trend[0] = 180
        // trend[1] = 0.1 * 182 + 0.9 * 180 = 180.2
        // trend[2] = 0.1 * 179 + 0.9 * 180.2 = 180.08
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 2),
            makeEntry(weight: 182.0, daysAgo: 1),
            makeEntry(weight: 179.0, daysAgo: 0)
        ]
        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.1)
        #expect(abs(result[1].smoothedWeight - 180.2) < 0.001)
    }
}
```

## Mocking

**Framework:** Manual mock classes implementing protocols

**Patterns:**
```swift
/// Mock implementation of HealthStoreProtocol for testing without device.
final class MockHealthStore: HealthStoreProtocol {
    // Configurable return values
    var isHealthDataAvailableResult = true
    var authorizationResult = true
    var authorizationError: Error?
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var saveError: Error?

    // Call tracking
    var requestAuthorizationCalled = false
    var saveCalled = false

    static var healthDataAvailable = true

    static func isHealthDataAvailable() -> Bool {
        healthDataAvailable
    }

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws -> Bool {
        requestAuthorizationCalled = true
        if let error = authorizationError {
            throw error
        }
        return authorizationResult
    }
}
```

**Protocol-Based Injection:**
- Define protocols for external dependencies (e.g., `HealthStoreProtocol`)
- Inject dependencies via initializer
- Production code uses real implementation; tests use mocks

**Example from `W8TrackrTests/HealthSyncManagerTests.swift`:**
```swift
@MainActor
struct HealthSyncManagerAuthorizationTests {

    @Test func requestAuthorizationCallsHealthStore() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = true
        let manager = HealthSyncManager(healthStore: mockStore)

        _ = try await manager.requestAuthorization()

        #expect(mockStore.requestAuthorizationCalled == true)
    }
}
```

**What to Mock:**
- External services (HealthKit, UserNotifications)
- System APIs that require device features
- Network requests (none in current codebase)

**What NOT to Mock:**
- Pure functions (TrendCalculator algorithms)
- SwiftData models (use in-memory containers)
- Date/Calendar for predictable test data

## Fixtures and Factories

**Test Data:**
```swift
// Helper method within test struct
private func makeEntry(weight: Double, daysAgo: Int = 0) -> WeightEntry {
    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    return WeightEntry(weight: weight, unit: .lb, date: date)
}
```

**Sample Data in Models:**
Models provide static sample data for both tests and previews:
- `WeightEntry.sampleData` - Full year of entries (30 entries)
- `WeightEntry.shortSampleData` - 2 weeks of entries (14 entries)
- `WeightEntry.initialData` - Minimal seed data (5 entries)
- `WeightEntry.emptyData` - Empty array
- `WeightEntry.singleEntry` - Single entry for edge cases
- `WeightEntry.minimalData` - 2 entries for trend testing
- `WeightEntry.boundaryData` - Min/max weight values

**Location:**
- Test helpers: Inline within test structs
- Shared sample data: `W8Trackr/Models/WeightEntry.swift` (static properties)

## Coverage

**Requirements:** None enforced (no coverage thresholds)

**View Coverage:**
```bash
# Generate coverage report via Xcode
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr \
  -sdk iphonesimulator test \
  -enableCodeCoverage YES
```

**Coverage Focus Areas:**
- Algorithm correctness (TrendCalculator)
- Model validation (WeightUnit, WeightEntry)
- Manager state transitions (HealthSyncManager)
- Notification scheduling (NotificationScheduler)

## Test Types

**Unit Tests:**
- Pure function testing (calculations, conversions, validation)
- State management testing (manager initialization, state transitions)
- Model property testing (computed properties, sync fields)
- Located in `W8TrackrTests/`

**Integration Tests:**
- Manager + Mock dependency tests (HealthSyncManager with MockHealthStore)
- Model container tests (using in-memory SwiftData containers)

**UI Tests:**
- Screenshot automation for App Store (`ScreenshotTests.swift`)
- Uses XCTest framework with XCUIApplication
- Integrated with fastlane snapshot

**Example from `W8TrackrUITests/ScreenshotTests.swift`:**
```swift
final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
    }

    @MainActor
    func test01_Dashboard() throws {
        let dashboard = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboard.exists)
        sleep(1)
        snapshot("01_dashboard")
    }
}
```

## Common Patterns

**Async Testing:**
```swift
@Test func requestAuthorizationReturnsSuccessOnApproval() async throws {
    let mockStore = MockHealthStore()
    mockStore.authorizationResult = true
    let manager = HealthSyncManager(healthStore: mockStore)

    let result = try await manager.requestAuthorization()

    #expect(result == true)
}
```

**Error Testing:**
```swift
@Test func requestAuthorizationThrowsOnError() async {
    let mockStore = MockHealthStore()
    let expectedError = NSError(domain: "HealthKit", code: 100, userInfo: nil)
    mockStore.authorizationError = expectedError
    let manager = HealthSyncManager(healthStore: mockStore)

    await #expect(throws: Error.self) {
        try await manager.requestAuthorization()
    }
}
```

**Floating-Point Comparison:**
```swift
@Test func ewmaWithLambdaPointOne() {
    // ...
    #expect(abs(result[1].smoothedWeight - 180.2) < 0.001)
}
```

**Boundary Testing:**
```swift
@Test func poundsJustBelowMinimumIsInvalid() {
    #expect(WeightUnit.lb.isValidWeight(0.9999999) == false)
}

@Test func poundsJustAboveMinimumIsValid() {
    #expect(WeightUnit.lb.isValidWeight(1.0) == true)
    #expect(WeightUnit.lb.isValidWeight(1.0000001) == true)
}
```

**MainActor Testing:**
```swift
@MainActor
struct HealthSyncManagerInitializationTests {

    @Test func managerInitializesWithMockStore() {
        let mockStore = MockHealthStore()
        let manager = HealthSyncManager(healthStore: mockStore)
        #expect(manager != nil)
    }
}
```

## Test Organization by Feature

**Core Tests (`W8TrackrTests.swift`):**
- WeightUnit tests (validation, conversion, boundaries)
- WeightEntry tests (initialization, computed properties)
- DateRange tests
- GoalWeight validation tests
- Chart data filtering tests
- Daily average calculation tests
- Linear regression tests
- NotificationScheduler tests (streak, milestone, summary)
- DataExporter tests (CSV, JSON)
- Sample data tests

**Algorithm Tests (`TrendCalculatorTests.swift`):**
- EWMA hand-calculated values
- Lambda parameter variations
- Holt's method forecast accuracy
- Edge cases (empty, single entry, gaps)
- Unit handling
- TrendPoint and HoltResult tests

**Health Integration Tests (`HealthSyncManagerTests.swift`):**
- Initialization tests
- State persistence tests
- Authorization flow tests
- Save/update/delete operations
- Graceful degradation tests

**Model Field Tests (`WeightEntryHealthTests.swift`):**
- Sync field defaults (healthKitUUID, source, syncVersion, pendingHealthSync)
- Computed properties (isImported, needsSync)

---

*Testing analysis: 2026-01-20*
