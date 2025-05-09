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
    
    var weightUnit: WeightUnit
    
    var entries: [WeightEntry]
    
    @State private var weight: Double
    let today = Date()
    
    init(
        entries: [WeightEntry],
        weightUnit: WeightUnit
    ) {
        self.entries = entries
        self.weightUnit = weightUnit
        
        // Convert the initial weight to the current unit
        let initialWeight = entries.first?.weightValue(in: weightUnit) ?? weightUnit.defaultWeight
        _weight = State(initialValue: initialWeight)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                Text(today.formatted(date: .abbreviated, time: .omitted))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: .zero) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField("Weight", value: $weight, format: .number.precision(.fractionLength(1)))
                            .font(.system(size: 64, weight: .medium))
                            .keyboardType(.decimalPad)
                            .fixedSize()
                            .multilineTextAlignment(.trailing)
                        
                        Text(weightUnit.rawValue)
                            .font(.title)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 40)
                    }
                    
                    HStack(spacing: 40) {
                        Button {
                            weight = max(0, weight - 1.0)
                        } label: {
                            Image(systemName: "backward.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.blue)
                        }
                        
                        Button {
                            weight = max(0, weight - 0.1)
                        } label: {
                            Image(systemName: "backward.end.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.blue)
                        }
                        
                        Button {
                            weight = min(500, weight + 0.1)
                        } label: {
                            Image(systemName: "forward.end.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.blue)
                        }
                        
                        Button {
                            weight = min(500, weight + 1.0)
                        } label: {
                            Image(systemName: "forward.circle.fill")
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
    AddWeightView(entries: WeightEntry.sortedSampleData, weightUnit: .lb)
}
