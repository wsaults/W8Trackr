//
//  DataExporter.swift
//  W8Trackr
//
//  Created by Will Saults on 1/8/26.
//

import Foundation

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
}
