# Quickstart: Social Sharing

**Feature**: 003-social-sharing
**Purpose**: Manual validation checklist for testing social sharing on device

## Prerequisites

Before testing:
- [ ] Feature branch `003-social-sharing` checked out
- [ ] Feature `002-goal-notifications` merged (for MilestoneAchievement model)
- [ ] App builds without errors
- [ ] iPhone simulator or physical device available

## Test Setup

### Initial State

1. [ ] Set goal weight to 160 lb in Settings
2. [ ] Log initial weight of 200 lb (this is your "start weight")
3. [ ] Verify goal notifications are enabled

### Enable Sharing Features

1. [ ] Go to Settings → Sharing Preferences
2. [ ] Note default settings: "Hide Exact Weights" = ON, "Include Graphic" = ON
3. [ ] Verify all toggles are accessible via VoiceOver

---

## User Story 1: Share Milestone Achievement (P1)

### Scenario 1.1: Share from Milestone Notification

**Setup**: Trigger a 25% milestone

1. [ ] Log weight entry: **190 lb** (25% progress toward 160 lb goal)
2. [ ] **Expected**: Milestone celebration notification appears
3. [ ] Tap "Share" on the notification or celebration view
4. [ ] **Expected**: Share preview screen shows
5. [ ] **Verify**: Preview shows message WITHOUT exact weight (privacy mode ON)
6. [ ] **Verify**: Preview shows progress graphic (if enabled)
7. [ ] Tap "Share"
8. [ ] **Expected**: iOS share sheet appears within 2 taps from milestone
9. [ ] Select Messages
10. [ ] **Verify**: Message text is properly formatted

### Scenario 1.2: Share from Milestone History

1. [ ] Navigate to milestone history view
2. [ ] Select the 25% milestone achieved earlier
3. [ ] Tap "Share"
4. [ ] **Expected**: Same share preview appears
5. [ ] **Verify**: Past milestones can be shared

### Scenario 1.3: Share with Full Details (Privacy OFF)

1. [ ] Go to Settings → Sharing Preferences
2. [ ] Turn OFF "Hide Exact Weights"
3. [ ] Return to milestone history, share 25% milestone again
4. [ ] **Expected**: Message now includes "190 lb" in the text
5. [ ] **Verify**: Exact weight appears when privacy is disabled

### Scenario 1.4: Share to Multiple Destinations

1. [ ] Trigger 50% milestone (log 180 lb)
2. [ ] Share and select different destinations:
   - [ ] Messages
   - [ ] Mail
   - [ ] Copy to Clipboard
3. [ ] **Verify**: Content appears correctly in each destination

### Scenario 1.5: Clipboard Fallback

1. [ ] If share sheet fails (simulate by canceling multiple times)
2. [ ] **Expected**: "Copy to Clipboard" option available
3. [ ] Tap "Copy to Clipboard"
4. [ ] **Expected**: Confirmation appears
5. [ ] Paste somewhere to verify content copied correctly

---

## User Story 2: Share Progress Summary (P2)

### Scenario 2.1: Share Progress After 30+ Days

**Setup**: Ensure at least 7 days of data exists (use sample data or date manipulation)

1. [ ] Navigate to Summary view
2. [ ] Tap "Share Progress"
3. [ ] **Expected**: Progress summary preview shows:
   - Total tracking duration
   - Weight change (hidden or shown per settings)
   - Trend direction
4. [ ] **Verify**: Progress graphic displays correctly

### Scenario 2.2: Share Progress with Goal Achieved

1. [ ] Log weight of 160 lb (goal reached)
2. [ ] Share progress summary
3. [ ] **Expected**: Message emphasizes "Goal achieved!" celebration
4. [ ] **Verify**: Tone is celebratory

### Scenario 2.3: Insufficient Data Warning

1. [ ] Create new user or clear data
2. [ ] Log only 2-3 days of weight entries
3. [ ] Attempt to share progress
4. [ ] **Expected**: Message encourages logging more entries
5. [ ] **Verify**: Share option is disabled or shows gentle guidance

### Scenario 2.4: Share After Regression

1. [ ] Log weight above previous entry (simulate regression)
2. [ ] Share progress
3. [ ] **Expected**: Message remains positive ("consistency", "every day counts")
4. [ ] **Verify**: No negative or shaming language

---

## User Story 3: Privacy Controls (P3)

### Scenario 3.1: Hide Exact Weights

