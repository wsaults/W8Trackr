//
//  ContentView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/29/25.
//

import SwiftData
import SwiftUI

/// Root view containing the main tab navigation.
///
/// ## Data Strategy
/// ContentView uses three different data sources depending on context:
///
/// 1. **Simulator builds** (`#if targetEnvironment(simulator)`):
///    Uses `WeightEntry.shortSampleData` - 14 entries over 2 weeks.
///    Provides consistent preview data without database dependencies.
///
/// 2. **Device builds** (`@Query`):
///    Uses live SwiftData queries for real user data.
///    Sorted by date descending (newest first).
///
/// 3. **First launch seeding** (`WeightEntry.initialData`):
///    When entries are empty on device, seeds 5 sample entries.
///    Gives new users immediate data to explore the app.
///    A toast informs users they can delete and add their own entries.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("preferredWeightUnit") var preferredWeightUnit: WeightUnit = Locale.current.measurementSystem == .metric ? .kg : .lb
    @AppStorage("goalWeight") var goalWeight: Double = 170.0
    @AppStorage("showSmoothing") var showSmoothing: Bool = true
    @State private var showingInitialDataToast = false

    // MARK: - Data Sources
    // Simulator: Static sample data for consistent previews
    // Device: Live SwiftData queries for real user data
    #if targetEnvironment(simulator)
    private var entries: [WeightEntry] = WeightEntry.shortSampleData
    private var completedMilestones: [CompletedMilestone] = []
    #else
    @Query(
        sort: [SortDescriptor(\WeightEntry.date, order: .reverse)]
    ) private var entries: [WeightEntry]
    @Query(
        sort: [SortDescriptor(\CompletedMilestone.achievedDate, order: .reverse)]
    ) private var completedMilestones: [CompletedMilestone]
    #endif

    var body: some View {
        TabView {
            DashboardView(
                entries: entries,
                completedMilestones: completedMilestones,
                preferredWeightUnit: preferredWeightUnit,
                goalWeight: goalWeight,
                showSmoothing: showSmoothing
            )
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent")
                }
            
            LogbookView(entries: entries, preferredWeightUnit: preferredWeightUnit, goalWeight: goalWeight)
                .tabItem {
                    Label("Logbook", systemImage: "book")
                }
            
            SettingsView(weightUnit: $preferredWeightUnit, goalWeight: $goalWeight, showSmoothing: $showSmoothing)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            // Validate and sanitize stored goal weight for current unit
            if !preferredWeightUnit.isValidGoalWeight(goalWeight) {
                goalWeight = min(max(goalWeight, preferredWeightUnit.minGoalWeight), preferredWeightUnit.maxGoalWeight)
            }

            if entries.isEmpty {
                WeightEntry.initialData.forEach { entry in
                    modelContext.insert(entry)
                }
                try? modelContext.save()
                withAnimation {
                    showingInitialDataToast = true
                }
            }
        }
        .toast(
            isPresented: $showingInitialDataToast,
            message: "Sample data added. Feel free to delete and add your own entries!",
            systemImage: "info.circle"
        )
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("Populated", traits: .modifier(ContentViewPreview())) {
    ContentView()
}

@available(iOS 18, macOS 15, *)
#Preview("Empty", traits: .modifier(ContentViewPreview(isEmpty: true))) {
    ContentView()
}
#endif
