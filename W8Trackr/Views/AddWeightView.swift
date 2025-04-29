//
//  AddWeightView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftUI

struct AddWeightView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Binding var weightUnit: WeightUnit
    
    var entries: [WeightEntry]
    
    @State private var weight: Double
    @State private var isEditing = false
    let today = Date()
    
    init(
        entries: [WeightEntry],
        weightUnit: Binding<WeightUnit>
    ) {
        self.entries = entries
        _weightUnit = weightUnit
        let unit = weightUnit.wrappedValue
        _weight = State(initialValue: entries.first?.weightValue ?? unit.defaultWeight)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                Text(today.formatted(date: .abbreviated, time: .omitted))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if isEditing {
                            TextField("Weight", value: $weight, format: .number.precision(.fractionLength(1)))
                                .font(.system(size: 64, weight: .medium))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 200)
                        } else {
                            Text(String(format: "%.1f", weight))
                                .font(.system(size: 64, weight: .medium))
                                .onTapGesture {
                                    isEditing = true
                                }
                        }
                        
                        Text(weightUnit.rawValue)
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 40) {
                        Button {
                            weight = max(0, weight - 0.1)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.blue)
                        }
                        
                        Button {
                            weight = min(500, weight + 0.1)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                
                Button {
                    let entry = WeightEntry(weight: weight, unit: UnitMass(symbol: weightUnit.rawValue))
                    modelContext.insert(entry)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Text("Save")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.top, 30)
            .navigationTitle("Add Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddWeightView(entries: WeightEntry.sortedSampleData, weightUnit: .constant(WeightUnit.lb))
}
