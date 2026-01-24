# Roadmap: W8Trackr

## Milestones

- [x] **v1.0 Pre-Launch Audit** - Phases 1-20 (shipped 2026-01-22)
- [x] **v1.1 Feature Expansion** - Phases 21-26 (shipped 2026-01-24)
- [ ] **v1.2 Global Localization** - Phases 27-28 (in progress)

## Phases

<details>
<summary>v1.0 Pre-Launch Audit (Phases 1-20) - SHIPPED 2026-01-22</summary>

See archived milestone documentation for v1.0 phase details.

**Summary:** 20 phases, 30 plans, 15,861 LOC shipped.

</details>

<details>
<summary>v1.1 Feature Expansion (Phases 21-26) - SHIPPED 2026-01-24</summary>

**Summary:** 6 phases, 15 plans, 18,795 LOC added.

- Phase 21: Infrastructure & Migration - App Group setup and data migration
- Phase 22: Widgets - Home screen widgets (small, medium, large)
- Phase 23: HealthKit Import - Read weight data from Apple Health
- Phase 24: Social Sharing - Shareable progress images
- Phase 25: Localization - Spanish language support
- Phase 26: Testing - Comprehensive test coverage (301 tests)

</details>

### v1.2 Global Localization (In Progress)

**Milestone Goal:** Expand W8Trackr to 8 additional languages (Chinese, French, German, Japanese, Portuguese, Italian, Korean, Russian) for global App Store reach.

**Phase Numbering:**
- Integer phases (27, 28): Planned milestone work
- Decimal phases (27.1, 27.2): Urgent insertions if needed

- [ ] **Phase 27: In-App Localization** - UI strings, widget strings, and formatting for all 8 languages
- [ ] **Phase 28: App Store Localization** - Metadata translations for all 8 languages

## Phase Details

### Phase 27: In-App Localization
**Goal:** Users in all 8 target locales see the app in their native language with correct formatting
**Depends on:** v1.1 complete (Spanish localization patterns established)
**Requirements:** ZH-01, ZH-02, ZH-03, FR-01, FR-02, FR-03, DE-01, DE-02, DE-03, JA-01, JA-02, JA-03, PT-01, PT-02, PT-03, IT-01, IT-02, IT-03, KO-01, KO-02, KO-03, RU-01, RU-02, RU-03
**Risk:** LOW - Pattern established in Phase 25, mechanical translation work
**Success Criteria** (what must be TRUE):
  1. All UI strings display correctly in Chinese, French, German, Japanese, Portuguese, Italian, Korean, and Russian when device language is set accordingly
  2. Widget strings display correctly in all 8 languages
  3. Numbers and dates format according to each locale's conventions (decimal separators, date order)
  4. Existing localization unit tests pass for all new locales
**Plans:** 3 plans
Plans:
- [ ] 27-01-PLAN.md - Main app UI string translations (8 languages)
- [ ] 27-02-PLAN.md - Widget string translations (8 languages)
- [ ] 27-03-PLAN.md - InfoPlist and Siri phrase translations (8 languages)

### Phase 28: App Store Localization
**Goal:** Users in all 8 target markets discover W8Trackr through localized App Store listings
**Depends on:** Phase 27 (in-app localization verified first)
**Requirements:** ZH-04, FR-04, DE-04, JA-04, PT-04, IT-04, KO-04, RU-04
**Risk:** LOW - Existing fastlane metadata structure, copy translation work
**Success Criteria** (what must be TRUE):
  1. App Store name displays correctly in all 8 languages
  2. App Store description available in all 8 languages
  3. Keywords optimized for each language's App Store search
  4. What's New text available in all 8 languages for v1.2 release
**Plans:** TBD during phase planning

## Progress

**Execution Order:**
Phases execute in numeric order: 27 -> 27.1 -> 27.2 -> 28 -> etc.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 27. In-App Localization | v1.2 | 0/3 | Planned | - |
| 28. App Store Localization | v1.2 | 0/? | Not Started | - |

---
*Roadmap created: 2026-01-22*
*Last updated: 2026-01-24 (Phase 27 plans created)*
