# Features Research: v1.1

**Domain:** iOS weight tracking app feature expansion
**Researched:** 2026-01-22
**Overall confidence:** HIGH (verified against Apple documentation, existing codebase, and industry patterns)

---

## HealthKit Import

Reading weight data FROM Apple Health (reverse of existing export functionality).

### Table Stakes

Features users expect from any weight app with HealthKit import:

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Read body mass samples | Core feature - smart scales write to Health | Medium | `HKSampleQuery` with `.bodyMass` type |
| Respect source priority | Health app already manages source hierarchy | Low | Use `HKStatisticsQuery` for automatic de-duplication |
| Display data source | Users want to know where data came from | Low | `WeightEntry.source` field already exists |
| Conflict resolution (Health wins) | User expectation for authoritative health data | Medium | Per milestone context: Health is source of truth |
| Initial sync on enable | Import existing history when feature enabled | Medium | One-time backfill of historical data |
| Background updates | Smart scale data appears without opening app | High | Requires `HKObserverQuery` + background delivery |
| Selective import | Don't import duplicates or W8Trackr's own exports | Medium | Match on date/value or use `HKMetadataKeySyncIdentifier` |

### Differentiators

Features that would make W8Trackr's HealthKit import stand out:

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Smart merge UI | Visual diff showing imported vs local entries | Medium | Show conflicts before auto-resolving |
| Source filtering | Let users choose which sources to import | Low | e.g., "Only import from Withings Scale" |
| Trend preservation | Maintain EWMA smoothing across import | Low | Existing `TrendCalculator` handles mixed sources |
| Retroactive body fat import | Import body fat % alongside weight | Low | Model already supports `bodyFatPercentage` |
| Import notification | Toast/alert when background import occurs | Low | Good UX, informs user of data changes |

### Anti-features

Things to explicitly NOT build:

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Automatic overwrite of local data | Users may have notes/context on manual entries | Health wins on conflict, but preserve notes |
| Full two-way sync loop | Creates complexity, potential for infinite loops | Import only; export remains one-way on save |
| Duplicate entry creation | Common HealthKit pitfall, confuses users | Use `HKStatisticsQuery` de-duplication or date matching |
| Import without explicit user action | Privacy concern, unexpected behavior | Require toggle enable + confirmation |
| Real-time sync indicator | Distracting, battery drain | Sync silently, show status only on error |

### Implementation Notes

**Existing infrastructure (from codebase analysis):**
- `HealthKitManager` has `healthStore` ready for read operations
- `WeightEntry` model has `source`, `healthKitUUID`, `syncVersion` fields
- `com.apple.developer.healthkit.background-delivery` entitlement already enabled
- `HealthSyncManager` exists (partial implementation)

**Key technical decisions:**
- Use `HKStatisticsQuery` instead of `HKSampleQuery` to get auto-deduplicated data
- For conflict resolution: compare `date` and `weightValue` - if match within threshold, skip import
- Use `HKMetadataKeySyncIdentifier` (iOS 11+) for robust duplicate prevention
- Background delivery frequency: `.hourly` is sufficient for weight data (not real-time)

