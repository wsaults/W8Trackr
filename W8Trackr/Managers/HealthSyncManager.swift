//
//  HealthSyncManager.swift
//  W8Trackr
//
//  Manages bidirectional synchronization between W8Trackr and Apple HealthKit.
//

import Foundation
import HealthKit
import SwiftData
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
@Observable @MainActor
final class HealthSyncManager {

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

    /// The UserDefaults instance for persisting settings (injectable for testing).
    private let userDefaults: UserDefaults

    // MARK: - Observable State

    /// The current sync status for UI feedback.
    var syncStatus: SyncStatus = .idle

    /// Whether the user has granted authorization to access Health data.
    var isAuthorized = false

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
        get { userDefaults.bool(forKey: Self.healthSyncEnabledKey) }
        set {
            userDefaults.set(newValue, forKey: Self.healthSyncEnabledKey)
        }
    }

    /// The last successful sync date, or `nil` if never synced.
    var lastHealthSyncDate: Date? {
        get { userDefaults.object(forKey: Self.lastHealthSyncDateKey) as? Date }
        set {
            userDefaults.set(newValue, forKey: Self.lastHealthSyncDateKey)
        }
    }

    /// The stored anchor for incremental HealthKit queries.
    ///
    /// Used to fetch only changes since the last sync rather than all data.
    var healthSyncAnchor: Data? {
        get { userDefaults.data(forKey: Self.healthSyncAnchorKey) }
        set { userDefaults.set(newValue, forKey: Self.healthSyncAnchorKey) }
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
    /// - Parameters:
    ///   - healthStore: The HealthKit store to use. Defaults to the system HKHealthStore.
    ///     Pass a mock for testing.
    ///   - userDefaults: The UserDefaults instance for persisting settings. Defaults to `.standard`.
    ///     Pass a custom suite for test isolation.
    init(healthStore: any HealthStoreProtocol = HKHealthStore(), userDefaults: UserDefaults = .standard) {
        self.healthStore = healthStore
        self.userDefaults = userDefaults
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
            HKMetadataKeySyncIdentifier: String(entry.id.hashValue)
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

    // MARK: - Anchor Persistence

    /// Saves the HKQueryAnchor for incremental sync across app launches.
    private func saveAnchor(_ anchor: HKQueryAnchor?) {
        guard let anchor = anchor else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: anchor,
                requiringSecureCoding: true
            )
            healthSyncAnchor = data
        } catch {
            // Anchor archiving failure is non-fatal; next sync will fetch all data
        }
    }

    /// Loads the persisted HKQueryAnchor for incremental sync.
    private func loadAnchor() -> HKQueryAnchor? {
        guard let data = healthSyncAnchor else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(
                ofClass: HKQueryAnchor.self,
                from: data
            )
        } catch {
            // Unarchive failure is non-fatal; nil triggers full sync
            return nil
        }
    }

    // MARK: - Import Operations

    /// Imports weight entries from HealthKit using an anchored query.
    ///
    /// Uses HKAnchoredObjectQueryDescriptor for incremental sync:
    /// - First call (nil anchor): Fetches all historical weight data
    /// - Subsequent calls: Fetches only changes since last sync
    ///
    /// Creates WeightEntry for each imported sample with source attribution.
    /// Skips samples that were originally created by W8Trackr (by checking source bundle ID).
    ///
    /// - Parameter modelContext: The SwiftData context to insert entries into
    /// - Returns: Number of new entries imported
    /// - Throws: HealthKit query errors
    @discardableResult
    func importWeightFromHealth(modelContext: ModelContext) async throws -> Int {
        guard Self.isHealthDataAvailable,
              let weightType = weightType else {
            return 0
        }

        syncStatus = .syncing

        do {
            let descriptor = HKAnchoredObjectQueryDescriptor(
                predicates: [.quantitySample(type: weightType)],
                anchor: loadAnchor()
            )

            // Cast required because protocol doesn't expose result(for:) method
            guard let store = healthStore as? HKHealthStore else {
                syncStatus = .idle
                return 0
            }

            let result = try await descriptor.result(for: store)

            // Save anchor for next incremental sync
            saveAnchor(result.newAnchor)

            var importedCount = 0

            // Process added samples
            for sample in result.addedSamples {
                guard let quantitySample = sample as? HKQuantitySample else { continue }

                // Skip samples created by W8Trackr (avoid duplicates)
                if quantitySample.sourceRevision.source.bundleIdentifier == Bundle.main.bundleIdentifier {
                    continue
                }

                // Skip if we already have this entry (by healthKitUUID)
                let uuidString = quantitySample.uuid.uuidString
                let existingDescriptor = FetchDescriptor<WeightEntry>(
                    predicate: #Predicate { $0.healthKitUUID == uuidString }
                )
                let existingEntries = try modelContext.fetch(existingDescriptor)
                guard existingEntries.isEmpty else { continue }

                // Create WeightEntry from sample
                let entry = createEntryFromSample(quantitySample)
                modelContext.insert(entry)
                importedCount += 1
            }

            // Handle deleted samples - remove imported entries if source sample was deleted
            for deletedObject in result.deletedObjects {
                let uuidString = deletedObject.uuid.uuidString
                let deleteDescriptor = FetchDescriptor<WeightEntry>(
                    predicate: #Predicate { $0.healthKitUUID == uuidString }
                )
                let entriesToDelete = try modelContext.fetch(deleteDescriptor)
                for entry in entriesToDelete where entry.isImported {
                    // Only delete imported entries (not W8Trackr-created ones)
                    modelContext.delete(entry)
                }
            }

            if importedCount > 0 || !result.deletedObjects.isEmpty {
                try modelContext.save()
            }

            syncStatus = .success
            lastHealthSyncDate = Date()

            return importedCount
        } catch {
            syncStatus = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Creates a WeightEntry from an HKQuantitySample.
    ///
    /// Converts the sample to the app's internal format:
    /// - Extracts weight in kg from the sample quantity
    /// - Converts to lb (app's storage unit)
    /// - Sets source to the originating app/device name
    /// - Stores healthKitUUID for duplicate detection
    /// - Marks pendingHealthSync as false (already in Health)
    private func createEntryFromSample(_ sample: HKQuantitySample) -> WeightEntry {
        let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        let weightInLb = weightInKg * WeightUnit.kgToLb

        let entry = WeightEntry(
            weight: weightInLb,
            unit: .lb,
            date: sample.startDate
        )

        // Set source from HealthKit sample (e.g., "Withings Scale", "Fitness app")
        entry.source = sample.sourceRevision.source.name
        entry.healthKitUUID = sample.uuid.uuidString
        entry.pendingHealthSync = false  // Already in Health, no need to sync back

        return entry
    }
}
