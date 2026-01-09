//
//  WeeklySummaryCard.swift
//  W8Trackr
//
//  Weekly summary card showing stats and encouraging messages
//

import SwiftUI

struct WeeklySummary {
    let weekStart: Date
    let weekEnd: Date
    let entries: [WeightEntry]
    let previousWeekEntries: [WeightEntry]
    let weightUnit: WeightUnit

    var entryCount: Int { entries.count }

    var averageWeight: Double? {
        guard !entries.isEmpty else { return nil }
        let total = entries.reduce(0) { $0 + $1.weightValue(in: weightUnit) }
        return total / Double(entries.count)
    }

    var previousWeekAverage: Double? {
        guard !previousWeekEntries.isEmpty else { return nil }
        let total = previousWeekEntries.reduce(0) { $0 + $1.weightValue(in: weightUnit) }
        return total / Double(previousWeekEntries.count)
    }

    var changeFromLastWeek: Double? {
        guard let current = averageWeight, let previous = previousWeekAverage else { return nil }
        return current - previous
    }

    var bestDay: (date: Date, weight: Double)? {
        guard let best = entries.min(by: { $0.weightValue(in: weightUnit) < $1.weightValue(in: weightUnit) }) else {
            return nil
        }
        return (best.date, best.weightValue(in: weightUnit))
    }

    var trend: WeeklyTrend {
        guard let change = changeFromLastWeek else { return .stable }
        if abs(change) < 0.5 { return .stable }
        return change < 0 ? .down : .up
    }
}

enum WeeklyTrend {
    case up, down, stable

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .up: return .orange
        case .down: return .green
        case .stable: return .blue
        }
    }
}

struct WeeklySummaryCard: View {
    let summary: WeeklySummary

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: summary.weekStart)
        let end = formatter.string(from: summary.weekEnd)
        return "\(start) - \(end)"
    }

    private var encouragingMessage: String {
        switch summary.trend {
        case .down:
            let messages = [
                "Great progress this week!",
                "You're crushing it!",
                "Keep up the momentum!",
                "Amazing work!"
            ]
            return messages.randomElement() ?? messages[0]
        case .stable:
            let messages = [
                "Staying consistent!",
                "Holding steady!",
                "Consistency is key!",
                "Right on track!"
            ]
            return messages.randomElement() ?? messages[0]
        case .up:
            let messages = [
                "Every week is a fresh start!",
                "Tomorrow's another day!",
                "Keep tracking, keep learning!",
                "Progress isn't always linear!"
            ]
            return messages.randomElement() ?? messages[0]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with date range and trend
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateRangeText)
                        .font(.headline)
                    Text("\(summary.entryCount) entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: summary.trend.icon)
                    .font(.title2)
                    .foregroundStyle(summary.trend.color)
                    .fontWeight(.bold)
            }

            Divider()

            // Stats grid
            HStack(spacing: 20) {
                StatView(
                    title: "Average",
                    value: summary.averageWeight.map { String(format: "%.1f", $0) } ?? "--",
                    unit: summary.weightUnit.rawValue
                )

                StatView(
                    title: "Change",
                    value: summary.changeFromLastWeek.map { formatChange($0) } ?? "--",
                    unit: summary.weightUnit.rawValue,
                    valueColor: summary.trend.color
                )

                if let best = summary.bestDay {
                    StatView(
                        title: "Best Day",
                        value: String(format: "%.1f", best.weight),
                        unit: formatBestDayDate(best.date)
                    )
                }
            }

            // Encouraging message
            Text(encouragingMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .italic()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    private func formatChange(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", value))"
    }

    private func formatBestDayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

private struct StatView: View {
    let title: String
    let value: String
    let unit: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(valueColor)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date.now
    let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
    let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

    let summary = WeeklySummary(
        weekStart: weekStart,
        weekEnd: weekEnd,
        entries: WeightEntry.shortSampleData.filter { $0.date >= weekStart },
        previousWeekEntries: [],
        weightUnit: .lb
    )

    return WeeklySummaryCard(summary: summary)
        .padding()
        .background(Color.gray.opacity(0.1))
}
