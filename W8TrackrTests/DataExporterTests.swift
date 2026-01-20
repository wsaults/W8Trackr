//
//  DataExporterTests.swift
//  W8TrackrTests
//
//  Unit tests for DataExporter functionality
//

import Testing
import Foundation
@testable import W8Trackr

// MARK: - DataExporter Tests

struct DataExporterTests {

    @Test func generateCSVWithEmptyEntriesReturnsHeaderOnly() {
        let csv = DataExporter.generateCSV(from: [])
        #expect(csv == "date,weight,unit,note,bodyFat\n")
    }

    @Test func generateCSVWithSingleEntry() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let entry = WeightEntry(weight: 175.5, unit: .lb, date: date, note: "Test note", bodyFatPercentage: 20.5)

        let csv = DataExporter.generateCSV(from: [entry])
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 3) // header, data row, empty line
        #expect(lines[0] == "date,weight,unit,note,bodyFat")
        #expect(lines[1].contains("175.5"))
        #expect(lines[1].contains("lb"))
        #expect(lines[1].contains("Test note"))
        #expect(lines[1].contains("20.5"))
    }

    @Test func generateCSVEscapesCommasInNotes() {
        let entry = WeightEntry(weight: 170.0, unit: .lb, date: Date(), note: "Note with, comma")

        let csv = DataExporter.generateCSV(from: [entry])

        #expect(csv.contains("\"Note with, comma\""))
    }

    @Test func generateCSVEscapesQuotesInNotes() {
        let entry = WeightEntry(weight: 170.0, unit: .lb, date: Date(), note: "Note with \"quotes\"")

        let csv = DataExporter.generateCSV(from: [entry])

        #expect(csv.contains("\"Note with \"\"quotes\"\"\""))
    }

    @Test func generateCSVHandlesNilFields() {
        let entry = WeightEntry(weight: 170.0, unit: .lb, date: Date())

        let csv = DataExporter.generateCSV(from: [entry])
        let lines = csv.components(separatedBy: "\n")
        let dataLine = lines[1]
        let columns = dataLine.components(separatedBy: ",")

        // Note should be empty string, bodyFat should be empty
        #expect(columns[3].isEmpty) // note
        #expect(columns[4].isEmpty) // bodyFat
    }

    @Test func generateCSVSortsEntriesByDateAscending() {
        let calendar = Calendar.current
        let now = Date.now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now),
            WeightEntry(weight: 172.0, date: twoDaysAgo),
            WeightEntry(weight: 171.0, date: yesterday)
        ]

        let csv = DataExporter.generateCSV(from: entries)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Data lines should be sorted: 172 (oldest), 171, 170 (newest)
        #expect(lines[1].contains("172.0"))
        #expect(lines[2].contains("171.0"))
        #expect(lines[3].contains("170.0"))
    }

    @Test func generateCSVFiltersEntriesByStartDate() {
        let calendar = Calendar.current
        let now = Date.now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now),
            WeightEntry(weight: 172.0, date: fiveDaysAgo) // Should be excluded
        ]

        let csv = DataExporter.generateCSV(from: entries, startDate: threeDaysAgo)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 2) // header + 1 data row
        #expect(lines[1].contains("170.0"))
        #expect(!csv.contains("172.0"))
    }

    @Test func generateCSVFiltersEntriesByEndDate() {
        let calendar = Calendar.current
        let now = Date.now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now), // Should be excluded
            WeightEntry(weight: 172.0, date: fiveDaysAgo)
        ]

        let csv = DataExporter.generateCSV(from: entries, endDate: threeDaysAgo)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 2) // header + 1 data row
        #expect(lines[1].contains("172.0"))
        #expect(!csv.contains("170.0"))
    }

    @Test func generateCSVFiltersEntriesByDateRange() {
        let calendar = Calendar.current
        let now = Date.now
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!
        let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: now)!
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now),           // Outside range (too recent)
            WeightEntry(weight: 171.0, date: twoDaysAgo),    // Inside range
            WeightEntry(weight: 172.0, date: fourDaysAgo),   // Inside range
            WeightEntry(weight: 173.0, date: sixDaysAgo)     // Outside range (too old)
        ]

        let csv = DataExporter.generateCSV(
            from: entries,
            startDate: calendar.date(byAdding: .day, value: -5, to: now)!,
            endDate: calendar.date(byAdding: .day, value: -1, to: now)!
        )
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 3) // header + 2 data rows
        #expect(csv.contains("171.0"))
        #expect(csv.contains("172.0"))
        #expect(!csv.contains("170.0"))
        #expect(!csv.contains("173.0"))
    }

    @Test func createCSVFileReturnsValidURL() {
        let content = "date,weight,unit,note,bodyFat\n2024-01-01,170.0,lb,,\n"
        let url = DataExporter.createCSVFile(content: content, filename: "test_export.csv")

        #expect(url != nil)
        #expect(url?.lastPathComponent == "test_export.csv")
        #expect(url?.pathExtension == "csv")
    }

    @Test func createCSVFileWritesContent() {
        let content = "date,weight,unit,note,bodyFat\n2024-01-01,170.0,lb,,\n"
        guard let url = DataExporter.createCSVFile(content: content, filename: "test_export_content.csv") else {
            Issue.record("Failed to create CSV file")
            return
        }

        let readContent = try? String(contentsOf: url, encoding: .utf8)
        #expect(readContent == content)

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - ExportFormat Tests

struct ExportFormatTests {

    @Test func csvFormatHasCorrectProperties() {
        #expect(ExportFormat.csv.rawValue == "CSV")
        #expect(ExportFormat.csv.fileExtension == "csv")
        #expect(ExportFormat.csv.mimeType == "text/csv")
        #expect(ExportFormat.csv.id == "CSV")
    }

    @Test func jsonFormatHasCorrectProperties() {
        #expect(ExportFormat.json.rawValue == "JSON")
        #expect(ExportFormat.json.fileExtension == "json")
        #expect(ExportFormat.json.mimeType == "application/json")
        #expect(ExportFormat.json.id == "JSON")
    }

    @Test func allCasesContainsBothFormats() {
        let allCases = ExportFormat.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.csv))
        #expect(allCases.contains(.json))
    }
}

