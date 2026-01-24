//
//  Milestone.swift
//  W8Trackr
//
//  Created by Claude on 1/8/26.
//

import Foundation
import SwiftData

/// Configurable interval for milestone celebrations
enum MilestoneInterval: String, CaseIterable {
    case five = "5"
    case ten = "10"
    case fifteen = "15"

    /// Interval value in pounds
    var pounds: Double {
        switch self {
        case .five: return 5.0
        case .ten: return 10.0
        case .fifteen: return 15.0
        }
    }

    /// Interval value in kilograms (rounded for clean UX)
    var kilograms: Double {
        switch self {
        case .five: return 2.0    // ~2.27 kg
        case .ten: return 5.0     // ~4.54 kg
        case .fifteen: return 7.0 // ~6.80 kg
        }
    }

    /// Get interval value for the specified unit
    func value(for unit: WeightUnit) -> Double {
        switch unit {
        case .lb: return pounds
        case .kg: return kilograms
        }
    }

    /// Display label showing value and unit
    func displayLabel(for unit: WeightUnit) -> String {
        let value = Int(self.value(for: unit))
        return "\(value) \(unit.rawValue)"
    }
}

/// Persisted record of a completed milestone
@Model
final class CompletedMilestone {
    var targetWeight: Double = 0
    var weightUnit: String = WeightUnit.lb.rawValue
    var achievedDate: Date = Date.now
    var startWeight: Double = 0
    var celebrationShown: Bool = false

    init(targetWeight: Double, unit: WeightUnit, achievedDate: Date = .now, startWeight: Double) {
        self.targetWeight = targetWeight
        self.weightUnit = unit.rawValue
        self.achievedDate = achievedDate
        self.startWeight = startWeight
    }

    func targetWeight(in unit: WeightUnit) -> Double {
        let storedUnit = WeightUnit(rawValue: weightUnit) ?? .lb
        return storedUnit.convert(targetWeight, to: unit)
    }
}

/// Runtime calculation of milestone progress
struct MilestoneProgress {
    let currentWeight: Double
    let nextMilestone: Double
    let previousMilestone: Double
    let goalWeight: Double
    let unit: WeightUnit
    let completedMilestones: [Double]

    /// Progress from previous milestone to next milestone (0.0 to 1.0)
    /// Returns 0.0 if user is moving in the wrong direction (gaining when trying to lose, or vice versa)
    var progressToNextMilestone: Double {
        let totalDistance = abs(previousMilestone - nextMilestone)
        guard totalDistance > 0 else { return 1.0 }

        let isLosingWeight = goalWeight < previousMilestone

        // Check if user is moving in the correct direction
        if isLosingWeight {
            // For weight loss: current should be <= previous (moving down)
            // If current > previous, user gained weight - return 0
            guard currentWeight <= previousMilestone else { return 0.0 }
            let traveled = previousMilestone - currentWeight
            return min(1.0, max(0.0, traveled / totalDistance))
        } else {
            // For weight gain: current should be >= previous (moving up)
            // If current < previous, user lost weight - return 0
            guard currentWeight >= previousMilestone else { return 0.0 }
            let traveled = currentWeight - previousMilestone
            return min(1.0, max(0.0, traveled / totalDistance))
        }
    }

    /// Weight remaining to reach next milestone
    var weightToNextMilestone: Double {
        abs(currentWeight - nextMilestone)
    }

    /// Whether we've reached the final goal
    var hasReachedGoal: Bool {
        if goalWeight < previousMilestone {
            // Losing weight
            return currentWeight <= goalWeight
        } else {
            // Gaining weight
            return currentWeight >= goalWeight
        }
    }
}

/// Utility for computing milestones
enum MilestoneCalculator {
    /// Milestone interval by unit, using user preference
    static func interval(for unit: WeightUnit, preference: MilestoneInterval = .five) -> Double {
        preference.value(for: unit)
    }

    /// Generate all milestone targets between start and goal weights
    static func generateMilestones(
        startWeight: Double,
        goalWeight: Double,
        unit: WeightUnit,
        intervalPreference: MilestoneInterval = .five
    ) -> [Double] {
        let interval = interval(for: unit, preference: intervalPreference)
        let isLosingWeight = goalWeight < startWeight

        var milestones: [Double] = []
        var current = startWeight

        if isLosingWeight {
            // Round down to next milestone (e.g., 198 -> 195)
            current = floor(startWeight / interval) * interval
            while current > goalWeight {
                current -= interval
                if current > goalWeight {
                    milestones.append(current)
                }
            }
        } else {
            // Round up to next milestone (e.g., 152 -> 155)
            current = ceil(startWeight / interval) * interval
            while current < goalWeight {
                current += interval
                if current < goalWeight {
                    milestones.append(current)
                }
            }
        }

        // Always include goal as final milestone
        milestones.append(goalWeight)

        return milestones
    }

    /// Calculate current milestone progress
    static func calculateProgress(
        currentWeight: Double,
        startWeight: Double,
        goalWeight: Double,
        unit: WeightUnit,
        completedMilestones: [CompletedMilestone],
        intervalPreference: MilestoneInterval = .five
    ) -> MilestoneProgress {
        let allMilestones = generateMilestones(
            startWeight: startWeight,
            goalWeight: goalWeight,
            unit: unit,
            intervalPreference: intervalPreference
        )
        let completedWeights = Set(completedMilestones.map { $0.targetWeight(in: unit) })
        let isLosingWeight = goalWeight < startWeight

        // Find next uncompleted milestone
        let nextMilestone: Double
        let previousMilestone: Double

        if isLosingWeight {
            // Next milestone is the first one at or below current weight (includes milestones we've just reached)
            nextMilestone = allMilestones.first { $0 <= currentWeight } ?? goalWeight
            // Previous milestone is the last one above current weight (the one we came from)
            previousMilestone = allMilestones.last { $0 > currentWeight } ?? startWeight
        } else {
            // Next milestone is the first one at or above current weight
            nextMilestone = allMilestones.first { $0 >= currentWeight } ?? goalWeight
            // Previous milestone is the last one below current weight
            previousMilestone = allMilestones.last { $0 < currentWeight } ?? startWeight
        }

        return MilestoneProgress(
            currentWeight: currentWeight,
            nextMilestone: nextMilestone,
            previousMilestone: previousMilestone,
            goalWeight: goalWeight,
            unit: unit,
            completedMilestones: Array(completedWeights)
        )
    }
}
