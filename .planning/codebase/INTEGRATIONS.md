# External Integrations

**Analysis Date:** 2026-01-20

## APIs & External Services

**Apple HealthKit:**
- Purpose: Bidirectional sync of weight and body fat entries
- SDK/Client: `HealthKit` framework
- Auth: Runtime permission dialog
- Implementation: `W8Trackr/Managers/HealthSyncManager.swift`, `W8Trackr/Managers/HealthKitManager.swift`
- Capabilities: Save, update, delete weight samples; read weight history
- Required plist keys: `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`

**Apple CloudKit:**
- Purpose: Cross-device iCloud sync for SwiftData
- SDK/Client: `CloudKit` framework (automatic via SwiftData)
- Auth: iCloud account (automatic)
- Implementation: `W8Trackr/Managers/CloudKitSyncManager.swift`
- Container ID: `iCloud.com.saults.W8Tracker`
- Capabilities: Automatic sync, offline support, conflict resolution

**Siri / App Intents:**
- Purpose: Voice control for logging weight and querying trends
- SDK/Client: `AppIntents` framework
- Auth: None required
- Implementation: `W8Trackr/Intents/AppShortcuts.swift`
- Phrases: "Log my weight", "What's my weight trend", "How much have I lost"

## Data Storage

**Databases:**
- SwiftData (on-device)
  - Models: `WeightEntry`, `CompletedMilestone`, `MilestoneAchievement`
  - Location: App container Documents directory
  - Client: `@Model`, `@Query`, `ModelContext`
  - CloudKit backing: Enabled via entitlements

**File Storage:**
- Local filesystem only
- Temporary directory used for CSV/JSON exports
- Implementation: `W8Trackr/Managers/DataExporter.swift`

**Caching:**
- UserDefaults for preferences
- Keys: `preferredWeightUnit`, `goalWeight`, `reminderTime`, `hasCompletedOnboarding`, `healthSyncEnabled`, `smartRemindersEnabled`

## Authentication & Identity

**Auth Provider:**
- None (no user accounts)
- iCloud identity used implicitly for CloudKit sync
- HealthKit authorization managed separately

## Monitoring & Observability

**Error Tracking:**
- None (no external error tracking service)

**Logs:**
- Console logging via `print()` statements (warned by SwiftLint)
- No structured logging framework

## CI/CD & Deployment

**Hosting:**
- Apple App Store
- TestFlight for beta

**CI Pipeline:**
- GitHub Actions
- Workflows: `.github/workflows/test.yml`, `.github/workflows/testflight.yml`
- Runs on: `macos-15` runner
- Xcode: 16.2 (CI), 16.3 (local dev)

**Deployment Trigger:**
- Tests: Push/PR to `main`
- TestFlight: Push tag `v*`

## Environment Configuration

**Required env vars (CI only):**
- `APP_STORE_CONNECT_API_KEY` - Base64-encoded p8 key
- `APP_STORE_CONNECT_KEY_ID` - API key ID
- `APP_STORE_CONNECT_ISSUER_ID` - Team issuer ID

**Secrets location:**
- GitHub repository secrets
- Local: `fastlane/api_key.json` (gitignored)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Entitlements

Defined in `W8Trackr/W8Trackr.entitlements`:

```xml
- aps-environment: development (push notifications)
- com.apple.developer.icloud-container-identifiers: iCloud.com.saults.W8Tracker
- com.apple.developer.icloud-services: CloudKit
- com.apple.developer.healthkit: true
- com.apple.developer.healthkit.background-delivery: true
```

## Info.plist Usage Descriptions

| Key | Description |
|-----|-------------|
| `NSUserNotificationUsageDescription` | Daily weight logging reminders |
| `NSSiriUsageDescription` | Siri shortcuts for logging weight |
| `NSHealthShareUsageDescription` | Read weight data from Health |
| `NSHealthUpdateUsageDescription` | Save weight/body fat to Health |

## Integration Status

| Integration | Status | Notes |
|-------------|--------|-------|
| HealthKit Write | Complete | Weight + body fat export |
| HealthKit Read | Partial | Infrastructure exists, P2 feature |
| CloudKit Sync | Complete | Automatic via SwiftData |
| Siri Shortcuts | Complete | 3 intents available |
| Push Notifications | Enabled | Local notifications only |

---

*Integration audit: 2026-01-20*
