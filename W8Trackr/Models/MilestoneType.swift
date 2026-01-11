//
//  MilestoneType.swift
//  W8Trackr
//
//  Created by Claude on 1/10/26.
//

import Foundation

/// Types of milestone achievements based on progress percentage
enum MilestoneType: String, CaseIterable {
    case quarter = "25"              // 25% progress
    case half = "50"                 // 50% progress
    case threeQuarter = "75"         // 75% progress
    case complete = "100"            // Goal achieved
    case approaching = "approaching" // Within 5 lb/2.5 kg of goal

    var displayName: String {
        switch self {
        case .quarter: return "25% Progress"
        case .half: return "Halfway There"
        case .threeQuarter: return "75% Progress"
        case .complete: return "Goal Achieved"
        case .approaching: return "Approaching Goal"
        }
    }

    var celebrationMessage: String {
        switch self {
        case .quarter: return "You're making progress! 25% of the way to your goal."
        case .half: return "Halfway there! Keep up the great work!"
        case .threeQuarter: return "Almost there! Just 25% left to reach your goal."
        case .complete: return "Congratulations! You've reached your goal weight!"
        case .approaching: return "You're so close! Just a few more to go."
        }
    }

    /// Threshold percentage for this milestone (nil for approaching)
    var threshold: Double? {
        switch self {
        case .quarter: return 25.0
        case .half: return 50.0
        case .threeQuarter: return 75.0
        case .complete: return 100.0
        case .approaching: return nil
        }
    }
}
