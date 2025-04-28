//
//  SettingsView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var weightUnit: String
    @Binding var goalWeight: Double
    
    let weightUnits = ["lb", "kg"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Weight Settings") {
                    Picker("Weight Unit", selection: $weightUnit) {
                        ForEach(weightUnits, id: \.self) { unit in
                            Text(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text("Goal Weight")
                        Spacer()
                        TextField("Goal Weight", value: $goalWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(weightUnit)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
