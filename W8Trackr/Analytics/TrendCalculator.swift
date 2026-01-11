//
//  TrendCalculator.swift
//  W8Trackr
//
//  Analytics utilities for weight trend calculation
//

import Foundation

/// A single point in the weight trend timeline, containing both raw and smoothed values.
/// Used for charting and trend analysis.
struct TrendPoint: Identifiable, Equatable {
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

    static func == (lhs: TrendPoint, rhs: TrendPoint) -> Bool {
        lhs.date == rhs.date && lhs.rawWeight == rhs.rawWeight && lhs.smoothedWeight == rhs.smoothedWeight
    }
}

/// Result of Holt's Double Exponential Smoothing calculation
struct HoltResult {
    /// Current smoothed level (best estimate of current value)
    let level: Double
    /// Current smoothed trend (rate of change per day)
    let trend: Double
    /// Date of the last data point used in calculation
    let lastDate: Date

    /// Forecasts the value at a future point
    /// - Parameter daysAhead: Number of days into the future to forecast
    /// - Returns: Predicted value
    func forecast(daysAhead: Int) -> Double {
        level + Double(daysAhead) * trend
    }
}

enum TrendCalculator {

    /// Default smoothing factor from The Hacker's Diet
    /// Lower values = smoother trend (less responsive to daily fluctuations)
    /// Higher values = more responsive to recent changes
    static let defaultLambda: Double = 0.1

    /// Calculates EWMA trend line from weight entries using Hacker's Diet formula
    ///
    /// - Parameters:
    ///   - entries: Array of weight entries (will be sorted by date ascending)
    ///   - lambda: Smoothing factor (0 < lambda <= 1). Default is 0.1 per Hacker's Diet
    ///   - unit: Weight unit to use for calculations
    /// - Returns: Array of TrendPoints with smoothed trend values, sorted by date ascending
    ///
    /// The EWMA formula:
    /// ```
    /// trend[0] = weight[0]
    /// trend[t] = lambda * weight[t] + (1 - lambda) * trend[t-1]
    /// ```
    ///
    /// Edge cases:
    /// - Empty array returns empty array
    /// - Single entry returns that entry's weight as the trend
    /// - Gaps in dates are handled naturally (previous trend carries forward)
    static func calculateEWMA(
        entries: [WeightEntry],
        lambda: Double = defaultLambda,
        unit: WeightUnit = .lb
    ) -> [TrendPoint] {
        guard !entries.isEmpty else { return [] }

        let sorted = entries.sorted { $0.date < $1.date }

        var result: [TrendPoint] = []
        var previousTrend: Double?

        for entry in sorted {
            let weight = entry.weightValue(in: unit)

            let trend: Double
            if let prev = previousTrend {
                trend = lambda * weight + (1 - lambda) * prev
            } else {
                trend = weight
            }

            // Convert to lbs for internal storage
            let rawWeightLbs = entry.weightValue(in: .lb)
            let smoothedWeightLbs = WeightUnit.lb == unit ? trend : unit.convert(trend, to: .lb)
            result.append(TrendPoint(date: entry.date, rawWeight: rawWeightLbs, smoothedWeight: smoothedWeightLbs))
            previousTrend = trend
        }

        return result
    }

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

