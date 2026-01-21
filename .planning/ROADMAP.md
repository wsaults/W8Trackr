# Roadmap: W8Trackr Pre-Launch Audit

## Overview

This milestone addresses bugs and UX issues discovered during pre-launch testing. The journey moves from critical stability fixes (fatalError stubs, milestone popup bug) through isolated UI fixes (chart animation) to user-facing polish (banner placement, sync status consolidation, undo capability) and finally code quality cleanup (GCD migration, deprecated APIs). All work prepares the app for App Store submission.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3, 4): Planned milestone work
- Decimal phases (e.g., 2.1): Urgent insertions if needed

- [x] **Phase 1: Critical Bugs** - Fix crash-risk stubs and repeated milestone popup
- [x] **Phase 2: Chart Animation** - Fix jank during date segment changes
- [x] **Phase 3: UX Polish** - Banner placement, sync status consolidation, undo capability
- [x] **Phase 4: Code Quality** - Migrate GCD to async/await, replace deprecated APIs
- [x] **Phase 5: Light/Dark Mode** - Add proper light/dark mode support
- [x] **Phase 6: Dashboard Polish** - Improve card layouts, hero card styling, chart labels, FAB alignment
- [x] **Phase 7: Chart Improvements** - Extended prediction line, horizontal scrolling, tap selection
- [x] **Phase 8: Logbook Improvements** - Month-segmented dates, enhanced row data, filter menu
- [ ] **Phase 9: Milestone Intervals** - Customizable milestone celebration intervals

## Phase Details

### Phase 1: Critical Bugs
**Goal**: Eliminate runtime crash risks and fix the most visible UX bug
**Depends on**: Nothing (first phase)
**Requirements**: BUG-01, BUG-03, BUG-04
**Success Criteria** (what must be TRUE):
  1. Milestone popup shows only once per milestone achievement, not on every dashboard visit
  2. App does not contain fatalError stubs that could crash at runtime
  3. MilestoneTracker service either works or is removed
  4. GoalProgressCalculator service either works or is removed
**Plans**: 2 plans

Plans:
- [x] 01-01-PLAN.md - Fix milestone celebration popup showing repeatedly
- [x] 01-02-PLAN.md - Remove fatalError stub services and unused code

### Phase 2: Chart Animation
**Goal**: Smooth chart transitions when user changes date range
**Depends on**: Phase 1
**Requirements**: BUG-02
**Success Criteria** (what must be TRUE):
  1. Chart line animates smoothly when switching between date segments (1W, 1M, 3M, etc.)
  2. No visual jank, squiggling, or jittering during animation
  3. Chart maintains correct data accuracy after animation completes
**Plans**: 1 plan

Plans:
- [x] 02-01-PLAN.md - Fix ChartEntry identity for smooth animations

### Phase 3: UX Polish
**Goal**: Improve dashboard layout and data safety for better user experience
**Depends on**: Phase 2
**Requirements**: UX-01, UX-02, UX-03
**Success Criteria** (what must be TRUE):
  1. Goal Reached banner appears at top of dashboard (visible without scrolling)
  2. iCloud sync status appears only in Settings section (not in dashboard or logbook)
  3. Delete All Entries action can be undone within a reasonable time window
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md - Goal Reached banner at top + remove sync status from Dashboard/Logbook
- [x] 03-02-PLAN.md - Add undo capability for Delete All Entries

### Phase 4: Code Quality
**Goal**: Clean up deprecated patterns and concurrency violations
**Depends on**: Phase 3
**Requirements**: QUAL-01, QUAL-02
**Success Criteria** (what must be TRUE):
  1. No GCD (DispatchQueue) usage remains in codebase
  2. All async operations use Swift concurrency (async/await, @MainActor)
  3. No deprecated .cornerRadius() calls remain in views
  4. SwiftLint passes with zero warnings
**Plans**: 4 plans

Plans:
- [x] 04-01-PLAN.md - Replace deprecated SwiftUI APIs and migrate View GCD to Task.sleep
- [x] 04-02-PLAN.md - Migrate Manager classes from GCD to @MainActor + async/await
- [x] 04-03-PLAN.md - Migrate HealthSyncManager to @Observable (gap closure)
- [x] 04-04-PLAN.md - Fix SwiftLint violations (gap closure)

### Phase 5: Light/Dark Mode
**Goal**: Ensure app looks correct in both light and dark appearance modes
**Depends on**: Phase 4
**Requirements**: UX-04
**Success Criteria** (what must be TRUE):
  1. App respects system appearance setting (light/dark)
  2. All views render correctly in both modes
  3. No hardcoded colors that break in opposite mode
  4. Charts and visualizations adapt to color scheme
**Plans**: 3 plans

Plans:
- [x] 05-01-PLAN.md - Migrate Dashboard, Onboarding, Goals, Analytics views to AppColors
- [x] 05-02-PLAN.md - Fix chart colors, deprecated APIs, and Animation view colors
- [x] 05-03-PLAN.md - Migrate remaining 10 views to AppColors (gap closure)

