# Pitfalls Research: v1.1

**Project:** W8Trackr
**Researched:** 2026-01-22
**Features:** HealthKit Import, WidgetKit, Social Sharing, Localization, Test Coverage

---

## HealthKit Import Pitfalls

The app already has HealthKit export working. Adding import (reading weight data) introduces new complexity, especially with the "Health wins on conflicts" requirement.

### HK-1: Authorization Asymmetry

**Risk:** HealthKit authorization is asymmetric - you can check write authorization status but NOT read authorization status. `authorizationStatus(for:)` only tells you about write permissions. For read permissions, iOS always returns `.notDetermined` for privacy reasons.

**Warning Signs:**
- Code that checks `authorizationStatus` before reading and expects accurate results
- UI that shows "HealthKit authorized" when only write access is granted
- Tests that mock authorization status for read operations

**Prevention:**
- Always attempt the read operation and handle empty results gracefully
- Design UI to say "may not have access" rather than definitively "has access"
- Request both read AND write permissions together (already done in `HealthSyncManager`)
- Use `HKAnchoredObjectQuery` which returns results or empty gracefully

**Phase:** HealthKit Import implementation

**Confidence:** HIGH (verified with Apple documentation)

---

### HK-2: Duplicate Entry Creation

**Risk:** When importing from HealthKit, entries from multiple sources (Apple Watch, iPhone, third-party scales) may have the same timestamp. The current `WeightEntry` model doesn't have a unique constraint (CloudKit compatible), so duplicate imports will create duplicate entries.

**Warning Signs:**
- Multiple entries appearing for the same date/time after import
- Weight history suddenly having 2x or 3x entries
- Chart showing erratic data after HealthKit sync

**Prevention:**
- Use `HKSample.uuid` as `healthKitUUID` to track which HealthKit samples are already imported
- Before creating a new `WeightEntry`, query existing entries for matching `healthKitUUID`
- Consider date-based deduplication: only one entry per calendar day (user choice)
- Use `HKStatisticsQuery` for aggregated data if exact samples aren't needed

**Phase:** HealthKit Import implementation

**Confidence:** HIGH (based on existing codebase design and HealthKit behavior)

---

### HK-3: Conflict Resolution Complexity

**Risk:** The requirement states "Health wins on conflicts" but this is ambiguous. What happens when:
- A W8Trackr entry exists for 8:00 AM, and HealthKit has an entry for 8:15 AM same day?
- User edits a W8Trackr entry that was originally imported from HealthKit?
- HealthKit has a deletion for a sample that was imported into W8Trackr?

**Warning Signs:**
- User complaints about "losing" their manual entries
- Data appearing to randomly change after sync
- Inability to edit imported entries

**Prevention:**
- Define clear conflict rules BEFORE implementation:
  - Same `healthKitUUID`: HealthKit value overwrites local
  - Same timestamp (within tolerance): HealthKit value takes precedence
  - Different timestamps: Both entries coexist
- Track `source` field to distinguish imported vs manual entries
- Consider making imported entries read-only or flagged in UI
- Store original imported values separately for audit trail

**Phase:** HealthKit Import specification (before implementation)

**Confidence:** MEDIUM (project-specific decision needed)

---

### HK-4: Timestamp and Timezone Issues

**Risk:** HealthKit stores dates in UTC. If user travels across timezones or if scale apps have timezone bugs, imported entries may appear on wrong days.

**Warning Signs:**
- Entries showing up on "wrong" day (yesterday instead of today)
- Duplicate entries when crossing midnight in different timezones
- Entries disappearing from "today" view

**Prevention:**
- Store both the HealthKit UTC timestamp AND a "display date" based on user's current calendar
- Use `Calendar.current` for display grouping, not raw Date comparisons
- Test with timezone changes in simulator
- Handle "future-dated" entries gracefully (HealthKit can reject these)

**Phase:** HealthKit Import implementation

**Confidence:** HIGH (documented HealthKit behavior)

---

### HK-5: Anchored Query Pagination Crash

