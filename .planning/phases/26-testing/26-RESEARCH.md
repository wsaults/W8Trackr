# Phase 26: Testing - Research

**Researched:** 2026-01-23
**Domain:** Swift Testing, SwiftData testing, HealthKit mocking
**Confidence:** HIGH

## Summary

Phase 26 focuses on comprehensive test coverage for W8Trackr. Research reveals that the project already has extensive test infrastructure using Swift Testing framework (not XCTest) with 11 test files covering: WeightEntry, WeightUnit, TrendCalculator (EWMA/Holt), HealthSyncManager, Notifications, DataExporter, Chart data, and Localization. The existing test patterns are well-established and follow modern Swift Testing conventions.

The primary work for this phase is gap analysis and enhancement of existing tests rather than building from scratch. The project uses `@Test` macro with struct-based test suites, `#expect()` assertions, and has a working `MockHealthStore` implementing `HealthStoreProtocol` for HealthKit testing isolation.

**Primary recommendation:** Audit existing tests against requirements, add missing CRUD operations tests, and ensure complete coverage for HealthKit sync flows with the existing mock infrastructure.

## Standard Stack

The established testing tools for this project:

### Core
| Framework | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Swift Testing | Built-in (Swift 6+) | Unit test framework | Modern Apple testing framework, already in use |
| XCTest | Built-in | Test execution host | Required for running Swift Testing tests |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@testable import W8Trackr` | N/A | Access internal symbols | All unit tests |
| `HealthKit` | Built-in | HealthKit types for mocking | HealthSync tests |

### Already Rejected/Not Needed
| Instead of | Could Use | Why Not Used |
|------------|-----------|--------------|
| Quick/Nimble | Swift Testing | Swift Testing provides modern syntax, no third-party needed |
| UI Tests | Unit tests only | Phase 25-03 decision removed UI tests |
| Snapshot tests | Unit tests only | Removed per Phase 25-03 decision |

**No additional packages needed** - the project uses only built-in testing frameworks.

## Architecture Patterns

### Existing Test Organization
```
W8TrackrTests/
├── W8TrackrTests.swift       # Entry point (index file)
├── WeightEntryTests.swift    # Model + sample data tests
├── WeightUnitTests.swift     # Unit conversion tests
├── TrendCalculatorTests.swift # EWMA + Holt algorithm tests
├── HealthSyncManagerTests.swift # HealthKit sync with MockHealthStore
├── WeightEntryHealthTests.swift # Sync field tests
├── NotificationTests.swift   # NotificationScheduler tests
├── DataExporterTests.swift   # CSV/JSON export tests
├── ChartDataTests.swift      # Filtering/calculation tests
├── LogbookRowDataTests.swift # Logbook helper tests
└── LocalizationTests.swift   # Locale formatting tests
```

### Pattern 1: Struct-Based Test Suites (Swift Testing)
**What:** Group related tests in structs without `@Suite` macro
**When to use:** All unit tests
**Example:**
```swift
// Source: Existing W8TrackrTests pattern
import Testing
import Foundation
@testable import W8Trackr

struct WeightEntryTests {

    @Test func weightEntryInitializesWithCorrectValues() {
        let entry = WeightEntry(weight: 175.5, unit: .lb)
        #expect(entry.weightValue == 175.5)
        #expect(entry.weightUnit == "lb")
    }
}
```

### Pattern 2: Mock with Protocol Abstraction
**What:** Protocol-based dependency injection for testing
**When to use:** External services (HealthKit, UserDefaults)
**Example:**
```swift
// Source: Existing HealthStoreProtocol pattern
final class MockHealthStore: HealthStoreProtocol, @unchecked Sendable {
    var authorizationResult = true
    var requestAuthorizationCalled = false

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws -> Bool {
        requestAuthorizationCalled = true
        return authorizationResult
    }
}
```

### Pattern 3: Test Isolation with Fresh UserDefaults
**What:** Create isolated UserDefaults per test
**When to use:** Tests that read/write user preferences
**Example:**
```swift
// Source: Existing HealthSyncManagerTests pattern
private func makeTestDefaults() -> UserDefaults {
    let suiteName = "com.w8trackr.tests.\(UUID().uuidString)"
    return UserDefaults(suiteName: suiteName)!
}
```

### Pattern 4: @MainActor for @Observable Tests
**What:** Mark test suites with @MainActor for thread safety
**When to use:** Testing @Observable/@MainActor classes
**Example:**
```swift
// Source: Existing HealthSyncManagerTests pattern
@MainActor
struct HealthSyncManagerStateTests {
    @Test func healthImportEnabledPersists() {
        let mockStore = MockHealthStore()
        let manager = HealthSyncManager(healthStore: mockStore)
        // Test @MainActor properties safely
    }
}
```

### Pattern 5: Helper Functions for Test Data
**What:** Private helpers to create test fixtures
**When to use:** Tests needing date-relative data
**Example:**
```swift
// Source: Existing TrendCalculatorTests pattern
private func makeEntry(weight: Double, daysAgo: Int = 0) -> WeightEntry {
    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    return WeightEntry(weight: weight, unit: .lb, date: date)
}
```

### Anti-Patterns to Avoid
- **Using XCTest syntax:** Use Swift Testing `@Test` and `#expect()`, not `func test*()` and `XCTAssert*()`
- **Shared mutable state:** Each test struct gets its own instance; don't share state between tests
- **Testing views directly:** Test view models and business logic, not SwiftUI views
- **Real HealthKit in tests:** Always use MockHealthStore for isolation
- **Real UserDefaults:** Use makeTestDefaults() pattern for isolation

