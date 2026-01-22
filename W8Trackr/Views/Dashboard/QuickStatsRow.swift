//
//  QuickStatsRow.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import SwiftUI

/// A row of quick stat cards showing key metrics at a glance
///
/// Layout:
/// ```
/// ┌─────────┐ ┌─────────┐
/// │This Week│ │ To Goal │
/// │  -1.5   │ │  12.5   │
/// │   lb    │ │   lb    │
/// └─────────┘ └─────────┘
/// ```
struct QuickStatsRow: View {
    let weeklyChange: Double?
    let toGoal: Double
    let weightUnit: WeightUnit

    var body: some View {
        HStack(spacing: 12) {
            // This week card
            if let change = weeklyChange {
                let sign = change > 0 ? "+" : ""
                let changeColor: Color = change < 0 ? AppColors.success :
                                          change > 0 ? AppColors.warning :
                                          AppColors.secondary
                QuickStatCard(
                    title: "This Week",
                    value: "\(sign)\(change.formatted(.number.precision(.fractionLength(1))))",
                    subtitle: weightUnit.displayName,
                    icon: change < 0 ? "arrow.down" : change > 0 ? "arrow.up" : "minus",
                    iconColor: changeColor
                )
            } else {
                QuickStatCard(
                    title: "This Week",
                    value: "--",
                    subtitle: weightUnit.displayName,
                    icon: "calendar",
                    iconColor: AppColors.secondary
                )
            }

            // To goal card
            let toGoalColor: Color = abs(toGoal) < 5 ? AppColors.success : AppColors.secondary
            QuickStatCard(
                title: "To Goal",
                value: toGoal.formatted(.number.precision(.fractionLength(1))),
                subtitle: weightUnit.displayName,
                icon: "flag.fill",
                iconColor: toGoalColor
            )
        }
    }
}

/// Individual stat card within QuickStatsRow
struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 6) {
            // Icon
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)

            // Value
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Subtitle
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)

            // Title
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(subtitle)")
    }
}

// MARK: - Streak Calculator

extension QuickStatsRow {
    /// Calculates the current logging streak from weight entries
    static func calculateStreak(from entries: [WeightEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique logged days sorted by date (most recent first)
        let loggedDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >)

        // Check if we logged today or yesterday (streak starts from most recent log)
        guard let mostRecentLog = loggedDays.first else { return 0 }

        let daysSinceLastLog = calendar.dateComponents([.day], from: mostRecentLog, to: today).day ?? 0

        // If last log was more than 1 day ago, streak is broken
        if daysSinceLastLog > 1 {
            return 0
        }

        // Count consecutive days backward from most recent log
        var streak = 1
        var currentDate = mostRecentLog

        for logDate in loggedDays.dropFirst() {
            let expectedPreviousDay = calendar.date(byAdding: .day, value: -1, to: currentDate)!

            if calendar.isDate(logDate, inSameDayAs: expectedPreviousDay) {
                streak += 1
                currentDate = logDate
            } else {
                break
            }
        }

        return streak
    }

    /// Calculates weekly weight change
    static func calculateWeeklyChange(from entries: [WeightEntry], unit: WeightUnit) -> Double? {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        // Get most recent entry
        guard let latestEntry = entries.first else { return nil }

        // Find entry from approximately a week ago
        let entriesBeforeWeekAgo = entries.filter { $0.date <= weekAgo }
        guard let weekAgoEntry = entriesBeforeWeekAgo.first else {
            // If no entry from a week ago, try to find oldest entry within last week
            let entriesThisWeek = entries.filter { $0.date > weekAgo }
            guard entriesThisWeek.count >= 2,
                  let oldestThisWeek = entriesThisWeek.last else {
                return nil
            }
            return latestEntry.weightValue(in: unit) - oldestThisWeek.weightValue(in: unit)
        }

        return latestEntry.weightValue(in: unit) - weekAgoEntry.weightValue(in: unit)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Good Progress") {
    QuickStatsRow(
        weeklyChange: -1.5,
        toGoal: 12.5,
        weightUnit: .lb
    )
    .padding()
}

#Preview("Just Started") {
    QuickStatsRow(
        weeklyChange: nil,
        toGoal: 25.0,
        weightUnit: .lb
    )
    .padding()
}

#Preview("Close to Goal") {
    QuickStatsRow(
        weeklyChange: -0.5,
        toGoal: 2.5,
        weightUnit: .kg
    )
    .padding()
}

#Preview("Weight Gain") {
    QuickStatsRow(
        weeklyChange: 2.0,
        toGoal: -10.0,
        weightUnit: .lb
    )
    .padding()
}
#endif
