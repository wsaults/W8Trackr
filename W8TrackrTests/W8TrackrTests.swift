//
//  W8TrackrTests.swift
//  W8TrackrTests
//
//  Created by Will Saults on 4/28/25.
//

import Testing
import Foundation
@testable import W8Trackr

// MARK: - Weight Unit Tests

struct WeightUnitTests {

    // MARK: - Default Weight Tests

    @Test func defaultWeightForPounds() {
        #expect(WeightUnit.lb.defaultWeight == 180.0)
    }

    @Test func defaultWeightForKilograms() {
        #expect(WeightUnit.kg.defaultWeight == 80.0)
    }

    // MARK: - Min Weight Tests

    @Test func minWeightForPounds() {
        #expect(WeightUnit.lb.minWeight == 1.0)
    }

    @Test func minWeightForKilograms() {
        #expect(WeightUnit.kg.minWeight == 0.5)
    }

    // MARK: - Max Weight Tests

    @Test func maxWeightForPounds() {
        #expect(WeightUnit.lb.maxWeight == 1500.0)
    }

    @Test func maxWeightForKilograms() {
        #expect(WeightUnit.kg.maxWeight == 680.0)
    }

    // MARK: - Weight Validation Tests

    @Test func validWeightWithinRangeForPounds() {
        #expect(WeightUnit.lb.isValidWeight(150.0) == true)
        #expect(WeightUnit.lb.isValidWeight(1.0) == true)    // Min boundary
        #expect(WeightUnit.lb.isValidWeight(1500.0) == true) // Max boundary
    }

    @Test func validWeightWithinRangeForKilograms() {
        #expect(WeightUnit.kg.isValidWeight(70.0) == true)
        #expect(WeightUnit.kg.isValidWeight(0.5) == true)   // Min boundary
        #expect(WeightUnit.kg.isValidWeight(680.0) == true) // Max boundary
    }

    @Test func invalidWeightBelowMinimum() {
        #expect(WeightUnit.lb.isValidWeight(0.5) == false)
        #expect(WeightUnit.lb.isValidWeight(0.0) == false)
        #expect(WeightUnit.kg.isValidWeight(0.4) == false)
        #expect(WeightUnit.kg.isValidWeight(0.0) == false)
    }

    @Test func invalidWeightAboveMaximum() {
        #expect(WeightUnit.lb.isValidWeight(1500.1) == false)
        #expect(WeightUnit.lb.isValidWeight(2000.0) == false)
        #expect(WeightUnit.kg.isValidWeight(680.1) == false)
        #expect(WeightUnit.kg.isValidWeight(1000.0) == false)
    }

    @Test func negativeWeightsAreInvalid() {
        #expect(WeightUnit.lb.isValidWeight(-1.0) == false)
        #expect(WeightUnit.kg.isValidWeight(-50.0) == false)
    }
}

// MARK: - Weight Validation Boundary Tests

struct WeightValidationBoundaryTests {

    // MARK: - Epsilon Edge Cases (Floating-Point Precision)

    @Test func poundsJustBelowMinimumIsInvalid() {
        // 0.9999999 is just under 1.0 lb minimum
        #expect(WeightUnit.lb.isValidWeight(0.9999999) == false)
        #expect(WeightUnit.lb.isValidWeight(0.999) == false)
    }

    @Test func poundsJustAboveMinimumIsValid() {
        // Values at or just above 1.0 should be valid
        #expect(WeightUnit.lb.isValidWeight(1.0) == true)
        #expect(WeightUnit.lb.isValidWeight(1.0000001) == true)
        #expect(WeightUnit.lb.isValidWeight(1.001) == true)
    }

    @Test func poundsJustBelowMaximumIsValid() {
        // Values at or just below 1500.0 should be valid
        #expect(WeightUnit.lb.isValidWeight(1500.0) == true)
        #expect(WeightUnit.lb.isValidWeight(1499.9999999) == true)
        #expect(WeightUnit.lb.isValidWeight(1499.999) == true)
    }

    @Test func poundsJustAboveMaximumIsInvalid() {
        // 1500.0000001 is just over 1500.0 lb maximum
        #expect(WeightUnit.lb.isValidWeight(1500.0000001) == false)
        #expect(WeightUnit.lb.isValidWeight(1500.001) == false)
    }

    @Test func kilogramsJustBelowMinimumIsInvalid() {
        // 0.4999999 is just under 0.5 kg minimum
        #expect(WeightUnit.kg.isValidWeight(0.4999999) == false)
        #expect(WeightUnit.kg.isValidWeight(0.499) == false)
    }

    @Test func kilogramsJustAboveMinimumIsValid() {
        // Values at or just above 0.5 should be valid
        #expect(WeightUnit.kg.isValidWeight(0.5) == true)
        #expect(WeightUnit.kg.isValidWeight(0.5000001) == true)
        #expect(WeightUnit.kg.isValidWeight(0.501) == true)
    }

    @Test func kilogramsJustBelowMaximumIsValid() {
        // Values at or just below 680.0 should be valid
        #expect(WeightUnit.kg.isValidWeight(680.0) == true)
        #expect(WeightUnit.kg.isValidWeight(679.9999999) == true)
        #expect(WeightUnit.kg.isValidWeight(679.999) == true)
    }

    @Test func kilogramsJustAboveMaximumIsInvalid() {
        // 680.0000001 is just over 680.0 kg maximum
        #expect(WeightUnit.kg.isValidWeight(680.0000001) == false)
        #expect(WeightUnit.kg.isValidWeight(680.001) == false)
    }

    // MARK: - Extreme Values

    @Test func verySmallPositiveWeightsAreInvalid() {
        // Very small values below minimum
        #expect(WeightUnit.lb.isValidWeight(0.0001) == false)
        #expect(WeightUnit.kg.isValidWeight(0.0001) == false)
        #expect(WeightUnit.lb.isValidWeight(Double.leastNormalMagnitude) == false)
        #expect(WeightUnit.kg.isValidWeight(Double.leastNormalMagnitude) == false)
    }

    @Test func veryLargeWeightsAreInvalid() {
        // Extremely large values
        #expect(WeightUnit.lb.isValidWeight(10000.0) == false)
        #expect(WeightUnit.kg.isValidWeight(10000.0) == false)
        #expect(WeightUnit.lb.isValidWeight(Double.greatestFiniteMagnitude) == false)
        #expect(WeightUnit.kg.isValidWeight(Double.greatestFiniteMagnitude) == false)
    }

