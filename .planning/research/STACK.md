# Stack Research: v1.1

**Project:** W8Trackr
**Researched:** 2026-01-22
**Mode:** Ecosystem (Stack dimension for new features)
**Overall Confidence:** HIGH

## Executive Summary

v1.1 requires five new capabilities: HealthKit read (import), WidgetKit widgets, image generation for sharing, Spanish localization, and test coverage. All can be achieved with Apple's first-party frameworks - no third-party dependencies needed. The existing architecture (SwiftUI + SwiftData + strict concurrency) integrates cleanly with these additions.

---

## New Capabilities Required

### 1. HealthKit Read (Import Weight from Apple Health)

**Current State:** App has HealthKit WRITE (export) only. `HealthKitManager.swift` requests `toShare` permissions but passes `read: nil`.

**Required Changes:**

| Component | Current | Required for v1.1 |
|-----------|---------|-------------------|
| Authorization | `toShare: [bodyMass, bodyFatPercentage]` | Add `read: [bodyMass, bodyFatPercentage]` |
| Query API | None | `HKAnchoredObjectQuery` for incremental sync |
| Info.plist | `NSHealthShareUsageDescription` present | Already configured |
| Privacy | Write-only | Read requires separate user consent |

**API Selection - HKAnchoredObjectQuery vs HKSampleQuery:**

| Criterion | HKSampleQuery | HKAnchoredObjectQuery | Recommendation |
|-----------|--------------|----------------------|----------------|
| Initial fetch | Snapshot | Snapshot + anchor | - |
| Subsequent syncs | Full re-fetch | Delta only (new/deleted) | Anchored wins |
| Deleted detection | Not supported | Built-in `deletedObjects` | Anchored wins |
| Sorting | Supported | Not supported | Sample wins |
| Persistence | N/A | Anchor persists via NSSecureCoding | Anchored wins |

**Recommendation:** Use `HKAnchoredObjectQuery` because:
1. Weight import is an ongoing sync, not one-time fetch
2. Detecting deletions prevents duplicates when user removes entries in Health app
3. Anchor persistence enables efficient incremental syncs on app launch
4. Sorting not critical - app can sort after fetch

**Key Implementation Pattern:**

```swift
// Request BOTH read and write
let typesToRead: Set<HKObjectType> = [bodyMassType, bodyFatType]
let typesToWrite: Set<HKSampleType> = [bodyMassType, bodyFatType]
try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

// Create anchored query
let anchor = loadPersistedAnchor() // From UserDefaults or file
let query = HKAnchoredObjectQuery(
    type: bodyMassType,
    predicate: nil,
    anchor: anchor,
    limit: HKObjectQueryNoLimit
) { query, addedSamples, deletedObjects, newAnchor, error in
    // Process addedSamples - create WeightEntry for each
    // Process deletedObjects - remove matching WeightEntry
    // Persist newAnchor for next sync
}
healthStore.execute(query)
```

**Privacy Consideration (HIGH confidence - Apple docs):**
Read authorization status is NEVER exposed to apps. When read access is denied:
- Queries return empty results (same as empty Health database)
- App cannot distinguish "denied" from "no data"
- This protects user health tracking habits from inference attacks

**Confidence:** HIGH (verified via Apple documentation and existing codebase patterns)

---

### 2. WidgetKit (Home Screen Widgets)

**Framework:** WidgetKit (iOS 14+, current: iOS 26)

**Required Widget Families:**

| Family | Size | Purpose | Priority |
|--------|------|---------|----------|
| `systemSmall` | 2x2 icon grid | Current weight + trend arrow | MVP |
| `systemMedium` | 4x2 icon grid | Weight + goal progress | MVP |
| `accessoryCircular` | Lock screen circle | Current weight only | Nice-to-have |
| `accessoryRectangular` | Lock screen rectangle | Weight + mini trend | Nice-to-have |

**iOS 26 WidgetKit Features (WWDC 2025):**

