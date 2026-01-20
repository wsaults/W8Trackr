//
//  WeightEntryTests.swift
//  W8TrackrTests
//
//  Unit tests for WeightEntry and related models
//

import Testing
import Foundation
@testable import W8Trackr

// MARK: - WeightEntry Tests

struct WeightEntryTests {

    @Test func weightEntryInitializesWithCorrectValues() {
        let date = Date.now
        let entry = WeightEntry(weight: 175.5, unit: .lb, date: date, note: "Test note", bodyFatPercentage: 20.0)

        #expect(entry.weightValue == 175.5)
        #expect(entry.weightUnit == "lb")
        #expect(entry.date == date)
        #expect(entry.note == "Test note")
        #expect(entry.bodyFatPercentage == 20.0)
    }

    @Test func weightEntryInitializesWithKilograms() {
        let entry = WeightEntry(weight: 80.0, unit: .kg)

        #expect(entry.weightValue == 80.0)
        #expect(entry.weightUnit == "kg")
    }

    @Test func weightEntryDefaultsToPounds() {
        let entry = WeightEntry(weight: 150.0)

        #expect(entry.weightUnit == "lb")
    }

    @Test func weightValueInSameUnitReturnsSameValue() {
        let entry = WeightEntry(weight: 180.0, unit: .lb)

        #expect(entry.weightValue(in: .lb) == 180.0)
    }

    @Test func weightValueConvertsPoundsToKilograms() {
        let entry = WeightEntry(weight: 100.0, unit: .lb)
        let result = entry.weightValue(in: .kg)
        let expected = 45.3592

        #expect(abs(result - expected) < 0.0001)
    }

    @Test func weightValueConvertsKilogramsToPounds() {
        let entry = WeightEntry(weight: 50.0, unit: .kg)
        let result = entry.weightValue(in: .lb)
        let expected = 110.231

        #expect(abs(result - expected) < 0.001)
    }

    @Test func weightEntryWithNilOptionalFields() {
        let entry = WeightEntry(weight: 170.0)

        #expect(entry.note == nil)
        #expect(entry.bodyFatPercentage == nil)
    }
}

// MARK: - DateRange Tests

struct DateRangeTests {

    @Test func oneWeekRangeReturnsSeven() {
        #expect(DateRange.oneWeek.days == 7)
    }

    @Test func allTimeRangeReturnsNil() {
        #expect(DateRange.allTime.days == nil)
    }

    @Test func dateRangeRawValues() {
        #expect(DateRange.oneWeek.rawValue == "1W")
        #expect(DateRange.oneMonth.rawValue == "1M")
        #expect(DateRange.threeMonth.rawValue == "3M")
        #expect(DateRange.sixMonth.rawValue == "6M")
        #expect(DateRange.oneYear.rawValue == "1Y")
        #expect(DateRange.allTime.rawValue == "All")
    }

    @Test func dateRangeAllCases() {
        let allCases = DateRange.allCases
        #expect(allCases.count == 6)
        #expect(allCases.contains(.oneWeek))
        #expect(allCases.contains(.oneMonth))
        #expect(allCases.contains(.threeMonth))
        #expect(allCases.contains(.sixMonth))
        #expect(allCases.contains(.oneYear))
        #expect(allCases.contains(.allTime))
    }
}

// MARK: - Goal Weight Validation Tests

struct GoalWeightValidationTests {

    @Test func validGoalWeightInPounds() {
        #expect(WeightUnit.lb.isValidWeight(160.0) == true)
        #expect(WeightUnit.lb.isValidWeight(200.0) == true)
        #expect(WeightUnit.lb.isValidWeight(100.0) == true)
    }

    @Test func validGoalWeightInKilograms() {
        #expect(WeightUnit.kg.isValidWeight(70.0) == true)
        #expect(WeightUnit.kg.isValidWeight(90.0) == true)
        #expect(WeightUnit.kg.isValidWeight(50.0) == true)
    }

    @Test func extremeButValidGoalWeights() {
        // Very low but valid
        #expect(WeightUnit.lb.isValidWeight(1.0) == true)
        #expect(WeightUnit.kg.isValidWeight(0.5) == true)

        // Very high but valid
        #expect(WeightUnit.lb.isValidWeight(1500.0) == true)
        #expect(WeightUnit.kg.isValidWeight(680.0) == true)
    }
}

// MARK: - Goal-Specific Weight Validation Tests

struct GoalSpecificWeightValidationTests {

    // MARK: - Goal Weight Bounds Tests

    @Test func minGoalWeightForPounds() {
        #expect(WeightUnit.lb.minGoalWeight == 66.0)
    }