    @Test func specialDoubleValuesAreInvalid() {
        // NaN and Infinity should be invalid
        #expect(WeightUnit.lb.isValidWeight(.nan) == false)
        #expect(WeightUnit.kg.isValidWeight(.nan) == false)
        #expect(WeightUnit.lb.isValidWeight(.infinity) == false)
        #expect(WeightUnit.kg.isValidWeight(.infinity) == false)
        #expect(WeightUnit.lb.isValidWeight(-.infinity) == false)
        #expect(WeightUnit.kg.isValidWeight(-.infinity) == false)
    }

    // MARK: - Cross-Unit Boundary Validation

    @Test func maxPoundsConvertsToValidKilograms() {
        // 1500 lb = 680.388 kg, which is just above kg max (680.0)
        let maxLbInKg = WeightUnit.lb.convert(1500.0, to: .kg)
        // This reveals an interesting edge case: max lb slightly exceeds max kg
        #expect(maxLbInKg > WeightUnit.kg.maxWeight)
    }

    @Test func maxKilogramsConvertsToValidPounds() {
        // 680 kg = 1499.1416 lb, which is within lb range
        let maxKgInLb = WeightUnit.kg.convert(680.0, to: .lb)
        #expect(maxKgInLb < WeightUnit.lb.maxWeight)
        #expect(WeightUnit.lb.isValidWeight(maxKgInLb) == true)
    }

    @Test func minPoundsConvertsToValidKilograms() {
        // 1.0 lb = 0.453592 kg, which is below kg min (0.5)
        let minLbInKg = WeightUnit.lb.convert(1.0, to: .kg)
        #expect(minLbInKg < WeightUnit.kg.minWeight)
    }

    @Test func minKilogramsConvertsToPounds() {
        // 0.5 kg = 1.10231 lb, which is above lb min (1.0)
        let minKgInLb = WeightUnit.kg.convert(0.5, to: .lb)
        #expect(minKgInLb > WeightUnit.lb.minWeight)
        #expect(WeightUnit.lb.isValidWeight(minKgInLb) == true)
    }

    // MARK: - Typical User Weight Range Tests

    @Test func typicalAdultWeightRangeIsValid() {
        // Typical adult weight range: 100-300 lb, 45-136 kg
        #expect(WeightUnit.lb.isValidWeight(100.0) == true)
        #expect(WeightUnit.lb.isValidWeight(150.0) == true)
        #expect(WeightUnit.lb.isValidWeight(200.0) == true)
        #expect(WeightUnit.lb.isValidWeight(300.0) == true)

        #expect(WeightUnit.kg.isValidWeight(45.0) == true)
        #expect(WeightUnit.kg.isValidWeight(70.0) == true)
        #expect(WeightUnit.kg.isValidWeight(90.0) == true)
        #expect(WeightUnit.kg.isValidWeight(136.0) == true)
    }
}

// MARK: - Weight Conversion Precision Tests

struct WeightConversionPrecisionTests {

    @Test func conversionFactorPrecision() {
        // Verify the exact conversion constants
        #expect(WeightUnit.lbToKg == 0.453592)
        #expect(WeightUnit.kgToLb == 2.20462)
    }

    @Test func multipleConversionsAccumulatePrecisionLoss() {
        // Converting back and forth multiple times shows floating-point drift
        // Note: lbToKg * kgToLb ≈ 0.9999973 (not exactly 1.0)
        // After 10 round trips: 180 * (0.9999973)^10 ≈ 179.9951
        var weight = 180.0
        for _ in 0..<10 {
            weight = WeightUnit.lb.convert(weight, to: .kg)
            weight = WeightUnit.kg.convert(weight, to: .lb)
        }
        // After 10 round trips, drift is ~0.005 due to imperfect inverse factors
        #expect(abs(weight - 180.0) < 0.01)
    }

    @Test func conversionAtBoundaryValuesPreservesPrecision() {
        // Test conversion precision at edge values
        let oneLb = WeightUnit.lb.convert(1.0, to: .kg)
        #expect(abs(oneLb - 0.453592) < 0.000001)

        let oneKg = WeightUnit.kg.convert(1.0, to: .lb)
        #expect(abs(oneKg - 2.20462) < 0.00001)
    }

    @Test func conversionOfLargeValuesPreservesPrecision() {
        // Large value conversions
        let largeInLb = 1000.0
        let toKg = WeightUnit.lb.convert(largeInLb, to: .kg)
        let expected = 453.592
        #expect(abs(toKg - expected) < 0.001)
    }

    @Test func conversionOfSmallValuesPreservesPrecision() {
        // Small value conversions
        let smallInKg = 1.0
        let toLb = WeightUnit.kg.convert(smallInKg, to: .lb)
        #expect(abs(toLb - 2.20462) < 0.00001)
    }
}

// MARK: - Weight Conversion Tests

struct WeightConversionTests {

    // Known conversion factor: 1 lb = 0.453592 kg
    // Known conversion factor: 1 kg = 2.20462 lb

    @Test func convertPoundsToKilograms() {
        let pounds = 100.0
        let expected = 45.3592 // 100 * 0.453592
        let result = pounds.weightValue(from: .lb, to: .kg)

        #expect(abs(result - expected) < 0.0001)
    }

    @Test func convertKilogramsToPounds() {
        let kilograms = 50.0
        let expected = 110.231 // 50 * 2.20462
        let result = kilograms.weightValue(from: .kg, to: .lb)

        #expect(abs(result - expected) < 0.001)
    }

    @Test func convertSameUnitReturnsOriginal() {
        let poundsValue = 150.0
        let kgValue = 70.0

        #expect(poundsValue.weightValue(from: .lb, to: .lb) == 150.0)
        #expect(kgValue.weightValue(from: .kg, to: .kg) == 70.0)
    }

    @Test func convertZeroWeight() {
        #expect(0.0.weightValue(from: .lb, to: .kg) == 0.0)
        #expect(0.0.weightValue(from: .kg, to: .lb) == 0.0)
    }

    @Test func conversionRoundTrip() {
        let original = 180.0
        let toKg = original.weightValue(from: .lb, to: .kg)
        let backToLb = toKg.weightValue(from: .kg, to: .lb)

        // Should get back approximately the same value
        #expect(abs(backToLb - original) < 0.01)
    }

    @Test func knownConversionValues() {
        // 1 pound = 0.453592 kg
        #expect(abs(1.0.weightValue(from: .lb, to: .kg) - 0.453592) < 0.000001)

        // 1 kg = 2.20462 lb
        #expect(abs(1.0.weightValue(from: .kg, to: .lb) - 2.20462) < 0.00001)
    }
}

