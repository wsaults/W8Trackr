//
//  MilestoneAchievement.swift
//  W8Trackr
//
//  Created by Claude on 1/10/26.
//

import Foundation
import SwiftData

/// Records when a user achieves a milestone in their weight goal journey
@Model
final class MilestoneAchievement {
    /// Unique identifier for the milestone
    var id: UUID = UUID()

    /// Type of milestone achieved (raw value of MilestoneType enum)
    var milestoneType: String = MilestoneType.quarter.rawValue

    /// When the milestone was achieved
    var dateAchieved: Date = Date.now

    /// User's weight when milestone was triggered
    var weightAtAchievement: Double = 0

    /// Goal weight at the time (for detecting goal changes)
    var goalWeightAtTime: Double = 0

    /// Start weight used for calculation (for audit/debugging)
    var startWeightAtTime: Double = 0

    /// Whether notification was successfully sent
    var notificationSent: Bool = false

    /// Calculated progress percentage at achievement
    var progressPercentage: Double = 0

    init(
        milestoneType: MilestoneType,
        weight: Double,
        goalWeight: Double,
        startWeight: Double,
        progressPercentage: Double
    ) {
        self.id = UUID()
        self.milestoneType = milestoneType.rawValue
        self.dateAchieved = Date.now
        self.weightAtAchievement = weight
        self.goalWeightAtTime = goalWeight
        self.startWeightAtTime = startWeight
        self.progressPercentage = progressPercentage
        self.notificationSent = false
    }
}

// MARK: - Sample Data for Previews

extension MilestoneAchievement {
    static var sampleData: [MilestoneAchievement] {
        [
            MilestoneAchievement(
                milestoneType: .quarter,
                weight: 195.0,
                goalWeight: 160.0,
                startWeight: 200.0,
                progressPercentage: 25.0
            ),
            MilestoneAchievement(
                milestoneType: .half,
                weight: 180.0,
                goalWeight: 160.0,
                startWeight: 200.0,
                progressPercentage: 50.0
            )
        ]
    }
}
