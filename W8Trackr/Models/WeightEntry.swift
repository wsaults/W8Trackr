//
//  Entry.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Foundation
import SwiftData

@Model
final class WeightEntry {
    var weightValue: Double = 0
    var weightUnit: String = "lb"
    var date: Date = Date.now
    var note: String?
    var bodyFatPercentage: Decimal?
    
    var weight: Measurement<UnitMass> {
        get {
            Measurement(value: weightValue, unit: UnitMass(symbol: weightUnit))
        }
        set {
            weightValue = newValue.value
            weightUnit = newValue.unit.symbol
        }
    }
    
    init(weight: Double, unit: UnitMass = .pounds, date: Date = .now, note: String? = nil, bodyFatPercentage: Decimal? = nil) {
        self.weightValue = weight
        self.weightUnit = unit.symbol
        self.date = date
        self.note = note
        self.bodyFatPercentage = bodyFatPercentage
    }
    
    func weightValue(in unit: UnitMass) -> Double {
        weight.converted(to: unit).value
    }
}

// MARK: - Sample Data
extension WeightEntry {
    static var sortedSampleData: [WeightEntry] {
        sampleData.sorted { $0.date < $1.date }
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
            WeightEntry(weight: 199.2, date: randomDateTime(daysToAdd: 12), bodyFatPercentage: 21.8),
            WeightEntry(weight: 198.5, date: randomDateTime(daysToAdd: 24), note: "Monthly check-in", bodyFatPercentage: 21.6),
            WeightEntry(weight: 197.8, date: randomDateTime(daysToAdd: 36), bodyFatPercentage: 21.4),
            WeightEntry(weight: 196.9, date: randomDateTime(daysToAdd: 48), bodyFatPercentage: 21.2),
            WeightEntry(weight: 195.5, date: randomDateTime(daysToAdd: 84), note: "Monthly check-in", bodyFatPercentage: 21.0),
            WeightEntry(weight: 194.7, date: randomDateTime(daysToAdd: 84), bodyFatPercentage: 20.8),
            WeightEntry(weight: 193.8, date: randomDateTime(daysToAdd: 84), bodyFatPercentage: 20.6),
            WeightEntry(weight: 192.5, date: randomDateTime(daysToAdd: 96), note: "Monthly check-in", bodyFatPercentage: 20.4),
            WeightEntry(weight: 191.6, date: randomDateTime(daysToAdd: 108), bodyFatPercentage: 20.2),
            WeightEntry(weight: 190.8, date: randomDateTime(daysToAdd: 120), bodyFatPercentage: 20.0),
            WeightEntry(weight: 189.5, date: randomDateTime(daysToAdd: 132), note: "Monthly check-in", bodyFatPercentage: 19.8),
            WeightEntry(weight: 188.7, date: randomDateTime(daysToAdd: 132), bodyFatPercentage: 19.6),
            WeightEntry(weight: 187.9, date: randomDateTime(daysToAdd: 156), bodyFatPercentage: 19.4),
            WeightEntry(weight: 186.5, date: randomDateTime(daysToAdd: 168), note: "Monthly check-in", bodyFatPercentage: 19.2),
            WeightEntry(weight: 185.8, date: randomDateTime(daysToAdd: 180), bodyFatPercentage: 19.0),
            WeightEntry(weight: 184.9, date: randomDateTime(daysToAdd: 192), bodyFatPercentage: 18.8),
            WeightEntry(weight: 183.5, date: randomDateTime(daysToAdd: 192), note: "Monthly check-in", bodyFatPercentage: 18.6),
            WeightEntry(weight: 182.7, date: randomDateTime(daysToAdd: 216), bodyFatPercentage: 18.4),
            WeightEntry(weight: 181.9, date: randomDateTime(daysToAdd: 228), bodyFatPercentage: 18.2),
            WeightEntry(weight: 180.5, date: randomDateTime(daysToAdd: 240), note: "Monthly check-in", bodyFatPercentage: 18.0),
            WeightEntry(weight: 179.8, date: randomDateTime(daysToAdd: 240), bodyFatPercentage: 17.8),
            WeightEntry(weight: 178.9, date: randomDateTime(daysToAdd: 264), bodyFatPercentage: 17.6),
            WeightEntry(weight: 177.5, date: randomDateTime(daysToAdd: 276), note: "Monthly check-in", bodyFatPercentage: 17.4),
            WeightEntry(weight: 176.8, date: randomDateTime(daysToAdd: 288), bodyFatPercentage: 17.2),
            WeightEntry(weight: 176.2, date: randomDateTime(daysToAdd: 288), bodyFatPercentage: 17.0),
            WeightEntry(weight: 175.8, date: randomDateTime(daysToAdd: 312), note: "Monthly check-in", bodyFatPercentage: 16.8),
            WeightEntry(weight: 175.5, date: randomDateTime(daysToAdd: 324), bodyFatPercentage: 16.6),
            WeightEntry(weight: 175.3, date: randomDateTime(daysToAdd: 336), bodyFatPercentage: 16.4),
            WeightEntry(weight: 175.0, date: randomDateTime(daysToAdd: 348), note: "Goal weight reached!", bodyFatPercentage: 16.2)
        ]
    }
}
