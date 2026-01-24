//
//  MilestonePopupTests.swift
//  W8TrackrTests
//
//  Comprehensive tests for milestone popup business logic.
//  Tests when milestone celebrations should appear.
//

import Foundation
import Testing
@testable import W8Trackr

// MARK: - Milestone Crossing Detection Tests

@Suite("Milestone Crossing Detection")
struct MilestoneCrossingTests {

    // MARK: - Weight Loss Crossing

    @Test("Detects single crossed milestone for weight loss")
    func detectsSingleCrossedMilestoneWeightLoss() {
        // Start: 200, Goal: 160, Current: 194 (crossed 195)
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 194,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .five
        )

        #expect(crossed.contains(195), "Should detect 195 as crossed")
        #expect(!crossed.contains(190), "Should not detect 190 as crossed yet")
    }

    @Test("Detects multiple crossed milestones for weight loss")
    func detectsMultipleCrossedMilestonesWeightLoss() {
        // Start: 200, Goal: 160, Current: 182 (crossed 195, 190, 185)
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 182,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .five
        )

        #expect(crossed.contains(195))
        #expect(crossed.contains(190))
        #expect(crossed.contains(185))
        #expect(!crossed.contains(180), "Should not include 180 (not yet crossed)")
    }

    @Test("Excludes already-completed milestones from detection")
    func excludesAlreadyCompletedMilestones() {
        // 195 already completed, current at 189 (also crossed 190)
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 189,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestoneWeights: [195],
            intervalPreference: .five
        )

        #expect(!crossed.contains(195), "195 already completed, should not be detected")
        #expect(crossed.contains(190), "190 should be detected as newly crossed")
    }

    @Test("Detects exact milestone boundary for weight loss")
    func detectsExactBoundaryWeightLoss() {
        // At exactly 195
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 195,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .five
        )

        #expect(crossed.contains(195), "Should detect milestone at exact boundary")
    }

    @Test("Returns empty when no milestones crossed yet")
    func returnsEmptyWhenNoCrossed() {
        // Current: 198, no milestones crossed
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 198,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .five
        )

        #expect(crossed.isEmpty, "Should return empty when weight hasn't reached any milestone")
    }

    // MARK: - Weight Gain Crossing

    @Test("Detects single crossed milestone for weight gain")
    func detectsSingleCrossedMilestoneWeightGain() {
        // Start: 120, Goal: 150, Current: 126 (crossed 125)
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 126,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .five
        )

        #expect(crossed.contains(125), "Should detect 125 as crossed for weight gain")
        #expect(!crossed.contains(130), "Should not detect 130 yet")
    }

    @Test("Detects multiple crossed milestones for weight gain")
    func detectsMultipleCrossedMilestonesWeightGain() {
        // Start: 120, Goal: 150, Current: 138 (crossed 125, 130, 135)
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 138,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .five
        )

        #expect(crossed.contains(125))
        #expect(crossed.contains(130))
        #expect(crossed.contains(135))
        #expect(!crossed.contains(140))
    }

    @Test("Detects exact milestone boundary for weight gain")
    func detectsExactBoundaryWeightGain() {
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 125,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .five
        )

        #expect(crossed.contains(125))
    }

    // MARK: - Goal Weight Detection

    @Test("Detects goal weight as crossed milestone")
    func detectsGoalWeightAsCrossed() {
        // At goal weight
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 160,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestoneWeights: [195, 190, 185, 180, 175, 170, 165],
            intervalPreference: .five
        )

        #expect(crossed.contains(160), "Should detect goal weight as milestone")
    }

    @Test("Detects passing goal weight for weight loss")
    func detectsPassingGoalWeightLoss() {
        // Went below goal
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 158,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestoneWeights: [195, 190, 185, 180, 175, 170, 165],
            intervalPreference: .five
        )

        #expect(crossed.contains(160), "Should detect goal when passed")
    }

    // MARK: - Interval Preferences

    @Test("Respects 10lb interval preference")
    func respectsTenPoundInterval() {
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 185,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .ten
        )

        #expect(crossed.contains(190), "Should have 190 at 10lb intervals")
        #expect(!crossed.contains(195), "Should not have 195 at 10lb intervals")
    }

    @Test("Respects 15lb interval preference")
    func respectsFifteenPoundInterval() {
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 180,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .fifteen
        )

        // 15lb intervals from 200: 195 (skip, not on 15), 185 (yes), 170 (yes), 160 (goal)
        // Actually, from 200 with 15lb: floor(200/15)*15 = 195, then 180, 165, 160
        #expect(!crossed.contains(190), "Should not have 190 at 15lb intervals")
    }

    // MARK: - Kilogram Unit

    @Test("Detects crossed milestones in kilograms")
    func detectsCrossedInKilograms() {
        // 90kg -> 70kg goal, 2kg intervals (maps from 5lb preference)
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 85,
            startWeight: 90,
            goalWeight: 70,
            unit: .kg,
            completedMilestoneWeights: [],
            intervalPreference: .five  // 2kg for kg unit
        )

        #expect(crossed.contains(88), "Should detect 88kg milestone")
        #expect(crossed.contains(86), "Should detect 86kg milestone")
    }
}

