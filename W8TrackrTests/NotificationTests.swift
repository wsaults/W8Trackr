//
//  NotificationTests.swift
//  W8TrackrTests
//
//  Unit tests for NotificationScheduler functionality
//

import Testing
import Foundation
@testable import W8Trackr

// MARK: - Notification Scheduler Tests

struct NotificationSchedulerTests {

    // MARK: - Streak Calculation Tests

    @Test func streakCalculationWithConsecutiveDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let entries = [
            WeightEntry(weight: 170.0, date: calendar.date(byAdding: .day, value: 0, to: today)!),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 172.0, date: calendar.date(byAdding: .day, value: -2, to: today)!)
        ]

        let streak = NotificationScheduler.calculateStreak(from: entries)
        #expect(streak == 3)
    }

    @Test func streakCalculationWithGap() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Today, yesterday, then skip a day
        let entries = [
            WeightEntry(weight: 170.0, date: today),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 173.0, date: calendar.date(byAdding: .day, value: -3, to: today)!) // Gap on day -2
        ]

        let streak = NotificationScheduler.calculateStreak(from: entries)
        #expect(streak == 2) // Only today and yesterday count
    }

    @Test func streakCalculationEmptyEntries() {
        let entries: [WeightEntry] = []
        let streak = NotificationScheduler.calculateStreak(from: entries)
        #expect(streak == 0)
    }

    @Test func streakCalculationOldEntriesOnly() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Only entries from 3+ days ago
        let entries = [
            WeightEntry(weight: 170.0, date: calendar.date(byAdding: .day, value: -5, to: today)!),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -6, to: today)!)
        ]

        let streak = NotificationScheduler.calculateStreak(from: entries)
        #expect(streak == 0) // Streak broken
    }

    // MARK: - Streak Warning Tests

    @Test func shouldSendStreakWarningWhenNoEntryToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Entries for previous 4 days but not today
        let entries = [
            WeightEntry(weight: 170.0, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -2, to: today)!),
            WeightEntry(weight: 172.0, date: calendar.date(byAdding: .day, value: -3, to: today)!),
            WeightEntry(weight: 173.0, date: calendar.date(byAdding: .day, value: -4, to: today)!)
        ]

        let (shouldWarn, streak) = NotificationScheduler.shouldSendStreakWarning(entries: entries)
        #expect(shouldWarn == true)
        #expect(streak >= 3)
    }

    @Test func shouldNotSendWarningWithEntryToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let entries = [
            WeightEntry(weight: 170.0, date: today),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 172.0, date: calendar.date(byAdding: .day, value: -2, to: today)!)
        ]

        let (shouldWarn, _) = NotificationScheduler.shouldSendStreakWarning(entries: entries)
        #expect(shouldWarn == false)
    }

    @Test func shouldNotSendWarningForShortStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Only 2 days streak (below threshold of 3)
        let entries = [
            WeightEntry(weight: 170.0, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 171.0, date: calendar.date(byAdding: .day, value: -2, to: today)!)
        ]

        let (shouldWarn, _) = NotificationScheduler.shouldSendStreakWarning(entries: entries)
        #expect(shouldWarn == false)
    }

    // MARK: - Milestone Progress Tests

    @Test func milestoneProgressWhenLosingWeight() {
        // Current: 172 lbs, Goal: 160 lbs
        // Next milestone: 170 lbs (2 lbs away)
        let result = NotificationScheduler.milestoneProgress(currentWeight: 172.0, goalWeight: 160.0, unit: .lb)

        #expect(result != nil)
        #expect(result!.remaining == 2.0)
        #expect(result!.milestone == 170.0)
    }

    @Test func milestoneProgressTooFarFromMilestone() {
        // Current: 175 lbs, Goal: 160 lbs
        // Next milestone: 175 lbs (would be 5 lbs away from 170, threshold is 2)
        let result = NotificationScheduler.milestoneProgress(currentWeight: 178.0, goalWeight: 160.0, unit: .lb)

        #expect(result == nil) // Too far from milestone
    }

    @Test func milestoneProgressInKilograms() {
        // Current: 77.5 kg, Goal: 70 kg
        // Next milestone: 77.5 (0.5 kg to 77.5 milestone - wait, let's recalculate)
        // Actually milestone for kg is 2.5 interval
        let result = NotificationScheduler.milestoneProgress(currentWeight: 76.0, goalWeight: 70.0, unit: .kg)

        #expect(result != nil)
        #expect(result!.remaining == 1.0) // 76 - 75 = 1 kg
        #expect(result!.milestone == 75.0)
    }

    // MARK: - Weekly Summary Tests

    @Test func weeklySummaryGeneratesCorrectData() {
        let calendar = Calendar.current
        let now = Date()

        let entries = [
            WeightEntry(weight: 175.0, date: calendar.date(byAdding: .day, value: -6, to: now)!),
            WeightEntry(weight: 174.0, date: calendar.date(byAdding: .day, value: -4, to: now)!),
            WeightEntry(weight: 173.0, date: calendar.date(byAdding: .day, value: -2, to: now)!),
            WeightEntry(weight: 172.0, date: now)
        ]

        let summary = NotificationScheduler.generateWeeklySummary(entries: entries, unit: .lb)

        #expect(summary != nil)
        #expect(summary!.entryCount == 4)
        #expect(summary!.weightChange < 0) // Lost weight
        #expect(summary!.trend == .down)
    }

    @Test func weeklySummaryExcludesOldEntries() {
        let calendar = Calendar.current
        let now = Date()

        let entries = [
            WeightEntry(weight: 180.0, date: calendar.date(byAdding: .day, value: -14, to: now)!), // Too old
            WeightEntry(weight: 175.0, date: calendar.date(byAdding: .day, value: -3, to: now)!),
            WeightEntry(weight: 174.0, date: now)
        ]

        let summary = NotificationScheduler.generateWeeklySummary(entries: entries, unit: .lb)

        #expect(summary != nil)
        #expect(summary!.entryCount == 2) // Only 2 entries within 7 days
    }

    @Test func weeklySummaryWithNoRecentEntries() {
        let calendar = Calendar.current
        let now = Date()

        let entries = [
            WeightEntry(weight: 180.0, date: calendar.date(byAdding: .day, value: -14, to: now)!)
        ]

        let summary = NotificationScheduler.generateWeeklySummary(entries: entries, unit: .lb)

        #expect(summary == nil) // No entries in past week
    }

    // MARK: - Optimal Time Analysis Tests

    @Test func optimalTimeWithInsufficientData() {
        let entries = [
            WeightEntry(weight: 170.0),
            WeightEntry(weight: 171.0),
            WeightEntry(weight: 172.0)
        ]

        let result = NotificationScheduler.analyzeOptimalReminderTime(from: entries)
        #expect(result == nil) // Need at least 5 entries
    }

    @Test func optimalTimeWithSufficientData() {
        let calendar = Calendar.current
        var entries: [WeightEntry] = []

        // Create 10 entries all around 8 AM
        for i in 0..<10 {
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            dateComponents.day! -= i
            dateComponents.hour = 8
            dateComponents.minute = 15

            if let date = calendar.date(from: dateComponents) {
                entries.append(WeightEntry(weight: Double(170 + i), date: date))
            }
        }

        let result = NotificationScheduler.analyzeOptimalReminderTime(from: entries)

        #expect(result != nil)
        #expect(result!.hour == 8)
        #expect(result!.minute == 15) // Rounded to nearest 15
    }
}
