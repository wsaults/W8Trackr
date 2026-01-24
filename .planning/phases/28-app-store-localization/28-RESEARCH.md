# Phase 28: App Store Localization - Research

**Researched:** 2026-01-24
**Domain:** App Store Connect metadata localization via fastlane deliver
**Confidence:** HIGH

## Summary

Phase 28 involves creating localized App Store metadata (name, subtitle, description, keywords, release notes) for 8 additional languages using the existing fastlane infrastructure. The project already has a working `fastlane/metadata/en-US/` folder structure and a `deliver` lane configured.

The approach is straightforward: create 8 new locale folders in `fastlane/metadata/` with translated `.txt` files. Fastlane's `deliver` action automatically reads these folders and uploads to App Store Connect. The key challenge is keyword optimization - direct translation of keywords is an anti-pattern; each locale needs market-specific keywords researched for actual search behavior.

**Primary recommendation:** Create locale folders with translated metadata files, keeping the app name "W8Trackr" consistent across all markets, and conduct minimal keyword research for each locale to ensure search relevance.

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| fastlane deliver | Latest | Upload metadata to App Store Connect | Already configured in project, industry standard |
| App Store Connect API | v2+ | Backend for metadata storage | Apple's official platform |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `fastlane deliver --skip_binary_upload` | Upload only metadata | Already configured in `release` lane |
| `fastlane deliver init` | Download existing metadata | One-time setup, already done |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| File-based metadata | Deliverfile Ruby DSL | File-based is simpler, already established |
| AI translation | Professional translators | AI acceptable per Phase 25 decision; can iterate on feedback |

## Architecture Patterns

### Required Folder Structure

```
fastlane/metadata/
├── copyright.txt              # Shared (not localized)
├── primary_category.txt       # Shared (not localized)
├── secondary_category.txt     # Shared (not localized)
├── review_information/        # Shared (not localized)
├── en-US/                     # Existing
│   ├── name.txt               # "W8Trackr" (8 chars)
│   ├── subtitle.txt           # "Simple Weight Tracking" (22 chars)
│   ├── description.txt        # Full description (687 chars)
│   ├── keywords.txt           # Comma-separated (89 chars)
│   ├── release_notes.txt      # What's New (503 chars)
│   ├── privacy_url.txt
│   └── support_url.txt
├── zh-Hans/                   # NEW - Chinese Simplified
│   ├── name.txt
│   ├── subtitle.txt
│   ├── description.txt
│   ├── keywords.txt
│   └── release_notes.txt
├── fr-FR/                     # NEW - French (France)
├── de-DE/                     # NEW - German
├── ja/                        # NEW - Japanese
├── pt-BR/                     # NEW - Portuguese (Brazil)
├── it/                        # NEW - Italian
├── ko/                        # NEW - Korean
└── ru/                        # NEW - Russian
```

### Locale Code Mapping

**CRITICAL:** Fastlane locale codes differ slightly from iOS String Catalog codes:

| Language | iOS String Catalog | Fastlane Metadata | Notes |
|----------|-------------------|-------------------|-------|
| Chinese (Simplified) | `zh-Hans` | `zh-Hans` | Same |
| French | `fr` | `fr-FR` | Fastlane requires region |
| German | `de` | `de-DE` | Fastlane requires region |
| Japanese | `ja` | `ja` | Same |
| Portuguese (Brazil) | `pt-BR` | `pt-BR` | Same |
| Italian | `it` | `it` | Same |
| Korean | `ko` | `ko` | Same |
| Russian | `ru` | `ru` | Same |

**Source:** fastlane docs - valid locale codes include: ar-SA, ca, cs, da, de-DE, el, en-AU, en-CA, en-GB, en-US, es-ES, es-MX, fi, fr-CA, fr-FR, he, hi, hr, hu, id, it, ja, ko, ms, nl-NL, no, pl, pt-BR, pt-PT, ro, ru, sk, sv, th, tr, uk, vi, zh-Hans, zh-Hant.

### Character Limits (App Store Connect)

| Field | Limit | English Content | Notes |
|-------|-------|-----------------|-------|
| App Name | 30 chars | "W8Trackr" (8) | Keep brand name unchanged |
| Subtitle | 30 chars | "Simple Weight Tracking" (22) | Must translate |
| Keywords | 100 chars | 89 chars used | Comma-separated, no spaces after commas |
| Description | 4,000 chars | 687 chars | Ample room for expansion |
| Release Notes | 4,000 chars | 503 chars | Ample room |
| Promotional Text | 170 chars | Not used | Optional |

