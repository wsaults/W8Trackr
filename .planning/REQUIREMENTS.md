# Requirements: W8Trackr Pre-Launch Audit

**Defined:** 2026-01-20
**Core Value:** Users can reliably track weight and see progress without UI bugs undermining the experience

## v1 Requirements

Requirements for pre-launch audit fixes. Each maps to roadmap phases.

### Bug Fixes

- [x] **BUG-01**: Fix milestone popup appearing repeatedly on every dashboard visit
- [ ] **BUG-02**: Fix chart animation jank when changing date segments
- [x] **BUG-03**: Remove fatalError stubs from MilestoneTracker service
- [x] **BUG-04**: Remove fatalError stubs from GoalProgressCalculator service

### UX Improvements

- [ ] **UX-01**: Move Goal Reached banner to top of dashboard when active
- [ ] **UX-02**: Consolidate iCloud sync status to Settings section only (remove from dashboard, logbook, settings header)
- [ ] **UX-03**: Add undo capability for "Delete All Entries" action

### Code Quality

- [ ] **QUAL-01**: Migrate deprecated GCD usage to async/await (HealthKitManager, NotificationManager, CloudKitSyncManager)
- [ ] **QUAL-02**: Replace deprecated `.cornerRadius()` with `.clipShape(.rect(cornerRadius:))`

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
| BUG-02 | Phase 2 | Pending |
| BUG-03 | Phase 1 | Complete |
| BUG-04 | Phase 1 | Complete |
| UX-01 | Phase 3 | Pending |
| UX-02 | Phase 3 | Pending |
| UX-03 | Phase 3 | Pending |
| QUAL-01 | Phase 4 | Pending |
| QUAL-02 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---
*Requirements defined: 2026-01-20*
*Traceability updated: 2026-01-20*
