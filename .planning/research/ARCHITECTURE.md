# Architecture Research: v1.1

**Project:** W8Trackr
**Researched:** 2026-01-22
**Scope:** Architecture dimension for v1.1 features

## Existing Architecture Summary

W8Trackr follows a pure SwiftUI architecture with these characteristics:

### Current Patterns
- **State Management:** `@State`, `@Binding`, `@AppStorage` for view state; no ViewModels
- **Persistence:** SwiftData `@Model` with `@Query` for reactive data
- **Services:** `@Observable @MainActor` manager classes (singleton pattern)
- **Concurrency:** Strict Swift 6.2 concurrency (async/await, no GCD)
- **Structure:** Feature-based folders (Views/, Managers/, Models/, Analytics/)

### Key Components
| Component | Pattern | Location |
|-----------|---------|----------|
| WeightEntry | SwiftData @Model | Models/WeightEntry.swift |
| HealthSyncManager | @Observable singleton | Managers/HealthSyncManager.swift |
| NotificationManager | ObservableObject | Managers/NotificationManager.swift |
| TrendCalculator | Pure enum (stateless) | Analytics/TrendCalculator.swift |
| ContentView | TabView root | Views/ContentView.swift |

### Data Flow
```
User Input --> SwiftUI View --> ModelContext --> SwiftData
                    |
                    +--> HealthSyncManager --> HealthKit
                    |
                    +--> NotificationManager --> UNUserNotificationCenter
```

---

## Integration Points

### 1. HealthKit Import (Read from Apple Health)

**Existing Foundation:**
- `HealthSyncManager` already handles export (write to HealthKit)
- `HealthStoreProtocol` provides testable abstraction
- `WeightEntry` has sync fields: `healthKitUUID`, `source`, `syncVersion`, `pendingHealthSync`

**Integration Strategy:**
```
HealthKit --> HKAnchoredObjectQuery --> HealthSyncManager.importFromHealth()
                                              |
                                              v
                                        SwiftData (WeightEntry)
```

**Key Integration Points:**
- Extend `HealthSyncManager` with `importWeightFromHealth()` method
- Add `HKAnchoredObjectQuery` for incremental sync (anchor already stored in UserDefaults)
- Use `source` field to distinguish imported entries ("Apple Health", device name)
- Conflict resolution: Health wins for same-date entries (user expectation)

**Modified Files:**
- `HealthSyncManager.swift` - Add import methods, query execution
- `HealthStoreProtocol.swift` - Add query-related protocol methods if needed

**New Components:**
- None required - existing architecture accommodates import

---

### 2. Widget Extension

**App Group Requirement:**
The widget needs shared data access. This requires:
1. App Group entitlement in both targets
2. Shared SwiftData container pointing to App Group
3. Shared UserDefaults for preferences

**Integration Strategy:**
```
Main App                          Widget Extension
    |                                    |
    v                                    v
SharedModelContainer.shared      SharedModelContainer.shared
    |                                    |
    v                                    v
App Group: group.com.saults.W8Trackr
    |
    +-- SwiftData store
    +-- UserDefaults (unit, goal)
```

**Contract Already Exists:**
The `specs/004-ios-widget/contracts/SharedModelContainer.swift` defines:
- `SharedModelContainer.shared` - Shared ModelContainer
- `SharedModelContainer.sharedDefaults` - Shared UserDefaults
- `SharedModelContainer.reloadWidgetTimeline()` - Timeline refresh trigger
- `SharedModelContainer.migratePreferencesToSharedDefaults()` - Migration helper

**Integration Points:**
1. **W8TrackrApp.swift** - Switch `.modelContainer()` to use `SharedModelContainer.shared`
2. **ContentView.swift** - Call `reloadWidgetTimeline()` after data changes
3. **WeightEntryView.swift** - Call `reloadWidgetTimeline()` after save
4. **SettingsView.swift** - Use shared defaults for unit/goal

**New Components:**
| Component | Target | Purpose |
|-----------|--------|---------|
| W8TrackrWidget/ | Widget Extension | New target |
| WeightWidgetProvider.swift | Widget | Timeline provider |
| SmallWidgetView.swift | Widget | Small widget UI |
| MediumWidgetView.swift | Widget | Medium widget UI |
| WeightWidgetEntry.swift | Widget | Timeline entry model |

**Entitlements Required:**
```xml
<!-- Both targets need: -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.saults.W8Trackr</string>
</array>
```

---

### 3. Image Sharing (Social Export)

**Integration Strategy:**
```
Chart/Progress View --> ImageRenderer --> UIImage --> UIActivityViewController
```

**Contract Already Exists:**
The `specs/003-social-sharing/contracts/ProgressImageRenderer.swift` defines:
- `ProgressImageRenderer.renderMilestoneImage()` - Milestone graphics
- `ProgressImageRenderer.renderProgressImage()` - Progress summary
- `MilestoneGraphicView` / `ProgressGraphicView` - SwiftUI views to render

