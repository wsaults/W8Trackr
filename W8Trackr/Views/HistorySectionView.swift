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
    @EnvironmentObject private var healthSyncManager: HealthSyncManager
    let entries: [WeightEntry]
    let weightUnit: WeightUnit
    var onEdit: ((WeightEntry) -> Void)?

    @State private var pendingDeletes: [WeightEntry] = []
    @State private var showingUndoToast = false
    @State private var showDeleteError = false
    @State private var deleteTask: Task<Void, Never>?

    private static let undoTimeout: TimeInterval = 5

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }()

    private var visibleEntries: [WeightEntry] {
        entries.filter { entry in
            !pendingDeletes.contains { $0.id == entry.id }
        }
    }

    private var undoMessage: String {
        let count = pendingDeletes.count
        return count == 1 ? "Entry deleted" : "\(count) entries deleted"
    }

    private func accessibilityLabel(for entry: WeightEntry) -> String {
        let dateStr = Self.dateFormatter.string(from: entry.date)
        let weightStr = entry.weightValue(in: weightUnit).formatted(.number.precision(.fractionLength(1)))
        var label = "\(dateStr), \(weightStr) \(weightUnit.rawValue)"
        if let bodyFat = entry.bodyFatPercentage {
            let bodyFatValue = NSDecimalNumber(decimal: bodyFat).doubleValue
            label += ", \(bodyFatValue.formatted(.number.precision(.fractionLength(1)))) percent body fat"
        }
        return label
    }

    var body: some View {
        List {
            ForEach(visibleEntries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.date, formatter: Self.dateFormatter)
                        if let bodyFat = entry.bodyFatPercentage {
                            Text("\(NSDecimalNumber(decimal: bodyFat).doubleValue, specifier: "%.1f")% body fat")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text(
                            entry.weightValue(in: weightUnit),
                            format: .number.precision(.fractionLength(1))
                        )
                        .fontWeight(.bold)

                        Text(weightUnit.rawValue)
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: entry))
                .accessibilityHint("Swipe right to edit, swipe left to delete")
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    onEdit?(entry)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        queueDelete(entry)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        onEdit?(entry)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    queueDelete(visibleEntries[index])
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !visibleEntries.isEmpty {
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
                        // Log error but don't block local delete
                        print("HealthKit delete failed for entry \(entry.id): \(error)")
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
        ) { entry in
            print("Edit: \(entry.id)")
        }
        .navigationTitle("History")
    }
    .environmentObject(HealthSyncManager())
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
    .environmentObject(HealthSyncManager())
}

@available(iOS 18, macOS 15, *)
#Preview("Single Entry", traits: .modifier(MinimalEntriesPreview())) {
    NavigationStack {
        HistorySectionView(
            entries: [WeightEntry(weight: 175.5)],
            weightUnit: .lb
        ) { entry in
            print("Edit: \(entry.id)")
        }
        .navigationTitle("History")
    }
    .environmentObject(HealthSyncManager())
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
    .environmentObject(HealthSyncManager())
}
#endif
