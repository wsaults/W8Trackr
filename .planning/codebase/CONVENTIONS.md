# Coding Conventions

**Analysis Date:** 2026-01-20

## Naming Patterns

**Files:**
- Views: PascalCase with `View` suffix (e.g., `DashboardView.swift`, `SettingsView.swift`)
- Models: PascalCase without suffix (e.g., `WeightEntry.swift`, `Milestone.swift`)
- Managers/Services: PascalCase with `Manager` or `Calculator` suffix (e.g., `HealthSyncManager.swift`, `TrendCalculator.swift`)
- Theme files: PascalCase describing purpose (e.g., `AppTheme.swift`, `Colors.swift`, `Gradients.swift`)
- Test files: Mirror source file name with `Tests` suffix (e.g., `TrendCalculatorTests.swift`)

**Functions:**
- camelCase starting with verb (e.g., `calculateEWMA`, `requestAuthorization`, `saveWeightToHealth`)
- Boolean getters use `is` prefix (e.g., `isValidWeight`, `isHealthSyncEnabled`)
- Computed properties: noun-form without `get` prefix (e.g., `currentWeight`, `weeklyChange`)

**Variables:**
- camelCase for all variables (e.g., `localGoalWeight`, `reminderTime`)
- Private properties prefixed with underscore only for backing storage caches (e.g., `_sampleDataCache`)
- Constants inside enums: `static let` with camelCase (e.g., `static let defaultLambda: Double = 0.1`)

**Types:**
- PascalCase for all types
- Enums: singular noun (e.g., `WeightUnit`, `SyncStatus`, `DateRange`)
- Structs: noun describing data (e.g., `TrendPoint`, `HoltResult`, `GoalPrediction`)
- Protocols: adjective with `-able` suffix or noun with `Protocol` suffix (e.g., `HealthStoreProtocol`)

## Code Style

**Formatting:**
- SwiftLint enforced with zero warnings
- Config: `.swiftlint.yml`
- Line length: 150 warning, 200 error
- Type body length: 400 warning, 600 error

**Key SwiftLint Rules:**
- `empty_count`, `closure_spacing`, `toggle_bool` enabled
- `force_unwrapping`, `force_try` disabled (project allows intentional use)
- `nesting`, `function_body_length` disabled (SwiftUI patterns)
- Custom rule warns on `print()` statements

**Indentation:**
- 4 spaces (Swift default)
- Trailing closures aligned with opening statement

## Import Organization

**Order:**
1. System frameworks (Foundation, SwiftUI, SwiftData)
2. Third-party frameworks (none used)
3. Local modules (@testable import for tests)

**Example from `W8Trackr/Views/Dashboard/DashboardView.swift`:**
```swift
import Charts
import SwiftData
import SwiftUI
```

**Path Aliases:**
- None used; relative imports only

## Error Handling

**Patterns:**
- `async throws` for operations that can fail (HealthKit, file I/O)
- Graceful degradation for authorization errors (mark pending, continue silently)
- `do/catch` blocks with specific error type handling

**Example from `W8Trackr/Managers/HealthSyncManager.swift`:**
```swift
do {
    try await healthStore.save(sample)
    entry.pendingHealthSync = false
    syncStatus = .success
} catch {
    // Graceful degradation: if auth denied, silently mark for later sync
    if isAuthorizationDeniedError(error) {
        entry.pendingHealthSync = true
        syncStatus = .idle
        return
    }
    syncStatus = .failed(error.localizedDescription)
    throw error
}
```

**Status Enums:**
- Use enums with associated values for status (e.g., `SyncStatus.failed(String)`)

## Logging

**Framework:** None - `print()` discouraged via SwiftLint custom rule

**Patterns:**
- No logging in production code
- Use Xcode debugger or breakpoints instead
- SwiftLint warns on `print()` statements with message: "Consider using os_log or removing print statements"

## Comments

