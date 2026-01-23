//
//  ContentView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/29/25.
//

import SwiftData
import SwiftUI
import WidgetKit

/// Root view containing the main tab navigation.
///
/// ## Data Strategy
/// ContentView uses SwiftData queries for all data:
///
/// 1. **Live data** (`@Query`):
///    Uses SwiftData queries for real user data.
///    Sorted by date descending (newest first).
///
/// 2. **First launch seeding** (`WeightEntry.initialData`):
///    When entries are empty, seeds 5 sample entries.
///    Gives new users immediate data to explore the app.
///    A toast informs users they can delete and add their own entries.
///
/// 3. **Dev testing**: Use Settings > Developer Menu to load test datasets.
/// Tab destinations for programmatic navigation
enum TabDestination: Hashable {
    case dashboard
    case logbook
    case settings
    case addEntry
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("preferredWeightUnit") var preferredWeightUnit: WeightUnit = Locale.current.measurementSystem == .metric ? .kg : .lb
    @AppStorage("goalWeight") var goalWeight: Double = 170.0
    @AppStorage("showSmoothing") var showSmoothing: Bool = true
    @AppStorage("milestoneInterval") var milestoneInterval: MilestoneInterval = .five
    @State private var showingInitialDataToast = false
    @State private var showingSaveError = false
    @State private var selectedTab: TabDestination = .dashboard
    @State private var previousTab: TabDestination = .dashboard
    @State private var showAddWeightView = false

    // MARK: - Data Sources
    // Always use live SwiftData queries - use Developer Menu to load test data
    @Query(
        sort: [SortDescriptor(\WeightEntry.date, order: .reverse)]
    ) private var entries: [WeightEntry]
    @Query(
        sort: [SortDescriptor(\CompletedMilestone.achievedDate, order: .reverse)]
    ) private var completedMilestones: [CompletedMilestone]

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent", value: .dashboard) {
                DashboardView(
                    selectedTab: $selectedTab,
                    entries: entries,
                    completedMilestones: completedMilestones,
                    preferredWeightUnit: preferredWeightUnit,
                    goalWeight: goalWeight,
                    showSmoothing: showSmoothing,
                    milestoneInterval: milestoneInterval
                )
            }

            Tab("Logbook", systemImage: "book", value: .logbook) {
                LogbookView(entries: entries, preferredWeightUnit: preferredWeightUnit, goalWeight: goalWeight)
            }

            Tab("Settings", systemImage: "gear", value: .settings) {
                SettingsView(
                    weightUnit: $preferredWeightUnit,
                    goalWeight: $goalWeight,
                    showSmoothing: $showSmoothing,
                    milestoneInterval: $milestoneInterval
                )
            }

            // Trailing "+" button using search role for inline positioning
            // Content is empty - we intercept selection and show a sheet instead
            Tab("Add", systemImage: "plus", value: .addEntry, role: .search) {
                Color.clear
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .addEntry {
                // Store the previous tab and show the sheet
                previousTab = oldValue
                showAddWeightView = true
                // Reset to previous tab so the + button doesn't stay selected
                selectedTab = oldValue
            }
        }
        .sheet(isPresented: $showAddWeightView) {
            WeightEntryView(entries: entries, weightUnit: preferredWeightUnit)
        }
        .onAppear {
            // Validate goal weight on first launch or after unit change
            // Handles the case where default 170.0 is invalid for metric users
            if !preferredWeightUnit.isValidGoalWeight(goalWeight) {
                goalWeight = preferredWeightUnit.defaultWeight
            }

            if entries.isEmpty {
                WeightEntry.initialData.forEach { entry in
                    modelContext.insert(entry)
                }
                do {
                    try modelContext.save()
                    withAnimation {
                        showingInitialDataToast = true
                    }
                } catch {
                    showingSaveError = true
                }
            }
        }
        .toast(
            isPresented: $showingInitialDataToast,
            message: "Sample data added. Feel free to delete and add your own entries!",
            systemImage: "info.circle"
        )
        .toast(isPresented: $showingSaveError, message: "Failed to save initial data", systemImage: "exclamationmark.triangle.fill")
        .onChange(of: goalWeight) { _, newValue in
            // Sync to App Group UserDefaults for widget access
            SharedModelContainer.sharedDefaults?.set(newValue, forKey: "goalWeight")
        }
        .onChange(of: preferredWeightUnit) { _, newValue in
            // Sync to App Group UserDefaults for widget access
            SharedModelContainer.sharedDefaults?.set(newValue.rawValue, forKey: "preferredWeightUnit")
        }
        .task {
            // Sync current values to shared defaults on launch for existing users
            SharedModelContainer.sharedDefaults?.set(goalWeight, forKey: "goalWeight")
            SharedModelContainer.sharedDefaults?.set(preferredWeightUnit.rawValue, forKey: "preferredWeightUnit")
            // Refresh widgets to pick up synced values
            WidgetCenter.shared.reloadTimelines(ofKind: "WeightWidget")
        }
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
