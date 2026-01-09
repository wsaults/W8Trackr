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
