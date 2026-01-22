//
//  W8TrackrApp.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftData
import SwiftUI
import WidgetKit

@main
struct W8TrackrApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var healthSyncManager = HealthSyncManager()
    @State private var migrationManager = MigrationManager()

    /// Skip onboarding during UI tests to allow screenshot automation
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui_testing")
    }

    init() {
        // Check migration status synchronously at init
        // This just checks file existence, doesn't do actual migration
        migrationManager.checkMigrationNeeded()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding || isUITesting {
                    ContentView()
                } else {
                    OnboardingView {
                        // Callback when onboarding completes
                    }
                }
            }
            .task {
                // Perform migration in background if needed
                // App is usable while this runs
                if migrationManager.status == .pending {
                    await migrationManager.performMigration()
                }
            }
            .overlay {
                // Show migration status banner if failed (requires manual retry)
                if case .failed(let message) = migrationManager.status {
                    migrationFailedBanner(message: message)
                }
            }
        }
        .environment(healthSyncManager)
        .environment(migrationManager)
        .modelContainer(SharedModelContainer.sharedModelContainer)
    }

    @ViewBuilder
    private func migrationFailedBanner(message: String) -> some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Data Migration Failed")
                        .bold()
                }

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Retry Migration") {
                    Task {
                        await migrationManager.retryMigration()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }
}