**Integration Points:**
1. **DashboardView.swift** - Add share button triggering sheet
2. **MilestoneProgressView.swift** - Share button for milestone achievements
3. **New ShareSheet.swift** - `UIActivityViewController` wrapper

**Key Consideration:**
`ImageRenderer` is `@MainActor` and requires iOS 16+. The contract correctly uses `@MainActor` annotation. Rendering happens synchronously on main thread, so keep graphic complexity low to avoid UI jank.

**Modified Files:**
- `DashboardView.swift` - Add share action
- `MilestoneProgressView.swift` - Add share action
- `HeroCardView.swift` - Potential share trigger location

**New Components:**
| Component | Purpose |
|-----------|---------|
| ShareSheetView.swift | UIViewControllerRepresentable for UIActivityViewController |
| ProgressImageRenderer.swift | Implementation of contract |
| MilestoneGraphicView.swift | Shareable milestone image |
| ProgressGraphicView.swift | Shareable progress image |

---

### 4. Localization (Spanish)

**Current State:**
- No `.lproj` directories exist
- No `.strings` or `.xcstrings` files
- All strings are inline in SwiftUI views

**iOS 15+ String Catalog Strategy:**
Use Xcode's String Catalog (`.xcstrings`) for modern localization workflow:

```
W8Trackr/
└── Localizable.xcstrings  <-- Single file, all languages
```

**Integration Points:**
1. **Create String Catalog** - Xcode: Product > Export Localizations
2. **Mark strings for localization** - Already done via SwiftUI `Text("string")`
3. **Info.plist strings** - Need separate `InfoPlist.xcstrings` for permission descriptions

**Localization-Sensitive Components:**
| Component | Strings to Localize |
|-----------|---------------------|
| OnboardingView.swift | Welcome text, feature descriptions |
| SettingsView.swift | Section headers, labels |
| DashboardView.swift | Stats labels, empty states |
| WeightEntryView.swift | Form labels, validation messages |
| Info.plist | Permission usage descriptions |

**String Considerations for Spanish:**
- Number formatting uses `Text(value, format: .number)` - already locale-aware
- Date formatting uses SwiftUI formatters - already locale-aware
- Weight unit strings ("lbs", "kg") should NOT be localized (international standard)

**New Components:**
| Component | Purpose |
|-----------|---------|
| Localizable.xcstrings | Main string catalog |
| InfoPlist.xcstrings | Info.plist strings |

---

## New Components Required

### Widget Extension Target
```
W8TrackrWidget/
├── W8TrackrWidgetBundle.swift      # Widget entry point
├── WeightWidget.swift              # Widget configuration
├── WeightWidgetProvider.swift      # Timeline provider
├── WeightWidgetEntry.swift         # Timeline entry
├── Views/
│   ├── SmallWidgetView.swift       # systemSmall layout
│   ├── MediumWidgetView.swift      # systemMedium layout
│   └── WidgetEmptyStateView.swift  # No data state
└── W8TrackrWidget.entitlements     # App Group entitlement
```

### Shared Code (Both Targets)
```
Shared/
├── SharedModelContainer.swift      # Already in specs/
└── WeightEntry.swift               # Must be shared (via target membership)
```

### Image Sharing
```
Views/Sharing/
├── ShareSheetView.swift            # UIActivityViewController wrapper
├── ProgressImageRenderer.swift     # ImageRenderer implementation
├── MilestoneGraphicView.swift      # Shareable milestone view
└── ProgressGraphicView.swift       # Shareable progress view
```

### Localization
```
W8Trackr/
├── Localizable.xcstrings           # Main strings (en, es)
└── InfoPlist.xcstrings             # Permission strings (en, es)
```

---

## Modified Components

### Must Modify
| File | Change | Reason |
|------|--------|--------|
| W8TrackrApp.swift | Use SharedModelContainer | Widget data sharing |
| W8Trackr.entitlements | Add App Group | Widget data sharing |
| HealthSyncManager.swift | Add import methods | HealthKit read |
| ContentView.swift | Add reloadWidgetTimeline calls | Widget updates |
| WeightEntryView.swift | Add reloadWidgetTimeline call | Widget updates |
| SettingsView.swift | Use shared defaults | Widget preferences |

### Should Modify
| File | Change | Reason |
|------|--------|--------|
| DashboardView.swift | Add share button | Social sharing |
| MilestoneProgressView.swift | Add share button | Social sharing |
| HeroCardView.swift | Share action trigger | Social sharing |

### Verification Needed
| File | Potential Change | When |
|------|------------------|------|
| NotificationManager.swift | None expected | Review for localization |
| TrendCalculator.swift | None expected | Pure calculation |
| WeightTrendChartView.swift | Localize axis labels | If needed |

---

## Data Flow Changes

### Current Flow (v1.0)
```
WeightEntryView --> ModelContext.insert() --> SwiftData
                           |
                           v
                    HealthSyncManager.saveWeightToHealth()
                           |
                           v
                       HealthKit (write only)
```

