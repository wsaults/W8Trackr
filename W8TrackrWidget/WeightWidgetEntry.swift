//
//  WeightWidgetEntry.swift
//  W8TrackrWidget
//
//  Created by Claude on 1/22/26.
//

import WidgetKit

/// Timeline entry containing all data needed to render widget views
struct WeightWidgetEntry: TimelineEntry {
    let date: Date

    /// Current weight as whole number (per CONTEXT.md), nil if no entries
    let currentWeight: Int?

    /// Weight unit string ("lb" or "kg")
    let weightUnit: String

    /// Goal weight as whole number, nil if not set
    let goalWeight: Int?

    /// Progress toward goal (0.0 to 1.0+), nil if no goal or no current weight
    let progressPercent: Double?

    /// Weight trend based on 7-day comparison
    let trend: WeightTrend

    /// Recent entries for sparkline chart (last 7 days, oldest first)
    let chartData: [ChartDataPoint]

    /// Weight trend direction
    enum WeightTrend {
        case up, down, neutral, unknown

        var systemImage: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            case .unknown: return "minus"
            }
        }
    }

    /// Data point for sparkline chart
    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
    }

    /// Empty state for when no data exists
    static var empty: WeightWidgetEntry {
        WeightWidgetEntry(
            date: .now,
            currentWeight: nil,
            weightUnit: "lb",
            goalWeight: nil,
            progressPercent: nil,
            trend: .unknown,
            chartData: []
        )
    }

    /// Placeholder for widget gallery
    static var placeholder: WeightWidgetEntry {
        let calendar = Calendar.current
        return WeightWidgetEntry(
            date: .now,
            currentWeight: 175,
            weightUnit: "lb",
            goalWeight: 165,
            progressPercent: 0.6,
            trend: .down,
            chartData: [
                ChartDataPoint(date: calendar.date(byAdding: .day, value: -6, to: .now) ?? .now, weight: 180),
                ChartDataPoint(date: calendar.date(byAdding: .day, value: -5, to: .now) ?? .now, weight: 179),
                ChartDataPoint(date: calendar.date(byAdding: .day, value: -4, to: .now) ?? .now, weight: 178),
                ChartDataPoint(date: calendar.date(byAdding: .day, value: -3, to: .now) ?? .now, weight: 177),
                ChartDataPoint(date: calendar.date(byAdding: .day, value: -2, to: .now) ?? .now, weight: 176),
                ChartDataPoint(date: calendar.date(byAdding: .day, value: -1, to: .now) ?? .now, weight: 175),
                ChartDataPoint(date: .now, weight: 175)
            ]
        )
    }
}
