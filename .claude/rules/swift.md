# Swift Language Patterns

## File Headers

Use standard Xcode header format:
```swift
//
//  FileName.swift
//  W8Trackr
//
//  Created by Author on M/D/YY.
//
```

## Enums

Prefer enums for type-safe constants and domain values:

```swift
// Good: Enum with computed properties
enum WeightUnit: String, CaseIterable {
    case lb, kg

    var defaultWeight: Double {
        switch self {
        case .lb: return 180.0
        case .kg: return 80.0
        }
    }
}
```

- Use `CaseIterable` when iterating over all cases (pickers, lists)
- Use `String` raw values when persisting or displaying
- Add computed properties for derived values

## Extensions

Use extensions to add functionality to existing types:

```swift
extension Double {
    func weightValue(from: WeightUnit, to unit: WeightUnit) -> Double {
        // Conversion logic
    }
}
```

Keep extensions in the same file as related domain logic.

## Optionals

- Use `guard let` for early returns
- Prefer `if let` for conditional unwrapping in local scope
- Use `??` for sensible defaults: `WeightUnit(rawValue: value) ?? .lb`

## MARK Comments

Use `// MARK: -` to organize code sections:

```swift
// MARK: - Sample Data
// MARK: - Private Methods
// MARK: - Computed Properties
```

## Naming Conventions

- Types: `PascalCase` (WeightEntry, NotificationManager)
- Properties/Methods: `camelCase` (weightValue, getReminderTime)
- Constants: `camelCase` in context, or `SCREAMING_SNAKE` for global constants
- Booleans: Prefix with `is`, `has`, `should` (isReminderEnabled)

## Type Inference

Let Swift infer types when obvious:
```swift
// Good
let entries = [WeightEntry]()
var showAlert = false

// Avoid unnecessary type annotations
let entries: [WeightEntry] = [WeightEntry]()  // Redundant
```

## Access Control

- Default to internal (implicit)
- Use `private` for implementation details
- Use `private(set)` for read-only external access

## Error Handling

Use do-catch for recoverable errors:
```swift
do {
    try modelContext.save()
} catch {
    print("Failed to save: \(error)")
}
```
