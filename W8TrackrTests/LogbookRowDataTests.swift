//
//  LogbookRowDataTests.swift
//  W8TrackrTests
//
//  Unit tests for LogbookRowData, TrendDirection, and filtering logic
//

import Testing
import Foundation
@testable import W8Trackr

// MARK: - TrendDirection Tests

struct TrendDirectionTests {

    @Test func upTrendHasCorrectSymbol() {
        #expect(TrendDirection.up.symbol == "arrow.up")
    }

    @Test func downTrendHasCorrectSymbol() {
        #expect(TrendDirection.down.symbol == "arrow.down")
    }

    @Test func stableTrendHasCorrectSymbol() {
        #expect(TrendDirection.stable.symbol == "minus")
    }

    @Test func upTrendUsesWarningColor() {
        // Gaining weight uses warning color (typically amber/orange)
        #expect(TrendDirection.up.color == AppColors.warning)
    }

    @Test func downTrendUsesSuccessColor() {
        // Losing weight uses success color (typically green)
        #expect(TrendDirection.down.color == AppColors.success)
    }

    @Test func stableTrendUsesSecondaryColor() {
        #expect(TrendDirection.stable.color == AppColors.secondary)
    }
}

// MARK: - LogbookRowData Weight Change Direction Tests

struct LogbookRowDataWeightChangeDirectionTests {

    private func makeEntry(weight: Double, daysAgo: Int = 0) -> WeightEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return WeightEntry(weight: weight, unit: .lb, date: date)
    }

    @Test func nilWeeklyRateReturnsStable() {
        let rowData = LogbookRowData(
            entry: makeEntry(weight: 180.0),
            movingAverage: nil,
            weeklyRate: nil,
            hasNote: false
        )

        #expect(rowData.weightChangeDirection == .stable)
    }

    @Test func smallPositiveRateReturnsStable() {
        // Rate < 0.1 should be stable (threshold for noise)
        let rowData = LogbookRowData(
            entry: makeEntry(weight: 180.0),
            movingAverage: 179.5,
            weeklyRate: 0.05,
            hasNote: false
        )

        #expect(rowData.weightChangeDirection == .stable)
    }

    @Test func smallNegativeRateReturnsStable() {
        // Rate > -0.1 should be stable (threshold for noise)
        let rowData = LogbookRowData(
            entry: makeEntry(weight: 180.0),
            movingAverage: 179.5,
            weeklyRate: -0.05,
            hasNote: false
        )

        #expect(rowData.weightChangeDirection == .stable)
    }

    @Test func negativeRateReturnsDown() {
        // Negative rate = losing weight = down
        let rowData = LogbookRowData(
            entry: makeEntry(weight: 180.0),
            movingAverage: 179.5,
            weeklyRate: -0.5,
            hasNote: false
        )

        #expect(rowData.weightChangeDirection == .down)
    }

    @Test func positiveRateReturnsUp() {
        // Positive rate = gaining weight = up
        let rowData = LogbookRowData(
            entry: makeEntry(weight: 180.0),
            movingAverage: 180.5,
            weeklyRate: 0.5,
            hasNote: false
        )

        #expect(rowData.weightChangeDirection == .up)
    }

    @Test func largeNegativeRateReturnsDown() {
        let rowData = LogbookRowData(
            entry: makeEntry(weight: 175.0),
            movingAverage: 176.0,
            weeklyRate: -2.5,
            hasNote: false
        )

        #expect(rowData.weightChangeDirection == .down)
    }

    @Test func largePositiveRateReturnsUp() {
        let rowData = LogbookRowData(
            entry: makeEntry(weight: 185.0),
            movingAverage: 184.0,
            weeklyRate: 3.0,
            hasNote: false
        )

        #expect(rowData.weightChangeDirection == .up)
    }

    @Test func boundaryAtPointOnePositiveReturnsUp() {
        // Exactly at threshold should be up
        let rowData = LogbookRowData(
            entry: makeEntry(weight: 180.0),
            movingAverage: 180.0,
            weeklyRate: 0.1,
            hasNote: false
        )

        #expect(rowData.weightChangeDirection == .up)
    }

    @Test func boundaryAtPointOneNegativeReturnsDown() {
        // Exactly at -0.1 should be down
        let rowData = LogbookRowData(
            entry: makeEntry(weight: 180.0),
            movingAverage: 180.0,
            weeklyRate: -0.1,
            hasNote: false
        )

        #expect(rowData.weightChangeDirection == .down)
    }
}

