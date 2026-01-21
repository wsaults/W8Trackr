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
- [x] **Phase 9: Milestone Intervals** - Customizable milestone celebration intervals
- [x] **Phase 10: Weight Entry UI Redesign** - Better weight entry controls with improved UX
- [x] **Phase 11: Logbook Header & Cell Height** - Add column headers and reduce row height
- [x] **Phase 12: Logbook Column Alignment** - Fix header/row column spacing alignment
- [x] **Phase 13: App Store Automation** - Fastlane setup, GitHub Actions CI, screenshots, metadata management
- [x] **Phase 14: Add Entry UI** - Replace FAB with Liquid Glass tab bar bottom accessory button
- [ ] **Phase 15: Weight Entry Screen** - Simplify to focused text input with number keyboard and notes field
- [ ] **Phase 16: Trailing FAB Button** - Move add button to right of tab bar using GlassEffectContainer

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
- [x] 09-01-PLAN.md - Add MilestoneInterval enum, Settings UI, and thread preference through views

**Details:**
- MilestoneInterval enum with three presets: 5 lb (2 kg), 10 lb (5 kg), 15 lb (7 kg)
- Segmented picker in Settings matching existing Weight Unit pattern
- @AppStorage for persistence
- Default .five maintains backward compatibility

### Phase 10: Weight Entry UI Redesign
**Goal**: Replace current weight entry control with a more intuitive and visually appealing UI
**Depends on**: Phase 9
**Requirements**: UX-10 (weight entry redesign)
**Success Criteria** (what must be TRUE):
  1. Weight entry control is visually appealing and consistent with app design
  2. Entry method is intuitive and easy to use
  3. Supports both lb and kg units seamlessly
  4. Works well with accessibility features (VoiceOver, Dynamic Type)
**Plans**: 1 plan

Plans:
- [x] 10-01-PLAN.md - Create unified WeightAdjustmentButton with plus/minus icons and increment labels

**Details:**
- Replace media transport icons (backward/forward) with semantic plus/minus icons
- Add visible increment labels (+1, +0.1, -1, -0.1) below each button
- Visual hierarchy: filled icons for large increments, outline for small
- Unified component shared between WeightEntryView and FirstWeightStepView
- Full accessibility support with descriptive VoiceOver labels

### Phase 11: Logbook Header & Cell Height
**Goal**: Add column headers to logbook and optimize row height for better data density
**Depends on**: Phase 10
**Requirements**: LOG-04 (logbook header and cell height)
**Success Criteria** (what must be TRUE):
  1. Column headers appear above logbook cells indicating what each column represents
  2. Headers are sticky/pinned when scrolling (visible at all times)
  3. Row height is reduced for better data density
  4. Layout remains readable and accessible
**Plans**: 1 plan

Plans:
- [x] 11-01-PLAN.md - Create LogbookHeaderView and reduce row padding

**Details:**
- Add header row with column labels: Date, Weight, Avg, Rate, Notes
- Header should remain visible when scrolling through entries
- Reduce vertical padding in cells to fit more entries on screen
- Maintain touch target accessibility requirements

### Phase 12: Logbook Column Alignment
**Goal**: Fix spacing alignment between logbook header and row columns
**Depends on**: Phase 11
**Requirements**: LOG-05 (logbook column alignment)
**Success Criteria** (what must be TRUE):
  1. Header columns and row columns are perfectly aligned
  2. Equal spacing between all columns in both header and rows
  3. Visual consistency when scrolling through entries
**Plans**: 1 plan

Plans:
- [x] 12-01-PLAN.md - Extract LogbookLayout constants, apply fixed widths, always render all columns

**Details:**
- Create LogbookLayout enum with shared spacing and width constants
- Ensure LogbookHeaderView and LogbookRowView use identical column widths and spacing
- Always render all columns (show placeholder for missing data) to prevent layout shift

### Phase 13: App Store Automation
**Goal**: Complete App Store automation setup with export compliance, updated device targets, and CI linting
**Depends on**: Phase 12
**Requirements**: CICD-01 (App Store automation)
**Success Criteria** (what must be TRUE):
  1. Fastlane configured for App Store submission workflows
  2. GitHub Actions CI pipeline runs tests on push/PR
  3. Fastlane can update App Store description/metadata
  4. Automated screenshot capture configured for all required device sizes
  5. App declares ITSAppUsesNonExemptEncryption = NO to bypass export compliance
**Plans**: 1 plan

Plans:
- [x] 13-01-PLAN.md - Add export compliance key, update device targets, add SwiftLint to CI

**Details:**
- Add ITSAppUsesNonExemptEncryption = NO to Info.plist (bypass export compliance questionnaire)
- Update Snapfile and Fastfile device lists for 2026 requirements (6.9" iPhone, 13" iPad)
- Add SwiftLint step to GitHub Actions test.yml workflow
- Most infrastructure already exists (Fastfile, Appfile, Snapfile, metadata, screenshot tests)

### Phase 14: Add Entry UI
**Goal**: Replace floating action button (FAB) with iOS 26 Liquid Glass tab bar bottom accessory for adding weight entries
**Depends on**: Phase 13
**Requirements**: UX-11 (add entry UI improvement)
**Success Criteria** (what must be TRUE):
  1. Add entry button appears as tab bar bottom accessory (inline with tab bar)
  2. Button uses `.tabViewBottomAccessory()` modifier with Liquid Glass styling
  3. Tab bar minimizes on scroll with `.tabBarMinimizeBehavior(.onScrollDown)`
  4. Accessory slides inline when tab bar minimizes
  5. Existing FAB removed from dashboard