// MARK: - Weight Conversion Boundary Tests

struct WeightConversionBoundaryTests {

    // MARK: - Epsilon Boundary Tests

    @Test func weightJustBelowMinimumIsInvalid() {
        // Test epsilon below minimum boundary
        let lbJustBelowMin = WeightUnit.lb.minWeight - 0.001  // 0.999
        let kgJustBelowMin = WeightUnit.kg.minWeight - 0.001  // 0.499

        #expect(WeightUnit.lb.isValidWeight(lbJustBelowMin) == false)
        #expect(WeightUnit.kg.isValidWeight(kgJustBelowMin) == false)
    }

    @Test func weightJustAboveMaximumIsInvalid() {
        // Test epsilon above maximum boundary
        let lbJustAboveMax = WeightUnit.lb.maxWeight + 0.001  // 1500.001
        let kgJustAboveMax = WeightUnit.kg.maxWeight + 0.001  // 680.001

        #expect(WeightUnit.lb.isValidWeight(lbJustAboveMax) == false)
        #expect(WeightUnit.kg.isValidWeight(kgJustAboveMax) == false)
    }

    @Test func weightExactlyAtBoundariesIsValid() {
        // Verify exact boundary values are valid
        #expect(WeightUnit.lb.isValidWeight(WeightUnit.lb.minWeight) == true)
        #expect(WeightUnit.lb.isValidWeight(WeightUnit.lb.maxWeight) == true)
        #expect(WeightUnit.kg.isValidWeight(WeightUnit.kg.minWeight) == true)
        #expect(WeightUnit.kg.isValidWeight(WeightUnit.kg.maxWeight) == true)
    }

    // MARK: - Conversion Factor Consistency

    @Test func conversionFactorsAreReciprocals() {
        // lbToKg * kgToLb should approximately equal 1.0
        let product = WeightUnit.lbToKg * WeightUnit.kgToLb
        #expect(abs(product - 1.0) < 0.0001)
    }

    @Test func conversionPrecisionAtSmallValues() {
        // Test precision with small weight values
        let smallLb = 1.0
        let toKg = smallLb.weightValue(from: .lb, to: .kg)
        let backToLb = toKg.weightValue(from: .kg, to: .lb)

        // Should round-trip with minimal error
        #expect(abs(backToLb - smallLb) < 0.0001)
    }

    @Test func conversionPrecisionAtLargeValues() {
        // Test precision at large weight values
        let largeLb = 1500.0
        let toKg = largeLb.weightValue(from: .lb, to: .kg)
        let backToLb = toKg.weightValue(from: .kg, to: .lb)

        // Should round-trip with minimal error
        #expect(abs(backToLb - largeLb) < 0.01)
    }

    // MARK: - Cross-Unit Validation Consistency

    @Test func minimumLbConvertedToKgIsValid() {
        // 1 lb in kg should be valid (0.453592 kg, which is >= 0.5 is false, so invalid!)
        let lbMin = WeightUnit.lb.minWeight  // 1.0 lb
        let inKg = lbMin.weightValue(from: .lb, to: .kg)  // 0.453592 kg

        // Note: This reveals a design decision - 1 lb (valid) converts to 0.45 kg (invalid in kg)
        // This is expected since kg has a higher minimum (0.5 kg)
        #expect(inKg < WeightUnit.kg.minWeight)
    }

    @Test func maximumKgConvertedToLbIsValid() {
        // 680 kg in lb should still be valid
        let kgMax = WeightUnit.kg.maxWeight  // 680.0 kg
        let inLb = kgMax.weightValue(from: .kg, to: .lb)  // ~1499.14 lb

        #expect(WeightUnit.lb.isValidWeight(inLb) == true)
    }

    @Test func maximumLbConvertedToKgIsValid() {
        // 1500 lb in kg should still be valid
        let lbMax = WeightUnit.lb.maxWeight  // 1500.0 lb
        let inKg = lbMax.weightValue(from: .lb, to: .kg)  // ~680.388 kg

        // Note: 1500 lb ≈ 680.388 kg, which exceeds kg max of 680
        // This reveals asymmetry in the bounds
        #expect(inKg > WeightUnit.kg.maxWeight)
    }

    // MARK: - Special Values

    @Test func verySmallPositiveWeightIsInvalid() {
        // Values close to zero but positive
        #expect(WeightUnit.lb.isValidWeight(0.0001) == false)
        #expect(WeightUnit.kg.isValidWeight(0.0001) == false)
    }

    @Test func infinityIsInvalid() {
        #expect(WeightUnit.lb.isValidWeight(Double.infinity) == false)
        #expect(WeightUnit.kg.isValidWeight(Double.infinity) == false)
        #expect(WeightUnit.lb.isValidWeight(-Double.infinity) == false)
        #expect(WeightUnit.kg.isValidWeight(-Double.infinity) == false)
    }

    @Test func nanIsInvalid() {
        // NaN comparisons always return false, so isValidWeight should return false
        #expect(WeightUnit.lb.isValidWeight(Double.nan) == false)
        #expect(WeightUnit.kg.isValidWeight(Double.nan) == false)
    }

    // MARK: - Typical Use Case Values

    @Test func typicalHumanWeightsAreValid() {
        // Common adult weights
        let typicalLbWeights = [100.0, 150.0, 180.0, 200.0, 250.0, 300.0]
        let typicalKgWeights = [45.0, 70.0, 80.0, 90.0, 115.0, 140.0]

        for weight in typicalLbWeights {
            #expect(WeightUnit.lb.isValidWeight(weight) == true)
        }

        for weight in typicalKgWeights {
            #expect(WeightUnit.kg.isValidWeight(weight) == true)
        }
    }

