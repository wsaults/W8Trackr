//
//  ExportView.swift
//  W8Trackr
//
//  Created by Will Saults on 1/8/26.
//

import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]

    @State private var useDateFilter = false
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var endDate = Date.now
    @State private var selectedFormat: ExportFormat = .csv

    private var filteredEntryCount: Int {
        if useDateFilter {
            return entries.filter { entry in
                let startOfDay = Calendar.current.startOfDay(for: startDate)
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate))!
                return entry.date >= startOfDay && entry.date < endOfDay
            }.count
        }
        return entries.count
    }

    private var exportContent: String {
        let start = useDateFilter ? startDate : nil
        let end = useDateFilter ? endDate : nil

        switch selectedFormat {
        case .csv:
            return DataExporter.generateCSV(from: entries, startDate: start, endDate: end)
        case .json:
            return DataExporter.generateJSON(from: entries, startDate: start, endDate: end)
        }
    }

    private var exportFilename: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "w8trackr_export_\(dateFormatter.string(from: .now)).\(selectedFormat.fileExtension)"
    }

    private var dateFilterSection: some View {
        Section {
            Toggle("Filter by Date Range", isOn: $useDateFilter.animation())

            if useDateFilter {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
        } header: {
            Text("Date Range")
        } footer: {
            if useDateFilter {
                Text("Export entries from \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(endDate.formatted(date: .abbreviated, time: .omitted))")
            } else {
                Text("Export all entries")
            }
        }
    }

    private var formatSection: some View {
        Section {
            Picker("Format", selection: $selectedFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Export Format")
        } footer: {
            if selectedFormat == .csv {
                Text("CSV format works with spreadsheet apps like Excel and Numbers.")
            } else {
                Text("JSON format is ideal for backups and can be imported by other apps.")
            }
        }
    }

    private var exportSummarySection: some View {
        Section {
            HStack {
                Text("Entries to Export")
                Spacer()
                Text("\(filteredEntryCount)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Fields")
                Spacer()
                Text("date, weight, unit, note, bodyFat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Export Summary")
        }
    }

    private var exportSection: some View {
        Section {
            if filteredEntryCount > 0 {
                ShareLink(
                    item: ExportFile(content: exportContent, filename: exportFilename, format: selectedFormat),
                    preview: SharePreview(exportFilename, icon: Image(systemName: "doc.text"))
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export to \(selectedFormat.rawValue)")
                    }
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("No entries to export")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                formatSection
                dateFilterSection
                exportSummarySection
                exportSection
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Transferable wrapper for export content to work with ShareLink
struct ExportFile: Transferable {
    let content: String
    let filename: String
    let format: ExportFormat

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { exportFile in
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(exportFile.filename)
            try exportFile.content.write(to: tempURL, atomically: true, encoding: .utf8)
            return SentTransferredFile(tempURL)
        }
    }
}

#Preview {
    ExportView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
