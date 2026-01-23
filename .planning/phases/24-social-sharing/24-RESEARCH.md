# Phase 24: Social Sharing - Research

**Researched:** 2026-01-23
**Domain:** iOS Image Generation and Social Sharing
**Confidence:** HIGH

## Summary

This phase implements social sharing functionality allowing users to generate and share progress images showing their weight journey statistics. The implementation leverages SwiftUI's native `ImageRenderer` for view-to-image conversion and `ShareLink` for the system share sheet. A privacy toggle allows users to hide exact weight values while still showing percentage progress.

The approach is straightforward: create a dedicated `ShareableProgressView` SwiftUI view that displays the user's stats, render it to a `UIImage` using `ImageRenderer`, and present it via `ShareLink`. The privacy mode simply swaps actual weight values for "hidden" placeholders in the view before rendering.

Existing contracts in `specs/003-social-sharing/contracts/` define the API structure. The `CompletedMilestone` model and `MilestoneProgress` types already exist. The app already uses `ShareLink` successfully in `ExportView.swift` with `Transferable` conformance.

**Primary recommendation:** Use `ImageRenderer` with a fixed-size SwiftUI view (600x315 for social media optimal ratio), set scale to `UIScreen.main.scale`, and share via `ShareLink` with custom `Transferable` conformance for the generated `UIImage`.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI ImageRenderer | iOS 16+ | Convert SwiftUI views to UIImage | Native API, handles all rendering complexity |
| SwiftUI ShareLink | iOS 16+ | Present system share sheet | Native API, automatic platform integration |
| UniformTypeIdentifiers | iOS 14+ | Define content types for sharing | Required for Transferable conformance |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UIKit (UIImage) | iOS 2+ | Image data representation | Target format for ImageRenderer |
| Core Transferable | iOS 16+ | Protocol for shareable content | Custom type sharing |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ImageRenderer | Core Graphics manual drawing | More complex, harder to maintain, no SwiftUI integration |
| ShareLink | UIActivityViewController wrapped | More boilerplate, less type-safe |
| PNG export | JPEG export | PNG better for graphics with gradients, text; larger file size acceptable |

**Installation:** No external dependencies required - all frameworks are part of iOS SDK.

## Architecture Patterns

### Recommended Project Structure
```
W8Trackr/
├── Views/
│   └── Sharing/
│       ├── ShareableProgressView.swift    # SwiftUI view rendered to image
│       ├── ShareProgressSheet.swift       # Sheet with preview + share button
│       └── ProgressImageGenerator.swift   # ImageRenderer wrapper
├── Models/
│   └── ShareableContent.swift             # Transferable wrapper for UIImage
└── Theme/
    └── (existing) Colors.swift, Gradients.swift
```

### Pattern 1: View-to-Image Rendering
**What:** Create a dedicated SwiftUI view specifically for rendering to image
**When to use:** When generating shareable graphics
**Example:**
```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image
@MainActor
struct ProgressImageGenerator {
    static func render(
        progressPercentage: Double,
        weightChange: Double,
        duration: String,
        showWeights: Bool,
        unit: WeightUnit
    ) -> UIImage? {
        let view = ShareableProgressView(
            progressPercentage: progressPercentage,
            weightChange: showWeights ? weightChange : nil,
            duration: duration,
            unit: unit
        )
        .frame(width: 600, height: 315)

        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
```

### Pattern 2: Transferable UIImage Wrapper
**What:** Wrap UIImage in a Transferable-conforming struct for ShareLink
**When to use:** When sharing generated images via ShareLink
**Example:**
```swift
// Source: https://developer.apple.com/forums/thread/747078
struct ShareableImage: Transferable {
    let image: UIImage
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { shareable in
            guard let data = shareable.image.pngData() else {
                throw ShareError.imageConversionFailed
            }
            return data
        }
    }
}

// Usage in view
ShareLink(
    item: ShareableImage(image: generatedImage, title: "My Progress"),
    preview: SharePreview("My Progress", image: Image(uiImage: generatedImage))
)
```

### Pattern 3: Privacy Toggle in Preferences
**What:** Store privacy setting in @AppStorage, apply when generating content
**When to use:** When user configures sharing preferences
**Example:**
```swift
// In Settings or ShareProgressSheet
@AppStorage("shareHideExactWeights") var hideExactWeights: Bool = true

// When generating share content
let showWeights = !hideExactWeights
let image = ProgressImageGenerator.render(
    progressPercentage: progress,
    weightChange: weightChange,
    duration: duration,
    showWeights: showWeights,
    unit: unit
)
```

