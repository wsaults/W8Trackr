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
    @Query(
        sort: [SortDescriptor(\WeightEntry.date, order: .reverse)]
    ) private var entries: [WeightEntry]
    
    @AppStorage("preferredWeightUnit") var preferredWeightUnit: WeightUnit = Locale.current.measurementSystem == .metric ? .kg : .lb
    @AppStorage("goalWeight") var goalWeight: Double = .zero
    
    var body: some Scene {
        WindowGroup {
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
        }
        .modelContainer(for: [WeightEntry.self])
    }
}