## Don't Hand-Roll

Problems that have existing solutions in the codebase:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HealthKit mocking | Custom mock from scratch | Existing `MockHealthStore` | Already conforms to `HealthStoreProtocol`, has call tracking |
| Test data creation | Inline WeightEntry construction | `makeEntry()` helper or `WeightEntry.sampleData` | Ensures consistent dates, reduces boilerplate |
| UserDefaults isolation | Manually cleaning defaults | `makeTestDefaults()` with UUID suite | Guaranteed isolation, no cleanup needed |
| Date arithmetic | Manual TimeInterval math | `Calendar.current.date(byAdding:)` | Handles DST, leap years correctly |

**Key insight:** The project already has well-established test patterns. New tests should follow existing conventions rather than introducing new patterns.

## Common Pitfalls

### Pitfall 1: Testing SwiftData Models Without Context
**What goes wrong:** Attempting to test SwiftData @Model classes without a ModelContainer crashes
**Why it happens:** SwiftData models require a context for persistence operations
**How to avoid:** For pure model logic (like WeightEntry), test without persistence. For CRUD operations, use in-memory ModelContainer
**Warning signs:** Tests crash with SwiftData-related errors

### Pitfall 2: Forgetting @MainActor on Tests
**What goes wrong:** Race conditions or compiler errors when testing @Observable/@MainActor classes
**Why it happens:** HealthSyncManager is @MainActor, tests must match
**How to avoid:** Mark entire test struct with `@MainActor` when testing MainActor types
**Warning signs:** Compiler errors about actor isolation

### Pitfall 3: Floating-Point Comparison Precision
**What goes wrong:** Tests fail due to floating-point precision issues
**Why it happens:** Weight calculations involve decimals
**How to avoid:** Use `abs(result - expected) < tolerance` pattern
**Warning signs:** Tests that pass sometimes and fail other times

### Pitfall 4: Time-Sensitive Tests
**What goes wrong:** Tests break based on when they run (time of day, DST)
**Why it happens:** Using `Date.now` without controlling time
**How to avoid:** Use explicit dates or relative offsets from a controlled base date
**Warning signs:** Tests pass locally but fail in CI, or fail near midnight

### Pitfall 5: HealthKit Availability Assumptions
**What goes wrong:** Tests fail on certain devices/simulators
**Why it happens:** HealthKit availability varies by device type
**How to avoid:** Use MockHealthStore which controls availability via static property
**Warning signs:** Tests pass on iPhone but fail on iPad

## Code Examples

Verified patterns from the existing codebase:

### CRUD Test Pattern for WeightEntry
```swift
// Pattern for testing entry creation/modification
struct WeightEntryCRUDTests {

    @Test func createEntryWithAllFields() {
        let date = Date.now
        let entry = WeightEntry(
            weight: 175.5,
            unit: .lb,
            date: date,
            note: "Morning",
            bodyFatPercentage: 20.0
        )

        #expect(entry.weightValue == 175.5)
        #expect(entry.weightUnit == "lb")
        #expect(entry.date == date)
        #expect(entry.note == "Morning")
        #expect(entry.bodyFatPercentage == 20.0)
    }

    @Test func updateEntryModifiesValues() {
        let entry = WeightEntry(weight: 170.0)
        entry.weightValue = 175.0
        entry.note = "Updated"

        #expect(entry.weightValue == 175.0)
        #expect(entry.note == "Updated")
    }
}
```