| Feature | Description | Applicability |
|---------|-------------|---------------|
| Glass presentation | Automatic glass/tint on Home Screen | Automatic - no code needed |
| Push updates | Server-push widget refresh | Not needed - local data only |
| Interactive widgets | Tap actions within widget | Could enable quick log button |
| Relevance widgets (watchOS) | Smart Stack appearance | Future - watchOS extension |

**Architecture Requirements:**

1. **App Group** - Share data between main app and widget extension
   - Identifier: `group.com.w8trackr.shared`
   - Both targets must have App Groups capability

2. **Shared ModelContainer** - SwiftData access from widget
   ```swift
   // SharedModelContainer.swift (in shared framework or both targets)
   @MainActor
   struct SharedModelContainer {
       static let shared: ModelContainer = {
           let schema = Schema([WeightEntry.self])
           let config = ModelConfiguration(
               schema: schema,
               url: FileManager.default
                   .containerURL(forSecurityApplicationGroupIdentifier: "group.com.w8trackr.shared")!
                   .appending(path: "W8Trackr.store"),
               cloudKitDatabase: .automatic
           )
           return try! ModelContainer(for: schema, configurations: config)
       }()
   }
   ```

3. **Timeline Refresh** - Trigger from main app when data changes
   ```swift
   import WidgetKit
   WidgetCenter.shared.reloadAllTimelines()
   ```

**Widget Extension Target Setup:**

| Setting | Value |
|---------|-------|
| Extension type | Widget Extension |
| Include Configuration Intent | No (static widget first) |
| Deployment target | iOS 26.0 |
| Embed in Application | W8Trackr |

**Confidence:** HIGH (Apple documentation + existing spec contracts in codebase)

---

### 3. Image Generation (Social Sharing)

**Framework:** SwiftUI `ImageRenderer` (iOS 16+)

**Current State:** Contract exists at `specs/003-social-sharing/contracts/ProgressImageRenderer.swift`

**API Usage:**

```swift
@MainActor
static func renderMilestoneImage(/* params */) -> UIImage? {
    let view = MilestoneGraphicView(/* params */)
    let renderer = ImageRenderer(content: view)
    renderer.scale = UIScreen.main.scale  // Critical for crisp images
    return renderer.uiImage
}
```

**Key Considerations:**

| Aspect | Recommendation | Rationale |
|--------|---------------|-----------|
| Scale | `UIScreen.main.scale` | 2x/3x for retina displays |
| Size | 600x315 (1.91:1 ratio) | Optimal for social media |
| Thread | `@MainActor` required | ImageRenderer is main-thread only |
| Limitations | No WebView/MapView | Pure SwiftUI only (OK for this use case) |

**Sharing Implementation:**

```swift
let activityVC = UIActivityViewController(
    activityItems: [image, shareText],
    applicationActivities: nil
)
// Present via UIViewControllerRepresentable or ShareLink
```

**Alternative - ShareLink (iOS 16+):**
```swift
ShareLink(
    item: image,
    preview: SharePreview("My Progress", image: Image(uiImage: image))
) {
    Label("Share", systemImage: "square.and.arrow.up")
}
```

**Confidence:** HIGH (ImageRenderer is stable, contract already defined)

---

### 4. Localization (Spanish)

**Framework:** Xcode String Catalogs (`.xcstrings`) - Xcode 15+

**Current State:** No localization files exist. App is English-only.

**Recommended Approach:**

1. **Create String Catalog** - `Localizable.xcstrings` in main target
2. **Build to extract** - Xcode auto-discovers strings from SwiftUI views
3. **Add Spanish** - Add `es` locale in catalog
4. **Export for translation** - `.xcloc` format for translators

**String Catalog Benefits:**

| Feature | Benefit |
|---------|---------|
| Automatic extraction | No manual key management |
| Built-in pluralization | Handle "1 pound" vs "2 pounds" |
| State tracking | NEW, STALE, NEEDS REVIEW markers |
| Type safety (Xcode 26) | Compiler enforces format specifiers |

**SwiftUI Auto-Localization:**