**Risk:** If user has years of HealthKit data, fetching all at once via `HKAnchoredObjectQuery` without proper limits can crash the app. The query parameter becomes too long, overwhelming HealthKit.

**Warning Signs:**
- Crashes on first sync for users with long HealthKit history
- Memory warnings during initial import
- Import never completing

**Prevention:**
- Set appropriate `limit` parameter on `HKAnchoredObjectQuery` (e.g., 100 or 500)
- Persist and restore anchor between sessions (already have `healthSyncAnchor` in `HealthSyncManager`)
- Process results in chunks with `@MainActor` yields for UI responsiveness
- Provide progress indicator for initial sync

**Phase:** HealthKit Import implementation

**Confidence:** HIGH (documented pitfall)

---

### HK-6: CloudKit + HealthKit Sync Race Condition

**Risk:** The app syncs SwiftData to CloudKit. If HealthKit import creates entries while CloudKit is syncing, or if the same user on two devices imports from HealthKit simultaneously, data can conflict or duplicate.

**Warning Signs:**
- Same HealthKit entry appearing multiple times after CloudKit sync
- Entries "fighting" between devices (appearing, disappearing)
- `syncVersion` continuously incrementing

**Prevention:**
- Import HealthKit data with deterministic identifiers (`healthKitUUID`)
- Ensure `healthKitUUID` is synced via CloudKit so both devices know what's imported
- Consider single-device-authoritative import (only most recently active device imports)
- Use `syncVersion` for CloudKit merge policy (higher wins)

**Phase:** HealthKit Import + CloudKit integration testing

**Confidence:** MEDIUM (requires testing with real CloudKit sync)

---

## Widget Pitfalls

First widget for the app. SwiftData + App Group + CloudKit adds complexity.

### WK-1: App Group Container Migration

**Risk:** Existing users have SwiftData stored in the main app's container. Adding a widget requires moving to App Group container. If migration fails or is incomplete, users lose their data or have two separate databases.

**Warning Signs:**
- Widget shows "No data" while app shows entries
- Data loss after app update
- Duplicate entries after migration

**Prevention:**
- Check if standard container has data before App Group container
- Migrate data to App Group on first launch with new version
- Use atomic file operations or SwiftData migration
- NEVER delete the old container until migration is verified
- Test migration with real user data (export, simulate upgrade, verify)

**Phase:** Widget infrastructure setup (CRITICAL - do first)

**Confidence:** HIGH (standard migration requirement)

---

### WK-2: Widget Shows Stale Data

**Risk:** Widget timeline doesn't refresh when app data changes. User adds weight entry, widget still shows old value.

**Warning Signs:**
- Widget showing yesterday's weight after new entry
- Users force-quitting app to refresh widget
- Widget data never updating

**Prevention:**
- Call `WidgetCenter.shared.reloadTimelines(ofKind:)` after every data mutation:
  - New entry added
  - Entry updated
  - Entry deleted
  - Preferences changed (goal weight, unit)
- Already have `SharedModelContainer.reloadWidgetTimeline()` helper - USE IT
- Don't rely solely on timeline policy; iOS limits background refreshes

**Phase:** Widget implementation (every mutation site)

**Confidence:** HIGH (documented requirement)

---

### WK-3: Widget Intent Changes Not Reflected in App

**Risk:** If widget uses AppIntents for user interaction (e.g., quick-add weight), changes made via widget may not appear in main app until app is relaunched.

**Warning Signs:**
- Adding entry via widget doesn't show in app until force-quit
- Data inconsistency between widget and app
- Works on iOS 18 but not iOS 17

**Prevention:**
- Consume SwiftData history using Apple's recommended pattern
- For iOS 17 support, may need to post `NSPersistentStoreRemoteChange` notification manually
- Test on both iOS 17 and 18 simulators
- Consider making widget read-only for v1.1 (display only, no input)

**Phase:** Widget implementation (if interactive)

**Confidence:** HIGH (documented iOS 17 bug, fixed in iOS 18)

---

### WK-4: Widget Extension CloudKit Sync Issues

**Risk:** If widget extension tries to sync with CloudKit independently, it conflicts with main app's sync. NSPersistentCloudKitContainer cannot sync while app is in background.