// MARK: - Celebration Check Tests

@Suite("Milestone Celebration Check")
struct MilestoneCelebrationCheckTests {

    // MARK: - No Entries Edge Case

    @Test("Returns noEntries when no weight entries exist")
    func returnsNoEntriesWhenEmpty() {
        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: false,
            currentWeight: 0,
            startWeight: 0,
            goalWeight: 0,
            unit: .lb,
            completedMilestones: []
        )

        #expect(check.milestoneToShow == nil)
        #expect(check.reason == .noEntries)
    }

    // MARK: - Uncelebrated Existing Milestones

    @Test("Shows uncelebrated existing milestone first")
    func showsUncelebratedExistingFirst() {
        // Create a milestone that hasn't been celebrated yet
        let uncelebrated = CompletedMilestone(
            targetWeight: 195,
            unit: .lb,
            startWeight: 200
        )
        uncelebrated.celebrationShown = false

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 188, // Also crossed 190, but uncelebrated takes priority
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [uncelebrated]
        )

        #expect(check.milestoneToShow == 195)
        #expect(check.reason == .uncelebratedExisting(weight: 195))
    }

    @Test("Skips celebrated milestones to find uncelebrated")
    func skipsCelebratedToFindUncelebrated() {
        let celebrated = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        celebrated.celebrationShown = true

        let uncelebrated = CompletedMilestone(targetWeight: 190, unit: .lb, startWeight: 200)
        uncelebrated.celebrationShown = false

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 185,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [celebrated, uncelebrated]
        )

        #expect(check.milestoneToShow == 190)
        #expect(check.reason == .uncelebratedExisting(weight: 190))
    }

    // MARK: - Newly Crossed Milestones

    @Test("Detects newly crossed milestone when no uncelebrated exist")
    func detectsNewlyCrossedWhenNoUncelebrated() {
        let celebrated = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        celebrated.celebrationShown = true

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 189, // Crossed 190
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [celebrated]
        )

        #expect(check.milestoneToShow == 190)
        #expect(check.reason == .newlyCrossed(weight: 190))
    }

    @Test("Returns first crossed milestone when multiple are crossed")
    func returnsFirstCrossedWhenMultiple() {
        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 182, // Crossed 195, 190, 185
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        // Should return the first one in order (195)
        #expect(check.milestoneToShow == 195)
        #expect(check.reason == .newlyCrossed(weight: 195))
    }

    // MARK: - No Celebration Needed

    @Test("Returns noCrossedMilestones when weight hasn't reached any")
    func returnsNoCrossedWhenNotReached() {
        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 198, // Not yet at 195
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(check.milestoneToShow == nil)
        #expect(check.reason == .noCrossedMilestones)
    }

    @Test("Returns allMilestonesAlreadyCelebrated when all done")
    func returnsAllCelebratedWhenDone() {
        let m1 = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        m1.celebrationShown = true

        let m2 = CompletedMilestone(targetWeight: 190, unit: .lb, startWeight: 200)
        m2.celebrationShown = true

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 189, // Both milestones already celebrated
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [m1, m2]
        )

        #expect(check.milestoneToShow == nil)
        #expect(check.reason == .allMilestonesAlreadyCelebrated)
    }

    // MARK: - Unit Conversion

    @Test("Handles milestone weights stored in different unit")
    func handlesDifferentStoredUnit() {
        // Milestone stored in kg but checking in lb
        let milestone = CompletedMilestone(targetWeight: 88.45, unit: .kg, startWeight: 90.72)
        milestone.celebrationShown = false

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 190, // lb
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [milestone]
        )

        // The uncelebrated milestone should be found and converted
        #expect(check.milestoneToShow != nil)
        #expect(check.reason != .noEntries)
    }
}

