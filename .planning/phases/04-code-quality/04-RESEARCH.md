# Phase 4: Code Quality - Research

**Researched:** 2026-01-20
**Domain:** Swift 6 concurrency migration, SwiftUI API modernization
**Confidence:** HIGH

## Summary

Phase 4 addresses two code quality requirements: migrating GCD (Grand Central Dispatch) usage to Swift concurrency (`async/await`), and replacing deprecated `.cornerRadius()` calls with `.clipShape(.rect(cornerRadius:))`.

The project already has comprehensive research from the iOS 26/Swift 6 upgrade spec (specs/005-ios26-swift6-upgrade/research.md) that documents the migration patterns. The codebase has a mix of legacy GCD patterns in Manager classes and Views, plus a deprecated SwiftUI modifier used in 11 locations.

**Primary recommendation:** Follow established patterns from prior research. Migrate managers to `@Observable` + `@MainActor` with async methods. Replace all `.cornerRadius()` with `.clipShape(.rect(cornerRadius:))`. Run SwiftLint after changes to verify zero warnings.

## Standard Stack

### Core (Already in Project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift 6 | 6.2+ | Language with strict concurrency | Project requirement per CLAUDE.md |
| SwiftUI | iOS 26+ | UI framework | Project requirement |
| UNUserNotificationCenter | iOS 26 | Notifications with async API | Apple framework |
| HealthKit | iOS 26 | Health data with async API | Apple framework |
| Network | iOS 26 | NWPathMonitor | Apple framework |

### No Additional Libraries Needed
This phase uses only existing Apple frameworks. No third-party dependencies required.

## Architecture Patterns

### Pattern 1: @MainActor Service Class with @Observable

**What:** Replace `ObservableObject` classes with `@Observable` + `@MainActor`
**When to use:** All service/manager classes that publish state
**Source:** specs/005-ios26-swift6-upgrade/research.md (Section 2-3)

```swift
// Before
class NotificationManager: ObservableObject {
    @Published var isReminderEnabled = false

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isReminderEnabled = granted
                completion(granted)
            }
        }
    }
}

// After
@Observable
@MainActor
final class NotificationManager {
    var isReminderEnabled = false

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            isReminderEnabled = granted
            return granted
        } catch {
            return false
        }
    }
}
```

### Pattern 2: View State Updates with Task.sleep

**What:** Replace `DispatchQueue.main.asyncAfter` with `Task.sleep(for:)`
**When to use:** Delayed actions in Views (dismiss animations, auto-hide toasts)
**Source:** CLAUDE.md swiftui.md rules

```swift
// Before
func dismiss() {
    withAnimation(.easeIn(duration: 0.2)) {
        showContent = false
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        onDismiss()
    }
}

// After
func dismiss() {
    Task {
        withAnimation(.easeIn(duration: 0.2)) {
            showContent = false
        }
        try? await Task.sleep(for: .milliseconds(200))
        onDismiss()
    }
}
```

### Pattern 3: Cancellable Timer with Task

**What:** Replace `DispatchWorkItem` with cancellable Task
**When to use:** Undo timers, auto-dismiss patterns
**Source:** Swift structured concurrency best practices

```swift
// Before
@State private var deleteWorkItem: DispatchWorkItem?

func queueDelete(_ entry: WeightEntry) {
    deleteWorkItem?.cancel()

    let workItem = DispatchWorkItem { [self] in
        // action
    }
    deleteWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
}

// After
@State private var deleteTask: Task<Void, Never>?

func queueDelete(_ entry: WeightEntry) {
    deleteTask?.cancel()

    deleteTask = Task {
        try? await Task.sleep(for: .seconds(5))
        guard !Task.isCancelled else { return }
        // action
    }
}
```

### Pattern 4: clipShape Replacement

**What:** Replace deprecated `.cornerRadius()` with `.clipShape()`
**When to use:** All rounded corner styling
**Source:** CLAUDE.md swiftui.md rules

```swift
// Before
.cornerRadius(10)

// After
.clipShape(.rect(cornerRadius: 10))
```

### Anti-Patterns to Avoid

- **Using `DispatchQueue.main.async`:** Direct property assignment is safe on `@MainActor` classes
- **Mixing `ObservableObject` and `@Observable`:** Be consistent per class
- **Using `nonisolated(unsafe)`:** Bypasses safety guarantees
- **Fire-and-forget Tasks without cancellation:** Always handle Task lifecycle

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Delayed execution | DispatchQueue.main.asyncAfter | Task.sleep(for:) | Swift concurrency integration |
| Cancellable timers | DispatchWorkItem | Task with cancellation | Structured concurrency |
| Main thread dispatch | DispatchQueue.main.async | @MainActor annotation | Compile-time safety |
| Monitor queue | DispatchQueue(label:) | AsyncStream or actor | Data race prevention |

**Key insight:** `@MainActor` makes main-thread dispatch unnecessary - direct property assignment is safe.

## Common Pitfalls