### Anti-Patterns to Avoid
- **Rendering on background thread:** ImageRenderer MUST run on @MainActor - attempting background rendering will crash
- **Using default 1x scale:** Always set `renderer.scale = UIScreen.main.scale` for crisp images
- **Complex view hierarchies in render view:** Keep the shareable view simple; complex animations, Maps, WebViews will not render
- **Storing images in SwiftData:** Generated images are transient; regenerate on demand

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| View to image conversion | Core Graphics drawing | ImageRenderer | Handles all edge cases, respects layout |
| Share sheet presentation | UIActivityViewController wrapper | ShareLink | Type-safe, SwiftUI native |
| Image data serialization | Manual PNG encoding | UIImage.pngData() | Standard, well-tested |
| Content type declaration | String constants | UTType.png from UniformTypeIdentifiers | Type-safe, system-recognized |
| User preferences | Custom persistence | @AppStorage | Simple, automatic sync |

**Key insight:** iOS has mature, well-tested APIs for image generation and sharing. Custom solutions add complexity without benefit and may miss edge cases the system handles automatically.

## Common Pitfalls

### Pitfall 1: Rendering at 1x Scale
**What goes wrong:** Generated images appear blurry on Retina displays
**Why it happens:** ImageRenderer defaults to scale 1.0
**How to avoid:** Always set `renderer.scale = UIScreen.main.scale`
**Warning signs:** Shared images look fuzzy compared to app UI

### Pitfall 2: MainActor Violation
**What goes wrong:** Crash or undefined behavior
**Why it happens:** ImageRenderer requires main thread execution
**How to avoid:** Mark rendering functions with `@MainActor` or call from main thread
**Warning signs:** Runtime crash with actor isolation error

### Pitfall 3: Dynamic Type in Fixed-Size Views
**What goes wrong:** Text clips or overflows in rendered image
**Why it happens:** User may have large accessibility text size
**How to avoid:** Use fixed font sizes for shareable view, or use `.minimumScaleFactor()`
**Warning signs:** Truncated or overlapping text in shared images

### Pitfall 4: Missing Transferable Conformance
**What goes wrong:** ShareLink won't compile or share fails
**Why it happens:** Custom types must conform to Transferable
**How to avoid:** Implement `transferRepresentation` with correct content type
**Warning signs:** Compiler error about missing Transferable conformance

### Pitfall 5: Color Asset Dependencies
**What goes wrong:** Rendered image has wrong colors or crashes
**Why it happens:** ImageRenderer may not resolve asset catalog colors correctly
**How to avoid:** Use explicit Color values or AppColors.Fallback for shareable views
**Warning signs:** Wrong colors in shared image, works fine in app

## Code Examples

Verified patterns from official sources and existing codebase:

### Complete Shareable View (For Rendering)
```swift
// Source: Based on existing HeroCardView pattern + research
struct ShareableProgressView: View {
    let progressPercentage: Double
    let weightChange: Double?  // nil when privacy mode
    let duration: String
    let unit: WeightUnit

    // Use fixed sizes for consistent rendering
    private let width: CGFloat = 600
    private let height: CGFloat = 315

    var body: some View {
        ZStack {
            // Background gradient
            AppGradients.celebration

            VStack(spacing: 16) {
                // App branding
                Text("W8Trackr")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))

                // Progress percentage
                Text("\(Int(progressPercentage))%")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("of my goal")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.9))

                // Weight change (if showing)
                if let change = weightChange {
                    let sign = change > 0 ? "+" : ""
                    Text("\(sign)\(change.formatted(.number.precision(.fractionLength(1)))) \(unit.displayName)")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }

                // Duration
                Text(duration)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: width, height: height)
    }
}
```

### Image Generator Service
```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image
@MainActor
enum ProgressImageGenerator {
    /// Standard size for social media (1.91:1 ratio)
    static let imageSize = CGSize(width: 600, height: 315)

    static func generateProgressImage(
        progressPercentage: Double,
        weightChange: Double,
        duration: String,
        showWeights: Bool,
        unit: WeightUnit
    ) -> UIImage? {
        let view = ShareableProgressView(
            progressPercentage: progressPercentage,
            weightChange: showWeights ? weightChange : nil,
            duration: duration,
            unit: unit
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
```