**Warning Signs:**
- Widget showing different data than app after iCloud sync
- Sync conflicts appearing randomly
- Data loss or duplication

**Prevention:**
- Widget should be READ-ONLY from SwiftData
- Main app handles ALL CloudKit synchronization
- Widget only displays cached data from shared container
- Do not initialize CloudKit sync in widget extension

**Phase:** Widget architecture design

**Confidence:** HIGH (documented limitation)

---

### WK-5: Widget File Membership Errors

**Risk:** Widget extension needs access to shared code (models, utilities) but wrong file target membership causes build errors or runtime crashes.

**Warning Signs:**
- "Cannot find type 'WeightEntry' in scope" in widget code
- Runtime crashes in widget with "unrecognized selector"
- Build succeeds but widget shows error

**Prevention:**
- Create shared framework for common code OR carefully manage target membership
- `WeightEntry.swift` must be in both targets (or shared framework)
- `WeightUnit` must be accessible to widget
- Test build with clean derived data after adding widget target

**Phase:** Widget target setup

**Confidence:** HIGH (common setup issue)

---

### WK-6: Widget Database Restore Issue

**Risk:** After iPhone restore from backup, widget may fail with "The file couldn't be opened" because widget is created before app's data is restored.

**Warning Signs:**
- Widget broken after device restore
- Error in widget: "file couldn't be opened"
- Only fix is device restart

**Prevention:**
- Widget should handle missing database file gracefully (show placeholder)
- Detect first-run-after-restore scenario
- Don't crash or show error; show "Open app to set up" message
- Use optional container access with fallback

**Phase:** Widget error handling

**Confidence:** HIGH (documented iOS behavior)

---

## Sharing Pitfalls

Social sharing with image generation using ImageRenderer.

### SH-1: ImageRenderer Memory Pressure

**Risk:** `ImageRenderer` creates full-resolution images in memory. For sharing graphics with gradients and text, this can spike memory usage, especially on older devices.

**Warning Signs:**
- Crashes when generating share image on older devices
- Memory warnings before share sheet appears
- Black or blank images generated

**Prevention:**
- Use explicit dimensions (already have `standardSize = CGSize(width: 600, height: 315)`)
- Avoid embedding large images in the shareable view
- Use `@MainActor` for all ImageRenderer operations (already marked)
- Test on oldest supported device (e.g., iPhone XR with iOS 17)
- Release image promptly after sharing completes

**Phase:** Social sharing implementation

**Confidence:** HIGH (documented memory limitation)

---

### SH-2: Passing UIImage to Share Sheet

**Risk:** Passing `UIImage` directly to `UIActivityViewController` causes the receiving share extension to convert it to `NSData`, counting against the extension's 120MB memory limit. This can crash share extensions.

**Warning Signs:**
- Crashes in third-party share extensions (not your app)
- "Unable to share" errors with certain apps
- Works in Messages but fails in others

**Prevention:**
- Convert `UIImage` to `Data` (JPEG or PNG) before passing to share sheet
- Pass `Data` or file `URL` instead of `UIImage`
- Use JPEG compression (0.8 quality) to reduce size
- Provide image as `NSItemProvider` with proper type identifier

**Phase:** Social sharing implementation

**Confidence:** HIGH (documented share extension limitation)

---

### SH-3: ImageRenderer Localization Offset

**Risk:** After being converted to image, localized content can be misaligned. Text may appear offset, resulting in white borders or cut-off text.

**Warning Signs:**
- Share images have unexpected white borders
- Text appears cut off in certain languages
- Layout differs between preview and rendered image

**Prevention:**
- Use explicit frame sizes, not auto-layout
- Test rendered images in all supported languages
- Add padding buffer around content
- Use `alignmentGuide` to control positioning precisely

**Phase:** Social sharing + Localization integration

**Confidence:** MEDIUM (sporadic issue, environment-dependent)

---

### SH-4: Privacy - Showing Exact Weight

**Risk:** User accidentally shares image showing their exact weight publicly. Feature has "showWeight" toggle but defaults matter.

