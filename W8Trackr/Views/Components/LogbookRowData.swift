//
//  LogbookRowData.swift
//  W8Trackr
//
//  Row data model for logbook entries with calculated moving average and weekly rate.
//

import SwiftUI

/// Direction of weight change trend for visual indication
enum TrendDirection {
    case up
    case down
    case stable

    /// SF Symbol name for the direction arrow
    var symbol: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }

    /// Color for the direction indicator
    /// Note: Down (losing weight) is success/green, Up (gaining) is warning
    var color: Color {
        switch self {
        case .up: return AppColors.warning
        case .down: return AppColors.success
        case .stable: return AppColors.secondary
        }
    }
}

/// Enhanced row data for logbook display with calculated metrics
struct LogbookRowData: Identifiable {
    /// Uses the entry's date as a stable identifier
    var id: Date { entry.date }
    let entry: WeightEntry
    let movingAverage: Double?
    let weeklyRate: Double?
    let hasNote: Bool

    /// Determines trend direction based on weekly rate of change
    var weightChangeDirection: TrendDirection {
        guard let rate = weeklyRate else { return .stable }
        if abs(rate) < 0.1 {
            return .stable
        } else if rate < 0 {
            return .down  // Losing weight
        } else {
            return .up    // Gaining weight
        }
    }

    /// Builds row data array from weight entries with calculated metrics
    /// - Parameters:
    ///   - entries: Array of weight entries to process
    ///   - unit: Weight unit for calculations and display
    /// - Returns: Array of LogbookRowData sorted by date descending (newest first)
    static func buildRowData(entries: [WeightEntry], unit: WeightUnit) -> [LogbookRowData] {
        guard !entries.isEmpty else { return [] }

        // Sort entries by date descending (newest first) for display
        let sortedDescending = entries.sorted { $0.date > $1.date }

        // Calculate trend using TrendCalculator (expects oldest first)
        let sortedAscending = entries.sorted { $0.date < $1.date }
        let trendPoints = TrendCalculator.exponentialMovingAverage(entries: sortedAscending, span: 7)

        // Build dictionary keyed by start of day for O(1) lookup
        let trendByDay: [Date: TrendPoint] = Dictionary(
            uniqueKeysWithValues: trendPoints.map { point in
                (Calendar.current.startOfDay(for: point.date), point)
            }
        )

        let calendar = Calendar.current

        return sortedDescending.map { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            let trendPoint = trendByDay[entryDay]

            // Get moving average in the requested unit
            let movingAverage: Double? = trendPoint.map { point in
                point.smoothedWeight(in: unit)
            }

            // Calculate weekly rate: find entry from ~7 days ago
            var weeklyRate: Double?
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: entryDay) ?? entryDay

            // Find the closest entry that is at least 7 days old
            let previousEntries = sortedAscending.filter { otherEntry in
                calendar.startOfDay(for: otherEntry.date) <= sevenDaysAgo
            }

            if let previousEntry = previousEntries.last {
                let currentWeight = entry.weightValue(in: unit)
                let previousWeight = previousEntry.weightValue(in: unit)
                weeklyRate = currentWeight - previousWeight  // Positive = gained weight
            }

            return LogbookRowData(
                entry: entry,
                movingAverage: movingAverage,
                weeklyRate: weeklyRate,
                hasNote: entry.note != nil && !(entry.note?.isEmpty ?? true)
            )
        }
    }
}
