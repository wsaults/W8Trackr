//
//  DataExporter.swift
//  W8Trackr
//
//  Created by Will Saults on 1/8/26.
//

import Foundation

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
            let weight = entry.weightValue.formatted(.number.precision(.fractionLength(1)))
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

    /// Generates JSON content from weight entries
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

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        let exportData = ExportData(
            exportDate: dateFormatter.string(from: Date.now),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            entryCount: sortedEntries.count,
            entries: sortedEntries.map { entry in
                ExportEntry(
                    date: dateFormatter.string(from: entry.date),
                    weight: entry.weightValue,
                    unit: entry.weightUnit,
                    note: entry.note,
                    bodyFatPercentage: entry.bodyFatPercentage.map { Double(truncating: $0 as NSNumber) }
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let jsonData = try? encoder.encode(exportData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }

        return jsonString
    }
}

// MARK: - JSON Export Models

struct ExportData: Codable {
    let exportDate: String
    let appVersion: String
    let entryCount: Int
    let entries: [ExportEntry]
}

struct ExportEntry: Codable {
    let date: String
    let weight: Double
    let unit: String
    let note: String?
    let bodyFatPercentage: Double?
}
