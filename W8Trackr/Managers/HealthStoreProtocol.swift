//
//  HealthStoreProtocol.swift
//  W8Trackr
//
//  Protocol abstraction over HKHealthStore for dependency injection and testing.
//

import Foundation
import HealthKit

/// Protocol for HealthKit store operations, enabling dependency injection and testing.
///
/// This protocol abstracts the key HKHealthStore operations used by HealthSyncManager,
/// allowing unit tests to use a mock implementation without requiring device access.
///
/// Marked as `Sendable` because `HKHealthStore` is thread-safe by Apple's design
/// and can be used from any isolation context.
protocol HealthStoreProtocol: Sendable {
    /// Returns whether HealthKit is available on this device.
    /// - Returns: `false` on iPads without Health app, `true` on iPhones.
    static func isHealthDataAvailable() -> Bool

    /// Requests authorization to read and write health data types.
    /// - Parameters:
    ///   - typesToShare: Sample types the app wants to write
    ///   - typesToRead: Object types the app wants to read
    /// - Returns: `true` if authorization request was shown (not necessarily granted)
    /// - Throws: HealthKit errors if the request fails
    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws -> Bool

    /// Returns the authorization status for a specific type.
    /// - Parameter type: The object type to check
    /// - Returns: The current authorization status
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus

    /// Saves a sample to the HealthKit store.
    /// - Parameter sample: The sample to save
    /// - Throws: HealthKit errors (authorization, database, etc.)
    func save(_ sample: HKSample) async throws

    /// Deletes a sample from the HealthKit store.
    /// - Parameter sample: The sample to delete
    /// - Throws: HealthKit errors (authorization, not found, etc.)
    func delete(_ sample: HKSample) async throws

    /// Executes a HealthKit query.
    /// - Parameter query: The query to execute (observer, anchored, sample query, etc.)
    func execute(_ query: HKQuery)

    /// Stops a running query.
    /// - Parameter query: The query to stop
    func stop(_ query: HKQuery)

    /// Enables background delivery for a data type.
    /// - Parameters:
    ///   - type: The object type to monitor
    ///   - frequency: How often to deliver updates
    ///   - completion: Called with success/failure
    func enableBackgroundDelivery(
        for type: HKObjectType,
        frequency: HKUpdateFrequency,
        withCompletion completion: @escaping @Sendable (Bool, Error?) -> Void
    )
}

// MARK: - HKHealthStore Conformance

extension HKHealthStore: HealthStoreProtocol {
    /// Async wrapper for requestAuthorization that bridges to the callback-based API.
    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    /// Async wrapper for save that bridges to the callback-based API.
    func save(_ sample: HKSample) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            save(sample) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "HealthKit",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Save failed without error"]
                    ))
                }
            }
        }
    }

    /// Async wrapper for delete that bridges to the callback-based API.
    func delete(_ sample: HKSample) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delete(sample) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "HealthKit",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Delete failed without error"]
                    ))
                }
            }
        }
    }
}
