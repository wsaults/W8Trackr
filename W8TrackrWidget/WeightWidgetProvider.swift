//
//  WeightWidgetProvider.swift
//  W8TrackrWidget
//
//  Created by Claude on 1/22/26.
//

import SwiftData
import WidgetKit

struct WeightWidgetProvider: TimelineProvider {
    typealias Entry = WeightWidgetEntry

    func placeholder(in context: Context) -> WeightWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WeightWidgetEntry) -> Void) {
        // For preview/gallery, use placeholder
        if context.isPreview {
            completion(.placeholder)
            return
        }
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeightWidgetEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        // Refresh every 4 hours as fallback; main app triggers immediate refresh on data change
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    // MARK: - Data Fetching

    private func fetchCurrentEntry() -> WeightWidgetEntry {
        // Create a new ModelContext for background use (widgets don't run on main actor)
        let container = SharedModelContainer.sharedModelContainer
        let context = ModelContext(container)

        // Fetch entries sorted newest first
        var descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 30 // Enough for 7-day window

        guard let entries = try? context.fetch(descriptor), !entries.isEmpty else {
            return .empty
        }

        // Read preferences from shared defaults
        let defaults = SharedModelContainer.sharedDefaults
        let unitString = defaults?.string(forKey: "preferredWeightUnit") ?? "lb"
        let unit = WeightUnit(rawValue: unitString) ?? .lb

        // Goal weight from shared defaults
        let goalWeight: Int?
        if let goalValue = defaults?.object(forKey: "goalWeight") as? Double, goalValue > 0 {
            goalWeight = Int(goalValue)
        } else {
            goalWeight = nil
        }

        // Current weight (most recent entry)
        let currentEntry = entries[0]
        let currentWeight = Int(currentEntry.weightValue(in: unit))

        // Calculate progress toward goal
        let progressPercent: Double?
        if let goal = goalWeight, let startWeight = entries.last {
            let startValue = startWeight.weightValue(in: unit)
            let currentValue = currentEntry.weightValue(in: unit)
            let goalValue = Double(goal)

            // Progress = how far along from start to goal
            let totalChange = startValue - goalValue
            let actualChange = startValue - currentValue

            if abs(totalChange) > 0.1 {
                progressPercent = actualChange / totalChange
            } else {
                progressPercent = nil
            }
        } else {
            progressPercent = nil
        }

        // Calculate trend from 7-day window
        let trend = calculateTrend(entries: entries, unit: unit)

        // Prepare chart data (last 7 days, oldest first)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let chartData = entries
            .filter { $0.date >= sevenDaysAgo }
            .map { WeightWidgetEntry.ChartDataPoint(date: $0.date, weight: $0.weightValue(in: unit)) }
            .sorted { $0.date < $1.date } // Oldest first for chart

        return WeightWidgetEntry(
            date: .now,
            currentWeight: currentWeight,
            weightUnit: unitString,
            goalWeight: goalWeight,
            progressPercent: progressPercent,
            trend: trend,
            chartData: chartData
        )
    }

    private func calculateTrend(entries: [WeightEntry], unit: WeightUnit) -> WeightWidgetEntry.WeightTrend {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recentEntries = entries.filter { $0.date >= sevenDaysAgo }

        guard recentEntries.count >= 2,
              let newest = recentEntries.first,
              let oldest = recentEntries.last else {
            return .unknown
        }

        let diff = newest.weightValue(in: unit) - oldest.weightValue(in: unit)

        // Neutral threshold: less than 0.5 unit change (per spec)
        if abs(diff) < 0.5 {
            return .neutral
        }

        return diff > 0 ? .up : .down
    }
}