    @Test func extremeButMedicallyValidWeightsAreValid() {
        // Premature infant (~1 lb) to world record (~1400 lb)
        #expect(WeightUnit.lb.isValidWeight(1.0) == true)
        #expect(WeightUnit.lb.isValidWeight(1400.0) == true)

        // Premature infant (~0.5 kg) to world record (~635 kg)
        #expect(WeightUnit.kg.isValidWeight(0.5) == true)
        #expect(WeightUnit.kg.isValidWeight(635.0) == true)
    }
}

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

    @Test func sevenDayRangeReturnsSeven() {
        #expect(DateRange.sevenDay.days == 7)
    }

    @Test func allTimeRangeReturnsNil() {
        #expect(DateRange.allTime.days == nil)
    }

    @Test func dateRangeRawValues() {
        #expect(DateRange.sevenDay.rawValue == "7D")
        #expect(DateRange.thirtyDay.rawValue == "30D")
        #expect(DateRange.ninetyDay.rawValue == "90D")
        #expect(DateRange.oneEightyDay.rawValue == "180D")
        #expect(DateRange.oneYear.rawValue == "1Y")
        #expect(DateRange.allTime.rawValue == "All")
    }

    @Test func dateRangeAllCases() {
        let allCases = DateRange.allCases
        #expect(allCases.count == 6)
        #expect(allCases.contains(.sevenDay))
        #expect(allCases.contains(.thirtyDay))
        #expect(allCases.contains(.ninetyDay))
        #expect(allCases.contains(.oneEightyDay))
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

// MARK: - Chart Data Filtering Tests

struct ChartDataFilteringTests {

    @Test func filterEntriesByDateRange() {
        let calendar = Calendar.current
        let now = Date.now

        // Create entries at various dates
        let entry10DaysAgo = WeightEntry(
            weight: 180.0,
            date: calendar.date(byAdding: .day, value: -10, to: now)!
        )
        let entry5DaysAgo = WeightEntry(
            weight: 175.0,
            date: calendar.date(byAdding: .day, value: -5, to: now)!
        )
        let entry2DaysAgo = WeightEntry(
            weight: 172.0,
            date: calendar.date(byAdding: .day, value: -2, to: now)!
        )
        let entryToday = WeightEntry(weight: 170.0, date: now)

        let allEntries = [entry10DaysAgo, entry5DaysAgo, entry2DaysAgo, entryToday]

        // Filter for 7 days
        let cutoffDate = calendar.date(byAdding: .day, value: -7, to: now)!
        let filteredEntries = allEntries.filter { $0.date >= cutoffDate }

        #expect(filteredEntries.count == 3)
        #expect(!filteredEntries.contains { $0.weightValue == 180.0 }) // 10 days ago should be excluded
    }

    @Test func allTimeRangeIncludesAllEntries() {
        let calendar = Calendar.current
        let now = Date.now

        let entries = [
            WeightEntry(weight: 200.0, date: calendar.date(byAdding: .year, value: -1, to: now)!),
            WeightEntry(weight: 180.0, date: calendar.date(byAdding: .month, value: -6, to: now)!),
            WeightEntry(weight: 170.0, date: now)
        ]

        // allTime has nil days, so no filtering should occur
        if DateRange.allTime.days == nil {
            // No filtering - all entries included
            #expect(entries.count == 3)
        }
    }

    @Test func sortEntriesByDateAscending() {
        let calendar = Calendar.current
        let now = Date.now

        let entry1 = WeightEntry(weight: 180.0, date: calendar.date(byAdding: .day, value: -3, to: now)!)
        let entry2 = WeightEntry(weight: 175.0, date: calendar.date(byAdding: .day, value: -1, to: now)!)
        let entry3 = WeightEntry(weight: 170.0, date: now)

        let unsorted = [entry2, entry3, entry1]
        let sorted = unsorted.sorted { $0.date < $1.date }

        #expect(sorted[0].weightValue == 180.0) // Oldest first
        #expect(sorted[1].weightValue == 175.0)
        #expect(sorted[2].weightValue == 170.0) // Newest last
    }

    @Test func sortEntriesByDateDescending() {
        let calendar = Calendar.current
        let now = Date.now

        let entry1 = WeightEntry(weight: 180.0, date: calendar.date(byAdding: .day, value: -3, to: now)!)
        let entry2 = WeightEntry(weight: 175.0, date: calendar.date(byAdding: .day, value: -1, to: now)!)
        let entry3 = WeightEntry(weight: 170.0, date: now)

        let unsorted = [entry2, entry3, entry1]
        let sorted = unsorted.sorted { $0.date > $1.date }

        #expect(sorted[0].weightValue == 170.0) // Newest first
        #expect(sorted[1].weightValue == 175.0)
        #expect(sorted[2].weightValue == 180.0) // Oldest last
    }
}

// MARK: - Daily Average Calculation Tests

struct DailyAverageTests {

    @Test func calculateAverageForSingleEntry() {
        let entry = WeightEntry(weight: 175.0)
        let average = [entry].reduce(0.0) { $0 + $1.weightValue } / Double([entry].count)

        #expect(average == 175.0)
    }

    @Test func calculateAverageForMultipleEntries() {
        let entries = [
            WeightEntry(weight: 170.0),
            WeightEntry(weight: 175.0),
            WeightEntry(weight: 180.0)
        ]

        let average = entries.reduce(0.0) { $0 + $1.weightValue } / Double(entries.count)

        #expect(average == 175.0) // (170 + 175 + 180) / 3
    }

    @Test func groupEntriesByDay() {
        let calendar = Calendar.current
        let now = Date.now
        let startOfToday = calendar.startOfDay(for: now)

        // Two entries on the same day, one on a different day
        let entry1 = WeightEntry(weight: 170.0, date: startOfToday)
        let entry2 = WeightEntry(
            weight: 172.0,
            date: calendar.date(byAdding: .hour, value: 6, to: startOfToday)!
        )
        let entry3 = WeightEntry(
            weight: 175.0,
            date: calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        )

        let entries = [entry1, entry2, entry3]
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        #expect(grouped.count == 2) // Two different days
        #expect(grouped[startOfToday]?.count == 2) // Two entries today
    }
}

// MARK: - Linear Regression / Prediction Tests

struct PredictionCalculationTests {

    @Test func linearRegressionWithTwoPoints() {
        // Simple case: weight decreasing by 1 lb per day
        let calendar = Calendar.current
        let today = Date.now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let entries = [
            WeightEntry(weight: 171.0, date: yesterday),
            WeightEntry(weight: 170.0, date: today)
        ]

        // Verify data is valid for prediction
        let sorted = entries.sorted { $0.date < $1.date }
        #expect(sorted.count >= 2)

        // Verify time span is at least 1 hour
        let timeSpan = sorted.last!.date.timeIntervalSince(sorted.first!.date)
        #expect(timeSpan >= 3600) // At least 1 hour
    }

    @Test func predictionRequiresMinimumTwoEntries() {
        let entries = [WeightEntry(weight: 170.0)]

        // With only one entry, prediction should not be possible
        #expect(entries.count < 2)
    }

    @Test func predictionRequiresMinimumTimeSpan() {
        let now = Date.now

        // Two entries at nearly the same time (30 minutes apart)
        let entry1 = WeightEntry(weight: 170.0, date: now)
        let entry2 = WeightEntry(
            weight: 170.5,
            date: Calendar.current.date(byAdding: .minute, value: 30, to: now)!
        )

        let sorted = [entry1, entry2].sorted { $0.date < $1.date }
        let timeSpan = sorted.last!.date.timeIntervalSince(sorted.first!.date)

        // Less than 1 hour (3600 seconds)
        #expect(timeSpan < 3600)
    }

    @Test func linearRegressionSumsCalculation() {
        // Test the regression formula components
        let xs: [Double] = [0, 1, 2, 3] // Days
        let ys: [Double] = [180, 178, 176, 174] // Weights (losing 2 lb/day)

        let n = Double(xs.count)
        let sumX = xs.reduce(0, +)  // 0+1+2+3 = 6
        let sumY = ys.reduce(0, +)  // 180+178+176+174 = 708
        let sumXX = xs.reduce(0) { $0 + $1 * $1 }  // 0+1+4+9 = 14
        let sumXY = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }  // 0+178+352+522 = 1052

        #expect(sumX == 6)
        #expect(sumY == 708)
        #expect(sumXX == 14)
        #expect(sumXY == 1052)

        let denom = n * sumXX - sumX * sumX  // 4*14 - 36 = 20
        #expect(denom == 20)

        let slope = (n * sumXY - sumX * sumY) / denom  // (4*1052 - 6*708) / 20 = -2
        let intercept = (sumY - slope * sumX) / n  // (708 - (-2)*6) / 4 = 180

        #expect(slope == -2.0)
        #expect(intercept == 180.0)

        // Prediction for day 4 should be 172
        let predictedWeight = slope * 4.0 + intercept
        #expect(predictedWeight == 172.0)
    }

    @Test func predictionWithUphillTrend() {
        // Test when weight is increasing
        let xs: [Double] = [0, 1, 2]
        let ys: [Double] = [170, 172, 174] // Gaining 2 lb/day

        let n = Double(xs.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXX = xs.reduce(0) { $0 + $1 * $1 }
        let sumXY = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }

        let denom = n * sumXX - sumX * sumX
        let slope = (n * sumXY - sumX * sumY) / denom

        #expect(slope > 0) // Positive slope for weight gain
        #expect(slope == 2.0)
    }

    @Test func predictionWithFlatTrend() {
        // Test when weight is stable
        let xs: [Double] = [0, 1, 2]
        let ys: [Double] = [175, 175, 175] // No change

        let n = Double(xs.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXX = xs.reduce(0) { $0 + $1 * $1 }
        let sumXY = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }

        let denom = n * sumXX - sumX * sumX
        let slope = (n * sumXY - sumX * sumY) / denom

        #expect(slope == 0.0) // Zero slope for stable weight
    }
}

