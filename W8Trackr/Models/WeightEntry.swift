//
//  Entry.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Foundation
import SwiftData

enum WeightUnit: String, CaseIterable {
    case lb, kg

    /// Conversion factor: 1 lb = 0.453592 kg
    static let lbToKg = 0.453592
    /// Conversion factor: 1 kg = 2.20462 lb
    static let kgToLb = 2.20462

    var defaultWeight: Double {
        switch self {
        case .lb:
            return 180.0
        case .kg:
            return 80.0
        }
    }

    var minWeight: Double {
        switch self {
        case .lb:
            return 1.0
        case .kg:
            return 0.5
        }
    }

    var maxWeight: Double {
        switch self {
        case .lb:
            return 1500.0
        case .kg:
            return 680.0
        }
    }

    // MARK: - Goal Weight Bounds (Medical Standards)

    var minGoalWeight: Double {
        switch self {
        case .lb:
            return 70.0
        case .kg:
            return 32.0
        }
    }

    var maxGoalWeight: Double {
        switch self {
        case .lb:
            return 450.0
        case .kg:
            return 205.0
        }
    }

    var lowGoalWarningThreshold: Double {
        switch self {
        case .lb:
            return 100.0
        case .kg:
            return 45.0
        }
    }

    var highGoalWarningThreshold: Double {
        switch self {
        case .lb:
            return 350.0
        case .kg:
            return 159.0
        }
    }

    func isValidWeight(_ weight: Double) -> Bool {
        weight >= minWeight && weight <= maxWeight
    }

    func isValidGoalWeight(_ weight: Double) -> Bool {
        weight >= minGoalWeight && weight <= maxGoalWeight
    }

    func goalWeightWarning(_ weight: Double) -> GoalWeightWarning? {
        guard isValidGoalWeight(weight) else { return nil }
        if weight < lowGoalWarningThreshold {
            return .low
        } else if weight > highGoalWarningThreshold {
            return .high
        }
        return nil
    }
}

enum GoalWeightWarning {
    case low
    case high

    var message: String {
        switch self {
        case .low:
            return "This goal weight may be too low for healthy adults. Consider consulting a healthcare provider."
        case .high:
            return "This goal weight is quite high. Consider consulting a healthcare provider about a healthy target."
        }
    }
}

extension WeightUnit {
    /// Converts a weight value from this unit to the target unit
    func convert(_ value: Double, to targetUnit: WeightUnit) -> Double {
        guard self != targetUnit else { return value }
        switch (self, targetUnit) {
        case (.lb, .kg):
            return value * Self.lbToKg
        case (.kg, .lb):
            return value * Self.kgToLb
        default:
            return value
        }
    }
}

extension Double {
    func weightValue(from: WeightUnit, to unit: WeightUnit) -> Double {
        from.convert(self, to: unit)
    }
}

/// A single weight measurement entry persisted via SwiftData.
///
/// Each entry stores the weight in its original unit of measurement,
/// allowing accurate conversion when the user switches between lb and kg.
@Model
final class WeightEntry {
    /// The numeric weight value in the unit specified by `weightUnit`.
    var weightValue: Double = 0

    /// The unit of measurement as a raw string value.
    ///
    /// Stored as `String` rather than `WeightUnit` enum because SwiftData
    /// requires `Codable` types for persistence, and enums with raw values
    /// serialize more reliably as their raw string representation.
    var weightUnit: String = WeightUnit.lb.rawValue

    /// When this weight was recorded (defaults to creation time).
    var date: Date = Date.now

    /// Optional user note for context (e.g., "Morning weigh-in", "After workout").
    var note: String?

    /// Optional body fat percentage (1-60%), stored as Decimal for precision.
    var bodyFatPercentage: Decimal?

    /// Timestamp of last edit, `nil` if never modified after creation.
    var modifiedDate: Date?

    /// Creates a new weight entry.
    /// - Parameters:
    ///   - weight: The numeric weight value
    ///   - unit: Unit of measurement (defaults to pounds)
    ///   - date: When the weight was recorded (defaults to now)
    ///   - note: Optional context note
    ///   - bodyFatPercentage: Optional body fat percentage
    init(weight: Double, unit: WeightUnit = .lb, date: Date = .now, note: String? = nil, bodyFatPercentage: Decimal? = nil) {
        self.weightValue = weight
        self.weightUnit = unit.rawValue
        self.date = date
        self.note = note
        self.bodyFatPercentage = bodyFatPercentage
        // modifiedDate is nil on creation, set when entry is edited
    }