### Files That DO NOT Need Localization

These files are shared across all locales:
- `copyright.txt` - Legal text, often kept in English
- `primary_category.txt` - Category codes, not text
- `secondary_category.txt` - Category codes
- `privacy_url.txt` - URL (may keep English page or create localized)
- `support_url.txt` - URL (may keep English page or create localized)
- `review_information/*` - Apple reviewer info, English only

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Metadata upload | Custom API client | `fastlane deliver` | Already integrated, handles auth, retries |
| Screenshot localization | Manual upload | `fastlane snapshot` with localized text | Phase 28 scope is metadata only |
| Keyword research | Guessing | Minimal research + AI translation | Phase 25 decision allows AI translations |

**Key insight:** Direct keyword translation is the #1 mistake in App Store localization. Users in different markets search with different terms - "weight tracker" in English might be searched as entirely different concepts in Asian markets.

## Common Pitfalls

### Pitfall 1: Direct Keyword Translation

**What goes wrong:** Translating English keywords literally produces terms nobody searches for
**Why it happens:** Assuming users in all markets search the same concepts
**How to avoid:** Research top-performing competitor apps in each market to understand local search terms
**Warning signs:** Keywords that sound awkward in the target language

### Pitfall 2: Wrong Locale Folder Names

**What goes wrong:** `fastlane deliver` fails with "invalid language" error
**Why it happens:** Using iOS locale codes (e.g., `fr`) instead of fastlane codes (e.g., `fr-FR`)
**How to avoid:** Use exact folder names from fastlane's supported list
**Warning signs:** Error during `fastlane release` execution

### Pitfall 3: Exceeding Character Limits

**What goes wrong:** App Store Connect rejects metadata
**Why it happens:** Translations often expand text (German ~30% longer than English)
**How to avoid:** Check character counts for each translated file
**Warning signs:** Subtitle >30 chars, keywords >100 chars

### Pitfall 4: Missing Files in Locale Folders

**What goes wrong:** Fastlane falls back to default or English, inconsistent user experience
**Why it happens:** Forgetting a file in one locale folder
**How to avoid:** Create all 5 required files for each locale: name.txt, subtitle.txt, description.txt, keywords.txt, release_notes.txt
**Warning signs:** Partial translations appearing in App Store

### Pitfall 5: Machine Translation Without Review

**What goes wrong:** Grammatically incorrect or culturally inappropriate text
**Why it happens:** Relying solely on AI translation without any verification
**How to avoid:** At minimum, verify key terms and app name handling
**Warning signs:** Brand name "W8Trackr" getting translated or mangled

## Code Examples

### Verify Locale Folder Structure

```bash
# Source: fastlane docs
# Check all required files exist in each locale folder
for locale in zh-Hans fr-FR de-DE ja pt-BR it ko ru; do
  echo "=== $locale ==="
  for file in name.txt subtitle.txt description.txt keywords.txt release_notes.txt; do
    if [ -f "fastlane/metadata/$locale/$file" ]; then
      chars=$(wc -c < "fastlane/metadata/$locale/$file" | tr -d ' ')
      echo "  $file: $chars chars"
    else
      echo "  $file: MISSING"
    fi
  done
done
```

### Upload Metadata Only (No Binary)

```bash
# Source: Project's existing Fastfile
# The release lane already configured for metadata-only upload
bundle exec fastlane release
```

### Validate Character Limits

```bash
# Verify subtitle is under 30 characters for each locale
for locale in zh-Hans fr-FR de-DE ja pt-BR it ko ru; do
  chars=$(wc -c < "fastlane/metadata/$locale/subtitle.txt" | tr -d ' ')
  if [ $chars -gt 30 ]; then
    echo "WARNING: $locale subtitle is $chars chars (max 30)"
  fi
done

# Verify keywords under 100 characters
for locale in zh-Hans fr-FR de-DE ja pt-BR it ko ru; do
  chars=$(wc -c < "fastlane/metadata/$locale/keywords.txt" | tr -d ' ')
  if [ $chars -gt 100 ]; then
    echo "WARNING: $locale keywords is $chars chars (max 100)"
  fi
done
```

### Example Metadata File Content

