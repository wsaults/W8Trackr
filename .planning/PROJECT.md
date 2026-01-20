# W8Trackr Pre-Launch Audit

## What This Is

W8Trackr is an iOS weight tracking app with HealthKit sync, trend analysis, milestone celebrations, and iCloud backup. This milestone focuses on fixing bugs and UX issues discovered during pre-launch audit to prepare for App Store submission.

## Core Value

Users can reliably track their weight and see progress toward their goals without UI bugs undermining the experience.

## Requirements

### Validated

- ✓ Weight entry logging with date/notes — existing
- ✓ HealthKit export (write weight to Apple Health) — existing
- ✓ Trend analysis with EWMA smoothing — existing
- ✓ Milestone celebrations at 25/50/75/100% — existing
- ✓ Goal weight tracking with progress visualization — existing
- ✓ iCloud sync via SwiftData/CloudKit — existing
- ✓ Daily reminder notifications — existing
- ✓ CSV/JSON data export — existing

### Active

- [ ] Fix milestone popup appearing repeatedly
- [ ] Fix chart animation jank on date segment change
- [ ] Move Goal Reached banner to top of dashboard
- [ ] Consolidate iCloud sync status to Settings section only
- [ ] Remove/implement fatalError stub services
- [ ] Add undo capability for Delete All Entries

### Out of Scope

- HealthKit import (P2 feature) — deferred to post-launch
- Social sharing feature — spec exists, deferred
- iOS widget — spec exists, deferred
- New features — this milestone is bug fixes only

## Context

**Current State:** App is functionally complete but has UX bugs discovered during pre-launch testing.

**Known Issues:**
1. Same milestone popup shows every dashboard visit (persistence bug)
2. Chart line squiggles during date range animation (identity/recalculation issue)
3. "Goal Reached" banner requires scrolling to see (layout priority)
4. iCloud sync status appears in too many places (dashboard, logbook, settings header)
5. MilestoneTracker and GoalProgressCalculator have fatalError stubs
6. "Delete All Entries" has no undo

**Codebase Map:** `.planning/codebase/` contains architecture, conventions, and concerns documentation.

**Specs:** `specs/` folder contains detailed specifications for implemented features.

## Constraints

- **Platform**: iOS 26.0+, Swift 6.2+
- **Architecture**: Pure SwiftUI with SwiftData, no ViewModels
- **Dependencies**: No third-party frameworks allowed
- **Concurrency**: Strict Swift concurrency only (no GCD)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Bug fixes only, no new features | Focus on stability for launch | — Pending |
| Keep HealthKit import as P2 | Export works, import adds complexity | — Pending |

---
*Last updated: 2026-01-20 after initialization*