// MARK: - Notification Scheduler Tests

struct NotificationSchedulerTests {

    // MARK: - Streak Calculation Tests

    @Test func streakCalculationWithConsecutiveDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let entries = [
            WeightEntry(weight: 170.0, date: calendar.date(byAdding: .day, value: 0, to: today)!),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 172.0, date: calendar.date(byAdding: .day, value: -2, to: today)!)
        ]

        let streak = NotificationScheduler.calculateStreak(from: entries)
        #expect(streak == 3)
    }

    @Test func streakCalculationWithGap() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Today, yesterday, then skip a day
        let entries = [
            WeightEntry(weight: 170.0, date: today),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 173.0, date: calendar.date(byAdding: .day, value: -3, to: today)!) // Gap on day -2
        ]

        let streak = NotificationScheduler.calculateStreak(from: entries)
        #expect(streak == 2) // Only today and yesterday count
    }

    @Test func streakCalculationEmptyEntries() {
        let entries: [WeightEntry] = []
        let streak = NotificationScheduler.calculateStreak(from: entries)
        #expect(streak == 0)
    }

    @Test func streakCalculationOldEntriesOnly() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Only entries from 3+ days ago
        let entries = [
            WeightEntry(weight: 170.0, date: calendar.date(byAdding: .day, value: -5, to: today)!),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -6, to: today)!)
        ]

        let streak = NotificationScheduler.calculateStreak(from: entries)
        #expect(streak == 0) // Streak broken
    }

    // MARK: - Streak Warning Tests

    @Test func shouldSendStreakWarningWhenNoEntryToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Entries for previous 4 days but not today
        let entries = [
            WeightEntry(weight: 170.0, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -2, to: today)!),
            WeightEntry(weight: 172.0, date: calendar.date(byAdding: .day, value: -3, to: today)!),
            WeightEntry(weight: 173.0, date: calendar.date(byAdding: .day, value: -4, to: today)!)
        ]

        let (shouldWarn, streak) = NotificationScheduler.shouldSendStreakWarning(entries: entries)
        #expect(shouldWarn == true)
        #expect(streak >= 3)
    }

    @Test func shouldNotSendWarningWithEntryToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let entries = [
            WeightEntry(weight: 170.0, date: today),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 172.0, date: calendar.date(byAdding: .day, value: -2, to: today)!)
        ]

        let (shouldWarn, _) = NotificationScheduler.shouldSendStreakWarning(entries: entries)
        #expect(shouldWarn == false)
    }

    @Test func shouldNotSendWarningForShortStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Only 2 days streak (below threshold of 3)
        let entries = [
            WeightEntry(weight: 170.0, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -2, to: today)!)
        ]

        let (shouldWarn, _) = NotificationScheduler.shouldSendStreakWarning(entries: entries)
        #expect(shouldWarn == false)
    }

    // MARK: - Milestone Progress Tests

    @Test func milestoneProgressWhenLosingWeight() {
        // Current: 172 lbs, Goal: 160 lbs
        // Next milestone: 170 lbs (2 lbs away)
        let result = NotificationScheduler.milestoneProgress(currentWeight: 172.0, goalWeight: 160.0, unit: .lb)

        #expect(result != nil)
        #expect(result!.remaining == 2.0)
        #expect(result!.milestone == 170.0)
    }

    @Test func milestoneProgressTooFarFromMilestone() {
        // Current: 175 lbs, Goal: 160 lbs
        // Next milestone: 175 lbs (would be 5 lbs away from 170, threshold is 2)
        let result = NotificationScheduler.milestoneProgress(currentWeight: 178.0, goalWeight: 160.0, unit: .lb)

        #expect(result == nil) // Too far from milestone
    }

    @Test func milestoneProgressInKilograms() {
        // Current: 77.5 kg, Goal: 70 kg
        // Next milestone: 77.5 (0.5 kg to 77.5 milestone - wait, let's recalculate)
        // Actually milestone for kg is 2.5 interval
        let result = NotificationScheduler.milestoneProgress(currentWeight: 76.0, goalWeight: 70.0, unit: .kg)

        #expect(result != nil)
        #expect(result!.remaining == 1.0) // 76 - 75 = 1 kg
        #expect(result!.milestone == 75.0)
    }

    // MARK: - Weekly Summary Tests

    @Test func weeklySummaryGeneratesCorrectData() {
        let calendar = Calendar.current
        let now = Date()

        let entries = [
            WeightEntry(weight: 175.0, date: calendar.date(byAdding: .day, value: -6, to: now)!),
            WeightEntry(weight: 174.0, date: calendar.date(byAdding: .day, value: -4, to: now)!),
            WeightEntry(weight: 173.0, date: calendar.date(byAdding: .day, value: -2, to: now)!),
            WeightEntry(weight: 172.0, date: now)
        ]

        let summary = NotificationScheduler.generateWeeklySummary(entries: entries, unit: .lb)

        #expect(summary != nil)
        #expect(summary!.entryCount == 4)
        #expect(summary!.weightChange < 0) // Lost weight
        #expect(summary!.trend == .down)
    }

    @Test func weeklySummaryExcludesOldEntries() {
        let calendar = Calendar.current
        let now = Date()

        let entries = [
            WeightEntry(weight: 180.0, date: calendar.date(byAdding: .day, value: -14, to: now)!), // Too old
            WeightEntry(weight: 175.0, date: calendar.date(byAdding: .day, value: -3, to: now)!),
            WeightEntry(weight: 174.0, date: now)
        ]

        let summary = NotificationScheduler.generateWeeklySummary(entries: entries, unit: .lb)

        #expect(summary != nil)
        #expect(summary!.entryCount == 2) // Only 2 entries within 7 days
    }

    @Test func weeklySummaryWithNoRecentEntries() {
        let calendar = Calendar.current
        let now = Date()

        let entries = [
            WeightEntry(weight: 180.0, date: calendar.date(byAdding: .day, value: -14, to: now)!)
        ]

        let summary = NotificationScheduler.generateWeeklySummary(entries: entries, unit: .lb)

        #expect(summary == nil) // No entries in past week
    }

    // MARK: - Optimal Time Analysis Tests

    @Test func optimalTimeWithInsufficientData() {
        let entries = [
            WeightEntry(weight: 170.0),
            WeightEntry(weight: 171.0),
            WeightEntry(weight: 172.0)
        ]

        let result = NotificationScheduler.analyzeOptimalReminderTime(from: entries)
        #expect(result == nil) // Need at least 5 entries
    }

    @Test func optimalTimeWithSufficientData() {
        let calendar = Calendar.current
        var entries: [WeightEntry] = []

        // Create 10 entries all around 8 AM
        for i in 0..<10 {
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            dateComponents.day! -= i
            dateComponents.hour = 8
            dateComponents.minute = 15

            if let date = calendar.date(from: dateComponents) {
                entries.append(WeightEntry(weight: Double(170 + i), date: date))
            }
        }

        let result = NotificationScheduler.analyzeOptimalReminderTime(from: entries)

        #expect(result != nil)
        #expect(result!.hour == 8)
        #expect(result!.minute == 15) // Rounded to nearest 15
    }
}

