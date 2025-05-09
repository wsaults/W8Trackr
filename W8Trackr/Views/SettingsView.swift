//
//  SettingsView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var weightUnit: WeightUnit
    @Binding var goalWeight: Double
    @State private var localGoalWeight: Double = 0.0
    @State private var showingDeleteAlert = false
    @State private var isReminderEnabled = false
    @State private var reminderTime = Date()
    @State private var showingNotificationPermissionAlert = false
    
    private func updateGoalWeight(_ newValue: Double) {
        goalWeight = newValue
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                scheduleNotification()
            } else {
                showingNotificationPermissionAlert = true
            }
        }
    }
    
    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        
        center.removeAllPendingNotificationRequests()
        
        if isReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Time to Log Your Weight"
            content.body = "Don't forget to log your weight for today!"
            content.sound = .default
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(identifier: "weightLogReminder",
                                             content: content,
                                             trigger: trigger)
            
            center.add(request)
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
            Toggle("Daily Reminder", isOn: $isReminderEnabled)
                .onChange(of: isReminderEnabled) { _, newValue in
                    if newValue {
                        requestNotificationPermission()
                    } else {
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                }
            
            if isReminderEnabled {
                DatePicker("Reminder Time",
                          selection: $reminderTime,
                          displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { _, _ in
                        scheduleNotification()
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
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        isReminderEnabled = settings.authorizationStatus == .authorized
                    }
                }
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
                    isReminderEnabled = false
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
