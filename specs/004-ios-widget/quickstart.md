# Quickstart: iOS Home Screen Widget

**Feature Branch**: `004-ios-widget`
**Created**: 2025-01-09

## Prerequisites

- Xcode 16+ with iOS 18 SDK
- W8Trackr project builds successfully
- Familiarity with WidgetKit concepts

## Implementation Steps

### Step 1: Add Widget Extension Target

1. In Xcode, select **File → New → Target**
2. Choose **Widget Extension** under iOS
3. Name it `W8TrackrWidget`
4. Uncheck "Include Configuration App Intent" (using static configuration)
5. Click **Finish**

### Step 2: Configure App Groups

Both targets need the same App Group:

1. Select **W8Trackr** target → Signing & Capabilities
2. Click **+ Capability** → **App Groups**
3. Add group: `group.com.yourcompany.W8Trackr`
4. Repeat for **W8TrackrWidget** target

### Step 3: Create Shared Folder

Create `Shared/` folder at project root with shared code:

```
Shared/
├── DataAccess/
│   └── SharedModelContainer.swift
└── Extensions/
    └── WeightEntry+Widget.swift
```

Add these files to **both** targets in Xcode.

### Step 4: Share WeightEntry Model

Add `W8Trackr/Models/WeightEntry.swift` to the widget target:

1. Select `WeightEntry.swift` in Project Navigator
2. Show File Inspector (⌘⌥1)
3. Under Target Membership, check **W8TrackrWidget**

### Step 5: Update Main App

1. Replace `.modelContainer(for:)` with shared container
2. Add preference migration on launch
3. Call `reloadWidgetTimeline()` after data changes

```swift
// W8TrackrApp.swift
@main
struct W8TrackrApp: App {
    init() {
        SharedModelContainer.migratePreferencesToSharedDefaults()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
```

### Step 6: Implement Widget Views

Create size-specific views:

```swift
// SmallWidgetView.swift
struct SmallWidgetView: View {
    let entry: WeightWidgetEntry

    var body: some View {
        VStack(alignment: .leading) {
            if let weight = entry.currentWeight {
                Text("\(weight, specifier: "%.1f") \(entry.weightUnit.rawValue)")
                    .font(.title)
                    .fontWeight(.bold)
            } else {
                Text("No data")
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(DeepLinkRoute.addWeight.url)
    }
}
```

### Step 7: Configure URL Scheme

Add to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>w8trackr</string>
        </array>
    </dict>
</array>
```

### Step 8: Handle Deep Links

Update `ContentView` to handle widget taps:

```swift
ContentView()
    .onOpenURL { url in
        if let route = DeepLinkHandler.route(for: url) {
            navigationState.navigate(to: route)
        }
    }
```

## Testing

### Widget Preview in Xcode

```swift
#Preview(as: .systemSmall) {
    W8TrackrWidget()
} timeline: {
    WeightWidgetEntry(date: .now, currentWeight: 175.0, weightUnit: .lb, goalWeight: 160.0, entryDate: .now, trend: .down)
    WeightWidgetEntry(date: .now, currentWeight: nil, weightUnit: .lb, goalWeight: nil, entryDate: nil, trend: .unknown)
}
```

### Simulator Testing

1. Run the main app target first (initializes shared container)
2. Add a weight entry
3. Run the widget extension target
4. Add widget from home screen widget gallery
5. Tap widget to verify deep link

### Test Cases

| Scenario | Expected |
|----------|----------|
| No entries | Empty state message |
| Has entries, no goal | Weight only, no progress |
| Has entries and goal | Weight + goal progress |
| Tap widget | Opens app to add weight |
| Change unit in app | Widget updates on next refresh |

## Troubleshooting

### Widget shows stale data
- Ensure `reloadWidgetTimeline()` is called after data changes
- Check App Group is configured on both targets

### Widget shows "No data" unexpectedly
- Verify shared container uses same App Group identifier
- Check `WeightEntry.swift` is in widget target membership

### Deep link doesn't work
- Verify URL scheme in `Info.plist`
- Check `onOpenURL` handler is at root of view hierarchy

## Files to Create

| File | Target | Purpose |
|------|--------|---------|
| `Shared/DataAccess/SharedModelContainer.swift` | Both | Shared container config |
| `W8TrackrWidget/W8TrackrWidget.swift` | Widget | Widget entry point |
| `W8TrackrWidget/Provider/WeightWidgetProvider.swift` | Widget | Timeline provider |
| `W8TrackrWidget/Views/SmallWidgetView.swift` | Widget | Small layout |
| `W8TrackrWidget/Views/MediumWidgetView.swift` | Widget | Medium layout |
| `W8TrackrWidget/Models/WidgetEntry.swift` | Widget | Timeline entry |

## Success Criteria Checklist

- [ ] Widget appears in widget gallery
- [ ] Small widget shows current weight
- [ ] Medium widget shows weight + action button
- [ ] Widget updates when weight is logged
- [ ] Tapping widget opens add weight screen
- [ ] Light/dark mode works correctly
- [ ] Empty state displays correctly
