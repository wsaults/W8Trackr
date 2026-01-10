# Quickstart: Goal Progress Notifications

**Feature**: 002-goal-notifications
**Purpose**: Manual validation checklist for testing goal notifications on device

## Prerequisites

Before testing:
- [ ] Feature branch `002-goal-notifications` checked out
- [ ] App builds without errors
- [ ] iPhone simulator or physical device available
- [ ] Notification permissions enabled for W8Trackr

## Test Setup

### Initial State

1. [ ] Open Settings → set goal weight to 160 lb
2. [ ] Delete all existing weight entries (Settings → Danger Zone)
3. [ ] Note: First entry after this will be your "start weight"

### Enable Notifications

1. [ ] Go to Settings → Notifications
2. [ ] Enable "Daily Reminders" (grants notification permission)
3. [ ] Enable "Goal Progress Notifications"
4. [ ] Enable "Milestone Celebrations"
5. [ ] Enable "Approaching Goal Alerts"

---

## User Story 1: Milestone Celebrations (P1)

### Scenario 1.1: 25% Milestone

**Setup**: Goal = 160 lb, need to establish start weight

1. [ ] Log weight entry: **200 lb** (this is your start weight)
2. [ ] Verify: No notification (you're at 0% progress)
3. [ ] Log weight entry: **190 lb** (25% of 40 lb = 10 lb lost)
4. [ ] **Expected**: Receive "25% Progress" celebration notification within 3 seconds
5. [ ] **Verify**: Notification title contains "25%" or "progress"
6. [ ] **Verify**: Notification taps open the app

### Scenario 1.2: 50% Milestone (Halfway)

1. [ ] Log weight entry: **180 lb** (50% of 40 lb = 20 lb lost)
2. [ ] **Expected**: Receive "Halfway There" notification within 3 seconds
3. [ ] **Verify**: Notification mentions "halfway" or "50%"

### Scenario 1.3: 75% Milestone

1. [ ] Log weight entry: **170 lb** (75% of 40 lb = 30 lb lost)
2. [ ] **Expected**: Receive "Almost There" notification within 3 seconds
3. [ ] **Verify**: Notification mentions "75%" or "almost"

### Scenario 1.4: 100% Milestone (Goal Achieved)

1. [ ] Log weight entry: **160 lb** (goal reached)
2. [ ] **Expected**: Receive "Goal Achieved" celebration notification
3. [ ] **Verify**: Notification mentions "congratulations" or "goal achieved"

### Scenario 1.5: No Duplicate Notifications

1. [ ] Log another weight entry: **159 lb** (past goal)
2. [ ] **Expected**: NO additional goal achieved notification
3. [ ] **Verify**: Only original milestone notifications were sent once

---

## User Story 2: Approaching Goal Alerts (P2)

### Scenario 2.1: Entering Approaching Range

**Setup**: Reset to new goal

1. [ ] Set goal weight to **180 lb**
2. [ ] Log weight entry: **200 lb** (new start weight)
3. [ ] Log weight entry: **184 lb** (within 5 lb of goal)
4. [ ] **Expected**: Receive "Approaching Goal" notification
5. [ ] **Verify**: Notification mentions distance remaining (e.g., "4 lb to go")

### Scenario 2.2: No Duplicate Approaching Notification

1. [ ] Log weight entry: **183 lb** (still within range)
2. [ ] **Expected**: NO duplicate approaching notification

### Scenario 2.3: Regression and Re-entry

1. [ ] Log weight entry: **190 lb** (regression above threshold)
2. [ ] Log weight entry: **184 lb** (re-enter approaching range)
3. [ ] **Expected**: Receive new "Approaching Goal" notification

### Scenario 2.4: Weight Gain Goals

**Setup**: Test gaining weight

1. [ ] Set goal weight to **150 lb** (higher than current)
2. [ ] Log weight entry: **140 lb** (start weight)
3. [ ] Log weight entry: **146 lb** (within 5 lb of goal from below)
4. [ ] **Expected**: Receive "Approaching Goal" notification
5. [ ] **Verify**: Works correctly for weight gain goals

---

## User Story 3: Weekly Summaries (P3)

### Scenario 3.1: Weekly Summary Content

**Note**: This requires waiting for scheduled time or manually triggering

1. [ ] Enable weekly summaries in Settings
2. [ ] Set summary day/time (or use default: Sunday 9 AM)
3. [ ] Log entries for 7+ days
4. [ ] Wait for scheduled summary OR manually trigger for testing
5. [ ] **Expected**: Summary notification with:
   - Number of entries logged
   - Weight change (lost/gained X lb)
   - Trend direction

### Scenario 3.2: No Entries = Gentle Reminder

1. [ ] Delete all entries from past week
2. [ ] Trigger weekly summary
3. [ ] **Expected**: Gentle reminder instead of summary
4. [ ] **Verify**: Message encourages logging, not judgmental

### Scenario 3.3: Summaries Disabled

1. [ ] Disable weekly summaries in Settings
2. [ ] Trigger summary time
3. [ ] **Expected**: No notification sent

---

## Edge Cases

### EC-1: No Goal Set

1. [ ] Clear goal weight (set to 0 or remove)
2. [ ] Log weight entry
3. [ ] **Expected**: No milestone or approaching notifications
4. [ ] **Verify**: App works normally, no crashes

### EC-2: Goal Change Mid-Journey

1. [ ] Set goal to 160 lb, log 200 lb start, log 190 lb (25% achieved)
2. [ ] Change goal to 150 lb (bigger change)
3. [ ] Log 185 lb
4. [ ] **Expected**: Progress recalculates, may trigger new milestones
5. [ ] **Verify**: 25% milestone NOT re-triggered unless significant goal change

### EC-3: Multiple Milestones in One Day

1. [ ] Set goal to 160 lb, log 200 lb start
2. [ ] Log 170 lb (this crosses 25%, 50%, AND 75% at once)
3. [ ] **Expected**: Only ONE notification (highest milestone = 75%)
4. [ ] **Verify**: No notification spam

### EC-4: Notifications Disabled System-Wide

1. [ ] Go to iOS Settings → W8Trackr → Notifications → Off
2. [ ] Achieve a milestone in W8Trackr
3. [ ] **Expected**: No notification appears
4. [ ] **Verify**: Milestone is still RECORDED (check achievements list if visible)
5. [ ] Re-enable notifications
6. [ ] **Verify**: Future milestones send notifications

### EC-5: App in Background

1. [ ] Log weight that triggers milestone
2. [ ] Immediately background the app
3. [ ] **Expected**: Notification still appears within 3 seconds

---

## Accessibility Validation

### VoiceOver Support

1. [ ] Enable VoiceOver (Settings → Accessibility → VoiceOver)
2. [ ] Navigate to Settings → Notifications section
3. [ ] **Verify**: All toggles have accessible labels
4. [ ] **Verify**: Toggle state is announced ("on"/"off")
5. [ ] Trigger a milestone notification
6. [ ] **Verify**: Notification content is read correctly by VoiceOver

### Dynamic Type

1. [ ] Set system text size to Largest (Settings → Display → Text Size)
2. [ ] Open W8Trackr Settings → Notifications
3. [ ] **Verify**: All text is readable, no truncation
4. [ ] **Verify**: Layout adapts to larger text

---

## Performance Validation

### SC-001: Notification Speed

1. [ ] Log a weight entry that triggers a milestone
2. [ ] Start stopwatch as you tap Save
3. [ ] Stop when notification appears
4. [ ] **Expected**: ≤ 3 seconds
5. [ ] **Record**: Actual time _______ seconds

### SC-003: Settings Configuration Time

1. [ ] Open Settings → Notifications
2. [ ] Change 3 different toggle values
3. [ ] **Expected**: ≤ 30 seconds total
4. [ ] **Record**: Actual time _______ seconds

---

## Regression Checks

After testing new feature, verify existing functionality:

- [ ] Daily reminder notifications still work
- [ ] Smart reminders (streak warnings) still work
- [ ] Weight chart displays correctly
- [ ] Weight entries save and display in Logbook
- [ ] Unit conversion works correctly
- [ ] Trend calculations include all entries

---

## Sign-Off

| Tester | Date | Device | iOS Version | Result |
|--------|------|--------|-------------|--------|
| | | | | ⬜ Pass / ⬜ Fail |

**Notes**:
