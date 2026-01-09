//
//  TrendCalculator.swift
//  W8Trackr
//
//  Analytics utilities for weight trend calculation
//

import Foundation

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

enum TrendCalculator {

    /// Calculates exponential moving average for weight entries
    /// - Parameters:
    ///   - entries: Weight entries sorted by date (oldest first)
    ///   - span: Number of periods for smoothing (default: 10 days)
    ///   - convertWeight: Closure to convert weight to display unit
    /// - Returns: Array of smoothed trend points
    static func exponentialMovingAverage(
        entries: [WeightEntry],
        span: Int = 10,
        convertWeight: (Double) -> Double = { $0 }
    ) -> [TrendPoint] {
        guard !entries.isEmpty else { return [] }

        // Sort entries by date (oldest first)
        let sorted = entries.sorted { $0.date < $1.date }

        // Group by day and calculate daily averages first
        let dailyAverages = Dictionary(grouping: sorted) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        .map { date, dayEntries -> (date: Date, weight: Double) in
            let avgWeight = dayEntries.reduce(0.0) { $0 + $1.weightValue } / Double(dayEntries.count)
            return (date, avgWeight)
        }
        .sorted { $0.date < $1.date }

        guard !dailyAverages.isEmpty else { return [] }

        // Smoothing factor: α = 2 / (span + 1)
        let alpha = 2.0 / Double(span + 1)

        var trendPoints: [TrendPoint] = []
        var ema: Double = dailyAverages[0].weight

        for (index, dayData) in dailyAverages.enumerated() {
            if index == 0 {
                // First point: EMA equals the first value
                ema = dayData.weight
            } else {
                // EMA = α × current + (1 - α) × previous_EMA
                ema = alpha * dayData.weight + (1 - alpha) * ema
            }

            trendPoints.append(TrendPoint(
                date: dayData.date,
                weight: convertWeight(ema)
            ))
        }

        return trendPoints
    }
}
