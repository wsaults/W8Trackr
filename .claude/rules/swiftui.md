# SwiftUI Conventions

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
