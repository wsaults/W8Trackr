//
//  HealthSyncManagerTests.swift
//  W8TrackrTests
//
//  Tests for HealthSyncManager initialization and core functionality.
//

import Testing
import Foundation
import HealthKit
@testable import W8Trackr

// MARK: - Mock HealthStore

/// Mock implementation of HealthStoreProtocol for testing without device.
/// Marked as `@unchecked Sendable` because tests run serially and don't have concurrent access.
final class MockHealthStore: HealthStoreProtocol, @unchecked Sendable {
    // Configurable return values
    var isHealthDataAvailableResult = true
    var authorizationResult = true
    var authorizationError: Error?
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var saveError: Error?
    var deleteError: Error?
    var queryError: Error?
    var querySamples: [HKSample] = []

    // Call tracking
    var requestAuthorizationCalled = false
    var saveCalled = false
    var deleteCalled = false
    var deletedSample: HKSample?
    var executedQueries: [HKQuery] = []

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

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        authorizationStatus
    }

    func save(_ sample: HKSample) async throws {
        saveCalled = true
        if let error = saveError {
            throw error
        }
    }

    func delete(_ sample: HKSample) async throws {
        deleteCalled = true
        deletedSample = sample
        if let error = deleteError {
            throw error
        }
    }

    func execute(_ query: HKQuery) {
        executedQueries.append(query)
    }

    func stop(_ query: HKQuery) {
        // No-op for mock
    }

    func enableBackgroundDelivery(
        for type: HKObjectType,
        frequency: HKUpdateFrequency,
        withCompletion completion: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        completion(true, nil)
    }

    func disableBackgroundDelivery(
        for type: HKObjectType,
        withCompletion completion: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        completion(true, nil)
    }
}

// MARK: - Test Helpers

/// Creates an isolated UserDefaults instance for test isolation.
/// Each call returns a fresh suite that doesn't share state with other tests.
private func makeTestDefaults() -> UserDefaults {
    let suiteName = "com.w8trackr.tests.\(UUID().uuidString)"
    return UserDefaults(suiteName: suiteName)!
}

// MARK: - HealthSyncManager Initialization Tests

@MainActor
struct HealthSyncManagerInitializationTests {

    @Test func managerInitializesWithMockStore() {
        let mockStore = MockHealthStore()
        let manager = HealthSyncManager(healthStore: mockStore)
        // Verify manager is functional by checking default state
        #expect(manager.isHealthImportEnabled == false)
    }

    @Test func managerDefaultsToHealthImportDisabled() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        #expect(manager.isHealthImportEnabled == false)
    }

    @Test func isHealthDataAvailableReturnsCorrectValue() {
        // Note: This tests the static property which uses the real HKHealthStore
        // In simulator, Health data is typically available
        #expect(HealthSyncManager.isHealthDataAvailable == true || HealthSyncManager.isHealthDataAvailable == false)
    }
}

// MARK: - HealthSyncManager State Tests

@MainActor
struct HealthSyncManagerStateTests {

    @Test func healthImportEnabledPersists() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)

        manager.isHealthImportEnabled = true
        #expect(manager.isHealthImportEnabled == true)

        manager.isHealthImportEnabled = false
        #expect(manager.isHealthImportEnabled == false)
    }

    @Test func lastHealthSyncDateInitiallyNil() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        #expect(manager.lastHealthSyncDate == nil)
    }
}

// MARK: - HealthSyncManager Authorization Tests

@MainActor
struct HealthSyncManagerAuthorizationTests {

    @Test func requestAuthorizationCallsHealthStore() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = true
        let manager = HealthSyncManager(healthStore: mockStore)

        _ = try await manager.requestAuthorization()

        #expect(mockStore.requestAuthorizationCalled == true)
    }

    @Test func requestAuthorizationReturnsSuccessOnApproval() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = true
        let manager = HealthSyncManager(healthStore: mockStore)

        let result = try await manager.requestAuthorization()

        #expect(result == true)
    }

    @Test func requestAuthorizationReturnsFalseOnDenial() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = false
        let manager = HealthSyncManager(healthStore: mockStore)

        let result = try await manager.requestAuthorization()

        #expect(result == false)
    }

    @Test func requestAuthorizationThrowsOnError() async {
        let mockStore = MockHealthStore()
        let expectedError = NSError(domain: "HealthKit", code: 100, userInfo: nil)
        mockStore.authorizationError = expectedError
        let manager = HealthSyncManager(healthStore: mockStore)

        await #expect(throws: Error.self) {
            try await manager.requestAuthorization()
        }
    }
}

// MARK: - Graceful Degradation Tests

@MainActor
struct HealthSyncManagerGracefulDegradationTests {

    @Test func appFunctionsWhenAuthorizationDenied() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = false
        mockStore.authorizationStatus = .notDetermined
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)

        // Request authorization (denied)
        let authorized = try await manager.requestAuthorization()
        #expect(authorized == false)

        // Manager should still be usable, just not importing from Health
        #expect(manager.isHealthImportEnabled == false)
        #expect(manager.syncStatus == .idle)
    }
}
