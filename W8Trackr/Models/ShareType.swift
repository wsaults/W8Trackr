//
//  ShareType.swift
//  W8Trackr
//
//  Types of content that can be shared for social sharing feature.
//

import Foundation

/// Types of content that can be shared via social sharing
enum ShareType: String, CaseIterable {
    case milestoneAchievement   // 25%, 50%, 75%, 100% progress
    case progressSummary        // Overall progress to date
    case goalAchieved           // Final goal completion

    /// Celebration emoji for the share type
    var celebrationEmoji: String {
        switch self {
        case .milestoneAchievement: return "🎉"
        case .progressSummary: return "📈"
        case .goalAchieved: return "🏆"
        }
    }

    /// Default title for share content
    var defaultTitle: String {
        switch self {
        case .milestoneAchievement: return "Progress Milestone"
        case .progressSummary: return "My Progress"
        case .goalAchieved: return "Goal Achieved!"
        }
    }
}
