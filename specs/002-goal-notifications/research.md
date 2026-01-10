# Research: Goal Progress Notifications

**Feature**: 002-goal-notifications
**Date**: 2025-01-09
**Purpose**: Phase 0 research to inform design decisions

## Existing Infrastructure Analysis

### Current Notification System

The codebase already has a mature notification system:

**NotificationManager.swift** (lines 11-127)
- `ObservableObject` managing notification state
- Handles permission requests via `UNUserNotificationCenter`
- Manages daily reminders and "smart reminders" feature
- Calls `NotificationScheduler` for goal-aware notifications

**NotificationScheduler.swift** (lines 13-286)
- `struct` with static methods for notification logic
- Already implements:
  - **Milestone approaching** (line 126-154): Detects when user is within 2 lb of next 5-lb increment
  - **Weekly summary** (line 161-205): Generates weekly progress message
  - **Streak warning** (line 107-116): Alerts when logging streak at risk

### Gap Analysis: Spec vs. Existing

| Spec Requirement | Current Implementation | Gap |
|------------------|------------------------|-----|
| 25%/50%/75%/100% milestones | 5-lb/2.5-kg increments | Need percentage-based calculation |
| Milestone celebration | "Almost there" approaching | Need achievement notifications |
| Approaching goal alert (within 5 lb) | Within 2 lb of next 5-lb mark | Need goal-distance calculation |
| Duplicate prevention | None | Need milestone tracking model |
| Milestone recording | None (transient) | Need SwiftData persistence |
| User preferences UI | Smart reminders toggle only | Need granular notification settings |

### Key Finding: Refactor vs. Extend

The existing `milestoneProgress` function (NotificationScheduler.swift:126-154) calculates distance to next 5-lb round number, NOT progress toward goal. The spec requires **percentage-based milestones** toward goal weight.

**Recommendation**: Create new `GoalProgressCalculator` service for spec-compliant progress calculation. Keep existing `NotificationScheduler.milestoneProgress` for "approaching next 5-lb mark" feature (complementary, not conflicting).

## iOS UserNotifications Best Practices

### Notification Content Guidelines

From Apple's Human Interface Guidelines:

1. **Be concise**: Title ≤ 50 characters, body ≤ 150 characters
2. **Be actionable**: Tell users what happened and what they can do
3. **Be relevant**: Time notifications appropriately (not during sleep hours)
4. **Celebrate achievements**: Positive reinforcement increases engagement

### Notification Frequency Research

| Pattern | Recommendation |
|---------|----------------|
| Milestone achievements | Immediate (within 3 seconds of qualifying entry) |
| Approaching goal | Once per threshold crossing (not daily) |
| Weekly summary | Fixed schedule (Sunday evening per spec) |
| Duplicate prevention | Track by milestone type + goal version |

### Technical Considerations

1. **Local vs. Push**: Spec requires local notifications only (no server)
2. **Background delivery**: Not needed - notifications triggered by weight entry (app is active)
3. **Pending notification limit**: iOS allows 64 pending local notifications - sufficient for this feature

## Progress Calculation Research

### Percentage-Based Milestones

The spec defines progress as:
```
progress = (startWeight - currentWeight) / (startWeight - goalWeight) * 100
```

For weight gain goals (goalWeight > startWeight):
```
progress = (currentWeight - startWeight) / (goalWeight - startWeight) * 100
```

### Milestone Thresholds

| Milestone | Trigger Condition | Notification Type |
|-----------|-------------------|-------------------|
| 25% | progress >= 25% | Celebration |
| 50% | progress >= 50% | "Halfway there" celebration |
| 75% | progress >= 75% | "Almost there" celebration |
| 100% | progress >= 100% | "Goal achieved" celebration |
| Approaching | within 5 lb/2.5 kg of goal | Alert |

### Edge Cases

1. **Start weight determination**: First weight logged AFTER goal is set, or first weight ever if goal was set before any logging
2. **Goal change**: Recalculate progress; don't re-trigger already-achieved milestones unless significant change (>10%)
3. **Regression**: If user regresses past a milestone, allow re-triggering when re-achieved
4. **Multiple milestones in one day**: Show highest milestone only to avoid spam

## Data Model Research

### MilestoneAchievement Entity

Required fields per spec:
- Milestone type (25%, 50%, 75%, 100%, approaching, goal_achieved)
- Date achieved
- Weight at achievement
- Goal weight at time of achievement (for goal-change detection)
- Notification sent flag (for graceful degradation)

### NotificationPreferences

Per spec FR-006, FR-010:
- Goal notifications enabled (master toggle)
- Milestone celebrations enabled
- Approaching goal alerts enabled
- Weekly summaries enabled
- Summary day/time (default: Sunday 9 AM)

## Testing Strategy

### Unit Test Coverage

1. **GoalProgressCalculator**
   - Progress percentage calculation (weight loss)
   - Progress percentage calculation (weight gain)
   - Milestone threshold detection
   - Approaching goal detection
   - Start weight determination logic

2. **MilestoneTracker**
   - Duplicate prevention logic
   - Regression detection
   - Goal change handling
   - Multi-milestone-in-one-day filtering

3. **NotificationManager Extensions**
   - Notification content formatting
   - Preference respect (disabled notifications)
   - Unit conversion in messages

### Integration Test Coverage

1. Weight entry triggers milestone check
2. Milestone achievement persists to SwiftData
3. Settings changes update notification preferences

### Manual Device Testing

- Notification appearance and content
- VoiceOver accessibility
- Notification taps open app to correct view

## Competitive Analysis

### Common Patterns in Weight Tracking Apps

| App | Milestone Style | Frequency | Duplicate Handling |
|-----|-----------------|-----------|-------------------|
| MyFitnessPal | Badge achievements | On entry | Track in user profile |
| Lose It! | Percentage milestones | On entry | Server-side dedup |
| Noom | Celebration screens | On entry + weekly | Track locally |

**W8Trackr Approach**: Combine percentage milestones (spec) with local SwiftData tracking (offline-first), triggered immediately on qualifying weight entry.

## Recommendations

### Architecture

1. **New `GoalProgressCalculator`**: Pure functions for progress math (highly testable)
2. **New `MilestoneAchievement` model**: SwiftData for persistence
3. **Extend `NotificationManager`**: Add goal notification scheduling
4. **Extend `SettingsView`**: Add granular notification preferences

### Implementation Order

1. Unit tests for progress calculation (TDD)
2. `GoalProgressCalculator` implementation
3. Unit tests for milestone tracking
4. `MilestoneAchievement` model
5. Integration with weight entry flow
6. Settings UI for preferences

### Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Notification fatigue | Strict duplicate prevention, highest-milestone-only rule |
| Goal change confusion | Clear messaging about progress recalculation |
| Permission denied | Graceful degradation - record milestones even without notification permission |

## Sources

- [Apple HIG: Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications)
- [UNUserNotificationCenter Documentation](https://developer.apple.com/documentation/usernotifications)
- Existing codebase: `NotificationManager.swift`, `NotificationScheduler.swift`
- Feature spec: `specs/002-goal-notifications/spec.md`