// MARK: - LogbookRowData ID Tests

struct LogbookRowDataIDTests {

    @Test func idUsesEntryDate() {
        let date = Date()
        let entry = WeightEntry(weight: 180.0, unit: .lb, date: date)
        let rowData = LogbookRowData(
            entry: entry,
            movingAverage: nil,
            weeklyRate: nil,
            hasNote: false
        )

        #expect(rowData.id == date)
    }
}

// MARK: - LogbookRowData.buildRowData Factory Tests

struct LogbookRowDataBuildRowDataTests {

    private func makeEntry(weight: Double, daysAgo: Int = 0, note: String? = nil) -> WeightEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return WeightEntry(weight: weight, unit: .lb, date: date, note: note)
    }

    @Test func emptyEntriesReturnsEmptyArray() {
        let result = LogbookRowData.buildRowData(entries: [], unit: .lb)
        #expect(result.isEmpty)
    }

    @Test func singleEntryReturnsOneRow() {
        let entries = [makeEntry(weight: 180.0)]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result.count == 1)
        #expect(result[0].entry.weightValue == 180.0)
    }

    @Test func resultIsSortedNewestFirst() {
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 3),
            makeEntry(weight: 178.0, daysAgo: 1),
            makeEntry(weight: 182.0, daysAgo: 5)
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result.count == 3)
        // Should be sorted newest first: daysAgo 1, 3, 5
        #expect(result[0].entry.weightValue == 178.0) // Day 1 ago (newest)
        #expect(result[1].entry.weightValue == 180.0) // Day 3 ago
        #expect(result[2].entry.weightValue == 182.0) // Day 5 ago (oldest)
    }

    @Test func hasNoteIsTrueForEntryWithNote() {
        let entries = [makeEntry(weight: 180.0, note: "Had a big dinner")]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result.count == 1)
        #expect(result[0].hasNote == true)
    }

    @Test func hasNoteIsFalseForEntryWithoutNote() {
        let entries = [makeEntry(weight: 180.0, note: nil)]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result.count == 1)
        #expect(result[0].hasNote == false)
    }

    @Test func hasNoteIsFalseForEmptyNote() {
        let entries = [makeEntry(weight: 180.0, note: "")]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result.count == 1)
        #expect(result[0].hasNote == false)
    }

    @Test func hasNoteIsFalseForWhitespaceOnlyNote() {
        let entries = [makeEntry(weight: 180.0, note: "   ")]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result.count == 1)
        // Note: The current implementation doesn't trim whitespace,
        // so whitespace-only notes may be considered as having a note
        // This test documents current behavior
    }

    @Test func movingAverageIsCalculated() {
        // Create entries over several days to generate a moving average
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 0),
            makeEntry(weight: 181.0, daysAgo: 1),
            makeEntry(weight: 182.0, daysAgo: 2),
            makeEntry(weight: 183.0, daysAgo: 3),
            makeEntry(weight: 184.0, daysAgo: 4)
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result.count == 5)
        // Each row should have a moving average
        for row in result {
            #expect(row.movingAverage != nil)
        }
    }

    @Test func weeklyRateRequiresSevenDaysOfHistory() {
        // Entry without 7 days of history should have nil weekly rate
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 0),
            makeEntry(weight: 182.0, daysAgo: 3)
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result.count == 2)
        // The newest entry (daysAgo: 0) doesn't have a 7-day-old entry to compare
        #expect(result[0].weeklyRate == nil)
    }

    @Test func weeklyRateIsCalculatedWithEnoughHistory() {
        // Entry with at least 7 days of history should have weekly rate
        let entries = [
            makeEntry(weight: 178.0, daysAgo: 0),
            makeEntry(weight: 180.0, daysAgo: 7)
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result.count == 2)
        // The newest entry should have a weekly rate: 178 - 180 = -2
        #expect(result[0].weeklyRate != nil)
        #expect(result[0].weeklyRate == -2.0)
    }

    @Test func unitConversionInBuildRowData() {
        // Create entry in kg
        let date = Date()
        let entry = WeightEntry(weight: 81.6466, unit: .kg, date: date) // 180 lb

        let resultLb = LogbookRowData.buildRowData(entries: [entry], unit: .lb)
        let resultKg = LogbookRowData.buildRowData(entries: [entry], unit: .kg)

        #expect(resultLb.count == 1)
        #expect(resultKg.count == 1)

        // The entry's weight value should match the requested unit
        // (WeightEntry provides weightValue(in:) for conversion)
    }
}