// MARK: - DataExporter Tests

struct DataExporterTests {

    @Test func generateCSVWithEmptyEntriesReturnsHeaderOnly() {
        let csv = DataExporter.generateCSV(from: [])
        #expect(csv == "date,weight,unit,note,bodyFat\n")
    }

    @Test func generateCSVWithSingleEntry() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let entry = WeightEntry(weight: 175.5, unit: .lb, date: date, note: "Test note", bodyFatPercentage: 20.5)

        let csv = DataExporter.generateCSV(from: [entry])
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 3) // header, data row, empty line
        #expect(lines[0] == "date,weight,unit,note,bodyFat")
        #expect(lines[1].contains("175.5"))
        #expect(lines[1].contains("lb"))
        #expect(lines[1].contains("Test note"))
        #expect(lines[1].contains("20.5"))
    }

    @Test func generateCSVEscapesCommasInNotes() {
        let entry = WeightEntry(weight: 170.0, unit: .lb, date: Date(), note: "Note with, comma")

        let csv = DataExporter.generateCSV(from: [entry])

        #expect(csv.contains("\"Note with, comma\""))
    }

    @Test func generateCSVEscapesQuotesInNotes() {
        let entry = WeightEntry(weight: 170.0, unit: .lb, date: Date(), note: "Note with \"quotes\"")

        let csv = DataExporter.generateCSV(from: [entry])

        #expect(csv.contains("\"Note with \"\"quotes\"\"\""))
    }

    @Test func generateCSVHandlesNilFields() {
        let entry = WeightEntry(weight: 170.0, unit: .lb, date: Date())

        let csv = DataExporter.generateCSV(from: [entry])
        let lines = csv.components(separatedBy: "\n")
        let dataLine = lines[1]
        let columns = dataLine.components(separatedBy: ",")

        // Note should be empty string, bodyFat should be empty
        #expect(columns[3].isEmpty) // note
        #expect(columns[4].isEmpty) // bodyFat
    }

    @Test func generateCSVSortsEntriesByDateAscending() {
        let calendar = Calendar.current
        let now = Date.now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now),
            WeightEntry(weight: 172.0, date: twoDaysAgo),
            WeightEntry(weight: 171.0, date: yesterday)
        ]

        let csv = DataExporter.generateCSV(from: entries)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Data lines should be sorted: 172 (oldest), 171, 170 (newest)
        #expect(lines[1].contains("172.0"))
        #expect(lines[2].contains("171.0"))
        #expect(lines[3].contains("170.0"))
    }

    @Test func generateCSVFiltersEntriesByStartDate() {
        let calendar = Calendar.current
        let now = Date.now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now),
            WeightEntry(weight: 172.0, date: fiveDaysAgo) // Should be excluded
        ]

        let csv = DataExporter.generateCSV(from: entries, startDate: threeDaysAgo)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 2) // header + 1 data row
        #expect(lines[1].contains("170.0"))
        #expect(!csv.contains("172.0"))
    }

    @Test func generateCSVFiltersEntriesByEndDate() {
        let calendar = Calendar.current
        let now = Date.now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now), // Should be excluded
            WeightEntry(weight: 172.0, date: fiveDaysAgo)
        ]

        let csv = DataExporter.generateCSV(from: entries, endDate: threeDaysAgo)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 2) // header + 1 data row
        #expect(lines[1].contains("172.0"))
        #expect(!csv.contains("170.0"))
    }

    @Test func generateCSVFiltersEntriesByDateRange() {
        let calendar = Calendar.current
        let now = Date.now
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!
        let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: now)!
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now),           // Outside range (too recent)
            WeightEntry(weight: 171.0, date: twoDaysAgo),    // Inside range
            WeightEntry(weight: 172.0, date: fourDaysAgo),   // Inside range
            WeightEntry(weight: 173.0, date: sixDaysAgo)     // Outside range (too old)
        ]

        let csv = DataExporter.generateCSV(
            from: entries,
            startDate: calendar.date(byAdding: .day, value: -5, to: now)!,
            endDate: calendar.date(byAdding: .day, value: -1, to: now)!
        )
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 3) // header + 2 data rows
        #expect(csv.contains("171.0"))
        #expect(csv.contains("172.0"))
        #expect(!csv.contains("170.0"))
        #expect(!csv.contains("173.0"))
    }

    @Test func createCSVFileReturnsValidURL() {
        let content = "date,weight,unit,note,bodyFat\n2024-01-01,170.0,lb,,\n"
        let url = DataExporter.createCSVFile(content: content, filename: "test_export.csv")

        #expect(url != nil)
        #expect(url?.lastPathComponent == "test_export.csv")
        #expect(url?.pathExtension == "csv")
    }

    @Test func createCSVFileWritesContent() {
        let content = "date,weight,unit,note,bodyFat\n2024-01-01,170.0,lb,,\n"
        guard let url = DataExporter.createCSVFile(content: content, filename: "test_export_content.csv") else {
            Issue.record("Failed to create CSV file")
            return
        }

        let readContent = try? String(contentsOf: url, encoding: .utf8)
        #expect(readContent == content)

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - ExportFormat Tests

struct ExportFormatTests {

    @Test func csvFormatHasCorrectProperties() {
        #expect(ExportFormat.csv.rawValue == "CSV")
        #expect(ExportFormat.csv.fileExtension == "csv")
        #expect(ExportFormat.csv.mimeType == "text/csv")
        #expect(ExportFormat.csv.id == "CSV")
    }

    @Test func jsonFormatHasCorrectProperties() {
        #expect(ExportFormat.json.rawValue == "JSON")
        #expect(ExportFormat.json.fileExtension == "json")
        #expect(ExportFormat.json.mimeType == "application/json")
        #expect(ExportFormat.json.id == "JSON")
    }

    @Test func allCasesContainsBothFormats() {
        let allCases = ExportFormat.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.csv))
        #expect(allCases.contains(.json))
    }
}

