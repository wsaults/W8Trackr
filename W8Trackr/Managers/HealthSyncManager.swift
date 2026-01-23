//
//  HealthSyncManager.swift
//  W8Trackr
//
//  Manages importing weight data from Apple HealthKit.
//

import Foundation
import HealthKit
import SwiftData
import SwiftUI

/// Manages importing weight entries from Apple HealthKit.
///
/// This manager handles:
/// - Authorization requests for Health data access
/// - Importing weight entries from HealthKit
/// - Background delivery for automatic sync when Health data changes
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

    /// The currently running observer query for background updates.
    /// Stored to allow stopping the query when import is disabled.
    private var observerQuery: HKObserverQuery?

    // MARK: - Observable State

    /// The current sync status for UI feedback.
    var syncStatus: SyncStatus = .idle

    /// Whether the user has granted authorization to access Health data.
    var isAuthorized = false

    // MARK: - Persisted State

    /// User preference key for Health import enabled/disabled.
    private static let healthImportEnabledKey = "healthImportEnabled"

    /// Key for storing the HealthKit query anchor for incremental sync.
    private static let healthSyncAnchorKey = "healthSyncAnchor"

    /// Key for storing the last successful sync timestamp.
    private static let lastHealthSyncDateKey = "lastHealthSyncDate"

    /// Whether Health import is enabled by the user.
    ///
    /// When enabled, the app imports weight data from Apple Health
    /// and sets up background delivery for automatic sync.
    var isHealthImportEnabled: Bool {
        get { userDefaults.bool(forKey: Self.healthImportEnabledKey) }
        set {
            userDefaults.set(newValue, forKey: Self.healthImportEnabledKey)
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

    /// Requests authorization to read weight data from HealthKit.
    ///
    /// - Returns: `true` if the authorization dialog was presented.
    /// - Throws: HealthKit errors if the request fails.
    func requestAuthorization() async throws -> Bool {
        guard Self.isHealthDataAvailable,
              let weightType = weightType else {
            return false
        }

        // Only request read access (no write/share)
        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKObjectType> = [weightType]

        let success = try await healthStore.requestAuthorization(
            toShare: typesToShare,
            read: typesToRead
        )

        // Update authorization status after request
        checkAuthorizationStatus()

        return success
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

    // MARK: - Background Delivery

    /// Sets up background delivery for weight data import.
    ///
    /// Creates an HKObserverQuery to receive notifications when Health data changes,
    /// then runs an incremental import using the anchored query.
    ///
    /// CRITICAL: The completion handler MUST always be called in the observer callback.
    /// Failure to call it causes HealthKit to use exponential backoff, eventually
    /// stopping background delivery entirely.
    ///
    /// - Parameter modelContext: The SwiftData context for importing entries
    func setupBackgroundDelivery(modelContext: ModelContext) {
        guard Self.isHealthDataAvailable,
              isHealthImportEnabled,
              let weightType = weightType else {
            return
        }

        // Stop existing query if any
        if let existingQuery = observerQuery {
            healthStore.stop(existingQuery)
            observerQuery = nil
        }

        let query = HKObserverQuery(
            sampleType: weightType,
            predicate: nil
        ) { [weak self] _, completionHandler, error in
            // CRITICAL: Always call completion handler using defer
            // Missing this call causes exponential backoff and eventual delivery halt
            defer { completionHandler() }

            guard error == nil else {
                print("Observer query error: \(error!.localizedDescription)")
                return
            }

            // Run incremental import on main actor
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await self.importWeightFromHealth(modelContext: modelContext)
                } catch {
                    print("Background import failed: \(error)")
                }
            }
        }

        healthStore.execute(query)
        observerQuery = query

        // Enable background delivery with immediate frequency
        healthStore.enableBackgroundDelivery(
            for: weightType,
            frequency: .immediate
        ) { success, error in
            if !success, let error {
                print("enableBackgroundDelivery failed: \(error)")
            }
        }
    }

    /// Stops background delivery and clears the observer query.
    ///
    /// Called when user disables Health import.
    func stopBackgroundDelivery() {
        guard let weightType = weightType else { return }

        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
        }

        // Optionally disable background delivery
        // Note: Not strictly required since query is stopped
        healthStore.disableBackgroundDelivery(for: weightType) { _, _ in }
    }
}
