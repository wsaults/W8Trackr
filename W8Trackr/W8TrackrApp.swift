//
//  W8TrackrApp.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftData
import SwiftUI

@main
struct W8TrackrApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var healthSyncManager = HealthSyncManager()

    /// Skip onboarding during UI tests to allow screenshot automation
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui_testing")
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding || isUITesting {
                ContentView()
            } else {
                OnboardingView {
                    // Callback when onboarding completes
                }
            }
        }
        .environmentObject(healthSyncManager)
        .modelContainer(for: [WeightEntry.self, CompletedMilestone.self, MilestoneAchievement.self])
    }
}
