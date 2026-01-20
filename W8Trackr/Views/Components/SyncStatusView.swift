//
//  SyncStatusView.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import SwiftUI

/// A subtle sync status indicator for the navigation bar
///
/// Displays iCloud sync status with appropriate icons:
/// - Synced: green checkmark cloud
/// - Syncing: animated blue cloud
/// - Offline: gray slashed cloud
/// - Error: red warning cloud (tappable for details)
/// - No account: orange person icon (tappable for details)
struct SyncStatusView: View {
    private var syncManager: CloudKitSyncManager { CloudKitSyncManager.shared }
    @State private var showingDetails = false

    var body: some View {
        Button {
            if syncManager.status.isTappable {
                showingDetails = true
            }
        } label: {
            statusIcon
        }
        .buttonStyle(.plain)
        .disabled(!syncManager.status.isTappable)
        .accessibilityLabel(syncManager.status.statusText)
        .accessibilityHint(syncManager.status.isTappable ? "Tap for more details" : "")
        .alert("Sync Status", isPresented: $showingDetails) {
            if syncManager.status == .noAccount {
                Button("Open Settings") {
                    openSettings()
                }
                Button("OK", role: .cancel) { }
            } else {
                Button("Retry") {
                    syncManager.refresh()
                }
                Button("OK", role: .cancel) { }
            }
        } message: {
            if let errorMessage = syncManager.errorMessage {
                Text(errorMessage)
            } else {
                Text(syncManager.status.statusText)
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if syncManager.status.isAnimating {
            Image(systemName: syncManager.status.iconName)
                .foregroundStyle(syncManager.status.color)
                .symbolEffect(.pulse, options: .repeating)
        } else {
            Image(systemName: syncManager.status.iconName)
                .foregroundStyle(syncManager.status.color)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Toolbar Modifier

extension View {
    /// Adds sync status indicator to the navigation bar
    func syncStatusToolbar() -> some View {
        self.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SyncStatusView()
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Synced") {
    NavigationStack {
        Text("Content")
            .navigationTitle("Preview")
            .syncStatusToolbar()
    }
}

#Preview("All States") {
    VStack(spacing: 20) {
        ForEach([
            CloudSyncStatus.synced,
            .syncing,
            .offline,
            .noAccount,
            .error,
            .checking
        ], id: \.statusText) { status in
            HStack {
                Image(systemName: status.iconName)
                    .foregroundStyle(status.color)
                Text(status.statusText)
                    .font(.caption)
            }
        }
    }
    .padding()
}
#endif
