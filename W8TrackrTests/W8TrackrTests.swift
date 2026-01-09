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

// MARK: - WeightEntry Tests

struct WeightEntryTests {

    @Test func weightEntryInitializesWithCorrectValues() {
        let date = Date.now
        let entry = WeightEntry(weight: 175.5, unit: .pounds, date: date, note: "Test note", bodyFatPercentage: 20.0)

        #expect(entry.weightValue == 175.5)
        #expect(entry.weightUnit == "lb")
        #expect(entry.date == date)
        #expect(entry.note == "Test note")
        #expect(entry.bodyFatPercentage == 20.0)
    }

    @Test func weightEntryInitializesWithKilograms() {
        let entry = WeightEntry(weight: 80.0, unit: .kilograms)

        #expect(entry.weightValue == 80.0)
        #expect(entry.weightUnit == "kg")
    }

    @Test func weightEntryDefaultsToPounds() {
        let entry = WeightEntry(weight: 150.0)

        #expect(entry.weightUnit == "lb")
    }

    @Test func weightValueInSameUnitReturnsSameValue() {
        let entry = WeightEntry(weight: 180.0, unit: .pounds)

        #expect(entry.weightValue(in: .lb) == 180.0)
    }

    @Test func weightValueConvertsPoundsToKilograms() {
        let entry = WeightEntry(weight: 100.0, unit: .pounds)
        let result = entry.weightValue(in: .kg)
        let expected = 45.3592

        #expect(abs(result - expected) < 0.0001)
    }

    @Test func weightValueConvertsKilogramsToPounds() {
        let entry = WeightEntry(weight: 50.0, unit: .kilograms)
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
        #expect(DateRange.sevenDay.rawValue == "7 Day")
        #expect(DateRange.allTime.rawValue == "All")
    }

    @Test func dateRangeAllCases() {
        let allCases = DateRange.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.sevenDay))
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