// MARK: - Weight Loss Journey Tests

@Suite("Weight Loss Milestone Journey")
struct WeightLossJourneyTests {

    @Test("Full weight loss journey milestone by milestone")
    func fullWeightLossJourney() {
        var completedMilestones: [CompletedMilestone] = []

        // Step 1: At start weight (200), no milestones
        var check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 200,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: completedMilestones
        )
        #expect(check.milestoneToShow == nil)
        #expect(check.reason == .noCrossedMilestones)

        // Step 2: Cross first milestone (195)
        check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 194,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: completedMilestones
        )
        #expect(check.milestoneToShow == 195)

        // Step 3: Simulate celebration, add to completed
        let m195 = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        m195.celebrationShown = true
        completedMilestones.append(m195)

        // Step 4: Still at 194, should have no more to show
        check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 194,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: completedMilestones
        )
        #expect(check.milestoneToShow == nil)

        // Step 5: Cross second milestone (190)
        check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 189,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: completedMilestones
        )
        #expect(check.milestoneToShow == 190)
    }

    @Test("Skip weighing for weeks, multiple milestones at once")
    func multipleMilestonesAtOnce() {
        // User went from 200 to 175 without recording in between
        var check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 175,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        // Should show first milestone (195)
        #expect(check.milestoneToShow == 195)

        // After celebrating 195
        var completed: [CompletedMilestone] = []
        let m195 = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        m195.celebrationShown = true
        completed.append(m195)

        check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 175,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: completed
        )
        #expect(check.milestoneToShow == 190, "Should show next uncelebrated (190)")

        // Continue pattern...
        let m190 = CompletedMilestone(targetWeight: 190, unit: .lb, startWeight: 200)
        m190.celebrationShown = true
        completed.append(m190)

        check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 175,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: completed
        )
        #expect(check.milestoneToShow == 185)
    }
}

// MARK: - Weight Gain Journey Tests

@Suite("Weight Gain Milestone Journey")
struct WeightGainJourneyTests {

    @Test("Weight gain journey shows milestones correctly")
    func weightGainJourney() {
        // Start: 120, Goal: 150
        var check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 126,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestones: []
        )

        #expect(check.milestoneToShow == 125, "Should celebrate 125 for weight gain")
    }

    @Test("Weight gain respects exact boundary")
    func weightGainExactBoundary() {
        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 125,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestones: []
        )

        #expect(check.milestoneToShow == 125)
    }
}

// MARK: - Edge Case Tests

@Suite("Milestone Popup Edge Cases")
struct MilestonePopupEdgeCaseTests {

    @Test("Handles fractional weights crossing milestone")
    func handlesFractionalWeights() {
        // 194.9 is past 195
        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 194.9,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(check.milestoneToShow == 195)
    }

    @Test("Handles goal weight not on interval boundary")
    func handlesGoalNotOnBoundary() {
        // Goal is 163, not on 5lb boundary
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 162,
            startWeight: 200,
            goalWeight: 163,
            unit: .lb,
            completedMilestoneWeights: [195, 190, 185, 180, 175, 170, 165],
            intervalPreference: .five
        )

