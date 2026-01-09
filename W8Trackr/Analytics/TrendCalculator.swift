//
//  TrendCalculator.swift
//  W8Trackr
//
//  Analytics utilities for weight trend calculation
//

import Foundation

/// A single point in the weight trend timeline, containing both raw and smoothed values.
/// Used for charting and trend analysis.
struct TrendPoint: Identifiable {
    /// Unique identifier for SwiftUI, based on the date
    var id: Date { date }

    /// The date of this trend point
    let date: Date

    /// The original weight value as recorded (stored in pounds internally)
    let rawWeight: Double

    /// The smoothed/averaged weight value (stored in pounds internally)
    let smoothedWeight: Double

    /// The rate of weight change (lbs per day), nil if not enough data to calculate
    let trendRate: Double?

    // MARK: - Initialization

    /// Creates a TrendPoint with the given values.
    /// - Parameters:
    ///   - date: The date for this trend point
    ///   - rawWeight: The raw weight value in pounds
    ///   - smoothedWeight: The smoothed weight value in pounds
    ///   - trendRate: Optional rate of change in lbs/day
    init(date: Date, rawWeight: Double, smoothedWeight: Double, trendRate: Double? = nil) {
        self.date = date
        self.rawWeight = rawWeight
        self.smoothedWeight = smoothedWeight
        self.trendRate = trendRate
    }

    // MARK: - Unit Conversion

    /// Returns the raw weight converted to the specified unit
    func rawWeight(in unit: WeightUnit) -> Double {
        WeightUnit.lb.convert(rawWeight, to: unit)
    }

    /// Returns the smoothed weight converted to the specified unit
    func smoothedWeight(in unit: WeightUnit) -> Double {
        WeightUnit.lb.convert(smoothedWeight, to: unit)
    }

    /// Returns the trend rate converted to the specified unit (per day)
    func trendRate(in unit: WeightUnit) -> Double? {
        guard let rate = trendRate else { return nil }
        return WeightUnit.lb.convert(rate, to: unit)
    }
}

// MARK: - WeightEntry Extension for Trend Calculation

extension Array where Element == WeightEntry {

    /// Calculates smoothed weight trend using exponentially weighted moving average (EWMA).
    ///
    /// This method processes weight entries by:
    /// 1. Sorting entries chronologically (oldest first)
    /// 2. Grouping same-day entries and averaging them
    /// 3. Applying EWMA smoothing with the specified lambda factor
    ///
    /// - Parameters:
    ///   - unit: The unit to use for output values (default: .lb). Note: TrendPoint stores
    ///           values in pounds internally; use TrendPoint's conversion methods for display.
    ///   - lambda: Smoothing factor between 0 and 1 (default: 0.1 per Hacker's Diet).
    ///             Lower values = smoother trend (more weight on historical data).
    ///             Higher values = more responsive (more weight on recent data).
    /// - Returns: Array of TrendPoints with raw and smoothed weight values, sorted by date.
    func smoothedTrend(unit: WeightUnit = .lb, lambda: Double = 0.1) -> [TrendPoint] {
        guard !isEmpty else { return [] }

        // Clamp lambda to valid range
        let smoothingFactor = Swift.max(0.0, Swift.min(1.0, lambda))

        // Sort entries chronologically (oldest first for EWMA processing)
        let sorted = self.sorted { $0.date < $1.date }

        // Group by calendar day and compute daily average weight
        let calendar = Calendar.current
        let dailyData = Dictionary(grouping: sorted) { entry in
            calendar.startOfDay(for: entry.date)
        }
        .map { date, dayEntries -> (date: Date, rawWeight: Double) in
            // Convert all to pounds for internal storage consistency
            let avgWeight = dayEntries.reduce(0.0) { sum, entry in
                sum + entry.weightValue(in: .lb)
            } / Double(dayEntries.count)
            return (date, avgWeight)
        }
        .sorted { $0.date < $1.date }

        guard !dailyData.isEmpty else { return [] }

        // Apply EWMA: smoothed[t] = λ × raw[t] + (1-λ) × smoothed[t-1]
        var trendPoints: [TrendPoint] = []
        var smoothed: Double = dailyData[0].rawWeight
        var previousSmoothed: Double?

        for (index, day) in dailyData.enumerated() {
            if index == 0 {
                // Initialize with first day's value
                smoothed = day.rawWeight
            } else {
                previousSmoothed = smoothed
                smoothed = smoothingFactor * day.rawWeight + (1 - smoothingFactor) * smoothed
            }

            // Calculate trend rate (lbs/day) from smoothed values
            var trendRate: Double?
            if let prevSmoothed = previousSmoothed {
                let daysBetween = calendar.dateComponents(
                    [.day],
                    from: dailyData[index - 1].date,
                    to: day.date
                ).day ?? 1
                if daysBetween > 0 {
                    trendRate = (smoothed - prevSmoothed) / Double(daysBetween)
                }
            }

            trendPoints.append(TrendPoint(
                date: day.date,
                rawWeight: day.rawWeight,
                smoothedWeight: smoothed,
                trendRate: trendRate
            ))
        }

        return trendPoints
    }
}

// MARK: - TrendCalculator Utilities

enum TrendCalculator {

    /// Calculates exponential moving average for weight entries
    /// - Parameters:
    ///   - entries: Weight entries sorted by date (oldest first)
    ///   - span: Number of periods for smoothing (default: 10 days)
    /// - Returns: Array of trend points with raw and smoothed values (stored in lbs)
    static func exponentialMovingAverage(
        entries: [WeightEntry],
        span: Int = 10
    ) -> [TrendPoint] {
        guard !entries.isEmpty else { return [] }

        // Sort entries by date (oldest first)
        let sorted = entries.sorted { $0.date < $1.date }

        // Group by day and calculate daily averages first
        let dailyAverages = Dictionary(grouping: sorted) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        .map { date, dayEntries -> (date: Date, rawWeight: Double) in
            // Convert all entries to lbs for internal storage
            let avgWeight = dayEntries.reduce(0.0) { $0 + $1.weightValue(in: .lb) } / Double(dayEntries.count)
            return (date, avgWeight)
        }
        .sorted { $0.date < $1.date }

        guard !dailyAverages.isEmpty else { return [] }

        // Smoothing factor: α = 2 / (span + 1)
        let alpha = 2.0 / Double(span + 1)

        var trendPoints: [TrendPoint] = []
        var ema: Double = dailyAverages[0].rawWeight
        var previousEma: Double?

        for (index, dayData) in dailyAverages.enumerated() {
            if index == 0 {
                // First point: EMA equals the first value
                ema = dayData.rawWeight
            } else {
                // EMA = α × current + (1 - α) × previous_EMA
                previousEma = ema
                ema = alpha * dayData.rawWeight + (1 - alpha) * ema
            }

            // Calculate trend rate (lbs per day) if we have previous data
            var trendRate: Double?
            if index > 0, let prevEma = previousEma {
                let daysBetween = Calendar.current.dateComponents(
                    [.day],
                    from: dailyAverages[index - 1].date,
                    to: dayData.date
                ).day ?? 1
                if daysBetween > 0 {
                    trendRate = (ema - prevEma) / Double(daysBetween)
                }
            }

            trendPoints.append(TrendPoint(
                date: dayData.date,
                rawWeight: dayData.rawWeight,
                smoothedWeight: ema,
                trendRate: trendRate
            ))
        }

        return trendPoints
    }
}
