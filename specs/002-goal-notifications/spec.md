# Feature Specification: Goal Progress Notifications

**Feature Branch**: `002-goal-notifications`
**Created**: 2025-01-09
**Status**: Draft
**Input**: User description: "Implement goal progress notifications when approaching target weight"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Milestone Celebration Notifications (Priority: P1)

As a user working toward my goal weight, I want to receive encouraging notifications when I hit weight loss milestones so that I stay motivated throughout my journey.

**Why this priority**: Positive reinforcement is the primary value proposition. Users need encouragement to maintain their weight tracking habit. Celebrating progress creates an emotional connection to the app.

**Independent Test**: Can be fully tested by logging weight entries that cross milestone thresholds and verifying notifications appear. Delivers immediate motivational value.

**Acceptance Scenarios**:

1. **Given** a user has a goal weight of 160 lb and current weight of 180 lb, **When** they log a weight of 175 lb (25% progress), **Then** they receive a celebration notification
2. **Given** a user has a goal weight set, **When** they reach 50% of their goal, **Then** they receive a "halfway there" notification
3. **Given** a user has a goal weight set, **When** they reach 75% progress, **Then** they receive an "almost there" notification
4. **Given** a user reaches their exact goal weight, **When** they log that entry, **Then** they receive a "goal achieved" celebration notification
5. **Given** a user has notifications disabled system-wide, **When** they hit a milestone, **Then** the milestone is recorded but no notification is sent

---

### User Story 2 - Approaching Goal Alerts (Priority: P2)

As a user nearing my goal weight, I want to receive a heads-up notification when I'm within a small range of my target so that I can prepare for maintenance mode and celebrate my achievement.

**Why this priority**: This is the specific feature requested - alerting users when they're close. Secondary to milestones because it only fires once near the end, while milestones provide value throughout the journey.

**Independent Test**: Can be tested by logging a weight entry within the "approaching" threshold (e.g., within 5 lb of goal) and verifying the notification appears.

**Acceptance Scenarios**:

1. **Given** a user has a goal weight of 160 lb, **When** they log a weight of 163 lb (within 5 lb), **Then** they receive an "approaching goal" notification
2. **Given** a user already received an "approaching goal" notification, **When** they log another weight still within range, **Then** they do NOT receive a duplicate notification
3. **Given** a user received the "approaching goal" notification then regressed above the threshold, **When** they re-enter the approaching range, **Then** they receive the notification again
4. **Given** a user is gaining weight toward a higher goal, **When** they enter the approaching range from below, **Then** the notification works the same way

---

### User Story 3 - Progress Summary Notifications (Priority: P3)

As a regular weight tracker, I want to receive periodic summaries of my progress so that I can see trends without opening the app.

**Why this priority**: Nice-to-have feature that increases engagement but is not core to the "approaching goal" request. Can be deferred if scope needs trimming.

**Independent Test**: Can be tested by enabling weekly summaries, waiting for the scheduled time, and verifying the summary notification contains accurate progress data.

**Acceptance Scenarios**:

1. **Given** a user has logged weight for 7+ days, **When** the weekly summary time arrives, **Then** they receive a notification with their progress (weight change, trend direction)
2. **Given** a user has weekly summaries enabled, **When** they have no weight entries that week, **Then** they receive a gentle reminder instead of a summary
3. **Given** a user disables progress summaries, **When** the scheduled time arrives, **Then** no notification is sent

---

### Edge Cases

- What happens when the user hasn't set a goal weight?
  - Milestone and approaching notifications are disabled; only daily reminders (existing feature) work
- What happens when the user's goal involves gaining weight (e.g., underweight)?
  - Same milestone logic applies in reverse (progress toward higher weight)
- What happens when the user changes their goal weight mid-journey?
  - Progress percentages recalculate; previously earned milestones are not re-triggered
- What happens if the user logs multiple entries crossing multiple milestones in one day?
  - Show the highest milestone notification only, avoid notification spam
- What happens when the user reaches goal then regresses?
  - "Goal achieved" only shows once; if they re-achieve later, show it again

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST calculate progress percentage as `(startWeight - currentWeight) / (startWeight - goalWeight) * 100` for weight loss goals
- **FR-002**: System MUST support both weight loss and weight gain goals with appropriate progress calculation
- **FR-003**: System MUST trigger milestone notifications at 25%, 50%, 75%, and 100% progress thresholds
- **FR-004**: System MUST trigger an "approaching goal" notification when user is within 5 lb (or 2.5 kg) of their goal
- **FR-005**: System MUST NOT send duplicate notifications for the same milestone or approaching alert until user regresses and re-achieves
- **FR-006**: System MUST allow users to enable/disable goal progress notifications in Settings
- **FR-007**: System MUST respect system-wide notification permissions (graceful degradation)
- **FR-008**: System MUST record milestone achievements even if notifications are disabled
- **FR-009**: System MUST recalculate progress when goal weight is changed
- **FR-010**: System MUST support optional weekly progress summary notifications
- **FR-011**: System MUST use the user's preferred weight unit in notification messages
- **FR-012**: System MUST determine "start weight" as the first logged weight OR weight when goal was set (whichever is later)

### Key Entities

- **GoalProgress**: Tracks the user's progress toward their goal (start weight, current weight, goal weight, progress percentage, milestones achieved)
- **MilestoneAchievement**: Records when a user achieves a milestone (milestone type, date achieved, weight at achievement)
- **NotificationPreferences**: User's preferences for goal notifications (milestones enabled, approaching enabled, summaries enabled, summary day/time)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users receive milestone notifications within 3 seconds of logging a qualifying weight entry
- **SC-002**: 100% of milestone achievements are recorded accurately (no false positives or missed milestones)
- **SC-003**: Users can configure notification preferences in under 30 seconds
- **SC-004**: Zero duplicate notifications for the same milestone without regression
- **SC-005**: Weekly summary notifications arrive within 5 minutes of the scheduled time
- **SC-006**: Users who enable goal notifications show 20% higher retention than those who don't (measurable after 30 days)
- **SC-007**: App remains fully functional when notification permissions are denied

## Assumptions

The following reasonable defaults have been applied:

1. **Milestone thresholds**: 25%, 50%, 75%, 100% (industry standard for progress tracking)
2. **Approaching threshold**: Within 5 lb (2.5 kg) of goal - close enough to be exciting, far enough to not overlap with "goal achieved"
3. **Weekly summary timing**: User-configurable day/time, defaulting to Sunday 9 AM local time
4. **Start weight determination**: First weight logged after setting a goal, or first weight ever if goal was set before any logging
5. **Notification style**: Local notifications (not push) - no server infrastructure required
6. **Duplicate prevention**: Track milestones achieved per goal; reset if goal changes significantly (>10% change)
