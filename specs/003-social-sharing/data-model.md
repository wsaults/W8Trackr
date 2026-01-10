# Data Model: Social Sharing

**Feature**: 003-social-sharing
**Date**: 2025-01-09
**Purpose**: Define data structures for shareable content and preferences

## Entity Relationship Diagram

```
┌────────────────────────────┐      ┌────────────────────────────┐
│  MilestoneAchievement      │      │    SharingPreferences      │
│  (from 002 - no changes)   │      │      (@AppStorage)         │
├────────────────────────────┤      ├────────────────────────────┤
│ - milestoneType: String    │──┐   │ - hideExactWeights: Bool   │
│ - dateAchieved: Date       │  │   │ - hideDates: Bool          │
│ - weightAtAchievement: Double│ │   │ - includeGraphic: Bool     │
│ - progressPercentage: Double │ │   │ - defaultHashtag: String   │
└────────────────────────────┘  │   └────────────────────────────┘
                                │              │
                                │              │
                                ▼              ▼
                     ┌────────────────────────────────┐
                     │       ShareableContent         │
                     │   (Computed, Transferable)     │
                     ├────────────────────────────────┤
                     │ - contentType: ShareType       │
                     │ - title: String                │
                     │ - message: String              │
                     │ - image: UIImage?              │
                     │ - progressPercentage: Double?  │
                     │ - milestoneType: MilestoneType?│
                     └────────────────────────────────┘
```

## SharingPreferences (@AppStorage)

Preferences are stored in UserDefaults via `@AppStorage`, not SwiftData:

```swift
// In SettingsView or a dedicated SharingPreferencesManager

@AppStorage("shareHideExactWeights") var hideExactWeights: Bool = true  // Privacy by default
@AppStorage("shareHideDates") var hideDates: Bool = false
@AppStorage("shareIncludeGraphic") var includeGraphic: Bool = true
@AppStorage("shareDefaultHashtag") var defaultHashtag: String = "#W8Trackr"
```

### Property Descriptions

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `hideExactWeights` | Bool | `true` | When true, share content shows percentages only, not actual lb/kg values |
| `hideDates` | Bool | `false` | When true, dates shown as relative ("3 months ago") not specific |
| `includeGraphic` | Bool | `true` | When true, generates and attaches progress image to share |
| `defaultHashtag` | String | `#W8Trackr` | Hashtag appended to share messages |

## ShareType Enum

```swift
/// Types of content that can be shared
enum ShareType: String, CaseIterable {
    case milestoneAchievement   // 25%, 50%, 75%, 100% progress
    case approachingGoal        // Within 5 lb of goal
    case progressSummary        // Overall progress to date
    case goalAchieved           // Final goal completion

    var celebrationEmoji: String {
        switch self {
        case .milestoneAchievement: return "🎉"
        case .approachingGoal: return "🔥"
        case .progressSummary: return "📈"
        case .goalAchieved: return "🏆"
        }
    }

    var defaultTitle: String {
        switch self {
        case .milestoneAchievement: return "Progress Milestone"
        case .approachingGoal: return "Almost There!"
        case .progressSummary: return "My Progress"
        case .goalAchieved: return "Goal Achieved!"
        }
    }
}
```

## ShareableContent (Transferable)

```swift
import SwiftUI
import UniformTypeIdentifiers

/// Content ready for sharing via ShareLink
/// Conforms to Transferable for native iOS sharing
struct ShareableContent: Transferable {
    let contentType: ShareType
    let title: String
    let message: String
    let image: UIImage?
    let progressPercentage: Double?
    let milestoneType: MilestoneType?
    let weightUnit: WeightUnit

    // For privacy mode
    let showsExactWeights: Bool
    let showsExactDates: Bool

    // MARK: - Transferable Conformance

    static var transferRepresentation: some TransferRepresentation {
        // Primary: Text representation
        DataRepresentation(exportedContentType: .plainText) { content in
            Data(content.message.utf8)
        }

        // Secondary: Image if available
        DataRepresentation(exportedContentType: .png) { content in
            guard let image = content.image,
                  let data = image.pngData() else {
                throw ShareError.noImageAvailable
            }
            return data
        }
    }

    // MARK: - Preview Generation

    var preview: SharePreview<String, Image> {
        if let uiImage = image {
            return SharePreview(title, image: Image(uiImage: uiImage))
        } else {
            return SharePreview(title)
        }
    }

    // MARK: - Computed Properties

    /// Full shareable text with emoji and hashtag
    var fullText: String {
        "\(message) \(contentType.celebrationEmoji)"
    }

    /// Subject line for email shares
    var emailSubject: String {
        title
    }
}

enum ShareError: Error {
    case noImageAvailable
    case contentGenerationFailed
}
```

## ShareContentInput (Generation Input)

```swift
/// Input data for generating shareable content
/// Separates raw data from privacy-filtered output
struct ShareContentInput {
    // For milestone shares
    let milestone: MilestoneAchievement?

    // For progress shares
    let currentWeight: Double?
    let startWeight: Double?
    let goalWeight: Double?
    let progressPercentage: Double?
    let trackingDuration: DateInterval?

    // Context
    let weightUnit: WeightUnit
    let isWeightGainGoal: Bool

    // From preferences
    let preferences: SharingPreferences
}

/// Snapshot of sharing preferences
struct SharingPreferences {
    let hideExactWeights: Bool
    let hideDates: Bool
    let includeGraphic: Bool
    let defaultHashtag: String

    /// Default privacy-first configuration
    static let `default` = SharingPreferences(
        hideExactWeights: true,
        hideDates: false,
        includeGraphic: true,
        defaultHashtag: "#W8Trackr"
    )
}
```

