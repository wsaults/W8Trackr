//
//  EditWeightView.swift
//  W8Trackr
//
//  Created by Claude on 1/8/26.
//

import SwiftUI

struct EditWeightView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    let entry: WeightEntry
    var weightUnit: WeightUnit

    @State private var weight: Double
    @State private var date: Date
    @State private var note: String
    @State private var lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var mediumFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    private var isValidWeight: Bool {
        weightUnit.isValidWeight(weight)
    }

    private var validationMessage: String? {
        guard !isValidWeight else { return nil }
        return "Weight must be between \(weightUnit.minWeight.formatted()) and \(weightUnit.maxWeight.formatted()) \(weightUnit.rawValue)"
    }

    init(entry: WeightEntry, weightUnit: WeightUnit) {
        self.entry = entry
        self.weightUnit = weightUnit
        _weight = State(initialValue: entry.weightValue(in: weightUnit))
        _date = State(initialValue: entry.date)
        _note = State(initialValue: entry.note ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Date picker section
                DatePicker(
                    "Date",
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .padding(.horizontal)
                .padding(.top, 20)

                Spacer()

                // Weight section
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

                // Note section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    TextField("Add a note (optional)", text: $note, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                .padding(.horizontal)

                // Save button
                Button {
                    saveChanges()
                } label: {
                    Text("Save Changes")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidWeight ? .blue : .gray)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(!isValidWeight)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Edit Entry")
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

    private func saveChanges() {
        entry.weightValue = weight
        entry.weightUnit = weightUnit.rawValue
        entry.date = date
        entry.note = note.isEmpty ? nil : note
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    EditWeightView(
        entry: WeightEntry(weight: 175.5, date: .now, note: "Morning weigh-in"),
        weightUnit: .lb
    )
}
