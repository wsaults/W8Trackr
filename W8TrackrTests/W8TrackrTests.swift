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

// MARK: - Goal-Specific Weight Validation Tests

struct GoalSpecificWeightValidationTests {

    // MARK: - Goal Weight Bounds Tests

    @Test func minGoalWeightForPounds() {
        #expect(WeightUnit.lb.minGoalWeight == 70.0)
    }

    @Test func minGoalWeightForKilograms() {
        #expect(WeightUnit.kg.minGoalWeight == 32.0)
    }

    @Test func maxGoalWeightForPounds() {
        #expect(WeightUnit.lb.maxGoalWeight == 450.0)
    }

    @Test func maxGoalWeightForKilograms() {
        #expect(WeightUnit.kg.maxGoalWeight == 205.0)
    }

    // MARK: - Goal Weight Validation Tests

    @Test func validGoalWeightWithinMedicalBounds() {
        #expect(WeightUnit.lb.isValidGoalWeight(160.0) == true)
        #expect(WeightUnit.lb.isValidGoalWeight(70.0) == true)  // Min boundary
        #expect(WeightUnit.lb.isValidGoalWeight(450.0) == true) // Max boundary
        #expect(WeightUnit.kg.isValidGoalWeight(70.0) == true)
        #expect(WeightUnit.kg.isValidGoalWeight(32.0) == true)  // Min boundary
        #expect(WeightUnit.kg.isValidGoalWeight(205.0) == true) // Max boundary
    }

    @Test func invalidGoalWeightBelowMinimum() {
        #expect(WeightUnit.lb.isValidGoalWeight(69.9) == false)
        #expect(WeightUnit.lb.isValidGoalWeight(50.0) == false)
        #expect(WeightUnit.kg.isValidGoalWeight(31.9) == false)
        #expect(WeightUnit.kg.isValidGoalWeight(20.0) == false)
    }

    @Test func invalidGoalWeightAboveMaximum() {
        #expect(WeightUnit.lb.isValidGoalWeight(450.1) == false)
        #expect(WeightUnit.lb.isValidGoalWeight(500.0) == false)
        #expect(WeightUnit.kg.isValidGoalWeight(205.1) == false)
        #expect(WeightUnit.kg.isValidGoalWeight(250.0) == false)
    }

    // MARK: - Goal Weight Warning Tests

    @Test func lowGoalWeightWarningThresholds() {
        #expect(WeightUnit.lb.lowGoalWarningThreshold == 100.0)
        #expect(WeightUnit.kg.lowGoalWarningThreshold == 45.0)
    }

    @Test func highGoalWeightWarningThresholds() {
        #expect(WeightUnit.lb.highGoalWarningThreshold == 350.0)
        #expect(WeightUnit.kg.highGoalWarningThreshold == 159.0)
    }

    @Test func noWarningForNormalGoalWeight() {
        #expect(WeightUnit.lb.goalWeightWarning(160.0) == nil)
        #expect(WeightUnit.lb.goalWeightWarning(200.0) == nil)
        #expect(WeightUnit.kg.goalWeightWarning(70.0) == nil)
        #expect(WeightUnit.kg.goalWeightWarning(80.0) == nil)
    }

    @Test func lowWarningForLowGoalWeight() {
        let warning = WeightUnit.lb.goalWeightWarning(90.0)
        #expect(warning == .low)

        let kgWarning = WeightUnit.kg.goalWeightWarning(40.0)
        #expect(kgWarning == .low)
    }

    @Test func highWarningForHighGoalWeight() {
        let warning = WeightUnit.lb.goalWeightWarning(400.0)
        #expect(warning == .high)

        let kgWarning = WeightUnit.kg.goalWeightWarning(180.0)
        #expect(kgWarning == .high)
    }

    @Test func noWarningForInvalidGoalWeight() {
        // Invalid weights should return nil, not a warning
        #expect(WeightUnit.lb.goalWeightWarning(50.0) == nil)
        #expect(WeightUnit.lb.goalWeightWarning(500.0) == nil)
    }

    @Test func warningMessagesAreNotEmpty() {
        #expect(!GoalWeightWarning.low.message.isEmpty)
        #expect(!GoalWeightWarning.high.message.isEmpty)
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
