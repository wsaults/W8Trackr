//
//  ContentView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/29/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("preferredWeightUnit") var preferredWeightUnit: WeightUnit = Locale.current.measurementSystem == .metric ? .kg : .lb
    @AppStorage("goalWeight") var goalWeight: Double = 170.0
    @AppStorage("showSmoothing") var showSmoothing: Bool = true
    @State private var showingInitialDataToast = false
    @State private var showingSaveError = false

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
            SummaryView(
                entries: entries,
                completedMilestones: completedMilestones,
                preferredWeightUnit: preferredWeightUnit,
                goalWeight: goalWeight,
                showSmoothing: showSmoothing
            )
                .tabItem {
                    Label("Summary", systemImage: "chart.line.uptrend.xyaxis")
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
        .errorToast(isPresented: $showingSaveError, message: "Failed to save initial data")
    }
}
