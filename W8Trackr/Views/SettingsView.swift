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
    @Binding var showSmoothing: Bool
    @State private var localGoalWeight: Double = 0.0
    @State private var showingDeleteAlert = false
    @State private var reminderTime: Date
    @State private var showingNotificationPermissionAlert = false
    @State private var showingSmoothingInfo = false

    init(weightUnit: Binding<WeightUnit>, goalWeight: Binding<Double>, showSmoothing: Binding<Bool>) {
        _weightUnit = weightUnit
        _goalWeight = goalWeight
        _showSmoothing = showSmoothing
        _reminderTime = State(initialValue: NotificationManager.getReminderTime())
    }

    private var isValidGoalWeight: Bool {
        weightUnit.isValidWeight(localGoalWeight)
    }

    private var goalWeightValidationMessage: String? {
        guard !isValidGoalWeight else { return nil }
        return "Goal weight must be between \(weightUnit.minWeight.formatted()) and \(weightUnit.maxWeight.formatted()) \(weightUnit.rawValue)"
    }

    private func updateGoalWeight(_ newValue: Double) {
        if weightUnit.isValidWeight(newValue) {
            goalWeight = newValue
        }
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
                localGoalWeight = oldUnit.convert(localGoalWeight, to: newUnit)
            }
            
            HStack {
                Text("Goal Weight")
                Spacer()
                TextField("Goal Weight", value: $localGoalWeight, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(isValidGoalWeight ? Color.primary : Color.red)
                    .onChange(of: localGoalWeight) { _, newValue in
                        updateGoalWeight(newValue)
                    }
                Text(weightUnit.rawValue)
            }

            if let message = goalWeightValidationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
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
    
    private var chartSettingsSection: some View {
        Section {
            HStack {
                Toggle("Trend Smoothing", isOn: $showSmoothing)
                Button {
                    showingSmoothingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Chart Settings")
        } footer: {
            Text("Shows your true weight trend by smoothing out daily fluctuations from water weight and sodium.")
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

                if let suggestedTime = notificationManager.suggestedReminderTime {
                    Button {
                        reminderTime = suggestedTime
                        notificationManager.scheduleNotification(at: suggestedTime)
                        notificationManager.saveReminderTime(suggestedTime)
                    } label: {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Use suggested time: \(suggestedTime, style: .time)")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("You'll receive a notification at the specified time every day to log your weight.")
        }
    }

    private var smartRemindersSection: some View {
        Section {
            Toggle("Smart Reminders", isOn: $notificationManager.isSmartRemindersEnabled)
                .onChange(of: notificationManager.isSmartRemindersEnabled) { _, newValue in
                    notificationManager.setSmartRemindersEnabled(newValue)
                }
        } header: {
            Text("Smart Reminders")
        } footer: {
            Text("Get personalized notifications including streak warnings, milestone alerts, and weekly summaries based on your logging habits.")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                weightSettingsSection
                chartSettingsSection
                reminderSection
                smartRemindersSection
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
            .alert("Trend Smoothing", isPresented: $showingSmoothingInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your weight naturally fluctuates 2-4 lbs daily due to water retention, sodium intake, and digestion. Trend smoothing uses a 10-day exponential moving average to reveal your true weight trend, helping you focus on long-term progress rather than day-to-day noise.")
            }
        }
    }
}
