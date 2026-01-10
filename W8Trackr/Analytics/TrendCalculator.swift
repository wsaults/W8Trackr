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

// MARK: - Goal Prediction Result

/// Result of goal date prediction calculation
struct GoalPrediction {
    /// Predicted date to reach goal (nil if unreachable or already at goal)
    let predictedDate: Date?

    /// Current velocity in weight units per week
    let weeklyVelocity: Double

    /// Status of the prediction
    let status: GoalPredictionStatus

    /// Weight remaining to goal (positive = need to lose, negative = need to gain)
    let weightToGoal: Double

    /// The unit used for weight values
    let unit: WeightUnit
}

/// Status of the goal prediction
enum GoalPredictionStatus: Equatable {
    /// Goal already reached or within tolerance
    case atGoal

    /// On track to reach goal, shows predicted date
    case onTrack(Date)

    /// Moving away from goal (gaining when trying to lose, or vice versa)
    case wrongDirection

    /// Velocity too slow (would take more than 2 years)
    case tooSlow

    /// Not enough data to make prediction (need at least 7 days of data)
    case insufficientData

    /// No entries available
    case noData

    /// User-friendly message for this status
    var message: String {
        switch self {
        case .atGoal:
            return "You've reached your goal!"
        case .onTrack(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "On track to reach goal by \(formatter.string(from: date))"
        case .wrongDirection:
            return "Currently moving away from goal"
        case .tooSlow:
            return "At current pace, goal is over 2 years away"
        case .insufficientData:
            return "Keep logging to see goal prediction"
        case .noData:
            return "Start logging to track progress"
        }
    }

    /// SF Symbol name for this status
    var iconName: String {
        switch self {
        case .atGoal:
            return "trophy.fill"
        case .onTrack:
            return "calendar.badge.clock"
        case .wrongDirection:
            return "arrow.up.right"
        case .tooSlow:
            return "tortoise.fill"
        case .insufficientData, .noData:
            return "chart.line.uptrend.xyaxis"
        }
    }

    /// Whether this is a positive/encouraging status
    var isPositive: Bool {
        switch self {
        case .atGoal, .onTrack:
            return true
        default:
            return false
        }
    }
}

// MARK: - TrendCalculator Utilities

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
            let avgWeight = dayEntries.reduce(0.0) { $0 + $1.weightValue } / Double(dayEntries.count)
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

    // MARK: - Goal Date Prediction

    /// Calculates when the user will reach their goal weight based on current trend.
    ///
    /// Uses the smoothed trend velocity (from EWMA) to project the goal date.
    /// Requires at least 7 days of data for a reliable prediction.
    ///
    /// - Parameters:
    ///   - entries: Weight entries to analyze
    ///   - goalWeight: Target weight in the specified unit
    ///   - unit: Weight unit for goal and velocity calculations
    /// - Returns: GoalPrediction with status, predicted date, and velocity
    static func predictGoalDate(
        entries: [WeightEntry],
        goalWeight: Double,
        unit: WeightUnit
    ) -> GoalPrediction {
        guard !entries.isEmpty else {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: 0,
                status: .noData,
                weightToGoal: 0,
                unit: unit
            )
        }

        // Get trend data
        let trendPoints = entries.smoothedTrend()

        guard trendPoints.count >= 2 else {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: 0,
                status: .insufficientData,
                weightToGoal: 0,
                unit: unit
            )
        }

        // Check if we have at least 7 days of data for reliable prediction
        let firstDate = trendPoints.first!.date
        let lastDate = trendPoints.last!.date
        let daySpan = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0

        guard daySpan >= 7 else {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: 0,
                status: .insufficientData,
                weightToGoal: 0,
                unit: unit
            )
        }

        // Calculate current weight and goal in consistent unit
        let currentSmoothedWeight = trendPoints.last!.smoothedWeight(in: unit)
        let weightToGoal = currentSmoothedWeight - goalWeight

        // Goal tolerance: within 0.5 lb or 0.25 kg of goal
        let goalTolerance = unit == .lb ? 0.5 : 0.25

        if abs(weightToGoal) <= goalTolerance {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: 0,
                status: .atGoal,
                weightToGoal: weightToGoal,
                unit: unit
            )
        }

        // Calculate average daily velocity from recent trend points (last 7 available)
        let recentPoints = Array(trendPoints.suffix(min(7, trendPoints.count)))
        let velocities = recentPoints.compactMap { $0.trendRate(in: unit) }

        guard !velocities.isEmpty else {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: 0,
                status: .insufficientData,
                weightToGoal: weightToGoal,
                unit: unit
            )
        }

        // Average daily velocity (positive = gaining, negative = losing)
        let avgDailyVelocity = velocities.reduce(0, +) / Double(velocities.count)
        let weeklyVelocity = avgDailyVelocity * 7

        // Determine if moving in the right direction
        // weightToGoal > 0 means need to lose (current > goal)
        // weightToGoal < 0 means need to gain (current < goal)
        let needToLose = weightToGoal > 0
        let isLosing = avgDailyVelocity < 0

        // Check for wrong direction
        if (needToLose && !isLosing) || (!needToLose && isLosing) {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: weeklyVelocity,
                status: .wrongDirection,
                weightToGoal: weightToGoal,
                unit: unit
            )
        }

        // Calculate days to goal
        // daysToGoal = |weightToGoal| / |dailyVelocity|
        let daysToGoal = abs(weightToGoal) / abs(avgDailyVelocity)

        // Cap at 2 years (730 days)
        let maxDays: Double = 730

        if daysToGoal > maxDays {
            return GoalPrediction(
                predictedDate: nil,
                weeklyVelocity: weeklyVelocity,
                status: .tooSlow,
                weightToGoal: weightToGoal,
                unit: unit
            )
        }

        // Calculate predicted date
        let predictedDate = Calendar.current.date(
            byAdding: .day,
            value: Int(ceil(daysToGoal)),
            to: Date()
        )

        return GoalPrediction(
            predictedDate: predictedDate,
            weeklyVelocity: weeklyVelocity,
            status: .onTrack(predictedDate!),
            weightToGoal: weightToGoal,
            unit: unit
        )
    }
}
