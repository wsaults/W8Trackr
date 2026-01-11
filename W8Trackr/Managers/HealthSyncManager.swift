//
//  HealthSyncManager.swift
//  W8Trackr
//
//  Manages bidirectional synchronization between W8Trackr and Apple HealthKit.
//

import Foundation
import HealthKit
import SwiftUI

/// Manages synchronization of weight entries between W8Trackr and Apple HealthKit.
///
/// This manager handles:
/// - Authorization requests for Health data access
/// - Exporting weight entries to HealthKit (P1)
/// - Importing weight entries from HealthKit (P2 - future)
/// - Ongoing bidirectional sync (P3 - future)
///
/// Uses dependency injection via `HealthStoreProtocol` for testability.
@MainActor
final class HealthSyncManager: ObservableObject {

    // MARK: - Shared Instance

    /// Shared singleton for use across the app.
    static let shared = HealthSyncManager()

    // MARK: - Static Properties

    /// Returns whether HealthKit is available on this device.
    ///
    /// Returns `false` on iPads without the Health app.
    static var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Dependencies

    /// The HealthKit store instance (real or mock for testing).
    private let healthStore: any HealthStoreProtocol

    // MARK: - Published State

    /// The current sync status for UI feedback.
    @Published var syncStatus: SyncStatus = .idle

    /// Whether the user has granted authorization to access Health data.
    @Published var isAuthorized = false

    // MARK: - Persisted State

    /// User preference key for Health sync enabled/disabled.
    private static let healthSyncEnabledKey = "healthSyncEnabled"

    /// Key for storing the HealthKit query anchor for incremental sync.
    private static let healthSyncAnchorKey = "healthSyncAnchor"

    /// Key for storing the last successful sync timestamp.
    private static let lastHealthSyncDateKey = "lastHealthSyncDate"

    /// Whether Health sync is enabled by the user.
    ///
    /// Stored in UserDefaults and persists across app launches.
    var isHealthSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.healthSyncEnabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.healthSyncEnabledKey)
            objectWillChange.send()
        }
    }

    /// The last successful sync date, or `nil` if never synced.
    var lastHealthSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: Self.lastHealthSyncDateKey) as? Date }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.lastHealthSyncDateKey)
            objectWillChange.send()
        }
    }

    /// The stored anchor for incremental HealthKit queries.
    ///
    /// Used to fetch only changes since the last sync rather than all data.
    var healthSyncAnchor: Data? {
        get { UserDefaults.standard.data(forKey: Self.healthSyncAnchorKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.healthSyncAnchorKey) }
    }

    // MARK: - Sync Status

    /// Represents the current state of Health sync operations.
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case failed(String)
    }

    // MARK: - HealthKit Types

    /// The HealthKit quantity type for body mass (weight).
    private var weightType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .bodyMass)
    }

    // MARK: - Initialization

    /// Creates a new HealthSyncManager with the specified health store.
    ///
    /// - Parameter healthStore: The HealthKit store to use. Defaults to the system HKHealthStore.
    ///   Pass a mock for testing.
    init(healthStore: any HealthStoreProtocol = HKHealthStore()) {
        self.healthStore = healthStore
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Checks the current authorization status for weight data.
    private func checkAuthorizationStatus() {
        guard Self.isHealthDataAvailable,
              let weightType = weightType else {
            isAuthorized = false
            return
        }

        let status = healthStore.authorizationStatus(for: weightType)
        isAuthorized = status == .sharingAuthorized
    }

    /// Requests authorization to read and write weight data to HealthKit.
    ///
    /// - Returns: `true` if the authorization dialog was presented.
    /// - Throws: HealthKit errors if the request fails.
    func requestAuthorization() async throws -> Bool {
        guard Self.isHealthDataAvailable,
              let weightType = weightType else {
            return false
        }

        let typesToShare: Set<HKSampleType> = [weightType]
        let typesToRead: Set<HKObjectType> = [weightType]

        let success = try await healthStore.requestAuthorization(
            toShare: typesToShare,
            read: typesToRead
        )

        // Update authorization status after request
        checkAuthorizationStatus()

        return success
    }

    // MARK: - Sync Operations

    /// Saves a weight entry to HealthKit with sync metadata.
    ///
    /// Creates an HKQuantitySample for the weight and saves it to HealthKit.
    /// On success, updates the entry's `healthKitUUID` and clears `pendingHealthSync`.
    ///
    /// - Parameter entry: The weight entry to sync
    /// - Throws: HealthKit errors if save fails or authorization denied
    func saveWeightToHealth(_ entry: WeightEntry) async throws {
        guard Self.isHealthDataAvailable,
              let weightType = weightType else {
            throw NSError(
                domain: "HealthSyncManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit not available"]
            )
        }

        // Convert weight to kg for HealthKit (standard unit)
        let weightInKg = entry.weightValue(in: .kg)
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightInKg)

        // Create metadata with sync version for conflict resolution
        let metadata: [String: Any] = [
            HKMetadataKeySyncVersion: entry.syncVersion,
            HKMetadataKeySyncIdentifier: entry.healthKitUUID ?? UUID().uuidString
        ]

        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: entry.date,
            end: entry.date,
            metadata: metadata
        )

        try await healthStore.save(sample)

        // Update entry with HealthKit reference
        entry.healthKitUUID = sample.uuid.uuidString
        entry.pendingHealthSync = false
    }

    /// Updates a weight entry in HealthKit after local modifications.
    ///
    /// Increments the sync version for conflict resolution and saves the updated entry.
    /// HealthKit uses the syncIdentifier to correlate with the existing sample.
    ///
    /// - Parameter entry: The weight entry that was modified
    /// - Throws: HealthKit errors if save fails
    func updateWeightInHealth(_ entry: WeightEntry) async throws {
        entry.syncVersion += 1
        entry.pendingHealthSync = true
        try await saveWeightToHealth(entry)
    }

    /// Deletes a weight entry from HealthKit.
    ///
    /// Queries HealthKit for the sample matching the entry's healthKitUUID and deletes it.
    /// Clears the entry's healthKitUUID on success.
    ///
    /// - Parameter entry: The weight entry to delete from Health
    /// - Throws: HealthKit errors if delete fails or sample not found
    func deleteWeightFromHealth(_ entry: WeightEntry) async throws {
        guard Self.isHealthDataAvailable,
              let weightType = weightType else {
            throw NSError(
                domain: "HealthSyncManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit not available"]
            )
        }

        guard let uuidString = entry.healthKitUUID,
              let uuid = UUID(uuidString: uuidString) else {
            // Entry was never synced to HealthKit, nothing to delete
            return
        }

        // Query for the sample with matching UUID
        let predicate = HKQuery.predicateForObject(with: uuid)
        let samples = try await querySamples(type: weightType, predicate: predicate)

        guard let sample = samples.first else {
            // Sample not found in HealthKit (may have been deleted externally)
            entry.healthKitUUID = nil
            return
        }

        try await healthStore.delete(sample)
        entry.healthKitUUID = nil
    }

    /// Queries HealthKit for samples matching the given type and predicate.
    ///
    /// - Parameters:
    ///   - type: The sample type to query
    ///   - predicate: Filter criteria for the query
    /// - Returns: Array of matching samples
    private func querySamples(
        type: HKSampleType,
        predicate: NSPredicate
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            healthStore.execute(query)
        }
    }
}
