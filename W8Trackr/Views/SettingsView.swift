//
//  SettingsView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var weightUnit: WeightUnit
    @Binding var goalWeight: Double
    @State private var localGoalWeight: Double = 0.0
    @State private var showingDeleteAlert = false
    
    private func updateGoalWeight(_ newValue: Double) {
        goalWeight = newValue
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Weight Unit", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: weightUnit) { oldUnit, newUnit in
                        if newUnit == .lb {
                            localGoalWeight *= 2.20462 // Convert kg to lbs
                        } else {
                            localGoalWeight /= 2.20462 // Convert lbs to kg
                        }
                    }
                    
                    HStack {
                        Text("Goal Weight")
                        Spacer()
                        TextField("Goal Weight", value: $localGoalWeight, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: localGoalWeight) { _, newValue in
                                updateGoalWeight(newValue)
                            }
                        Text(weightUnit.rawValue)
                    }
                } header: {
                    Text("Weight Settings")
                } footer: {
                    Text("Your goal weight will be automatically converted when changing units.")
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Text("Delete All Weight Entries")
                    }
                } header: {
                    Text("Danger Zone")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                localGoalWeight = goalWeight
            }
            .alert("Delete All Entries", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    do {
                        let entries = try modelContext.fetch(FetchDescriptor<WeightEntry>())
                        for entry in entries {
                            modelContext.delete(entry)
                        }
                        try modelContext.save()
                        dismiss()
                    } catch {
                        print("Failed to delete entries: \(error)")
                    }
                }
            } message: {
                Text("Are you sure you want to delete all weight entries? This action cannot be undone.")
            }
        }
    }
}