**Warning Signs:**
- User complaints about privacy
- Exact weight appearing in shared images unintentionally

**Prevention:**
- Default `showWeight` to FALSE
- Clear UI explanation of what will be shared
- Preview image before sharing (already implied in contract)
- Consider separate "Progress %" and "Weight" share options

**Phase:** Social sharing UX design

**Confidence:** MEDIUM (UX decision, not technical)

---

## Localization Pitfalls

First non-English language. No existing `.lproj` folders.

### L10N-1: Hardcoded Strings Scattered

**Risk:** App has been developed in English-only. Many strings are likely hardcoded throughout the codebase rather than using `LocalizedStringKey` or `String(localized:)`.

**Warning Signs:**
- String Catalog shows very few extractable strings
- Large portions of UI remain in English after adding translations
- Strings in view code like `Text("Weight")`

**Prevention:**
- Audit ALL view files for hardcoded strings BEFORE adding String Catalog
- Use Xcode's "Export for Localization" to identify extraction scope
- SwiftUI `Text("...")` automatically extracts, but verify format strings
- Create grep pattern to find non-localized strings: `Text\(".*"\)` that aren't `Text(verbatim:`

**Phase:** Localization preparation (before adding translations)

**Confidence:** HIGH (standard localization issue)

---

### L10N-2: String Concatenation Breaking

**Risk:** English string concatenation like `"\(month) Progress"` doesn't work in languages with different word order. Japanese reverses it: "進捗 8月" not "8月 進捗".

**Warning Signs:**
- Awkward translations in non-English languages
- Translators complaining about untranslatable strings
- Grammar errors in formatted strings

**Prevention:**
- Use String Catalog with positional specifiers: `%1$@ %2$@ Progress`
- Never concatenate user-facing strings in code
- Provide full sentence templates, not fragments
- Test with actual translations, not just string replacement

**Phase:** Localization implementation

**Confidence:** HIGH (documented localization issue)

---

### L10N-3: Number and Date Formatting

**Risk:** App uses custom number formatting that doesn't respect locale. Weight shown as "175.5 lbs" everywhere, but some locales use comma as decimal separator.

**Warning Signs:**
- Numbers displaying incorrectly in European locales (175,5 vs 175.5)
- Dates in wrong format for locale
- Users confused by unfamiliar number format

**Prevention:**
- Use `Text(value, format: .number.precision(...))` consistently (per CLAUDE.md)
- Use `Text(date, format: .dateTime)` for dates
- Test with German locale (comma decimal) and Arabic locale (different numerals)
- Review all `String(format:)` usage and migrate

**Phase:** Localization implementation

**Confidence:** HIGH (existing code uses correct patterns per CLAUDE.md, but verify)

---

### L10N-4: Plural Rules

**Risk:** English has simple singular/plural (1 entry, 2 entries). Other languages have complex rules (Arabic has six plural forms, Russian has three).

**Warning Signs:**
- Grammatically incorrect plurals in translated text
- "1 entries" appearing in some languages
- Translators asking about plural handling

**Prevention:**
- Use String Catalog's "Vary by Plural" feature
- Never manually check `count == 1` for singular/plural
- Use `Text("^[\(count) entry](inflect: true)")` for automatic inflection
- Review all count-based strings and add plural variants

**Phase:** Localization implementation

**Confidence:** HIGH (documented requirement)

---

### L10N-5: Text Truncation in UI

**Risk:** German text is often 30% longer than English. UI designed for English may truncate or overflow with longer translations.

**Warning Signs:**
- Text cut off with "..." in non-English
- Button text wrapping unexpectedly
- Layout breaking in translated versions

**Prevention:**
- Use Dynamic Type and flexible layouts
- Don't hardcode widths for text containers
- Test with pseudolocalization (Xcode scheme setting)
- Review ALL fixed-width UI elements
- Add `lineLimit(nil)` where appropriate

**Phase:** Localization QA testing

**Confidence:** HIGH (standard localization issue)

---

### L10N-6: Widget Localization Separate

**Risk:** Widget extension has separate bundle. If localization is only added to main app bundle, widget remains in English.

