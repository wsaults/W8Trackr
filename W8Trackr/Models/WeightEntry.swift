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
    var weightValue: Double
    var weightUnit: String
    var date: Date
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
    
    // Convenience method to get weight in a specific unit
    func weightValue(in unit: UnitMass) -> Double {
        return weight.converted(to: unit).value
    }
}

// MARK: - Sample Data
extension WeightEntry {
    static var sampleData: [WeightEntry] {
        let calendar = Calendar.current
        return [
            WeightEntry(
                weight: 185.5,
                date: calendar.date(byAdding: .day, value: -30, to: .now)!,
                note: "Started new diet",
                bodyFatPercentage: 20.5
            ),
            WeightEntry(
                weight: 183.2,
                date: calendar.date(byAdding: .day, value: -20, to: .now)!,
                note: "Good progress",
                bodyFatPercentage: 19.8
            ),
            WeightEntry(
                weight: 181.7,
                date: calendar.date(byAdding: .day, value: -10, to: .now)!,
                bodyFatPercentage: 19.2
            ),
            WeightEntry(
                weight: 180.3,
                date: .now,
                note: "Hit my first goal!",
                bodyFatPercentage: 18.5
            )
        ]
    }
}
