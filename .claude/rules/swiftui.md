# SwiftUI Rules

## Deprecated API Migrations
Replace these deprecated patterns with modern equivalents:

| Deprecated | Modern |
|------------|--------|
| `foregroundColor()` | `foregroundStyle()` |
| `cornerRadius()` | `clipShape(.rect(cornerRadius:))` |
| `NavigationView` | `NavigationStack` |
| `ObservableObject` | `@Observable` |
| `fontWeight(.bold)` | `bold()` |
| `showsIndicators: false` | `.scrollIndicators(.hidden)` |
| `Task.sleep(nanoseconds:)` | `Task.sleep(for:)` |
| `tabItem()` | Modern `Tab` API |

## Navigation
- Use `NavigationStack` with `navigationDestination(for:)` for type-safe routing
- Never use deprecated `NavigationView`

## State Management
- Use `@Observable` classes exclusively
- Never use `ObservableObject` or `@Published`
- Move view logic into view models for testability

## Interactions
- Use `Button` for tap interactions, not `onTapGesture()`
- Only use `onTapGesture()` when you need tap location or count
- Always include text labels with image buttons: `Button("Label", systemImage: "icon", action: myAction)`

## Layout
- Prefer `containerRelativeFrame()` or `visualEffect()` over `GeometryReader`
- Never use `UIScreen.main.bounds` for available space calculations
- Avoid hard-coded padding and spacing values unless specified

## Typography & Sizing
- Use Dynamic Type instead of fixed font sizes
- Let the system handle font scaling for accessibility

## onChange Modifier
- Never use the single-parameter `onChange()` variant
- Use either the two-parameter or no-parameter version

## Code Quality
- Avoid `AnyView` unless absolutely necessary
- Don't break views into computed properties; create separate `View` structs
- Use static member lookup: `.circle` not `Circle()`, `.borderedProminent` not `BorderedProminentButtonStyle()`

## Images & Rendering
- Use `ImageRenderer` instead of `UIGraphicsImageRenderer`

## Collections
- When using `ForEach` with `enumerated()`, preserve the sequence type
- Don't convert to arrays first when using enumerated sequences
