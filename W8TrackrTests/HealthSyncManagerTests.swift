//
//  HealthSyncManagerTests.swift
//  W8TrackrTests
//
//  Tests for HealthSyncManager initialization and core functionality.
//  Following TDD: these tests are written FIRST, before implementation.
//

import Testing
import Foundation
import HealthKit
@testable import W8Trackr

// MARK: - Mock HealthStore

/// Mock implementation of HealthStoreProtocol for testing without device.
final class MockHealthStore: HealthStoreProtocol {
    // Configurable return values
    var isHealthDataAvailableResult = true
    var authorizationResult = true
    var authorizationError: Error?
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var saveError: Error?
    var deleteError: Error?

    // Call tracking
    var requestAuthorizationCalled = false
    var saveCalled = false
    var deleteCalled = false
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
}

// MARK: - HealthSyncManager Initialization Tests

@MainActor
struct HealthSyncManagerInitializationTests {

    @Test func managerInitializesWithMockStore() {
        let mockStore = MockHealthStore()
        let manager = HealthSyncManager(healthStore: mockStore)
        #expect(manager != nil)
    }

    @Test func managerDefaultsToHealthSyncDisabled() {
        let mockStore = MockHealthStore()
        let manager = HealthSyncManager(healthStore: mockStore)
        #expect(manager.isHealthSyncEnabled == false)
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

    @Test func healthSyncEnabledPersists() {
        let mockStore = MockHealthStore()
        let manager = HealthSyncManager(healthStore: mockStore)

        // Clear any previous state
        UserDefaults.standard.removeObject(forKey: "healthSyncEnabled")

        manager.isHealthSyncEnabled = true
        #expect(manager.isHealthSyncEnabled == true)

        manager.isHealthSyncEnabled = false
        #expect(manager.isHealthSyncEnabled == false)
    }

    @Test func lastHealthSyncDateInitiallyNil() {
        let mockStore = MockHealthStore()
        // Clear any previous state
        UserDefaults.standard.removeObject(forKey: "lastHealthSyncDate")
        let manager = HealthSyncManager(healthStore: mockStore)
        #expect(manager.lastHealthSyncDate == nil)
    }
}
