# Codebase Structure

**Analysis Date:** 2026-01-20

## Directory Layout

```
W8Trackr/
├── W8Trackr/                    # Main app source
│   ├── W8TrackrApp.swift        # @main entry point
│   ├── Analytics/               # Trend calculation algorithms
│   ├── Intents/                 # App Shortcuts/Siri intents
│   ├── Managers/                # Stateful service managers
│   ├── Models/                  # SwiftData @Model classes
│   ├── Preview Content/         # Preview modifiers
│   ├── Services/                # Stateless business logic
│   ├── Theme/                   # Design system (colors, spacing)
│   ├── Views/                   # SwiftUI views
│   │   ├── Analytics/           # Analytics-related views
│   │   ├── Animations/          # Animation components
│   │   ├── Components/          # Reusable UI components
│   │   ├── Dashboard/           # Dashboard tab views
│   │   ├── Goals/               # Goal/milestone views
│   │   └── Onboarding/          # Onboarding flow views
│   └── Assets.xcassets/         # Colors, images, app icon
├── W8TrackrTests/               # Unit tests
├── W8TrackrUITests/             # UI/screenshot tests
├── W8Trackr.xcodeproj/          # Xcode project
├── specs/                       # Feature specifications
├── fastlane/                    # Fastlane automation
└── .claude/rules/               # Claude AI coding rules
```

## Directory Purposes

