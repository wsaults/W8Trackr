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

    // Filter state - persists during session via @State
    @State private var showOnlyNotes = false
    @State private var showMilestones = false
    @State private var selectedDays: Set<Int> = []  // 1=Sunday, 2=Monday, ..., 7=Saturday

    private var hasActiveFilters: Bool {
        showOnlyNotes || showMilestones || !selectedDays.isEmpty
    }

    private var weekdayNames: [String] {
        Calendar.current.weekdaySymbols
    }

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
                    HistorySectionView(
                        entries: entries,
                        weightUnit: preferredWeightUnit,
                        showOnlyNotes: showOnlyNotes,
                        showMilestones: showMilestones,
                        selectedDays: selectedDays
                    ) { entry in
                        entryToEdit = entry
                    }
                }
            }
            .navigationTitle("Logbook")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        // Filter menu
                        Menu {
                            Toggle("With Notes", isOn: $showOnlyNotes)
                            Toggle("Milestones", isOn: $showMilestones)

                            Divider()

                            Menu("Day of Week") {
                                ForEach(1...7, id: \.self) { day in
                                    Toggle(weekdayNames[day - 1], isOn: Binding(
                                        get: { selectedDays.contains(day) },
                                        set: { isOn in
                                            if isOn {
                                                selectedDays.insert(day)
                                            } else {
                                                selectedDays.remove(day)
                                            }
                                        }
                                    ))
                                }

                                if !selectedDays.isEmpty {
                                    Divider()
                                    Button("Clear Days") {
                                        selectedDays.removeAll()
                                    }
                                }
                            }

                            if hasActiveFilters {
                                Divider()
                                Button("Clear All Filters", role: .destructive) {
                                    showOnlyNotes = false
                                    showMilestones = false
                                    selectedDays.removeAll()
                                }
                            }
                        } label: {
                            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        }
                        .accessibilityLabel("Filter logbook entries")
                        .accessibilityHint(hasActiveFilters ? "Filters are active. Tap to modify or clear filters." : "Show filter options")

                        // Add entry button
                        Button {
                            showingAddWeight = true
                        } label: {
                            Image(systemName: "plus")
                        }
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
