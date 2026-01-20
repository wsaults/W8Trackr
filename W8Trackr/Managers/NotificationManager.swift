//
//  NotificationManager.swift
//  W8Trackr
//
//  Created by Will Saults on 5/8/25.
//

import Foundation
import UserNotifications

/// Manages local notification permissions and scheduling for weight logging reminders.
///
/// This class handles two types of notifications:
/// 1. **Daily reminders** - Fixed-time notifications to prompt weight logging
/// 2. **Smart reminders** - Adaptive notifications including streak warnings,
///    milestone alerts, and weekly summaries
///
/// ## Threading
/// Annotated with `@MainActor` to ensure all property updates are safe for UI binding.
///
/// ## Usage
/// ```swift
/// @State private var notificationManager = NotificationManager()
/// ```
@Observable @MainActor
final class NotificationManager {
    /// Whether the user has granted notification permissions and enabled daily reminders.
    /// Updated asynchronously on init and after permission requests.
    var isReminderEnabled = false

    /// Whether adaptive smart notifications (streaks, milestones, summaries) are enabled.
    /// Persisted to UserDefaults.
    var isSmartRemindersEnabled = false

    /// AI-suggested optimal reminder time based on user's historical logging patterns.
    /// `nil` if insufficient data or smart reminders disabled.
    var suggestedReminderTime: Date?

    private static let reminderTimeKey = "reminderTime"
    private static let smartRemindersKey = "smartRemindersEnabled"

    /// Initializes the manager and checks current notification authorization status.
    ///
    /// Loads persisted smart reminder preference and asynchronously queries
    /// the system for notification permission status.
    init() {
        isSmartRemindersEnabled = UserDefaults.standard.bool(forKey: Self.smartRemindersKey)
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            isReminderEnabled = settings.authorizationStatus == .authorized
        }
    }

    /// Requests notification permission from the system.
    ///
    /// - Returns: `true` if permission was granted, `false` otherwise.
    ///
    /// If the user has previously denied permission, this will not show a prompt;
    /// the method will return `false` and the app should direct the user to Settings.
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            isReminderEnabled = granted
            return granted
        } catch {
            return false
        }
    }

    /// Schedules a daily repeating notification at the specified time.
    ///
    /// - Parameter time: The time of day to send the reminder (date component ignored).
    ///
    /// Replaces any existing daily reminder while preserving smart notifications.
    /// Only schedules if `isReminderEnabled` is `true`.
    func scheduleNotification(at time: Date) {
        let center = UNUserNotificationCenter.current()

        // Remove only the daily reminder, preserve smart notifications
        center.removePendingNotificationRequests(withIdentifiers: [NotificationScheduler.NotificationID.dailyReminder.rawValue])

        if isReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Time to Log Your Weight"
            content.body = "Don't forget to log your weight for today!"
            content.sound = .default

            // Create date components from the selected time
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)

            // Create the trigger for daily notification at specified time
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let request = UNNotificationRequest(identifier: NotificationScheduler.NotificationID.dailyReminder.rawValue,
                                             content: content,
                                             trigger: trigger)

            center.add(request)
        }
    }

    /// Removes all pending notifications and disables reminders.
    ///
    /// Clears both daily reminders and smart notifications.
    func disableNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        isReminderEnabled = false
    }

    /// Persists the user's preferred reminder time to UserDefaults.
    ///
    /// - Parameter time: The time to save (only hour/minute components are used).
    func saveReminderTime(_ time: Date) {
        UserDefaults.standard.set(time, forKey: Self.reminderTimeKey)
    }

    /// Retrieves the persisted reminder time, or current time if none saved.
    ///
    /// - Returns: The saved reminder time, or `Date()` as default.
    static func getReminderTime() -> Date {
        UserDefaults.standard.object(forKey: reminderTimeKey) as? Date ?? Date()
    }

    // MARK: - Smart Reminders

    /// Enables or disables smart reminder notifications.
    ///
    /// - Parameter enabled: Whether smart reminders should be active.
    ///
    /// When disabled, removes all pending smart notifications (streak warnings,
    /// milestones, weekly summaries) but preserves daily reminders.
    func setSmartRemindersEnabled(_ enabled: Bool) {
        isSmartRemindersEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.smartRemindersKey)

        if !enabled {
            NotificationScheduler.removeSmartNotifications()
        }
    }

    /// Updates smart notifications based on current weight data.
    ///
    /// Call this after adding or editing weight entries to refresh:
    /// - Suggested optimal reminder time (based on logging patterns)
    /// - Streak warning (if user hasn't logged recently)
    /// - Milestone notification (if close to a weight milestone)
    /// - Weekly summary (progress recap)
    ///
    /// - Parameters:
    ///   - entries: All weight entries for analysis
    ///   - goalWeight: User's target weight
    ///   - unit: Current weight unit preference
    func updateSmartNotifications(entries: [WeightEntry], goalWeight: Double, unit: WeightUnit) {
        guard isReminderEnabled && isSmartRemindersEnabled else { return }

        // Update suggested reminder time based on logging patterns
        if let optimalTime = NotificationScheduler.analyzeOptimalReminderTime(from: entries) {
            var calendar = Calendar.current
            calendar.timeZone = .current
            if let date = calendar.date(from: optimalTime) {
                suggestedReminderTime = date
            }
        }

        // Schedule streak warning if needed
        let (shouldWarn, streak) = NotificationScheduler.shouldSendStreakWarning(entries: entries)
        if shouldWarn {
            NotificationScheduler.scheduleStreakWarning(streak: streak)
        }

        // Schedule milestone notification if close to a milestone
        if let latestEntry = entries.max(by: { $0.date < $1.date }) {
            let currentWeight = latestEntry.weightValue(in: unit)
            if let (remaining, milestone) = NotificationScheduler.milestoneProgress(
                currentWeight: currentWeight,
                goalWeight: goalWeight,
                unit: unit
            ) {
                NotificationScheduler.scheduleMilestoneNotification(remaining: remaining, milestone: milestone, unit: unit)
            }
        }

        // Schedule weekly summary
        if let summary = NotificationScheduler.generateWeeklySummary(entries: entries, unit: unit) {
            NotificationScheduler.scheduleWeeklySummary(summary: summary)
        }
    }
}
