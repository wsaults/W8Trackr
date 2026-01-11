//
//  TrendCalculatorTests.swift
//  W8TrackrTests
//
//  Unit tests for TrendCalculator algorithms (EWMA and Holt's method)
//

import Testing
import Foundation
@testable import W8Trackr

// MARK: - EWMA Tests with Hand-Calculated Values

struct EWMAHandCalculatedTests {

    // MARK: - Helper to create entries with specific dates

    private func makeEntry(weight: Double, daysAgo: Int = 0) -> WeightEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return WeightEntry(weight: weight, unit: .lb, date: date)
    }

    @Test func ewmaFirstPointEqualsFirstWeight() {
        // First trend point should equal the first weight
        let entries = [makeEntry(weight: 180.0, daysAgo: 0)]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.1)

        #expect(result.count == 1)
        #expect(result[0].smoothedWeight == 180.0)
    }

    @Test func ewmaWithLambdaPointOne() {
        // Hand-calculated EWMA with lambda = 0.1
        // weights: [180, 182, 179]
        // trend[0] = 180
        // trend[1] = 0.1 * 182 + 0.9 * 180 = 18.2 + 162 = 180.2
        // trend[2] = 0.1 * 179 + 0.9 * 180.2 = 17.9 + 162.18 = 180.08
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 2),
            makeEntry(weight: 182.0, daysAgo: 1),
            makeEntry(weight: 179.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.1)

        #expect(result.count == 3)
        #expect(abs(result[0].smoothedWeight - 180.0) < 0.001)
        #expect(abs(result[1].smoothedWeight - 180.2) < 0.001)
        #expect(abs(result[2].smoothedWeight - 180.08) < 0.001)
    }

    @Test func ewmaWithLambdaPointFive() {
        // Hand-calculated EWMA with lambda = 0.5
        // weights: [180, 182, 179]
        // trend[0] = 180
        // trend[1] = 0.5 * 182 + 0.5 * 180 = 91 + 90 = 181
        // trend[2] = 0.5 * 179 + 0.5 * 181 = 89.5 + 90.5 = 180
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 2),
            makeEntry(weight: 182.0, daysAgo: 1),
            makeEntry(weight: 179.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.5)

        #expect(result.count == 3)
        #expect(abs(result[0].smoothedWeight - 180.0) < 0.001)
        #expect(abs(result[1].smoothedWeight - 181.0) < 0.001)
        #expect(abs(result[2].smoothedWeight - 180.0) < 0.001)
    }

    @Test func ewmaWithLambdaPointThree() {
        // Hand-calculated EWMA with lambda = 0.3
        // weights: [170, 172, 171, 169]
        // trend[0] = 170
        // trend[1] = 0.3 * 172 + 0.7 * 170 = 51.6 + 119 = 170.6
        // trend[2] = 0.3 * 171 + 0.7 * 170.6 = 51.3 + 119.42 = 170.72
        // trend[3] = 0.3 * 169 + 0.7 * 170.72 = 50.7 + 119.504 = 170.204
        let entries = [
            makeEntry(weight: 170.0, daysAgo: 3),
            makeEntry(weight: 172.0, daysAgo: 2),
            makeEntry(weight: 171.0, daysAgo: 1),
            makeEntry(weight: 169.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.3)

        #expect(result.count == 4)
        #expect(abs(result[0].smoothedWeight - 170.0) < 0.001)
        #expect(abs(result[1].smoothedWeight - 170.6) < 0.001)
        #expect(abs(result[2].smoothedWeight - 170.72) < 0.001)
        #expect(abs(result[3].smoothedWeight - 170.204) < 0.001)
    }
}

// MARK: - EWMA Lambda = 1.0 Tests

struct EWMALambdaOneTests {

    private func makeEntry(weight: Double, daysAgo: Int = 0) -> WeightEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return WeightEntry(weight: weight, unit: .lb, date: date)
    }

    @Test func lambdaOneEqualsRawValues() {
        // When lambda = 1.0, smoothed values should equal raw values
        // trend[t] = 1.0 * weight[t] + 0 * prev = weight[t]
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 4),
            makeEntry(weight: 182.0, daysAgo: 3),
            makeEntry(weight: 179.0, daysAgo: 2),
            makeEntry(weight: 185.0, daysAgo: 1),
            makeEntry(weight: 176.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 1.0)

        #expect(result.count == 5)
        for (index, point) in result.enumerated() {
            #expect(point.smoothedWeight == point.rawWeight,
                   "At index \(index): smoothed \(point.smoothedWeight) should equal raw \(point.rawWeight)")
        }
    }

    @Test func lambdaOneWithTwoPoints() {
        let entries = [
            makeEntry(weight: 170.0, daysAgo: 1),
            makeEntry(weight: 175.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 1.0)

        #expect(result.count == 2)
        #expect(result[0].smoothedWeight == 170.0)
        #expect(result[1].smoothedWeight == 175.0)
    }

    @Test func lambdaOneSingleEntry() {
        let entries = [makeEntry(weight: 165.0)]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 1.0)

        #expect(result.count == 1)
        #expect(result[0].smoothedWeight == 165.0)
    }
}

