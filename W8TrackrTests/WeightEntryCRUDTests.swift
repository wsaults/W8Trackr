//
//  WeightEntryCRUDTests.swift
//  W8TrackrTests
//
//  Tests for WeightEntry CRUD lifecycle operations.
//  Satisfies TEST-01 requirement: CRUD operations tested.
//

import Testing
import Foundation
@testable import W8Trackr

// MARK: - WeightEntry Create Tests

struct WeightEntryCreateTests {

    @Test func createEntryWithAllFields() {
        let date = Date.now
        let entry = WeightEntry(
            weight: 185.5,
            unit: .lb,
            date: date,
            note: "Morning weigh-in",
            bodyFatPercentage: 18.5
        )

        #expect(entry.weightValue == 185.5)
        #expect(entry.weightUnit == "lb")
        #expect(entry.date == date)
        #expect(entry.note == "Morning weigh-in")
        #expect(entry.bodyFatPercentage == 18.5)
        #expect(entry.source == "W8Trackr")
        #expect(entry.syncVersion == 1)
        #expect(entry.pendingHealthSync == true)
        #expect(entry.healthKitUUID == nil)
        #expect(entry.modifiedDate == nil)
    }

    @Test func createEntryWithMinimalFields() {
        let entry = WeightEntry(weight: 170.0)

        #expect(entry.weightValue == 170.0)
        #expect(entry.weightUnit == "lb")
        #expect(entry.note == nil)
        #expect(entry.bodyFatPercentage == nil)
    }

    @Test func createEntryWithKilogramsUnit() {
        let entry = WeightEntry(weight: 75.5, unit: .kg)

        #expect(entry.weightValue == 75.5)
        #expect(entry.weightUnit == "kg")
    }

    @Test func createEntryPreservesOptionalNote() {
        let entryWithNote = WeightEntry(weight: 180.0, note: "Post workout")
        let entryWithoutNote = WeightEntry(weight: 180.0)

        #expect(entryWithNote.note == "Post workout")
        #expect(entryWithoutNote.note == nil)
    }

    @Test func createEntryPreservesOptionalBodyFat() {
        let entryWithBodyFat = WeightEntry(weight: 180.0, bodyFatPercentage: 22.5)
        let entryWithoutBodyFat = WeightEntry(weight: 180.0)

        #expect(entryWithBodyFat.bodyFatPercentage == 22.5)
        #expect(entryWithoutBodyFat.bodyFatPercentage == nil)
    }

    @Test func createEntryWithCustomDate() {
        let customDate = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        let entry = WeightEntry(weight: 175.0, date: customDate)

        #expect(entry.date == customDate)
    }
}

// MARK: - WeightEntry Update Tests

struct WeightEntryUpdateTests {

    @Test func updateWeightValue() {
        let entry = WeightEntry(weight: 180.0)

        entry.weightValue = 175.0

        #expect(entry.weightValue == 175.0)
    }

    @Test func updateWeightUnit() {
        let entry = WeightEntry(weight: 180.0, unit: .lb)

        entry.weightUnit = WeightUnit.kg.rawValue

        #expect(entry.weightUnit == "kg")
    }

    @Test func updateDate() {
        let originalDate = Date.now
        let newDate = Calendar.current.date(byAdding: .day, value: -3, to: originalDate)!
        let entry = WeightEntry(weight: 180.0, date: originalDate)

        entry.date = newDate

        #expect(entry.date == newDate)
    }

    @Test func updateNote() {
        let entry = WeightEntry(weight: 180.0, note: "Original note")

        entry.note = "Updated note"

        #expect(entry.note == "Updated note")
    }

    @Test func updateNoteFromNilToValue() {
        let entry = WeightEntry(weight: 180.0)
        #expect(entry.note == nil)

        entry.note = "New note"

        #expect(entry.note == "New note")
    }

    @Test func updateNoteFromValueToNil() {
        let entry = WeightEntry(weight: 180.0, note: "Original note")

        entry.note = nil

        #expect(entry.note == nil)
    }

    @Test func updateBodyFatPercentage() {
        let entry = WeightEntry(weight: 180.0, bodyFatPercentage: 20.0)

        entry.bodyFatPercentage = 18.5

        #expect(entry.bodyFatPercentage == 18.5)
    }

    @Test func updateBodyFatFromNilToValue() {
        let entry = WeightEntry(weight: 180.0)
        #expect(entry.bodyFatPercentage == nil)

        entry.bodyFatPercentage = 22.0

        #expect(entry.bodyFatPercentage == 22.0)
    }