### Pitfall 1: Forgetting @MainActor on Shared Instance
**What goes wrong:** Data races accessing singleton from multiple contexts
**Why it happens:** Static `shared` property accessed before understanding actor isolation
**How to avoid:** Always add `@MainActor` to classes with static shared instances
**Warning signs:** Compiler warnings about "non-isolated" access

### Pitfall 2: Mixing Sync and Async Patterns
**What goes wrong:** Completion handlers with async code creates callback hell
**Why it happens:** Partial migration leaves old patterns
**How to avoid:** Convert entire call chain to async, not just one layer
**Warning signs:** Nested closures with `Task { }` inside completion handlers

### Pitfall 3: Missing Task Cancellation Handling
**What goes wrong:** Delayed actions fire even after view dismissal
**Why it happens:** Task.sleep completes even when parent view is gone
**How to avoid:** Check `Task.isCancelled` after sleep, cancel tasks in view cleanup
**Warning signs:** Actions occurring on dismissed/deallocated views

### Pitfall 4: CloudKitSyncManager Complexity
**What goes wrong:** NWPathMonitor uses its own queue, complex state machine
**Why it happens:** Monitor callback patterns don't map cleanly to @MainActor
**How to avoid:** Keep monitor queue, but use `MainActor.run { }` for property updates
**Warning signs:** Data race warnings on status property updates

### Pitfall 5: Duplicate HealthKit Managers
**What goes wrong:** HealthKitManager and HealthSyncManager both exist
**Why it happens:** HealthSyncManager was new implementation, HealthKitManager is legacy
**How to avoid:** Migrate all usages to HealthSyncManager, then delete HealthKitManager
**Warning signs:** WeightEntryView uses both managers (line 330 and 336)

## Code Examples

### UNUserNotificationCenter Async API
```swift
// Source: Apple UNUserNotificationCenter async documentation
let center = UNUserNotificationCenter.current()

// Request authorization (async)
let granted = try await center.requestAuthorization(options: [.alert, .sound])

// Get notification settings (async)
let settings = await center.notificationSettings()
let isAuthorized = settings.authorizationStatus == .authorized
```

### CKContainer Async API
```swift
// Source: Apple CloudKit async documentation
let container = CKContainer.default()

// Check account status (async)
let accountStatus = try await container.accountStatus()
switch accountStatus {
case .available:
    // logged in
case .noAccount:
    // not logged in
default:
    break
}
```