**When to Comment:**
- Mark sections with `// MARK: -` for navigation
- Document complex algorithms with inline comments
- Explain "why" for non-obvious decisions

**Documentation Comments:**
- Triple-slash `///` for public APIs
- Use markdown formatting in doc comments
- Include parameter descriptions and return value explanations

**Example from `W8Trackr/Analytics/TrendCalculator.swift`:**
```swift
/// Calculates EWMA trend line from weight entries using Hacker's Diet formula
///
/// - Parameters:
///   - entries: Array of weight entries (will be sorted by date ascending)
///   - lambda: Smoothing factor (0 < lambda <= 1). Default is 0.1 per Hacker's Diet
///   - unit: Weight unit to use for calculations
/// - Returns: Array of TrendPoints with smoothed trend values, sorted by date ascending
///
/// The EWMA formula:
/// ```
/// trend[0] = weight[0]
/// trend[t] = lambda * weight[t] + (1 - lambda) * trend[t-1]
/// ```
```

**MARK Sections:**
- `// MARK: - Section Name` for major sections
- `// MARK: Section Name` (without dash) for subsections
- Common sections: `Properties`, `Initialization`, `Body`, `View Components`, `Private Helpers`

## Function Design

**Size:**
- Keep functions focused on single responsibility
- SwiftUI views can be longer (body builders); extract into computed properties or separate views

**Parameters:**
- Use default parameter values for optional configuration (e.g., `lambda: Double = defaultLambda`)
- Trailing closures for callbacks and completion handlers
- Label all parameters (no `_` for external labels)

**Return Values:**
- Return optionals for operations that may not produce a result
- Use `Result` type for complex success/failure scenarios
- Enums with associated values for multi-state returns

## Module Design

**Exports:**
- No explicit export control; all public by default within module
- Use `private` for implementation details
- Use `fileprivate` sparingly

**Access Control:**
```swift
// Public API
func requestAuthorization() async throws -> Bool

// Internal helper
private func checkAuthorizationStatus()

// Published state (observable)
@Published var syncStatus: SyncStatus = .idle
```

**Barrel Files:**
- Not used; each type in its own file

## SwiftUI-Specific Conventions

**State Management:**
- `@State` for view-local state
- `@Binding` for parent-child communication
- `@Environment` for system values and dependency injection
- `@AppStorage` for UserDefaults-backed preferences
- `@StateObject` for view-owned ObservableObjects
- `@ObservedObject` for passed-in ObservableObjects

**View Composition:**
- Extract sections into private computed properties returning `some View`
- Use `@ViewBuilder` for conditional view construction
- Separate large views into dedicated `View` structs

**Example from `W8Trackr/Views/SettingsView.swift`:**
```swift
private var weightSettingsSection: some View {
    Section {
        // Section content
    } header: {
        Text("Weight Settings")
    } footer: {
        Text("Your goal weight will be automatically converted when changing units.")
    }
}
```

**Previews:**
- Use `#if DEBUG` to wrap preview code
- Use custom `PreviewModifier` structs for reusable preview configurations
- Include multiple preview variants (empty state, with data, different configs)

**Example from `W8Trackr/Preview Content/PreviewModifiers.swift`:**
```swift
@available(iOS 18, macOS 15, *)
#Preview("With Data", traits: .modifier(DashboardPreview())) {
    DashboardView(...)
}
```

## Design System

**Theme Usage:**
- Spacing: `AppTheme.Spacing.md` (not magic numbers)
- Corner radius: `AppTheme.CornerRadius.md` (not `cornerRadius(12)`)
- Colors: `AppColors.surface`, `AppColors.Fallback.primary`
- Gradients: `AppGradients.primary`

**View Modifiers:**
- Use custom view modifiers for repeated styling: `.cardStyle()`, `.cardShadow()`
- Modern SwiftUI APIs: `foregroundStyle()` not `foregroundColor()`, `clipShape(.rect(cornerRadius:))` not `cornerRadius()`

---

*Convention analysis: 2026-01-20*