**Warning Signs:**
- Main app is localized but widget shows English
- Missing String Catalogs in widget target

**Prevention:**
- Add String Catalog to widget target as well
- Use shared localization file if possible, or duplicate carefully
- Widget must have its own `Localizable.xcstrings` or share via framework
- Test widget in non-English locale separately

**Phase:** Widget + Localization integration

**Confidence:** HIGH (standard multi-target issue)

---

## Testing Pitfalls

Adding tests to existing codebase with no prior test coverage.

### TEST-1: Untestable Architecture

**Risk:** Views have business logic embedded directly. No separation of concerns means testing requires UI tests for everything, which are slow and flaky.

**Warning Signs:**
- Every test requires launching the simulator
- Tests take minutes to run
- Tests fail randomly (flaky)

**Prevention:**
- Extract business logic to testable units (already have `TrendCalculator`, `LogbookRowData`)
- Prioritize testing pure functions and data transformations first
- Views should be "dumb" - delegate logic to tested helpers
- Don't retrofit ViewModel pattern; add focused extractors instead

**Phase:** Test coverage (ongoing)

**Confidence:** HIGH (codebase already has some good patterns)

---

### TEST-2: SwiftData Testing Complexity

**Risk:** SwiftData requires `ModelContainer` setup. Tests that use SwiftData are slower and more complex. Current `HealthSyncManagerTests` uses mock store but real SwiftData tests need in-memory containers.

**Warning Signs:**
- Tests leaking data between runs
- Tests failing in CI but passing locally
- Slow test suite

**Prevention:**
- Use in-memory `ModelConfiguration` for tests: `ModelConfiguration(isStoredInMemoryOnly: true)`
- Create fresh container for each test
- Follow existing pattern in `HealthSyncManagerTests` (isolated `UserDefaults` suite)
- Separate unit tests (no SwiftData) from integration tests (with SwiftData)

**Phase:** Test infrastructure setup

**Confidence:** HIGH (existing codebase shows pattern)

---

### TEST-3: HealthKit Testing Requires Mocks

**Risk:** HealthKit cannot be tested on simulator without device. Current `MockHealthStore` exists but only tests export path.

**Warning Signs:**
- HealthKit import tests skipped or failing on CI
- Tests only pass on device
- Mock doesn't cover anchored queries

**Prevention:**
- Extend `MockHealthStore` to support `HKAnchoredObjectQuery` execution
- Add mock `HKSample` creation for import testing
- Test the transformation logic separately from HealthKit API calls
- Use protocol-based injection (already have `HealthStoreProtocol`)

**Phase:** HealthKit Import testing

**Confidence:** HIGH (existing pattern in codebase)

---

### TEST-4: Testing Coverage Gaps Create False Confidence

**Risk:** Adding some tests creates false sense of coverage. Critical paths remain untested while easy-to-test code gets extensive coverage.

**Warning Signs:**
- High coverage percentage but production bugs persist
- Tests only cover happy paths
- Edge cases discovered by users, not tests

**Prevention:**
- Prioritize testing:
  1. Data transformations (unit conversion, trend calculation)
  2. HealthKit sync logic (conflict resolution)
  3. Critical user flows (add entry, edit, delete)
- Use code coverage tools but focus on critical path coverage, not percentage
- Add tests for bugs as they're found (regression tests)

**Phase:** Test strategy (define before writing tests)

**Confidence:** HIGH (standard testing wisdom)

---

### TEST-5: Flaky UI Tests

**Risk:** UI tests for weight entry, charts, and settings are inherently flaky. Timing issues, animations, and network conditions cause intermittent failures.

**Warning Signs:**
- Tests pass locally, fail in CI
- Re-running same test gives different results
- Tests depend on animation timing

**Prevention:**
- Use accessibility identifiers for all interactive elements
- Disable animations in test scheme: `UIView.setAnimationsEnabled(false)`
- Use `waitForExistence` with appropriate timeouts
- Prefer unit tests over UI tests where possible
- Run UI tests on consistent simulator (not physical devices)