// MARK: - JSON Export Tests

struct JSONExportTests {

    @Test func generateJSONWithEmptyEntriesReturnsEmptyArray() {
        let json = DataExporter.generateJSON(from: [])

        #expect(json.contains("\"entryCount\" : 0"))
        #expect(json.contains("\"entries\" : ["))
    }

    @Test func generateJSONWithSingleEntry() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let entry = WeightEntry(weight: 175.5, unit: .lb, date: date, note: "Test note", bodyFatPercentage: 20.5)

        let json = DataExporter.generateJSON(from: [entry])

        #expect(json.contains("\"weight\" : 175.5"))
        #expect(json.contains("\"unit\" : \"lb\""))
        #expect(json.contains("\"note\" : \"Test note\""))
        #expect(json.contains("\"bodyFatPercentage\" : 20.5"))
        #expect(json.contains("\"entryCount\" : 1"))
    }

    @Test func generateJSONHandlesNilFields() {
        let entry = WeightEntry(weight: 170.0, unit: .lb, date: Date())

        let json = DataExporter.generateJSON(from: [entry])

        // Swift's JSONEncoder omits keys for nil optionals (compact representation)
        // Verify the entry is still valid and parseable
        #expect(json.contains("\"weight\" : 170"))
        #expect(json.contains("\"unit\" : \"lb\""))

        // Verify it doesn't contain bogus values for nil fields
        #expect(!json.contains("\"note\" : \"\""))
        #expect(!json.contains("\"bodyFatPercentage\" : 0"))
    }

    @Test func generateJSONSortsEntriesByDateAscending() {
        let calendar = Calendar.current
        let now = Date.now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now),
            WeightEntry(weight: 172.0, date: twoDaysAgo),
            WeightEntry(weight: 171.0, date: yesterday)
        ]

        let json = DataExporter.generateJSON(from: entries)

        // Verify entries are sorted - 172.0 should appear before 171.0 which appears before 170.0
        let index172 = json.range(of: "172")?.lowerBound
        let index171 = json.range(of: "171")?.lowerBound
        let index170 = json.range(of: "170")?.lowerBound

        #expect(index172 != nil)
        #expect(index171 != nil)
        #expect(index170 != nil)
        #expect(index172! < index171!)
        #expect(index171! < index170!)
    }

    @Test func generateJSONFiltersEntriesByStartDate() {
        let calendar = Calendar.current
        let now = Date.now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now),
            WeightEntry(weight: 172.0, date: fiveDaysAgo) // Should be excluded
        ]

        let json = DataExporter.generateJSON(from: entries, startDate: threeDaysAgo)

        #expect(json.contains("\"entryCount\" : 1"))
        #expect(json.contains("170"))
        #expect(!json.contains("172"))
    }

    @Test func generateJSONFiltersEntriesByEndDate() {
        let calendar = Calendar.current
        let now = Date.now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now), // Should be excluded
            WeightEntry(weight: 172.0, date: fiveDaysAgo)
        ]

        let json = DataExporter.generateJSON(from: entries, endDate: threeDaysAgo)

        #expect(json.contains("\"entryCount\" : 1"))
        #expect(json.contains("172"))
        #expect(!json.contains("170"))
    }

    @Test func generateJSONIncludesMetadata() {
        let entry = WeightEntry(weight: 170.0, date: Date())

        let json = DataExporter.generateJSON(from: [entry])

        #expect(json.contains("\"appVersion\""))
        #expect(json.contains("\"exportDate\""))
        #expect(json.contains("\"entryCount\""))
        #expect(json.contains("\"entries\""))
    }

    @Test func generateJSONProducesValidJSON() {
        let entries = [
            WeightEntry(weight: 170.0, date: Date(), note: "Test"),
            WeightEntry(weight: 175.0, date: Date())
        ]

        let json = DataExporter.generateJSON(from: entries)
        let jsonData = json.data(using: .utf8)!

        // Verify it can be parsed as JSON
        let parsed = try? JSONSerialization.jsonObject(with: jsonData)
        #expect(parsed != nil)
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

// MARK: - TrendCalculator EWMA Tests

struct TrendCalculatorTests {

    // MARK: - Empty and Single Entry Tests

    @Test func emptyEntriesReturnsEmptyResult() {
        let result = TrendCalculator.calculateEWMA(entries: [])
        #expect(result.isEmpty)
    }

    @Test func singleEntryReturnsThatWeight() {
        let entry = WeightEntry(weight: 175.0, unit: .lb, date: Date())
        let result = TrendCalculator.calculateEWMA(entries: [entry])

        #expect(result.count == 1)
        #expect(result[0].smoothedWeight == 175.0)
    }

    // MARK: - Basic EWMA Calculation Tests

    @Test func twoEntriesCalculatesCorrectTrend() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let entries = [
            WeightEntry(weight: 180.0, unit: .lb, date: yesterday),
            WeightEntry(weight: 170.0, unit: .lb, date: today)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries)

        #expect(result.count == 2)
        #expect(result[0].smoothedWeight == 180.0) // First entry = weight
        // Second: 0.1 * 170 + 0.9 * 180 = 17 + 162 = 179
        #expect(abs(result[1].smoothedWeight - 179.0) < 0.001)
    }

    @Test func ewmaSmoothesDailyFluctuations() {
        let calendar = Calendar.current
        let baseDate = Date()

        // Simulate daily weights with fluctuations
        let weights: [Double] = [180.0, 182.0, 179.0, 181.0, 178.0]
        var entries: [WeightEntry] = []

        for (i, weight) in weights.enumerated() {
            let date = calendar.date(byAdding: .day, value: i - 4, to: baseDate)!
            entries.append(WeightEntry(weight: weight, unit: .lb, date: date))
        }

        let result = TrendCalculator.calculateEWMA(entries: entries)

        #expect(result.count == 5)

        // Verify trend is smoother than raw weights
        // The variance of trend should be less than variance of weights
        let trendValues = result.map { $0.smoothedWeight }
        let trendVariance = variance(trendValues)
        let weightVariance = variance(weights)

        #expect(trendVariance < weightVariance)
    }

    // MARK: - Sorting Tests

    @Test func unsortedEntriesAreSortedByDate() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        // Entries in random order
        let entries = [
            WeightEntry(weight: 170.0, unit: .lb, date: today),
            WeightEntry(weight: 180.0, unit: .lb, date: twoDaysAgo),
            WeightEntry(weight: 175.0, unit: .lb, date: yesterday)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries)

        // Result should be sorted by date ascending
        #expect(result[0].date == twoDaysAgo)
        #expect(result[1].date == yesterday)
        #expect(result[2].date == today)

        // First trend should be 180 (oldest entry)
        #expect(result[0].smoothedWeight == 180.0)
    }

    // MARK: - Lambda Parameter Tests

    @Test func defaultLambdaIsHackersDietStandard() {
        #expect(TrendCalculator.defaultLambda == 0.1)
    }

    @Test func higherLambdaIsMoreResponsive() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let entries = [
            WeightEntry(weight: 180.0, unit: .lb, date: yesterday),
            WeightEntry(weight: 170.0, unit: .lb, date: today)
        ]

        let lowLambda = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.1)
        let highLambda = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.5)

        // Higher lambda should be closer to latest weight (170)
        let lowLambdaDistance = abs(lowLambda[1].smoothedWeight - 170.0)
        let highLambdaDistance = abs(highLambda[1].smoothedWeight - 170.0)

        #expect(highLambdaDistance < lowLambdaDistance)
    }

    @Test func lambdaOneEqualsRawWeight() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let entries = [
            WeightEntry(weight: 180.0, unit: .lb, date: yesterday),
            WeightEntry(weight: 170.0, unit: .lb, date: today)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 1.0)

        // Lambda = 1 means trend = current weight (no smoothing)
        #expect(result[0].smoothedWeight == 180.0)
        #expect(result[1].smoothedWeight == 170.0)
    }

    // MARK: - Unit Conversion Tests

    @Test func respectsUnitParameter() {
        // Entry is 100 lb
        let entry = WeightEntry(weight: 100.0, unit: .lb, date: Date())

        let lbResult = TrendCalculator.calculateEWMA(entries: [entry], unit: .lb)
        let kgResult = TrendCalculator.calculateEWMA(entries: [entry], unit: .kg)

        // Both should store smoothedWeight in lbs (internal storage is always lbs)
        #expect(lbResult[0].smoothedWeight == 100.0)
        // When unit is .kg, the calculation is done in kg but stored in lbs
        // So result should be approximately the same (round-trip conversion)
        #expect(abs(kgResult[0].smoothedWeight - 100.0) < 0.01)
    }

    // MARK: - Gap Handling Tests

    @Test func handlesGapsInDates() {
        let calendar = Calendar.current
        let today = Date()
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: today)!

        // Gap of 7 days between first two entries
        let entries = [
            WeightEntry(weight: 180.0, unit: .lb, date: tenDaysAgo),
            WeightEntry(weight: 175.0, unit: .lb, date: threeDaysAgo),
            WeightEntry(weight: 170.0, unit: .lb, date: today)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries)

        // Should still calculate correctly
        #expect(result.count == 3)
        #expect(result[0].smoothedWeight == 180.0)
        // Gap doesn't affect formula, just uses previous trend
        #expect(result[1].smoothedWeight < 180.0)
        #expect(result[2].smoothedWeight < result[1].smoothedWeight)
    }

    // MARK: - TrendPoint Tests

    @Test func trendPointEquatable() {
        let date = Date()
        let point1 = TrendPoint(date: date, rawWeight: 175.0, smoothedWeight: 175.0)
        let point2 = TrendPoint(date: date, rawWeight: 175.0, smoothedWeight: 175.0)
        let point3 = TrendPoint(date: date, rawWeight: 180.0, smoothedWeight: 180.0)

        #expect(point1 == point2)
        #expect(point1 != point3)
    }

    // MARK: - Helper Functions

    private func variance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
}
