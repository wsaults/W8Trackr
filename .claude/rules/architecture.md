# W8Trackr Architecture Rules

This document defines the pure SwiftUI architecture patterns for W8Trackr.

## State Management

- **@State** for view-local state
- **@Binding** for parent-child communication
- **@Environment** for system values and dependency injection
- **@AppStorage** for UserDefaults-backed preferences
- **NO ViewModels** - views own their state directly

## Data Layer

- SwiftData **@Model** for persistence
- **@Query** for reactive data fetching
- **@Environment(\.modelContext)** for mutations
- Keep models simple - no business logic in models

## Service Layer

- **ObservableObject** for stateful services (e.g., NotificationManager)
- **@StateObject** when view owns the service
- Inject via Environment when sharing across views

## View Composition

- Extract computed view properties for complex sections
- Prefer composition over inheritance
- Keep views focused and single-purpose

## What NOT to Do

- No Redux/TCA patterns
- No Combine for UI binding (use @Published in ObservableObject only)
- No repository pattern abstractions
- No protocol-heavy architectures