### HealthKit Sync Test Pattern
```swift
// Pattern for testing HealthKit sync with mock
@MainActor
struct HealthSyncTests {

    @Test func syncCallsHealthStoreOnEnable() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = true
        let manager = HealthSyncManager(healthStore: mockStore)

        _ = try await manager.requestAuthorization()

        #expect(mockStore.requestAuthorizationCalled == true)
    }

    @Test func syncHandlesAuthorizationDenial() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = false
        let manager = HealthSyncManager(healthStore: mockStore)

        let result = try await manager.requestAuthorization()

        #expect(result == false)
        #expect(manager.isHealthImportEnabled == false)
    }
}
```

### EWMA Algorithm Verification Pattern
```swift
// Pattern for verifying mathematical calculations
struct TrendCalculationTests {

    @Test func ewmaProducesExpectedSmoothing() {
        // Hand-calculated: lambda=0.1
        // weights: [180, 182]
        // trend[0] = 180
        // trend[1] = 0.1*182 + 0.9*180 = 180.2
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 1),
            makeEntry(weight: 182.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.1)

        #expect(result.count == 2)
        #expect(abs(result[0].smoothedWeight - 180.0) < 0.001)
        #expect(abs(result[1].smoothedWeight - 180.2) < 0.001)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| XCTest with `func test*()` | Swift Testing with `@Test` | Swift 6 / Xcode 16 | Modern syntax, better parallelism |
| `XCTAssertEqual()` | `#expect()` | Swift Testing | More readable, better error messages |
| `XCTestCase` classes | Structs with `@Test` | Swift Testing | Simpler, automatic isolation |
| `setUp()/tearDown()` | `init()/deinit` | Swift Testing | Natural Swift lifecycle |

**Already migrated:** The project already uses Swift Testing exclusively. No migration needed.

## Existing Test Coverage Analysis

### Tests Already Implemented (HIGH coverage):
- **WeightEntry model:** Creation, unit conversion, validation, sample data
- **WeightUnit:** Conversion, bounds, goal weight validation
- **TrendCalculator:** EWMA with hand-calculated values, Holt's method, edge cases
- **HealthSyncManager:** Authorization, state persistence, graceful degradation
- **NotificationScheduler:** Streak calculation, milestone progress, weekly summary
- **DataExporter:** CSV generation, JSON generation, date filtering
- **Localization:** Number formatting by locale, date formatting

### Gaps to Address (per requirements):
| Requirement | Current Status | Gap |
|-------------|----------------|-----|
| TEST-01: CRUD operations | Partial - create/read tested, update/delete less covered | Add explicit CRUD lifecycle tests |
| TEST-02: HealthKit sync logic | Covered via MockHealthStore | Verify save/delete flows |
| TEST-03: EWMA calculations | Fully covered | None |
| TEST-04: UI tests weight entry flow | Removed per Phase 25-03 | N/A - intentionally out of scope |
| TEST-05: UI tests settings flow | Removed per Phase 25-03 | N/A - intentionally out of scope |
| TEST-06: Mock HealthKit store | Implemented | Already exists |

## Open Questions

Things that couldn't be fully resolved:

1. **SwiftData CRUD in unit tests**
   - What we know: WeightEntry can be tested without ModelContainer for property-level tests
   - What's unclear: Whether full CRUD persistence tests are needed or if property tests suffice
   - Recommendation: Focus on model property tests (existing pattern) since SwiftData handles persistence

2. **UI test requirements despite removal**
   - What we know: Phase 25-03 explicitly removed UI tests
   - What's unclear: Whether TEST-04/TEST-05 requirements should be interpreted as unit tests instead
   - Recommendation: Interpret as "verify the logic" via unit tests, not literally UI tests

## Sources

### Primary (HIGH confidence)
- Existing W8TrackrTests codebase (11 test files)
- Apple Swift Testing Documentation: https://developer.apple.com/documentation/testing

### Secondary (MEDIUM confidence)
- [Hacking with Swift - SwiftData unit testing](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code) - in-memory container pattern
- [Swift with Majid - Swift Testing lifecycle](https://swiftwithmajid.com/2024/10/29/introducing-swift-testing-lifecycle/) - setup/teardown patterns
- [Medium - HealthKit testing with protocols](https://medium.com/@azharanwar/advanced-unit-testing-in-swift-protocols-dependency-injection-and-healthkit-4795ef4f33ec) - mock pattern

### Tertiary (LOW confidence)
- General WebSearch results for Swift Testing best practices

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using existing project patterns
- Architecture: HIGH - Patterns verified against existing codebase
- Pitfalls: HIGH - Derived from project code review

**Research date:** 2026-01-23
**Valid until:** 2026-02-23 (30 days - stable domain)