### Transferable Wrapper (Existing Pattern)
```swift
// Source: Existing ExportView.swift + https://developer.apple.com/forums/thread/747078
struct ShareableProgressImage: Transferable {
    let image: UIImage
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { shareable in
            guard let data = shareable.image.pngData() else {
                throw CocoaError(.fileWriteUnknown)
            }
            return data
        }
    }
}
```

### Share Sheet Integration
```swift
// Source: Existing ExportView.swift pattern
struct ShareProgressSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("shareHideExactWeights") private var hideExactWeights = true

    let progressPercentage: Double
    let weightChange: Double
    let duration: String
    let unit: WeightUnit

    @State private var generatedImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Preview
                if let image = generatedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 12))
                        .padding()
                }

                // Privacy toggle
                Toggle("Hide exact weights", isOn: $hideExactWeights)
                    .padding(.horizontal)
                    .onChange(of: hideExactWeights) { _, _ in
                        regenerateImage()
                    }

                // Share button
                if let image = generatedImage {
                    ShareLink(
                        item: ShareableProgressImage(image: image, title: "My Progress"),
                        preview: SharePreview("My W8Trackr Progress", image: Image(uiImage: image))
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Share Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { regenerateImage() }
        }
    }

    private func regenerateImage() {
        generatedImage = ProgressImageGenerator.generateProgressImage(
            progressPercentage: progressPercentage,
            weightChange: weightChange,
            duration: duration,
            showWeights: !hideExactWeights,
            unit: unit
        )
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UIGraphicsImageRenderer | SwiftUI ImageRenderer | iOS 16 (2022) | SwiftUI-native, simpler API |
| UIActivityViewController wrapper | ShareLink | iOS 16 (2022) | Type-safe, declarative |
| Manual UTI strings | UniformTypeIdentifiers | iOS 14 (2020) | Type-safe content types |
| ObservableObject for preferences | @AppStorage | iOS 14 (2020) | Simpler, automatic persistence |

**Deprecated/outdated:**
- `UIGraphicsBeginImageContext`: Use ImageRenderer for SwiftUI views
- `UIActivityViewController` direct usage: Use ShareLink in SwiftUI
- String-based UTIs: Use UTType from UniformTypeIdentifiers

## Open Questions

Things that couldn't be fully resolved:

1. **Chart inclusion in shareable image**
   - What we know: ImageRenderer can render Charts framework views
   - What's unclear: Whether the existing WeightTrendChartView renders correctly in fixed-size context
   - Recommendation: Start with stats-only view; chart inclusion as enhancement if time permits

2. **Social media aspect ratios**
   - What we know: 1.91:1 (600x315) is optimal for Twitter/Facebook link previews
   - What's unclear: Whether Instagram Stories (9:16) or other ratios should be supported
   - Recommendation: Use 1.91:1 as single format; avoid scope creep with multiple formats

3. **App branding in shared image**
   - What we know: Including "W8Trackr" watermark is common practice
   - What's unclear: Exact placement and styling preferences
   - Recommendation: Top-center subtle branding as shown in code examples

## Sources

### Primary (HIGH confidence)
- [Hacking with Swift - ImageRenderer](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image) - Complete ImageRenderer usage pattern
- [SerialCoder.dev - ShareLink](https://serialcoder.dev/text-tutorials/swiftui/sharing-content-in-swiftui-with-sharelink/) - ShareLink and Transferable patterns
- [Apple Forums - UIImage Transferable](https://developer.apple.com/forums/thread/747078) - DataRepresentation for image sharing
- Existing codebase: `W8Trackr/Views/ExportView.swift` - Working ShareLink + Transferable implementation
- Existing codebase: `specs/003-social-sharing/` - Contracts and data model already defined

### Secondary (MEDIUM confidence)
- [DevFright - ShareLink Tutorial](https://www.devfright.com/how-to-use-sharelink-in-swiftui-to-share-text-images-and-urls/) - Additional ShareLink patterns
- [AppCoda - ImageRenderer](https://www.appcoda.com/imagerenderer-swiftui/) - iOS 26 compatible patterns

### Tertiary (LOW confidence)
- Social media optimal image dimensions (varies by platform, changes frequently)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Native iOS APIs, well-documented
- Architecture: HIGH - Follows existing codebase patterns, contracts already defined
- Pitfalls: HIGH - Well-documented common issues with ImageRenderer

**Research date:** 2026-01-23
**Valid until:** 60 days (stable APIs, unlikely to change)