**Sources:**
- [HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [HKObserverQuery](https://developer.apple.com/documentation/healthkit/hkobserverquery)
- [HealthKit Pitfalls](https://medium.com/mobilepeople/mastering-healthkit-common-pitfalls-and-solutions-b4f46729f28e)

---

## Widgets

Home screen widgets showing weight, trend, and progress.

### Table Stakes

Features users expect from any fitness tracking widget:

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Small widget (weight + trend arrow) | Glanceable current status | Medium | Show current weight, up/down/stable indicator |
| Tap to open app | Standard widget behavior | Low | Deep link to main view |
| Placeholder for no data | Widget gallery must show something | Low | Show sample data or "Start tracking" |
| Refresh on app data change | Widget shows stale data otherwise | Low | `WidgetCenter.shared.reloadTimelines()` on entry save |
| Support system appearance | Light/dark mode | Low | Use system colors, existing `AppTheme` |

### Differentiators

Features that would make W8Trackr widgets stand out:

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Medium widget (progress to goal) | Visual progress bar + milestone indicator | Medium | Show % to goal, next milestone |
| Large widget (sparkline chart) | 7-day trend visualization at a glance | High | Mini chart using existing `WeightTrendChartView` logic |
| Lock screen widgets | Quick glance without unlock | Low | Same data, smaller format |
| iOS 26 resize support | Users can change size without re-adding | Low | Use `.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])` |
| Goal reached celebration state | Special appearance when goal achieved | Low | Different styling/message when `distanceToGoal <= 0` |

### Anti-features

Things to explicitly NOT build:

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Interactive weight entry in widget | WidgetKit limitations, poor UX for numeric input | Tap widget to open entry view |
| Frequent timeline refresh | Battery drain, system throttles anyway | Use `.never` policy + app-triggered reloads |
| Complex animations | Widgets are static snapshots | Use static trend indicators |
| Multiple widget configurations | Complexity for v1.1 | Single static widget per size |
| Showing exact weight on lock screen | Privacy concern | Show trend only, or make configurable |

### Implementation Notes

**Existing infrastructure (from codebase analysis):**
- Contracts exist in `specs/004-ios-widget/contracts/`:
  - `WeightWidgetProvider.swift` - timeline provider skeleton
  - `SharedModelContainer.swift` - App Group configuration
  - `DeepLinkHandler.swift` - deep link handling
- `TrendCalculator` can be reused for trend direction
- App Group identifier defined: `group.com.yourcompany.W8Trackr`

**Key technical decisions:**
- App Group required for SwiftData access from widget extension
- Timeline policy: `.never` with explicit `reloadTimelines(ofKind:)` on data changes
- Fallback refresh: 4 hours (as per existing contract)
- Shared code via framework or file inclusion in widget target

**Widget sizing (per Apple HIG):**
- Small: 169x169pt - weight value + trend arrow
- Medium: 360x169pt - weight + progress bar + stats
- Large: 360x379pt - weight + sparkline + weekly summary

**Sources:**
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Keeping a Widget Up to Date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)
- [Widget Design Guidelines](https://developer.apple.com/design/human-interface-guidelines/widgets)

---

## Social Sharing

Export progress/milestones as shareable images.

### Table Stakes

Features users expect from fitness app sharing:

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Share milestone achievements | Standard in fitness apps (Nike Run Club, Apple Fitness) | Medium | When milestone reached, offer share option |
| Share as image (not data) | Privacy-safe, works on any platform | Medium | `ImageRenderer` + `ShareLink` |
| System share sheet | Native iOS experience | Low | `UIActivityViewController` via `ShareLink` |
| App branding on image | Attribution, marketing | Low | W8Trackr logo/watermark on generated image |
| Option to hide exact weights | Privacy control | Low | Show "% progress" instead of "175 lbs" |

### Differentiators

Features that would make W8Trackr sharing stand out:

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Multiple share templates | Different designs for different contexts | Medium | Milestone achievement vs progress summary |
| Social media optimized sizes | Images render correctly on Twitter/Instagram | Low | 1200x675 (Twitter), 1080x1080 (Instagram) |
| Share from milestone celebration | Contextual timing when user is excited | Low | Add share button to `MilestoneCelebrationView` |
| Progress snapshot with trend | Show journey, not just current state | Medium | Include mini sparkline in image |
| Copy to clipboard option | Quick paste into any app | Low | Alternative to full share sheet |

### Anti-features

Things to explicitly NOT build:

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Direct social media integration | APIs deprecated, maintenance burden | Use system share sheet |
| Automatic sharing | Privacy violation, user must opt-in | Always require explicit tap |
| Share raw data/CSV | Not useful for social, privacy concern | Image only for social; CSV export exists separately |
| In-app social feed | Scope creep, not core value prop | Keep sharing outbound-only |
| Location tagging | Unnecessary, privacy concern | Omit location metadata |

### Implementation Notes

**Existing infrastructure (from codebase analysis):**
- Contracts exist in `specs/003-social-sharing/contracts/`:
  - `ProgressImageRenderer.swift` - image generation skeleton
  - `ShareContentGenerator.swift` - content formatting skeleton
- `MilestoneCelebrationView` exists - add share button
- `ImageRenderer` requires iOS 16+ (app targets iOS 26)
- Existing `MilestoneType` enum for categorizing achievements

**Key technical decisions:**
- Image size: 600x315pt at device scale (1.91:1 ratio for social media)
- Use `@MainActor` for `ImageRenderer` operations
- `ShareLink` for SwiftUI-native sharing
- Privacy default: hide exact weights, show percentages

**Share content types:**
1. Milestone achievement: "25% of my goal!", progress ring, milestone icon
2. Progress summary: weight change, duration, trend visualization

**Sources:**
- [ImageRenderer Documentation](https://developer.apple.com/documentation/swiftui/imagerenderer)
- [Using ImageRenderer](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image)
- [Apple Fitness Sharing](https://support.apple.com/guide/iphone/share-your-activity-iph0b826155d/ios)

---

## Localization

Spanish language support as first non-English locale.

### Table Stakes

Features required for proper localization:

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| All UI strings localized | Core requirement | High | Every user-facing string needs extraction |
| Number formatting respects locale | "1,234.5" vs "1.234,5" | Low | Already using SwiftUI formatters |
| Date formatting respects locale | Month/day order varies | Low | Already using SwiftUI date formatters |
| Pluralization rules | "1 day" vs "2 days" | Medium | Use `.stringsdict` for Spanish plural rules |
| Unit labels localized | "lbs" vs "libras" | Low | May keep as-is (lb/kg are universal) |

### Differentiators

Features that would make localization stand out:

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| App Intents/Siri in Spanish | Voice control in native language | Medium | Requires `LocalizedStringResource` |
| Widget text localized | Consistent experience | Low | Same strings infrastructure |
| Milestone messages localized | Celebration feels native | Low | Part of string extraction |
| In-app language override | Users may want English UI regardless of device | Medium | Nice-to-have, not table stakes |

### Anti-features

Things to explicitly NOT build:

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Machine translation | Quality issues, brand risk | Use professional translation |
| Multiple Spanish variants (es-MX, es-ES) | Complexity for v1.1 | Single Spanish (es) for broad coverage |
| RTL support | Spanish is LTR, not needed for this milestone | Defer to future if Arabic/Hebrew added |
| Localized screenshots | App Store Connect auto-generates | Focus on metadata localization |

### Spanish-Specific Notes

**Language considerations:**
- Spanish has two grammatical genders - avoid gendered terms where possible
- Formal "usted" vs informal "tu" - app should use informal for fitness context
- Numbers: Spain uses "1.234,5" but Latin America uses "1,234.5" - defer to system locale
- Weight unit abbreviations (lb, kg) are universal, no translation needed

**String extraction scope (from codebase analysis):**
- Dashboard: "Current Weight", "Weekly Change", "Goal Prediction", "lbs to go"
- Settings: All section headers, toggle labels, button text
- Onboarding: All step titles and descriptions
- Milestones: Achievement messages ("25% of the way!", etc.)
- Alerts: Delete confirmations, error messages
- Siri phrases: "Log my weight", "What's my weight trend"

**Estimated string count:** 100-150 unique strings

**Sources:**
- [Apple Localization Guide](https://developer.apple.com/localization/)
- [iOS Localization with Swift](https://phrase.com/blog/posts/ios-tutorial-internationalization-localization/)
- [Pluralization Rules](https://developer.apple.com/videos/play/wwdc2022/10110/)

---

## Feature Dependencies

How new v1.1 features depend on existing v1.0 capabilities:

```
Existing v1.0                    New v1.1
-----------                      --------

WeightEntry model  ───────────>  HealthKit Import (uses source, healthKitUUID fields)
     │
     └──────────────────────────> Widgets (reads weight data via App Group)

HealthKitManager   ───────────>  HealthKit Import (extends with read operations)

TrendCalculator    ───────────>  Widgets (trend direction)
                   ───────────>  Social Sharing (sparkline in image)

MilestoneCelebrationView  ─────> Social Sharing (add share button)

AppTheme/Colors    ───────────>  Widgets (consistent styling)
                   ───────────>  Social Sharing (branded images)

SwiftData container ──────────>  Widgets (requires App Group migration)

All UI Strings     ───────────>  Localization (extraction required)
```

### Dependency Order Recommendation

Based on dependencies, suggested implementation order:

1. **Localization infrastructure** - String extraction affects all features; do early
2. **Widgets** - Requires App Group setup, which HealthKit Import can reuse
3. **HealthKit Import** - Builds on widget's shared container infrastructure
4. **Social Sharing** - Most isolated, fewest dependencies

### Shared Infrastructure Needs

| Component | Used By | Notes |
|-----------|---------|-------|
| App Group container | Widgets, HealthKit Import | Set up once, share database |
| Shared UserDefaults | Widgets | For preferences (unit, goal) |
| String localization | All features | Extract early, translate once |
| `TrendCalculator` | Widgets, Sharing | Already exists, just reuse |

---

## Complexity Summary

| Feature | Overall Complexity | Rationale |
|---------|-------------------|-----------|
| HealthKit Import | **High** | Background delivery, conflict resolution, sync state management |
| Widgets | **Medium** | App Group setup, new target, but well-documented pattern |
| Social Sharing | **Medium** | Image generation is straightforward, templates need design |
| Localization | **Medium** | High volume of strings, but mechanical extraction process |

---

## Sources

### Apple Documentation
- [HealthKit Framework](https://developer.apple.com/documentation/healthkit)
- [WidgetKit Framework](https://developer.apple.com/documentation/widgetkit)
- [ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer)
- [Localization Guide](https://developer.apple.com/localization/)

### Technical Articles
- [HealthKit Pitfalls and Solutions](https://medium.com/mobilepeople/mastering-healthkit-common-pitfalls-and-solutions-b4f46729f28e)
- [HealthKit Background Delivery](https://medium.com/@shemona/challenges-with-hkobserverquery-and-background-app-refresh-for-healthkit-data-handling-8f84a4617499)
- [Widget Refresh Best Practices](https://swiftsenpai.com/development/refreshing-widget/)
- [iOS Localization Tutorial](https://phrase.com/blog/posts/ios-tutorial-internationalization-localization/)

### Codebase Analysis
- Existing `HealthKitManager.swift` - export-only implementation
- Existing `WeightEntry.swift` - model with sync fields
- Existing `specs/` contracts - widget and sharing scaffolds
- Existing `.planning/` documentation
