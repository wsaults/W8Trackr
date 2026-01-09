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
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @Binding var weightUnit: WeightUnit
    @Binding var goalWeight: Double
    @Binding var showSmoothing: Bool
    @State private var localGoalWeight: Double = 0.0
    @State private var showingDeleteAlert = false
    @State private var reminderTime: Date
    @State private var showingNotificationPermissionAlert = false
    @State private var showingHealthKitPermissionAlert = false
    @State private var showingSmoothingInfo = false
    @State private var showingExportView = false

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
                // Validate source value before conversion
                guard oldUnit.isValidWeight(localGoalWeight) else {
                    // Invalid source value - use the new unit's default
                    localGoalWeight = newUnit.defaultWeight
                    goalWeight = newUnit.defaultWeight
                    return
                }

                let convertedWeight = oldUnit.convert(localGoalWeight, to: newUnit)

                // Validate converted result falls within new unit's bounds
                if newUnit.isValidWeight(convertedWeight) {
                    localGoalWeight = convertedWeight
                    goalWeight = convertedWeight
                } else {
                    // Conversion produced out-of-bounds value - clamp to valid range
                    let clampedWeight = min(max(convertedWeight, newUnit.minWeight), newUnit.maxWeight)
                    localGoalWeight = clampedWeight
                    goalWeight = clampedWeight
                }
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
    
    private var dataManagementSection: some View {
        Section {
            Button {
                showingExportView = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Data")
                }
            }
        } header: {
            Text("Data Management")
        }
    }

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Text("Delete All Weight Entries")
            }
            .accessibilityHint("This will permanently delete all your weight tracking data. This action cannot be undone.")
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

    @ViewBuilder
    private var healthSection: some View {
        if HealthKitManager.isHealthKitAvailable {
            Section {
                Toggle("Sync to Apple Health", isOn: Binding(
                    get: { healthKitManager.isHealthSyncEnabled },
                    set: { newValue in
                        if newValue {
                            healthKitManager.requestAuthorization { granted, _ in
                                if granted {
                                    healthKitManager.isHealthSyncEnabled = true
                                } else {
                                    showingHealthKitPermissionAlert = true
                                }
                            }
                        } else {
                            healthKitManager.isHealthSyncEnabled = false
                        }
                    }
                ))

                if healthKitManager.isHealthSyncEnabled {
                    HStack {
                        Text("Sync Status")
                        Spacer()
                        syncStatusView
                    }
                }
            } header: {
                Text("Apple Health")
            } footer: {
                Text("When enabled, your weight and body fat entries will be automatically saved to Apple Health.")
            }
        }
    }

    @ViewBuilder
    private var syncStatusView: some View {
        switch healthKitManager.lastSyncStatus {
        case .none:
            Text("Ready")
                .foregroundStyle(.secondary)
        case .syncing:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Syncing...")
            }
            .foregroundStyle(.secondary)
        case .success:
            Label("Synced", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let error):
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                weightSettingsSection
                chartSettingsSection
                reminderSection
                smartRemindersSection
                healthSection
                dataManagementSection
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
                        // Deletion failed silently
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
            .alert("Health Access Required", isPresented: $showingHealthKitPermissionAlert) {
                Button("OK", role: .cancel) { }
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("Please enable Health access in Settings to sync your weight data.")
            }
            .alert("Trend Smoothing", isPresented: $showingSmoothingInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("""
                    Your weight naturally fluctuates 2-4 lbs daily due to water retention, \
                    sodium intake, and digestion. Trend smoothing uses a 10-day exponential \
                    moving average to reveal your true weight trend, helping you focus on \
                    long-term progress rather than day-to-day noise.
                    """)
            }
            .sheet(isPresented: $showingExportView) {
                ExportView()
            }
        }
    }
}