    @Test func minGoalWeightForKilograms() {
        #expect(WeightUnit.kg.minGoalWeight == 30.0)
    }

    @Test func maxGoalWeightForPounds() {
        #expect(WeightUnit.lb.maxGoalWeight == 440.0)
    }

    @Test func maxGoalWeightForKilograms() {
        #expect(WeightUnit.kg.maxGoalWeight == 200.0)
    }

    // MARK: - Goal Weight Validation Tests

    @Test func validGoalWeightWithinMedicalBounds() {
        #expect(WeightUnit.lb.isValidGoalWeight(160.0) == true)
        #expect(WeightUnit.lb.isValidGoalWeight(66.0) == true)  // Min boundary
        #expect(WeightUnit.lb.isValidGoalWeight(440.0) == true) // Max boundary
        #expect(WeightUnit.kg.isValidGoalWeight(70.0) == true)
        #expect(WeightUnit.kg.isValidGoalWeight(30.0) == true)  // Min boundary
        #expect(WeightUnit.kg.isValidGoalWeight(200.0) == true) // Max boundary
    }

    @Test func invalidGoalWeightBelowMinimum() {
        #expect(WeightUnit.lb.isValidGoalWeight(65.9) == false)
        #expect(WeightUnit.lb.isValidGoalWeight(50.0) == false)
        #expect(WeightUnit.kg.isValidGoalWeight(29.9) == false)
        #expect(WeightUnit.kg.isValidGoalWeight(20.0) == false)
    }

    @Test func invalidGoalWeightAboveMaximum() {
        #expect(WeightUnit.lb.isValidGoalWeight(440.1) == false)
        #expect(WeightUnit.lb.isValidGoalWeight(500.0) == false)
        #expect(WeightUnit.kg.isValidGoalWeight(200.1) == false)
        #expect(WeightUnit.kg.isValidGoalWeight(250.0) == false)
    }

    // MARK: - Goal Weight Warning Tests

    @Test func lowGoalWeightWarningThresholds() {
        #expect(WeightUnit.lb.warningLowGoalWeight == 88.0)
        #expect(WeightUnit.kg.warningLowGoalWeight == 40.0)
    }

    @Test func highGoalWeightWarningThresholds() {
        #expect(WeightUnit.lb.warningHighGoalWeight == 330.0)
        #expect(WeightUnit.kg.warningHighGoalWeight == 150.0)
    }

    @Test func noWarningForNormalGoalWeight() {
        #expect(WeightUnit.lb.goalWeightWarning(160.0) == nil)
        #expect(WeightUnit.lb.goalWeightWarning(200.0) == nil)
        #expect(WeightUnit.kg.goalWeightWarning(70.0) == nil)
        #expect(WeightUnit.kg.goalWeightWarning(80.0) == nil)
    }

    @Test func lowWarningForLowGoalWeight() {
        let warning = WeightUnit.lb.goalWeightWarning(80.0)
        #expect(warning == .tooLow)

        let kgWarning = WeightUnit.kg.goalWeightWarning(35.0)
        #expect(kgWarning == .tooLow)
    }

    @Test func highWarningForHighGoalWeight() {
        let warning = WeightUnit.lb.goalWeightWarning(400.0)
        #expect(warning == .tooHigh)

        let kgWarning = WeightUnit.kg.goalWeightWarning(180.0)
        #expect(kgWarning == .tooHigh)
    }

    @Test func noWarningForInvalidGoalWeight() {
        // Invalid weights should return nil, not a warning
        #expect(WeightUnit.lb.goalWeightWarning(50.0) == nil)
        #expect(WeightUnit.lb.goalWeightWarning(500.0) == nil)
    }

    @Test func warningMessagesAreNotEmpty() {
        #expect(!GoalWeightWarning.tooLow.message.isEmpty)
        #expect(!GoalWeightWarning.tooHigh.message.isEmpty)
    }
}

// MARK: - Sample Data Tests

struct SampleDataTests {

    @Test func sampleDataIsNotEmpty() {
        #expect(!WeightEntry.sampleData.isEmpty)
    }

    @Test func sortedSampleDataIsDescending() {
        let sorted = WeightEntry.sortedSampleData

        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].date >= sorted[i + 1].date)
        }
    }

    @Test func shortSampleDataIsNotEmpty() {
        #expect(!WeightEntry.shortSampleData.isEmpty)
    }

    @Test func initialDataIsNotEmpty() {
        #expect(!WeightEntry.initialData.isEmpty)
    }

    @Test func sampleDataHasReasonableWeights() {
        for entry in WeightEntry.sampleData {
            #expect(entry.weightValue > 0)
            #expect(entry.weightValue < 500) // Reasonable upper bound
        }
    }
}