**Phase:** UI test implementation

**Confidence:** HIGH (standard UI testing challenge)

---

### TEST-6: Testing Widget in Isolation

**Risk:** Widget cannot be easily unit tested. Widget timeline provider runs in extension context, not app context.

**Warning Signs:**
- Widget bugs only discovered at runtime
- No tests for timeline generation
- Widget data fetching untested

**Prevention:**
- Extract widget data fetching logic to shared, testable code
- Test `WeightWidgetProvider.calculateTrend(from:)` as unit test
- Test data transformation, not WidgetKit integration
- Manually test widget scenarios in simulator gallery

**Phase:** Widget testing strategy

**Confidence:** MEDIUM (limited tooling for widget testing)

---

## Integration Pitfalls

Pitfalls specific to adding these features to the existing W8Trackr app.

### INT-1: App Group Migration Breaks CloudKit

**Risk:** Moving SwiftData to App Group container may require CloudKit to re-sync all data, or worse, create duplicate records.

**Warning Signs:**
- All data re-syncing after update
- Duplicate entries appearing on all devices
- CloudKit sync errors after migration

**Prevention:**
- Test migration path on device with CloudKit enabled
- Consider staged rollout: TestFlight with CloudKit users first
- Have rollback plan if migration corrupts CloudKit data
- Document expected behavior for users (data may re-sync)

**Phase:** Widget infrastructure (App Group migration)

**Confidence:** MEDIUM (requires real CloudKit testing)

---

### INT-2: Feature Flag Management

**Risk:** Shipping HealthKit import, widgets, sharing, and localization all at once means many potential failure points. One broken feature blocks entire release.

**Warning Signs:**
- Delayed release due to one feature's bugs
- All features coupled, can't ship incrementally
- Users get partially working features

**Prevention:**
- Ship features independently if possible
- Use runtime feature flags for gradual rollout
- Localization and test coverage can ship silently
- HealthKit import could be off by default, enabled in Settings

**Phase:** Release planning

**Confidence:** MEDIUM (project management, not technical)

---

### INT-3: HealthKit Import + Widget Data Staleness

**Risk:** HealthKit imports data in background. Widget shows stale data until next timeline refresh. User imports 10 weights from Health, widget shows old value.

**Warning Signs:**
- Widget not updating after HealthKit sync
- User confusion about which weight is "current"

**Prevention:**
- Call `reloadWidgetTimeline()` after HealthKit import completes
- Widget should show timestamp: "Updated 2 hours ago"
- Consider background app refresh to sync HealthKit and update widget

**Phase:** HealthKit Import + Widget integration

**Confidence:** HIGH (predictable integration point)

---

### INT-4: Localization + Sharing Image Text

**Risk:** Share image generates text. If image is generated with English app but shared to someone using different language, or vice versa, text on image doesn't match recipient's language.

**Warning Signs:**
- Share images always in one language regardless of user setting
- Text renders incorrectly for certain locales
- Font issues with non-Latin characters

**Prevention:**
- Generate share image using device's current locale
- Use system fonts that support all target languages
- Test share image generation in each supported locale
- Consider locale-neutral designs (icons over text)

**Phase:** Sharing + Localization integration

**Confidence:** MEDIUM (design decision)

---

### INT-5: Test Coverage Slowing CI

**Risk:** Adding comprehensive tests to a previously untested codebase dramatically increases CI time. Developers stop running tests locally.

**Warning Signs:**
- CI builds taking 10+ minutes
- Developers pushing without running tests
- Tests disabled or skipped to speed up development

**Prevention:**
- Separate fast unit tests from slow integration/UI tests
- Run unit tests on every commit, UI tests on merge to main only
- Use parallel test execution
- Target < 2 minute unit test suite

**Phase:** Test infrastructure

**Confidence:** HIGH (standard CI optimization)

---

## Critical Path

These pitfalls are most dangerous and must be addressed first:

### Priority 1: Blocking Issues (Address Before Implementation)

1. **WK-1: App Group Container Migration** - Existing users will lose data if migration fails. Must solve before shipping widget.

