//
//  NotificationManagerExtensions.swift
//  W8Trackr
//
//  Contract for goal notification extensions to NotificationManager
//  Feature: 002-goal-notifications
//

import Foundation
import UserNotifications

extension NotificationManager {

    // MARK: - Goal Progress Notifications

    /// Checks for milestone achievements and schedules appropriate notifications
    /// Called after each weight entry is saved
    /// - Parameters:
    ///   - entry: The weight entry just logged
    ///   - entries: All weight entries (for start weight calculation)
    ///   - goalWeight: User's goal weight
    ///   - unit: User's preferred weight unit
    ///   - achievements: Existing milestone achievements (for duplicate prevention)
    ///   - modelContext: SwiftData context for persisting new achievements
    func checkAndNotifyMilestones(
        entry: WeightEntry,
        entries: [WeightEntry],
        goalWeight: Double,
        unit: WeightUnit,
        achievements: [MilestoneAchievement],
        modelContext: ModelContext
    ) {
        // TODO: Implement
        // 1. Calculate current progress
        // 2. Determine crossed milestones
        // 3. Filter to new milestones only
        // 4. Get highest milestone (avoid spam)
        // 5. Record achievement in SwiftData
        // 6. Schedule notification if enabled
        fatalError("Not implemented")
    }

    /// Schedules a milestone celebration notification
    /// - Parameters:
    ///   - milestone: The milestone achieved
    ///   - weight: Weight at achievement
    ///   - unit: Weight unit for message formatting
    func scheduleMilestoneNotification(
        _ milestone: MilestoneType,
        weight: Double,
        unit: WeightUnit
    ) {
        // TODO: Implement
        // Use UNUserNotificationCenter
        // Notification ID: "milestone_\(milestone.rawValue)"
        // Trigger: immediate (no delay)
        fatalError("Not implemented")
    }

    /// Schedules an "approaching goal" notification
    /// - Parameters:
    ///   - currentWeight: Current weight
    ///   - goalWeight: Goal weight
    ///   - unit: Weight unit for message formatting
    func scheduleApproachingGoalNotification(
        currentWeight: Double,
        goalWeight: Double,
        unit: WeightUnit
    ) {
        // TODO: Implement
        // Notification ID: "approaching_goal"
        // Trigger: immediate
        fatalError("Not implemented")
    }

    // MARK: - Preference Checks

    /// Whether milestone notifications are enabled
    var areMilestoneNotificationsEnabled: Bool {
        // TODO: Implement
        // Check: isReminderEnabled && goalNotificationsEnabled && milestoneNotificationsEnabled
        fatalError("Not implemented")
    }

    /// Whether approaching goal notifications are enabled
    var areApproachingNotificationsEnabled: Bool {
        // TODO: Implement
        // Check: isReminderEnabled && goalNotificationsEnabled && approachingNotificationsEnabled
        fatalError("Not implemented")
    }

    // MARK: - Notification Removal

    /// Removes all goal-related notifications
    func removeGoalNotifications() {
        // TODO: Implement
        // Remove: milestone_*, approaching_goal
        fatalError("Not implemented")
    }
}
