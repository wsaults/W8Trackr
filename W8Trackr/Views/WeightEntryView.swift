//
//  WeightEntryView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftUI
import UIKit

struct WeightAdjustButton: View {
    let systemName: String
    let accessibilityLabel: String
    let accessibilityHint: String
    let action: () -> Void
    @ScaledMetric(relativeTo: .title) private var buttonIconSize: CGFloat = 44

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: buttonIconSize))
                .foregroundStyle(.blue)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

/// Unified view for adding new weight entries and editing existing ones.
/// Pass `existingEntry` to edit, or leave nil to add a new entry.
struct WeightEntryView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    var weightUnit: WeightUnit
    var entries: [WeightEntry]
    var existingEntry: WeightEntry?

    @State private var weight: Double
    @State private var date: Date
    @State private var note: String
    @State private var bodyFatPercentage: Double?
    @State private var includeBodyFat: Bool
    @State private var lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var mediumFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    @ScaledMetric(relativeTo: .largeTitle) private var weightFontSize: CGFloat = 64
    @ScaledMetric(relativeTo: .title) private var bodyFatFontSize: CGFloat = 32

    private var isEditing: Bool { existingEntry != nil }

    private var isValidWeight: Bool {
        weightUnit.isValidWeight(weight)
    }

    private var isValidBodyFat: Bool {
        guard includeBodyFat, let bf = bodyFatPercentage else { return true }
        return bf >= 1.0 && bf <= 60.0
    }

    private var validationMessage: String? {
        if !isValidWeight {
            return "Weight must be between \(weightUnit.minWeight.formatted()) and \(weightUnit.maxWeight.formatted()) \(weightUnit.rawValue)"
        }
        if !isValidBodyFat {
            return "Body fat must be between 1% and 60%"
        }
        return nil
    }

    private var isFormValid: Bool {
        isValidWeight && isValidBodyFat
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    init(
        entries: [WeightEntry],
        weightUnit: WeightUnit,
        existingEntry: WeightEntry? = nil
    ) {
        self.entries = entries
        self.weightUnit = weightUnit
        self.existingEntry = existingEntry

        if let entry = existingEntry {
            // Editing: initialize from existing entry
            _weight = State(initialValue: entry.weightValue(in: weightUnit))
            _date = State(initialValue: entry.date)
            _note = State(initialValue: entry.note ?? "")
            let hasBodyFat = entry.bodyFatPercentage != nil
            _includeBodyFat = State(initialValue: hasBodyFat)
            _bodyFatPercentage = State(initialValue: entry.bodyFatPercentage.map { NSDecimalNumber(decimal: $0).doubleValue })
        } else {
            // Adding: use most recent entry's weight as starting point
            let initialWeight = entries.first?.weightValue(in: weightUnit) ?? weightUnit.defaultWeight
            _weight = State(initialValue: initialWeight)
            _date = State(initialValue: Date())
            _note = State(initialValue: "")
            _includeBodyFat = State(initialValue: false)
            _bodyFatPercentage = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date section (picker when editing, static when adding)
                    if isEditing {
                        DatePicker(
                            "Date",
                            selection: $date,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                    } else {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }

                    // Weight input section
                    VStack(spacing: .zero) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            TextField("Weight", value: $weight, format: .number.precision(.fractionLength(1)))
                                .font(.system(size: weightFontSize, weight: .medium))
                                .keyboardType(.decimalPad)
                                .fixedSize()
                                .multilineTextAlignment(.trailing)

                            Text(weightUnit.rawValue)
                                .font(.title)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 40)
                        }

                        HStack(spacing: 40) {
                            WeightAdjustButton(
                                systemName: "backward.circle.fill",
                                accessibilityLabel: "Decrease by 1",
                                accessibilityHint: "Decreases weight by 1 \(weightUnit.rawValue)"
                            ) {
                                mediumFeedbackGenerator.impactOccurred()
                                weight = max(weightUnit.minWeight, weight - 1.0)
                            }

                            WeightAdjustButton(
                                systemName: "backward.end.circle.fill",
                                accessibilityLabel: "Decrease by 0.1",
                                accessibilityHint: "Decreases weight by 0.1 \(weightUnit.rawValue)"
                            ) {
                                lightFeedbackGenerator.impactOccurred()
                                weight = max(weightUnit.minWeight, weight - 0.1)
                            }

                            WeightAdjustButton(
                                systemName: "forward.end.circle.fill",
                                accessibilityLabel: "Increase by 0.1",
                                accessibilityHint: "Increases weight by 0.1 \(weightUnit.rawValue)"
                            ) {
                                lightFeedbackGenerator.impactOccurred()
                                weight = min(weightUnit.maxWeight, weight + 0.1)
                            }

                            WeightAdjustButton(
                                systemName: "forward.circle.fill",
                                accessibilityLabel: "Increase by 1",
                                accessibilityHint: "Increases weight by 1 \(weightUnit.rawValue)"
                            ) {
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

                    // Body fat section
                    VStack(spacing: 12) {
                        Toggle("Include Body Fat %", isOn: $includeBodyFat)
                            .tint(.blue)

                        if includeBodyFat {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                TextField("Body Fat", value: $bodyFatPercentage, format: .number.precision(.fractionLength(1)))
                                    .font(.system(size: bodyFatFontSize, weight: .medium))
                                    .keyboardType(.decimalPad)
                                    .fixedSize()
                                    .multilineTextAlignment(.trailing)

                                Text("%")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 40)

                    // Note section (always shown when editing, optional for add)
                    if isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            TextField("Add a note (optional)", text: $note, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                    }

                    // Timestamps section (only when editing)
                    if isEditing, let entry = existingEntry {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Created")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(Self.timestampFormatter.string(from: entry.date))
                            }
                            if let modifiedDate = entry.modifiedDate {
                                HStack {
                                    Text("Last Modified")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(Self.timestampFormatter.string(from: modifiedDate))
                                }
                            }
                        }
                        .font(.footnote)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)

                    // Save button
                    Button {
                        saveEntry()
                    } label: {
                        Text(isEditing ? "Save Changes" : "Save")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? .blue : .gray)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            .navigationTitle(isEditing ? "Edit Entry" : "Add Weight")
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

    private func saveEntry() {
        let bodyFat: Decimal? = includeBodyFat && bodyFatPercentage != nil
            ? Decimal(bodyFatPercentage!)
            : nil

        if let entry = existingEntry {
            // Update existing entry
            entry.weightValue = weight
            entry.weightUnit = weightUnit.rawValue
            entry.date = date
            entry.note = note.isEmpty ? nil : note
            entry.bodyFatPercentage = bodyFat
            entry.modifiedDate = Date()

            // Announce to VoiceOver
            let announcement = "Entry updated: \(weight.formatted(.number.precision(.fractionLength(1)))) \(weightUnit.rawValue)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        } else {
            // Create new entry
            let entry = WeightEntry(
                weight: weight,
                unit: weightUnit,
                bodyFatPercentage: bodyFat
            )
            modelContext.insert(entry)

            // Announce to VoiceOver
            let announcement = "Entry saved: \(weight.formatted(.number.precision(.fractionLength(1)))) \(weightUnit.rawValue)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }

        try? modelContext.save()

        // Sync to HealthKit
        HealthKitManager.shared.saveWeightEntry(
            weightInUnit: weight,
            unit: weightUnit,
            bodyFatPercentage: bodyFat,
            date: isEditing ? date : Date()
        )

        dismiss()
    }
}

#Preview("Add Mode") {
    WeightEntryView(entries: WeightEntry.sortedSampleData, weightUnit: .lb)
}

#Preview("Edit Mode") {
    WeightEntryView(
        entries: WeightEntry.sortedSampleData,
        weightUnit: .lb,
        existingEntry: WeightEntry(weight: 175.5, date: .now, note: "Morning weigh-in", bodyFatPercentage: 18.5)
    )
}
