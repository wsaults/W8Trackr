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

### Chart Improvements

- [x] **CHART-01**: Extend prediction line to 14 days ahead (not just 1 day)
- [x] **CHART-02**: Enable horizontal scrolling to explore historical data
- [x] **CHART-03**: Add tap selection to show exact weight value for date

### Code Quality

- [x] **QUAL-01**: Migrate deprecated GCD usage to async/await (HealthKitManager, NotificationManager, CloudKitSyncManager)
- [x] **QUAL-02**: Replace deprecated `.cornerRadius()` with `.clipShape(.rect(cornerRadius:))`

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

**Coverage:**
- v1 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0

---
*Requirements defined: 2026-01-20*
*Traceability updated: 2026-01-20*