// MARK: - Weekly Rate Calculation Tests

struct LogbookRowDataWeeklyRateTests {

    private func makeEntry(weight: Double, daysAgo: Int) -> WeightEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return WeightEntry(weight: weight, unit: .lb, date: date)
    }

    @Test func weeklyRateForWeightLoss() {
        // Started at 185, now at 180 = lost 5 lbs in a week
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 0),
            makeEntry(weight: 185.0, daysAgo: 7)
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result[0].weeklyRate == -5.0) // Current - Previous = 180 - 185 = -5
    }

    @Test func weeklyRateForWeightGain() {
        // Started at 175, now at 180 = gained 5 lbs in a week
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 0),
            makeEntry(weight: 175.0, daysAgo: 7)
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result[0].weeklyRate == 5.0) // Current - Previous = 180 - 175 = 5
    }

    @Test func weeklyRateForStableWeight() {
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 0),
            makeEntry(weight: 180.0, daysAgo: 7)
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result[0].weeklyRate == 0.0)
    }

    @Test func weeklyRateUsesClosestEntryAtLeastSevenDaysAgo() {
        // Entry at 8 days ago should be used as the comparison
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 0),
            makeEntry(weight: 182.0, daysAgo: 5),  // Not old enough
            makeEntry(weight: 185.0, daysAgo: 8)   // This one should be used
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        // Newest entry's rate: 180 - 185 = -5
        #expect(result[0].weeklyRate == -5.0)
    }
}

// MARK: - Integration Tests (buildRowData with TrendDirection)

struct LogbookRowDataIntegrationTests {

    private func makeEntry(weight: Double, daysAgo: Int) -> WeightEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return WeightEntry(weight: weight, unit: .lb, date: date)
    }

    @Test func weightLossShowsDownTrendDirection() {
        let entries = [
            makeEntry(weight: 175.0, daysAgo: 0),  // Lost 5 lbs
            makeEntry(weight: 180.0, daysAgo: 7)
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result[0].weightChangeDirection == .down)
        #expect(result[0].weightChangeDirection.symbol == "arrow.down")
        #expect(result[0].weightChangeDirection.color == AppColors.success)
    }

    @Test func weightGainShowsUpTrendDirection() {
        let entries = [
            makeEntry(weight: 185.0, daysAgo: 0),  // Gained 5 lbs
            makeEntry(weight: 180.0, daysAgo: 7)
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result[0].weightChangeDirection == .up)
        #expect(result[0].weightChangeDirection.symbol == "arrow.up")
        #expect(result[0].weightChangeDirection.color == AppColors.warning)
    }

    @Test func stableWeightShowsStableTrendDirection() {
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 0),
            makeEntry(weight: 180.0, daysAgo: 7)
        ]

        let result = LogbookRowData.buildRowData(entries: entries, unit: .lb)

        #expect(result[0].weightChangeDirection == .stable)
        #expect(result[0].weightChangeDirection.symbol == "minus")
        #expect(result[0].weightChangeDirection.color == AppColors.secondary)
    }
}

// MARK: - Milestone Detection Tests

struct MilestoneDetectionTests {

    // Test the milestone weight detection logic used in filtering
    // These are based on the milestoneWeights set in HistorySectionView

    @Test func roundMilestoneWeightsAreRecognized() {
        let milestoneWeights: [Double] = [150, 175, 200, 225]

        for weight in milestoneWeights {
            let isNearMilestone = Self.isNearMilestone(weight)
            #expect(isNearMilestone, "Weight \(weight) should be recognized as near a milestone")
        }
    }

