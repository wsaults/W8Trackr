# SwiftUI Architecture Rules

## Navigation

Use **NavigationStack** (not NavigationView):

```swift
NavigationStack {
    content
        .navigationTitle("Title")
        .navigationBarTitleDisplayMode(.inline)
}
```

NavigationView is deprecated. Always use NavigationStack for new views.

## State Management

### Property Wrappers

| Wrapper | Use Case |
|---------|----------|
| `@State` | View-local mutable state |
| `@Binding` | Two-way binding from parent |
| `@Environment` | System/context values (dismiss, modelContext) |
| `@StateObject` | ObservableObject owned by this view |
| `@ObservedObject` | ObservableObject passed from parent |
| `@AppStorage` | UserDefaults-backed persistence |

### Patterns

```swift
// View-local state
@State private var showAddWeightView = false

// Passed from parent
var entries: [WeightEntry]
var preferredWeightUnit: WeightUnit

// Two-way binding
@Binding var weightUnit: WeightUnit

// System values
@Environment(\.dismiss) private var dismiss
@Environment(\.modelContext) private var modelContext

// Observable managers
@StateObject private var notificationManager = NotificationManager()
```

## View Composition

### Computed View Properties

Extract complex sections into computed properties:

```swift
struct SettingsView: View {
    private var weightSettingsSection: some View {
        Section {
            // Content
        } header: {
            Text("Weight Settings")
        }
    }

    private var dangerZoneSection: some View {
        Section {
            // Content
        } header: {
            Text("Danger Zone")
        }
    }

    var body: some View {
        Form {
            weightSettingsSection
            reminderSection
            dangerZoneSection
        }
    }
}
```

### Empty States

Use ContentUnavailableView for empty collections:

```swift
if entries.isEmpty {
    ContentUnavailableView(
        "Start Tracking!",
        systemImage: "person.badge.plus",
        description: Text("Tap the + button to track your weight")
    )
}
```

## Forms and Settings

Structure with Sections:

```swift
Form {
    Section {
        // Controls
    } header: {
        Text("Section Header")
    } footer: {
        Text("Helpful description for the user.")
    }
}
```

## Sheets and Modals

```swift
@State private var showAddWeightView = false

// In body
.sheet(isPresented: $showAddWeightView) {
    AddWeightView(entries: entries, weightUnit: preferredWeightUnit)
}
```

## Alerts

Use the modern alert API:

```swift
.alert("Delete All Entries", isPresented: $showingDeleteAlert) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        // Action
    }
} message: {
    Text("Are you sure?")
}
```

## onChange Modifier

Use the modern two-parameter closure:

```swift
.onChange(of: weightUnit) { oldValue, newValue in
    // React to change
}
```

## Previews (iOS 18+)

### Required Pattern

All previews MUST:
1. Be wrapped in `#if DEBUG` / `#endif`
2. Use `@available(iOS 18, macOS 15, *)`
3. Use PreviewModifier from `Preview Content/PreviewModifiers.swift`
4. Include at least: populated state + empty state

### Available Preview Modifiers

| Modifier | Description |
|----------|-------------|
| `EntriesPreview` | Full sample data (30+ entries) |
| `EmptyEntriesPreview` | Empty state (no data) |
| `MinimalEntriesPreview` | Sparse data (3 entries) |
| `ShortSamplePreview` | Short sample (7 days) |
| `ContentViewPreview` | For ContentView with `isEmpty` option |
| `SettingsViewPreview` | For SettingsView with `withSampleData` option |
| `DashboardPreview` | For DashboardView |

### Example

```swift
#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("Populated", traits: .modifier(EntriesPreview())) {
    YourView()
}

@available(iOS 18, macOS 15, *)
#Preview("Empty", traits: .modifier(EmptyEntriesPreview())) {
    YourView()
}
#endif
```

### Configurable Preview Modifiers

Some modifiers accept configuration options:

```swift
// ContentView with empty state
@available(iOS 18, macOS 15, *)
#Preview("Empty", traits: .modifier(ContentViewPreview(isEmpty: true))) {
    ContentView()
}

// SettingsView with sample data
@available(iOS 18, macOS 15, *)
#Preview("With Data", traits: .modifier(SettingsViewPreview(withSampleData: true))) {
    SettingsView(...)
}
```

### Why PreviewModifier?

- **Shared Context**: `makeSharedContext()` creates a single ModelContainer shared across previews
- **Async Support**: Properly handles async model setup
- **Type Safety**: Swift compiler enforces correct usage
- **Reusability**: Define once, use across all views

### Creating New Preview Modifiers

When creating a view-specific preview modifier:

```swift
#if DEBUG
@available(iOS 18, macOS 15, *)
struct MyViewPreview: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(
            for: WeightEntry.self, CompletedMilestone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        // Insert test data as needed
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}
#endif
```

## Layout Patterns

### ZStack for Overlays

```swift
ZStack(alignment: .bottom) {
    VStack { /* Main content */ }
    FloatingActionButton()  // Overlaid at bottom
}
```

### ScrollView with Content

```swift
ScrollView {
    ChartSectionView(entries: entries, goalWeight: goalWeight, weightUnit: preferredWeightUnit)
}
```

## Styling

- Use semantic colors: `.gray.opacity(0.1)` for subtle backgrounds
- Use SF Symbols: `Image(systemName: "plus")`
- Use `.clipShape(.circle)` for circular buttons