1. [ ] Go to Settings → Sharing Preferences
2. [ ] Enable "Hide Exact Weights" (should be default)
3. [ ] Share any milestone or progress
4. [ ] **Expected**: Only percentages appear, no lb/kg values
5. [ ] **Verify**: Zero instances of exact weight in shared content

### Scenario 3.2: Hide Dates

1. [ ] Enable "Hide Dates" in Settings
2. [ ] Share progress summary
3. [ ] **Expected**: Duration shows as "3 months" not "since Jan 1"
4. [ ] **Verify**: No specific dates in shared content

### Scenario 3.3: Preview Accuracy

1. [ ] Open share preview for any content
2. [ ] **Verify**: Preview shows EXACTLY what will be shared
3. [ ] Change privacy settings
4. [ ] Open preview again
5. [ ] **Verify**: Preview immediately reflects new settings

### Scenario 3.4: Graphic Toggle

1. [ ] Disable "Include Graphic" in Settings
2. [ ] Share milestone
3. [ ] **Expected**: Share sheet shows text only, no image attachment
4. [ ] Enable "Include Graphic"
5. [ ] Share again
6. [ ] **Expected**: Image is now attached to share

---

## Edge Cases

### EC-1: No Achievements Yet

1. [ ] Create new user or clear milestone history
2. [ ] Verify no milestones achieved
3. [ ] Look for share option on summary view
4. [ ] **Expected**: Share milestone option hidden or disabled
5. [ ] **Expected**: Tooltip explains "Achieve your first milestone to unlock sharing"

### EC-2: Weight Gain Goal

1. [ ] Set goal weight to 150 lb (higher than current 140 lb)
2. [ ] Log weight of 140 lb (start)
3. [ ] Log weight of 145 lb (50% progress toward gain goal)
4. [ ] Share milestone
5. [ ] **Expected**: Message uses neutral language ("progress toward goal")
6. [ ] **Verify**: No "weight lost" language

### EC-3: No Goal Set

1. [ ] Clear goal weight (set to 0 or remove)
2. [ ] Check sharing options
3. [ ] **Expected**: Progress-based shares disabled
4. [ ] **Expected**: App works normally otherwise

### EC-4: Profile Name Not Set

1. [ ] Ensure no profile name is configured
2. [ ] Share a milestone
3. [ ] **Expected**: Generic message without personalization
4. [ ] **Verify**: No placeholder text like "[Your Name]"

---

## Performance Validation

### SC-001: 2-Tap Share Initiation

1. [ ] Achieve a milestone
2. [ ] Count taps to reach share sheet:
   - Tap 1: "Share" on celebration
   - Tap 2: Confirm on preview (or share sheet destination)
3. [ ] **Expected**: ≤ 2 taps from milestone to share sheet
4. [ ] **Record**: Actual taps _______

### SC-002: Preview Load Time

1. [ ] Tap Share on any content
2. [ ] Start timer when tap occurs
3. [ ] Stop timer when preview fully loads (including graphic)
4. [ ] **Expected**: < 1 second
5. [ ] **Record**: Actual time _______ ms

### SC-004: Settings Configuration Time

1. [ ] Open Settings → Sharing Preferences
2. [ ] Change all 4 settings
3. [ ] **Expected**: < 30 seconds total
4. [ ] **Record**: Actual time _______ seconds

---

## Accessibility Validation

### VoiceOver Support

1. [ ] Enable VoiceOver (Settings → Accessibility → VoiceOver)
2. [ ] Navigate to share button
3. [ ] **Verify**: Button has accessible label ("Share milestone" or similar)
4. [ ] Open share preview
5. [ ] **Verify**: All preview content is readable
6. [ ] Navigate to Settings → Sharing Preferences
7. [ ] **Verify**: All toggles announce their state correctly

### Dynamic Type

1. [ ] Set system text size to Largest
2. [ ] Open share preview
3. [ ] **Verify**: All text is readable, no truncation
4. [ ] **Verify**: Layout adapts to larger text

---

## Regression Checks

After testing new feature, verify existing functionality:

- [ ] Milestone notifications still work (from 002-goal-notifications)
- [ ] Weight entries save correctly
- [ ] Chart displays correctly
- [ ] Settings persist after app restart
- [ ] Unit conversion works correctly

---

## Sign-Off

| Tester | Date | Device | iOS Version | Result |
|--------|------|--------|-------------|--------|
| | | | | ⬜ Pass / ⬜ Fail |

**Notes**:
