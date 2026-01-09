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

Use PreviewModifier for complex preview setup:

```swift
@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(EntriesPreview())) {
    @Previewable @Query var entries: [WeightEntry]
    SummaryView(entries: entries, preferredWeightUnit: .lb, goalWeight: 160)
}

struct EntriesPreview: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(
            for: WeightEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        WeightEntry.sampleData.forEach { container.mainContext.insert($0) }
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}
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