        #expect(crossed.contains(163), "Should include off-boundary goal weight")
    }

    @Test("User regains weight after milestone - no re-celebration")
    func noRecelebrationAfterRegain() {
        // User hit 195, celebrated, then regained to 197
        let m195 = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        m195.celebrationShown = true

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 197, // Regained weight
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [m195]
        )

        #expect(check.milestoneToShow == nil, "Should not re-celebrate 195 after regaining")
        #expect(check.reason == .noCrossedMilestones)
    }

    @Test("User regains weight then loses again - no duplicate celebration")
    func noDuplicateAfterRegainAndLose() {
        // User hit 195, celebrated, regained to 197, then lost back to 194
        let m195 = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        m195.celebrationShown = true

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 194, // Back past 195 again
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [m195]
        )

        // Should NOT re-celebrate 195, should move to 190
        #expect(check.milestoneToShow == 190)
    }

    @Test("App restart with uncelebrated milestone shows popup")
    func appRestartShowsUncelebratedPopup() {
        // Simulates: User crossed milestone, app saved it, but crashed before celebration
        let uncelebrated = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        uncelebrated.celebrationShown = false // Saved but not celebrated

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 194,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [uncelebrated]
        )

        #expect(check.milestoneToShow == 195)
        #expect(check.reason == .uncelebratedExisting(weight: 195))
    }

    @Test("Start weight equals goal weight - no milestones")
    func startEqualsGoal() {
        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 160,
            startWeight: 160,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        // When start equals goal, the only milestone is the goal itself
        // User is already at goal, so 160 should be detected
        #expect(check.milestoneToShow == 160)
    }

    @Test("Small weight range has goal as only milestone")
    func smallRangeOnlyGoal() {
        // Start: 163, Goal: 160 - only 3 lbs, goal is only milestone
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 163,
            goalWeight: 160,
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones == [160], "Only goal should be milestone for small range")

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 159,
            startWeight: 163,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(check.milestoneToShow == 160)
    }
}

// MARK: - Interval Preference Tests

@Suite("Milestone Interval Preferences")
struct MilestoneIntervalPreferenceTests {

    @Test("5lb intervals create expected milestones")
    func fivePoundIntervals() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 200,
            goalWeight: 180,
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones.contains(195))
        #expect(milestones.contains(190))
        #expect(milestones.contains(185))
        #expect(milestones.contains(180))
    }

    @Test("10lb intervals create expected milestones")
    func tenPoundIntervals() {
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
        #expect(!milestones.contains(195)) // Not on 10lb boundary
    }

    @Test("15lb intervals create expected milestones")
    func fifteenPoundIntervals() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            intervalPreference: .fifteen
        )

        // From 200 with 15lb intervals: floor(200/15)*15 = 195, then 180, 165, 160
        #expect(milestones.contains(195))
        #expect(milestones.contains(180))
        #expect(milestones.contains(165))
        #expect(milestones.contains(160))
    }

    @Test("Kilogram intervals map correctly from pound preferences")
    func kilogramIntervalMapping() {
        // 5lb preference = 2kg for kg unit
        let interval5 = MilestoneInterval.five.value(for: .kg)
        #expect(interval5 == 2.0)

        // 10lb preference = 5kg for kg unit
        let interval10 = MilestoneInterval.ten.value(for: .kg)
        #expect(interval10 == 5.0)

        // 15lb preference = 7kg for kg unit
        let interval15 = MilestoneInterval.fifteen.value(for: .kg)
        #expect(interval15 == 7.0)
    }
}

// MARK: - Regression Tests

@Suite("Milestone Popup Regression Tests")
struct MilestonePopupRegressionTests {

    // BUG: Milestone popup appeared repeatedly for the same milestone
    @Test("Milestone popup does not repeat after celebrationShown is true")
    func popupDoesNotRepeat() {
        let celebrated = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        celebrated.celebrationShown = true

        // Check multiple times - should always return nil for 195
        for _ in 0..<5 {
            let check = MilestoneCalculator.checkForCelebration(
                hasEntries: true,
                currentWeight: 194,
                startWeight: 200,
                goalWeight: 160,
                unit: .lb,
                completedMilestones: [celebrated]
            )

            #expect(check.milestoneToShow != 195, "Should not repeat 195 celebration")
        }
    }

