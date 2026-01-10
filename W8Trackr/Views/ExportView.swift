//
//  ExportView.swift
//  W8Trackr
//
//  Created by Will Saults on 1/8/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]

    @State private var useDateFilter = false
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var endDate = Date.now
    @State private var selectedFormat: ExportFormat = .csv
    @State private var showingImportPicker = false
    @State private var showingImportConfirmation = false
    @State private var importResult: ImportResult?
    @State private var showingImportSuccessToast = false
    @State private var showingImportErrorAlert = false
    @State private var importErrorMessage = ""

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
                Text("Format")
                Spacer()
                Text(selectedFormat.rawValue)
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
                        Text("Export \(selectedFormat.rawValue)")
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

    private var importSection: some View {
        Section {
            Button {
                showingImportPicker = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import from File")
                }
            }
        } header: {
            Text("Import Data")
        } footer: {
            Text("Import weight entries from a CSV or JSON backup file")
        }
    }

    private func handleImportedFile(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importErrorMessage = "Could not access the selected file"
                showingImportErrorAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let fileExtension = url.pathExtension.lowercased()

                let result: ImportResult
                if fileExtension == "json" {
                    result = DataExporter.importJSON(from: data)
                } else {
                    result = DataExporter.importCSV(from: data)
                }

                if result.entries.isEmpty && !result.errors.isEmpty {
                    importErrorMessage = result.errors.joined(separator: "\n")
                    showingImportErrorAlert = true
                } else {
                    importResult = result
                    showingImportConfirmation = true
                }
            } catch {
                importErrorMessage = "Failed to read file: \(error.localizedDescription)"
                showingImportErrorAlert = true
            }

        case .failure(let error):
            importErrorMessage = "Failed to select file: \(error.localizedDescription)"
            showingImportErrorAlert = true
        }
    }

    private func performImport() {
        guard let result = importResult else { return }

        for imported in result.entries {
            let entry = WeightEntry(
                weight: imported.weight,
                unit: imported.unit,
                date: imported.date,
                note: imported.note,
                bodyFatPercentage: imported.bodyFatPercentage
            )
            modelContext.insert(entry)
        }

        do {
            try modelContext.save()
            showingImportSuccessToast = true
        } catch {
            importErrorMessage = "Failed to save imported entries: \(error.localizedDescription)"
            showingImportErrorAlert = true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                formatSection
                dateFilterSection
                exportSummarySection
                exportSection
                importSection
            }
            .navigationTitle("Backup & Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.commaSeparatedText, .json],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    handleImportedFile(result: .success(url))
                } else if case .failure(let error) = result {
                    handleImportedFile(result: .failure(error))
                }
            }
            .alert("Import \(importResult?.successCount ?? 0) Entries?", isPresented: $showingImportConfirmation) {
                Button("Cancel", role: .cancel) {
                    importResult = nil
                }
                Button("Import") {
                    performImport()
                }
            } message: {
                if let result = importResult {
                    if result.errors.isEmpty {
                        Text("This will add \(result.successCount) weight entries to your data.")
                    } else {
                        Text("This will add \(result.successCount) entries. \(result.errorCount) rows had errors and will be skipped.")
                    }
                }
            }
            .alert("Import Error", isPresented: $showingImportErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importErrorMessage)
            }
            .toast(
                isPresented: $showingImportSuccessToast,
                message: "\(importResult?.successCount ?? 0) entries imported",
                systemImage: "checkmark.circle.fill"
            )
        }
    }
}

/// Transferable wrapper for export content to work with ShareLink
struct ExportFile: Transferable {
    let content: String
    let filename: String
    let format: ExportFormat

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            guard file.format == .csv else {
                throw CocoaError(.fileWriteUnknown)
            }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(file.filename)
            try file.content.write(to: tempURL, atomically: true, encoding: .utf8)
            return SentTransferredFile(tempURL)
        }
        FileRepresentation(exportedContentType: .json) { file in
            guard file.format == .json else {
                throw CocoaError(.fileWriteUnknown)
            }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(file.filename)
            try file.content.write(to: tempURL, atomically: true, encoding: .utf8)
            return SentTransferredFile(tempURL)
        }
    }
}

#Preview {
    ExportView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
