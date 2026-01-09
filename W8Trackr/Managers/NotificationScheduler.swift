//
//  NotificationScheduler.swift
//  W8Trackr
//
//  Created by Claude on 1/8/26.
//

import Foundation
import UserNotifications
import SwiftData

/// Handles smart notification scheduling based on user behavior patterns
struct NotificationScheduler {

    // MARK: - Notification Identifiers

    enum NotificationID: String {
        case dailyReminder = "weightLogReminder"
        case streakWarning = "streakWarning"
        case milestoneApproaching = "milestoneApproaching"
        case weeklySummary = "weeklySummary"
    }

    // MARK: - Optimal Time Analysis

    /// Analyzes weight entry timestamps to determine the user's preferred logging time
    /// - Parameter entries: Array of weight entries to analyze
    /// - Returns: Optimal hour and minute based on logging patterns, or nil if insufficient data
    static func analyzeOptimalReminderTime(from entries: [WeightEntry]) -> DateComponents? {
        guard entries.count >= 5 else { return nil }

        let calendar = Calendar.current
        let recentEntries = entries
            .sorted { $0.date > $1.date }
            .prefix(30) // Analyze last 30 entries for recency bias

        // Extract hours from each entry
        let hours = recentEntries.map { calendar.component(.hour, from: $0.date) }
        let minutes = recentEntries.map { calendar.component(.minute, from: $0.date) }

        // Calculate weighted average (more recent = higher weight)
        var weightedHourSum = 0.0
        var weightedMinuteSum = 0.0
        var totalWeight = 0.0

        for (index, _) in recentEntries.enumerated() {
            let weight = Double(recentEntries.count - index) // More recent = higher weight
            weightedHourSum += Double(hours[index]) * weight
            weightedMinuteSum += Double(minutes[index]) * weight
            totalWeight += weight
        }

        let avgHour = Int(weightedHourSum / totalWeight)
        let avgMinute = Int(weightedMinuteSum / totalWeight)

        // Round minutes to nearest 15
        let roundedMinute = (avgMinute / 15) * 15

        var components = DateComponents()
        components.hour = avgHour
        components.minute = roundedMinute
        return components
    }

    // MARK: - Streak Calculation

