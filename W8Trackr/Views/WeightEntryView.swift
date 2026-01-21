//
//  WeightEntryView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftUI

/// Unified view for adding new weight entries and editing existing ones.
/// Pass `existingEntry` to edit, or leave nil to add a new entry.
struct WeightEntryView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    var weightUnit: WeightUnit
    var entries: [WeightEntry]
    var existingEntry: WeightEntry?

    // MARK: - Focus State
    enum EntryField: Hashable { case weight, notes, bodyFat }
    @FocusState private var focusedField: EntryField?

    // MARK: - Form State
    @State private var weight: Double
    @State private var date: Date
    @State private var note: String
    @State private var bodyFatPercentage: Double?
    @State private var showMoreFields = false
    @State private var showDiscardAlert = false
    @State private var showingSaveError = false

    // MARK: - Scaled Metrics
    @ScaledMetric(relativeTo: .largeTitle) private var weightFontSize: CGFloat = 64
    @ScaledMetric(relativeTo: .title) private var bodyFatFontSize: CGFloat = 32

    // MARK: - Initial Values for Change Detection
    private let initialWeight: Double
    private let initialNote: String
    private let initialDate: Date
    private let initialBodyFat: Double?

    // MARK: - Constants
    private let noteCharacterLimit = 500

    // MARK: - Computed Properties
    private var isEditing: Bool { existingEntry != nil }

    private var isValidWeight: Bool {
        weightUnit.isValidWeight(weight)
    }

    private var isValidBodyFat: Bool {
        guard showMoreFields, let bf = bodyFatPercentage else { return true }
        return bf >= 1.0 && bf <= 60.0
    }

    private var isFormValid: Bool {
        isValidWeight && isValidBodyFat
    }

    private var charactersRemaining: Int {
        noteCharacterLimit - note.count
    }

    private var canNavigateForward: Bool {
        !Calendar.current.isDateInToday(date)
    }

    private var hasUnsavedChanges: Bool {
        // Round to 1 decimal place to avoid floating point comparison issues
        let weightChanged = (weight * 10).rounded() != (initialWeight * 10).rounded()
        let noteChanged = note != initialNote
        let dateChanged = !Calendar.current.isDate(date, inSameDayAs: initialDate)
        let bodyFatChanged: Bool = {
            switch (bodyFatPercentage, initialBodyFat) {
            case (.none, .none): return false
            case (.some, .none), (.none, .some): return true
            case let (.some(currentValue), .some(initialValue)):
                return (currentValue * 10).rounded() != (initialValue * 10).rounded()
            }
        }()
        return weightChanged || noteChanged || dateChanged || bodyFatChanged
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Initialization
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
            let entryWeight = entry.weightValue(in: weightUnit)
            let entryNote = entry.note ?? ""
            let entryBodyFat = entry.bodyFatPercentage.map { NSDecimalNumber(decimal: $0).doubleValue }

            _weight = State(initialValue: entryWeight)
            _date = State(initialValue: entry.date)
            _note = State(initialValue: entryNote)
            _bodyFatPercentage = State(initialValue: entryBodyFat)
            _showMoreFields = State(initialValue: entryBodyFat != nil)

            self.initialWeight = entryWeight
            self.initialNote = entryNote
            self.initialDate = entry.date
            self.initialBodyFat = entryBodyFat
        } else {
            // Adding: use most recent entry's weight as starting point
            let startWeight = entries.first?.weightValue(in: weightUnit) ?? weightUnit.defaultWeight
            let currentDate = Date()

            _weight = State(initialValue: startWeight)
            _date = State(initialValue: currentDate)
            _note = State(initialValue: "")
            _bodyFatPercentage = State(initialValue: nil)
            _showMoreFields = State(initialValue: false)

            self.initialWeight = startWeight
            self.initialNote = ""
            self.initialDate = currentDate
            self.initialBodyFat = nil
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date section
                    dateSection

                    // Weight input section
                    weightSection

                    // Notes section (always visible)
                    notesSection

                    // More... expandable section for body fat
                    moreFieldsSection

                    // Timestamps section (only when editing)
                    if isEditing, let entry = existingEntry {
                        timestampsSection(for: entry)
                    }

                    Spacer(minLength: 20)

                    // Save button
                    saveButton
                }
                .padding(.top, 20)
            }
            .navigationTitle(isEditing ? "Edit Entry" : "Add Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Unable to Save", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your weight entry couldn't be saved. Please try again.")
            }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes that will be lost.")
            }
            .interactiveDismissDisabled(hasUnsavedChanges)
            .task {
                // Only auto-focus weight for new entries
                if !isEditing {
                    focusedField = .weight
                }
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var dateSection: some View {
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
            HStack {
                Button {
                    if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: date) {
                        date = newDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }

                Text(date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.headline)
                    .frame(maxWidth: .infinity)

                Button {
                    if canNavigateForward,
                       let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date) {
                        date = newDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
                .disabled(!canNavigateForward)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("Weight", value: $weight, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: weightFontSize, weight: .medium))
                    .keyboardType(.decimalPad)
                    .fixedSize()
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .weight)

                Text(weightUnit.rawValue)
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(.secondary)

            TextField("Add a note (optional)", text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .focused($focusedField, equals: .notes)
                .onChange(of: note) { _, newValue in
                    if newValue.count > noteCharacterLimit {
                        note = String(newValue.prefix(noteCharacterLimit))
                    }
                }

            if charactersRemaining < 50 {
                Text("\(charactersRemaining) characters remaining")
                    .font(.caption)
                    .foregroundStyle(charactersRemaining < 10 ? .red : .secondary)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var moreFieldsSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    showMoreFields.toggle()
                    if showMoreFields && bodyFatPercentage == nil {
                        bodyFatPercentage = 20.0  // Default when expanding
                    }
                }
            } label: {
                HStack {
                    Text(showMoreFields ? "Less..." : "More...")
                    Image(systemName: showMoreFields ? "chevron.up" : "chevron.down")
                }
                .font(.subheadline)
                .foregroundStyle(AppColors.primary)
            }

            if showMoreFields {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Body Fat %")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField(
                            "Body Fat",
                            value: $bodyFatPercentage,
                            format: .number.precision(.fractionLength(1))
                        )
                        .font(.system(size: bodyFatFontSize, weight: .medium))
                        .keyboardType(.decimalPad)
                        .fixedSize()
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .bodyFat)

                        Text("%")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func timestampsSection(for entry: WeightEntry) -> some View {
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
        .clipShape(.rect(cornerRadius: 8))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var saveButton: some View {
        Button {
            saveEntry()
        } label: {
            Text(isEditing ? "Save Changes" : "Save")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? AppColors.primary : AppColors.surfaceSecondary)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 10))
        }
        .disabled(!isFormValid)
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func saveEntry() {
        let bodyFat: Decimal? = showMoreFields && bodyFatPercentage != nil
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
                date: date,
                bodyFatPercentage: bodyFat
            )
            entry.note = note.isEmpty ? nil : note
            modelContext.insert(entry)

            // Announce to VoiceOver
            let announcement = "Entry saved: \(weight.formatted(.number.precision(.fractionLength(1)))) \(weightUnit.rawValue)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }

        do {
            try modelContext.save()
        } catch {
            showingSaveError = true
            return
        }

        // Sync to HealthKit (only after successful save)
        if let entry = existingEntry {
            // Update existing entry in Health
            Task {
                try? await HealthSyncManager.shared.updateWeightInHealth(entry: entry)
            }
        } else {
            // For new entries, find the just-saved entry and sync it
            // Note: The legacy HealthKitManager is still used for new entries until
            // the full migration to HealthSyncManager is complete (T024)
            Task {
                _ = await HealthKitManager.shared.saveWeightEntry(
                    weightInUnit: weight,
                    unit: weightUnit,
                    bodyFatPercentage: bodyFat,
                    date: date
                )
            }
        }

        dismiss()
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("Add Mode (lb)", traits: .modifier(EntriesPreview())) {
    WeightEntryView(
        entries: WeightEntry.sortedSampleData,
        weightUnit: .lb
    )
}