    // BUG: Milestone detection used wrong direction comparison
    @Test("Weight gain uses >= not <= for milestone crossing")
    func weightGainUsesCorrectComparison() {
        // Weight gain: current >= milestone means crossed
        let crossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 125,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .five
        )

        #expect(crossed.contains(125), "Should detect 125 when current >= 125")

        // But 124 should NOT cross 125
        let notCrossed = MilestoneCalculator.detectCrossedMilestones(
            currentWeight: 124,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestoneWeights: [],
            intervalPreference: .five
        )

        #expect(!notCrossed.contains(125), "Should NOT detect 125 when current < 125")
    }

    // BUG: Milestone calculation was incorrect when user's start weight was later deleted
    @Test("Milestones still work when oldest entry is deleted (start weight changes)")
    func milestonesWorkAfterEntryDeletion() {
        // Original start: 200, Goal: 160, User at 185
        // User deletes old entries, new "start" is 190

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 185,
            startWeight: 190, // New start after deletion
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        // Should still detect milestones between 190 and 160
        // 185 crosses 185 (rounded from 190)
        #expect(check.milestoneToShow != nil)
    }

    // BUG: celebrationShown flag was not being checked, causing popups on app restart
    @Test("Uncelebrated milestones show on app restart, celebrated ones don't")
    func celebrationShownFlagRespected() {
        let celebrated = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        celebrated.celebrationShown = true

        let uncelebrated = CompletedMilestone(targetWeight: 190, unit: .lb, startWeight: 200)
        uncelebrated.celebrationShown = false

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 185,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [celebrated, uncelebrated]
        )

        #expect(check.milestoneToShow == 190, "Should show uncelebrated 190, not celebrated 195")
        #expect(check.reason == .uncelebratedExisting(weight: 190))
    }
}

// MARK: - Milestone Progress Calculation Tests

@Suite("Milestone Progress Calculation")
struct MilestoneProgressCalculationTests {

    // MARK: - Progress Percentage Tests

