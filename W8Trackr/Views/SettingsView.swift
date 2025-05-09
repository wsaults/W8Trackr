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
    @StateObject private var notificationManager = NotificationManager()
    @Binding var weightUnit: WeightUnit
    @Binding var goalWeight: Double
    @State private var localGoalWeight: Double = 0.0
    @State private var showingDeleteAlert = false
    @State private var reminderTime: Date
    @State private var showingNotificationPermissionAlert = false
    
    init(weightUnit: Binding<WeightUnit>, goalWeight: Binding<Double>) {
        _weightUnit = weightUnit
        _goalWeight = goalWeight
        _reminderTime = State(initialValue: NotificationManager().getReminderTime())
    }
    
    private func updateGoalWeight(_ newValue: Double) {
        goalWeight = newValue
    }
    
    private var weightSettingsSection: some View {
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
                TextField("Goal Weight", value: $localGoalWeight, format: .number.precision(.fractionLength(1)))
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
    }
    
    private var dangerZoneSection: some View {
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
    
    private var reminderSection: some View {
        Section {
            Toggle("Daily Reminder", isOn: $notificationManager.isReminderEnabled)
                .onChange(of: notificationManager.isReminderEnabled) { _, newValue in
                    if newValue {
                        notificationManager.requestNotificationPermission { granted in
                            if !granted {
                                showingNotificationPermissionAlert = true
                            }
                        }
                    } else {
                        notificationManager.disableNotifications()
                    }
                }
            
            if notificationManager.isReminderEnabled {
                DatePicker("Reminder Time",
                          selection: $reminderTime,
                          displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { _, newValue in
                        notificationManager.scheduleNotification(at: newValue)
                        notificationManager.saveReminderTime(newValue)
                    }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("You'll receive a notification at the specified time every day to log your weight.")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                weightSettingsSection
                reminderSection
                dangerZoneSection
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
            .alert("Notifications Disabled", isPresented: $showingNotificationPermissionAlert) {
                Button("OK", role: .cancel) {
                    notificationManager.isReminderEnabled = false
                }
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("Please enable notifications in Settings to use daily reminders.")
            }
        }
    }
}
