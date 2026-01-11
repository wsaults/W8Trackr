# W8Trackr Coding Standards

Swift coding standards for this project, based on [twostraws/SwiftAgents](https://github.com/twostraws/SwiftAgents/blob/main/AGENTS.md).

## Platform Requirements

- **iOS**: 26.0+
- **Swift**: 6.2+
- **Concurrency**: Strict Swift concurrency only (no GCD)
- **Third-party frameworks**: Not allowed without explicit approval

## Architecture

- Mark all `@Observable` classes with `@MainActor`
- Never use `ObservableObject` - use `@Observable` instead
- Avoid UIKit unless specifically requested
- Place view logic in view models for testability

## Swift Language

### String & Number Handling
- Prefer `replacing(_:with:)` over Foundation alternatives
- Use `Text(value, format: .number.precision(.fractionLength(2)))` not `String(format:)`
- Use `localizedStandardContains()` for user-input text filtering

### Modern APIs
- Use `URL.documentsDirectory` and `appending(path:)` for file paths
- Prefer static member lookup (`.circle`) over struct instances (`Circle()`)
- Avoid force unwraps and force `try` except for unrecoverable errors

## SwiftUI

### Deprecated Patterns to Replace
| Deprecated | Use Instead |
|------------|-------------|
| `foregroundColor()` | `foregroundStyle()` |
| `cornerRadius()` | `clipShape(.rect(cornerRadius:))` |
| `NavigationView` | `NavigationStack` + `navigationDestination(for:)` |
| `ObservableObject` | `@Observable` |
| `onTapGesture()` for buttons | `Button` (unless location/tap count needed) |
| `tabItem()` | `Tab` API |
| Single-param `onChange()` | Two-param version |
| `Task.sleep(nanoseconds:)` | `Task.sleep(for:)` |
| `GeometryReader` | `containerRelativeFrame()` / `visualEffect()` |
| `UIGraphicsImageRenderer` | `ImageRenderer` |

### Layout & Styling
- Avoid hard-coded padding/spacing values
- Prefer Dynamic Type over fixed font sizes
- Use `bold()` instead of `fontWeight(.bold)`
- Use `.scrollIndicators(.hidden)` for hiding scroll indicators
- Button images must include text labels

### View Structure
- Extract computed property views into separate `View` structs
- Don't convert `enumerated()` sequences to arrays in `ForEach`
- Avoid `AnyView` unless absolutely necessary
- Avoid `UIScreen.main.bounds`

## SwiftData with CloudKit

**Required for CloudKit compatibility:**
- Never use `@Attribute(.unique)`
- All properties require default values OR be optional
- All relationships must be optional

## Code Quality

- SwiftLint must pass with zero warnings before committing
- Keep structs/classes/enums in separate files
- Write unit tests for core logic; UI tests only when necessary
- Never commit API keys or secrets

## Project Structure

Organize by app features with consistent folder layout:
```
W8Trackr/
├── Features/
│   ├── Onboarding/
│   ├── Dashboard/
│   └── Settings/
├── Models/
├── Services/
└── Shared/
```

## Build & Test Commands

```bash
# Build
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -configuration Debug -sdk iphonesimulator build

# Run all tests
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -sdk iphonesimulator test

# Run specific test class
xcodebuild -project W8Trackr.xcodeproj -scheme W8Trackr -sdk iphonesimulator \
  -only-testing:W8TrackrTests/W8TrackrTests test
```
