# Swift Rules

## Platform & Version Requirements
- Target iOS 26.0+ and Swift 6.2+
- Use modern Swift concurrency exclusively

## Concurrency
- Mark all `@Observable` classes with `@MainActor`
- Enforce strict Swift concurrency throughout the codebase
- Never use Grand Central Dispatch patterns like `DispatchQueue.main.async()`
- Use `async`/`await` for all asynchronous operations

## Error Handling & Safety
- No force unwraps (`!`) unless the situation is unrecoverable
- No force `try` unless the failure is unrecoverable
- Handle errors gracefully with proper `do`/`catch` blocks

## String Methods
- Use `replacing("old", with: "new")` instead of `replacingOccurrences(of:with:)`
- Use `localizedStandardContains()` for text filtering instead of `contains()`
- Prefer Swift-native string methods over Foundation equivalents

## Number Formatting
- Use `Text(value, format: .number.precision(.fractionLength(2)))` instead of C-style formatting
- Leverage Swift's built-in formatters

## Foundation APIs
- Use `URL.documentsDirectory` for the app's documents folder
- Use `appending(path:)` to construct URL paths
- Prefer Swift-native alternatives to Foundation methods where available

## Project Organization
- Maintain feature-based folder structure
- Place each type (struct, class, enum) in its own Swift file
- Write unit tests for core logic; UI tests only when necessary
- Exclude secrets and API keys from repositories
