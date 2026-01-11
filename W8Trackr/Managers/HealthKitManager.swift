//
//  HealthKitManager.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var lastSyncStatus: SyncStatus = .none

    private static let healthSyncEnabledKey = "healthSyncEnabled"

    var isHealthSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.healthSyncEnabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.healthSyncEnabledKey)
            objectWillChange.send()
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
        DispatchQueue.main.async {
            self.isAuthorized = status == .sharingAuthorized
        }
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard Self.isHealthKitAvailable else {
            completion(false, nil)
            return
        }

        var typesToWrite: Set<HKSampleType> = []
        if let weightType = weightType {
            typesToWrite.insert(weightType)
        }
        if let bodyFatType = bodyFatType {
            typesToWrite.insert(bodyFatType)
        }

        guard !typesToWrite.isEmpty else {
            completion(false, nil)
            return
        }

        healthStore.requestAuthorization(toShare: typesToWrite, read: nil) { success, error in
            DispatchQueue.main.async {
                // Check actual authorization status, not just dialog completion
                // The 'success' parameter only indicates the dialog was presented,
                // not that the user granted permission
                if let weightType = self.weightType {
                    self.isAuthorized = self.healthStore.authorizationStatus(for: weightType) == .sharingAuthorized
                } else {
                    self.isAuthorized = false
                }
                completion(self.isAuthorized, error)
            }
        }
    }

    func saveWeight(_ weightInPounds: Double, date: Date, completion: ((Bool, Error?) -> Void)? = nil) {
        guard isHealthSyncEnabled,
              Self.isHealthKitAvailable,
              let weightType = weightType else {
            completion?(false, nil)
            return
        }

        DispatchQueue.main.async {
            self.lastSyncStatus = .syncing
        }

        // HealthKit uses kilograms internally, convert from pounds
        let weightInKg = weightInPounds * WeightUnit.lbToKg
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightInKg)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)

        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.lastSyncStatus = .success
                } else {
                    self.lastSyncStatus = .failed(error?.localizedDescription ?? "Unknown error")
                }
                completion?(success, error)
            }
        }
    }

    func saveBodyFatPercentage(_ percentage: Double, date: Date, completion: ((Bool, Error?) -> Void)? = nil) {
        guard isHealthSyncEnabled,
              Self.isHealthKitAvailable,
              let bodyFatType = bodyFatType else {
            completion?(false, nil)
            return
        }

        // HealthKit expects body fat as a ratio (0.0-1.0), not a percentage
        let ratio = percentage / 100.0
        let quantity = HKQuantity(unit: .percent(), doubleValue: ratio)
        let sample = HKQuantitySample(type: bodyFatType, quantity: quantity, start: date, end: date)

        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion?(success, error)
            }
        }
    }

    func saveWeightEntry(weightInUnit: Double, unit: WeightUnit, bodyFatPercentage: Decimal?, date: Date, completion: ((Bool) -> Void)? = nil) {
        guard isHealthSyncEnabled, Self.isHealthKitAvailable else {
            completion?(false)
            return
        }

        // Convert to pounds for internal storage (our standard)
        let weightInPounds = unit == .kg ? weightInUnit * WeightUnit.kgToLb : weightInUnit

        saveWeight(weightInPounds, date: date) { success, _ in
            guard success else {
                completion?(false)
                return
            }

            // Save body fat if available
            if let bodyFat = bodyFatPercentage {
                self.saveBodyFatPercentage(NSDecimalNumber(decimal: bodyFat).doubleValue, date: date) { bfSuccess, _ in
                    completion?(bfSuccess)
                }
            } else {
                completion?(true)
            }
        }
    }
}
