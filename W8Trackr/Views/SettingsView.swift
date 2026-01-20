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
    @State private var notificationManager = NotificationManager()
    private var healthSyncManager: HealthSyncManager { HealthSyncManager.shared }
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
    @State private var showingDeleteErrorToast = false
    @State private var pendingDeletionEntries: [WeightEntry] = []
    @State private var deletionTask: Task<Void, Never>?
    @State private var showingUndoToast = false

    init(weightUnit: Binding<WeightUnit>, goalWeight: Binding<Double>, showSmoothing: Binding<Bool>) {
        _weightUnit = weightUnit
        _goalWeight = goalWeight
        _showSmoothing = showSmoothing
        _reminderTime = State(initialValue: NotificationManager.getReminderTime())
    }

    private var isValidGoalWeight: Bool {
        weightUnit.isValidGoalWeight(localGoalWeight)
    }

    private var goalWeightValidationMessage: String? {
        guard !isValidGoalWeight else { return nil }
        return "Goal weight must be between \(weightUnit.minGoalWeight.formatted()) and \(weightUnit.maxGoalWeight.formatted()) \(weightUnit.rawValue)"
    }

    private var goalWeightWarning: GoalWeightWarning? {
        weightUnit.goalWeightWarning(localGoalWeight)
    }

    private func updateGoalWeight(_ newValue: Double) {
        if weightUnit.isValidGoalWeight(newValue) {
            goalWeight = newValue
        }
    }

    private func deleteAllEntries() {
        do {
            let entries = try modelContext.fetch(FetchDescriptor<WeightEntry>())
            guard !entries.isEmpty else { return }

            // Cancel any existing deletion task
            deletionTask?.cancel()

            // Cache entries for potential undo (copy the array)
            pendingDeletionEntries = entries

            // Delete from context
            for entry in entries {
                modelContext.delete(entry)
            }
            try modelContext.save()

            // Show undo toast
            showingUndoToast = true

            // Schedule cleanup after undo window expires
            deletionTask = Task {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    // Clear cache - entries are now permanently gone
                    pendingDeletionEntries = []
                    showingUndoToast = false
                }
            }

            // Don't dismiss - stay in Settings so user can undo
        } catch {
            showingDeleteErrorToast = true
        }
    }

    private func undoDelete() {
        // Cancel the cleanup task
        deletionTask?.cancel()
        deletionTask = nil

        // Re-insert cached entries
        for entry in pendingDeletionEntries {
            modelContext.insert(entry)
        }

        do {
            try modelContext.save()
            pendingDeletionEntries = []
            showingUndoToast = false
        } catch {
            // If undo fails, show error toast
            showingDeleteErrorToast = true
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
                guard oldUnit != newUnit else { return }

                // Validate source value before conversion
                guard oldUnit.isValidGoalWeight(localGoalWeight) else {
                    // Invalid source value - use the new unit's default
                    localGoalWeight = newUnit.defaultWeight
                    goalWeight = newUnit.defaultWeight
                    return
                }

                let convertedWeight = oldUnit.convert(localGoalWeight, to: newUnit)

                // Validate converted result falls within new unit's goal bounds
                if newUnit.isValidGoalWeight(convertedWeight) {
                    localGoalWeight = convertedWeight
                    goalWeight = convertedWeight
                } else {
                    // Conversion produced out-of-bounds value - clamp to valid goal range
                    let clampedWeight = min(max(convertedWeight, newUnit.minGoalWeight), newUnit.maxGoalWeight)
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
                    .foregroundStyle(isValidGoalWeight ? Color.primary : Color.red)
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

            if let warning = goalWeightWarning {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(warning.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
            .accessibilityHint("This will delete all your weight tracking data. You can undo within 5 seconds.")
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
                        Task {
                            let granted = await notificationManager.requestNotificationPermission()
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
        if HealthSyncManager.isHealthDataAvailable {
            Section {
                Toggle("Sync to Apple Health", isOn: Binding(
                    get: { healthSyncManager.isHealthSyncEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                do {
                                    let success = try await healthSyncManager.requestAuthorization()
                                    if success && healthSyncManager.isAuthorized {
                                        healthSyncManager.isHealthSyncEnabled = true
                                    } else {
                                        showingHealthKitPermissionAlert = true
                                    }
                                } catch {
                                    showingHealthKitPermissionAlert = true
                                }
                            }
                        } else {
                            healthSyncManager.isHealthSyncEnabled = false
                        }
                    }
                ))

                if healthSyncManager.isHealthSyncEnabled {
                    HStack {
                        Text("Sync Status")
                        Spacer()
                        syncStatusView
                    }
                }
            } header: {
                Text("Apple Health")
            } footer: {
                Text("When enabled, your weight entries will be automatically saved to Apple Health.")
            }
        }
    }

    @ViewBuilder
    private var syncStatusView: some View {
        switch healthSyncManager.syncStatus {
        case .idle:
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

    #if DEBUG
    @State private var showingDevMenu = false
    #endif

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
            .syncStatusToolbar()
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingDevMenu = true
                    } label: {
                        Image(systemName: "hammer.fill")
                            .foregroundStyle(.orange)
                    }
                    .accessibilityLabel("Developer Menu")
                }
            }
            #endif
            .onAppear {
                localGoalWeight = goalWeight
            }
            .alert("Delete All Entries", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllEntries()
                }
            } message: {
                Text("Are you sure you want to delete all weight entries? You'll have 5 seconds to undo.")
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
            #if DEBUG
            .sheet(isPresented: $showingDevMenu) {
                DevMenuView()
            }
            #endif
            .toast(
                isPresented: $showingUndoToast,
                message: "All entries deleted",
                systemImage: "trash",
                actionLabel: "Undo",
                duration: 5
            ) {
                undoDelete()
            }
            .toast(
                isPresented: $showingDeleteErrorToast,
                message: "Failed to delete entries",
                systemImage: "exclamationmark.triangle.fill",
                actionLabel: "Retry",
                onAction: deleteAllEntries
            )
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("Default (lb)", traits: .modifier(SettingsViewPreview())) {
    @Previewable @State var weightUnit: WeightUnit = .lb
    @Previewable @State var goalWeight: Double = 160.0
    @Previewable @State var showSmoothing: Bool = true

    SettingsView(
        weightUnit: $weightUnit,
        goalWeight: $goalWeight,
        showSmoothing: $showSmoothing
    )
}

@available(iOS 18, macOS 15, *)
#Preview("Metric (kg)", traits: .modifier(SettingsViewPreview())) {
    @Previewable @State var weightUnit: WeightUnit = .kg
    @Previewable @State var goalWeight: Double = 72.5
    @Previewable @State var showSmoothing: Bool = true

    SettingsView(
        weightUnit: $weightUnit,
        goalWeight: $goalWeight,
        showSmoothing: $showSmoothing
    )
}

@available(iOS 18, macOS 15, *)
#Preview("With Sample Data", traits: .modifier(SettingsViewPreview(withSampleData: true))) {
    @Previewable @State var weightUnit: WeightUnit = .lb
    @Previewable @State var goalWeight: Double = 165.0
    @Previewable @State var showSmoothing: Bool = false

    SettingsView(
        weightUnit: $weightUnit,
        goalWeight: $goalWeight,
        showSmoothing: $showSmoothing
    )
}
#endif
