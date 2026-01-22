# Roadmap: W8Trackr

## Milestones

- [x] **v1.0 Pre-Launch Audit** - Phases 1-20 (shipped 2026-01-22)
- [ ] **v1.1 Feature Expansion** - Phases 21-26 (in progress)

## Phases

<details>
<summary>v1.0 Pre-Launch Audit (Phases 1-20) - SHIPPED 2026-01-22</summary>

See archived milestone documentation for v1.0 phase details.

**Summary:** 20 phases, 30 plans, 15,861 LOC shipped.

</details>

### v1.1 Feature Expansion (In Progress)

**Milestone Goal:** Add HealthKit import, home screen widgets, social sharing, Spanish localization, and comprehensive test coverage.

**Phase Numbering:**
- Integer phases (21, 22, 23): Planned milestone work
- Decimal phases (21.1, 21.2): Urgent insertions (marked with INSERTED)

- [ ] **Phase 21: Infrastructure & Migration** - App Group setup and data migration
- [ ] **Phase 22: Widgets** - Home screen widgets (small, medium, large)
- [ ] **Phase 23: HealthKit Import** - Read weight data from Apple Health
- [ ] **Phase 24: Social Sharing** - Shareable progress images
- [ ] **Phase 25: Localization** - Spanish language support
- [ ] **Phase 26: Testing** - Comprehensive test coverage

## Phase Details

### Phase 21: Infrastructure & Migration
**Goal:** Existing users' data migrates safely to App Group container, enabling widget data sharing
**Depends on:** v1.0 complete
**Requirements:** INFRA-01, INFRA-02, INFRA-03
**Risk:** HIGH - Affects all existing users, CloudKit sync implications
**Success Criteria** (what must be TRUE):
  1. App launches without data loss for existing users (migration verified)
  2. SwiftData container lives in App Group location accessible to extensions
  3. HealthKit settings link navigates to system Health settings (not app settings)
  4. CloudKit sync continues working after migration (no duplicates, no data loss)
**Plans:** TBD

Plans:
- [ ] 21-01: TBD

### Phase 22: Widgets
**Goal:** Users can add home screen widgets showing weight, progress, and trends
**Depends on:** Phase 21 (App Group infrastructure)
**Requirements:** WDGT-01, WDGT-02, WDGT-03, WDGT-04, WDGT-05
**Risk:** MEDIUM - New extension target, entitlements
**Success Criteria** (what must be TRUE):
  1. Small widget displays current weight with trend arrow (up/down/neutral)
  2. Medium widget displays progress percentage toward goal weight
  3. Large widget displays sparkline chart of recent weight entries
  4. Widgets update when user adds, edits, or deletes weight entries in app
  5. Tapping any widget opens W8Trackr app
**Plans:** TBD

Plans:
- [ ] 22-01: TBD

### Phase 23: HealthKit Import
**Goal:** Users can import weight data from Apple Health with automatic sync
**Depends on:** Phase 21 (for testing infrastructure patterns)
**Requirements:** HKIT-01, HKIT-02, HKIT-03, HKIT-04, HKIT-05
**Risk:** HIGH - Complex conflict resolution, sync state management
**Success Criteria** (what must be TRUE):
  1. User can grant HealthKit read permission from Settings
  2. All weight samples from Apple Health appear in W8Trackr
  3. Imported entries show Health icon to distinguish from manual entries
  4. Initial sync completes automatically when permission is first granted
  5. New Health data syncs automatically in background without user action
**Plans:** TBD

Plans:
- [ ] 23-01: TBD

### Phase 24: Social Sharing
**Goal:** Users can share their weight loss progress as an image
**Depends on:** Phase 21 (stable infrastructure)
**Requirements:** SHAR-01, SHAR-02, SHAR-03
**Risk:** LOW - Self-contained feature, contracts exist
**Success Criteria** (what must be TRUE):
  1. User can generate a progress image from dashboard showing stats/chart
  2. Share sheet appears with standard iOS sharing options
  3. User can toggle privacy mode to hide exact weight values before sharing
**Plans:** TBD

Plans:
- [ ] 24-01: TBD

### Phase 25: Localization
**Goal:** Spanish-speaking users can use the app in their native language
**Depends on:** Phases 22-24 (UI stable before translation)
**Requirements:** LOCL-01, LOCL-02, LOCL-03
**Risk:** LOW - Standard localization workflow
**Success Criteria** (what must be TRUE):
  1. All UI text displays correctly in Spanish when device language is Spanish
  2. Numbers format with correct decimal/thousands separators for Spanish locale
  3. Dates format according to Spanish locale conventions
  4. App Store listing available in Spanish (name, description, keywords)
**Plans:** TBD

Plans:
- [ ] 25-01: TBD

### Phase 26: Testing
**Goal:** Comprehensive test coverage prevents regressions and validates critical paths
**Depends on:** Phases 21-25 (test final implementations)
**Requirements:** TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06
**Risk:** LOW - Testing infrastructure patterns established
**Success Criteria** (what must be TRUE):
  1. Unit tests verify weight entry CRUD operations (create, read, update, delete)
  2. Unit tests verify HealthKit sync logic with mock data
  3. Unit tests verify EWMA trend calculations produce correct values
  4. UI tests verify complete weight entry flow (add, view, edit, delete)
  5. UI tests verify settings flow (change goal, enable notifications, etc.)
  6. Mock HealthKit store available for isolated testing without real Health data
**Plans:** TBD

Plans:
- [ ] 26-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 21 -> 21.1 -> 21.2 -> 22 -> etc.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 21. Infrastructure & Migration | v1.1 | 0/TBD | Not started | - |
| 22. Widgets | v1.1 | 0/TBD | Not started | - |
| 23. HealthKit Import | v1.1 | 0/TBD | Not started | - |
| 24. Social Sharing | v1.1 | 0/TBD | Not started | - |
| 25. Localization | v1.1 | 0/TBD | Not started | - |
| 26. Testing | v1.1 | 0/TBD | Not started | - |

---
*Roadmap created: 2026-01-22*
*Last updated: 2026-01-22*