    /// Calculates the current logging streak (consecutive days with entries)
    /// - Parameter entries: Array of weight entries
    /// - Returns: Number of consecutive days with at least one entry
    static func calculateStreak(from entries: [WeightEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique days with entries, sorted descending
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >)

        // Check if there's an entry today or yesterday (to count streak)
        guard let mostRecentDay = uniqueDays.first else { return 0 }

        let daysSinceMostRecent = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0

        // If most recent entry is more than 1 day ago, streak is broken
        if daysSinceMostRecent > 1 {
            return 0
        }

        // Count consecutive days backwards
        var streak = 0
        var expectedDate = daysSinceMostRecent == 0 ? today : calendar.date(byAdding: .day, value: -1, to: today)!

        for day in uniqueDays {
            if calendar.isDate(day, inSameDayAs: expectedDate) {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if day < expectedDate {
                break // Gap in streak
            }
        }

        return streak
    }

    /// Checks if streak warning should be sent (no entry today and streak > 0)
    static func shouldSendStreakWarning(entries: [WeightEntry]) -> (shouldSend: Bool, streak: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let hasEntryToday = entries.contains { calendar.isDate($0.date, inSameDayAs: today) }
        let streak = calculateStreak(from: entries)

        // Send warning if no entry today and streak is at least 3 days
        return (!hasEntryToday && streak >= 3, streak)
    }

    // MARK: - Milestone Detection

    /// Calculates progress toward the next 5-lb milestone
    /// - Parameters:
    ///   - currentWeight: Current weight in user's preferred unit
    ///   - goalWeight: Target weight in user's preferred unit
    ///   - unit: Weight unit for formatting
    /// - Returns: Tuple with pounds/kg remaining to next milestone, or nil if at/past goal
    static func milestoneProgress(currentWeight: Double, goalWeight: Double, unit: WeightUnit) -> (remaining: Double, milestone: Double)? {
        let isLosingWeight = currentWeight > goalWeight

        // Calculate next 5-unit milestone in the direction of goal
        let milestoneInterval: Double = unit == .lb ? 5.0 : 2.5

        let nextMilestone: Double
        if isLosingWeight {
            nextMilestone = floor(currentWeight / milestoneInterval) * milestoneInterval
            if nextMilestone >= currentWeight {
                return nil // Already at or past this milestone
            }
        } else {
            nextMilestone = ceil(currentWeight / milestoneInterval) * milestoneInterval
            if nextMilestone <= currentWeight {
                return nil
            }
        }

        let remaining = abs(currentWeight - nextMilestone)

        // Only notify if within 2 units of milestone
        let threshold: Double = unit == .lb ? 2.0 : 1.0
        if remaining <= threshold {
            return (remaining, nextMilestone)
        }

        return nil
    }

    // MARK: - Weekly Summary

    /// Generates weekly summary data
    /// - Parameter entries: Weight entries from the past week
    /// - Returns: Summary with entry count, weight change, and trend
    static func generateWeeklySummary(entries: [WeightEntry], unit: WeightUnit) -> WeeklySummary? {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let weekEntries = entries.filter { $0.date >= oneWeekAgo }
        guard !weekEntries.isEmpty else { return nil }

        let sortedEntries = weekEntries.sorted { $0.date < $1.date }

        guard let firstWeight = sortedEntries.first?.weightValue(in: unit),
              let lastWeight = sortedEntries.last?.weightValue(in: unit) else {
            return nil
        }

        let weightChange = lastWeight - firstWeight
        let entryCount = weekEntries.count

        return WeeklySummary(
            entryCount: entryCount,
            weightChange: weightChange,
            unit: unit,
            trend: weightChange < 0 ? .down : (weightChange > 0 ? .up : .stable)
        )
    }

    struct WeeklySummary {
        let entryCount: Int
        let weightChange: Double
        let unit: WeightUnit
        let trend: Trend

        enum Trend {
            case up, down, stable
        }

        var message: String {
            let changeStr = String(format: "%.1f", abs(weightChange))
            let direction = trend == .down ? "lost" : (trend == .up ? "gained" : "maintained")

            if trend == .stable {
                return "Weekly summary: \(entryCount) entries logged. Weight stable."
            }
            return "Weekly summary: \(entryCount) entries logged. You \(direction) \(changeStr) \(unit.rawValue) this week!"
        }
    }

    // MARK: - Notification Scheduling

    /// Schedules streak warning notification for evening if no entry logged today
    static func scheduleStreakWarning(streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak!"
        content.body = "You have a \(streak)-day logging streak. Log your weight to keep it going!"
        content.sound = .default

        // Schedule for 8 PM today
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.streakWarning.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Schedules milestone approaching notification
    static func scheduleMilestoneNotification(remaining: Double, milestone: Double, unit: WeightUnit) {
        let content = UNMutableNotificationContent()
        content.title = "Almost there!"
        content.body = String(format: "Just %.1f %@ to your next milestone of %.0f %@!", remaining, unit.rawValue, milestone, unit.rawValue)
        content.sound = .default

        // Schedule for 9 AM tomorrow
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.milestoneApproaching.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Schedules weekly summary notification for Sunday evening
    static func scheduleWeeklySummary(summary: WeeklySummary) {
        let content = UNMutableNotificationContent()
        content.title = "Your Week in Review"
        content.body = summary.message
        content.sound = .default

        // Schedule for Sunday at 7 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 19
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.weeklySummary.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Removes all smart notifications (keeps daily reminder)
    static func removeSmartNotifications() {
        let identifiers = [
            NotificationID.streakWarning.rawValue,
            NotificationID.milestoneApproaching.rawValue,
            NotificationID.weeklySummary.rawValue
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
