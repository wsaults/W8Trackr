//
//  MigrationManager.swift
//  W8Trackr
//
//  Manages data migration from default SwiftData location to App Group container.
//

import CoreData
import Foundation
import SwiftData
import WidgetKit

/// Represents the current state of data migration.
///
/// Migration moves SwiftData from the default Application Support location
/// to the App Group container for widget access.
enum MigrationStatus: Equatable {
    /// Fresh install or already migrated - no action needed
    case notNeeded
    /// Migration needed but not started
    case pending
    /// Currently migrating
    case inProgress
    /// Successfully migrated
    case completed
    /// Migration failed with error message
    case failed(String)

    static func == (lhs: MigrationStatus, rhs: MigrationStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notNeeded, .notNeeded),
             (.pending, .pending),
             (.inProgress, .inProgress),
             (.completed, .completed):
            return true
        case let (.failed(lhsMsg), .failed(rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

/// Manages migration of SwiftData from the default location to App Group container.
///
/// This manager handles the one-time migration required when updating from a version
/// that stored data in the default Application Support directory to one that uses
/// App Groups for widget data sharing.
///
/// ## Migration Strategy
/// Uses `replacePersistentStore` (NOT `migratePersistentStore`) to preserve CloudKit
/// metadata and prevent data duplication during sync.
///
/// ## Usage
/// ```swift
/// @State private var migrationManager = MigrationManager()
///
/// var body: some Scene {
///     WindowGroup {
///         ContentView()
///             .task {
///                 if migrationManager.status == .pending {
///                     await migrationManager.performMigration()
///                 }
///             }
///     }
/// }
/// ```
@Observable @MainActor
final class MigrationManager {
    /// The current migration status.
    private(set) var status: MigrationStatus = .pending

    /// URL of the old SwiftData store (Application Support/default.store)
    private let oldStoreURL: URL

    /// URL of the new SwiftData store (App Group container/default.store)
    private let newStoreURL: URL

    /// Creates a new MigrationManager and detects store locations.
    init() {
        // Default SwiftData location (Application Support)
        oldStoreURL = URL.applicationSupportDirectory
            .appending(path: "default.store")

        // App Group location
        let fileManager = FileManager.default
        if let appGroupURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: SharedModelContainer.appGroupIdentifier
        ) {
            newStoreURL = appGroupURL.appending(path: "default.store")
        } else {
            // This shouldn't happen if entitlements are correct
            newStoreURL = oldStoreURL
        }
    }

    /// Checks whether migration is needed based on store file existence.
    ///
    /// Call this at app launch before attempting migration.
    /// - Fresh install: No old store exists, uses App Group directly
    /// - Already migrated: New store exists, old may or may not exist
    /// - Needs migration: Old store exists, new doesn't
    func checkMigrationNeeded() {
        let fileManager = FileManager.default

        // If new store already exists, migration not needed (already done or fresh install to App Group)
        if fileManager.fileExists(atPath: newStoreURL.path()) {
            status = .notNeeded
            return
        }

        // If old store doesn't exist, fresh install - no migration needed
        if !fileManager.fileExists(atPath: oldStoreURL.path()) {
            status = .notNeeded
            return
        }

        // Old store exists, new doesn't - migration needed
        status = .pending
    }

    /// Performs migration using CloudKit-safe `replacePersistentStore`.
    ///
    /// CRITICAL: Uses `replacePersistentStore`, NOT `migratePersistentStore`.
    /// The migrate API strips CloudKit metadata, causing data duplication
    /// when sync resumes after migration.
    ///
    /// Migration runs on a background thread but status updates are on MainActor.
    /// The app remains usable during migration - users will see their data
    /// once migration completes.
    func performMigration() async {
        guard status == .pending else { return }

        status = .inProgress

        do {
            // Perform migration on background thread since it involves file I/O
            try await Task.detached(priority: .userInitiated) { [oldStoreURL, newStoreURL] in
                // Create a temporary Core Data stack for migration
                // We use NSPersistentContainer because SwiftData doesn't expose
                // the replacePersistentStore API directly
                let container = NSPersistentContainer(name: "W8Trackr")

                // Configure WITHOUT CloudKit during migration to prevent:
                // 1. Sync attempts during file operations
                // 2. Hangs for users with iCloud disabled
                let description = NSPersistentStoreDescription(url: oldStoreURL)
                description.cloudKitContainerOptions = nil
                container.persistentStoreDescriptions = [description]

                // Use replacePersistentStore which preserves CloudKit metadata
                try container.persistentStoreCoordinator.replacePersistentStore(
                    at: newStoreURL,
                    withPersistentStoreFrom: oldStoreURL,
                    type: .sqlite
                )
            }.value

            // Migration succeeded
            status = .completed

            // Notify widgets to reload (they can now access data)
            WidgetCenter.shared.reloadAllTimelines()

            // Decision: Keep old store as backup for this release.
            // Can be cleaned up in a future version after confirming migration success at scale.

        } catch {
            // Do NOT retry automatically - user must tap retry
            status = .failed(error.localizedDescription)
        }
    }

    /// Manual retry triggered by user after a failed migration.
    ///
    /// Resets status to pending and attempts migration again.
    func retryMigration() async {
        guard case .failed = status else { return }
        status = .pending
        await performMigration()
    }
}
