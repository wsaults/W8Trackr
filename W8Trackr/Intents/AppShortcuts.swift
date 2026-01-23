//
//  AppShortcuts.swift
//  W8Trackr
//
//  Siri Shortcuts integration using App Intents framework (iOS 16+)
//

import AppIntents
import SwiftData

// MARK: - App Shortcuts Provider

struct W8TrackrShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWeightIntent(),
            phrases: [
                // English
                "Log my weight in \(.applicationName)",
                "Add weight to \(.applicationName)",
                "Record my weight in \(.applicationName)",
                // Spanish
                "Registrar mi peso en \(.applicationName)",
                "Agregar peso en \(.applicationName)",
                "Anotar mi peso en \(.applicationName)"
            ],
            shortTitle: "Log Weight",
            systemImageName: "scalemass"
        )

        AppShortcut(
            intent: GetWeightTrendIntent(),
            phrases: [
                // English
                "What's my weight trend in \(.applicationName)",
                "How is my weight trending in \(.applicationName)",
                "Show weight trend from \(.applicationName)",
                // Spanish
                "Cual es mi tendencia de peso en \(.applicationName)",
                "Como va mi peso en \(.applicationName)",
                "Mostrar tendencia de peso de \(.applicationName)"
            ],
            shortTitle: "Weight Trend",
            systemImageName: "chart.line.uptrend.xyaxis"
        )

        AppShortcut(
            intent: GetWeightLossIntent(),
            phrases: [
                // English
                "How much have I lost in \(.applicationName)",
                "What's my weight change in \(.applicationName)",
                "How much weight have I lost in \(.applicationName)",
                // Spanish
                "Cuanto peso he perdido en \(.applicationName)",
                "Cual es mi cambio de peso en \(.applicationName)",
                "Cuanto he bajado en \(.applicationName)"
            ],
            shortTitle: "Weight Change",
            systemImageName: "arrow.down.right"
        )
    }
}

// MARK: - Log Weight Intent

struct LogWeightIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Weight"
    static let description = IntentDescription("Opens W8Trackr to log your current weight")

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // The app will open due to openAppWhenRun = true
        // We return a dialog to provide voice feedback
        return .result(dialog: "Opening W8Trackr to log your weight")
    }
}

// MARK: - Get Weight Trend Intent

struct GetWeightTrendIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Weight Trend"
    static let description = IntentDescription("Reports your recent weight trend")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: WeightEntry.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let entries = try context.fetch(descriptor)

        guard entries.count >= 2 else {
            return .result(dialog: "I need at least 2 weight entries to calculate a trend. Keep logging!")
        }

        // Get entries from the last 7 days
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEntries = entries.filter { $0.date >= sevenDaysAgo }

        let entriesToAnalyze = recentEntries.count >= 2 ? recentEntries : Array(entries.prefix(7))

        guard let newest = entriesToAnalyze.first,
              let oldest = entriesToAnalyze.last else {
            return .result(dialog: "Unable to calculate trend")
        }

        // Use preferred unit from UserDefaults
        let preferredUnitString = UserDefaults.standard.string(forKey: "preferredWeightUnit") ?? "lb"
        let unit = WeightUnit(rawValue: preferredUnitString) ?? .lb

        let newestWeight = newest.weightValue(in: unit)
        let oldestWeight = oldest.weightValue(in: unit)
        let change = newestWeight - oldestWeight

        let trendDescription: String
        let changeAmount = abs(change).formatted(.number.precision(.fractionLength(1)))

        if abs(change) < 0.5 {
            trendDescription = "Your weight has been stable at \(newestWeight.formatted(.number.precision(.fractionLength(1)))) \(unit.rawValue)"
        } else if change < 0 {
            trendDescription = "You're down \(changeAmount) \(unit.rawValue)! Your current weight is \(newestWeight.formatted(.number.precision(.fractionLength(1)))) \(unit.rawValue)"
        } else {
            trendDescription = "You're up \(changeAmount) \(unit.rawValue). Your current weight is \(newestWeight.formatted(.number.precision(.fractionLength(1)))) \(unit.rawValue)"
        }

        return .result(dialog: "\(trendDescription)")
    }
}

// MARK: - Get Weight Loss Intent

struct GetWeightLossIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Weight Change"
    static let description = IntentDescription("Reports your total weight change since you started tracking")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: WeightEntry.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let entries = try context.fetch(descriptor)

        guard let firstEntry = entries.first,
              let lastEntry = entries.last,
              entries.count >= 2 else {
            return .result(dialog: "I need at least 2 weight entries to calculate your progress. Keep logging!")
        }

        // Use preferred unit from UserDefaults
        let preferredUnitString = UserDefaults.standard.string(forKey: "preferredWeightUnit") ?? "lb"
        let unit = WeightUnit(rawValue: preferredUnitString) ?? .lb

        let startWeight = firstEntry.weightValue(in: unit)
        let currentWeight = lastEntry.weightValue(in: unit)
        let totalChange = currentWeight - startWeight

        let changeAmount = abs(totalChange).formatted(.number.precision(.fractionLength(1)))
        let startFormatted = startWeight.formatted(.number.precision(.fractionLength(1)))
        let currentFormatted = currentWeight.formatted(.number.precision(.fractionLength(1)))

        let timeSpan = Calendar.current.dateComponents([.day], from: firstEntry.date, to: lastEntry.date)
        let days = timeSpan.day ?? 0
        let timeDescription = days == 1 ? "1 day" : "\(days) days"

        let message: String
        if abs(totalChange) < 0.5 {
            message = "Your weight has stayed steady at around \(currentFormatted) \(unit.rawValue) over \(timeDescription)"
        } else if totalChange < 0 {
            message = "Great progress! You've lost \(changeAmount) \(unit.rawValue) over \(timeDescription). You started at \(startFormatted) and you're now at \(currentFormatted) \(unit.rawValue)"
        } else {
            message = "You've gained \(changeAmount) \(unit.rawValue) over \(timeDescription). You started at \(startFormatted) and you're now at \(currentFormatted) \(unit.rawValue)"
        }

        return .result(dialog: "\(message)")
    }
}
