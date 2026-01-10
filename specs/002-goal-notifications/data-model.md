# Data Model: Goal Progress Notifications

**Feature**: 002-goal-notifications
**Date**: 2025-01-09
**Purpose**: Define data structures for milestone tracking and notification preferences

## Entity Relationship Diagram

```
┌──────────────────────────┐      ┌────────────────────────────┐
│     WeightEntry          │      │   MilestoneAchievement     │
│ (existing - no changes)  │      │        (NEW)               │
├──────────────────────────┤      ├────────────────────────────┤
│ - weightValue: Double    │──┐   │ - id: UUID                 │
│ - weightUnit: String     │  │   │ - milestoneType: String    │
│ - date: Date             │  │   │ - dateAchieved: Date       │
│ - note: String?          │  │   │ - weightAtAchievement: Double│
│ - bodyFatPercentage:     │  │   │ - goalWeightAtTime: Double │
│   Decimal?               │  │   │ - startWeightAtTime: Double│
└──────────────────────────┘  │   │ - notificationSent: Bool   │
                              │   │ - progressPercentage: Double│
                              │   └────────────────────────────┘
                              │
                              │   ┌────────────────────────────┐
                              │   │  GoalProgress              │
                              │   │  (computed, not persisted) │
                              │   ├────────────────────────────┤
                              └──▶│ - startWeight: Double      │
                                  │ - currentWeight: Double    │
                                  │ - goalWeight: Double       │
                                  │ - progressPercentage: Double│
                                  │ - nextMilestone: Milestone?│
                                  │ - isApproachingGoal: Bool  │
                                  └────────────────────────────┘
```

## SwiftData Model: MilestoneAchievement

```swift
import SwiftData
import Foundation

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
```

## MilestoneType Enum

```swift
enum MilestoneType: String, CaseIterable {
    case quarter = "25"          // 25% progress
    case half = "50"             // 50% progress
    case threeQuarter = "75"     // 75% progress
    case complete = "100"        // Goal achieved
    case approaching = "approaching"  // Within 5 lb/2.5 kg of goal

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
```

## GoalProgress Struct (Computed)

```swift
/// Represents current progress toward goal weight
/// Computed on-demand, not persisted
struct GoalProgress {
    let startWeight: Double
    let currentWeight: Double
    let goalWeight: Double
    let preferredUnit: WeightUnit

    /// Progress percentage (0-100+)
    var progressPercentage: Double {
        let totalChange = startWeight - goalWeight
        guard totalChange != 0 else { return 0 }
        let currentChange = startWeight - currentWeight
        return (currentChange / totalChange) * 100
    }

    /// Whether user is working toward lower weight
    var isLosingWeight: Bool {
        goalWeight < startWeight
    }

    /// Distance from goal in preferred units
    var distanceFromGoal: Double {
        abs(currentWeight - goalWeight)
    }

    /// Whether user is within approaching threshold
    var isApproachingGoal: Bool {
        let threshold: Double = preferredUnit == .lb ? 5.0 : 2.5
        return distanceFromGoal <= threshold && progressPercentage < 100
    }

    /// Next milestone to achieve (nil if all achieved)
    var nextMilestone: MilestoneType? {
        for milestone in [MilestoneType.quarter, .half, .threeQuarter, .complete] {
            if let threshold = milestone.threshold, progressPercentage < threshold {
                return milestone
            }
        }
        return nil
    }

    /// Milestones that have been crossed based on current progress
    var crossedMilestones: [MilestoneType] {
        var crossed: [MilestoneType] = []
        for milestone in [MilestoneType.quarter, .half, .threeQuarter, .complete] {
            if let threshold = milestone.threshold, progressPercentage >= threshold {
                crossed.append(milestone)
            }
        }
        if isApproachingGoal {
            crossed.append(.approaching)
        }
        return crossed
    }
}
```

## NotificationPreferences (AppStorage)

