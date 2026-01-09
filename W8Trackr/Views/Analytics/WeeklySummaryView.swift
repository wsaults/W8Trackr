//
//  WeeklySummaryView.swift
//  W8Trackr
//
//  Swipeable weekly summaries showing progress over time
//

import SwiftUI

struct WeeklySummaryView: View {
    let entries: [WeightEntry]
    let weightUnit: WeightUnit

    @State private var selectedWeekIndex: Int = 0

    private var weeks: [WeeklySummary] {
        generateWeeks()
    }

    var body: some View {
        Section {
            if weeks.isEmpty {
                ContentUnavailableView(
                    "No Weekly Data",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Log entries to see weekly summaries")
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 8) {
                    TabView(selection: $selectedWeekIndex) {
                        ForEach(Array(weeks.enumerated()), id: \.offset) { index, summary in
                            WeeklySummaryCard(summary: summary)
                                .padding(.horizontal)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 220)

                    // Custom page indicator
                    PageIndicator(
                        currentPage: selectedWeekIndex,
                        totalPages: weeks.count
                    )
                }
            }
        } header: {
            HStack {
                Text("Weekly Summary")
                    .font(.title2)
                Spacer()
                if weeks.count > 1 {
                    Text("Swipe for more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }

    private func generateWeeks() -> [WeeklySummary] {
        guard !entries.isEmpty else { return [] }

        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.date > $1.date }

        // Find the range of weeks we have data for
        guard let newestDate = sortedEntries.first?.date,
              let oldestDate = sortedEntries.last?.date else {
            return []
        }

        // Get the start of the current week containing the newest entry
        var weekStarts: [Date] = []
        var currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: newestDate))!

        // Generate week starts going backwards until we pass the oldest entry
        let oldestWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: oldestDate))!

        while currentWeekStart >= oldestWeekStart {
            weekStarts.append(currentWeekStart)
            currentWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
        }

        // Limit to most recent 12 weeks for performance
        let limitedWeekStarts = Array(weekStarts.prefix(12))

        return limitedWeekStarts.enumerated().compactMap { index, weekStart in
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let weekEndOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEnd)!

            let weekEntries = entries.filter { entry in
                entry.date >= weekStart && entry.date <= weekEndOfDay
            }

            // Get previous week entries for comparison
            let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
            let previousWeekEnd = calendar.date(byAdding: .day, value: 6, to: previousWeekStart)!
            let previousWeekEndOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: previousWeekEnd)!

            let previousWeekEntries = entries.filter { entry in
                entry.date >= previousWeekStart && entry.date <= previousWeekEndOfDay
            }

            // Only include weeks that have at least one entry
            guard !weekEntries.isEmpty else { return nil }

            return WeeklySummary(
                weekStart: weekStart,
                weekEnd: weekEnd,
                entries: weekEntries,
                previousWeekEntries: previousWeekEntries,
                weightUnit: weightUnit
            )
        }
    }
}

private struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<min(totalPages, 5), id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            if totalPages > 5 {
                Text("+\(totalPages - 5)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    ScrollView {
        WeeklySummaryView(
            entries: WeightEntry.shortSampleData,
            weightUnit: .lb
        )
    }
    .background(Color.gray.opacity(0.1))
}
