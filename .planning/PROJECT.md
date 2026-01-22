# W8Trackr

## What This Is

W8Trackr is an iOS weight tracking app with HealthKit sync, trend analysis, milestone celebrations, and iCloud backup. The app provides reliable weight tracking with smooth animations, full accessibility support, and a polished iOS 26 interface.

## Core Value

Users can reliably track their weight and see progress toward their goals with confidence-inspiring visualizations.

## Current State (v1.0 shipped)

**Version:** 1.0 (Build 6)
**Status:** Submitted for App Store review
**Codebase:** 15,861 lines Swift, iOS 26.0+, Swift 6.2+
**Architecture:** Pure SwiftUI with SwiftData, no ViewModels, @Observable managers

**Tech Stack:**
- SwiftUI with SwiftData persistence
- HealthKit export (write weight to Apple Health)
- iCloud sync via CloudKit
- EWMA trend analysis
- iOS 26 Liquid Glass tab bar

## Requirements

### Validated

- ✓ Weight entry logging with date/notes — existing
- ✓ HealthKit export (write weight to Apple Health) — existing
- ✓ Trend analysis with EWMA smoothing — existing
- ✓ Milestone celebrations at configurable intervals — v1.0
- ✓ Goal weight tracking with progress visualization — existing
- ✓ iCloud sync via SwiftData/CloudKit — existing
- ✓ Daily reminder notifications — existing
- ✓ CSV/JSON data export — existing
- ✓ Fix milestone popup appearing repeatedly — v1.0
- ✓ Fix chart animation jank on date segment change — v1.0
- ✓ Move Goal Reached banner to top of dashboard — v1.0
- ✓ Consolidate iCloud sync status to Settings section only — v1.0
- ✓ Remove/implement fatalError stub services — v1.0
- ✓ Add undo capability for Delete All Entries — v1.0
- ✓ Add light/dark mode support — v1.0
- ✓ Goal prediction card full width and better design — v1.0
- ✓ Current Weight card text readable on colored background — v1.0
- ✓ Current Weight card red/green based on trend direction — v1.0
- ✓ Chart segmented control shows months (1M, 3M, 6M) — v1.0
- ✓ FAB button right-aligned as trailing tab button — v1.0
- ✓ Extended prediction line (14 days) — v1.0
- ✓ Horizontal chart scrolling — v1.0
- ✓ Tap selection with value display — v1.0
- ✓ Month-segmented logbook entries — v1.0
- ✓ Enhanced logbook row display — v1.0
- ✓ Logbook filter menu — v1.0
- ✓ Logbook column headers and reduced cell height — v1.0
- ✓ Customizable milestone intervals — v1.0
- ✓ Text-based weight entry with date arrows — v1.0
- ✓ iOS 26 Liquid Glass tab bar accessory — v1.0
- ✓ Full WCAG 2.1 AA accessibility — v1.0
- ✓ App Store automation (fastlane, CI) — v1.0

### Active

**v1.1 Scope:**
- [ ] HealthKit import (read weight from Apple Health, Health wins on conflicts)
- [ ] Spanish localization
- [ ] Full test coverage (unit + UI tests)
- [ ] Fix HealthKit settings link destination
- [ ] Home screen widget (multiple sizes: weight+trend, progress, sparkline)
- [ ] Social sharing (export chart/stats as shareable image)

### Out of Scope

- watchOS app — post-launch consideration
- iPad optimization — post-launch consideration
- Milestone achievement sharing — v1.1 focuses on progress screenshots only

## Context

**Shipped v1.0** with 15,861 LOC Swift on 2026-01-22.

**App Store Status:** Build 6 submitted for review.

**Known Issues:** None critical. Minor tech debt documented in v1-MILESTONE-AUDIT.md.

**Pending Human Actions:**
- Publish privacy page at https://saults.io/w8trackr-privacy
- Publish support page at https://saults.io/w8trackr-support
- Complete age rating questionnaire in App Store Connect

## Constraints

- **Platform**: iOS 26.0+, Swift 6.2+
- **Architecture**: Pure SwiftUI with SwiftData, no ViewModels
- **Dependencies**: No third-party frameworks allowed
- **Concurrency**: Strict Swift concurrency only (no GCD, one exception for NWPathMonitor)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Bug fixes only for v1.0 milestone | Focus on stability for launch | ✓ Good |
| HealthKit import deferred to v1.1 | Export works, import adds complexity | ✓ Good |
| iOS 26 Liquid Glass tab bar | Modern platform integration | ✓ Good |
| Text-based weight entry over plus/minus buttons | Faster data entry UX | ✓ Good |
| Month-segmented logbook | Better organization for historical data | ✓ Good |
| Horizontal chart scrolling | Explore historical data naturally | ✓ Good |
| Hide streak UI for launch | Simplify initial experience | ✓ Good |
| WCAG 2.1 AA as launch requirement | Inclusive design from day one | ✓ Good |
| Automated accessibility tests | Prevent regressions | ✓ Good |

---
*Last updated: 2026-01-22 after v1.1 milestone started*