Preferences are stored in UserDefaults via `@AppStorage`, not SwiftData:

```swift
// In NotificationManager or SettingsView

@AppStorage("goalNotificationsEnabled") var goalNotificationsEnabled: Bool = true
@AppStorage("milestoneNotificationsEnabled") var milestoneNotificationsEnabled: Bool = true
@AppStorage("approachingNotificationsEnabled") var approachingNotificationsEnabled: Bool = true
@AppStorage("weeklySummaryEnabled") var weeklySummaryEnabled: Bool = true
@AppStorage("weeklySummaryDay") var weeklySummaryDay: Int = 1  // 1 = Sunday
@AppStorage("weeklySummaryHour") var weeklySummaryHour: Int = 9  // 9 AM
```

## Start Weight Determination

Per spec FR-012, start weight logic:

```swift
/// Determines the start weight for progress calculation
/// - Parameters:
///   - entries: All weight entries
///   - goalSetDate: When the goal was last set/changed (from UserDefaults)
/// - Returns: Start weight or nil if no valid entries
func determineStartWeight(entries: [WeightEntry], goalSetDate: Date?) -> Double? {
    guard !entries.isEmpty else { return nil }

    let sortedByDate = entries.sorted { $0.date < $1.date }

    if let goalDate = goalSetDate {
        // First entry on or after goal was set
        if let firstAfterGoal = sortedByDate.first(where: { $0.date >= goalDate }) {
            return firstAfterGoal.weightValue
        }
    }

    // Fallback: first entry ever
    return sortedByDate.first?.weightValue
}
```

## Duplicate Prevention Logic

```swift
/// Checks if a milestone has already been achieved for the current goal
/// - Parameters:
///   - milestone: The milestone type to check
///   - currentGoalWeight: Current goal weight (for detecting goal changes)
///   - achievements: Existing milestone achievements
/// - Returns: true if milestone should be triggered, false if duplicate
func shouldTriggerMilestone(
    _ milestone: MilestoneType,
    currentGoalWeight: Double,
    achievements: [MilestoneAchievement]
) -> Bool {
    // Check for existing achievement of this type
    let existingAchievements = achievements.filter {
        $0.milestoneType == milestone.rawValue
    }

    guard let mostRecent = existingAchievements.max(by: { $0.dateAchieved < $1.dateAchieved }) else {
        // No prior achievement - trigger it
        return true
    }

    // Check if goal changed significantly (>10%)
    let goalChangePercent = abs(currentGoalWeight - mostRecent.goalWeightAtTime) / mostRecent.goalWeightAtTime * 100
    if goalChangePercent > 10 {
        // Goal changed significantly - allow re-trigger
        return true
    }

    // Already achieved for this goal - don't trigger
    return false
}
```

## Model Container Configuration

Update `W8TrackrApp.swift`:

```swift
@main
struct W8TrackrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WeightEntry.self, MilestoneAchievement.self])
    }
}
```

## Query Examples

### Fetch All Achievements (Sorted by Date)

```swift
@Query(sort: \MilestoneAchievement.dateAchieved, order: .reverse)
var achievements: [MilestoneAchievement]
```

### Check for Specific Milestone

```swift
let descriptor = FetchDescriptor<MilestoneAchievement>(
    predicate: #Predicate { $0.milestoneType == "50" }
)
let halfwayAchievements = try modelContext.fetch(descriptor)
```

### Achievements for Current Goal

```swift
func achievementsForGoal(_ goalWeight: Double, tolerance: Double = 0.1) -> FetchDescriptor<MilestoneAchievement> {
    FetchDescriptor<MilestoneAchievement>(
        predicate: #Predicate {
            abs($0.goalWeightAtTime - goalWeight) <= tolerance
        },
        sortBy: [SortDescriptor(\.dateAchieved, order: .reverse)]
    )
}
```

## Sample Data for Previews

```swift
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
```
