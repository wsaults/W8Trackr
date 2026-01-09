//
//  NotificationManager.swift
//  W8Trackr
//
//  Created by Will Saults on 5/8/25.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    @Published var isReminderEnabled = false
    @Published var isSmartRemindersEnabled = false
    @Published var suggestedReminderTime: Date?

    private static let reminderTimeKey = "reminderTime"
    private static let smartRemindersKey = "smartRemindersEnabled"

    init() {
        isSmartRemindersEnabled = UserDefaults.standard.bool(forKey: Self.smartRemindersKey)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isReminderEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isReminderEnabled = granted
                completion(granted)
            }
        }
    }

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

    func disableNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        isReminderEnabled = false
    }

    func saveReminderTime(_ time: Date) {
        UserDefaults.standard.set(time, forKey: Self.reminderTimeKey)
    }

    static func getReminderTime() -> Date {
        UserDefaults.standard.object(forKey: reminderTimeKey) as? Date ?? Date()
    }

    // MARK: - Smart Reminders

    func setSmartRemindersEnabled(_ enabled: Bool) {
        isSmartRemindersEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.smartRemindersKey)

        if !enabled {
            NotificationScheduler.removeSmartNotifications()
        }
    }

    /// Updates smart notifications based on current weight entries
    /// Call this after adding/editing entries
    func updateSmartNotifications(entries: [WeightEntry], goalWeight: Double, unit: WeightUnit) {
        guard isReminderEnabled && isSmartRemindersEnabled else { return }

        // Update suggested reminder time based on logging patterns
        if let optimalTime = NotificationScheduler.analyzeOptimalReminderTime(from: entries) {
            var calendar = Calendar.current
            calendar.timeZone = .current
            if let date = calendar.date(from: optimalTime) {
                DispatchQueue.main.async {
                    self.suggestedReminderTime = date
                }
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
