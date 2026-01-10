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

@available(iOS 18, macOS 15, *)
struct ContentViewPreview: PreviewModifier {
    var isEmpty: Bool = false

    static func makeSharedContext() async throws -> ModelContainer {
        try ModelContainer(
            for: WeightEntry.self, CompletedMilestone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func body(content: Content, context: ModelContainer) -> some View {
        if !isEmpty {
            // Populate with sample data
            let _ = {
                WeightEntry.shortSampleData.forEach { entry in
                    context.mainContext.insert(entry)
                }
                try? context.mainContext.save()
            }()
        }
        return content.modelContainer(context)
    }
}
#endif