Most SwiftUI views auto-localize:
```swift
Text("Current Weight")           // Auto-extracted
Button("Save") { }               // Auto-extracted
Label("Goal", systemImage: "...")  // Auto-extracted
```

Explicit localization for dynamic strings:
```swift
Text(weight, format: .number)    // Numbers auto-format per locale
String(localized: "entries_count \(count)")  // Explicit key
```

**Files to Create:**

| File | Purpose |
|------|---------|
| `Localizable.xcstrings` | Main strings catalog |
| `InfoPlist.xcstrings` | App name, permission descriptions |

**Localization-Sensitive UI:**

| Area | Consideration |
|------|---------------|
| Weight units | Already supports lb/kg |
| Date formats | Use `.formatted()` - auto-localizes |
| Numbers | Use `Text(value, format:)` - auto-localizes |
| Plurals | String catalog handles automatically |
| RTL | Not needed for Spanish |

**Confidence:** HIGH (String Catalogs are mature, well-documented)

---

### 5. Testing (Unit + UI Tests)

**Current State:**
- Using Swift Testing framework (`@Test`, `#expect`)
- 6 test files exist with good coverage of TrendCalculator, HealthSyncManager
- Mock patterns established (`MockHealthStore`)

**Framework:** Swift Testing (preferred) + XCTest (UI tests only)

**Swift Testing vs XCTest:**

| Feature | Swift Testing | XCTest | Use |
|---------|--------------|--------|-----|
| Test declaration | `@Test func` | `func test...()` | Swift Testing preferred |
| Assertions | `#expect(...)` | `XCTAssert...()` | Swift Testing preferred |
| Parallelization | Default parallel | Opt-in | Swift Testing wins |
| Test container | `struct` | `class: XCTestCase` | Swift Testing wins |
| UI Testing | Not supported | Supported | XCTest required |
| Performance | Not supported | `XCTMetric` | XCTest required |

**Recommendation:**
- **Unit tests:** Swift Testing (`@Test`, `#expect`)
- **UI tests:** XCTest (`XCUIApplication`)
- **Widget tests:** Unit test `TimelineProvider` with Swift Testing

**SwiftData Testing Pattern (in-memory):**

```swift
@MainActor
struct WeightEntryTests {

    private func makeTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: WeightEntry.self, configurations: config)
    }

    @Test func entryPersistsCorrectly() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let entry = WeightEntry(weight: 175.0)
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WeightEntry>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.weightValue == 175.0)
    }
}
```

**Test Coverage Targets:**

| Area | Current | Target | Priority |
|------|---------|--------|----------|
| TrendCalculator | Covered | Maintain | - |
| HealthSyncManager | Covered | Extend for read | HIGH |
| WeightEntry model | Covered | Maintain | - |
| HealthKit import | None | New tests | HIGH |
| Widget provider | None | New tests | MEDIUM |
| Image rendering | None | New tests | LOW |
| Localization | None | Snapshot tests | LOW |

**UI Test Strategy:**

```swift
// W8TrackrUITests/WidgetUITests.swift
import XCTest

final class WidgetUITests: XCTestCase {

    func testWidgetDisplaysWeight() throws {
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing"]  // Triggers in-memory SwiftData
        app.launch()

        // Widget testing requires manual verification or snapshot testing
        // XCUITest cannot directly access widget extension
    }
}
```

**Confidence:** HIGH (existing test patterns are solid, Swift Testing is mature)

---

## Integration Notes

### How Features Interact with Existing Architecture

| New Feature | Existing Component | Integration Point |
|-------------|-------------------|-------------------|
| HealthKit Read | HealthKitManager | Extend with query methods |
| HealthKit Read | WeightEntry | Use existing `source` field for import tracking |
| Widgets | SwiftData | App Groups + shared container |
| Widgets | TrendCalculator | Reuse for widget trend display |
| Image Sharing | WeightTrendChartView | Render existing chart views |
| Localization | All Views | SwiftUI auto-localizes, minimal changes |
| Testing | Existing tests | Follow established patterns |

