# Phase 25: Localization - Research

**Researched:** 2026-01-23
**Domain:** iOS SwiftUI Localization with String Catalogs
**Confidence:** HIGH

## Summary

This research covers localizing W8Trackr for Spanish-speaking users, focusing on three key areas: UI string translation, locale-aware number/date formatting, and App Store metadata. The current codebase has approximately 150 Text() calls across 30 files that need localization, plus Info.plist permission strings and widget text.

Apple's String Catalogs (.xcstrings), introduced in Xcode 15, are the standard approach for iOS localization. They automatically extract localizable strings from SwiftUI views after each build, eliminating the need for manual key management. The project targets iOS 26+ and Swift 6.2+, which fully supports the latest localization features including Xcode 26's symbol generation for compile-time safety.

For Spanish locale formatting, iOS handles number and date formatting automatically when using SwiftUI's built-in formatters (`.formatted()`, `Text(value, format:)`). Spanish (Spain) uses dots as thousands separators and commas as decimal separators (1.234,56), while dates follow Spanish conventions.

**Primary recommendation:** Create a Localizable.xcstrings String Catalog file, add Spanish localization, build to extract strings automatically, then translate. Use SwiftUI's built-in formatters for all numbers and dates.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| String Catalogs (.xcstrings) | Xcode 15+ | UI string management | Apple's recommended approach; auto-extraction; built-in plural/device variation support |
| SwiftUI Localization | iOS 16+ | Automatic string localization | Text(), Button() auto-localize string literals |
| Foundation Formatters | iOS 15+ | Locale-aware number/date formatting | Automatic locale detection; handles all regional variations |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| InfoPlist.xcstrings | Xcode 15+ | Permission string localization | Localizing NSHealthShareUsageDescription, etc. |
| App Store Connect | N/A | Metadata localization | Spanish app name, description, keywords |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| String Catalogs | .strings/.stringsdict | Legacy format; more manual work; no auto-extraction |
| Built-in formatters | Manual String(format:) | Incorrect; ignores locale; violates CLAUDE.md rules |

**Setup:**
No external dependencies needed. String Catalogs are built into Xcode.

## Architecture Patterns

### Recommended Project Structure
```
W8Trackr/
├── Localizable.xcstrings        # Main app strings (auto-created)
├── InfoPlist.xcstrings          # Permission descriptions
├── en.lproj/                    # (Auto-generated at build time)
│   └── Localizable.strings
└── es.lproj/                    # (Auto-generated at build time)
    └── Localizable.strings

W8TrackrWidget/
├── Localizable.xcstrings        # Widget-specific strings
└── InfoPlist.xcstrings          # Widget Info.plist strings (if needed)
```

### Pattern 1: SwiftUI Automatic Localization
**What:** SwiftUI views automatically localize string literals in Text(), Button(), etc.
**When to use:** All user-facing strings in SwiftUI views
**Example:**
```swift
// Source: Apple SwiftUI Localization documentation
// These are automatically localizable:
Text("Weight Settings")           // Extracted to String Catalog
Button("Save Changes") { ... }    // Extracted to String Catalog
Text("Goal Weight")               // Extracted to String Catalog

// For non-localized strings (code constants, identifiers):
Text(verbatim: "W8Trackr")        // NOT extracted
```

### Pattern 2: String(localized:) for Non-View Strings
**What:** Use String(localized:) for strings outside SwiftUI views
**When to use:** Accessibility labels, Siri intents, computed properties
**Example:**
```swift
// Source: Apple String Localization documentation
// For strings in accessibility labels or programmatic text:
let announcement = String(localized: "Entry saved")
UIAccessibility.post(notification: .announcement, argument: announcement)

// In App Intents:
static let title: LocalizedStringResource = "Log Weight"
```

### Pattern 3: Locale-Aware Number Formatting
**What:** Use SwiftUI's built-in format parameter
**When to use:** All weight, body fat, and numeric displays
**Example:**
```swift
// Source: CLAUDE.md coding standards
// CORRECT - Locale-aware:
Text(weight, format: .number.precision(.fractionLength(1)))

// INCORRECT - Ignores locale:
Text(String(format: "%.1f", weight))  // DO NOT USE
```

### Pattern 4: Locale-Aware Date Formatting
**What:** Use SwiftUI's date formatting or DateFormatter with locale
**When to use:** All date displays
**Example:**
```swift
// Source: SwiftUI documentation
// CORRECT - Locale-aware:
Text(date, format: .dateTime.month(.abbreviated).day())

// Or with DateFormatter:
let formatter = DateFormatter()
formatter.dateStyle = .medium  // Automatically uses device locale
formatter.string(from: date)   // Returns "10 de diciembre, 2026" for Spanish
```

### Pattern 5: Pluralization
**What:** String Catalog handles plural variations automatically
**When to use:** Any string with a count (days, weeks, entries)
**Example:**
```swift
// Source: Apple String Catalogs documentation
// In code:
Text("\(days) days to go!")

// In String Catalog, configure "Vary by Plural" for this key
// Provide translations for:
// - One: "1 day to go!"
// - Other: "%lld days to go!"
```

