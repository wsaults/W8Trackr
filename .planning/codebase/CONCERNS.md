# Codebase Concerns

**Analysis Date:** 2026-01-20

## Tech Debt

**Unimplemented Service Layer (MilestoneTracker & GoalProgressCalculator):**
- Issue: Both services contain methods with `fatalError("Not implemented")` that will crash if called
- Files: `W8Trackr/Services/MilestoneTracker.swift`, `W8Trackr/Services/GoalProgressCalculator.swift`
- Impact: Runtime crashes if any code path calls these methods. Currently these appear unused but remain dangerous landmines.
- Fix approach: Either implement the functionality or remove the stub methods. The `MilestoneCalculator` enum in `W8Trackr/Models/Milestone.swift` provides working milestone logic that duplicates some of this intent.

**Duplicate HealthKit Managers:**
- Issue: Two separate classes manage HealthKit operations with overlapping responsibilities
- Files: `W8Trackr/Managers/HealthKitManager.swift`, `W8Trackr/Managers/HealthSyncManager.swift`
- Impact: Code duplication, potential state inconsistency, confusion about which to use. Comment in `WeightEntryView.swift` line 335 notes "legacy HealthKitManager is still used for new entries until the full migration"
- Fix approach: Complete migration to `HealthSyncManager` (T024 per code comment), then remove `HealthKitManager`

**Deprecated GCD Usage:**
- Issue: Uses `DispatchQueue.main.async` throughout despite project rules requiring strict Swift concurrency
- Files: `W8Trackr/Managers/HealthKitManager.swift` (5 occurrences), `W8Trackr/Managers/NotificationManager.swift` (3 occurrences), `W8Trackr/Managers/CloudKitSyncManager.swift` (4 occurrences)
- Impact: Violates project concurrency guidelines, potential race conditions, harder to reason about thread safety
- Fix approach: Migrate to `@MainActor` and `async/await` patterns. `HealthSyncManager.swift` already shows the correct pattern with `@MainActor` annotation.

**NotificationManager Uses ObservableObject:**
- Issue: Uses deprecated `ObservableObject` pattern instead of `@Observable`
- Files: `W8Trackr/Managers/NotificationManager.swift`, `W8Trackr/Managers/HealthKitManager.swift`
- Impact: Inconsistent with project conventions which mandate `@Observable`
- Fix approach: Migrate to `@Observable` macro with `@MainActor` annotation

**Deprecated SwiftUI API in WeightEntryView:**
- Issue: Uses `.cornerRadius(10)` instead of modern `.clipShape(.rect(cornerRadius: 10))`
- Files: `W8Trackr/Views/WeightEntryView.swift` (line 265)
- Impact: SwiftLint warning, deprecated API
- Fix approach: Replace with `.clipShape(.rect(cornerRadius: 10))`

## Known Bugs

**CloudKit Sync Status Guessing:**
- Symptoms: Sync status may show "Synced" when actually still in progress
- Files: `W8Trackr/Managers/CloudKitSyncManager.swift` (lines 94-100, 148-153)
- Trigger: Network restored or sync event without clear success signal
- Workaround: Uses `asyncAfter` delays to assume success, which is unreliable
- Details: The code sets `.syncing` status then blindly sets `.synced` after 1-2 seconds if status hasn't changed, rather than waiting for actual confirmation.

**HealthKit Auth Status Not Updated on Settings Toggle:**
- Symptoms: Toggle may show enabled but actual HealthKit permission could be denied in system settings
- Files: `W8Trackr/Views/SettingsView.swift` (lines 247-267)
- Trigger: User enables toggle, then goes to Settings app and revokes permission
- Workaround: App gracefully degrades per `HealthSyncManager.isAuthorizationDeniedError()` but UI state is stale

## Security Considerations

**No Input Sanitization on Notes:**
- Risk: Weight entry notes are stored directly without sanitization
- Files: `W8Trackr/Views/WeightEntryView.swift`, `W8Trackr/Models/WeightEntry.swift`
- Current mitigation: SwiftData handles SQL injection. Notes displayed via SwiftUI Text which escapes HTML.
- Recommendations: Consider length limits on note field to prevent abuse in exports/sharing

**UserDefaults for Sensitive Preferences:**
- Risk: Health sync preference stored in UserDefaults (unencrypted)
- Files: `W8Trackr/Managers/HealthSyncManager.swift` (keys: `healthSyncEnabled`, `lastHealthSyncDate`)
- Current mitigation: These are preferences, not sensitive health data. Actual weight data is in SwiftData with CloudKit sync.
- Recommendations: None urgent, but consider Keychain for any future auth tokens

**HealthKit Metadata Includes Entry Hash:**
- Risk: Entry ID hash stored in HealthKit metadata could theoretically correlate across devices
- Files: `W8Trackr/Managers/HealthSyncManager.swift` (line 311)
- Current mitigation: This is necessary for sync conflict resolution
- Recommendations: Document this in privacy policy

## Performance Bottlenecks

**Full Data Reload on Every Change:**
- Problem: `@Query` in `ContentView.swift` fetches all entries sorted on every data change
- Files: `W8Trackr/Views/ContentView.swift` (lines 43-49)
- Cause: SwiftData's reactive queries reload entire result set
- Improvement path: Use pagination for large datasets, limit to recent entries for dashboard, or use `fetchLimit`