@available(iOS 18, macOS 15, *)
#Preview("Add Mode (kg)", traits: .modifier(EntriesPreview())) {
    WeightEntryView(
        entries: WeightEntry.sortedSampleData,
        weightUnit: .kg
    )
}

@available(iOS 18, macOS 15, *)
#Preview("Edit Mode", traits: .modifier(EntriesPreview())) {
    WeightEntryView(
        entries: WeightEntry.sortedSampleData,
        weightUnit: .lb,
        existingEntry: WeightEntry(
            weight: 175.5,
            date: .now,
            note: "Morning weigh-in",
            bodyFatPercentage: 18.5
        )
    )
}

@available(iOS 18, macOS 15, *)
#Preview("Min Boundary (lb)", traits: .modifier(EmptyEntriesPreview())) {
    WeightEntryView(
        entries: [WeightEntry(weight: WeightUnit.lb.minWeight + 5)],
        weightUnit: .lb
    )
}

@available(iOS 18, macOS 15, *)
#Preview("Max Boundary (lb)", traits: .modifier(EmptyEntriesPreview())) {
    WeightEntryView(
        entries: [WeightEntry(weight: WeightUnit.lb.maxWeight - 50)],
        weightUnit: .lb
    )
}

@available(iOS 18, macOS 15, *)
#Preview("Empty Entries", traits: .modifier(EmptyEntriesPreview())) {
    WeightEntryView(
        entries: [],
        weightUnit: .lb
    )
}
#endif