// MARK: - JSON Export Tests

struct JSONExportTests {

    @Test func generateJSONWithEmptyEntriesReturnsEmptyArray() {
        let json = DataExporter.generateJSON(from: [])

        #expect(json.contains("\"entryCount\" : 0"))
        #expect(json.contains("\"entries\" : ["))
    }

    @Test func generateJSONWithSingleEntry() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let entry = WeightEntry(weight: 175.5, unit: .lb, date: date, note: "Test note", bodyFatPercentage: 20.5)

        let json = DataExporter.generateJSON(from: [entry])

        #expect(json.contains("\"weight\" : 175.5"))
        #expect(json.contains("\"unit\" : \"lb\""))
        #expect(json.contains("\"note\" : \"Test note\""))
        #expect(json.contains("\"bodyFatPercentage\" : 20.5"))
        #expect(json.contains("\"entryCount\" : 1"))
    }

    @Test func generateJSONHandlesNilFields() {
        let entry = WeightEntry(weight: 170.0, unit: .lb, date: Date())

        let json = DataExporter.generateJSON(from: [entry])

        // Swift's JSONEncoder omits keys for nil optionals (compact representation)
        // Verify the entry is still valid and parseable
        #expect(json.contains("\"weight\" : 170"))
        #expect(json.contains("\"unit\" : \"lb\""))

        // Verify it doesn't contain bogus values for nil fields
        #expect(!json.contains("\"note\" : \"\""))
        #expect(!json.contains("\"bodyFatPercentage\" : 0"))
    }

    @Test func generateJSONSortsEntriesByDateAscending() {
        let calendar = Calendar.current
        let now = Date.now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now),
            WeightEntry(weight: 172.0, date: twoDaysAgo),
            WeightEntry(weight: 171.0, date: yesterday)
        ]

        let json = DataExporter.generateJSON(from: entries)

        // Verify entries are sorted - 172.0 should appear before 171.0 which appears before 170.0
        let index172 = json.range(of: "172")?.lowerBound
        let index171 = json.range(of: "171")?.lowerBound
        let index170 = json.range(of: "170")?.lowerBound

        #expect(index172 != nil)
        #expect(index171 != nil)
        #expect(index170 != nil)
        #expect(index172! < index171!)
        #expect(index171! < index170!)
    }

    @Test func generateJSONFiltersEntriesByStartDate() {
        let calendar = Calendar.current
        let now = Date.now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now),
            WeightEntry(weight: 172.0, date: fiveDaysAgo) // Should be excluded
        ]

        let json = DataExporter.generateJSON(from: entries, startDate: threeDaysAgo)

        #expect(json.contains("\"entryCount\" : 1"))
        #expect(json.contains("170"))
        #expect(!json.contains("172"))
    }

    @Test func generateJSONFiltersEntriesByEndDate() {
        let calendar = Calendar.current
        let now = Date.now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now)!

        let entries = [
            WeightEntry(weight: 170.0, date: now), // Should be excluded
            WeightEntry(weight: 172.0, date: fiveDaysAgo)
        ]

        let json = DataExporter.generateJSON(from: entries, endDate: threeDaysAgo)

        #expect(json.contains("\"entryCount\" : 1"))
        #expect(json.contains("172"))
        #expect(!json.contains("170"))
    }

    @Test func generateJSONIncludesMetadata() {
        let entry = WeightEntry(weight: 170.0, date: Date())

        let json = DataExporter.generateJSON(from: [entry])

        #expect(json.contains("\"appVersion\""))
        #expect(json.contains("\"exportDate\""))
        #expect(json.contains("\"entryCount\""))
        #expect(json.contains("\"entries\""))
    }

    @Test func generateJSONProducesValidJSON() {
        let entries = [
            WeightEntry(weight: 170.0, date: Date(), note: "Test"),
            WeightEntry(weight: 175.0, date: Date())
        ]

        let json = DataExporter.generateJSON(from: entries)
        let jsonData = json.data(using: .utf8)!

        // Verify it can be parsed as JSON
        let parsed = try? JSONSerialization.jsonObject(with: jsonData)
        #expect(parsed != nil)
    }
}
