//
//  DataExporter.swift
//  W8Trackr
//
//  Created by Will Saults on 1/8/26.
//

import Foundation

// MARK: - Export Format

/// Export format options
enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case json = "JSON"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        }
    }

    var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        }
    }
}

// MARK: - Exportable Entry (Codable wrapper)

struct ExportableEntry: Codable {
    let date: Date
    let weight: Double
    let unit: String
    let note: String?
    let bodyFatPercentage: Double?
    let modifiedDate: Date?

    init(from entry: WeightEntry) {
        self.date = entry.date
        self.weight = entry.weightValue
        self.unit = entry.weightUnit
        self.note = entry.note
        self.bodyFatPercentage = entry.bodyFatPercentage.map { NSDecimalNumber(decimal: $0).doubleValue }
        self.modifiedDate = entry.modifiedDate
    }
}

// MARK: - Export Container (for JSON backup)

struct ExportContainer: Codable {
    let exportDate: Date
    let appVersion: String
    let entryCount: Int
    let entries: [ExportableEntry]

    init(entries: [WeightEntry]) {
        self.exportDate = Date.now
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        self.entryCount = entries.count
        self.entries = entries.map { ExportableEntry(from: $0) }
    }
}

// MARK: - Import Result

struct ImportResult {
    let entries: [ImportedEntry]
    let errors: [String]

    var successCount: Int { entries.count }
    var errorCount: Int { errors.count }
}

struct ImportedEntry {
    let weight: Double
    let unit: WeightUnit
    let date: Date
    let note: String?
    let bodyFatPercentage: Decimal?
}

// MARK: - DataExporter

struct DataExporter {

    /// Generates CSV content from weight entries
    /// - Parameters:
    ///   - entries: Array of WeightEntry objects to export
    ///   - startDate: Optional start date for filtering (inclusive)
    ///   - endDate: Optional end date for filtering (inclusive)
    /// - Returns: CSV string with headers and data rows
    static func generateCSV(
        from entries: [WeightEntry],
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> String {
        let filteredEntries = filterEntries(entries, startDate: startDate, endDate: endDate)
        let sortedEntries = filteredEntries.sorted { $0.date < $1.date }

        var csv = "date,weight,unit,note,bodyFat\n"

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        for entry in sortedEntries {
            let date = dateFormatter.string(from: entry.date)
            let weight = String(format: "%.1f", entry.weightValue)
            let unit = entry.weightUnit
            let note = escapeCSVField(entry.note ?? "")
            let bodyFat = entry.bodyFatPercentage.map { String(describing: $0) } ?? ""

            csv += "\(date),\(weight),\(unit),\(note),\(bodyFat)\n"
        }

        return csv
    }

    /// Filters entries by date range
    private static func filterEntries(
        _ entries: [WeightEntry],
        startDate: Date?,
        endDate: Date?
    ) -> [WeightEntry] {
        var filtered = entries

        if let start = startDate {
            let startOfDay = Calendar.current.startOfDay(for: start)
            filtered = filtered.filter { $0.date >= startOfDay }
        }

        if let end = endDate {
            // Include entire end day
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: end))!
            filtered = filtered.filter { $0.date < endOfDay }
        }

        return filtered
    }

    /// Escapes a field for CSV format (handles commas, quotes, newlines)
    private static func escapeCSVField(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n")
        if needsQuoting {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// Creates a temporary file URL for the CSV export
    static func createCSVFile(content: String, filename: String = "w8trackr_export.csv") -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    // MARK: - JSON Export

    /// Generates JSON backup content from weight entries
    /// - Parameters:
    ///   - entries: Array of WeightEntry objects to export
    ///   - startDate: Optional start date for filtering (inclusive)
    ///   - endDate: Optional end date for filtering (inclusive)
    /// - Returns: JSON string with entry data
    static func generateJSON(
        from entries: [WeightEntry],
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> String {
        let filteredEntries = filterEntries(entries, startDate: startDate, endDate: endDate)
        let sortedEntries = filteredEntries.sorted { $0.date < $1.date }
        let container = ExportContainer(entries: sortedEntries)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(container),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return jsonString
    }

    // MARK: - Import

    /// Imports entries from CSV data
    static func importCSV(from data: Data) -> ImportResult {
        guard let content = String(data: data, encoding: .utf8) else {
            return ImportResult(entries: [], errors: ["Could not read file as UTF-8 text"])
        }

        var entries: [ImportedEntry] = []
        var errors: [String] = []

        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            return ImportResult(entries: [], errors: ["File is empty or has no data rows"])
        }

        // Parse header to find column indices
        let header = parseCSVLine(lines[0])
        let dateIndex = header.firstIndex(of: "date")
        let weightIndex = header.firstIndex(of: "weight")
        let unitIndex = header.firstIndex(of: "unit")
        let noteIndex = header.firstIndex(of: "note")
        let bodyFatIndex = header.firstIndex(of: "bodyFat")

        guard let dateIdx = dateIndex, let weightIdx = weightIndex else {
            return ImportResult(entries: [], errors: ["CSV must have 'date' and 'weight' columns"])
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        for (lineNumber, line) in lines.dropFirst().enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }

            let fields = parseCSVLine(trimmedLine)
            let rowNum = lineNumber + 2 // 1-indexed, after header

            // Parse date
            guard dateIdx < fields.count,
                  let date = dateFormatter.date(from: fields[dateIdx]) else {
                errors.append("Row \(rowNum): Invalid date format")
                continue
            }

            // Parse weight
            guard weightIdx < fields.count,
                  let weight = Double(fields[weightIdx]) else {
                errors.append("Row \(rowNum): Invalid weight value")
                continue
            }

            // Parse unit (default to lb if missing)
            var unit: WeightUnit = .lb
            if let unitIdx = unitIndex, unitIdx < fields.count {
                unit = WeightUnit(rawValue: fields[unitIdx]) ?? .lb
            }

            // Parse optional note
            var note: String?
            if let noteIdx = noteIndex, noteIdx < fields.count {
                let noteValue = fields[noteIdx]
                note = noteValue.isEmpty ? nil : noteValue
            }

            // Parse optional body fat
            var bodyFat: Decimal?
            if let bfIdx = bodyFatIndex, bfIdx < fields.count {
                let bfValue = fields[bfIdx]
                if !bfValue.isEmpty, let bfDouble = Double(bfValue) {
                    bodyFat = Decimal(bfDouble)
                }
            }

            entries.append(ImportedEntry(
                weight: weight,
                unit: unit,
                date: date,
                note: note,
                bodyFatPercentage: bodyFat
            ))
        }

        return ImportResult(entries: entries, errors: errors)
    }

    /// Imports entries from JSON backup data
    static func importJSON(from data: Data) -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let container = try decoder.decode(ExportContainer.self, from: data)
            let entries = container.entries.map { exportable -> ImportedEntry in
                ImportedEntry(
                    weight: exportable.weight,
                    unit: WeightUnit(rawValue: exportable.unit) ?? .lb,
                    date: exportable.date,
                    note: exportable.note,
                    bodyFatPercentage: exportable.bodyFatPercentage.map { Decimal($0) }
                )
            }
            return ImportResult(entries: entries, errors: [])
        } catch {
            return ImportResult(entries: [], errors: ["Failed to parse JSON: \(error.localizedDescription)"])
        }
    }

    /// Parses a CSV line handling quoted fields
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        fields.append(currentField)

        return fields.map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