### SwiftData + App Groups Migration

**Important:** Existing data must migrate to shared container location.

```swift
// One-time migration check in W8TrackrApp.swift
@MainActor
private func migrateToSharedContainerIfNeeded() {
    let oldURL = URL.applicationSupportDirectory.appending(path: "W8Trackr.store")
    let newURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.w8trackr.shared")!
        .appending(path: "W8Trackr.store")

    guard FileManager.default.fileExists(atPath: oldURL.path),
          !FileManager.default.fileExists(atPath: newURL.path) else { return }

    try? FileManager.default.moveItem(at: oldURL, to: newURL)
}
```

---

## What NOT to Add

| Excluded | Rationale |
|----------|-----------|
| Third-party HealthKit wrappers | Apple's API is sufficient, no abstraction needed |
| Combine for reactive updates | Project uses strict async/await concurrency |
| Core Data | SwiftData is already in use, no migration needed |
| Third-party localization tools | String Catalogs are superior |
| Third-party charting libraries | SwiftUI Charts already in use |
| Snapshot testing frameworks | XCTest attachments sufficient for UI verification |
| Widget configuration intents | Start with static widgets, add later if needed |
| React Native / Flutter | Project is pure Swift, stay native |

---

## Version Requirements Summary

| Technology | Minimum Version | Current in Project | Notes |
|------------|-----------------|-------------------|-------|
| iOS | 26.0 | 26.0 | All features available |
| Swift | 6.2 | 6.2 | Strict concurrency |
| WidgetKit | iOS 14+ | iOS 26 | Glass presentation automatic |
| ImageRenderer | iOS 16+ | iOS 26 | Fully supported |
| String Catalogs | Xcode 15+ | Xcode 26 | Type-safe symbols available |
| Swift Testing | Xcode 16+ | Xcode 26 | Preferred over XCTest |
| HKAnchoredObjectQuery | iOS 8+ | iOS 26 | Mature API |

---

## Sources

### HealthKit
- [HKSampleQuery - Apple Developer Documentation](https://developer.apple.com/documentation/healthkit/hksamplequery)
- [HKAnchoredObjectQuery Tutorial - DevFright](https://www.devfright.com/how-to-use-healthkit-hkanchoredobjectquery/)
- [HealthKit Tutorial Fetch Weight - DevFright](https://www.devfright.com/healthkit-tutorial-fetch-weight-data-swift/)
- [Authorizing Access to Health Data - Apple](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- [Managing Permissions with HealthKit - Cocoacasts](https://cocoacasts.com/managing-permissions-with-healthkit)

### WidgetKit
- [What's New in Widgets - WWDC25](https://developer.apple.com/videos/play/wwdc2025/278/)
- [WidgetKit - Apple Developer Documentation](https://developer.apple.com/documentation/widgetkit)
- [How to Access SwiftData from Widgets - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets)
- [SwiftData with Widgets - Medium](https://medium.com/@rishixcode/swiftdata-with-widgets-in-swiftui-0aab327a35d8)

### ImageRenderer
- [ImageRenderer - Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/imagerenderer)
- [How to Convert SwiftUI View to Image - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image)
- [ImageRenderer in SwiftUI - Swift with Majid](https://swiftwithmajid.com/2023/04/18/imagerenderer-in-swiftui/)

### Localization
- [Localizing with String Catalogs - Apple Developer Documentation](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [Explore Localization with Xcode - WWDC25](https://developer.apple.com/videos/play/wwdc2025/225/)
- [Swift Localization Best Practices 2025 - Fline](https://www.fline.dev/swift-localization-in-2025-best-practices-you-couldnt-use-before/)

### Testing
- [Swift Testing - Apple Developer](https://developer.apple.com/xcode/swift-testing)
- [How to Write Unit Tests for SwiftData - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code)
- [Modern Swift Unit Testing - Avanderlee](https://www.avanderlee.com/swift-testing/modern-unit-test/)
