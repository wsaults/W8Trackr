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
    
    @Query(
        sort: [SortDescriptor(\WeightEntry.date, order: .reverse)]
    ) private var entries: [WeightEntry]
    
    var body: some View {
        TabView {
            SummaryView(entries: entries, preferredWeightUnit: preferredWeightUnit, goalWeight: goalWeight)
                .tabItem {
                    Label("Summary", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            LogbookView(entries: entries, preferredWeightUnit: preferredWeightUnit, goalWeight: goalWeight)
                .tabItem {
                    Label("Logbook", systemImage: "book")
                }
            
            SettingsView(weightUnit: $preferredWeightUnit, goalWeight: $goalWeight)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            if entries.isEmpty {
                WeightEntry.initialData.forEach { entry in
                    modelContext.insert(entry)
                }
                try? modelContext.save()
            }
        }
    }
}
