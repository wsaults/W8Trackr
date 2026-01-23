//
//  HealthSyncFlowTests.swift
//  W8TrackrTests
//
//  Tests for HealthKit sync flow operations.
//  Satisfies TEST-02 requirement: HealthKit sync logic tested.
//

import Testing
import Foundation
import HealthKit
@testable import W8Trackr

// MARK: - Test Helpers

/// Creates an isolated UserDefaults instance for test isolation.
/// Each call returns a fresh suite that doesn't share state with other tests.
private func makeTestDefaults() -> UserDefaults {
    let suiteName = "com.w8trackr.healthsyncflow.tests.\(UUID().uuidString)"
    return UserDefaults(suiteName: suiteName)!
}

// MARK: - Sync Enable/Disable Flow Tests

@MainActor
struct HealthSyncEnableDisableFlowTests {

    @Test func enableImportSetsFlag() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)

        // Initially disabled
        #expect(manager.isHealthImportEnabled == false)

        // Enable import
        manager.isHealthImportEnabled = true

        #expect(manager.isHealthImportEnabled == true)
    }

    @Test func disableImportClearsFlag() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)

        // Enable first
        manager.isHealthImportEnabled = true
        #expect(manager.isHealthImportEnabled == true)

        // Disable
        manager.isHealthImportEnabled = false

        #expect(manager.isHealthImportEnabled == false)
    }

    @Test func enablePersistsAcrossManagerInstances() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()

        // First manager instance - enable
        let manager1 = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager1.isHealthImportEnabled = true

        // Second manager instance - should read persisted value
        let manager2 = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)

        #expect(manager2.isHealthImportEnabled == true)
    }

    @Test func disablePersistsAcrossManagerInstances() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()

        // First manager instance - enable then disable
        let manager1 = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager1.isHealthImportEnabled = true
        manager1.isHealthImportEnabled = false

        // Second manager instance - should read persisted value
        let manager2 = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)

        #expect(manager2.isHealthImportEnabled == false)
    }
}

// MARK: - Authorization Flow Tests

@MainActor
struct HealthSyncAuthorizationFlowTests {

    @Test func successfulAuthorizationCallsHealthStore() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = true
        let manager = HealthSyncManager(healthStore: mockStore)

        _ = try await manager.requestAuthorization()

        #expect(mockStore.requestAuthorizationCalled == true)
    }

    @Test func successfulAuthorizationReturnsTrue() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = true
        let manager = HealthSyncManager(healthStore: mockStore)

        let result = try await manager.requestAuthorization()

        #expect(result == true)
    }

    @Test func deniedAuthorizationReturnsFalse() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = false
        let manager = HealthSyncManager(healthStore: mockStore)

        let result = try await manager.requestAuthorization()

        #expect(result == false)
    }

    @Test func deniedAuthorizationKeepsImportDisabled() async throws {
        let mockStore = MockHealthStore()
        mockStore.authorizationResult = false
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)

        _ = try await manager.requestAuthorization()

        #expect(manager.isHealthImportEnabled == false)
    }

    @Test func authorizationErrorThrowsToCallerAsync() async {
        let mockStore = MockHealthStore()
        let expectedError = NSError(domain: "HealthKit", code: 101, userInfo: nil)
        mockStore.authorizationError = expectedError
        let manager = HealthSyncManager(healthStore: mockStore)

        await #expect(throws: Error.self) {
            try await manager.requestAuthorization()
        }
    }
}

// MARK: - Sync Status Tests

@MainActor
struct HealthSyncStatusTests {

    @Test func initialStatusIsIdle() {
        let mockStore = MockHealthStore()
        let manager = HealthSyncManager(healthStore: mockStore)

        #expect(manager.syncStatus == .idle)
    }

    @Test func statusEquality() {
        #expect(HealthSyncManager.SyncStatus.idle == .idle)
        #expect(HealthSyncManager.SyncStatus.syncing == .syncing)
        #expect(HealthSyncManager.SyncStatus.success == .success)
        #expect(HealthSyncManager.SyncStatus.failed("error") == .failed("error"))
        #expect(HealthSyncManager.SyncStatus.idle != .syncing)
    }

    @Test func failedStatusContainsErrorMessage() {
        let status = HealthSyncManager.SyncStatus.failed("Connection timeout")

        if case .failed(let message) = status {
            #expect(message == "Connection timeout")
        } else {
            Issue.record("Expected failed status with error message")
        }
    }
}

