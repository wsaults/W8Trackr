# Requirements: W8Trackr v1.1

**Defined:** 2026-01-22
**Core Value:** Users can reliably track weight and see progress with confidence-inspiring visualizations

## v1.1 Requirements

Requirements for v1.1 release. Each maps to roadmap phases.

### Infrastructure

- [x] **INFRA-01**: App configures App Group entitlement for widget data sharing
- [x] **INFRA-02**: Existing users' SwiftData migrates to shared container without data loss
- [x] **INFRA-03**: HealthKit settings link navigates to correct destination

### HealthKit Import

- [x] **HKIT-01**: User can grant HealthKit read permission for weight data
- [x] **HKIT-02**: App imports all weight samples from Apple Health
- [x] **HKIT-03**: Weight entries display source indicator (manual vs Health)
- [x] **HKIT-04**: Initial sync completes on first permission grant
- [x] **HKIT-05**: App syncs automatically when Health data changes (background)

### Widgets

- [x] **WDGT-01**: Small widget displays current weight with trend arrow
- [x] **WDGT-02**: Medium widget displays progress toward goal weight
- [x] **WDGT-03**: Large widget displays sparkline chart of recent entries
- [x] **WDGT-04**: Widgets refresh when app data changes
- [x] **WDGT-05**: Tapping widget opens W8Trackr app

### Social Sharing

- [x] **SHAR-01**: User can generate shareable progress image
- [x] **SHAR-02**: User can share via system share sheet
- [x] **SHAR-03**: User can hide exact weight values in shared image (privacy)

### Localization

- [x] **LOCL-01**: All UI strings display correctly in Spanish
- [x] **LOCL-02**: Numbers and dates format according to locale
- [x] **LOCL-03**: App Store metadata available in Spanish

### Testing

- [x] **TEST-01**: Unit tests cover weight data CRUD operations
- [x] **TEST-02**: Unit tests cover HealthKit sync logic
- [x] **TEST-03**: Unit tests cover trend/EWMA calculations
- [x] **TEST-04**: UI tests verify weight entry flow — REMOVED per Phase 25-03
- [x] **TEST-05**: UI tests verify settings flow — REMOVED per Phase 25-03
- [x] **TEST-06**: Mock HealthKit available for isolated testing

## Future Requirements

Deferred to later milestone. Tracked but not in v1.1 roadmap.

### Widgets

- **WDGT-06**: Lock screen widget (accessoryCircular)
- **WDGT-07**: Interactive widget actions (quick log)

### Social Sharing

- **SHAR-04**: Multiple share image templates
- **SHAR-05**: W8Trackr branded watermark on shared images

### HealthKit

- **HKIT-06**: Smart de-duplication (same weight + timestamp = one entry)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Milestone achievement sharing | v1.1 focuses on progress screenshots only |
| watchOS app | Post-launch consideration |
| iPad optimization | Post-launch consideration |
| Conflict resolution (Health overwrites) | User chose "always import" — both sources coexist |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | Phase 21 | Complete |
| INFRA-02 | Phase 21 | Complete |
| INFRA-03 | Phase 21 | Complete |
| HKIT-01 | Phase 23 | Complete |
| HKIT-02 | Phase 23 | Complete |
| HKIT-03 | Phase 23 | Complete |
| HKIT-04 | Phase 23 | Complete |
| HKIT-05 | Phase 23 | Complete |
| WDGT-01 | Phase 22 | Complete |
| WDGT-02 | Phase 22 | Complete |
| WDGT-03 | Phase 22 | Complete |
| WDGT-04 | Phase 22 | Complete |
| WDGT-05 | Phase 22 | Complete |
| SHAR-01 | Phase 24 | Complete |
| SHAR-02 | Phase 24 | Complete |
| SHAR-03 | Phase 24 | Complete |
| LOCL-01 | Phase 25 | Complete |
| LOCL-02 | Phase 25 | Complete |
| LOCL-03 | Phase 25 | Complete |
| TEST-01 | Phase 26 | Complete |
| TEST-02 | Phase 26 | Complete |
| TEST-03 | Phase 26 | Complete |
| TEST-04 | Phase 26 | N/A (Removed) |
| TEST-05 | Phase 26 | N/A (Removed) |
| TEST-06 | Phase 26 | Complete |

**Coverage:**
- v1.1 requirements: 25 total
- Mapped to phases: 25
- Unmapped: 0
- Complete: 23 (INFRA: 3, WDGT: 5, HKIT: 5, SHAR: 3, LOCL: 3, TEST: 4)
- N/A: 2 (TEST-04, TEST-05 removed per Phase 25-03)

---
*Requirements defined: 2026-01-22*
*Last updated: 2026-01-23 (v1.1 milestone complete)*