    /// Calculates Holt's Double Exponential Smoothing for trend-aware predictions
    ///
    /// Holt's method extends simple exponential smoothing by adding a trend component,
    /// making it ideal for weight data that follows upward or downward trends.
    ///
    /// - Parameters:
    ///   - entries: Weight entries (will be sorted by date internally)
    ///   - alpha: Smoothing factor for level (0-1). Higher = more responsive to recent values. Default: 0.3
    ///   - beta: Smoothing factor for trend (0-1). Higher = faster trend adaptation. Default: 0.1
    /// - Returns: HoltResult with level, trend, and forecast capability, or nil if fewer than 2 entries
    static func calculateHolt(
        entries: [WeightEntry],
        alpha: Double = 0.3,
        beta: Double = 0.1
    ) -> HoltResult? {
        // Group by day and calculate daily averages (same preprocessing as EMA)
        let dailyAverages = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        .map { date, dayEntries -> (date: Date, weight: Double) in
            // Convert all entries to lbs for internal storage (matching TrendPoint convention)
            let avgWeight = dayEntries.reduce(0.0) { $0 + $1.weightValue(in: .lb) } / Double(dayEntries.count)
            return (date, avgWeight)
        }
        .sorted { $0.date < $1.date }

        // Holt's method requires at least 2 data points to establish initial trend
        guard dailyAverages.count >= 2 else { return nil }

        // Initialize: L₀ = first value, T₀ = second - first
        var level = dailyAverages[0].weight
        var trend = dailyAverages[1].weight - dailyAverages[0].weight

        // Process remaining data points
        for i in 1..<dailyAverages.count {
            let observation = dailyAverages[i].weight
            let previousLevel = level

            // Update level: L_t = α * y_t + (1 - α) * (L_{t-1} + T_{t-1})
            level = alpha * observation + (1 - alpha) * (previousLevel + trend)

            // Update trend: T_t = β * (L_t - L_{t-1}) + (1 - β) * T_{t-1}
            trend = beta * (level - previousLevel) + (1 - beta) * trend
        }

        return HoltResult(
            level: level,
            trend: trend,
            lastDate: dailyAverages.last!.date
        )
    }

    // MARK: - Goal Prediction

    /// Predicts when user will reach their goal weight based on current trend
    ///
    /// - Parameters:
    ///   - entries: Weight entries to analyze
    ///   - goalWeight: Target weight in the specified unit
    ///   - unit: Weight unit for the prediction
    /// - Returns: GoalPrediction with status and estimated date
    static func predictGoalDate(
        entries: [WeightEntry],
        goalWeight: Double,
        unit: WeightUnit
    ) -> GoalPrediction {
        // Need enough data for trend calculation
        guard entries.count >= 7 else {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: 0,
                status: entries.isEmpty ? .noData : .insufficientData,
                weightToGoal: 0,
                unit: unit
            )
        }

        // Calculate trend using Holt's method
        guard let holt = calculateHolt(entries: entries) else {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: 0,
                status: .insufficientData,
                weightToGoal: 0,
                unit: unit
            )
        }

        let currentWeight = holt.level
        let dailyTrend = holt.trend
        let weeklyVelocity = dailyTrend * 7

        // Convert goal weight to stored unit if needed
        let goalInStoredUnit = goalWeight

        let weightToGoal = abs(currentWeight - goalInStoredUnit)
        let needsToLose = currentWeight > goalInStoredUnit

        // Check if already at goal (within 0.5 units)
        if weightToGoal < 0.5 {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: weeklyVelocity,
                status: .atGoal,
                weightToGoal: weightToGoal,
                unit: unit
            )
        }

        // Check if trending wrong direction
        let isLosingWeight = dailyTrend < 0
        if (needsToLose && !isLosingWeight) || (!needsToLose && isLosingWeight) {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: weeklyVelocity,
                status: .wrongDirection,
                weightToGoal: weightToGoal,
                unit: unit
            )
        }

        // Calculate days to goal
        let daysToGoal = Int(weightToGoal / abs(dailyTrend))

        // If more than 2 years out, mark as too slow
        if daysToGoal > 730 {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: weeklyVelocity,
                status: .tooSlow,
                weightToGoal: weightToGoal,
                unit: unit
            )
        }

        let predictedDate = Calendar.current.date(byAdding: .day, value: daysToGoal, to: Date())!

        return GoalPrediction(
            predictedDate: predictedDate,
            weeklyVelocity: weeklyVelocity,
            status: .onTrack(predictedDate),
            weightToGoal: weightToGoal,
            unit: unit
        )
    }
}