2. **HK-3: Conflict Resolution Complexity** - "Health wins" is ambiguous. Define rules in specification before writing code.

3. **L10N-1: Hardcoded Strings Scattered** - Audit must happen before adding String Catalog, or translations will be incomplete.

### Priority 2: High-Risk Technical Issues

4. **HK-2: Duplicate Entry Creation** - Without deduplication, HealthKit import will flood the app with duplicates.

5. **WK-4: Widget Extension CloudKit Sync Issues** - Widget must NOT sync; this architecture decision affects all widget code.

6. **TEST-2: SwiftData Testing Complexity** - Set up test infrastructure correctly once; don't retrofit later.

### Priority 3: Integration Issues (Address During Integration)

7. **INT-1: App Group Migration Breaks CloudKit** - Test thoroughly before release.

8. **WK-3: Widget Intent Changes Not Reflected in App** - iOS 17 bug; decide if widget is read-only or needs workaround.

9. **INT-3: HealthKit Import + Widget Data Staleness** - Ensure reload is called at all import completion points.

---

## Sources

### HealthKit
- [Apple HealthKit Pitfalls - Beda Software](https://beda.software/blog/apple-healthkit-pitfalls)
- [Mastering HealthKit: Common Pitfalls and Solutions - Medium](https://medium.com/mobilepeople/mastering-healthkit-common-pitfalls-and-solutions-b4f46729f28e)
- [Reading data from HealthKit - Apple Developer Documentation](https://developer.apple.com/documentation/healthkit/reading-data-from-healthkit)
- [HKAnchoredObjectQuery - DevFright](https://www.devfright.com/how-to-use-healthkit-hkanchoredobjectquery/)

### WidgetKit
- [Understanding Widget Runtime Limitations - Medium](https://medium.com/@telawittig/understanding-the-limitations-of-widgets-runtime-in-ios-app-development-and-strategies-for-managing-a3bb018b9f5a)
- [Using WidgetKit + SwiftData - Caleb Hearth](https://calebhearth.com/using-widgetkit-with-swiftdata)
- [iOS in the Cloud: CloudKit, SwiftData and WidgetKit - Medium](https://medium.com/kostiantyn-kolosov/ios-in-the-cloud-how-to-make-friendship-between-cloudkit-coredata-swiftdata-and-widgetkit-f22431d4eaf6)
- [How to access SwiftData from widgets - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets)

### Image Sharing
- [Reduce share extension crashes - Medium](https://medium.com/@timonus/reduce-share-extension-crashes-from-your-app-with-this-one-weird-trick-6b86211bb175)
- [Dealing with memory limits in iOS app extensions - Igor Kulman](https://blog.kulman.sk/dealing-with-memory-limits-in-app-extensions/)
- [Widget iOS image bundling problem - Fabrizio Duroni](https://www.fabrizioduroni.it/blog/post/2023/01/10/widget-ios-swiftui-image-problem)

### Localization
- [Swift Localization in 2025 - FLine](https://www.fline.dev/swift-localization-in-2025-best-practices-you-couldnt-use-before/)
- [Scaling iOS Localization with Swift String Catalogs - Medium](https://medium.com/@oksanafedorchuk_54367/scaling-ios-localization-with-swift-string-catalogs-my-step-by-step-journey-ec1374764ad3)
- [Localizing and varying text with a string catalog - Apple Developer](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)

### Testing
- [Updating existing codebase for unit tests - Apple Developer](https://developer.apple.com/documentation/xcode/updating-your-existing-codebase-to-accommodate-unit-tests)
- [Unit Testing in iOS 2025 - Medium](https://medium.com/@Rutik_Maraskolhe/unit-testing-in-ios-2025-cutting-edge-strategies-tools-and-trends-for-high-quality-apps-eee2876e47ba)

### SwiftData + CloudKit
- [Syncing SwiftData with CloudKit - Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit)
- [How to resolve conflicts with SwiftData - Apple Developer Forums](https://developer.apple.com/forums/thread/751480)
- [Syncing changes between main app and extensions - Apple Developer Forums](https://developer.apple.com/forums/thread/764290)