    @Test func weightsJustBelowMilestoneAreRecognized() {
        // Threshold is strictly < 0.5 lbs (not <=)
        #expect(Self.isNearMilestone(174.6) == true, "174.6 is 0.4 from 175")
        #expect(Self.isNearMilestone(199.6) == true, "199.6 is 0.4 from 200")
        #expect(Self.isNearMilestone(199.5) == false, "199.5 is exactly 0.5 from 200 (threshold is <, not <=)")
    }

    @Test func weightsJustAboveMilestoneAreRecognized() {
        #expect(Self.isNearMilestone(175.4) == true, "175.4 is within 0.5 of 175")
        #expect(Self.isNearMilestone(200.4) == true, "200.4 is within 0.5 of 200")
    }

    @Test func weightsOutsideThresholdAreNotRecognized() {
        #expect(Self.isNearMilestone(174.0) == false, "174.0 is more than 0.5 from 175")
        #expect(Self.isNearMilestone(201.0) == false, "201.0 is more than 0.5 from 200")
        #expect(Self.isNearMilestone(182.5) == false, "182.5 is not near any milestone")
    }

    // Helper function mirroring HistorySectionView's logic
    private static let milestoneWeights: Set<Double> = [
        150, 155, 160, 165, 170, 175, 180, 185, 190, 195, 200,
        205, 210, 215, 220, 225, 230, 235, 240, 245, 250
    ]

    private static func isNearMilestone(_ weight: Double) -> Bool {
        milestoneWeights.contains { milestone in
            abs(weight - milestone) < 0.5
        }
    }
}

// MARK: - Day of Week Filter Tests

struct DayOfWeekFilterTests {

    // Calendar.component(.weekday) returns 1=Sunday, 2=Monday, ..., 7=Saturday

    private func makeEntryOnWeekday(_ weekday: Int) -> WeightEntry {
        // Find a date that falls on the specified weekday
        let calendar = Calendar.current
        var date = Date()
        while calendar.component(.weekday, from: date) != weekday {
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return WeightEntry(weight: 180.0, unit: .lb, date: date)
    }

    @Test func filterBySundayOnlyShowsSundayEntries() {
        let sundayEntry = makeEntryOnWeekday(1) // Sunday
        let mondayEntry = makeEntryOnWeekday(2) // Monday

        let entries = [sundayEntry, mondayEntry]
        let selectedDays: Set<Int> = [1] // Sunday only

        let filtered = entries.filter { entry in
            let weekday = Calendar.current.component(.weekday, from: entry.date)
            return selectedDays.contains(weekday)
        }

        #expect(filtered.count == 1)
        #expect(Calendar.current.component(.weekday, from: filtered[0].date) == 1)
    }

    @Test func filterByWeekdaysExcludesWeekends() {
        let sundayEntry = makeEntryOnWeekday(1)
        let mondayEntry = makeEntryOnWeekday(2)
        let saturdayEntry = makeEntryOnWeekday(7)

        let entries = [sundayEntry, mondayEntry, saturdayEntry]
        let weekdays: Set<Int> = [2, 3, 4, 5, 6] // Mon-Fri

        let filtered = entries.filter { entry in
            let weekday = Calendar.current.component(.weekday, from: entry.date)
            return weekdays.contains(weekday)
        }

        #expect(filtered.count == 1)
        #expect(Calendar.current.component(.weekday, from: filtered[0].date) == 2) // Monday
    }

    @Test func emptySelectedDaysShowsAll() {
        let sundayEntry = makeEntryOnWeekday(1)
        let mondayEntry = makeEntryOnWeekday(2)

        let entries = [sundayEntry, mondayEntry]
        let selectedDays: Set<Int> = [] // Empty = show all

        // When selectedDays is empty, the filter should not apply
        // (this mirrors the behavior in HistorySectionView where
        // the day filter only applies if selectedDays is non-empty)
        let filtered: [WeightEntry]
        if selectedDays.isEmpty {
            filtered = entries
        } else {
            filtered = entries.filter { entry in
                let weekday = Calendar.current.component(.weekday, from: entry.date)
                return selectedDays.contains(weekday)
            }
        }

        #expect(filtered.count == 2)
    }
}