**`W8Trackr/Analytics/`:**
- Purpose: Weight trend calculation and prediction algorithms
- Contains: `TrendCalculator.swift` (EWMA, Holt's method, goal prediction)
- Key files: `TrendCalculator.swift`

**`W8Trackr/Intents/`:**
- Purpose: Siri Shortcuts and App Intents
- Contains: `AppShortcuts.swift`
- Key files: `AppShortcuts.swift`

**`W8Trackr/Managers/`:**
- Purpose: Stateful singleton services for external integrations
- Contains: ObservableObject managers for HealthKit, Notifications, CloudKit, Data Export
- Key files:
  - `HealthSyncManager.swift` - Modern HealthKit sync with testable protocol
  - `HealthKitManager.swift` - Legacy HealthKit manager (being migrated)
  - `NotificationManager.swift` - Daily/smart reminder scheduling
  - `NotificationScheduler.swift` - Notification content generation
  - `CloudKitSyncManager.swift` - iCloud sync management
  - `DataExporter.swift` - CSV export functionality
  - `HealthStoreProtocol.swift` - Protocol for HealthKit testability

**`W8Trackr/Models/`:**
- Purpose: SwiftData persistence models
- Contains: `@Model` classes for domain entities
- Key files:
  - `WeightEntry.swift` - Core weight measurement + WeightUnit enum
  - `Milestone.swift` - CompletedMilestone model + MilestoneCalculator
  - `MilestoneAchievement.swift` - Milestone achievement tracking
  - `MilestoneType.swift` - Milestone type enum

**`W8Trackr/Preview Content/`:**
- Purpose: SwiftUI preview infrastructure
- Contains: PreviewModifier implementations for different data states
- Key files: `PreviewModifiers.swift` (EntriesPreview, EmptyEntriesPreview, etc.)

**`W8Trackr/Services/`:**
- Purpose: Stateless business logic calculators
- Contains: Pure function structs/enums for calculations
- Key files:
  - `MilestoneTracker.swift` - Milestone persistence operations (stub implementation)
  - `GoalProgressCalculator.swift` - Goal progress calculation (stub implementation)

**`W8Trackr/Theme/`:**
- Purpose: Design system definitions
- Contains: Colors, typography, spacing, gradients, shadows
- Key files:
  - `Colors.swift` - AppColors semantic color definitions
  - `AppTheme.swift` - Spacing, typography, corner radii, shadows
  - `Gradients.swift` - AppGradients definitions

**`W8Trackr/Views/`:**
- Purpose: SwiftUI view components
- Contains: All UI code organized by feature area
- Key files at root:
  - `ContentView.swift` - Root TabView container
  - `SettingsView.swift` - Settings tab
  - `LogbookView.swift` - Logbook tab
  - `WeightEntryView.swift` - Add/edit weight modal
  - `ChartSectionView.swift` - Weight trend chart
  - `WeightTrendChartView.swift` - Chart rendering
  - `HistorySectionView.swift` - Entry history list
  - `EmptyStateView.swift` - Empty state illustrations
  - `ToastView.swift` - Toast notification component
  - `ExportView.swift` - Data export sheet
  - `CurrentWeightView.swift` - Current weight display
  - `SummaryView.swift` - Summary statistics

**`W8Trackr/Views/Analytics/`:**
- Purpose: Analytics and summary views
- Key files: `WeeklySummaryView.swift`, `WeeklySummaryCard.swift`

**`W8Trackr/Views/Animations/`:**
- Purpose: Animation components and modifiers
- Key files: `ConfettiView.swift`, `SparkleView.swift`, `AnimationModifiers.swift`

**`W8Trackr/Views/Components/`:**
- Purpose: Reusable UI components
- Key files: `GoalPredictionView.swift`, `SyncStatusView.swift`

**`W8Trackr/Views/Dashboard/`:**
- Purpose: Dashboard tab views
- Key files: `DashboardView.swift`, `HeroCardView.swift`, `QuickStatsRow.swift`

**`W8Trackr/Views/Goals/`:**
- Purpose: Goal and milestone UI
- Key files: `MilestoneProgressView.swift`, `MilestoneCelebrationView.swift`

**`W8Trackr/Views/Onboarding/`:**
- Purpose: First-launch onboarding flow
- Key files:
  - `OnboardingView.swift` - Flow container
  - `WelcomeStepView.swift` - Welcome screen
  - `UnitPreferenceStepView.swift` - Unit selection
  - `GoalStepView.swift` - Goal weight setting
  - `FeatureTourStepView.swift` - Feature tour
  - `FirstWeightStepView.swift` - Initial weight entry
  - `CompletionStepView.swift` - Completion celebration

## Key File Locations

**Entry Points:**
- `W8Trackr/W8TrackrApp.swift`: App entry, ModelContainer setup, root view selection

**Configuration:**
- `W8Trackr.xcodeproj/`: Xcode project settings
- `.swiftlint.yml`: SwiftLint rules
- `CLAUDE.md`: Project coding standards
- `.claude/rules/`: Architecture and platform rules

**Core Logic:**
- `W8Trackr/Analytics/TrendCalculator.swift`: Trend analysis algorithms
- `W8Trackr/Models/WeightEntry.swift`: Core data model + unit conversion
- `W8Trackr/Models/Milestone.swift`: Milestone calculation logic

**Testing:**
- `W8TrackrTests/W8TrackrTests.swift`: Unit tests
- `W8TrackrTests/TrendCalculatorTests.swift`: Trend calculator tests
- `W8TrackrTests/WeightEntryHealthTests.swift`: Health sync tests
- `W8TrackrTests/HealthSyncManagerTests.swift`: HealthSyncManager tests
- `W8TrackrUITests/ScreenshotTests.swift`: Screenshot automation

## Naming Conventions

**Files:**
- Views: `{Feature}View.swift` (e.g., `DashboardView.swift`, `SettingsView.swift`)
- View Components: `{Purpose}View.swift` (e.g., `HeroCardView.swift`, `ToastView.swift`)
- Models: `{Entity}.swift` (e.g., `WeightEntry.swift`, `Milestone.swift`)
- Managers: `{Feature}Manager.swift` (e.g., `HealthSyncManager.swift`, `NotificationManager.swift`)
- Calculators: `{Feature}Calculator.swift` (e.g., `TrendCalculator.swift`, `MilestoneCalculator.swift`)

**Directories:**
- Feature areas: PascalCase plural (e.g., `Views/Dashboard/`, `Views/Onboarding/`)
- Layer directories: PascalCase singular (e.g., `Models/`, `Theme/`, `Analytics/`)

## Where to Add New Code

**New Feature:**
- Primary code: Create feature directory under `W8Trackr/Views/{Feature}/`
- Business logic: Add calculator to `W8Trackr/Services/` or `W8Trackr/Analytics/`
- New model: Add to `W8Trackr/Models/`
- Tests: Add to `W8TrackrTests/{Feature}Tests.swift`

**New View Component:**
- Reusable component: `W8Trackr/Views/Components/{Name}View.swift`
- Feature-specific: `W8Trackr/Views/{Feature}/{Name}View.swift`

**New Manager/Service:**
- Stateful manager (ObservableObject): `W8Trackr/Managers/{Feature}Manager.swift`
- Stateless calculator: `W8Trackr/Services/{Feature}Calculator.swift`

**New SwiftData Model:**
- Model file: `W8Trackr/Models/{Entity}.swift`
- Register in: `W8TrackrApp.swift` modelContainer initialization

**Utilities:**
- Theme additions: Add to appropriate file in `W8Trackr/Theme/`
- Animation helpers: `W8Trackr/Views/Animations/`

**New Tests:**
- Unit tests: `W8TrackrTests/{Feature}Tests.swift`
- UI tests: `W8TrackrUITests/{Feature}UITests.swift`

## Special Directories

**`specs/`:**
- Purpose: Feature specification documents for planning
- Generated: No (hand-written)
- Committed: Yes
- Contains: Numbered feature specs with checklists and contracts

**`fastlane/`:**
- Purpose: Fastlane automation for screenshots and deployment
- Generated: Partially (Fastfile is hand-written)
- Committed: Yes

**`W8Trackr/Preview Content/`:**
- Purpose: Preview-only code (excluded from release builds)
- Generated: No
- Committed: Yes
- Note: Only compiled when DEBUG is defined

**`W8Trackr/Assets.xcassets/`:**
- Purpose: Asset catalog for colors, images, app icon
- Generated: No (Xcode manages)
- Committed: Yes
- Contains: Color sets for theme, app icon

**`.claude/rules/`:**
- Purpose: Claude AI coding rules for this project
- Generated: No
- Committed: Yes
- Contains: architecture.md, ios.md, swift.md, swiftdata.md, swiftui.md

---

*Structure analysis: 2026-01-20*
