# Requirements: W8Trackr Pre-Launch Audit

**Defined:** 2026-01-20
**Core Value:** Users can reliably track weight and see progress without UI bugs undermining the experience

## v1 Requirements

Requirements for pre-launch audit fixes. Each maps to roadmap phases.

### Bug Fixes

- [x] **BUG-01**: Fix milestone popup appearing repeatedly on every dashboard visit
- [x] **BUG-02**: Fix chart animation jank when changing date segments
- [x] **BUG-03**: Remove fatalError stubs from MilestoneTracker service
- [x] **BUG-04**: Remove fatalError stubs from GoalProgressCalculator service

### UX Improvements

- [x] **UX-01**: Move Goal Reached banner to top of dashboard when active
- [x] **UX-02**: Consolidate iCloud sync status to Settings section only (remove from dashboard, logbook, settings header)
- [x] **UX-03**: Add undo capability for "Delete All Entries" action
- [x] **UX-04**: Add proper light/dark mode support across all views
- [x] **UX-05**: Goal prediction card should take full width and look better
- [x] **UX-06**: Current Weight card "Current Weight" text should be readable on colored background
- [x] **UX-07**: Current Weight card background should be red/green based on up/down trend
- [x] **UX-08**: Chart segmented control should show months (1M, 3M, 6M) not days (30D, 90D, 180D)
- [x] **UX-09**: Move + FAB button to be right aligned
- [x] **UX-10**: Redesign weight entry controls with plus/minus icons, increment labels, and accessibility support
- [x] **UX-11**: Replace FAB with iOS 26 Liquid Glass tab bar bottom accessory for adding entries
- [x] **UX-12**: Simplify weight entry screen to focused text input with number keyboard and labeled notes field
- [x] **UX-13**: Move add entry button to trailing side of tab bar (Reminders app pattern)
- [x] **UX-14**: Improve next milestone progress UI with left-to-right progress bar
- [x] **UX-15**: Hide streak-related UI elements for launch (streak card, notifications, celebration)

### Chart Improvements

- [x] **CHART-01**: Extend prediction line to 14 days ahead (not just 1 day)
- [x] **CHART-02**: Enable horizontal scrolling to explore historical data
- [x] **CHART-03**: Add tap selection to show exact weight value for date

### Logbook Improvements

- [x] **LOG-01**: Segment logbook entries by month with clear section headers
- [x] **LOG-02**: Enhanced row display with date, weight, moving average, weekly rate arrow, notes indicator
- [x] **LOG-03**: Add filter menu in nav bar with Notes, Milestones, Day of Week filters
- [x] **LOG-04**: Add column headers above logbook rows with reduced row height for data density
- [x] **LOG-05**: Fix spacing alignment between logbook header and row columns

### Settings

- [x] **SETTINGS-01**: Allow users to customize milestone celebration interval (every 5, 10, or 15 lbs)

### Code Quality

- [x] **QUAL-01**: Migrate deprecated GCD usage to async/await (HealthKitManager, NotificationManager, CloudKitSyncManager)
- [x] **QUAL-02**: Replace deprecated `.cornerRadius()` with `.clipShape(.rect(cornerRadius:))`

### CI/CD

- [x] **CICD-01**: App Store automation (export compliance, screenshot devices, CI linting)

## v2 Requirements

Deferred to post-launch. Tracked but not in current roadmap.

### Features

- **FEAT-01**: HealthKit import (bring existing Apple Health weight data into W8Trackr)
- **FEAT-02**: Social sharing (share progress images)
- **FEAT-03**: iOS home screen widget

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| New tracking features | Bug fix milestone only |
| UI redesign | Current design is fine, just fixing issues |
| iPad support | Post-launch consideration |
| watchOS app | Post-launch consideration |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BUG-01 | Phase 1 | Complete |
| BUG-02 | Phase 2 | Complete |
| BUG-03 | Phase 1 | Complete |
| BUG-04 | Phase 1 | Complete |
| UX-01 | Phase 3 | Complete |
| UX-02 | Phase 3 | Complete |
| UX-03 | Phase 3 | Complete |
| QUAL-01 | Phase 4 | Complete |
| QUAL-02 | Phase 4 | Complete |
| UX-04 | Phase 5 | Complete |
| UX-05 | Phase 6 | Complete |
| UX-06 | Phase 6 | Complete |
| UX-07 | Phase 6 | Complete |
| UX-08 | Phase 6 | Complete |
| UX-09 | Phase 6 | Complete |
| CHART-01 | Phase 7 | Complete |
| CHART-02 | Phase 7 | Complete |
| CHART-03 | Phase 7 | Complete |
| LOG-01 | Phase 8 | Complete |
| LOG-02 | Phase 8 | Complete |
| LOG-03 | Phase 8 | Complete |
| SETTINGS-01 | Phase 9 | Complete |
| UX-10 | Phase 10 | Complete |
| LOG-04 | Phase 11 | Complete |
| LOG-05 | Phase 12 | Complete |
| CICD-01 | Phase 13 | Complete |
| UX-11 | Phase 14 | Complete |
| UX-12 | Phase 15 | Complete |
| UX-13 | Phase 16 | Complete |
| UX-14 | Phase 17 | Complete |
| UX-15 | Phase 18 | Complete |

**Coverage:**
- v1 requirements: 31 total
- Mapped to phases: 31
- Unmapped: 0

---
*Requirements defined: 2026-01-20*
*Traceability updated: 2026-01-21*