// MARK: - MockHealthStore Save/Delete Tracking Tests

@MainActor
struct MockHealthStoreSaveDeleteTrackingTests {

    @Test func mockHealthStoreSaveCalledTracking() async throws {
        let mockStore = MockHealthStore()
        #expect(mockStore.saveCalled == false)

        // Create a minimal HKQuantitySample to test save tracking
        let weightType = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .pound(), doubleValue: 180.0)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: Date.now,
            end: Date.now
        )

        try await mockStore.save(sample)

        #expect(mockStore.saveCalled == true)
    }

    @Test func mockHealthStoreDeleteCalledTracking() async throws {
        let mockStore = MockHealthStore()
        #expect(mockStore.deleteCalled == false)

        // Create a minimal HKQuantitySample to test delete tracking
        let weightType = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .pound(), doubleValue: 180.0)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: Date.now,
            end: Date.now
        )

        try await mockStore.delete(sample)

        #expect(mockStore.deleteCalled == true)
    }

    @Test func mockHealthStoreDeletedSampleCapture() async throws {
        let mockStore = MockHealthStore()
        #expect(mockStore.deletedSample == nil)

        // Create a minimal HKQuantitySample to test delete tracking
        let weightType = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .pound(), doubleValue: 185.0)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: Date.now,
            end: Date.now
        )

        try await mockStore.delete(sample)

        #expect(mockStore.deletedSample != nil)
        if let deletedSample = mockStore.deletedSample as? HKQuantitySample {
            #expect(deletedSample.quantity.doubleValue(for: .pound()) == 185.0)
        } else {
            Issue.record("Expected deleted sample to be HKQuantitySample")
        }
    }

    @Test func mockHealthStoreSaveErrorHandling() async {
        let mockStore = MockHealthStore()
        let expectedError = NSError(domain: "HealthKit", code: 200, userInfo: nil)
        mockStore.saveError = expectedError

        let weightType = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .pound(), doubleValue: 180.0)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: Date.now,
            end: Date.now
        )

        await #expect(throws: Error.self) {
            try await mockStore.save(sample)
        }
    }

    @Test func mockHealthStoreDeleteErrorHandling() async {
        let mockStore = MockHealthStore()
        let expectedError = NSError(domain: "HealthKit", code: 201, userInfo: nil)
        mockStore.deleteError = expectedError

        let weightType = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .pound(), doubleValue: 180.0)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: Date.now,
            end: Date.now
        )

        await #expect(throws: Error.self) {
            try await mockStore.delete(sample)
        }
    }
}

// MARK: - Last Sync Date Tests

@MainActor
struct HealthSyncLastSyncDateTests {

    @Test func lastSyncDateInitiallyNil() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)

        #expect(manager.lastHealthSyncDate == nil)
    }

    @Test func lastSyncDateCanBeSet() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        let syncDate = Date.now

        manager.lastHealthSyncDate = syncDate

        #expect(manager.lastHealthSyncDate != nil)
        // Compare timestamps (Date comparison can have precision issues)
        if let savedDate = manager.lastHealthSyncDate {
            #expect(abs(savedDate.timeIntervalSince(syncDate)) < 1.0)
        }
    }

    @Test func lastSyncDatePersistsAcrossInstances() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let syncDate = Date.now

        let manager1 = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager1.lastHealthSyncDate = syncDate

        let manager2 = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)

        #expect(manager2.lastHealthSyncDate != nil)
    }
}

// MARK: - Background Delivery Setup Tests

@MainActor
struct HealthSyncBackgroundDeliveryTests {

    @Test func enableBackgroundDeliveryCallsMock() {
        let mockStore = MockHealthStore()
        var callbackCalled = false

        let weightType = HKQuantityType(.bodyMass)
        mockStore.enableBackgroundDelivery(for: weightType, frequency: .immediate) { success, _ in
            callbackCalled = true
            #expect(success == true)
        }

        #expect(callbackCalled == true)
    }

    @Test func disableBackgroundDeliveryCallsMock() {
        let mockStore = MockHealthStore()
        var callbackCalled = false

        let weightType = HKQuantityType(.bodyMass)
        mockStore.disableBackgroundDelivery(for: weightType) { success, _ in
            callbackCalled = true
            #expect(success == true)
        }

        #expect(callbackCalled == true)
    }
}
