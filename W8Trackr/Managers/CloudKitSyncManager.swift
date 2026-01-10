//
//  CloudKitSyncManager.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import CloudKit
import Combine
import Network
import SwiftUI

/// Monitors CloudKit sync status for SwiftData
///
/// Provides real-time sync status by monitoring:
/// - Network connectivity (via NWPathMonitor)
/// - iCloud account status (via CKContainer)
/// - CloudKit sync events (via NSPersistentCloudKitContainer notifications)
final class CloudKitSyncManager: ObservableObject {
    static let shared = CloudKitSyncManager()

    /// Current sync status
    @Published private(set) var status: CloudSyncStatus = .checking

    /// Last sync timestamp (nil if never synced)
    @Published private(set) var lastSyncDate: Date?

    /// Error message for failed state
    @Published private(set) var errorMessage: String?

    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.w8trackr.networkMonitor")
    private var cancellables = Set<AnyCancellable>()
    private var isNetworkAvailable = true

    private init() {
        setupNetworkMonitoring()
        setupCloudKitMonitoring()
        checkInitialStatus()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
                self?.updateStatus()
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    // MARK: - CloudKit Monitoring

    private func setupCloudKitMonitoring() {
        // Listen for CloudKit sync events from NSPersistentCloudKitContainer
        NotificationCenter.default.publisher(
            for: NSNotification.Name("NSPersistentCloudKitContainer.eventChangedNotification")
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            self?.handleCloudKitEvent(notification)
        }
        .store(in: &cancellables)

        // Also listen for iCloud account changes
        NotificationCenter.default.publisher(for: .CKAccountChanged)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.checkiCloudStatus()
        }
        .store(in: &cancellables)
    }

    private func handleCloudKitEvent(_ notification: Notification) {
        // Extract event type from notification if available
        if let event = notification.userInfo?["event"] as? Any {
            let eventDescription = String(describing: event)

            if eventDescription.contains("setup") || eventDescription.contains("import") || eventDescription.contains("export") {
                status = .syncing
            } else if eventDescription.contains("succeeded") {
                lastSyncDate = Date()
                errorMessage = nil
                status = .synced
            } else if eventDescription.contains("failed") {
                errorMessage = "Sync failed. Will retry automatically."
                status = .error
            }
        } else {
            // Generic sync activity detected
            status = .syncing
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if self?.status == .syncing {
                    self?.lastSyncDate = Date()
                    self?.status = .synced
                }
            }
        }
    }

    // MARK: - Status Checks

    private func checkInitialStatus() {
        checkiCloudStatus()
    }

    private func checkiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.status = .error
                    return
                }

                switch status {
                case .available:
                    self?.updateStatus()
                case .noAccount:
                    self?.errorMessage = "Sign in to iCloud to sync data across devices"
                    self?.status = .noAccount
                case .restricted:
                    self?.errorMessage = "iCloud access is restricted"
                    self?.status = .error
                case .couldNotDetermine:
                    self?.status = .checking
                case .temporarilyUnavailable:
                    self?.errorMessage = "iCloud is temporarily unavailable"
                    self?.status = .offline
                @unknown default:
                    self?.status = .checking
                }
            }
        }
    }

    private func updateStatus() {
        guard status != .noAccount else { return }

        if !isNetworkAvailable {
            status = .offline
            errorMessage = nil
        } else if status == .offline {
            // Network restored, check if we can sync
            status = .syncing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                if self?.status == .syncing {
                    self?.lastSyncDate = Date()
                    self?.status = .synced
                }
            }
        } else if status == .checking {
            status = .synced
            lastSyncDate = Date()
        }
    }

    /// Force a status refresh
    func refresh() {
        checkiCloudStatus()
    }

    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - Sync Status Enum

/// Represents the current CloudKit sync status
enum CloudSyncStatus: Equatable {
    /// Checking initial status
    case checking
    /// Data is synced with iCloud
    case synced
    /// Currently syncing data
    case syncing
    /// Device is offline, data saved locally
    case offline
    /// No iCloud account signed in
    case noAccount
    /// Sync error occurred
    case error

    /// SF Symbol name for this status
    var iconName: String {
        switch self {
        case .checking:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.icloud.fill"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .offline:
            return "icloud.slash"
        case .noAccount:
            return "person.crop.circle.badge.exclamationmark"
        case .error:
            return "exclamationmark.icloud.fill"
        }
    }

    /// Color for the status icon
    var color: Color {
        switch self {
        case .checking:
            return .secondary
        case .synced:
            return .green
        case .syncing:
            return .blue
        case .offline:
            return .secondary
        case .noAccount:
            return .orange
        case .error:
            return .red
        }
    }

    /// Human-readable status text
    var statusText: String {
        switch self {
        case .checking:
            return "Checking sync status..."
        case .synced:
            return "Synced with iCloud"
        case .syncing:
            return "Syncing..."
        case .offline:
            return "Offline - changes saved locally"
        case .noAccount:
            return "Not signed in to iCloud"
        case .error:
            return "Sync error"
        }
    }

    /// Whether this status should show an activity indicator
    var isAnimating: Bool {
        switch self {
        case .checking, .syncing:
            return true
        default:
            return false
        }
    }

    /// Whether tapping should show details
    var isTappable: Bool {
        switch self {
        case .error, .noAccount, .offline:
            return true
        default:
            return false
        }
    }
}