// MARK: - Holt's Method Forecast Accuracy Tests

struct HoltForecastTests {

    private func makeEntry(weight: Double, daysAgo: Int = 0) -> WeightEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return WeightEntry(weight: weight, unit: .lb, date: date)
    }

    @Test func holtForecastWithLinearTrend() {
        // Perfect linear trend: losing 1 lb per day
        // weights: [180, 179, 178, 177, 176]
        // Initial: L₀ = 180, T₀ = 179 - 180 = -1
        // For perfect linear data, forecast should be very accurate
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 4),
            makeEntry(weight: 179.0, daysAgo: 3),
            makeEntry(weight: 178.0, daysAgo: 2),
            makeEntry(weight: 177.0, daysAgo: 1),
            makeEntry(weight: 176.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateHolt(entries: entries, alpha: 0.3, beta: 0.1)

        #expect(result != nil)
        // With linear data, trend should be approximately -1 lb/day
        #expect(abs(result!.trend - (-1.0)) < 0.5)
        // Level should be close to 176 (last value)
        #expect(abs(result!.level - 176.0) < 1.0)
        // Forecast 5 days ahead should be approximately 171 (176 - 5)
        let forecast5 = result!.forecast(daysAhead: 5)
        #expect(abs(forecast5 - 171.0) < 2.0)
    }

    @Test func holtForecastWithGainingTrend() {
        // Perfect linear trend: gaining 2 lb per day
        // weights: [170, 172, 174, 176, 178]
        let entries = [
            makeEntry(weight: 170.0, daysAgo: 4),
            makeEntry(weight: 172.0, daysAgo: 3),
            makeEntry(weight: 174.0, daysAgo: 2),
            makeEntry(weight: 176.0, daysAgo: 1),
            makeEntry(weight: 178.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateHolt(entries: entries, alpha: 0.3, beta: 0.1)

        #expect(result != nil)
        // Trend should be approximately +2 lb/day
        #expect(result!.trend > 0)
        #expect(abs(result!.trend - 2.0) < 1.0)
        // Forecast 3 days ahead should predict continued gain
        let forecast3 = result!.forecast(daysAhead: 3)
        #expect(forecast3 > 178.0)
    }

    @Test func holtHandCalculatedTwoPoints() {
        // Manual calculation with alpha=0.3, beta=0.1
        // weights: [180, 182]
        // L₀ = 180
        // T₀ = 182 - 180 = 2
        // After processing second point (i=1):
        // L₁ = 0.3 * 182 + 0.7 * (180 + 2) = 54.6 + 127.4 = 182
        // T₁ = 0.1 * (182 - 180) + 0.9 * 2 = 0.2 + 1.8 = 2
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 1),
            makeEntry(weight: 182.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateHolt(entries: entries, alpha: 0.3, beta: 0.1)

        #expect(result != nil)
        #expect(abs(result!.level - 182.0) < 0.01)
        #expect(abs(result!.trend - 2.0) < 0.01)
        // Forecast 1 day ahead: 182 + 2 = 184
        #expect(abs(result!.forecast(daysAhead: 1) - 184.0) < 0.01)
    }

    @Test func holtFlatTrend() {
        // Stable weight should have near-zero trend
        let entries = [
            makeEntry(weight: 175.0, daysAgo: 4),
            makeEntry(weight: 175.0, daysAgo: 3),
            makeEntry(weight: 175.0, daysAgo: 2),
            makeEntry(weight: 175.0, daysAgo: 1),
            makeEntry(weight: 175.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateHolt(entries: entries, alpha: 0.3, beta: 0.1)

        #expect(result != nil)
        // Trend should be very close to 0
        #expect(abs(result!.trend) < 0.1)
        // Level should be close to 175
        #expect(abs(result!.level - 175.0) < 0.5)
        // Forecast should stay near 175
        #expect(abs(result!.forecast(daysAhead: 7) - 175.0) < 1.0)
    }

    @Test func holtForecastZeroDaysAhead() {
        // Forecast 0 days ahead should equal the current level
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 1),
            makeEntry(weight: 178.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateHolt(entries: entries)

        #expect(result != nil)
        #expect(result!.forecast(daysAhead: 0) == result!.level)
    }
}

// MARK: - Edge Case Tests

struct TrendCalculatorEdgeCaseTests {

    private func makeEntry(weight: Double, daysAgo: Int = 0) -> WeightEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return WeightEntry(weight: weight, unit: .lb, date: date)
    }

    // MARK: - Empty Array Tests

    @Test func ewmaEmptyArrayReturnsEmpty() {
        let entries: [WeightEntry] = []
        let result = TrendCalculator.calculateEWMA(entries: entries)
        #expect(result.isEmpty)
    }

    @Test func exponentialMovingAverageEmptyReturnsEmpty() {
        let entries: [WeightEntry] = []
        let result = TrendCalculator.exponentialMovingAverage(entries: entries)
        #expect(result.isEmpty)
    }

    @Test func holtEmptyArrayReturnsNil() {
        let entries: [WeightEntry] = []
        let result = TrendCalculator.calculateHolt(entries: entries)
        #expect(result == nil)
    }

    // MARK: - Single Entry Tests

    @Test func ewmaSingleEntryReturnsSameValue() {
        let entries = [makeEntry(weight: 175.0)]
        let result = TrendCalculator.calculateEWMA(entries: entries)

        #expect(result.count == 1)
        #expect(result[0].smoothedWeight == 175.0)
        #expect(result[0].rawWeight == 175.0)
    }

    @Test func holtSingleEntryReturnsNil() {
        // Holt's method requires at least 2 points to establish initial trend
        let entries = [makeEntry(weight: 175.0)]
        let result = TrendCalculator.calculateHolt(entries: entries)
        #expect(result == nil)
    }

    // MARK: - Gap Tests (Non-consecutive Days)

    @Test func ewmaHandlesGapsInDates() {
        // Entries with gaps: day 0, day 5, day 10
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 10),
            makeEntry(weight: 178.0, daysAgo: 5),
            makeEntry(weight: 176.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.1)

        #expect(result.count == 3)
        // First point equals first weight
        #expect(result[0].smoothedWeight == 180.0)
        // Subsequent points follow EWMA formula regardless of gaps
        // trend[1] = 0.1 * 178 + 0.9 * 180 = 17.8 + 162 = 179.8
        #expect(abs(result[1].smoothedWeight - 179.8) < 0.01)
        // trend[2] = 0.1 * 176 + 0.9 * 179.8 = 17.6 + 161.82 = 179.42
        #expect(abs(result[2].smoothedWeight - 179.42) < 0.01)
    }

    @Test func holtHandlesGapsInDates() {
        // Holt should handle gaps - the trend is per-entry, not per-day
        let entries = [
            makeEntry(weight: 180.0, daysAgo: 10),
            makeEntry(weight: 178.0, daysAgo: 5),
            makeEntry(weight: 176.0, daysAgo: 0)
        ]

        let result = TrendCalculator.calculateHolt(entries: entries)

        #expect(result != nil)
        // Should still produce a valid result
        #expect(result!.level > 0)
        // Trend should be negative (weight decreasing)
        #expect(result!.trend < 0)
    }

    // MARK: - Unsorted Input Tests

    @Test func ewmaSortsEntriesByDate() {
        // Provide entries out of order
        let entries = [
            makeEntry(weight: 178.0, daysAgo: 0),  // Most recent first
            makeEntry(weight: 182.0, daysAgo: 2),  // Oldest last
            makeEntry(weight: 180.0, daysAgo: 1)   // Middle
        ]

        let result = TrendCalculator.calculateEWMA(entries: entries, lambda: 0.1)

        #expect(result.count == 3)
        // Should be sorted: 182 (oldest), 180, 178 (newest)
        // First smoothed = first raw = 182
        #expect(result[0].rawWeight == 182.0)
        #expect(result[0].smoothedWeight == 182.0)
        // Second smoothed = 0.1*180 + 0.9*182 = 18 + 163.8 = 181.8
        #expect(abs(result[1].smoothedWeight - 181.8) < 0.01)
    }

    @Test func holtSortsEntriesByDate() {
        // Provide entries out of order
        let entries = [
            makeEntry(weight: 176.0, daysAgo: 0),
            makeEntry(weight: 180.0, daysAgo: 2),
            makeEntry(weight: 178.0, daysAgo: 1)
        ]

        let result = TrendCalculator.calculateHolt(entries: entries)

        #expect(result != nil)
        // Should detect decreasing trend (180 -> 178 -> 176)
        #expect(result!.trend < 0)
    }

    // MARK: - Multiple Entries Same Day Tests

    @Test func exponentialMovingAverageAveragesSameDayEntries() {
        // The exponentialMovingAverage method groups by day first
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let entries = [
            WeightEntry(weight: 180.0, unit: .lb, date: today),
            WeightEntry(weight: 182.0, unit: .lb, date: today), // Same day
            WeightEntry(weight: 175.0, unit: .lb, date: yesterday)
        ]

        let result = TrendCalculator.exponentialMovingAverage(entries: entries, span: 10)

        // Should have 2 days worth of data
        #expect(result.count == 2)
        // Yesterday's entry should be 175
        #expect(result[0].rawWeight == 175.0)
        // Today's average should be (180 + 182) / 2 = 181
        #expect(result[1].rawWeight == 181.0)
    }
}

// MARK: - TrendPoint Tests

struct TrendPointTests {

    @Test func trendPointUnitConversion() {
        let point = TrendPoint(date: Date(), rawWeight: 180.0, smoothedWeight: 178.5, trendRate: -0.5)

        // Convert to kg
        let rawKg = point.rawWeight(in: .kg)
        let smoothedKg = point.smoothedWeight(in: .kg)
        let rateKg = point.trendRate(in: .kg)

        // 180 lb ≈ 81.65 kg
        #expect(abs(rawKg - 81.6466) < 0.01)
        // 178.5 lb ≈ 80.97 kg
        #expect(abs(smoothedKg - 80.9662) < 0.01)
        // -0.5 lb/day ≈ -0.227 kg/day
        #expect(rateKg != nil)
        #expect(abs(rateKg! - (-0.2268)) < 0.01)
    }

    @Test func trendPointNilTrendRate() {
        let point = TrendPoint(date: Date(), rawWeight: 180.0, smoothedWeight: 180.0, trendRate: nil)

        #expect(point.trendRate == nil)
        #expect(point.trendRate(in: .kg) == nil)
        #expect(point.trendRate(in: .lb) == nil)
    }

    @Test func trendPointEquality() {
        let date = Date()
        let point1 = TrendPoint(date: date, rawWeight: 180.0, smoothedWeight: 179.0, trendRate: -0.5)
        let point2 = TrendPoint(date: date, rawWeight: 180.0, smoothedWeight: 179.0, trendRate: -0.3)
        let point3 = TrendPoint(date: date, rawWeight: 180.0, smoothedWeight: 178.0, trendRate: -0.5)

        // Equality ignores trendRate (only compares date, rawWeight, smoothedWeight)
        #expect(point1 == point2)
        #expect(point1 != point3)
    }

    @Test func trendPointIdentifiable() {
        let date = Date()
        let point = TrendPoint(date: date, rawWeight: 180.0, smoothedWeight: 179.0)

        #expect(point.id == date)
    }
}

// MARK: - HoltResult Tests

struct HoltResultTests {

    @Test func forecastCalculation() {
        let result = HoltResult(level: 175.0, trend: -0.5, lastDate: Date())

        #expect(result.forecast(daysAhead: 0) == 175.0)
        #expect(result.forecast(daysAhead: 1) == 174.5)
        #expect(result.forecast(daysAhead: 7) == 171.5)
        #expect(result.forecast(daysAhead: 14) == 168.0)
    }

    @Test func forecastWithPositiveTrend() {
        let result = HoltResult(level: 170.0, trend: 0.3, lastDate: Date())

        #expect(result.forecast(daysAhead: 0) == 170.0)
        #expect(result.forecast(daysAhead: 10) == 173.0)
    }

    @Test func forecastWithZeroTrend() {
        let result = HoltResult(level: 175.0, trend: 0.0, lastDate: Date())

        // Forecast should stay at level regardless of days ahead
        #expect(result.forecast(daysAhead: 0) == 175.0)
        #expect(result.forecast(daysAhead: 30) == 175.0)
        #expect(result.forecast(daysAhead: 365) == 175.0)
    }
}

// MARK: - Unit Handling Tests

struct TrendCalculatorUnitTests {

    @Test func holtNormalizesEntriesWithDifferentUnits() {
        // Bug fix test: calculateHolt should normalize all entries to lbs internally
        // Before fix: used raw weightValue which mixed units incorrectly
        // After fix: uses weightValue(in: .lb) for consistent calculation

        let calendar = Calendar.current
        let baseDate = Date()

        // Create entries with SAME weight in different units:
        // 180 lb = 81.6466 kg
        let entries = [
            WeightEntry(weight: 180.0, unit: .lb, date: calendar.date(byAdding: .day, value: -2, to: baseDate)!),
            WeightEntry(weight: 81.6466, unit: .kg, date: calendar.date(byAdding: .day, value: -1, to: baseDate)!),
            WeightEntry(weight: 180.0, unit: .lb, date: baseDate)
        ]

        let result = TrendCalculator.calculateHolt(entries: entries)

        #expect(result != nil)
        // Since all entries represent the same weight (180 lb), trend should be near zero
        #expect(abs(result!.trend) < 0.1, "Trend should be near zero for constant weight data")
        // Level should be approximately 180 lb
        #expect(abs(result!.level - 180.0) < 0.5, "Level should be approximately 180 lbs")
    }

    @Test func holtWithMixedUnitsProducesCorrectTrend() {
        // Test that a weight loss trend is correctly calculated across unit changes
        let calendar = Calendar.current
        let baseDate = Date()

        // Linear weight loss: 182 lb -> 180 lb -> 178 lb (2 lb per day)
        // But middle entry is in kg: 180 lb = 81.6466 kg
        let entries = [
            WeightEntry(weight: 182.0, unit: .lb, date: calendar.date(byAdding: .day, value: -2, to: baseDate)!),
            WeightEntry(weight: 81.6466, unit: .kg, date: calendar.date(byAdding: .day, value: -1, to: baseDate)!), // 180 lb
            WeightEntry(weight: 178.0, unit: .lb, date: baseDate)
        ]

        let result = TrendCalculator.calculateHolt(entries: entries, alpha: 0.3, beta: 0.1)

        #expect(result != nil)
        // Should detect a negative trend (losing weight)
        #expect(result!.trend < 0, "Should detect weight loss trend")
        // Trend should be approximately -2 lb/day
        #expect(abs(result!.trend - (-2.0)) < 1.0, "Trend should be approximately -2 lbs/day")
        // Level should be close to latest weight (178 lb)
        #expect(abs(result!.level - 178.0) < 2.0, "Level should be close to 178 lbs")
    }

    @Test func holtWithAllKgEntriesWorkCorrectly() {
        // Ensure kg-only entries also work correctly
        let calendar = Calendar.current
        let baseDate = Date()

        // 80 kg, 81 kg, 82 kg (gaining 1 kg per day)
        let entries = [
            WeightEntry(weight: 80.0, unit: .kg, date: calendar.date(byAdding: .day, value: -2, to: baseDate)!),
            WeightEntry(weight: 81.0, unit: .kg, date: calendar.date(byAdding: .day, value: -1, to: baseDate)!),
            WeightEntry(weight: 82.0, unit: .kg, date: baseDate)
        ]

        let result = TrendCalculator.calculateHolt(entries: entries, alpha: 0.3, beta: 0.1)

        #expect(result != nil)
        // Should detect positive trend (gaining weight)
        #expect(result!.trend > 0, "Should detect weight gain trend")
        // 1 kg/day ≈ 2.2 lb/day (internal storage is in lbs)
        #expect(abs(result!.trend - 2.2) < 0.5, "Trend should be approximately 2.2 lbs/day (1 kg/day)")
    }
}

// MARK: - Default Lambda Tests

struct DefaultLambdaTests {

    @Test func defaultLambdaIsHackersDietValue() {
        // The Hacker's Diet recommends lambda = 0.1 for weight smoothing
        #expect(TrendCalculator.defaultLambda == 0.1)
    }

    @Test func ewmaUsesDefaultLambda() {
        let calendar = Calendar.current
        let entry1 = WeightEntry(weight: 180.0, unit: .lb, date: calendar.date(byAdding: .day, value: -1, to: Date())!)
        let entry2 = WeightEntry(weight: 182.0, unit: .lb, date: Date())

        let resultDefault = TrendCalculator.calculateEWMA(entries: [entry1, entry2])
        let resultExplicit = TrendCalculator.calculateEWMA(entries: [entry1, entry2], lambda: 0.1)

        // Both should produce same smoothed values
        #expect(resultDefault.count == resultExplicit.count)
        for i in 0..<resultDefault.count {
            #expect(resultDefault[i].smoothedWeight == resultExplicit[i].smoothedWeight)
        }
    }
}
