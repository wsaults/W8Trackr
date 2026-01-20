//
//  DevMenuView.swift
//  W8Trackr
//
//  Developer tools for testing with different data scenarios.
//  Only available in DEBUG builds.
//

#if DEBUG
import SwiftUI
import SwiftData

struct DevMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var customWeight: Double = 175.0
    @State private var customDate: Date = .now
    @State private var showingSuccessToast = false
    @State private var toastMessage = ""

    enum DatasetOption: String, CaseIterable, Identifiable {
        case empty = "New User (No Data)"
        case oneWeek = "1 Week of Data"
        case threeWeeks = "3 Weeks of Data"
        case threeMonths = "3 Months of Data"
        case sixMonths = "6 Months of Data"
        case elevenMonths = "11 Months of Data"
        case eighteenMonths = "1.5 Years of Data"

        var id: String { rawValue }

        var entryCount: Int {
            switch self {
            case .empty: return 0
            case .oneWeek: return 7
            case .threeWeeks: return 21
            case .threeMonths: return 45
            case .sixMonths: return 90
            case .elevenMonths: return 165
            case .eighteenMonths: return 270
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                datasetSection
                addEntrySection
            }
            .navigationTitle("Developer Menu")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .toast(isPresented: $showingSuccessToast, message: toastMessage, systemImage: "checkmark.circle.fill")
        }
    }

    private var datasetSection: some View {
        Section {
            ForEach(DatasetOption.allCases) { option in
                Button {
                    replaceWithDataset(option)
                } label: {
                    HStack {
                        Text(option.rawValue)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(option.entryCount) entries")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Replace Dataset")
        } footer: {
            Text("Instantly replaces all data with sample entries.")
        }
    }

    private var addEntrySection: some View {
        Section {
            DatePicker("Date", selection: $customDate, displayedComponents: [.date])

            HStack {
                Text("Weight")
                Spacer()
                TextField("Weight", value: $customWeight, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("lb")
                    .foregroundStyle(.secondary)
            }

            Button("Add Entry") {
                addCustomEntry()
            }
        } header: {
            Text("Add Custom Entry")
        } footer: {
            Text("Quickly add a weight entry for any date.")
        }
    }

    private func replaceWithDataset(_ option: DatasetOption) {
        do {
            // Clear all existing entries first
            let existingEntries = try modelContext.fetch(FetchDescriptor<WeightEntry>())
            for entry in existingEntries {
                modelContext.delete(entry)
            }

            // Also clear completed milestones for clean testing
            let existingMilestones = try modelContext.fetch(FetchDescriptor<CompletedMilestone>())
            for milestone in existingMilestones {
                modelContext.delete(milestone)
            }

            // Generate and insert new entries
            let newEntries = generateDataset(for: option)
            for entry in newEntries {
                modelContext.insert(entry)
            }

            try modelContext.save()

            toastMessage = "Loaded \(newEntries.count) entries"
            showingSuccessToast = true
        } catch {
            toastMessage = "Failed: \(error.localizedDescription)"
            showingSuccessToast = true
        }
    }

    private func addCustomEntry() {
        let entry = WeightEntry(weight: customWeight, date: customDate)
        modelContext.insert(entry)

        do {
            try modelContext.save()
            toastMessage = "Added \(customWeight.formatted(.number.precision(.fractionLength(1)))) lb on \(customDate.formatted(date: .abbreviated, time: .omitted))"
            showingSuccessToast = true
            // Don't reset customDate - user may want to add more entries for same/nearby dates
        } catch {
            toastMessage = "Failed to add entry"
            showingSuccessToast = true
        }
    }

    private func generateDataset(for option: DatasetOption) -> [WeightEntry] {
        guard option != .empty else { return [] }

        let calendar = Calendar.current
        let today = Date.now

        // Starting weight and target for realistic progression
        let startWeight: Double = 195.0
        let goalWeight: Double = 165.0
        let totalLoss = startWeight - goalWeight

        let days: Int
        switch option {
        case .empty: return []
        case .oneWeek: days = 7
        case .threeWeeks: days = 21
        case .threeMonths: days = 90
        case .sixMonths: days = 180
        case .elevenMonths: days = 330
        case .eighteenMonths: days = 548
        }

        var entries: [WeightEntry] = []
        let entryCount = option.entryCount
        let daySpacing = max(1, days / entryCount)

        for i in 0..<entryCount {
            let daysAgo = days - (i * daySpacing)
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

            // Calculate weight with gradual loss and some daily variation
            let progress = Double(i) / Double(max(1, entryCount - 1))
            let baseWeight = startWeight - (totalLoss * progress * min(1.0, Double(days) / 365.0))
            let variation = Double.random(in: -1.5...1.5)
            let weight = max(goalWeight, baseWeight + variation)

            // Add occasional notes
            var note: String?
            if i == 0 {
                note = "Starting weight"
            } else if i == entryCount - 1 {
                note = "Latest entry"
            } else if i % 7 == 0 {
                note = "Weekly check-in"
            }

            let entry = WeightEntry(
                weight: (weight * 10).rounded() / 10, // Round to 1 decimal
                date: setMorningTime(date),
                note: note
            )
            entries.append(entry)
        }

        return entries
    }

    private func setMorningTime(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) ?? date
    }
}

#Preview {
    DevMenuView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
#endif