**Plans**: 1 plan

Plans:
- [x] 14-01-PLAN.md - Add tab bar accessory and remove FAB from DashboardView/SummaryView

**Details:**
- Use `.tabViewBottomAccessory { }` modifier on TabView in ContentView
- Button gets automatic Liquid Glass capsule background
- Add `.tabBarMinimizeBehavior(.onScrollDown)` for scroll-to-minimize
- Remove current FAB overlay from SummaryView/Dashboard
- Wire button to show WeightEntrySheet

**Reference:** [Hacking with Swift - TabView Bottom Accessory](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-tabview-accessory)

### Phase 15: Weight Entry Screen
**Goal**: Redesign weight entry as a focused text input form with date navigation, notes, and expandable body fat section
**Depends on**: Phase 14
**Requirements**: UX-12 (weight entry screen simplification)
**Success Criteria** (what must be TRUE):
  1. Weight input is a text field with "Weight" label above it
  2. Weight text field is auto-focused when screen appears (new entries only)
  3. Keyboard is decimal pad style (number keyboard)
  4. Date navigation uses left/right arrows for new entries (DatePicker kept for edit mode)
  5. Notes field always visible with 500-char limit and character counter
  6. Body fat in expandable "More..." section
  7. Unsaved changes detection with discard confirmation
  8. Existing plus/minus button controls removed
**Plans**: 2 plans

Plans:
- [ ] 15-01-PLAN.md - Redesign WeightEntryView with text input, date arrows, notes, expandable body fat, unsaved changes protection
- [ ] 15-02-PLAN.md - Update FirstWeightStepView to text-only input and delete WeightAdjustmentButton component

**Details:**
- Replace WeightAdjustmentButton-based UI with simple TextField
- Use @FocusState with .task {} to auto-focus weight input on appear
- Set .keyboardType(.decimalPad) for number entry
- Date arrows for new entries (right arrow disabled on today), DatePicker for edit mode
- Notes always visible with character limit and countdown when <50 remaining
- "More..." button expands body fat field with animation
- interactiveDismissDisabled(hasUnsavedChanges) with confirmation dialog
- Delete WeightAdjustmentButton.swift after migration complete

### Phase 16: Trailing FAB Button
**Goal**: Reposition add entry button to appear to the right of the tab bar (trailing side) like Reminders app
**Depends on**: Phase 15
**Requirements**: UX-13 (trailing FAB positioning)
**Success Criteria** (what must be TRUE):
  1. Add button appears to the right of the tab bar, not above it
  2. Button uses Liquid Glass styling via `.glassEffect()`
  3. Button and tab bar visually blend when close together using `GlassEffectContainer`
  4. Button remains accessible during tab bar minimize on scroll
  5. Remove `.tabViewBottomAccessory` usage (replaced by custom layout)
**Plans**: 0 plans

Plans:
- [ ] TBD (run /gsd:plan-phase 16 to break down)

**Details:**
- Replace `.tabViewBottomAccessory` with `ZStack(alignment: .bottomTrailing)` approach
- Wrap tab bar and FAB in `GlassEffectContainer` for visual blending
- Apply `.glassEffect()` to the floating button
- Position button using `.safeAreaInset` or `.offset` to align with tab bar
- Maintain accessibility labels and hints
- Handle tab bar minimize behavior (button should remain visible/accessible)

**Reference:**
- [Donny Wals - Liquid Glass Tab Bars](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)
- [GlassEffectContainer Guide](https://dev.to/arshtechpro/understanding-glasseffectcontainer-in-ios-26-2n8p)
- [Building Side-Floating FAB](https://iifx.dev/en/articles/457706754/building-the-new-ios-26-tab-bar-ui-liquid-glass-side-floating-fab)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10 -> 11 -> 12 -> 13 -> 14 -> 15 -> 16

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
| 9. Milestone Intervals | 1/1 | Complete | 2026-01-21 |
| 10. Weight Entry UI Redesign | 1/1 | Complete | 2026-01-21 |
| 11. Logbook Header & Cell Height | 1/1 | Complete | 2026-01-21 |
| 12. Logbook Column Alignment | 1/1 | Complete | 2026-01-21 |
| 13. App Store Automation | 1/1 | Complete | 2026-01-21 |
| 14. Add Entry UI | 1/1 | Complete | 2026-01-21 |
| 15. Weight Entry Screen | 0/2 | Not Started | - |
| 16. Trailing FAB Button | 0/? | Not Started | - |

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
*Phase 9 complete: 2026-01-21*
*Phase 10 added: 2026-01-21*
*Phase 10 planned: 2026-01-21*
*Phase 10 complete: 2026-01-21*
*Phase 11 added: 2026-01-21*
*Phase 11 planned: 2026-01-21*
*Phase 11 complete: 2026-01-21*
*Phase 12 added: 2026-01-21*
*Phase 12 planned: 2026-01-21*
*Phase 12 complete: 2026-01-21*
*Phase 13 added: 2026-01-21*
*Phase 13 planned: 2026-01-21*
*Phase 13 complete: 2026-01-21*
*Phase 14 added: 2026-01-21*
*Phase 14 planned: 2026-01-21*
*Phase 14 complete: 2026-01-21*
*Phase 15 added: 2026-01-21*
*Phase 15 planned: 2026-01-21*
*Phase 16 added: 2026-01-21*