    @Test("Progress is 0% at previous milestone for weight loss")
    func progressZeroAtPreviousMilestoneWeightLoss() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 200,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.progressToNextMilestone >= 0.0)
        #expect(progress.progressToNextMilestone <= 0.1, "Should be near 0% at start")
    }

    @Test("Progress is 50% halfway between milestones for weight loss")
    func progressFiftyPercentHalfwayWeightLoss() {
        // Between 200 and 195, halfway is 197.5
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 197.5,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.progressToNextMilestone >= 0.45)
        #expect(progress.progressToNextMilestone <= 0.55, "Should be ~50% at halfway point")
    }

    @Test("Progress is 100% at next milestone for weight loss")
    func progressHundredPercentAtMilestoneWeightLoss() {
        // At exactly 195 (first milestone from 200)
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 195,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.progressToNextMilestone >= 0.99, "Should be ~100% at milestone")
    }

    @Test("Progress is 0% when moving wrong direction for weight loss")
    func progressZeroWrongDirectionWeightLoss() {
        // User gained weight instead of losing
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 205,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.progressToNextMilestone == 0.0, "Should be 0% when gaining instead of losing")
    }

    @Test("Progress is 0% when moving wrong direction for weight gain")
    func progressZeroWrongDirectionWeightGain() {
        // User lost weight instead of gaining
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 115,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.progressToNextMilestone == 0.0, "Should be 0% when losing instead of gaining")
    }

    @Test("Progress calculates correctly for weight gain")
    func progressForWeightGain() {
        // Start: 120, Goal: 150, Current: 122.5 (halfway to 125)
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 122.5,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.progressToNextMilestone >= 0.45)
        #expect(progress.progressToNextMilestone <= 0.55, "Should be ~50% halfway to next milestone")
    }

    // MARK: - Weight To Next Milestone Tests

    @Test("Weight to next milestone calculates correctly")
    func weightToNextMilestoneCalculation() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 197,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        // Next milestone is 195, current is 197, so 2 lbs to go
        #expect(progress.weightToNextMilestone >= 1.9)
        #expect(progress.weightToNextMilestone <= 2.1)
    }

    @Test("Weight to next milestone is 0 when at milestone")
    func weightToNextMilestoneZeroAtMilestone() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 195,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.weightToNextMilestone <= 0.1, "Should be ~0 at milestone")
    }

    // MARK: - Has Reached Goal Tests

    @Test("hasReachedGoal is true when at goal for weight loss")
    func hasReachedGoalAtGoalWeightLoss() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 160,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.hasReachedGoal == true)
    }

    @Test("hasReachedGoal is true when past goal for weight loss")
    func hasReachedGoalPastGoalWeightLoss() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 158,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.hasReachedGoal == true)
    }

    @Test("hasReachedGoal is false when above goal for weight loss")
    func hasReachedGoalFalseAboveGoalWeightLoss() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 165,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.hasReachedGoal == false)
    }

    @Test("hasReachedGoal is true when at goal for weight gain")
    func hasReachedGoalAtGoalWeightGain() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 150,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.hasReachedGoal == true)
    }

    @Test("hasReachedGoal is true when past goal for weight gain")
    func hasReachedGoalPastGoalWeightGain() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 155,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.hasReachedGoal == true)
    }

    @Test("hasReachedGoal is false when below goal for weight gain")
    func hasReachedGoalFalseBelowGoalWeightGain() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 145,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.hasReachedGoal == false)
    }

    // MARK: - Next/Previous Milestone Identification

    @Test("Identifies correct next and previous milestones for weight loss")
    func identifiesNextPreviousMilestonesWeightLoss() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 192,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        // At 192, previous was 195, next is 190
        #expect(progress.previousMilestone == 195)
        #expect(progress.nextMilestone == 190)
    }

    @Test("Identifies correct next and previous milestones for weight gain")
    func identifiesNextPreviousMilestonesWeightGain() {
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 127,
            startWeight: 120,
            goalWeight: 150,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        // At 127, previous was 125, next is 130
        #expect(progress.previousMilestone == 125)
        #expect(progress.nextMilestone == 130)
    }

    // MARK: - Kilogram Progress Tests

    @Test("Progress calculates correctly in kilograms")
    func progressInKilograms() {
        // 90kg -> 70kg, interval 2kg
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 87,
            startWeight: 90,
            goalWeight: 70,
            unit: .kg,
            completedMilestones: [],
            intervalPreference: .five  // 2kg for kg unit
        )

        // From 88 to 86, at 87 should be ~50%
        #expect(progress.progressToNextMilestone >= 0.4)
        #expect(progress.progressToNextMilestone <= 0.6)
    }
}

// MARK: - Generate Milestones Tests

@Suite("Generate Milestones")
struct GenerateMilestonesTests {