```
# name.txt - Keep consistent across all locales
W8Trackr

# subtitle.txt (French example, formal tone)
Suivi de Poids Simple

# keywords.txt (French example - localized search terms)
suivi poids,journal santé,progression fitness,mesures corps,journal régime

# description.txt structure (French example)
Suivez votre poids avec W8Trackr - la méthode simple et privée pour surveiller votre parcours santé.

JOURNALISATION SIMPLE
• Saisie rapide du poids en quelques touches
• Suivi optionnel du pourcentage de graisse corporelle
• Ajoutez des notes pour mémoriser le contexte

[... continue with feature sections ...]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual App Store Connect edits | fastlane deliver automation | 2016+ | Consistent, version-controlled metadata |
| Same keywords all markets | Localized keyword research | Industry standard | Better discoverability |
| Hire translators for v1 | AI translation + iterate | 2024+ | Faster time-to-market, acceptable quality |

**Deprecated/outdated:**
- Deliverfile Ruby DSL for metadata: Still works but file-based approach is simpler
- `cmn-Hans` locale code: Old code, use `zh-Hans`

## Open Questions

### 1. Keyword Strategy Depth

- **What we know:** Direct translation is an anti-pattern; local keyword research is ideal
- **What's unclear:** How much keyword research is acceptable for AI translation approach
- **Recommendation:** Minimal research - check top 3 competitor apps per market, note commonly used terms, then AI translate with those as guidance. Full ASO optimization can be Phase 28.1 if needed.

### 2. Screenshots Localization

- **What we know:** Screenshots in `fastlane/screenshots/en-US/` exist
- **What's unclear:** Whether Phase 28 should include localized screenshots
- **Recommendation:** OUT OF SCOPE for Phase 28 per phase description (metadata only). Text in screenshots is already localized via iOS localization from Phase 27.

### 3. URLs Localization

- **What we know:** `privacy_url.txt` and `support_url.txt` exist in en-US
- **What's unclear:** Whether to create localized privacy/support pages
- **Recommendation:** Keep same URLs across all locales (English pages). Localized web pages can be future work if needed.

## Sources

### Primary (HIGH confidence)
- `/fastlane/docs` Context7 - deliver action, metadata folder structure, locale codes
- [Apple App Store Localizations Reference](https://developer.apple.com/help/app-store-connect/reference/app-store-localizations/) - Official locale list
- [Fastlane Deliver Documentation](https://docs.fastlane.tools/actions/deliver/) - File structure, character limits

### Secondary (MEDIUM confidence)
- [App Store Metadata Character Limits](https://developer.apple.com/app-store/product-page/) - 30/30/100/4000 limits verified
- [AppTweak ASO Guide](https://www.apptweak.com/en/aso-blog/guide-to-app-store-localization) - Keyword localization best practices

### Tertiary (LOW confidence)
- WebSearch results on keyword translation approaches - General guidance, varies by market

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - fastlane deliver is already configured and documented
- Architecture: HIGH - Folder structure is well-documented in fastlane docs
- Locale mapping: HIGH - Verified against fastlane's supported language list
- Pitfalls: MEDIUM - Based on documented common issues and industry practices

**Research date:** 2026-01-24
**Valid until:** 2026-02-24 (30 days - stable domain)

---

## Appendix: English Source Content

For reference, here is the current English content to be translated:

### name.txt (8 characters)
```
W8Trackr
```

### subtitle.txt (22 characters)
```
Simple Weight Tracking
```

### description.txt (687 characters)
```
Track your weight with W8Trackr - the simple, private way to monitor your health journey.

SIMPLE LOGGING
• Quick weight entry with just a few taps
• Optional body fat percentage tracking
• Add notes to remember context

SMART TRENDS
• Visualize your progress with beautiful charts
• Smoothed trend lines show your true direction
• Filter by week, month, or all time

FLEXIBLE UNITS
• Switch between pounds and kilograms
• Automatic conversion preserves precision

PRIVATE BY DESIGN
• All data stays on your device
• No account required
• No ads, no tracking

Whether you're working toward a goal or simply staying aware, W8Trackr makes weight tracking effortless.
```

### keywords.txt (89 characters)
```
weight tracking,health journal,fitness progress,body measurements,diet log,scale tracker
```

### release_notes.txt (v1.1 - 503 characters)
```
What's New in v1.1:

• Home Screen Widgets - Track your progress at a glance with small, medium, and large widgets
• HealthKit Import - Sync your existing weight data from Apple Health with automatic background updates
• Share Your Milestones - Celebrate your progress by sharing milestone achievements
• Spanish Localization - Full support for Spanish speakers
• Improved Milestone Tracking - More accurate progress calculations
• Bug Fixes - Various stability and performance improvements
```

**Note:** Release notes will need updating for v1.2 to reflect the 8-language localization as the key feature.