### Anti-Patterns to Avoid
- **String concatenation for sentences:** Different languages have different word orders. Use full sentences with placeholders.
- **Hardcoded number formatting:** Using String(format:) ignores locale settings. Always use .formatted() or Text(value, format:).
- **Assuming singular/plural:** Russian has 4 plural forms; Arabic has 6. Use String Catalog plural variations.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Number formatting | Custom "1,234.5" logic | `.formatted()` | Spanish uses "1.234,5"; locale rules are complex |
| Pluralization | `count == 1 ? "day" : "days"` | String Catalog "Vary by Plural" | Other languages have multiple plural forms |
| Date formatting | Manual "Dec 10, 2026" | `DateFormatter.dateStyle` | Spanish: "10 de dic. de 2026"; month case varies |
| Sentence building | Concatenating strings | Single localized sentence with placeholders | Word order varies by language |
| Unit display | Hardcoded "lbs"/"kg" | Consider Measurement APIs | (Low priority for v1) |

**Key insight:** Localization edge cases are endless. A single hardcoded assumption (like "plurals have 2 forms") breaks for Russian, Arabic, or Welsh speakers.

## Common Pitfalls

### Pitfall 1: Interpolated Variables Not Extracting
**What goes wrong:** `Text("Weight: \(weight)")` extracts the key as "Weight: %@" but the placeholder type matters
**Why it happens:** Xcode extracts %@ by default, but integers need %lld, floats need %f
**How to avoid:** After extraction, check the String Catalog and adjust format specifiers in translations
**Warning signs:** Numbers display incorrectly or crash in translated versions

### Pitfall 2: Forgetting Widget Localization
**What goes wrong:** Main app is localized but widgets show English
**Why it happens:** Widgets are a separate target with their own String Catalog
**How to avoid:** Create separate Localizable.xcstrings in W8TrackrWidget target
**Warning signs:** Widget gallery shows untranslated text

### Pitfall 3: Info.plist Strings Not Translating
**What goes wrong:** Permission dialogs appear in English for Spanish users
**Why it happens:** Info.plist strings need InfoPlist.xcstrings or InfoPlist.strings files
**How to avoid:** Create InfoPlist.xcstrings with keys matching Info.plist keys exactly
**Warning signs:** Permission prompts show English descriptions

### Pitfall 4: App Intents Not Localized
**What goes wrong:** Siri shows English phrases for Spanish device
**Why it happens:** AppShortcut phrases need LocalizedStringResource and InfoPlist strings
**How to avoid:** Use LocalizedStringResource for intent titles; localize AppShortcuts phrases
**Warning signs:** Shortcuts app shows English action names

### Pitfall 5: Computed Strings Missing from Catalog
**What goes wrong:** Strings built at runtime aren't extracted
**Why it happens:** Xcode only extracts compile-time string literals
**How to avoid:** Use String(localized:) for dynamic strings or add them manually to catalog
**Warning signs:** Some UI text remains in English despite localization

### Pitfall 6: Spanish Locale Number Grouping
**What goes wrong:** Numbers like "1234" not grouped as expected
**Why it happens:** CLDR data for Spanish has minimumGroupingDigits=2, so grouping starts at 5+ digits
**How to avoid:** Use default formatters; don't override grouping separator manually
**Warning signs:** "1234" displays as "1234" not "1.234" (this is correct per CLDR)

## Code Examples

Verified patterns from official sources:

### Creating String Catalog
```
File > New > File > String Catalog
Name: Localizable.xcstrings (or InfoPlist.xcstrings for plist strings)
Location: App target root
```

### Adding Spanish Localization
```
1. Select Localizable.xcstrings in Project Navigator
2. In Inspector panel, click "Localize..."
3. In Project settings > Info > Localizations, click "+"
4. Select "Spanish (es)" or "Spanish (Spain) (es-ES)"
5. Build project to extract strings
```

### Localizing Text Views (Auto-Extracted)
```swift
// Source: Apple SwiftUI Localization
// All of these are automatically extracted:
Text("Dashboard")
Text("Weight Settings")
Button("Save") { save() }
Label("Export Data", systemImage: "square.and.arrow.up")

// Section headers and footers:
Section {
    // content
} header: {
    Text("Reminders")  // Extracted
} footer: {
    Text("You'll receive a notification at the specified time.")  // Extracted
}
```

### Localizing Computed Strings
```swift
// Source: Apple String Localization
// For strings outside SwiftUI views:
var headerText: String {
    switch status {
    case .atGoal:
        return String(localized: "Goal Reached!")
    case .onTrack:
        return String(localized: "Goal Prediction")
    case .wrongDirection:
        return String(localized: "Trend Alert")
    }
}
```

