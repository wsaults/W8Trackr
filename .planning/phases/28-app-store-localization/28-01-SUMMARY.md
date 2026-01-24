---
phase: 28-app-store-localization
plan: 01
subsystem: localization
tags: [app-store, fastlane, metadata, i18n, chinese, french, german, japanese]

# Dependency graph
requires:
  - phase: 27-in-app-localization
    provides: "Translation patterns and language selection"
provides:
  - App Store metadata for 4 locales (zh-Hans, fr-FR, de-DE, ja)
  - fastlane deliver compatible folder structure
  - 20 metadata files ready for upload
affects: [28-02, app-store-connect]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "fastlane metadata locale folder structure"
    - "Brand name preservation across translations"

key-files:
  created:
    - fastlane/metadata/zh-Hans/name.txt
    - fastlane/metadata/zh-Hans/subtitle.txt
    - fastlane/metadata/zh-Hans/description.txt
    - fastlane/metadata/zh-Hans/keywords.txt
    - fastlane/metadata/zh-Hans/release_notes.txt
    - fastlane/metadata/fr-FR/name.txt
    - fastlane/metadata/fr-FR/subtitle.txt
    - fastlane/metadata/fr-FR/description.txt
    - fastlane/metadata/fr-FR/keywords.txt
    - fastlane/metadata/fr-FR/release_notes.txt
    - fastlane/metadata/de-DE/name.txt
    - fastlane/metadata/de-DE/subtitle.txt
    - fastlane/metadata/de-DE/description.txt
    - fastlane/metadata/de-DE/keywords.txt
    - fastlane/metadata/de-DE/release_notes.txt
    - fastlane/metadata/ja/name.txt
    - fastlane/metadata/ja/subtitle.txt
    - fastlane/metadata/ja/description.txt
    - fastlane/metadata/ja/keywords.txt
    - fastlane/metadata/ja/release_notes.txt
  modified: []

key-decisions:
  - "Locale-specific keywords over direct translations for better App Store search"
  - "Formal register in all languages (vous/Sie/desu-masu)"
  - "W8Trackr brand name preserved unchanged in all locales"

patterns-established:
  - "fastlane metadata: one folder per locale with 5 standard files"
  - "Keywords: locale-appropriate search terms, comma-separated, no trailing spaces"

# Metrics
duration: 2min
completed: 2026-01-24
---

# Phase 28 Plan 01: App Store Metadata Translations Summary

**App Store metadata for Chinese, French, German, and Japanese markets with locale-appropriate keywords and formal tone**

## Performance

- **Duration:** 2 min
- **Started:** 2026-01-24T17:50:16Z
- **Completed:** 2026-01-24T17:52:08Z
- **Tasks:** 3
- **Files created:** 20

## Accomplishments
- Created 4 locale folders matching fastlane deliver requirements
- Translated all 5 metadata files per locale (name, subtitle, description, keywords, release_notes)
- Used locale-appropriate search terms for keywords (not direct translations)
- Maintained formal/polite register in all languages
- All character limits respected (subtitle <= 30, keywords <= 100)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Chinese (Simplified) metadata** - `1ee8492` (feat)
2. **Task 2: Create French and German metadata** - `d8217b3` (feat)
3. **Task 3: Create Japanese metadata** - `355c63c` (feat)

## Files Created

### Chinese (Simplified) - zh-Hans
- `fastlane/metadata/zh-Hans/name.txt` - W8Trackr (unchanged)
- `fastlane/metadata/zh-Hans/subtitle.txt` - 简单体重记录 (19 chars)
- `fastlane/metadata/zh-Hans/description.txt` - Full translation (643 chars)
- `fastlane/metadata/zh-Hans/keywords.txt` - 体重记录,减肥,健康管理... (74 chars)
- `fastlane/metadata/zh-Hans/release_notes.txt` - v1.2 localization notes (295 chars)

### French - fr-FR
- `fastlane/metadata/fr-FR/name.txt` - W8Trackr (unchanged)
- `fastlane/metadata/fr-FR/subtitle.txt` - Suivi de poids simple (22 chars)
- `fastlane/metadata/fr-FR/description.txt` - Full translation with vous form (838 chars)
- `fastlane/metadata/fr-FR/keywords.txt` - suivi poids,journal sante... (74 chars)
- `fastlane/metadata/fr-FR/release_notes.txt` - v1.2 localization notes (376 chars)

### German - de-DE
- `fastlane/metadata/de-DE/name.txt` - W8Trackr (unchanged)
- `fastlane/metadata/de-DE/subtitle.txt` - Einfache Gewichtskontrolle (27 chars)
- `fastlane/metadata/de-DE/description.txt` - Full translation with Sie form (829 chars)
- `fastlane/metadata/de-DE/keywords.txt` - Gewicht,Waage,Gesundheit... (76 chars)
- `fastlane/metadata/de-DE/release_notes.txt` - v1.2 localization notes (378 chars)

### Japanese - ja
- `fastlane/metadata/ja/name.txt` - W8Trackr (unchanged)
- `fastlane/metadata/ja/subtitle.txt` - シンプルな体重記録 (28 chars)
- `fastlane/metadata/ja/description.txt` - Full translation with desu/masu form (832 chars)
- `fastlane/metadata/ja/keywords.txt` - 体重,ダイエット,健康管理... (95 chars)
- `fastlane/metadata/ja/release_notes.txt` - v1.2 localization notes (402 chars)

## Decisions Made
- **Locale-specific keywords:** Used terms users actually search in each market rather than translating English keywords
- **Formal register:** All translations use formal/polite forms (vous, Sie, desu/masu) for professional App Store presence
- **Brand preservation:** W8Trackr kept in roman characters across all locales for brand recognition

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - files are ready for fastlane deliver upload.

## Next Phase Readiness
- 4 locales complete and ready for App Store Connect upload via fastlane
- Plan 28-02 will add remaining 4 locales (ko, pt-BR, ru, es-ES)
- All files follow identical structure for consistency

---
*Phase: 28-app-store-localization*
*Completed: 2026-01-24*
