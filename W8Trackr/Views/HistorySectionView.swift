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
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }()
    
    var body: some View {
        List {
            ForEach(entries) { entry in
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
                        deleteEntry(entry)
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
                    deleteEntry(entries[index])
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !entries.isEmpty {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteEntry(_ entry: WeightEntry) {
        withAnimation {
            modelContext.delete(entry)
            try? modelContext.save()
        }
    }
}

#Preview {
    HistorySectionView(entries: WeightEntry.sortedSampleData, weightUnit: .lb)
}
