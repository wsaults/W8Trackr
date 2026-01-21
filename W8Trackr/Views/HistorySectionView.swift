//
//  HistorySectionView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftUI
import UIKit

struct HistorySectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthSyncManager.self) private var healthSyncManager
    let entries: [WeightEntry]
    let weightUnit: WeightUnit
    let showOnlyNotes: Bool
    let showMilestones: Bool
    let selectedDays: Set<Int>
    var onEdit: ((WeightEntry) -> Void)?

    @State private var pendingDeletes: [WeightEntry] = []
    @State private var showingUndoToast = false
    @State private var showDeleteError = false
    @State private var deleteTask: Task<Void, Never>?

    private static let undoTimeout: TimeInterval = 5

    // Milestone weights in 5-lb increments (common round numbers)
    private static let milestoneWeights: Set<Double> = [
        150, 155, 160, 165, 170, 175, 180, 185, 190, 195, 200,
        205, 210, 215, 220, 225, 230, 235, 240, 245, 250
    ]

    init(
        entries: [WeightEntry],
        weightUnit: WeightUnit,
        showOnlyNotes: Bool = false,
        showMilestones: Bool = false,
        selectedDays: Set<Int> = [],
        onEdit: ((WeightEntry) -> Void)? = nil
    ) {
        self.entries = entries
        self.weightUnit = weightUnit
        self.showOnlyNotes = showOnlyNotes
        self.showMilestones = showMilestones
        self.selectedDays = selectedDays
        self.onEdit = onEdit
    }

    private func isNearMilestone(_ weight: Double) -> Bool {
        Self.milestoneWeights.contains { milestone in
            abs(weight - milestone) < 0.5
        }
    }

    // MARK: - Computed Properties for Month Grouping

    private var filteredEntries: [WeightEntry] {
        var result = entries.filter { entry in
            !pendingDeletes.contains { $0.id == entry.id }
        }

        // Filter: Notes only
        if showOnlyNotes {
            result = result.filter { entry in
                if let note = entry.note {
                    return !note.trimmingCharacters(in: .whitespaces).isEmpty
                }
                return false
            }
        }

        // Filter: Milestones
        if showMilestones {
            result = result.filter { entry in
                isNearMilestone(entry.weightValue(in: weightUnit))
            }
        }

        // Filter: Day of Week
        if !selectedDays.isEmpty {
            result = result.filter { entry in
                let weekday = Calendar.current.component(.weekday, from: entry.date)
                return selectedDays.contains(weekday)
            }
        }

        return result
    }

    private var rowDataList: [LogbookRowData] {
        LogbookRowData.buildRowData(entries: filteredEntries, unit: weightUnit)
    }

    private var entriesByMonth: [Date: [LogbookRowData]] {
        Dictionary(grouping: rowDataList) { rowData in
            let components = Calendar.current.dateComponents([.year, .month], from: rowData.entry.date)
            return Calendar.current.date(from: components) ?? rowData.entry.date
        }
    }

    private var sortedMonths: [Date] {
        entriesByMonth.keys.sorted(by: >) // Newest first
    }

    private var undoMessage: String {
        let count = pendingDeletes.count
        return count == 1 ? "Entry deleted" : "\(count) entries deleted"
    }

    var body: some View {
        Group {
            if sortedMonths.isEmpty {
                ContentUnavailableView(
                    "No Matching Entries",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Try adjusting your filters")
                )
            } else {
                VStack(spacing: 0) {
                    LogbookHeaderView()

                    List {
                        ForEach(sortedMonths, id: \.self) { month in
                            Section {
                                ForEach(entriesByMonth[month] ?? []) { rowData in
                                    LogbookRowView(rowData: rowData, weightUnit: weightUnit) {
                                        onEdit?(rowData.entry)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            queueDelete(rowData.entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            onEdit?(rowData.entry)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(AppColors.primary)
                                    }
                                }
                            } header: {
                                Text(month, format: .dateTime.month(.wide).year())
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !filteredEntries.isEmpty {
                    EditButton()
                }
            }
        }
        .toast(
            isPresented: $showingUndoToast,
            message: undoMessage,
            systemImage: "trash",
            actionLabel: "Undo",
            duration: Self.undoTimeout
        ) {
            undoDelete()
        }
        .toast(isPresented: $showDeleteError, message: "Failed to delete entry", systemImage: "exclamationmark.triangle.fill")
        .onChange(of: showingUndoToast) { _, isShowing in
            if !isShowing && !pendingDeletes.isEmpty {
                commitDeletes()
            }
        }
    }

    private func queueDelete(_ entry: WeightEntry) {
        deleteTask?.cancel()

        withAnimation {
            pendingDeletes.append(entry)
            showingUndoToast = true
        }

        deleteTask = Task {
            try? await Task.sleep(for: .seconds(Self.undoTimeout))
            guard !Task.isCancelled else { return }
            withAnimation {
                showingUndoToast = false
            }
        }
    }

    private func undoDelete() {
        deleteTask?.cancel()
        deleteTask = nil

        withAnimation {
            pendingDeletes.removeAll()
            showingUndoToast = false
        }
    }

    private func commitDeletes() {
        let count = pendingDeletes.count
        let entriesToDelete = pendingDeletes

        // Delete from HealthKit first (async, non-blocking)
        if healthSyncManager.isHealthSyncEnabled {
            Task {
                for entry in entriesToDelete {
                    do {
                        try await healthSyncManager.deleteWeightFromHealth(entry: entry)
                    } catch {
                        // HealthKit delete error is non-blocking - local delete proceeds
                    }
                }
            }
        }

        // Delete from local storage
        for entry in entriesToDelete {
            modelContext.delete(entry)
        }
        do {
            try modelContext.save()
            // Announce to VoiceOver
            let announcement = count == 1 ? "Entry deleted" : "\(count) entries deleted"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        } catch {
            showDeleteError = true
        }

        pendingDeletes.removeAll()
        deleteTask = nil
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("Populated", traits: .modifier(EntriesPreview())) {
    NavigationStack {
        HistorySectionView(
            entries: WeightEntry.sortedSampleData,
            weightUnit: .lb
        ) { _ in }
        .navigationTitle("History")
    }
    .environment(HealthSyncManager())
}

@available(iOS 18, macOS 15, *)
#Preview("Empty", traits: .modifier(EmptyEntriesPreview())) {
    NavigationStack {
        HistorySectionView(
            entries: [],
            weightUnit: .lb
        )
        .navigationTitle("History")
    }
    .environment(HealthSyncManager())
}

@available(iOS 18, macOS 15, *)
#Preview("Single Entry", traits: .modifier(MinimalEntriesPreview())) {
    NavigationStack {
        HistorySectionView(
            entries: [WeightEntry(weight: 175.5)],
            weightUnit: .lb
        ) { _ in }
        .navigationTitle("History")
    }
    .environment(HealthSyncManager())
}

@available(iOS 18, macOS 15, *)
#Preview("Kilograms", traits: .modifier(EntriesPreview())) {
    NavigationStack {
        HistorySectionView(
            entries: WeightEntry.shortSampleData,
            weightUnit: .kg
        )
        .navigationTitle("History")
    }
    .environment(HealthSyncManager())
}

@available(iOS 18, macOS 15, *)
#Preview("With Notes Filter", traits: .modifier(EntriesPreview())) {
    NavigationStack {
        HistorySectionView(
            entries: WeightEntry.sortedSampleData,
            weightUnit: .lb,
            showOnlyNotes: true
        )
        .navigationTitle("History")
    }
    .environment(HealthSyncManager())
}

@available(iOS 18, macOS 15, *)
#Preview("Empty Filter Results", traits: .modifier(EntriesPreview())) {
    NavigationStack {
        HistorySectionView(
            entries: WeightEntry.sortedSampleData,
            weightUnit: .lb,
            showOnlyNotes: true,
            showMilestones: true
        )
        .navigationTitle("History")
    }
    .environment(HealthSyncManager())
}
#endif
