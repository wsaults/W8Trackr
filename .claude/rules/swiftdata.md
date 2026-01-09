# SwiftData Patterns

## Model Definition

Use `@Model` macro for persistent models:

```swift
import SwiftData

@Model
final class WeightEntry {
    var weightValue: Double = 0
    var weightUnit: String = WeightUnit.lb.rawValue
    var date: Date = Date.now
    var note: String?
    var bodyFatPercentage: Decimal?

    init(weight: Double, unit: UnitMass = .pounds, date: Date = .now, note: String? = nil, bodyFatPercentage: Decimal? = nil) {
        self.weightValue = weight
        self.weightUnit = unit.symbol
        self.date = date
        self.note = note
        self.bodyFatPercentage = bodyFatPercentage
    }
}
```

### Key Points

- Use `final class` with `@Model`
- Provide default values for all stored properties
- Use explicit initializer for convenient construction
- Optionals don't need defaults (implicitly nil)

## Container Configuration

Configure at the app level:

```swift
@main
struct W8TrackrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WeightEntry.self])
    }
}
```

## Querying Data

Use `@Query` for automatic fetching and updates:

```swift
struct ContentView: View {
    @Query(sort: \WeightEntry.date, order: .reverse) var entries: [WeightEntry]

    var body: some View {
        List(entries) { entry in
            // Display entry
        }
    }
}
```

### Query with Predicates

```swift
@Query(filter: #Predicate<WeightEntry> { entry in
    entry.date >= startDate
}, sort: \WeightEntry.date, order: .reverse)
var recentEntries: [WeightEntry]
```

## Mutations

Access modelContext via Environment:

```swift
@Environment(\.modelContext) private var modelContext

// Insert
let entry = WeightEntry(weight: 175.0, unit: .pounds)
modelContext.insert(entry)

// Delete
modelContext.delete(entry)

// Save (usually automatic, but can be explicit)
try modelContext.save()
```

### Batch Operations

```swift
func deleteAllEntries() throws {
    let entries = try modelContext.fetch(FetchDescriptor<WeightEntry>())
    for entry in entries {
        modelContext.delete(entry)
    }
    try modelContext.save()
}
```

## FetchDescriptor

For complex fetches outside @Query:

```swift
let descriptor = FetchDescriptor<WeightEntry>(
    predicate: #Predicate { $0.date >= startDate },
    sortBy: [SortDescriptor(\.date, order: .reverse)]
)
let entries = try modelContext.fetch(descriptor)
```

## Sample Data

Include static sample data in models for previews and testing:

```swift
@Model
final class WeightEntry {
    // ... properties and init ...

    // MARK: - Sample Data

    static var sampleData: [WeightEntry] {
        [
            WeightEntry(weight: 200.0, date: Date(), note: "Starting weight"),
            WeightEntry(weight: 198.5, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
            // ...
        ]
    }

    static var sortedSampleData: [WeightEntry] {
        sampleData.sorted { $0.date > $1.date }
    }
}
```

## Preview Configuration

Use in-memory containers for previews:

```swift
struct EntriesPreview: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(
            for: WeightEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        WeightEntry.sampleData.forEach { example in
            container.mainContext.insert(example)
        }
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}
```

## Data Conversion

Store raw values, convert at display time:

```swift
@Model
final class WeightEntry {
    var weightValue: Double = 0
    var weightUnit: String = "lb"  // Store as string

    func weightValue(in unit: WeightUnit) -> Double {
        let currentUnit = WeightUnit(rawValue: weightUnit) ?? .lb
        return weightValue.weightValue(from: currentUnit, to: unit)
    }
}
```

This approach:
- Preserves original input values
- Supports unit preference changes without data migration
- Converts on-demand for display

## Relationships

For related models (not used in this app yet, but for reference):

```swift
@Model
final class User {
    var name: String
    @Relationship(deleteRule: .cascade) var entries: [WeightEntry]
}
```

## DO NOT Use

- Core Data (NSManagedObject, NSPersistentContainer)
- Manual NSPredicate (use #Predicate macro)
- Fetch requests outside @Query unless necessary
