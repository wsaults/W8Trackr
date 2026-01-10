//
//  MilestoneTracker.swift
//  W8Trackr
//
//  Contract for milestone achievement tracking
//  Feature: 002-goal-notifications
//

import Foundation
import SwiftData

/// Manages milestone achievement persistence and querying
/// Uses SwiftData for storage
struct MilestoneTracker {

    // MARK: - Recording Achievements

    /// Records a milestone achievement in SwiftData
    /// - Parameters:
    ///   - milestone: The milestone type achieved
    ///   - weight: Weight at achievement
    ///   - goalWeight: Current goal weight
    ///   - startWeight: Start weight used for calculation
    ///   - progress: Progress percentage at achievement
    ///   - modelContext: SwiftData context
    /// - Returns: The created MilestoneAchievement
    @discardableResult
    static func recordAchievement(
        milestone: MilestoneType,
        weight: Double,
        goalWeight: Double,
        startWeight: Double,
        progress: Double,
        modelContext: ModelContext
    ) -> MilestoneAchievement {
        // TODO: Implement
        // 1. Create MilestoneAchievement
        // 2. Insert into modelContext
        // 3. Return the achievement
        fatalError("Not implemented")
    }

    /// Marks a milestone achievement as notified
    /// - Parameters:
    ///   - achievement: The achievement to update
    ///   - modelContext: SwiftData context
    static func markAsNotified(
        _ achievement: MilestoneAchievement,
        modelContext: ModelContext
    ) {
        // TODO: Implement
        // Set notificationSent = true
        fatalError("Not implemented")
    }

    // MARK: - Querying Achievements

    /// Fetches all achievements for a specific goal weight
    /// - Parameters:
    ///   - goalWeight: The goal weight to query
    ///   - tolerance: Tolerance for goal weight matching (default 0.1)
    ///   - modelContext: SwiftData context
    /// - Returns: Array of achievements for this goal
    static func achievements(
        forGoal goalWeight: Double,
        tolerance: Double = 0.1,
        modelContext: ModelContext
    ) throws -> [MilestoneAchievement] {
        // TODO: Implement
        // Use FetchDescriptor with #Predicate
        fatalError("Not implemented")
    }

    /// Checks if a specific milestone has been achieved for current goal
    /// - Parameters:
    ///   - milestone: Milestone type to check
    ///   - goalWeight: Current goal weight
    ///   - modelContext: SwiftData context
    /// - Returns: true if milestone was previously achieved
    static func hasAchieved(
        _ milestone: MilestoneType,
        forGoal goalWeight: Double,
        modelContext: ModelContext
    ) throws -> Bool {
        // TODO: Implement
        fatalError("Not implemented")
    }

    /// Gets the most recent achievement of any type
    /// - Parameter modelContext: SwiftData context
    /// - Returns: Most recent achievement, or nil if none
    static func mostRecentAchievement(
        modelContext: ModelContext
    ) throws -> MilestoneAchievement? {
        // TODO: Implement
        fatalError("Not implemented")
    }

    // MARK: - Goal Change Handling

    /// Resets achievements when goal changes significantly
    /// Does NOT delete achievements - just allows them to be re-earned
    /// - Parameters:
    ///   - previousGoal: Previous goal weight
    ///   - newGoal: New goal weight
    ///   - modelContext: SwiftData context
    /// - Returns: true if goal changed significantly (>10%)
    static func handleGoalChange(
        previousGoal: Double,
        newGoal: Double,
        modelContext: ModelContext
    ) -> Bool {
        // TODO: Implement
        // Check if change is >10%
        // If so, new achievements will be allowed
        // Old achievements are preserved for history
        fatalError("Not implemented")
    }
}
