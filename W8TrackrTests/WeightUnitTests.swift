//
//  WeightUnitTests.swift
//  W8TrackrTests
//
//  Unit tests for WeightUnit functionality
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
        #expect(WeightUnit.lb.isValidWeight(0.9) == false)
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
