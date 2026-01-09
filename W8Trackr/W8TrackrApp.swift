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

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView {
                    // Callback when onboarding completes
                }
            }
        }
        .modelContainer(for: [WeightEntry.self])
    }
}
