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

    /// Shared instance for convenient access from views.
    ///
    /// Uses the real HKHealthStore. For testing, create instances with mock stores.
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

    // MARK: - Export Operations

    /// Saves a weight entry to HealthKit.
    ///
    /// Creates a new HKQuantitySample for the weight and stores the resulting UUID
    /// in the entry's `healthKitUUID` field for future updates/deletions.
    ///
    /// - Parameter entry: The weight entry to save
    /// - Throws: HealthKit errors if save fails
    func saveWeightToHealth(entry: WeightEntry) async throws {
        guard isHealthSyncEnabled,
              Self.isHealthDataAvailable,
              let weightType = weightType else {
            return
        }

        syncStatus = .syncing

        do {
            let sample = createWeightSample(from: entry, type: weightType)
            try await healthStore.save(sample)

            // Store the HealthKit UUID for future updates/deletions
            entry.healthKitUUID = sample.uuid.uuidString
            entry.pendingHealthSync = false
            entry.syncVersion += 1

            syncStatus = .success
            lastHealthSyncDate = Date()
        } catch {
            // Graceful degradation: if auth denied, silently mark for later sync
            if isAuthorizationDeniedError(error) {
                entry.pendingHealthSync = true
                syncStatus = .idle
                return
            }
            syncStatus = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Updates an existing weight entry in HealthKit.
    ///
    /// HealthKit doesn't support direct updates, so this:
    /// 1. Deletes the existing sample (if healthKitUUID exists)
    /// 2. Creates a new sample with updated values
    /// 3. Updates the entry's healthKitUUID to the new sample
    ///
    /// - Parameter entry: The weight entry to update
    /// - Throws: HealthKit errors if update fails
    func updateWeightInHealth(entry: WeightEntry) async throws {
        guard isHealthSyncEnabled,
              Self.isHealthDataAvailable,
              let weightType = weightType else {
            return
        }

        syncStatus = .syncing

        do {
            // If we have an existing HealthKit sample, delete it first
            if let existingUUID = entry.healthKitUUID,
               let uuid = UUID(uuidString: existingUUID) {
                // Create a predicate to find and delete the old sample
                let predicate = HKQuery.predicateForObject(with: uuid)
                try await deleteHealthSamples(matching: predicate, type: weightType)
            }

            // Create and save new sample
            let sample = createWeightSample(from: entry, type: weightType)
            try await healthStore.save(sample)

            // Update entry with new UUID and sync metadata
            entry.healthKitUUID = sample.uuid.uuidString
            entry.pendingHealthSync = false
            entry.syncVersion += 1

            syncStatus = .success
            lastHealthSyncDate = Date()
        } catch {
            // Graceful degradation: if auth denied, silently mark for later sync
            if isAuthorizationDeniedError(error) {
                entry.pendingHealthSync = true
                syncStatus = .idle
                return
            }
            syncStatus = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Deletes a weight entry from HealthKit.
    ///
    /// Uses the stored `healthKitUUID` to locate and delete the corresponding sample.
    /// No-op if the entry hasn't been synced to HealthKit.
    ///
    /// - Parameter entry: The weight entry to delete from Health
    /// - Throws: HealthKit errors if delete fails
    func deleteWeightFromHealth(entry: WeightEntry) async throws {
        guard isHealthSyncEnabled,
              Self.isHealthDataAvailable,
              let weightType = weightType,
              let existingUUID = entry.healthKitUUID,
              let uuid = UUID(uuidString: existingUUID) else {
            return
        }

        syncStatus = .syncing

        do {
            let predicate = HKQuery.predicateForObject(with: uuid)
            try await deleteHealthSamples(matching: predicate, type: weightType)

            entry.healthKitUUID = nil
            entry.pendingHealthSync = false

            syncStatus = .success
            lastHealthSyncDate = Date()
        } catch {
            // Graceful degradation: if auth denied, silently clear UUID
            // The HealthKit sample may remain orphaned, but app continues
            if isAuthorizationDeniedError(error) {
                entry.healthKitUUID = nil
                syncStatus = .idle
                return
            }
            syncStatus = .failed(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Private Helpers

    /// Checks if an error indicates HealthKit authorization was denied.
    ///
    /// Used for graceful degradation: when auth is denied, operations silently
    /// succeed from the app's perspective while marking entries for later sync.
    private func isAuthorizationDeniedError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == HKErrorDomain &&
               nsError.code == HKError.errorAuthorizationDenied.rawValue
    }

    /// Creates an HKQuantitySample from a WeightEntry.
    private func createWeightSample(from entry: WeightEntry, type: HKQuantityType) -> HKQuantitySample {
        let unit = WeightUnit(rawValue: entry.weightUnit) ?? .lb
        let weightInKg = unit == .kg ? entry.weightValue : entry.weightValue * WeightUnit.lbToKg

        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightInKg)

        // Include sync metadata for conflict resolution
        let metadata: [String: Any] = [
            HKMetadataKeySyncVersion: entry.syncVersion,
            HKMetadataKeySyncIdentifier: entry.id.hashValue
        ]

        return HKQuantitySample(
            type: type,
            quantity: quantity,
            start: entry.date,
            end: entry.date,
            metadata: metadata
        )
    }

    /// Deletes HealthKit samples matching a predicate.
    private func deleteHealthSamples(matching predicate: NSPredicate, type: HKSampleType) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { [weak self] _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first else {
                    // No sample found - that's OK, just continue
                    continuation.resume()
                    return
                }

                Task { @MainActor [weak self] in
                    do {
                        try await self?.healthStore.delete(sample)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            healthStore.execute(query)
        }
    }
}
