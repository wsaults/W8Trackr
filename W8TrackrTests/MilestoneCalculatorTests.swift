//
//  MilestoneCalculatorTests.swift
//  W8TrackrTests
//
//  Tests for milestone generation and progress calculation
//

import Foundation
import Testing
@testable import W8Trackr

// MARK: - Milestone Generation Tests

@Suite("Milestone Generation")
struct MilestoneGenerationTests {

    @Test("Generates correct milestones for weight loss")
    func generatesMilestonesForWeightLoss() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            intervalPreference: .five
        )

        // Should include milestones at 5lb intervals from 195 down to 165, plus goal
        #expect(milestones.contains(195))
        #expect(milestones.contains(190))
        #expect(milestones.contains(185))
        #expect(milestones.contains(180))
        #expect(milestones.contains(175))
        #expect(milestones.contains(170))
        #expect(milestones.contains(165))
        #expect(milestones.contains(160)) // goal
        #expect(milestones.count == 8)
    }

    @Test("Generates correct milestones for weight gain")
    func generatesMilestonesForWeightGain() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            intervalPreference: .five
        )

        // Should include milestones at 5lb intervals from 125 up to 145, plus goal
        #expect(milestones.contains(125))
        #expect(milestones.contains(130))
        #expect(milestones.contains(135))
        #expect(milestones.contains(140))
        #expect(milestones.contains(145))
        #expect(milestones.contains(150)) // goal
    }

    @Test("Includes goal weight as final milestone")
    func includesGoalAsFinalMilestone() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 200,
            goalWeight: 162, // Not on 5lb boundary
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones.last == 162)
    }

    @Test("Respects 10lb interval preference")
    func respectsTenPoundInterval() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            intervalPreference: .ten
        )

        #expect(milestones.contains(190))
        #expect(milestones.contains(180))
        #expect(milestones.contains(170))
        #expect(milestones.contains(160))
        #expect(!milestones.contains(195)) // Not at 10lb intervals
    }

    @Test("Handles kilogram intervals correctly")
    func handlesKilogramIntervals() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 90,
            goalWeight: 70,
            unit: .kg,
            intervalPreference: .five // Maps to 2kg for kilograms
        )

        // 2kg intervals from 88 down to 72, plus goal 70
        #expect(milestones.contains(88))
        #expect(milestones.contains(86))
        #expect(milestones.contains(70))
    }
}

// MARK: - Progress Calculation Tests

@Suite("Milestone Progress Calculation")
struct MilestoneProgressTests {

