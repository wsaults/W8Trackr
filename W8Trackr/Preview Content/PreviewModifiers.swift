//
//  PreviewModifiers.swift
//  W8Trackr
//
//  Shared preview modifiers for SwiftUI previews
//

#if DEBUG
import SwiftData
import SwiftUI

// MARK: - Entries Preview (Full Sample Data)

/// Preview modifier that provides a ModelContainer with full sample data
///
/// Usage:
/// ```swift
/// @available(iOS 18, macOS 15, *)
/// #Preview(traits: .modifier(EntriesPreview())) {
///     YourView()
/// }
/// ```
@available(iOS 18, macOS 15, *)
struct EntriesPreview: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(
            for: WeightEntry.self, CompletedMilestone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let examples = WeightEntry.sampleData
        examples.forEach { example in
            container.mainContext.insert(example)
        }
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

// MARK: - Empty Entries Preview

/// Preview modifier that provides an empty ModelContainer (no data)
///
/// Usage:
/// ```swift
/// @available(iOS 18, macOS 15, *)
/// #Preview("Empty State", traits: .modifier(EmptyEntriesPreview())) {
///     YourView()
/// }
/// ```
@available(iOS 18, macOS 15, *)
struct EmptyEntriesPreview: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        try ModelContainer(
            for: WeightEntry.self, CompletedMilestone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

// MARK: - Minimal Entries Preview

/// Preview modifier that provides a ModelContainer with minimal data (2-3 entries)
///
/// Useful for testing views with sparse data without heavy loading
///
/// Usage:
/// ```swift
/// @available(iOS 18, macOS 15, *)
/// #Preview("Minimal Data", traits: .modifier(MinimalEntriesPreview())) {
///     YourView()
/// }
/// ```
@available(iOS 18, macOS 15, *)
struct MinimalEntriesPreview: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(
            for: WeightEntry.self, CompletedMilestone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        // Insert only 3 entries for minimal testing
        let calendar = Calendar.current
        let today = Date()

        let entries = [
            WeightEntry(weight: 175.0, date: today),
            WeightEntry(weight: 176.5, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            WeightEntry(weight: 178.0, date: calendar.date(byAdding: .day, value: -3, to: today)!)
        ]

        entries.forEach { container.mainContext.insert($0) }
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

// MARK: - Short Sample Data Preview

/// Preview modifier that provides short sample data (7 days)
///
/// Usage:
/// ```swift
/// @available(iOS 18, macOS 15, *)
/// #Preview(traits: .modifier(ShortSamplePreview())) {
///     YourView()
/// }
/// ```
@available(iOS 18, macOS 15, *)
struct ShortSamplePreview: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(
            for: WeightEntry.self, CompletedMilestone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        WeightEntry.shortSampleData.forEach { container.mainContext.insert($0) }
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

// MARK: - Settings View Preview

/// Preview modifier for SettingsView with optional sample data
///
/// Usage:
/// ```swift
/// @available(iOS 18, macOS 15, *)
/// #Preview(traits: .modifier(SettingsViewPreview())) {
///     SettingsView(...)
/// }
///
/// @available(iOS 18, macOS 15, *)
/// #Preview("With Data", traits: .modifier(SettingsViewPreview(withSampleData: true))) {
///     SettingsView(...)
/// }
/// ```
@available(iOS 18, macOS 15, *)
struct SettingsViewPreview: PreviewModifier {
    var withSampleData: Bool = false

    static func makeSharedContext() async throws -> ModelContainer {
        try ModelContainer(
            for: WeightEntry.self, CompletedMilestone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func body(content: Content, context: ModelContainer) -> some View {
        if withSampleData {
            _ = {
                WeightEntry.shortSampleData.forEach { entry in
                    context.mainContext.insert(entry)
                }
                try? context.mainContext.save()
            }()
        }
        return content.modelContainer(context)
    }
}

// MARK: - Dashboard Preview

/// Preview modifier for DashboardView
///
/// Usage:
/// ```swift
/// @available(iOS 18, macOS 15, *)
/// #Preview(traits: .modifier(DashboardPreview())) {
///     DashboardView(...)
/// }
/// ```
@available(iOS 18, macOS 15, *)
struct DashboardPreview: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        try ModelContainer(
            for: WeightEntry.self, CompletedMilestone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

// MARK: - Content View Preview

/// Preview modifier for ContentView with optional empty state
///
/// Usage:
/// ```swift
/// @available(iOS 18, macOS 15, *)
/// #Preview("With Data", traits: .modifier(ContentViewPreview())) {
///     ContentView()
/// }
///
/// @available(iOS 18, macOS 15, *)
/// #Preview("Empty", traits: .modifier(ContentViewPreview(isEmpty: true))) {
///     ContentView()
/// }
/// ```
@available(iOS 18, macOS 15, *)
struct ContentViewPreview: PreviewModifier {
    var isEmpty: Bool = false

    static func makeSharedContext() async throws -> ModelContainer {
        try ModelContainer(
            for: WeightEntry.self, CompletedMilestone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func body(content: Content, context: ModelContainer) -> some View {
        if !isEmpty {
            _ = {
                WeightEntry.shortSampleData.forEach { entry in
                    context.mainContext.insert(entry)
                }
                try? context.mainContext.save()
            }()
        }
        return content.modelContainer(context)
    }
}

#endif
