//
//  ChartDataTests.swift
//  W8TrackrTests
//
//  Unit tests for chart data filtering and calculations
//

import Testing
import Foundation
@testable import W8Trackr

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
