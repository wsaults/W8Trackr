//
//  GoalProgressCalculator.swift
//  W8Trackr
//
//  Contract for goal progress calculation service
//  Feature: 002-goal-notifications
//

import Foundation

/// Pure functions for calculating goal progress and milestones
/// All methods are static and side-effect free for easy testing
struct GoalProgressCalculator {

    // MARK: - Progress Calculation

    /// Calculates progress percentage toward goal weight
    /// - Parameters:
    ///   - startWeight: Weight when goal was set
    ///   - currentWeight: Current weight
    ///   - goalWeight: Target weight
    /// - Returns: Progress percentage (0-100+, can exceed 100 if past goal)
    static func calculateProgress(
        startWeight: Double,
        currentWeight: Double,
        goalWeight: Double
    ) -> Double {
        // TODO: Implement
        fatalError("Not implemented")
    }

    /// Determines the start weight for progress calculation
    /// - Parameters:
    ///   - entries: All weight entries sorted by date (ascending)
    ///   - goalSetDate: When the current goal was set (nil if never set)
    /// - Returns: Start weight, or nil if no valid entries exist
    static func determineStartWeight(
        entries: [WeightEntry],
        goalSetDate: Date?
    ) -> Double? {
        // TODO: Implement
        fatalError("Not implemented")
    }

    // MARK: - Milestone Detection

    /// Returns milestones crossed at the given progress percentage
    /// - Parameter progress: Progress percentage (0-100+)
    /// - Returns: Array of crossed milestones (25%, 50%, 75%, 100%)
    static func crossedMilestones(at progress: Double) -> [MilestoneType] {
        // TODO: Implement
        fatalError("Not implemented")
    }

    /// Checks if user is within "approaching goal" threshold
    /// - Parameters:
    ///   - currentWeight: Current weight in user's preferred unit
    ///   - goalWeight: Goal weight in user's preferred unit
    ///   - unit: Weight unit (determines threshold: 5 lb or 2.5 kg)
    /// - Returns: true if within threshold and not yet at goal
    static func isApproachingGoal(
        currentWeight: Double,
        goalWeight: Double,
        unit: WeightUnit
    ) -> Bool {
        // TODO: Implement
        fatalError("Not implemented")
    }

    // MARK: - Milestone Filtering

    /// Filters milestones to only those not yet achieved for current goal
    /// - Parameters:
    ///   - crossed: Milestones crossed based on current progress
    ///   - existingAchievements: Previously recorded achievements
    ///   - currentGoalWeight: Current goal weight (for goal-change detection)
    /// - Returns: Milestones that should trigger notifications
    static func newMilestones(
        crossed: [MilestoneType],
        existingAchievements: [MilestoneAchievement],
        currentGoalWeight: Double
    ) -> [MilestoneType] {
        // TODO: Implement
        fatalError("Not implemented")
    }

    /// Returns the highest milestone from a list (for single-notification rule)
    /// - Parameter milestones: Array of milestones
    /// - Returns: Highest milestone (100 > 75 > 50 > 25 > approaching), or nil if empty
    static func highestMilestone(_ milestones: [MilestoneType]) -> MilestoneType? {
        // TODO: Implement
        fatalError("Not implemented")
    }

    // MARK: - Goal Change Detection

    /// Checks if goal has changed significantly (>10%)
    /// - Parameters:
    ///   - currentGoal: Current goal weight
    ///   - previousGoal: Previous goal weight
    /// - Returns: true if change exceeds 10%
    static func hasGoalChangedSignificantly(
        currentGoal: Double,
        previousGoal: Double
    ) -> Bool {
        // TODO: Implement
        fatalError("Not implemented")
    }
}
