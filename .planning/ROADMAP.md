# Roadmap: W8Trackr Pre-Launch Audit

## Overview

This milestone addresses bugs and UX issues discovered during pre-launch testing. The journey moves from critical stability fixes (fatalError stubs, milestone popup bug) through isolated UI fixes (chart animation) to user-facing polish (banner placement, sync status consolidation, undo capability) and finally code quality cleanup (GCD migration, deprecated APIs). All work prepares the app for App Store submission.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3, 4): Planned milestone work
- Decimal phases (e.g., 2.1): Urgent insertions if needed

- [x] **Phase 1: Critical Bugs** - Fix crash-risk stubs and repeated milestone popup
- [x] **Phase 2: Chart Animation** - Fix jank during date segment changes
- [ ] **Phase 3: UX Polish** - Banner placement, sync status consolidation, undo capability
- [ ] **Phase 4: Code Quality** - Migrate GCD to async/await, replace deprecated APIs

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
- [ ] 03-01-PLAN.md - Goal Reached banner at top + remove sync status from Dashboard/Logbook
- [ ] 03-02-PLAN.md - Add undo capability for Delete All Entries

### Phase 4: Code Quality
**Goal**: Clean up deprecated patterns and concurrency violations
**Depends on**: Phase 3
**Requirements**: QUAL-01, QUAL-02
**Success Criteria** (what must be TRUE):
  1. No GCD (DispatchQueue) usage remains in codebase
  2. All async operations use Swift concurrency (async/await, @MainActor)
  3. No deprecated .cornerRadius() calls remain in views
  4. SwiftLint passes with zero warnings
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Critical Bugs | 2/2 | Complete | 2026-01-20 |
| 2. Chart Animation | 1/1 | Complete | 2026-01-20 |
| 3. UX Polish | 0/2 | Ready | - |
| 4. Code Quality | 0/TBD | Not started | - |

---
*Roadmap created: 2026-01-20*
*Phase 1 planned: 2026-01-20*
*Phase 2 planned: 2026-01-20*
*Phase 3 planned: 2026-01-20*