### NWPathMonitor with MainActor
```swift
// Source: Best practice for monitor + @MainActor
@Observable
@MainActor
final class NetworkManager {
    var isNetworkAvailable = true

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "network.monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }

    deinit {
        monitor.cancel()
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 (2023) | Per-property tracking |
| `DispatchQueue.main.async` | `@MainActor` annotation | Swift 5.5 (2021) | Compile-time safety |
| `DispatchQueue.main.asyncAfter` | `Task.sleep(for:)` | Swift 5.5 (2021) | Structured concurrency |
| Completion handlers | `async/await` | Swift 5.5 (2021) | Linear code flow |
| `.cornerRadius()` | `.clipShape(.rect(cornerRadius:))` | iOS 17 (2023) | More flexible clipping |

**Deprecated/outdated:**
- `ObservableObject`: Still works but `@Observable` is preferred
- `DispatchQueue` for UI updates: Use `@MainActor` instead
- `.cornerRadius()`: Deprecated, use `.clipShape()`

## Codebase Inventory

### GCD Usage Locations (QUAL-01)

**Managers (5 instances each):**

| File | Line | Pattern | Migration |
|------|------|---------|-----------|
| HealthKitManager.swift | 59 | `DispatchQueue.main.async` in init | Direct assignment with @MainActor |
| HealthKitManager.swift | 84 | `DispatchQueue.main.async` in completion | Convert to async/await |
| HealthKitManager.swift | 106 | `DispatchQueue.main.async` status update | Direct assignment |
| HealthKitManager.swift | 116 | `DispatchQueue.main.async` in save callback | Convert to async |
| HealthKitManager.swift | 141 | `DispatchQueue.main.async` in body fat callback | Convert to async |
| NotificationManager.swift | 49 | `DispatchQueue.main.async` in init | Direct assignment |
| NotificationManager.swift | 64 | `DispatchQueue.main.async` in auth callback | Convert to async |
| NotificationManager.swift | 163 | `DispatchQueue.main.async` for suggestedTime | Direct assignment |
| CloudKitSyncManager.swift | 32 | `DispatchQueue(label:)` for monitor | Keep - monitor requires queue |
| CloudKitSyncManager.swift | 46 | `DispatchQueue.main.async` in monitor handler | Use MainActor.run |
| CloudKitSyncManager.swift | 61 | `.receive(on: DispatchQueue.main)` | Use MainActor.run in sink |
| CloudKitSyncManager.swift | 69 | `.receive(on: DispatchQueue.main)` | Use MainActor.run in sink |
| CloudKitSyncManager.swift | 94 | `DispatchQueue.main.asyncAfter` | Task.sleep |
| CloudKitSyncManager.swift | 111 | `DispatchQueue.main.async` in callback | MainActor.run |
| CloudKitSyncManager.swift | 148 | `DispatchQueue.main.asyncAfter` | Task.sleep |

**Views (6 instances):**

| File | Line | Pattern | Migration |
|------|------|---------|-----------|
| OnboardingView.swift | 152 | `DispatchQueue.main.asyncAfter` confetti dismiss | Task.sleep |
| ToastView.swift | 135 | `DispatchQueue.main.asyncAfter` auto-dismiss | Task.sleep |
| MilestoneCelebrationView.swift | 110 | `DispatchQueue.main.asyncAfter` dismiss | Task.sleep |
| HistorySectionView.swift | 141 | `DispatchWorkItem` creation | Task pattern |
| HistorySectionView.swift | 147 | `DispatchQueue.main.asyncAfter` undo timer | Task.sleep |
| AnimationModifiers.swift | 182 | `DispatchQueue.main.asyncAfter` dismiss | Task.sleep |
| AnimationModifiers.swift | 331 | `DispatchQueue.main.asyncAfter` dismiss | Task.sleep |
| ConfettiView.swift | 264 | `DispatchQueue.main.asyncAfter` auto-dismiss | Task.sleep |

### cornerRadius Usage Locations (QUAL-02)

| File | Line | Current | Replacement |
|------|------|---------|-------------|
| WeeklySummaryCard.swift | 166 | `.cornerRadius(12)` | `.clipShape(.rect(cornerRadius: 12))` |
| WeightEntryView.swift | 248 | `.cornerRadius(8)` | `.clipShape(.rect(cornerRadius: 8))` |
| WeightEntryView.swift | 264 | `.cornerRadius(10)` | `.clipShape(.rect(cornerRadius: 10))` |
| ToastView.swift | 82 | `.cornerRadius(10)` | `.clipShape(.rect(cornerRadius: 10))` |
| MilestoneProgressView.swift | 66 | `.cornerRadius(10)` | `.clipShape(.rect(cornerRadius: 10))` |
| MilestoneProgressView.swift | 125 | `.cornerRadius(10)` | `.clipShape(.rect(cornerRadius: 10))` |
| MilestoneCelebrationView.swift | 74 | `.cornerRadius(12)` | `.clipShape(.rect(cornerRadius: 12))` |
| MilestoneCelebrationView.swift | 83 | `.cornerRadius(20)` | `.clipShape(.rect(cornerRadius: 20))` |
| MilestoneCelebrationView.swift | 213 | `.cornerRadius(10)` | `.clipShape(.rect(cornerRadius: 10))` |
| ChartSectionView.swift | 49 | `.cornerRadius(10)` | `.clipShape(.rect(cornerRadius: 10))` |
| CurrentWeightView.swift | 54 | `.cornerRadius(10)` | `.clipShape(.rect(cornerRadius: 10))` |

## Migration Strategy

### Recommended Order

1. **QUAL-02 first (cornerRadius):** Simple find-replace, no behavioral changes, quick win
2. **QUAL-01 Views:** Migrate View GCD patterns (lower risk, no shared state)
3. **QUAL-01 NotificationManager:** Medium complexity, well-documented async API
4. **QUAL-01 HealthKitManager:** Consider consolidation with HealthSyncManager
5. **QUAL-01 CloudKitSyncManager:** Most complex (monitor queue, Combine)

### HealthKit Manager Consolidation

**Current state:**
- `HealthKitManager` - Legacy, uses completion handlers + GCD
- `HealthSyncManager` - Modern, already uses `@MainActor` + async

**Recommendation:**
- Migrate `HealthKitManager` code to `HealthSyncManager`
- Update `WeightEntryView` line 336 to use `HealthSyncManager`
- Delete `HealthKitManager` after verification

## Open Questions

1. **CloudKitSyncManager Combine usage:**
   - What we know: Uses `.receive(on: DispatchQueue.main)` in Combine pipelines
   - What's unclear: Whether to migrate to pure async or keep Combine with MainActor.run
   - Recommendation: Use MainActor.run in sink closures (minimal change, maintains pattern)

2. **Test updates needed:**
   - What we know: Tests may need `@MainActor` annotations
   - What's unclear: Current test state (STATE.md mentions infrastructure issues)
   - Recommendation: Add `@MainActor` to relevant tests, verify test infrastructure separately

## Sources

### Primary (HIGH confidence)
- specs/005-ios26-swift6-upgrade/research.md - Prior project research
- CLAUDE.md rules (swift.md, swiftui.md) - Project coding standards
- Apple UNUserNotificationCenter documentation - Async API patterns
- Apple CloudKit documentation - Async API patterns

### Secondary (MEDIUM confidence)
- Swift.org concurrency migration guide - General patterns
- Apple "Adopting Swift 6" documentation - Migration strategies

### Tertiary (LOW confidence)
- None - all findings verified with project docs or Apple sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using only Apple frameworks already in project
- Architecture: HIGH - Patterns documented in prior research spec
- Pitfalls: HIGH - Identified from actual codebase analysis
- Migration inventory: HIGH - Direct grep of codebase

**Research date:** 2026-01-20
**Valid until:** 2026-02-20 (stable patterns, no rapid changes expected)
