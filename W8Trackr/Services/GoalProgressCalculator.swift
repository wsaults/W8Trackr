//
//  GoalProgressCalculator.swift
//  W8Trackr
//
//  Calculates goal progress and detects milestone achievements
//

import Foundation

/// Calculates progress towards a weight goal and detects milestone achievements.
///
/// This calculator handles:
/// - Overall percentage progress from start weight to goal weight
/// - Detection of milestone thresholds (25%, 50%, 75%, approaching, complete)
/// - Both weight loss and weight gain goals
///
/// Example usage:
/// ```swift
/// let calculator = GoalProgressCalculator()
/// let result = calculator.calculateProgress(
///     currentWeight: 175.0,
///     startWeight: 200.0,
///     goalWeight: 160.0,
///     unit: .lb
/// )
/// print(result.progressPercentage) // 62.5
/// ```
struct GoalProgressCalculator {

    // MARK: - Types

    /// Result of a progress calculation
    struct ProgressResult {
        /// Current weight in the specified unit
        let currentWeight: Double

        /// Starting weight in the specified unit
        let startWeight: Double

        /// Goal weight in the specified unit
        let goalWeight: Double

        /// Progress from 0.0 to 100.0 (can exceed 100 if past goal)
        let progressPercentage: Double

        /// Weight remaining to reach goal (absolute value)
        let weightRemaining: Double

        /// The unit used for all weight values
        let unit: WeightUnit

        /// Whether user is trying to lose weight (goal < start)
        let isLosingWeight: Bool

        /// Any milestones newly crossed at this progress level
        let newlyReachedMilestones: [MilestoneType]
    }

    // MARK: - Configuration

    /// Threshold for "approaching goal" milestone in the user's preferred unit
    /// Default: 5 lbs or approximately 2.5 kg
    let approachingThreshold: Double

    // MARK: - Initialization

    /// Creates a calculator with default thresholds
    init() {
        self.approachingThreshold = 5.0 // lbs
    }

    /// Creates a calculator with custom approaching threshold
    /// - Parameter approachingThreshold: Distance from goal to trigger "approaching" milestone (in lbs)
    init(approachingThreshold: Double) {
        self.approachingThreshold = approachingThreshold
    }

    // MARK: - Progress Calculation

    /// Calculates current progress towards the goal weight
    ///
    /// - Parameters:
    ///   - currentWeight: User's current weight
    ///   - startWeight: Weight when goal was set
    ///   - goalWeight: Target weight
    ///   - unit: Unit for all weight values
    ///   - previousMilestones: Already-achieved milestones to exclude from `newlyReachedMilestones`
    /// - Returns: ProgressResult with calculated values
    func calculateProgress(
        currentWeight: Double,
        startWeight: Double,
        goalWeight: Double,
        unit: WeightUnit,
        previousMilestones: Set<MilestoneType> = []
    ) -> ProgressResult {
        // TODO: Implement progress calculation
        // 1. Determine if losing or gaining weight
        // 2. Calculate percentage progress (handle edge cases like start == goal)
        // 3. Calculate weight remaining
        // 4. Determine which milestones have been reached
        // 5. Filter to only newly reached milestones

        fatalError("Not implemented")
    }

    // MARK: - Milestone Detection

    /// Determines which milestone thresholds have been crossed
    ///
    /// - Parameters:
    ///   - progressPercentage: Current progress from 0-100+
    ///   - weightRemaining: Distance from goal weight
    ///   - unit: Weight unit for threshold conversion
    /// - Returns: All milestones that have been reached at this progress level
    func milestonesReached(
        progressPercentage: Double,
        weightRemaining: Double,
        unit: WeightUnit
    ) -> [MilestoneType] {
        // TODO: Implement milestone detection
        // Check each MilestoneType threshold against current progress
        // Handle "approaching" milestone specially (uses distance, not percentage)

        fatalError("Not implemented")
    }

    // MARK: - Helpers

    /// Converts the approaching threshold to the specified unit
    func approachingThreshold(in unit: WeightUnit) -> Double {
        WeightUnit.lb.convert(approachingThreshold, to: unit)
    }
}
