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
    
    var defaultWeight: Double {
        switch self {
        case .lb:
            return 180.0
        case .kg:
            return 80.0
        }
    }
}

@Model
final class WeightEntry {
    var weightValue: Double = 0
    var weightUnit: String = WeightUnit.lb.rawValue
    var date: Date = Date.now
    var note: String?
    var bodyFatPercentage: Decimal?

    init(weight: Double, unit: UnitMass = .pounds, date: Date = .now, note: String? = nil, bodyFatPercentage: Decimal? = nil) {
        self.weightValue = weight
        self.weightUnit = unit.symbol
        self.date = date
        self.note = note
        self.bodyFatPercentage = bodyFatPercentage
    }
    
    func weightValue(in unit: WeightUnit) -> Double {
        if weightUnit == WeightUnit.lb.rawValue, unit == .kg {
            return weightValue * 0.453592 // Convert from lb to kg
        } else if weightUnit == WeightUnit.kg.rawValue, unit == .lb {
            return weightValue * 2.20462 // Convert from kg to lb
        }
        
        return weightValue
    }
    
    // MARK: - Sample Data
    static var sortedSampleData: [WeightEntry] {
        sampleData.sorted { $0.date > $1.date }
    }
    
    static var sampleData: [WeightEntry] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -1, to: .now)!
        
        func randomDateTime(daysToAdd: Int) -> Date {
            let dateWithDays = calendar.date(byAdding: .day, value: daysToAdd, to: startDate)!
            let dateWithHours = calendar.date(byAdding: .hour, value: Int.random(in: 0...23), to: dateWithDays)!
            return calendar.date(byAdding: .minute, value: Int.random(in: 0...59), to: dateWithHours)!
        }
        
        return [
            WeightEntry(weight: 200.0, date: randomDateTime(daysToAdd: 0), note: "Starting weight", bodyFatPercentage: 22.0),
            WeightEntry(weight: 199.2, date: randomDateTime(daysToAdd: 2), bodyFatPercentage: 21.8),
            WeightEntry(weight: 198.5, date: randomDateTime(daysToAdd: 4), note: "Monthly check-in", bodyFatPercentage: 21.6),
            WeightEntry(weight: 197.8, date: randomDateTime(daysToAdd: 5), bodyFatPercentage: 21.4),
            WeightEntry(weight: 196.9, date: randomDateTime(daysToAdd: 5), bodyFatPercentage: 21.2),
            WeightEntry(weight: 195.5, date: randomDateTime(daysToAdd: 6), note: "Monthly check-in", bodyFatPercentage: 21.0),
            WeightEntry(weight: 194.7, date: randomDateTime(daysToAdd: 12), bodyFatPercentage: 20.8),
            WeightEntry(weight: 193.8, date: randomDateTime(daysToAdd: 14), bodyFatPercentage: 20.6),
            WeightEntry(weight: 192.5, date: randomDateTime(daysToAdd: 18), note: "Monthly check-in", bodyFatPercentage: 20.4),
            WeightEntry(weight: 191.6, date: randomDateTime(daysToAdd: 25), bodyFatPercentage: 20.2),
            WeightEntry(weight: 190.8, date: randomDateTime(daysToAdd: 31), bodyFatPercentage: 20.0),
            WeightEntry(weight: 189.5, date: randomDateTime(daysToAdd: 31), note: "Monthly check-in", bodyFatPercentage: 19.8),
            WeightEntry(weight: 188.7, date: randomDateTime(daysToAdd: 40), bodyFatPercentage: 19.6),
            WeightEntry(weight: 187.9, date: randomDateTime(daysToAdd: 50), bodyFatPercentage: 19.4),
            WeightEntry(weight: 186.5, date: randomDateTime(daysToAdd: 55), note: "Monthly check-in", bodyFatPercentage: 19.2),
            WeightEntry(weight: 185.8, date: randomDateTime(daysToAdd: 66), bodyFatPercentage: 19.0),
            WeightEntry(weight: 184.9, date: randomDateTime(daysToAdd: 80), bodyFatPercentage: 18.8),
            WeightEntry(weight: 183.5, date: randomDateTime(daysToAdd: 100), note: "Monthly check-in", bodyFatPercentage: 18.6),
            WeightEntry(weight: 182.7, date: randomDateTime(daysToAdd: 120), bodyFatPercentage: 18.4),
            WeightEntry(weight: 172.9, date: randomDateTime(daysToAdd: 140), bodyFatPercentage: 18.2),
            WeightEntry(weight: 170.5, date: randomDateTime(daysToAdd: 338), note: "Monthly check-in", bodyFatPercentage: 18.0),
            WeightEntry(weight: 169.8, date: randomDateTime(daysToAdd: 340), bodyFatPercentage: 17.8),
            WeightEntry(weight: 167.9, date: randomDateTime(daysToAdd: 342), bodyFatPercentage: 17.6),
            WeightEntry(weight: 165.5, date: randomDateTime(daysToAdd: 343), note: "Monthly check-in", bodyFatPercentage: 17.4),
            WeightEntry(weight: 165.8, date: randomDateTime(daysToAdd: 343), bodyFatPercentage: 17.2),
            WeightEntry(weight: 166.2, date: randomDateTime(daysToAdd: 344), bodyFatPercentage: 17.0),
            WeightEntry(weight: 164.8, date: randomDateTime(daysToAdd: 345), note: "Monthly check-in", bodyFatPercentage: 16.8),
            WeightEntry(weight: 163.5, date: randomDateTime(daysToAdd: 346), bodyFatPercentage: 16.6),
            WeightEntry(weight: 163.3, date: randomDateTime(daysToAdd: 347), bodyFatPercentage: 16.4),
            WeightEntry(weight: 162.0, date: randomDateTime(daysToAdd: 348), note: "Goal weight reached!", bodyFatPercentage: 16.2)
        ]
    }
    
    static var shortSampleData: [WeightEntry] {
        let calendar = Calendar.current
        let today = Date.now
        
        func dateTime(daysAgo: Int) -> Date {
            let dateWithDays = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dateWithHours = calendar.date(byAdding: .hour, value: Int.random(in: 6...10), to: dateWithDays)!
            return calendar.date(byAdding: .minute, value: Int.random(in: 0...59), to: dateWithHours)!
        }
        
        return [
            WeightEntry(weight: 200.0, date: dateTime(daysAgo: 13), note: "Started tracking", bodyFatPercentage: 25.0),
            WeightEntry(weight: 197.2, date: dateTime(daysAgo: 12), bodyFatPercentage: 24.5),
            WeightEntry(weight: 193.8, date: dateTime(daysAgo: 11), bodyFatPercentage: 24.0),
            WeightEntry(weight: 189.5, date: dateTime(daysAgo: 10), note: "Good workout", bodyFatPercentage: 23.5),
            WeightEntry(weight: 185.8, date: dateTime(daysAgo: 9), bodyFatPercentage: 23.0),
            WeightEntry(weight: 182.2, date: dateTime(daysAgo: 8), bodyFatPercentage: 22.5),
            WeightEntry(weight: 177.8, date: dateTime(daysAgo: 7), note: "One week in", bodyFatPercentage: 22.0),
            WeightEntry(weight: 175.5, date: dateTime(daysAgo: 6), bodyFatPercentage: 21.5),
            WeightEntry(weight: 172.3, date: dateTime(daysAgo: 5), bodyFatPercentage: 21.0),
            WeightEntry(weight: 168.8, date: dateTime(daysAgo: 4), note: "Getting closer", bodyFatPercentage: 20.5),
            WeightEntry(weight: 166.2, date: dateTime(daysAgo: 3), bodyFatPercentage: 20.0),
            WeightEntry(weight: 163.8, date: dateTime(daysAgo: 2), bodyFatPercentage: 19.5),
            WeightEntry(weight: 161.5, date: dateTime(daysAgo: 1), note: "Almost there", bodyFatPercentage: 19.0),
            WeightEntry(weight: 160.0, date: dateTime(daysAgo: 0), note: "Goal weight reached!", bodyFatPercentage: 18.5)
        ].sorted { $0.date > $1.date }
    }
}
