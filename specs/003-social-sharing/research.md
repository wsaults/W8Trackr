# Research: Social Sharing

**Feature**: 003-social-sharing
**Date**: 2025-01-09
**Purpose**: Phase 0 research to inform design decisions

## SwiftUI Sharing APIs

### ShareLink (iOS 16+)

SwiftUI provides `ShareLink` as the native way to present the system share sheet. Key findings:

**Basic Usage**:
```swift
ShareLink(item: URL(string: "https://example.com")!)
ShareLink(
    item: photo,
    subject: Text("Cool Photo"),
    message: Text("Check it out!"),
    preview: SharePreview(photo.caption, image: photo.image)
)
```

**Transferable Protocol**: Custom types must conform to `Transferable` to be shareable:
```swift
struct Photo: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(\.image)
    }
    var image: Image
    var caption: String
}
```

**SharePreview**: Provides custom preview for the share sheet:
```swift
SharePreview("Title", image: Image("preview"))
```

### Decision: Use ShareLink with Custom Transferable

**Chosen**: `ShareLink` with custom `ShareableContent: Transferable` type

**Rationale**:
- Native SwiftUI API (no UIKit bridging needed for basic sharing)
- Supports text + image sharing via `Transferable` protocol
- Built-in `SharePreview` for preview display
- iOS 16+ requirement matches our iOS 18.0+ target

**Alternative Rejected**: Direct `UIActivityViewController` via UIViewControllerRepresentable
- More boilerplate code
- Less type-safe
- ShareLink covers all our use cases

## Image Generation

### ImageRenderer (iOS 16+)

SwiftUI's `ImageRenderer` converts any SwiftUI view to `UIImage` or `CGImage`:

```swift
let renderer = ImageRenderer(content: progressView)
renderer.scale = UIScreen.main.scale
if let uiImage = renderer.uiImage {
    // Share or save image
}
```

**Key Considerations**:
- Must run on `@MainActor`
- `scale` property controls resolution (use device scale for crisp images)
- Returns optional - may fail on complex views
- iOS 16.0+ required (we target iOS 18.0+, so this is fine)

### Decision: ImageRenderer for Progress Graphics

**Chosen**: `ImageRenderer` to convert custom SwiftUI progress view to `UIImage`

**Rationale**:
- Native SwiftUI solution, no Core Graphics manual drawing
- Progress view can use same design system as app
- Easy to unit test the view component separately from rendering
- Supports dynamic type and accessibility automatically

**Alternative Rejected**: Core Graphics manual drawing
- More complex, error-prone
- Harder to match app's visual design
- No advantage for simple progress graphics

## Privacy Considerations

### Health Data Sensitivity

Weight data is considered sensitive health information. Best practices:

1. **Privacy by Default**: Hide exact weight values unless user explicitly opts in
2. **No External Transmission**: All content generated locally; no server logging of shares
3. **Preview Before Share**: User must see exactly what will be shared
4. **Minimal Data Exposure**: Percentages and relative changes preferred over absolutes

### Decision: Privacy-First Defaults

**Chosen Configuration**:
- `hideExactWeights`: `true` by default
- `hideDates`: `false` by default (relative dates are fine for most users)
- `includeGraphic`: `true` by default (visual is more engaging)

**Rationale**:
- Users who want to share exact weights can opt in
- Prevents accidental oversharing of sensitive data
- Aligns with Apple's health data privacy guidelines

## Content Formatting

### Platform Character Limits

| Platform | Character Limit |
|----------|-----------------|
| Twitter/X | 280 characters |
| SMS/iMessage | No practical limit |
| Email | No limit, but body preview ~100 chars |
| Instagram | Not applicable (image-based) |

### Decision: 140-Character Text Limit + Graphic

**Chosen**: Generate short text (≤140 chars) that works everywhere, plus optional graphic

**Rationale**:
- 140 chars fits all platforms including Twitter
- iOS share sheet allows user to edit before sending
- Graphic conveys more information without adding text length
- Focus on celebration message, not detailed stats

### Message Templates

**Milestone Achievement** (privacy mode):
- "I just hit 50% of my goal! 🎉 #W8Trackr"
- "Halfway to my weight goal! Keep pushing! 💪 #W8Trackr"

**Milestone Achievement** (full mode):
- "I just hit 180 lb - 50% to my goal! 🎉 #W8Trackr"

**Progress Summary** (privacy mode):
- "3 months of consistency! Making progress! 📈 #W8Trackr"

**Progress Summary** (full mode):
- "Lost 15 lb in 3 months! 50% to my goal! 📈 #W8Trackr"

## Dependency on 002-goal-notifications

### MilestoneAchievement Model

This feature depends on the `MilestoneAchievement` model from 002-goal-notifications:
- `milestoneType`: String (25, 50, 75, 100, approaching)
- `dateAchieved`: Date
- `weightAtAchievement`: Double
- `progressPercentage`: Double

### Integration Points

1. **Share from Notification**: When milestone notification appears, "Share" button triggers sharing flow
2. **Share from History**: MilestoneAchievement records can be shared after the fact
3. **Share from Summary**: GoalProgress calculation (from 002) provides current progress for summary shares

### Risk: 002 Not Yet Implemented

**Mitigation**: 003 can be developed in parallel if:
- MilestoneAchievement model exists (contract defined)
- Share feature can mock milestone data for testing
- Full integration happens when both features merge

## Clipboard Fallback

### Error Scenarios

1. Share sheet fails to present (rare)
2. User cancels share
3. No sharing destinations available

### Decision: UIPasteboard Fallback

**Chosen**: If ShareLink fails, offer "Copy to Clipboard" button

```swift
UIPasteboard.general.string = shareText
```

**Rationale**:
- Simple implementation
- Works offline
- Provides meaningful fallback for edge cases

## Architecture Summary

### Components

1. **ShareableContent**: Value type conforming to `Transferable`
   - Holds text, optional image, privacy-filtered values
   - Generated by `ShareContentGenerator`

2. **ShareContentGenerator**: Service with pure functions
   - `generateMilestoneContent(milestone:, preferences:) -> ShareableContent`
   - `generateProgressContent(progress:, preferences:) -> ShareableContent`

3. **ProgressImageRenderer**: Service for image creation
   - `renderProgressImage(progress:, preferences:) -> UIImage?`
   - Uses `ImageRenderer` internally

4. **SharePreviewView**: SwiftUI view for preview
   - Shows exactly what will be shared
   - Confirm/Cancel buttons

5. **ShareButton**: Reusable component
   - Integrates with `ShareLink`
   - Handles clipboard fallback

### Data Flow

```
MilestoneAchievement / GoalProgress
        ↓
ShareContentGenerator (applies privacy preferences)
        ↓
ShareableContent (Transferable)
        ↓
SharePreviewView (user reviews)
        ↓
ShareLink → iOS Share Sheet
```

## Sources

- [SwiftUI ShareLink Documentation](https://developer.apple.com/documentation/swiftui/sharelink)
- [SwiftUI SharePreview](https://developer.apple.com/documentation/swiftui/sharepreview)
- [SwiftUI ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer)
- [Transferable Protocol](https://developer.apple.com/documentation/coretransferable/transferable)
- Feature spec: `specs/003-social-sharing/spec.md`
- Dependency: `specs/002-goal-notifications/data-model.md`
