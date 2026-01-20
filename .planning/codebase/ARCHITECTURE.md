# Architecture

**Analysis Date:** 2026-01-20

## Pattern Overview

**Overall:** View-Owned State SwiftUI Architecture (No ViewModel)

**Key Characteristics:**
- Views own their state directly via `@State`, `@Binding`, and `@AppStorage`
- SwiftData handles persistence with `@Model` and `@Query` for reactive data fetching
- Services/Managers as `ObservableObject` singletons for cross-cutting concerns (HealthKit, Notifications)
- No Redux/TCA patterns, no repository abstractions
- Pure SwiftUI with minimal UIKit (only for haptic feedback)

## Layers

**Presentation Layer:**
- Purpose: SwiftUI Views render UI and own local state
- Location: `W8Trackr/Views/`
- Contains: View structs with `@State`, `@Binding`, `@Query`, and computed properties
- Depends on: Models, Services/Managers, Theme
- Used by: App entry point (`W8TrackrApp`)

**Data Layer:**
- Purpose: SwiftData persistence for weight entries and milestones
- Location: `W8Trackr/Models/`
- Contains: `@Model` classes (WeightEntry, CompletedMilestone, MilestoneAchievement)
- Depends on: Foundation, SwiftData
- Used by: Views via `@Query`, Services via `ModelContext`

**Service Layer:**
- Purpose: Business logic and external integrations
- Location: `W8Trackr/Services/`, `W8Trackr/Managers/`, `W8Trackr/Analytics/`
- Contains: Stateless calculators (TrendCalculator, MilestoneCalculator, GoalProgressCalculator), Stateful managers (HealthSyncManager, HealthKitManager, NotificationManager)
- Depends on: Models, HealthKit, UserNotifications
- Used by: Views inject managers via `@StateObject`, `@ObservedObject`, or access `.shared` singletons

**Theme Layer:**
- Purpose: Design system (colors, typography, spacing, gradients)
- Location: `W8Trackr/Theme/`
- Contains: `AppColors`, `AppTheme`, `AppGradients`
- Depends on: SwiftUI, Asset catalog
- Used by: All views for consistent styling

## Data Flow

**Weight Entry Creation:**

1. User taps FAB in `DashboardView` -> presents `WeightEntryView` as sheet
2. `WeightEntryView` manages local `@State` for weight, date, note, bodyFat
3. On save: creates `WeightEntry` model, inserts into `modelContext`, calls `try modelContext.save()`
4. HealthKit sync: `HealthSyncManager.shared.saveWeightToHealth(entry:)` or legacy `HealthKitManager.shared.saveWeightEntry(...)`
5. `@Query` in `ContentView` automatically reacts to SwiftData changes
6. Child views receive updated `entries` array via props

**User Preferences Flow:**

1. Preferences stored via `@AppStorage` (persisted to UserDefaults)
2. Key preferences: `preferredWeightUnit`, `goalWeight`, `showSmoothing`, `hasCompletedOnboarding`
3. `ContentView` owns these bindings and passes down to child views
4. Settings changes propagate immediately via SwiftUI's reactive binding system

**State Management:**
- `@State`: View-local state (sheet presentation, form inputs, local editing state)
- `@Binding`: Parent-child communication (weightUnit, goalWeight passed to child views)
- `@AppStorage`: UserDefaults-backed persistent preferences
- `@Query`: SwiftData reactive queries (entries sorted by date)
- `@StateObject`/`@ObservedObject`: Service managers with published state

## Key Abstractions

**WeightEntry (`@Model`):**
- Purpose: Core data entity for weight measurements
- Examples: `W8Trackr/Models/WeightEntry.swift`
- Pattern: SwiftData model with computed properties for unit conversion, HealthKit sync fields
- Contains: weightValue, weightUnit, date, note, bodyFatPercentage, healthKitUUID, syncVersion

**TrendCalculator (enum with static methods):**
- Purpose: Analytics engine for weight trend analysis
- Examples: `W8Trackr/Analytics/TrendCalculator.swift`
- Pattern: Stateless pure functions (EWMA, Holt's Double Exponential Smoothing, goal prediction)
- Returns: `TrendPoint[]`, `HoltResult`, `GoalPrediction`

**MilestoneCalculator (enum with static methods):**
- Purpose: Generate and track progress milestones
- Examples: `W8Trackr/Models/Milestone.swift`
- Pattern: Stateless calculator generating milestone targets and progress
- Returns: `MilestoneProgress`, milestone arrays

**HealthSyncManager (`@MainActor ObservableObject`):**
- Purpose: Bidirectional HealthKit synchronization
- Examples: `W8Trackr/Managers/HealthSyncManager.swift`
- Pattern: Singleton with published sync status, uses protocol for testability
- Manages: Authorization, save/update/delete operations, sync state

## Entry Points

**App Entry (`@main`):**
- Location: `W8Trackr/W8TrackrApp.swift`
- Triggers: App launch
- Responsibilities: Configure ModelContainer, determine initial view (onboarding vs main), inject HealthSyncManager environment object

**ContentView (Root TabView):**
- Location: `W8Trackr/Views/ContentView.swift`
- Triggers: After onboarding complete or UI testing
- Responsibilities: Tab navigation (Dashboard, Logbook, Settings), own preferences, seed initial data, pass data to child views

**OnboardingView:**
- Location: `W8Trackr/Views/Onboarding/OnboardingView.swift`
- Triggers: First launch when `hasCompletedOnboarding == false`
- Responsibilities: Step-through wizard for unit preference, goal setting, first weight entry

**DashboardView:**
- Location: `W8Trackr/Views/Dashboard/DashboardView.swift`
- Triggers: Dashboard tab selected
- Responsibilities: Hero card, quick stats, milestone progress, chart, goal prediction, FAB for adding entries

## Error Handling

**Strategy:** Graceful degradation with user feedback via alerts/toasts

**Patterns:**
- SwiftData saves wrapped in `do/catch`, show toast on failure
- HealthKit operations check authorization, silently mark entries for later sync if denied
- Form validation prevents invalid state (weight bounds, goal weight bounds)
- Alert dialogs for destructive actions (delete all entries)

**Error Types:**
- `modelContext.save()` failures -> show toast, don't dismiss view
- HealthKit authorization denied -> `pendingHealthSync = true`, continue operation
- Invalid weight/body fat -> inline validation messages, disable save button

## Cross-Cutting Concerns

**Logging:** Console logging via standard `print` statements in debug; no structured logging framework

**Validation:**
- Weight bounds: `WeightUnit.minWeight` to `WeightUnit.maxWeight`
- Goal weight bounds: `WeightUnit.minGoalWeight` to `WeightUnit.maxGoalWeight` with warnings for extreme values
- Body fat: 1-60% range
- Validation messages shown inline in forms

**Authentication:** Not applicable (local-only app, no user accounts)

**Health Data Access:**
- Authorization requested on-demand when user enables Health sync
- Status tracked in `HealthSyncManager.isAuthorized`
- Graceful fallback when authorization denied

**Notifications:**
- `NotificationManager` handles daily reminders and smart notifications
- Permission requested when user enables reminders in Settings
- Scheduled via `UNUserNotificationCenter`

---

*Architecture analysis: 2026-01-20*
