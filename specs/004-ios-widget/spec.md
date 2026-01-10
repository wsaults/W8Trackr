# Feature Specification: iOS Home Screen Widget

**Feature Branch**: `004-ios-widget`
**Created**: 2025-01-09
**Status**: Draft
**Input**: User description: "ios widget"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Current Weight at a Glance (Priority: P1)

As a user tracking my weight, I want to see my current weight displayed on my home screen without opening the app, so I can quickly check my progress throughout the day.

**Why this priority**: This is the core value proposition of a widget - providing instant access to key information. Without this, there's no reason to have a widget.

**Independent Test**: Can be fully tested by adding the widget to home screen and verifying it displays the most recent weight entry with the correct unit preference.

**Acceptance Scenarios**:

1. **Given** I have recorded at least one weight entry, **When** I view the widget on my home screen, **Then** I see my most recent weight displayed in my preferred unit (lb or kg)
2. **Given** I have no weight entries recorded, **When** I view the widget on my home screen, **Then** I see a helpful message prompting me to log my first weight
3. **Given** I have the widget on my home screen, **When** I change my weight unit preference in the app settings, **Then** the widget updates to show weight in the new unit

---

### User Story 2 - See Progress Toward Goal (Priority: P2)

As a user with a weight goal, I want to see how close I am to my goal weight on the widget, so I stay motivated and aware of my progress.

**Why this priority**: Progress visualization is key to user motivation, but requires the basic weight display (P1) to function first.

**Independent Test**: Can be fully tested by setting a goal weight in the app, logging entries, and verifying the widget shows progress information (e.g., "5 lbs to goal" or progress percentage).

**Acceptance Scenarios**:

1. **Given** I have a goal weight set and weight entries recorded, **When** I view the widget, **Then** I see the difference between my current weight and goal weight
2. **Given** I have no goal weight set, **When** I view the widget, **Then** the goal progress section is not displayed (only current weight shows)
3. **Given** I have reached or exceeded my goal weight, **When** I view the widget, **Then** I see a success indicator showing I've reached my goal

---

### User Story 3 - Quick Weight Entry from Widget (Priority: P3)

As a busy user, I want to tap the widget to quickly log my weight, so I can record my weight with minimal friction.

**Why this priority**: While convenient, this enhances rather than enables the core widget experience. The widget provides value even with read-only information.

**Independent Test**: Can be fully tested by tapping the widget and verifying it opens the app directly to the weight entry screen.

**Acceptance Scenarios**:

1. **Given** I am on my home screen viewing the widget, **When** I tap anywhere on the widget, **Then** the app opens directly to the weight entry screen
2. **Given** I tap the widget to enter weight, **When** I complete and save the entry, **Then** I am returned to the home screen and the widget updates with my new weight

---

### Edge Cases

- What happens when the app has never been opened (no data container exists)?
  - Widget displays onboarding message: "Open W8Trackr to get started"
- What happens when weight data is deleted while widget is displayed?
  - Widget refreshes to show empty state on next timeline update
- How does the widget handle when the user has multiple entries on the same day?
  - Widget displays the most recent entry by timestamp
- What happens if the user's preferred unit changes while the widget is displayed?
  - Widget updates on next timeline refresh (typically within 15 minutes)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Widget MUST display the user's most recent weight entry value
- **FR-002**: Widget MUST display weight in the user's preferred unit (lb or kg) as set in app settings
- **FR-003**: Widget MUST show an empty state with guidance when no weight entries exist
- **FR-004**: Widget MUST display the date/time of the most recent weight entry
- **FR-005**: Widget MUST show progress toward goal weight when a goal is set
- **FR-006**: Widget MUST update its content when new weight entries are added in the app
- **FR-007**: Widget MUST support the small widget size at minimum
- **FR-008**: Tapping the widget MUST open the app to the weight entry screen
- **FR-009**: Widget MUST respect the system appearance (light/dark mode)

### Key Entities

- **Weight Display**: Current weight value, unit indicator, entry timestamp
- **Goal Progress**: Distance to goal (numeric), direction indicator (gaining/losing toward goal)
- **Widget State**: Has data vs. empty state, has goal vs. no goal

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view their current weight on the home screen without opening the app
- **SC-002**: Widget content refreshes within 15 minutes of a new weight entry being recorded
- **SC-003**: Widget displays correctly in both light and dark system appearances
- **SC-004**: 100% of widget taps successfully navigate to the weight entry screen
- **SC-005**: Widget renders readable text at the small size (minimum supported size)
- **SC-006**: Users with goal weights set can see their progress at a glance

## Scope Boundaries

### In Scope

- Small widget size (required)
- Medium widget size (optional enhancement)
- Current weight display
- Goal progress display
- Tap-to-open functionality
- Light/dark mode support

### Out of Scope

- Large widget size (not enough content to justify)
- Lock screen widgets (future consideration)
- Interactive weight entry directly in widget (requires iOS 17+ interactive widgets - future consideration)
- Chart/graph display in widget (better suited for medium/large sizes in future)
- Apple Watch complications (separate feature)

## Assumptions

- Users have already set up the main app and have the data container initialized
- Widget will use the same data storage as the main app (shared container)
- Widget timeline updates follow standard iOS guidelines (system-managed refresh)
- Goal weight is optional - widget gracefully handles absence of goal
- Body fat percentage is not displayed in widget (too much information for small size)

## Dependencies

- Existing `WeightEntry` model with weight value, unit, and date
- Existing user preference for `preferredWeightUnit`
- Existing user preference for `goalWeight` (optional)
