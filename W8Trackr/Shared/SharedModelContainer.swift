//
//  SharedModelContainer.swift
//  W8Trackr
//
//  Created by Claude on 1/22/26.
//

import Foundation
import SwiftData

/// Shared model container configuration for the main app and widget extension.
///
/// This enum provides a centralized configuration for SwiftData persistence
/// that can be shared across the main app and widget targets via App Groups.
/// Using an enum ensures stateless access to configuration without instantiation.
enum SharedModelContainer {
    /// The App Group identifier shared between the main app and widget extension.
    static let appGroupIdentifier = "group.com.saults.W8Trackr"

    /// Creates a shared ModelContainer configured for App Group storage.
    ///
    /// The container uses:
    /// - App Group storage for cross-target data sharing
    /// - CloudKit automatic sync for cloud backup
    ///
    /// - Returns: A configured ModelContainer for the shared data store
    /// - Note: Uses fatalError if container creation fails, as the app cannot function without data persistence.
    static var sharedModelContainer: ModelContainer {
        let schema = Schema([
            WeightEntry.self,
            CompletedMilestone.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create shared ModelContainer: \(error.localizedDescription)")
        }
    }

    /// Shared UserDefaults for cross-target preferences.
    ///
    /// Returns nil if the App Group is not properly configured.
    /// Use this for sharing simple preferences between the main app and widgets.
    /// UserDefaults is thread-safe for reads/writes, so nonisolated(unsafe) is appropriate.
    nonisolated(unsafe) static let sharedDefaults: UserDefaults? = UserDefaults(suiteName: appGroupIdentifier)
}