    @Test("Generates correct milestones for round start weight")
    func generatesForRoundStartWeight() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 200,
            goalWeight: 180,
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones == [195, 190, 185, 180])
    }

    @Test("Generates correct milestones for non-round start weight")
    func generatesForNonRoundStartWeight() {
        // Start at 198, first milestone should be 195
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 198,
            goalWeight: 180,
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones.first == 195)
        #expect(milestones.last == 180)
    }

    @Test("Generates correct milestones for weight gain")
    func generatesForWeightGain() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 120,
            goalWeight: 140,
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones.first == 125)
        #expect(milestones.last == 140)
        #expect(milestones.contains(130))
        #expect(milestones.contains(135))
    }

    @Test("Always includes goal weight as final milestone")
    func alwaysIncludesGoal() {
        // Goal 163 is not on 5lb boundary
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 200,
            goalWeight: 163,
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones.last == 163, "Goal must always be included")
    }

    @Test("Handles small range with only goal as milestone")
    func handlesSmallRange() {
        // Only 3 lbs difference
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 163,
            goalWeight: 160,
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones == [160], "Only goal should be a milestone")
    }

    @Test("Handles equal start and goal")
    func handlesEqualStartAndGoal() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 160,
            goalWeight: 160,
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones == [160])
    }

    @Test("Respects 10lb interval correctly")
    func respectsTenLbInterval() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            intervalPreference: .ten
        )

        // Should be 190, 180, 170, 160
        #expect(!milestones.contains(195))
        #expect(milestones.contains(190))
        #expect(milestones.contains(180))
    }

    @Test("Generates milestones in kilograms")
    func generatesInKilograms() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 90,
            goalWeight: 80,
            unit: .kg,
            intervalPreference: .five  // 2kg intervals
        )

        // Should be 88, 86, 84, 82, 80
        #expect(milestones.contains(88))
        #expect(milestones.contains(86))
        #expect(milestones.last == 80)
    }

    @Test("Handles large weight range efficiently")
    func handlesLargeRange() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 400,
            goalWeight: 150,
            unit: .lb,
            intervalPreference: .five
        )

        // Should create many milestones but not crash
        #expect(milestones.count > 40)
        #expect(milestones.first == 395)
        #expect(milestones.last == 150)
    }
}

// MARK: - Direction Change Scenarios

@Suite("Direction Change Scenarios")
struct DirectionChangeTests {

    @Test("User significantly overshoots goal then regains")
    func userOvershootsThenRegains() {
        // User went from 200 to 155 (past goal of 160), then regained to 165
        let m195 = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        m195.celebrationShown = true
        let m190 = CompletedMilestone(targetWeight: 190, unit: .lb, startWeight: 200)
        m190.celebrationShown = true
        let m185 = CompletedMilestone(targetWeight: 185, unit: .lb, startWeight: 200)
        m185.celebrationShown = true
        let m180 = CompletedMilestone(targetWeight: 180, unit: .lb, startWeight: 200)
        m180.celebrationShown = true
        let m175 = CompletedMilestone(targetWeight: 175, unit: .lb, startWeight: 200)
        m175.celebrationShown = true
        let m170 = CompletedMilestone(targetWeight: 170, unit: .lb, startWeight: 200)
        m170.celebrationShown = true
        let m165 = CompletedMilestone(targetWeight: 165, unit: .lb, startWeight: 200)
        m165.celebrationShown = true
        let m160 = CompletedMilestone(targetWeight: 160, unit: .lb, startWeight: 200)
        m160.celebrationShown = true

        let completed = [m195, m190, m185, m180, m175, m170, m165, m160]

        // User regained to 165
        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 165,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: completed
        )

        // Should not re-celebrate any milestones
        #expect(check.milestoneToShow == nil)
        #expect(check.reason == .allMilestonesAlreadyCelebrated)
    }

    @Test("Progress reflects direction toward goal after regaining")
    func progressAfterRegaining() {
        // User at 170, goal 160, after having regained some weight
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 170,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        // Should still show progress toward goal
        #expect(progress.goalWeight == 160)
        #expect(progress.hasReachedGoal == false)
    }

    @Test("New milestones appear when user regains past completed ones")
    func newMilestonesAfterRegainPastCompleted() {
        // User hit 185, regained to 192
        // The 190 milestone should still be "available" but we already have 185 completed
        let m195 = CompletedMilestone(targetWeight: 195, unit: .lb, startWeight: 200)
        m195.celebrationShown = true
        let m190 = CompletedMilestone(targetWeight: 190, unit: .lb, startWeight: 200)
        m190.celebrationShown = true
        let m185 = CompletedMilestone(targetWeight: 185, unit: .lb, startWeight: 200)
        m185.celebrationShown = true

        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 192, // Regained past 190
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [m195, m190, m185]
        )

        // No new milestones to celebrate - they're all completed
        #expect(check.milestoneToShow == nil)
    }
}

