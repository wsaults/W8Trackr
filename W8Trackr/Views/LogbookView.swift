//
//  LogbookView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/29/25.
//

import SwiftUI
import SwiftData

struct LogbookView: View {
    var entries: [WeightEntry]
    var preferredWeightUnit: WeightUnit
    var goalWeight: Double
    @State private var showingAddWeight = false
    @State private var entryToEdit: WeightEntry?
    
    var body: some View {
        NavigationStack {
            VStack {
                if entries.isEmpty {
                    EmptyStateView(
                        illustration: .emptyLogbook,
                        title: "Your Logbook Awaits",
                        description: "Every journey starts with a single step. Add your first entry to begin tracking.",
                        actionTitle: "Add Entry",
                        action: { showingAddWeight = true }
                    )
                } else {
                    HistorySectionView(entries: entries, weightUnit: preferredWeightUnit) { entry in
                        entryToEdit = entry
                    }
                }
            }
            .navigationTitle("Logbook")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SyncStatusView()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddWeight = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWeight) {
                WeightEntryView(entries: entries, weightUnit: preferredWeightUnit)
            }
            .sheet(item: $entryToEdit) { entry in
                WeightEntryView(entries: entries, weightUnit: preferredWeightUnit, existingEntry: entry)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("Populated", traits: .modifier(EntriesPreview())) {
    LogbookView(
        entries: WeightEntry.sortedSampleData,
        preferredWeightUnit: .lb,
        goalWeight: 160
    )
}

@available(iOS 18, macOS 15, *)
#Preview("Empty", traits: .modifier(EmptyEntriesPreview())) {
    LogbookView(
        entries: [],
        preferredWeightUnit: .lb,
        goalWeight: 160
    )
}
#endif
