//
//  HealthKitManager.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import Foundation
import HealthKit

@Observable @MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    var isAuthorized = false
    var lastSyncStatus: SyncStatus = .none

    private static let healthSyncEnabledKey = "healthSyncEnabled"

    var isHealthSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.healthSyncEnabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.healthSyncEnabledKey)
        }
    }

    enum SyncStatus: Equatable {
        case none
        case syncing
        case success
        case failed(String)
    }

    static var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var weightType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .bodyMass)
    }

    private var bodyFatType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)
    }

    init() {
        checkAuthorizationStatus()
    }

    private func checkAuthorizationStatus() {
        guard Self.isHealthKitAvailable,
              let weightType = weightType else {
            return
        }

        let status = healthStore.authorizationStatus(for: weightType)
        isAuthorized = status == .sharingAuthorized
    }

    func requestAuthorization() async -> (success: Bool, error: (any Error)?) {
        guard Self.isHealthKitAvailable else {
            return (false, nil)
        }

        var typesToWrite: Set<HKSampleType> = []
        if let weightType = weightType {
            typesToWrite.insert(weightType)
        }
        if let bodyFatType = bodyFatType {
            typesToWrite.insert(bodyFatType)
        }

        guard !typesToWrite.isEmpty else {
            return (false, nil)
        }

        do {
            // Use withCheckedThrowingContinuation to call the callback-based API
            // to avoid conflict with HealthStoreProtocol extension
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.requestAuthorization(toShare: typesToWrite, read: nil) { _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            // Check actual authorization status, not just dialog completion
            // The 'success' parameter only indicates the dialog was presented,
            // not that the user granted permission
            if let weightType = weightType {
                isAuthorized = healthStore.authorizationStatus(for: weightType) == .sharingAuthorized
            } else {
                isAuthorized = false
            }
            return (isAuthorized, nil)
        } catch {
            isAuthorized = false
            return (false, error)
        }
    }

    func saveWeight(_ weightInPounds: Double, date: Date) async -> (success: Bool, error: (any Error)?) {
        guard isHealthSyncEnabled,
              Self.isHealthKitAvailable,
              let weightType = weightType else {
            return (false, nil)
        }

        lastSyncStatus = .syncing

        // HealthKit uses kilograms internally, convert from pounds
        let weightInKg = weightInPounds * WeightUnit.lbToKg
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightInKg)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)

        do {
            try await healthStore.save(sample)
            lastSyncStatus = .success
            return (true, nil)
        } catch {
            lastSyncStatus = .failed(error.localizedDescription)
            return (false, error)
        }
    }

    func saveBodyFatPercentage(_ percentage: Double, date: Date) async -> (success: Bool, error: (any Error)?) {
        guard isHealthSyncEnabled,
              Self.isHealthKitAvailable,
              let bodyFatType = bodyFatType else {
            return (false, nil)
        }

        // HealthKit expects body fat as a ratio (0.0-1.0), not a percentage
        let ratio = percentage / 100.0
        let quantity = HKQuantity(unit: .percent(), doubleValue: ratio)
        let sample = HKQuantitySample(type: bodyFatType, quantity: quantity, start: date, end: date)

        do {
            try await healthStore.save(sample)
            return (true, nil)
        } catch {
            return (false, error)
        }
    }

    func saveWeightEntry(weightInUnit: Double, unit: WeightUnit, bodyFatPercentage: Decimal?, date: Date) async -> Bool {
        guard isHealthSyncEnabled, Self.isHealthKitAvailable else {
            return false
        }

        // Convert to pounds for internal storage (our standard)
        let weightInPounds = unit == .kg ? weightInUnit * WeightUnit.kgToLb : weightInUnit

        let (weightSuccess, _) = await saveWeight(weightInPounds, date: date)
        guard weightSuccess else {
            return false
        }

        // Save body fat if available
        if let bodyFat = bodyFatPercentage {
            let (bfSuccess, _) = await saveBodyFatPercentage(NSDecimalNumber(decimal: bodyFat).doubleValue, date: date)
            return bfSuccess
        }
        return true
    }
}