### Phase 6: Dashboard Polish
**Goal**: Polish dashboard card layouts and styling for better visual consistency
**Depends on**: Phase 5
**Requirements**: UX-05, UX-06, UX-07, UX-08, UX-09
**Success Criteria** (what must be TRUE):
  1. Goal prediction card takes full width and has improved visual design
  2. Current Weight "Current Weight" text is clearly readable on gradient background
  3. Current Weight card background is green when losing weight (down trend), red/orange when gaining (up trend)
  4. Chart segmented control shows 1W, 1M, 3M, 6M, 1Y, All (months not days)
  5. FAB button is right-aligned at bottom of dashboard
**Plans**: 1 plan

Plans:
- [x] 06-01-PLAN.md - Dashboard styling: chart labels, hero card trends, FAB alignment, full-width prediction

### Phase 7: Chart Improvements
**Goal**: Make chart more interactive with scrolling, extended prediction, and tap selection
**Depends on**: Phase 6
**Requirements**: CHART-01, CHART-02, CHART-03
**Success Criteria** (what must be TRUE):
  1. Prediction line extends 14 days ahead (not just 1 day)
  2. Chart can be scrolled horizontally to explore historical data
  3. Tapping on chart shows exact weight value for that date
  4. Chart feels responsive and confidence-inspiring
**Plans**: 1 plan

Plans:
- [x] 07-01-PLAN.md - Extended prediction, horizontal scrolling, tap selection

### Phase 8: Logbook Improvements
**Goal**: Enhance logbook with better organization, richer data display, and filtering
**Depends on**: Phase 7
**Requirements**: LOG-01, LOG-02, LOG-03
**Success Criteria** (what must be TRUE):
  1. Logbook entries are segmented by month with clear section headers
  2. Each row displays: Date (day+weekday), Entry weight, Moving Average, Weekly Rate (with arrow), Notes indicator
  3. Nav bar has filter button with menu: Notes, Milestones, Day of Week submenu
  4. Filtering works correctly and persists during session
**Plans**: 2 plans

Plans:
- [x] 08-01-PLAN.md - Month sections, row data model, enhanced row view
- [x] 08-02-PLAN.md - Filter menu and filtering logic

**Details:**
Row layout example:
```
16      170.0     171.1          down-arrow 0.2     note-icon
Tue
```
Filter menu options: Notes, Milestones, Day of Week (submenu)

Note: "Heights" filter omitted - WeightEntry has no height property. "Weights" filter removed as it would show all entries (default behavior).

### Phase 9: Milestone Intervals
**Goal**: Allow users to customize when milestone celebrations trigger
**Depends on**: Phase 8
**Requirements**: SETTINGS-01
**Success Criteria** (what must be TRUE):
  1. User can select milestone interval in Settings (every 5 lbs, 10 lbs, or 15 lbs)
  2. Milestone celebrations respect the chosen interval
  3. Setting persists across app launches
  4. Default interval matches current behavior (every 5 lbs)
**Plans**: 1 plan

Plans:
- [ ] 09-01-PLAN.md - Add MilestoneInterval enum, Settings UI, and thread preference through views

**Details:**
- MilestoneInterval enum with three presets: 5 lb (2 kg), 10 lb (5 kg), 15 lb (7 kg)
- Segmented picker in Settings matching existing Weight Unit pattern
- @AppStorage for persistence
- Default .five maintains backward compatibility

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Critical Bugs | 2/2 | Complete | 2026-01-20 |
| 2. Chart Animation | 1/1 | Complete | 2026-01-20 |
| 3. UX Polish | 2/2 | Complete | 2026-01-20 |
| 4. Code Quality | 4/4 | Complete | 2026-01-20 |
| 5. Light/Dark Mode | 3/3 | Complete | 2026-01-20 |
| 6. Dashboard Polish | 1/1 | Complete | 2026-01-20 |
| 7. Chart Improvements | 1/1 | Complete | 2026-01-20 |
| 8. Logbook Improvements | 2/2 | Complete | 2026-01-20 |
| 9. Milestone Intervals | 0/1 | Planned | - |

---
*Roadmap created: 2026-01-20*
*Phase 1 planned: 2026-01-20*
*Phase 2 planned: 2026-01-20*
*Phase 3 planned: 2026-01-20*
*Phase 4 planned: 2026-01-20*
*Phase 4 gap closure plans: 2026-01-20*
*Phase 5 planned: 2026-01-20*
*Phase 5 gap closure plan: 2026-01-20*
*Phase 6 planned: 2026-01-20*
*Phase 7 planned: 2026-01-20*
*Phase 7 complete: 2026-01-20*
*Phase 8 added: 2026-01-20*
*Phase 8 planned: 2026-01-20*
*Phase 8 complete: 2026-01-20*
*Phase 9 added: 2026-01-21*
*Phase 9 planned: 2026-01-21*