// MARK: - Boundary Condition Tests

@Suite("Milestone Boundary Conditions")
struct MilestoneBoundaryConditionTests {

    @Test("Handles very small weight differences")
    func handlesVerySmallDifference() {
        // Only 0.5 lb difference
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 160.5,
            goalWeight: 160,
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones == [160], "Only goal should be milestone for tiny range")
    }

    @Test("Handles fractional goal weight")
    func handlesFractionalGoalWeight() {
        let milestones = MilestoneCalculator.generateMilestones(
            startWeight: 170,
            goalWeight: 162.5,
            unit: .lb,
            intervalPreference: .five
        )

        #expect(milestones.contains(165))
        #expect(milestones.last == 162.5)
    }

    @Test("Progress clamped between 0 and 1")
    func progressClampedBetweenZeroAndOne() {
        // Test that progress never exceeds bounds even with floating point issues
        let progress = MilestoneCalculator.calculateProgress(
            currentWeight: 194.999999,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: [],
            intervalPreference: .five
        )

        #expect(progress.progressToNextMilestone >= 0.0)
        #expect(progress.progressToNextMilestone <= 1.0)
    }

    @Test("Handles weight at exact interval boundary")
    func handlesExactIntervalBoundary() {
        // User at exactly 195 (on 5lb boundary)
        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 195.0,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(check.milestoneToShow == 195)
    }

    @Test("Handles weight just past milestone")
    func handlesWeightJustPastMilestone() {
        // User at 194.9, just past 195
        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 194.9,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(check.milestoneToShow == 195)
    }

    @Test("Handles weight just before milestone")
    func handlesWeightJustBeforeMilestone() {
        // User at 195.1, not quite at 195 yet
        let check = MilestoneCalculator.checkForCelebration(
            hasEntries: true,
            currentWeight: 195.1,
            startWeight: 200,
            goalWeight: 160,
            unit: .lb,
            completedMilestones: []
        )

        #expect(check.milestoneToShow == nil, "Should not celebrate milestone not yet reached")
    }
}

// MARK: - Milestone Interval Value Tests

@Suite("Milestone Interval Values")
struct MilestoneIntervalValueTests {

    @Test("5lb interval returns correct values")
    func fiveLbIntervalValues() {
        #expect(MilestoneInterval.five.pounds == 5.0)
        #expect(MilestoneInterval.five.kilograms == 2.0)
        #expect(MilestoneInterval.five.value(for: .lb) == 5.0)
        #expect(MilestoneInterval.five.value(for: .kg) == 2.0)
    }

    @Test("10lb interval returns correct values")
    func tenLbIntervalValues() {
        #expect(MilestoneInterval.ten.pounds == 10.0)
        #expect(MilestoneInterval.ten.kilograms == 5.0)
        #expect(MilestoneInterval.ten.value(for: .lb) == 10.0)
        #expect(MilestoneInterval.ten.value(for: .kg) == 5.0)
    }

    @Test("15lb interval returns correct values")
    func fifteenLbIntervalValues() {
        #expect(MilestoneInterval.fifteen.pounds == 15.0)
        #expect(MilestoneInterval.fifteen.kilograms == 7.0)
        #expect(MilestoneInterval.fifteen.value(for: .lb) == 15.0)
        #expect(MilestoneInterval.fifteen.value(for: .kg) == 7.0)
    }

    @Test("Display labels format correctly")
    func displayLabelsFormat() {
        #expect(MilestoneInterval.five.displayLabel(for: .lb) == "5 lb")
        #expect(MilestoneInterval.five.displayLabel(for: .kg) == "2 kg")
        #expect(MilestoneInterval.ten.displayLabel(for: .lb) == "10 lb")
        #expect(MilestoneInterval.fifteen.displayLabel(for: .kg) == "7 kg")
    }

    @Test("All cases are iterable")
    func allCasesIterable() {
        let allCases = MilestoneInterval.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.five))
        #expect(allCases.contains(.ten))
        #expect(allCases.contains(.fifteen))
    }
}
