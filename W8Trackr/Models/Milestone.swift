//
//  Milestone.swift
//  W8Trackr
//
//  Created by Claude on 1/8/26.
//

import Foundation
import SwiftData

/// Persisted record of a completed milestone
@Model
final class CompletedMilestone {
    var targetWeight: Double = 0
    var weightUnit: String = WeightUnit.lb.rawValue
    var achievedDate: Date = Date.now
    var startWeight: Double = 0

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
    var progressToNextMilestone: Double {
        let totalDistance = abs(previousMilestone - nextMilestone)
        guard totalDistance > 0 else { return 1.0 }
        let traveled = abs(previousMilestone - currentWeight)
        return min(1.0, max(0.0, traveled / totalDistance))
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
    /// Milestone interval by unit (5 lbs or 2 kg)
    static func interval(for unit: WeightUnit) -> Double {
        switch unit {
        case .lb: return 5.0
        case .kg: return 2.0
        }
    }

    /// Generate all milestone targets between start and goal weights
    static func generateMilestones(startWeight: Double, goalWeight: Double, unit: WeightUnit) -> [Double] {
        let interval = interval(for: unit)
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
        completedMilestones: [CompletedMilestone]
    ) -> MilestoneProgress {
        let allMilestones = generateMilestones(startWeight: startWeight, goalWeight: goalWeight, unit: unit)
        let completedWeights = Set(completedMilestones.map { $0.targetWeight(in: unit) })
        let isLosingWeight = goalWeight < startWeight

        // Find next uncompleted milestone
        let nextMilestone: Double
        let previousMilestone: Double

        if isLosingWeight {
            // Next milestone is the first one we haven't passed yet
            nextMilestone = allMilestones.first { $0 < currentWeight } ?? goalWeight
            // Previous milestone is the last one we passed
            previousMilestone = allMilestones.last { $0 >= currentWeight } ?? startWeight
        } else {
            nextMilestone = allMilestones.first { $0 > currentWeight } ?? goalWeight
            previousMilestone = allMilestones.last { $0 <= currentWeight } ?? startWeight
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