    /// Returns the weight converted to the specified unit.
    ///
    /// Handles conversion between lb and kg using standard conversion factors.
    /// If the stored unit matches the requested unit, returns the value unchanged.
    ///
    /// - Parameter unit: The target unit for the weight value
    /// - Returns: The weight value converted to the target unit
    func weightValue(in unit: WeightUnit) -> Double {
        let currentUnit = WeightUnit(rawValue: weightUnit) ?? .lb
        return weightValue.weightValue(from: currentUnit, to: unit)
    }
    
    // MARK: - Sample Data Generation
    //
    // Three datasets serve different preview/testing purposes:
    // - sampleData: Full year of entries for comprehensive previews (30 entries)
    // - shortSampleData: 2 weeks of entries for simulator builds (14 entries)
    // - initialData: Minimal seed data for first-launch experience (5 entries)
    //
    // Implementation uses a single generator with lazy caching for performance.

    /// Entry specification for data-driven sample generation
    private typealias EntrySpec = (weight: Double, days: Int, note: String?, bodyFat: Decimal?)

    /// Generates a date with fixed time component for deterministic previews
    /// - Parameters:
    ///   - baseDate: The reference date to offset from
    ///   - days: Number of days to add (positive) or subtract (negative)
    ///   - hour: Fixed hour for the time (default 8 for morning weigh-ins)
    ///   - minute: Fixed minute for the time (default 0)
    /// - Returns: Date with fixed time component
    private static func fixedDate(
        from baseDate: Date,
        addingDays days: Int,
        hour: Int = 8,
        minute: Int = 0
    ) -> Date {
        let calendar = Calendar.current
        guard let withDays = calendar.date(byAdding: .day, value: days, to: baseDate) else {
            return baseDate
        }
        // Set fixed time components for deterministic previews
        let components = DateComponents(hour: hour, minute: minute)
        return calendar.date(bySettingHour: components.hour ?? 8,
                            minute: components.minute ?? 0,
                            second: 0,
                            of: withDays) ?? withDays
    }

    /// Generates entries from a data-driven specification
    /// - Parameters:
    ///   - specs: Array of (weight, dayOffset, note, bodyFat) tuples
    ///   - baseDate: Reference date for day offsets
    ///   - daysAreNegative: If true, day values are subtracted from baseDate
    ///   - hour: Fixed hour for all entries (default 8 AM)
    /// - Returns: Array of WeightEntry objects
    private static func generateEntries(
        from specs: [EntrySpec],
        baseDate: Date,
        daysAreNegative: Bool = false,
        hour: Int = 8
    ) -> [WeightEntry] {
        specs.map { spec in
            WeightEntry(
                weight: spec.weight,
                date: fixedDate(
                    from: baseDate,
                    addingDays: daysAreNegative ? -spec.days : spec.days,
                    hour: hour
                ),
                note: spec.note,
                bodyFatPercentage: spec.bodyFat
            )
        }
    }

    // MARK: - Cached Sample Data
    // Using nonisolated(unsafe) for lazy initialization of preview-only data.
    // This avoids regenerating entries on every computed property access.

    private nonisolated(unsafe) static var _sampleDataCache: [WeightEntry]?
    private nonisolated(unsafe) static var _shortSampleDataCache: [WeightEntry]?
    private nonisolated(unsafe) static var _initialDataCache: [WeightEntry]?

    /// Full sample data sorted by date descending (newest first).
    /// Used in previews requiring sorted data display.
    static var sortedSampleData: [WeightEntry] {
        sampleData.sorted { $0.date > $1.date }
    }

    /// Comprehensive sample data spanning ~1 year with 30 entries.
    /// Shows realistic weight loss journey from 200 lb to goal weight.
    /// Used for chart previews and "All Time" range testing.
    static var sampleData: [WeightEntry] {
        if let cached = _sampleDataCache { return cached }

        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: .now)!
        let specs: [EntrySpec] = [
            (200.0, 0, "Starting weight", 22.0),
            (199.2, 2, nil, 21.8),
            (198.5, 4, "Monthly check-in", 21.6),
            (197.8, 5, nil, 21.4),
            (196.9, 5, nil, 21.2),
            (195.5, 6, "Monthly check-in", 21.0),
            (194.7, 12, nil, 20.8),
            (193.8, 14, nil, 20.6),
            (192.5, 18, "Monthly check-in", 20.4),
            (191.6, 25, nil, 20.2),
            (190.8, 31, nil, 20.0),
            (189.5, 31, "Monthly check-in", 19.8),
            (188.7, 40, nil, 19.6),
            (187.9, 50, nil, 19.4),
            (186.5, 55, "Monthly check-in", 19.2),
            (185.8, 66, nil, 19.0),
            (184.9, 80, nil, 18.8),
            (183.5, 100, "Monthly check-in", 18.6),
            (182.7, 120, nil, 18.4),
            (172.9, 140, nil, 18.2),
            (170.5, 338, "Monthly check-in", 18.0),
            (169.8, 340, nil, 17.8),
            (167.9, 342, nil, 17.6),
            (165.5, 343, "Monthly check-in", 17.4),
            (165.8, 343, nil, 17.2),
            (166.2, 344, nil, 17.0),
            (164.8, 345, "Monthly check-in", 16.8),
            (163.5, 346, nil, 16.6),
            (163.3, 347, nil, 16.4),
            (162.0, 348, "Goal weight reached!", 16.2)
        ]