**Sample Data Caching Uses `nonisolated(unsafe)`:**
- Problem: Static sample data uses unsafe lazy caching to avoid regeneration
- Files: `W8Trackr/Models/WeightEntry.swift` (lines 301-303)
- Cause: Performance optimization for preview data
- Improvement path: This is preview-only code, acceptable but document the concurrency risk

**TrendCalculator Processes All Entries:**
- Problem: EWMA calculation iterates through all entries even when filtered range is smaller
- Files: `W8Trackr/Analytics/TrendCalculator.swift`
- Cause: No pre-filtering before trend calculation
- Improvement path: Filter entries by date range before passing to calculator

## Fragile Areas

**Milestone Calculation Logic:**
- Files: `W8Trackr/Models/Milestone.swift`, `W8Trackr/Views/Dashboard/DashboardView.swift`
- Why fragile: Three similar concepts exist: `CompletedMilestone` (SwiftData), `MilestoneProgress` (runtime), `MilestoneAchievement` (SwiftData). Plus unused `MilestoneTracker` and `MilestoneType` enums.
- Safe modification: Stick to `MilestoneCalculator` enum for logic. Don't touch the stub services.
- Test coverage: No unit tests for `MilestoneCalculator`

**Weight Unit Conversion Chain:**
- Files: `W8Trackr/Models/WeightEntry.swift`, `W8Trackr/Views/SettingsView.swift`
- Why fragile: Unit conversion happens in multiple places. Boundary values between units don't match perfectly (1500 lb > 680 kg max)
- Safe modification: Always use `WeightUnit.convert(_:to:)` method, never manual math
- Test coverage: Well tested in `W8TrackrTests.swift`

**HealthKit Sync State Machine:**
- Files: `W8Trackr/Managers/HealthSyncManager.swift`
- Why fragile: State transitions (idle->syncing->success/failed) have edge cases around auth denied
- Safe modification: Always check `isAuthorizationDeniedError` before throwing errors
- Test coverage: Has tests in `HealthSyncManagerTests.swift`

**Delete Sample Query in HealthSyncManager:**
- Files: `W8Trackr/Managers/HealthSyncManager.swift` (lines 324-355)
- Why fragile: Complex nested closure with `withCheckedThrowingContinuation`, weak self capture, and Task re-entry to MainActor
- Safe modification: Ensure continuation always resumes exactly once
- Test coverage: Limited testing of delete path

## Scaling Limits

**SwiftData with CloudKit:**
- Current capacity: Works well for typical user (<1000 entries)
- Limit: CloudKit has rate limits and record size limits
- Scaling path: Already using optional relationships per CloudKit requirements. Consider archiving old entries if users track for years.

**Notification Scheduling:**
- Current capacity: 64 pending local notifications (iOS limit)
- Limit: Smart reminders could exhaust this quota
- Scaling path: `NotificationScheduler` already manages IDs, but should audit total pending count

## Dependencies at Risk

**No External Dependencies:**
- The project has no third-party dependencies (per CLAUDE.md policy)
- All code is first-party Swift/SwiftUI/HealthKit/CloudKit
- No package manifest (Package.swift) - pure Xcode project

## Missing Critical Features

**No Data Import:**
- Problem: Can export CSV/JSON but cannot import data
- Blocks: Users migrating from other apps
- Note: Import would need validation and duplicate detection

**No Undo for Delete All:**
- Problem: "Delete All Entries" in Settings is immediately destructive
- Blocks: Recovery from accidental deletion
- Note: Individual entry deletion has undo via `HistorySectionView`

**HealthKit Import Not Implemented:**
- Problem: Comment in `HealthSyncManager.swift` notes "Importing weight entries from HealthKit (P2 - future)"
- Blocks: Importing existing weight data from Apple Health
- Note: Only export to HealthKit is implemented

## Test Coverage Gaps

**No Tests for Milestone Logic:**
- What's not tested: `MilestoneCalculator` enum, `MilestoneProgress` struct, `CompletedMilestone` model
- Files: `W8Trackr/Models/Milestone.swift`
- Risk: Milestone celebration could fire incorrectly or fail silently
- Priority: Medium - this affects user delight features

**No Tests for View Logic:**
- What's not tested: Complex computed properties in views like `DashboardView`, `QuickStatsRow`
- Files: `W8Trackr/Views/Dashboard/*.swift`
- Risk: UI calculations could be wrong for edge cases
- Priority: Low - previews provide some coverage

**No Integration Tests for HealthKit Flow:**
- What's not tested: End-to-end flow of save->edit->delete with real HealthKit
- Files: `W8Trackr/Managers/HealthSyncManager.swift`
- Risk: Edge cases in auth flow or sync failures
- Priority: Medium - unit tests exist but integration gaps remain

**UI Tests Limited to Screenshots:**
- What's not tested: User flows, error states, accessibility
- Files: `W8TrackrUITests/ScreenshotTests.swift`
- Risk: Regressions in user workflows
- Priority: Low - app is simple enough that manual testing covers most paths

---

*Concerns audit: 2026-01-20*