    @Test func updateBodyFatFromValueToNil() {
        let entry = WeightEntry(weight: 180.0, bodyFatPercentage: 20.0)

        entry.bodyFatPercentage = nil

        #expect(entry.bodyFatPercentage == nil)
    }

    @Test func updateMultipleFieldsInSequence() {
        let entry = WeightEntry(weight: 180.0, unit: .lb, note: "Initial")

        // Update multiple fields
        entry.weightValue = 175.5
        entry.weightUnit = WeightUnit.kg.rawValue
        entry.note = "Updated"
        entry.bodyFatPercentage = 19.0

        // Verify all changes persisted
        #expect(entry.weightValue == 175.5)
        #expect(entry.weightUnit == "kg")
        #expect(entry.note == "Updated")
        #expect(entry.bodyFatPercentage == 19.0)
    }

    @Test func updateModifiedDateTracking() {
        let entry = WeightEntry(weight: 180.0)
        #expect(entry.modifiedDate == nil)

        let modifiedTime = Date.now
        entry.modifiedDate = modifiedTime

        #expect(entry.modifiedDate == modifiedTime)
    }
}

// MARK: - WeightEntry HealthKit Sync State Tests

struct WeightEntryHealthSyncStateTests {

    @Test func pendingHealthSyncDefaultsToTrue() {
        let entry = WeightEntry(weight: 180.0)
        #expect(entry.pendingHealthSync == true)
    }

    @Test func updatePendingHealthSyncToFalse() {
        let entry = WeightEntry(weight: 180.0)

        entry.pendingHealthSync = false

        #expect(entry.pendingHealthSync == false)
    }

    @Test func needsSyncReflectsPendingHealthSync() {
        let entry = WeightEntry(weight: 180.0)
        #expect(entry.needsSync == true)

        entry.pendingHealthSync = false
        #expect(entry.needsSync == false)
    }

    @Test func sourceDefaultsToW8Trackr() {
        let entry = WeightEntry(weight: 180.0)
        #expect(entry.source == "W8Trackr")
    }

    @Test func updateSourceForImportedEntry() {
        let entry = WeightEntry(weight: 180.0)

        entry.source = "Withings Scale"

        #expect(entry.source == "Withings Scale")
        #expect(entry.isImported == true)
    }

    @Test func isImportedReturnsFalseForW8TrackrSource() {
        let entry = WeightEntry(weight: 180.0)
        #expect(entry.isImported == false)
    }

    @Test func isImportedReturnsTrueForExternalSource() {
        let entry = WeightEntry(weight: 180.0)
        entry.source = "Apple Watch"
        #expect(entry.isImported == true)
    }

    @Test func healthKitUUIDCanBeSet() {
        let entry = WeightEntry(weight: 180.0)
        #expect(entry.healthKitUUID == nil)

        let uuid = UUID().uuidString
        entry.healthKitUUID = uuid

        #expect(entry.healthKitUUID == uuid)
    }

    @Test func syncVersionCanBeIncremented() {
        let entry = WeightEntry(weight: 180.0)
        #expect(entry.syncVersion == 1)

        entry.syncVersion = 2

        #expect(entry.syncVersion == 2)
    }
}

// MARK: - WeightEntry Conversion Tests

struct WeightEntryConversionTests {

    @Test func weightValueInSameUnitReturnsOriginal() {
        let entry = WeightEntry(weight: 180.0, unit: .lb)
        #expect(entry.weightValue(in: .lb) == 180.0)

        let kgEntry = WeightEntry(weight: 80.0, unit: .kg)
        #expect(kgEntry.weightValue(in: .kg) == 80.0)
    }

    @Test func weightValueConvertsLbToKg() {
        let entry = WeightEntry(weight: 220.0, unit: .lb)
        let kgValue = entry.weightValue(in: .kg)

        // 220 lb * 0.453592 = 99.79024 kg
        #expect(abs(kgValue - 99.79024) < 0.001)
    }

    @Test func weightValueConvertsKgToLb() {
        let entry = WeightEntry(weight: 100.0, unit: .kg)
        let lbValue = entry.weightValue(in: .lb)

        // 100 kg * 2.20462 = 220.462 lb
        #expect(abs(lbValue - 220.462) < 0.001)
    }

    @Test func conversionIsReversible() {
        let originalWeight = 185.0
        let entry = WeightEntry(weight: originalWeight, unit: .lb)

        // Convert lb -> kg -> lb
        let kgValue = entry.weightValue(in: .kg)
        let backToLb = kgValue.weightValue(from: .kg, to: .lb)

        // Tolerance of 0.01 accounts for floating-point rounding in conversion constants
        #expect(abs(backToLb - originalWeight) < 0.01)
    }
}
