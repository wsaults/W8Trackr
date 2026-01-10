# Feature Specification: Apple Health Integration

**Feature Branch**: `001-apple-health-sync`
**Created**: 2025-01-09
**Status**: Draft
**Input**: User description: "Add Apple Health integration to sync weight entries"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Export Weight to Apple Health (Priority: P1)

As a user who tracks weight in W8Trackr, I want my weight entries to automatically appear in Apple Health so that my health data is centralized and available to other apps and my healthcare providers.

**Why this priority**: This is the core value proposition. Users already have weight data in W8Trackr and want it reflected in Apple Health without manual re-entry. This enables the Apple Health ecosystem benefits immediately.

**Independent Test**: Can be fully tested by logging a weight entry in W8Trackr and verifying it appears in the Apple Health app. Delivers immediate value even without import functionality.

**Acceptance Scenarios**:

1. **Given** a user has granted Health access, **When** they log a new weight entry in W8Trackr, **Then** that entry appears in Apple Health within 5 seconds
2. **Given** a user has granted Health access, **When** they edit an existing weight entry in W8Trackr, **Then** the corresponding Apple Health entry is updated
3. **Given** a user has granted Health access, **When** they delete a weight entry in W8Trackr, **Then** the corresponding Apple Health entry is removed
4. **Given** a user has denied Health access, **When** they log a weight entry, **Then** the entry is saved locally and the user sees no error (graceful degradation)

---

### User Story 2 - Import Weight from Apple Health (Priority: P2)

As a new W8Trackr user who has existing weight data in Apple Health (from other apps, smart scales, or manual entry), I want to import that historical data so I can see my complete weight history and trends in W8Trackr.

**Why this priority**: Enables users with existing health data to adopt W8Trackr without losing historical context. Secondary to export because new users can start fresh, but existing Health users expect their data to transfer.

**Independent Test**: Can be tested by having weight entries in Apple Health (from another source), then enabling sync in W8Trackr and verifying historical entries appear. Delivers value of unified history view.

**Acceptance Scenarios**:

1. **Given** a user has weight entries in Apple Health, **When** they enable Health sync in W8Trackr for the first time, **Then** they see a prompt to import existing entries
2. **Given** a user chooses to import, **When** the import completes, **Then** all Apple Health weight entries appear in W8Trackr's history
3. **Given** a user chooses to skip import, **When** they continue, **Then** only future entries are synchronized
4. **Given** imported entries exist, **When** viewing the logbook, **Then** imported entries are visually distinguishable from manually-entered entries

---

### User Story 3 - Ongoing Bidirectional Sync (Priority: P3)

As a user who logs weight from multiple sources (W8Trackr, smart scale via Health, doctor visits), I want all my weight data to stay synchronized so I have a complete picture regardless of where data originates.

**Why this priority**: Builds on P1 and P2 to create a seamless experience. Requires both export and import to be working first. Addresses the power-user scenario of multiple data sources.

**Independent Test**: Can be tested by adding entries from both W8Trackr and Apple Health (via another app or manual entry) and verifying both apps show all entries.

**Acceptance Scenarios**:

1. **Given** sync is enabled, **When** a new weight entry is added to Apple Health by another source, **Then** it appears in W8Trackr within 1 minute
2. **Given** the same date has entries in both apps with different values, **When** sync occurs, **Then** the most recently modified entry takes precedence
3. **Given** the app was closed for an extended period, **When** the user opens W8Trackr, **Then** any new Apple Health entries are imported automatically
4. **Given** sync is enabled, **When** the user views their weight chart, **Then** data from all sources is included in trend calculations

---

### Edge Cases

- What happens when the user revokes Health permissions after sync was enabled?
  - App continues to function with local data only; shows a non-blocking prompt to re-enable
- What happens when Apple Health contains duplicate entries for the same timestamp?
  - Import the entry with the most recent modification date; ignore duplicates
- What happens when the device has no Apple Health (e.g., iPad without Health app)?
  - Health sync option is hidden; app functions normally with local storage only
- What happens during initial import if there are thousands of historical entries?
  - Show progress indicator; import in batches to prevent UI freezing
- What happens if sync fails due to network issues?
  - Queue changes locally and retry when connectivity is restored; no data loss

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST request user permission before accessing Apple Health data
- **FR-002**: System MUST allow users to enable or disable Health sync at any time via Settings
- **FR-003**: System MUST export new weight entries to Apple Health when sync is enabled
- **FR-004**: System MUST update Apple Health when a W8Trackr entry is edited
- **FR-005**: System MUST remove the corresponding Apple Health entry when a W8Trackr entry is deleted
- **FR-006**: System MUST import existing Apple Health weight entries when the user opts in during initial setup
- **FR-007**: System MUST detect and import new Apple Health entries added by other sources
- **FR-008**: System MUST handle unit conversion between W8Trackr's preferred unit and Apple Health's stored unit
- **FR-009**: System MUST gracefully degrade when Health permissions are denied (app remains fully functional with local data)
- **FR-010**: System MUST preserve the original source attribution for imported entries
- **FR-011**: System MUST resolve conflicts using "most recently modified wins" strategy
- **FR-012**: System MUST sync entries across the full date range (no arbitrary time limits)

### Key Entities

- **HealthSyncState**: Represents the user's sync preferences and status (enabled/disabled, last sync timestamp, pending changes count)
- **WeightEntry** (existing): Extended to track source attribution (W8Trackr, Apple Health, or specific external app name) and external identifier for sync correlation
- **SyncConflict**: Temporary representation of entries that differ between sources, resolved automatically using modification timestamps

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can enable Health sync in under 30 seconds (from Settings to first successful sync)
- **SC-002**: New weight entries appear in Apple Health within 5 seconds of logging
- **SC-003**: External Health entries appear in W8Trackr within 1 minute of app foregrounding
- **SC-004**: Initial import of 365 days of historical data completes in under 10 seconds
- **SC-005**: 100% of weight entries are accurately synced (no data loss or corruption)
- **SC-006**: App remains fully functional when Health access is unavailable or denied
- **SC-007**: Users who enable Health sync report the same or higher satisfaction with W8Trackr (no negative UX impact from sync complexity)

## Assumptions

The following reasonable defaults have been applied based on iOS platform conventions and health app best practices:

1. **Sync timing**: Background sync with immediate foreground sync (matches iOS system apps like Photos and Notes)
2. **Conflict resolution**: Most recently modified entry wins (standard distributed systems approach)
3. **Historical import**: All available history is importable (users expect complete data portability)
4. **Permission handling**: Standard iOS permission flow with graceful degradation on denial
5. **Unit handling**: Automatic conversion between lb/kg as needed (Health stores in kg internally)