        let data = generateEntries(from: specs, baseDate: startDate)
        _sampleDataCache = data
        return data
    }

    /// Short sample data spanning 2 weeks with 14 entries.
    /// Used in simulator builds for quick iteration without database.
    /// Dates are relative to "today" for realistic 7-day chart views.
    static var shortSampleData: [WeightEntry] {
        if let cached = _shortSampleDataCache { return cached }

        let specs: [EntrySpec] = [
            (200.0, 14, "Started tracking", 25.0),
            (197.2, 13, nil, 24.5),
            (193.8, 12, nil, 24.0),
            (194.5, 11, "Good workout", 23.5),
            (190.8, 10, nil, 23.0),
            (191.2, 9, nil, 22.5),
            (185.8, 8, "One week in", 22.0),
            (180.5, 7, nil, 21.5),
            (182.3, 6, nil, 21.0),
            (179.8, 5, "Getting closer", 20.5),
            (175.2, 4, nil, 20.0),
            (176.8, 3, nil, 19.5),
            (170.5, 2, "Almost there", 19.0),
            (171.0, 1, "Goal weight reached!", 18.5)
        ]

        let data = generateEntries(from: specs, baseDate: .now, daysAreNegative: true)
            .sorted { $0.date > $1.date }
        _shortSampleDataCache = data
        return data
    }

    /// Minimal seed data for first-launch experience (5 entries).
    /// Inserted when user's database is empty to demonstrate app features.
    /// Small enough to delete easily, large enough to show chart functionality.
    static var initialData: [WeightEntry] {
        if let cached = _initialDataCache { return cached }

        let specs: [EntrySpec] = [
            (182.3, 7, nil, 21.0),
            (179.8, 5, "Getting closer", 20.5),
            (175.2, 4, nil, 20.0),
            (175.4, 3, nil, 20.0),
            (176.8, 3, nil, 19.5)
        ]

        let data = generateEntries(from: specs, baseDate: .now, daysAreNegative: true)
            .sorted { $0.date > $1.date }
        _initialDataCache = data
        return data
    }

    // MARK: - Edge Case Sample Data
    // These datasets are for testing specific edge cases in previews and tests.

    /// Empty dataset for testing empty state displays.
    static var emptyData: [WeightEntry] { [] }

    /// Single entry for testing edge case displays with minimal data.
    static var singleEntry: [WeightEntry] {
        [WeightEntry(
            weight: 175.0,
            date: fixedDate(from: .now, addingDays: 0),
            note: "Only entry"
        )]
    }

    /// Minimal dataset (2 entries) for testing prediction with sparse data.
    /// Two entries is the minimum needed for trend calculation.
    static var minimalData: [WeightEntry] {
        [
            WeightEntry(
                weight: 180.0,
                date: fixedDate(from: .now, addingDays: -7),
                note: "Start"
            ),
            WeightEntry(
                weight: 175.0,
                date: fixedDate(from: .now, addingDays: 0),
                note: "Current"
            )
        ]
    }

    /// Boundary dataset for testing min/max weight value handling.
    /// Tests the extremes allowed by WeightUnit validation.
    static var boundaryData: [WeightEntry] {
        [
            WeightEntry(
                weight: WeightUnit.lb.minWeight,  // 1.0 lb
                date: fixedDate(from: .now, addingDays: -2),
                note: "Minimum weight"
            ),
            WeightEntry(
                weight: WeightUnit.lb.maxWeight,  // 1500.0 lb
                date: fixedDate(from: .now, addingDays: -1),
                note: "Maximum weight"
            ),
            WeightEntry(
                weight: 175.0,  // Normal weight for comparison
                date: fixedDate(from: .now, addingDays: 0),
                note: "Normal weight"
            )
        ]
    }
}
