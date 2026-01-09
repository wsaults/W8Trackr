//
//  HistorySectionView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftUI

struct HistorySectionView: View {
    @Environment(\.modelContext) private var modelContext
    let entries: [WeightEntry]
    let weightUnit: WeightUnit
    var onEdit: ((WeightEntry) -> Void)?

    @State private var pendingDeletes: [WeightEntry] = []
    @State private var showingUndoToast = false
    @State private var deleteWorkItem: DispatchWorkItem?

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
        .onChange(of: showingUndoToast) { _, isShowing in
            if !isShowing && !pendingDeletes.isEmpty {
                commitDeletes()
            }
        }
    }

    private func queueDelete(_ entry: WeightEntry) {
        deleteWorkItem?.cancel()

        withAnimation {
            pendingDeletes.append(entry)
            showingUndoToast = true
        }

        let workItem = DispatchWorkItem { [self] in
            withAnimation {
                showingUndoToast = false
            }
        }
        deleteWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.undoTimeout, execute: workItem)
    }

    private func undoDelete() {
        deleteWorkItem?.cancel()
        deleteWorkItem = nil

        withAnimation {
            pendingDeletes.removeAll()
            showingUndoToast = false
        }
    }

    private func commitDeletes() {
        for entry in pendingDeletes {
            modelContext.delete(entry)
        }
        try? modelContext.save()
        pendingDeletes.removeAll()
        deleteWorkItem = nil
    }
}

#Preview {
    HistorySectionView(entries: WeightEntry.sortedSampleData, weightUnit: .lb)
}