    @Test("Progress is 0% at start of milestone segment")
    func progressZeroAtStart() {
        let progress = MilestoneProgress(
            currentWeight: 180,
            nextMilestone: 175,
            previousMilestone: 180,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(progress.progressToNextMilestone == 0.0)
    }

    @Test("Progress is 100% when milestone is reached")
    func progressFullAtMilestone() {
        let progress = MilestoneProgress(
            currentWeight: 175,
            nextMilestone: 175,
            previousMilestone: 180,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(progress.progressToNextMilestone == 1.0)
    }

    @Test("Progress is 50% halfway through segment")
    func progressFiftyPercentHalfway() {
        let progress = MilestoneProgress(
            currentWeight: 177.5,
            nextMilestone: 175,
            previousMilestone: 180,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(progress.progressToNextMilestone == 0.5)
    }

    @Test("Weight to next milestone calculated correctly")
    func weightToNextMilestoneCorrect() {
        let progress = MilestoneProgress(
            currentWeight: 178,
            nextMilestone: 175,
            previousMilestone: 180,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(progress.weightToNextMilestone == 3.0)
    }

    @Test("Progress clamped to 0-1 range")
    func progressClampedToValidRange() {
        // Simulate going past the milestone
        let progress = MilestoneProgress(
            currentWeight: 174,
            nextMilestone: 175,
            previousMilestone: 180,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(progress.progressToNextMilestone <= 1.0)
        #expect(progress.progressToNextMilestone >= 0.0)
    }
}

// MARK: - Bug Regression Tests

@Suite("Milestone Progress Bug Fixes")
struct MilestoneProgressBugTests {

    // BUG: Progress shows 100% when user gains weight instead of loses
    @Test("Progress is 0% when user goes in wrong direction (weight loss goal)")
    func progressZeroWhenGainingWeightOnLossGoal() {
        // User started at 185, wants to get to 160, but gained weight to 190
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 190,
            startWeight: 185,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        // Should show 0% progress, not 100%
        #expect(progress.progressToNextMilestone == 0.0,
                "Progress should be 0% when user gains weight on weight loss goal, but was \(progress.progressToNextMilestone)")
    }

    @Test("Progress is 0% when user goes in wrong direction (weight gain goal)")
    func progressZeroWhenLosingWeightOnGainGoal() {
        // User started at 130, wants to get to 150, but lost weight to 125
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 125,
            startWeight: 130,
            goalWeight: 150,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        // Should show 0% progress
        #expect(progress.progressToNextMilestone == 0.0,
                "Progress should be 0% when user loses weight on weight gain goal, but was \(progress.progressToNextMilestone)")
    }

    @Test("Progress bar shows partial progress when 19 lbs away from goal")
    func progressNotFullWhen19LbsAway() {
        // Real bug scenario: milestone shows full bar when 19 lbs away
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 179,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        // 19 lbs from goal = should NOT show full bar
        // Current = 179, next milestone = 175, prev = 180
        // Progress should be (180-179)/(180-175) = 1/5 = 0.2
        #expect(progress.progressToNextMilestone < 1.0,
                "Progress should not be full when 19 lbs away, but was \(progress.progressToNextMilestone)")
        #expect(progress.progressToNextMilestone > 0.0,
                "Progress should show some progress")
    }

    @Test("Progress correct when current weight equals start weight")
    func progressZeroAtStartWeight() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 200,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        // At start weight, should be 0% toward first milestone
        #expect(progress.progressToNextMilestone == 0.0)
    }

    @Test("Progress correct when current weight is between start and first milestone")
    func progressCorrectBetweenStartAndFirstMilestone() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 197,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        // Start = 200, first milestone = 195, current = 197
        // Progress = (200-197)/(200-195) = 3/5 = 0.6
        #expect(progress.progressToNextMilestone > 0.5)
        #expect(progress.progressToNextMilestone < 0.7)
    }
}

// MARK: - Full Integration Tests

@Suite("Milestone Calculator Integration")
struct MilestoneCalculatorIntegrationTests {

    @Test("Full weight loss journey milestones")
    func fullWeightLossJourney() {
        let start = 200.0
        let goal = 160.0

        // At start
        var progress = MilestoneCalculator.calculateProgress(
            currentWeight: 200,
            startWeight: start,
            goalWeight: goal,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )
        #expect(progress.nextMilestone == 195)
        #expect(progress.progressToNextMilestone == 0.0)

        // Halfway to first milestone
        progress = MilestoneCalculator.calculateProgress(
            currentWeight: 197.5,
            startWeight: start,
            goalWeight: goal,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )
        #expect(progress.progressToNextMilestone == 0.5)

        // At first milestone
        progress = MilestoneCalculator.calculateProgress(
            currentWeight: 195,
            startWeight: start,
            goalWeight: goal,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )
        #expect(progress.progressToNextMilestone == 1.0)

        // Past first milestone, working on second
        progress = MilestoneCalculator.calculateProgress(
            currentWeight: 192,
            startWeight: start,
            goalWeight: goal,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )
        #expect(progress.nextMilestone == 190)
        #expect(progress.previousMilestone == 195)
        #expect(progress.progressToNextMilestone > 0.5)
    }

    @Test("Weight to next milestone shows correct remaining weight")
    func weightToNextMilestoneAccurate() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 181,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        // Current = 181, next = 180, remaining = 1
        #expect(progress.weightToNextMilestone == 1.0)
    }
}
