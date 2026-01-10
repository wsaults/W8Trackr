//
//  WeightWidgetProvider.swift
//  W8TrackrWidget
//
//  Contract: Timeline provider for weight tracking widget
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

/// Represents widget state at a point in time
struct WeightWidgetEntry: TimelineEntry {
    let date: Date
    let currentWeight: Double?
    let weightUnit: WeightUnit
    let goalWeight: Double?
    let entryDate: Date?
    let trend: WeightTrend

    /// Weight trend over recent entries
    enum WeightTrend {
        case up      // Weight increasing
        case down    // Weight decreasing
        case stable  // Change < 0.5 units
        case unknown // Insufficient data
    }

    // MARK: - Computed Properties

    /// Whether there is weight data to display
    var hasData: Bool {
        currentWeight != nil
    }

    /// Whether a goal is set
    var hasGoal: Bool {
        goalWeight != nil
    }

    /// Distance to goal (positive = above goal, negative = below goal)
    var distanceToGoal: Double? {
        guard let current = currentWeight, let goal = goalWeight else { return nil }
        return current - goal
    }

    /// Whether goal has been reached (current <= goal for weight loss)
    var goalReached: Bool {
        guard let distance = distanceToGoal else { return false }
        return distance <= 0
    }
}

// MARK: - Timeline Provider

/// Provides timeline entries for the weight widget
struct WeightWidgetProvider: TimelineProvider {

    /// App Group identifier for shared data access
    private static let appGroupIdentifier = "group.com.yourcompany.W8Trackr"

    // MARK: - TimelineProvider Protocol

    /// Placeholder entry for widget gallery
    func placeholder(in context: Context) -> WeightWidgetEntry {
        WeightWidgetEntry(
            date: .now,
            currentWeight: 175.0,
            weightUnit: .lb,
            goalWeight: 160.0,
            entryDate: .now,
            trend: .down
        )
    }

    /// Snapshot for widget gallery preview
    func getSnapshot(in context: Context, completion: @escaping (WeightWidgetEntry) -> Void) {
        let entry = fetchCurrentEntry()
        completion(entry)
    }

    /// Full timeline for widget updates
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeightWidgetEntry>) -> Void) {
        let currentEntry = fetchCurrentEntry()

        // Single entry timeline - relies on app-triggered reloads
        // Fallback refresh in 4 hours if no app activity
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? .now

        let timeline = Timeline(
            entries: [currentEntry],
            policy: .after(nextRefresh)
        )
        completion(timeline)
    }

    // MARK: - Data Fetching

    /// Fetch current weight data from shared container
    private func fetchCurrentEntry() -> WeightWidgetEntry {
        // TODO: Implementation will use SharedModelContainer
        // This contract defines the expected interface

        // Access shared SwiftData container
        // let context = SharedModelContainer.shared.mainContext

        // Fetch most recent entry
        // let descriptor = FetchDescriptor<WeightEntry>(
        //     sortBy: [SortDescriptor(\.date, order: .reverse)]
        // )
        // let entries = try? context.fetch(descriptor)

        // Read preferences from shared UserDefaults
        // let defaults = UserDefaults(suiteName: Self.appGroupIdentifier)
        // let unitString = defaults?.string(forKey: "preferredWeightUnit") ?? "lb"
        // let goalWeight = defaults?.double(forKey: "goalWeight")

        // Calculate trend from recent entries
        // let trend = calculateTrend(from: entries ?? [])

        // Return entry
        return WeightWidgetEntry(
            date: .now,
            currentWeight: nil,
            weightUnit: .lb,
            goalWeight: nil,
            entryDate: nil,
            trend: .unknown
        )
    }

    /// Calculate weight trend from recent entries
    /// - Parameter entries: Weight entries sorted by date (newest first)
    /// - Returns: Trend direction based on 7-day window
    private func calculateTrend(from entries: [WeightEntry]) -> WeightWidgetEntry.WeightTrend {
        guard entries.count >= 2 else { return .unknown }

        // Get entries from last 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recentEntries = entries.filter { $0.date >= sevenDaysAgo }

        guard let newest = recentEntries.first,
              let oldest = recentEntries.last,
              newest !== oldest else {
            return .unknown
        }

        let diff = newest.weightValue - oldest.weightValue

        // Threshold for "stable" - less than 0.5 unit change
        if abs(diff) < 0.5 {
            return .stable
        }

        return diff > 0 ? .up : .down
    }
}

// MARK: - Widget Configuration

/// Main widget definition
struct WeightWidget: Widget {
    let kind: String = "WeightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeightWidgetProvider()) { entry in
            WeightWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weight Tracker")
        .description("See your current weight and progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Entry View (Stub)

/// Routes to appropriate size-specific view
struct WeightWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WeightWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            // SmallWidgetView(entry: entry)
            Text("Small Widget")
        case .systemMedium:
            // MediumWidgetView(entry: entry)
            Text("Medium Widget")
        default:
            Text("Unsupported")
        }
    }
}
