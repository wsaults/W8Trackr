//
//  AddWeightView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftUI

struct WeightAdjustButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 44))
                .foregroundStyle(.blue)
        }
    }
}

struct AddWeightView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    var weightUnit: WeightUnit

    var entries: [WeightEntry]

    @State private var weight: Double
    @State private var lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var mediumFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    let today = Date()

    private var isValidWeight: Bool {
        weightUnit.isValidWeight(weight)
    }

    private var validationMessage: String? {
        guard !isValidWeight else { return nil }
        return "Weight must be between \(weightUnit.minWeight.formatted()) and \(weightUnit.maxWeight.formatted()) \(weightUnit.rawValue)"
    }

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
                        WeightAdjustButton(systemName: "backward.circle.fill") {
                            mediumFeedbackGenerator.impactOccurred()
                            weight = max(weightUnit.minWeight, weight - 1.0)
                        }

                        WeightAdjustButton(systemName: "backward.end.circle.fill") {
                            lightFeedbackGenerator.impactOccurred()
                            weight = max(weightUnit.minWeight, weight - 0.1)
                        }

                        WeightAdjustButton(systemName: "forward.end.circle.fill") {
                            lightFeedbackGenerator.impactOccurred()
                            weight = min(weightUnit.maxWeight, weight + 0.1)
                        }

                        WeightAdjustButton(systemName: "forward.circle.fill") {
                            mediumFeedbackGenerator.impactOccurred()
                            weight = min(weightUnit.maxWeight, weight + 1.0)
                        }
                    }
                    .padding(.top, 20)

                    if let message = validationMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.top, 8)
                    }
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
                        .background(isValidWeight ? .blue : .gray)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(!isValidWeight)
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
