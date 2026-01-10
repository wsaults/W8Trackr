//
//  SharedModelContainer.swift
//  W8Trackr (Shared)
//
//  Contract: Shared SwiftData container configuration for App Group access
//

import SwiftData

/// Provides shared ModelContainer for main app and widget extension
enum SharedModelContainer {

    /// App Group identifier - must match entitlements in both targets
    static let appGroupIdentifier = "group.com.yourcompany.W8Trackr"

    /// UserDefaults preference keys (shared between app and widget)
    enum PreferenceKey {
        static let preferredWeightUnit = "preferredWeightUnit"
        static let goalWeight = "goalWeight"
    }

    /// Shared ModelContainer configured for App Group storage
    ///
    /// Usage:
    /// - Main app: Use in `.modelContainer()` modifier
    /// - Widget: Access `mainContext` in TimelineProvider
    ///
    /// - Important: Both targets must include this file and the `WeightEntry` model
    static let shared: ModelContainer = {
        let schema = Schema([
            WeightEntry.self
            // Add other shared models here (e.g., MilestoneAchievement)
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()

    /// Shared UserDefaults for preferences
    ///
    /// Usage:
    /// ```swift
    /// let defaults = SharedModelContainer.sharedDefaults
    /// let unit = defaults?.string(forKey: PreferenceKey.preferredWeightUnit) ?? "lb"
    /// ```
    static let sharedDefaults: UserDefaults? = {
        UserDefaults(suiteName: appGroupIdentifier)
    }()
}

// MARK: - Preference Migration

extension SharedModelContainer {

    /// Migrate standard UserDefaults to shared App Group UserDefaults
    ///
    /// Call this once on app launch (after widget feature ships) to ensure
    /// existing user preferences are accessible by the widget.
    ///
    /// - Parameter standardDefaults: Standard UserDefaults (default: .standard)
    static func migratePreferencesToSharedDefaults(from standardDefaults: UserDefaults = .standard) {
        guard let shared = sharedDefaults else { return }

        // Only migrate if shared defaults are empty (first run after update)
        guard shared.string(forKey: PreferenceKey.preferredWeightUnit) == nil else {
            return // Already migrated
        }

        // Migrate weight unit
        if let unit = standardDefaults.string(forKey: PreferenceKey.preferredWeightUnit) {
            shared.set(unit, forKey: PreferenceKey.preferredWeightUnit)
        }

        // Migrate goal weight (only if explicitly set)
        let goalKey = PreferenceKey.goalWeight
        if standardDefaults.object(forKey: goalKey) != nil {
            shared.set(standardDefaults.double(forKey: goalKey), forKey: goalKey)
        }
    }
}

// MARK: - Widget Reload Helper

import WidgetKit

extension SharedModelContainer {

    /// Notify widget to reload its timeline
    ///
    /// Call this after any data change in the main app:
    /// - New weight entry added
    /// - Weight entry updated
    /// - Weight entry deleted
    /// - Preference changed (unit, goal weight)
    static func reloadWidgetTimeline() {
        WidgetCenter.shared.reloadTimelines(ofKind: "WeightWidget")
    }
}