### Localizing Strings with Variables
```swift
// Source: Apple String Catalogs documentation
// SwiftUI handles interpolation:
Text("About \(weeks) weeks away")

// In String Catalog, this appears as:
// Key: "About %lld weeks away"
// Spanish: "Aproximadamente %lld semanas"

// For plural-aware strings, use "Vary by Plural" in String Catalog
```

### Localizing Info.plist Permission Strings
```swift
// In InfoPlist.xcstrings (Spanish translation):
// Key: NSHealthShareUsageDescription
// Value: "W8Trackr lee tus datos de peso de Apple Salud para ayudarte a seguir tu progreso."

// Key: NSHealthUpdateUsageDescription
// Value: "W8Trackr guarda tus entradas de peso y grasa corporal en Apple Salud para mantener todos tus datos de salud en un solo lugar."
```

### Localizing App Intents
```swift
// Source: Apple App Intents documentation
// Intent title (already using LocalizedStringResource):
static let title: LocalizedStringResource = "Log Weight"

// Shortcut phrases need localization via String Catalog:
AppShortcut(
    intent: LogWeightIntent(),
    phrases: [
        "Log my weight in \(.applicationName)",  // English
        // Spanish phrases added in String Catalog
    ],
    shortTitle: "Log Weight",  // Localized via String Catalog
    systemImageName: "scalemass"
)
```

### Localizing Widgets
```swift
// Source: Apple WidgetKit documentation
// Widget display name and description are localized via String Catalog:
.configurationDisplayName("Weight Tracker")  // Add to widget's String Catalog
.description("See your current weight and progress at a glance.")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| .strings + .stringsdict files | String Catalogs (.xcstrings) | Xcode 15 (2023) | Single file for all translations; auto-extraction |
| NSLocalizedString() | String(localized:) | Swift 5.5 | Cleaner syntax; same functionality |
| Manual key management | Build-time extraction | Xcode 15 | Strings sync automatically with code |
| Separate files per language | Single catalog file | Xcode 15 | All translations visible in one editor |

**Deprecated/outdated:**
- `.strings` files: Still work but String Catalogs are preferred for new projects
- `.stringsdict` files: Replaced by String Catalog plural variations
- Manual genstrings tool: Replaced by Xcode build-time extraction

**New in Xcode 26:**
- Symbol generation for manually-added strings (compile-time safety)
- String catalog format 1.1
- Symbols are LocalizedStringResource (use directly in SwiftUI)

## Open Questions

Things that couldn't be fully resolved:

1. **Spanish Dialect: Spain vs Mexico**
   - What we know: App Store Connect supports both es-ES (Spain) and es-MX (Mexico)
   - What's unclear: Should we support both or just one?
   - Recommendation: Start with es-ES (Spanish - Spain) as it's the default "Spanish" in Xcode; add es-MX later if users request it

2. **App Store Metadata Translation Quality**
   - What we know: Need to translate name, description, keywords, what's new
   - What's unclear: Best approach for accurate, native-sounding translation
   - Recommendation: Have a native Spanish speaker review translations before submission

3. **Siri Phrase Localization**
   - What we know: AppShortcut phrases need localization
   - What's unclear: Exact mechanism for adding Spanish phrases in Xcode 26
   - Recommendation: Test with Spanish device to verify phrase recognition

## Sources

### Primary (HIGH confidence)
- [Apple Developer Documentation: Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [WWDC25: Explore localization with Xcode](https://developer.apple.com/videos/play/wwdc2025/225/)
- [WWDC23: Discover String Catalogs](https://developer.apple.com/videos/play/wwdc2023/10155/)
- [App Store Connect: App Store localizations](https://developer.apple.com/help/app-store-connect/reference/app-store-localizations/)

### Secondary (MEDIUM confidence)
- [Localization in Xcode 15 - Jacob Bartlett](https://blog.jacobstechtavern.com/p/localisation-in-xcode-15) - Comprehensive String Catalog guide
- [Swift Localization in 2025 - fline.dev](https://www.fline.dev/swift-localization-in-2025-best-practices-you-couldnt-use-before/) - Best practices overview
- [A Better Way to Localize Swift Packages - Daniel Saidi](https://danielsaidi.com/blog/2025/12/02/a-better-way-to-localize-swift-packages-with-xcode-string-catalogs) - String Catalog details
- [iOS Spanish Locale Formatting - Alberto de Bortoli](https://albertodebortoli.com/2020/01/06/the-ios-internationalization-basics-i-keep-forgetting/) - Number/date formatting for Spanish

### Tertiary (LOW confidence)
- [Localizing permissions in iOS - Medium](https://medium.com/@axmadxojaibrohimov/localizing-permissions-in-ios-app-ebe4ef72f3a0) - Info.plist localization steps

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Apple documentation is definitive
- Architecture: HIGH - SwiftUI localization is well-documented
- Number/Date formatting: HIGH - Foundation formatters are battle-tested
- Pitfalls: MEDIUM - Based on community patterns and Apple forums

**Research date:** 2026-01-23
**Valid until:** 90 days (localization patterns are stable)