## ProgressGraphicData (Image Generation Input)

```swift
/// Data needed to render a shareable progress graphic
struct ProgressGraphicData {
    let progressPercentage: Double
    let milestoneType: MilestoneType?
    let showExactWeight: Bool
    let currentWeight: Double?
    let weightUnit: WeightUnit
    let message: String

    /// Size of generated image (optimized for social media)
    static let imageSize = CGSize(width: 600, height: 315) // 1.91:1 ratio (Twitter/Facebook optimal)
}
```

## Message Templates

```swift
/// Templates for generating share messages
enum ShareMessageTemplate {

    // MARK: - Milestone Messages (Privacy Mode)

    static func milestonePrivacy(percentage: Int, hashtag: String) -> String {
        switch percentage {
        case 25: return "I just hit 25% of my goal! The journey continues. \(hashtag)"
        case 50: return "Halfway to my goal! 💪 Keep pushing! \(hashtag)"
        case 75: return "75% there! So close to my goal! \(hashtag)"
        case 100: return "I did it! Goal achieved! \(hashtag)"
        default: return "Making progress toward my goal! \(hashtag)"
        }
    }

    // MARK: - Milestone Messages (Full Mode)

    static func milestoneFull(
        percentage: Int,
        currentWeight: Double,
        unit: WeightUnit,
        hashtag: String
    ) -> String {
        let weightStr = String(format: "%.1f %@", currentWeight, unit.rawValue)
        switch percentage {
        case 25: return "Just hit \(weightStr) - 25% to my goal! \(hashtag)"
        case 50: return "At \(weightStr) - halfway there! \(hashtag)"
        case 75: return "Reached \(weightStr) - 75% to my goal! \(hashtag)"
        case 100: return "Goal achieved at \(weightStr)! \(hashtag)"
        default: return "Now at \(weightStr) - making progress! \(hashtag)"
        }
    }

    // MARK: - Progress Summary Messages

    static func progressSummaryPrivacy(
        durationDescription: String,
        direction: ProgressDirection,
        hashtag: String
    ) -> String {
        switch direction {
        case .toward: return "\(durationDescription) of consistency! Making progress! \(hashtag)"
        case .away: return "\(durationDescription) of tracking. Every day counts! \(hashtag)"
        case .stable: return "\(durationDescription) of maintaining. Steady progress! \(hashtag)"
        }
    }

    static func progressSummaryFull(
        weightChange: Double,
        durationDescription: String,
        unit: WeightUnit,
        isGain: Bool,
        hashtag: String
    ) -> String {
        let changeStr = String(format: "%.1f %@", abs(weightChange), unit.rawValue)
        let verb = isGain ? "gained" : "lost"
        return "\(verb.capitalized) \(changeStr) in \(durationDescription)! \(hashtag)"
    }
}

enum ProgressDirection {
    case toward  // Moving toward goal
    case away    // Moving away from goal
    case stable  // Maintaining
}
```

## View State (No SwiftData)

The sharing feature uses **no new SwiftData models**. All state is either:
1. Computed from existing models (`MilestoneAchievement`, `WeightEntry`)
2. Stored in `@AppStorage` (preferences)
3. Transient view state (`@State` for preview display)

### View State Example

```swift
struct SharePreviewView: View {
    let content: ShareableContent

    @State private var isShareSheetPresented = false
    @State private var showCopyConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // Preview content with Share/Cancel buttons
    }
}
```

## Query: Milestones Available for Sharing

```swift
/// Fetch milestones that can be shared (sorted by most recent)
@Query(sort: \MilestoneAchievement.dateAchieved, order: .reverse)
var shareableMilestones: [MilestoneAchievement]
```

## Sample Data for Previews

```swift
extension ShareableContent {
    static var sampleMilestone: ShareableContent {
        ShareableContent(
            contentType: .milestoneAchievement,
            title: "Progress Milestone",
            message: "I just hit 50% of my goal! The journey continues. #W8Trackr",
            image: nil, // Would be generated in real app
            progressPercentage: 50.0,
            milestoneType: .half,
            weightUnit: .lb,
            showsExactWeights: false,
            showsExactDates: false
        )
    }

    static var sampleProgress: ShareableContent {
        ShareableContent(
            contentType: .progressSummary,
            title: "My Progress",
            message: "3 months of consistency! Making progress! #W8Trackr",
            image: nil,
            progressPercentage: 45.0,
            milestoneType: nil,
            weightUnit: .lb,
            showsExactWeights: false,
            showsExactDates: true
        )
    }
}

extension SharingPreferences {
    static var samplePrivate: SharingPreferences {
        SharingPreferences(
            hideExactWeights: true,
            hideDates: true,
            includeGraphic: true,
            defaultHashtag: "#W8Trackr"
        )
    }

    static var sampleOpen: SharingPreferences {
        SharingPreferences(
            hideExactWeights: false,
            hideDates: false,
            includeGraphic: true,
            defaultHashtag: "#MyJourney"
        )
    }
}
```
