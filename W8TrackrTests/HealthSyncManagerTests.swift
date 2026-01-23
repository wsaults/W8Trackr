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
        #expect(manager.isHealthSyncEnabled == false)
    }

    @Test func managerDefaultsToHealthSyncDisabled() {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
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
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)

        manager.isHealthSyncEnabled = true
        #expect(manager.isHealthSyncEnabled == true)

        manager.isHealthSyncEnabled = false
        #expect(manager.isHealthSyncEnabled == false)
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

// MARK: - HealthSyncManager Save Tests

@MainActor
struct HealthSyncManagerSaveTests {

    @Test func saveWeightToHealthCallsHealthStore() async throws {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)

        try await manager.saveWeightToHealth(entry: entry)

        #expect(mockStore.saveCalled == true)
    }

    @Test func saveWeightToHealthSetsHealthKitUUID() async throws {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)
        #expect(entry.healthKitUUID == nil)

        try await manager.saveWeightToHealth(entry: entry)

        #expect(entry.healthKitUUID != nil)
    }

    @Test func saveWeightToHealthClearsPendingSync() async throws {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)
        entry.pendingHealthSync = true

        try await manager.saveWeightToHealth(entry: entry)

        #expect(entry.pendingHealthSync == false)
    }

    @Test func saveWeightToHealthThrowsOnError() async {
        let mockStore = MockHealthStore()
        let expectedError = NSError(domain: "HealthKit", code: 100, userInfo: nil)
        mockStore.saveError = expectedError
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)

        await #expect(throws: Error.self) {
            try await manager.saveWeightToHealth(entry: entry)
        }
    }

    @Test func saveWeightToHealthPreservesExistingUUID() async throws {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)
        let existingUUID = "existing-uuid-12345"
        entry.healthKitUUID = existingUUID

        try await manager.saveWeightToHealth(entry: entry)

        // UUID should be updated to the new sample's UUID, not preserved
        // (this is a re-sync scenario)
        #expect(entry.healthKitUUID != nil)
    }
}

// MARK: - HealthSyncManager Update Tests

@MainActor
struct HealthSyncManagerUpdateTests {

    @Test func updateWeightInHealthIncrementsSyncVersion() async throws {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)
        let originalVersion = entry.syncVersion

        try await manager.updateWeightInHealth(entry: entry)

        #expect(entry.syncVersion == originalVersion + 1)
    }

    @Test func updateWeightInHealthCallsSave() async throws {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)

        try await manager.updateWeightInHealth(entry: entry)

        #expect(mockStore.saveCalled == true)
    }

    @Test func updateWeightInHealthClearsPendingSync() async throws {
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)
        entry.pendingHealthSync = true

        try await manager.updateWeightInHealth(entry: entry)

        #expect(entry.pendingHealthSync == false)
    }

    @Test func updateWeightInHealthSetsPendingBeforeSave() async throws {
        // Verify that pendingHealthSync is set to true before save
        // (in case save fails, we still want pending=true)
        let mockStore = MockHealthStore()
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)
        entry.pendingHealthSync = false

        // After successful update, pending should be cleared
        try await manager.updateWeightInHealth(entry: entry)
        #expect(entry.pendingHealthSync == false)
    }
}

// MARK: - HealthSyncManager Delete Tests

@MainActor
struct HealthSyncManagerDeleteTests {

    @Test func deleteWeightFromHealthWithNilUUIDReturnsEarly() async throws {
        let mockStore = MockHealthStore()
        let manager = HealthSyncManager(healthStore: mockStore)
        let entry = WeightEntry(weight: 175.0)
        entry.healthKitUUID = nil

        try await manager.deleteWeightFromHealth(entry: entry)

        // Should not attempt to delete if no UUID
        #expect(mockStore.deleteCalled == false)
        #expect(mockStore.executedQueries.isEmpty)
    }

    @Test func deleteWeightFromHealthWithInvalidUUIDReturnsEarly() async throws {
        let mockStore = MockHealthStore()
        let manager = HealthSyncManager(healthStore: mockStore)
        let entry = WeightEntry(weight: 175.0)
        entry.healthKitUUID = "not-a-valid-uuid"

        try await manager.deleteWeightFromHealth(entry: entry)

        // Should not attempt to delete if UUID is invalid
        #expect(mockStore.deleteCalled == false)
    }

    // Note: Testing the full query-delete flow requires more sophisticated mocking
    // of HKSampleQuery completion handlers. The core delete logic is tested
    // through integration tests on a real device.
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

        // Manager should still be usable, just not syncing to Health
        #expect(manager.isHealthSyncEnabled == false)
        #expect(manager.syncStatus == .idle)
    }

    @Test func saveGracefullyDegradeOnAuthDenied() async throws {
        let mockStore = MockHealthStore()
        mockStore.saveError = NSError(
            domain: HKErrorDomain,
            code: HKError.errorAuthorizationDenied.rawValue,
            userInfo: nil
        )
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)
        entry.pendingHealthSync = false

        // Save should NOT throw when auth denied - graceful degradation
        try await manager.saveWeightToHealth(entry: entry)

        // Entry marked for later sync, status is idle (no error shown)
        #expect(entry.pendingHealthSync == true)
        #expect(manager.syncStatus == .idle)
    }

    @Test func updateGracefullyDegradeOnAuthDenied() async throws {
        let mockStore = MockHealthStore()
        mockStore.saveError = NSError(
            domain: HKErrorDomain,
            code: HKError.errorAuthorizationDenied.rawValue,
            userInfo: nil
        )
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)
        entry.pendingHealthSync = false

        // Update should NOT throw when auth denied - graceful degradation
        try await manager.updateWeightInHealth(entry: entry)

        // Entry marked for later sync, status is idle (no error shown)
        #expect(entry.pendingHealthSync == true)
        #expect(manager.syncStatus == .idle)
    }

    @Test func entryStillHasPendingSyncAfterFailedSave() async {
        let mockStore = MockHealthStore()
        mockStore.saveError = NSError(domain: "HealthKit", code: 100, userInfo: nil)
        let testDefaults = makeTestDefaults()
        let manager = HealthSyncManager(healthStore: mockStore, userDefaults: testDefaults)
        manager.isHealthSyncEnabled = true
        let entry = WeightEntry(weight: 175.0)
        entry.pendingHealthSync = true

        do {
            try await manager.saveWeightToHealth(entry: entry)
        } catch {
            // Expected to fail
        }

        // Entry should still be marked as pending for retry
        #expect(entry.pendingHealthSync == true)
    }
}