### New Flow (v1.1)
```
                    +-- HealthKit (external sources)
                    |
                    v
              HealthSyncManager.importFromHealth()
                    |
                    v
            Conflict Resolution (Health wins)
                    |
                    v
WeightEntryView --> ModelContext --> SwiftData <-- Widget reads
                           |                          |
                           v                          v
              HealthSyncManager.saveWeightToHealth()  Timeline refresh
                           |
                           v
                       HealthKit (write)
```

### Conflict Resolution Strategy
When importing from HealthKit:
1. **Match by date** - Find existing entry within same day
2. **Compare sources:**
   - If existing is `source: "W8Trackr"` and import is external -> Keep both (user might want manual entry)
   - If existing has `healthKitUUID` matching import -> Update existing
   - If no match -> Create new entry with `source: [device/app name]`
3. **UI indication** - Show imported entries differently (icon badge, source label)

**Recommendation:** Start simple - import creates new entries, show source in logbook. Deduplication can be phase 2.

---

## Suggested Build Order

Based on dependencies and risk:

### Phase 1: HealthKit Import
**Rationale:** Foundation already exists (HealthSyncManager, WeightEntry sync fields). Low-risk extension of existing patterns.

**Sequence:**
1. Add `HKAnchoredObjectQuery` to HealthSyncManager
2. Implement `importWeightFromHealth()`
3. Add import trigger in SettingsView
4. Test with real Health data

**Dependencies:** None (builds on existing code)

---

### Phase 2: Widget Extension
**Rationale:** Requires new target setup, entitlements changes, shared container migration. Higher complexity but well-defined contracts exist.

**Sequence:**
1. Add App Group entitlement to main app
2. Migrate to SharedModelContainer in W8TrackrApp
3. Create Widget extension target
4. Implement WeightWidgetProvider
5. Build SmallWidgetView, MediumWidgetView
6. Add reloadWidgetTimeline() calls in main app

**Dependencies:**
- SharedModelContainer must be ready before widget
- Main app entitlements must be updated first

---

### Phase 3: Social Sharing
**Rationale:** Self-contained feature, no architectural dependencies. Can be built independently.

**Sequence:**
1. Implement ShareSheetView wrapper
2. Build ProgressImageRenderer
3. Design MilestoneGraphicView, ProgressGraphicView
4. Integrate share buttons into existing views

**Dependencies:** None (uses existing views as data source)

---

### Phase 4: Localization
**Rationale:** Should come after other features are stable. Localizing moving targets wastes effort.

**Sequence:**
1. Create Localizable.xcstrings via Xcode export
2. Add Spanish translations
3. Create InfoPlist.xcstrings for permission strings
4. Test in Spanish locale

**Dependencies:**
- All user-visible strings should be finalized
- Permission strings need special attention

---

### Phase 5: Test Coverage
**Rationale:** Tests should cover final architecture, not moving targets.

**Sequence:**
1. Unit tests for HealthSyncManager import
2. Unit tests for SharedModelContainer
3. Widget snapshot tests
4. UI tests for share flow

**Dependencies:**
- All features must be implemented
- MockHealthStore already exists

---

## Architecture Considerations

### App Group Migration Risk
**Risk:** Existing users have data in standard container location.

**Mitigation:**
```swift
// In W8TrackrApp.swift, on first launch after update:
1. Check if standard container has data
2. If yes, copy to App Group location
3. Mark migration complete in UserDefaults
```

The `SharedModelContainer.migratePreferencesToSharedDefaults()` contract handles preferences but NOT SwiftData. SwiftData migration needs explicit handling.

### Widget Memory Constraints
**Constraint:** Widgets have strict memory limits (~30MB).

**Mitigation:**
- Fetch only most recent entry in provider
- Keep view hierarchy simple
- Avoid loading images in widget
- Use `TimelineReloadPolicy.after()` not continuous refresh

### HealthKit Background Delivery
**Consideration:** For real-time sync, enable background delivery.

**Trade-off:**
- Adds complexity (BGTaskScheduler integration)
- Battery impact
- User expectation: Most users check app periodically

**Recommendation:** Skip background delivery for v1.1. Manual "Sync Now" in Settings suffices.

---

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| HealthKit Import | HIGH | Existing HealthSyncManager patterns, WeightEntry already has sync fields |
| Widget Extension | HIGH | Contracts already defined, standard WidgetKit patterns |
| Image Sharing | HIGH | ImageRenderer is well-documented, straightforward implementation |
| Localization | HIGH | Standard Xcode String Catalog workflow |
| App Group Migration | MEDIUM | Need to verify SwiftData container migration path |

---

## Sources

- Existing codebase analysis (primary source)
- `specs/004-ios-widget/contracts/` - Widget architecture contracts
- `specs/003-social-sharing/contracts/` - Sharing contracts
- Apple HealthKit documentation (implicit, not fetched)
- Apple WidgetKit documentation (implicit, not fetched)
