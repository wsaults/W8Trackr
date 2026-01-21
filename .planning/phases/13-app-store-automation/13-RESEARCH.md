# Phase 13: App Store Automation - Research

**Researched:** 2026-01-21
**Domain:** iOS CI/CD, fastlane, GitHub Actions, App Store Connect
**Confidence:** HIGH

## Summary

This phase focuses on enhancing and completing the existing App Store automation infrastructure for W8Trackr. The project already has a solid foundation with fastlane configured (Fastfile, Appfile, Snapfile), GitHub Actions workflows (test.yml, testflight.yml), metadata structure, and screenshot UI tests. The remaining work involves: adding the `ITSAppUsesNonExemptEncryption` key to Info.plist, enhancing CI with SwiftLint, updating device targets for 2026 App Store requirements, and ensuring all components work together seamlessly.

Key findings: The project is well-positioned with existing infrastructure. The main gaps are (1) missing export compliance key in Info.plist, (2) CI workflow doesn't run SwiftLint, (3) screenshot device list needs updating to match 2026 App Store requirements, and (4) Gemfile.lock is missing (gitignored but should be generated).

**Primary recommendation:** Complete the existing automation setup by adding ITSAppUsesNonExemptEncryption=NO to Info.plist, adding SwiftLint to CI workflow, and updating Snapfile devices to capture 6.9" iPhone and 13" iPad screenshots (2026 mandatory sizes).

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| fastlane | latest (2.x) | iOS automation platform | Industry standard, official Apple API support |
| GitHub Actions | macos-15 runner | CI/CD platform | Native macOS support, good fastlane integration |
| Xcode | 16.2+ | Build toolchain | Required for iOS 26 SDK |
| SwiftLint | latest | Code quality | Already configured in project |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ruby/setup-ruby@v1 | v1 | Ruby environment | GitHub Actions for fastlane |
| actions/checkout@v4 | v4 | Git checkout | All CI workflows |
| actions/upload-artifact@v4 | v4 | Artifact storage | Test results, screenshots |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| GitHub Actions | Bitrise/CircleCI | More iOS-specific features but higher cost |
| fastlane match | Manual signing | Match adds complexity but better team scaling |
| fastlane snapshot | Manual screenshots | Automation essential for consistency |

**Installation:**
```bash
# Already configured via Gemfile
bundle install
```

## Architecture Patterns

### Current Project Structure (Already Implemented)
```
W8Trackr/
├── .github/
│   └── workflows/
│       ├── test.yml          # CI: build + test on push/PR
│       └── testflight.yml    # CD: deploy on version tags
├── fastlane/
│   ├── Appfile               # App identifier + team config
│   ├── Fastfile              # Lane definitions
│   ├── Snapfile              # Screenshot configuration
│   ├── api_key.json.example  # Template for API auth
│   ├── README.md             # Setup documentation
│   └── metadata/
│       ├── en-US/            # Localized metadata
│       │   ├── description.txt
│       │   ├── keywords.txt
│       │   ├── name.txt
│       │   ├── release_notes.txt
│       │   └── ...
│       ├── review_information/
│       └── copyright.txt
├── W8TrackrUITests/
│   ├── ScreenshotTests.swift # UI tests for screenshots
│   └── SnapshotHelper.swift  # fastlane snapshot helper
└── Gemfile                   # Ruby dependencies
```

### Pattern 1: Export Compliance Declaration
**What:** Add ITSAppUsesNonExemptEncryption key to Info.plist
**When to use:** All apps that only use standard HTTPS (URLSession)
**Example:**
```xml
<!-- Source: https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption -->
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### Pattern 2: SwiftLint in CI (Missing)
**What:** Add SwiftLint step to GitHub Actions workflow
**When to use:** Every CI pipeline for Swift projects
**Example:**
```yaml
# Source: https://docs.fastlane.tools/actions/swiftlint/
- name: Run SwiftLint
  run: |
    brew install swiftlint
    swiftlint lint --strict --reporter github-actions-logging
```

### Pattern 3: App Store Connect API Authentication
**What:** Use API key JSON for headless CI authentication
**When to use:** All CI/CD pipelines (avoids 2FA issues)
**Example:**
```json
// Source: https://docs.fastlane.tools/app-store-connect-api/
{
  "key_id": "YOUR_KEY_ID",
  "issuer_id": "YOUR_ISSUER_ID",
  "key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
  "in_house": false
}
```

### Anti-Patterns to Avoid
- **Using Apple ID + Password auth:** Breaks in CI due to 2FA requirements
- **Committing api_key.json:** Security risk; use secrets instead
- **Hardcoding device names:** Use variables for easier updates
- **Skipping screenshots:** Manually updating screenshots is error-prone

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Screenshot capture | Custom XCUITest scripts | fastlane snapshot | Handles devices, locales, status bar |
| Build numbering | Manual increment | `increment_build_number` action | Fetches latest from App Store Connect |
| Metadata upload | App Store Connect UI | fastlane deliver | Automation, version control |
| Code signing | Manual cert management | Xcode automatic or fastlane match | Match handles team sharing |
| Export compliance | Manual each submission | Info.plist key | One-time setup, automatic bypass |

**Key insight:** The existing fastlane setup already handles most complexity. The remaining work is configuration completion, not new tooling.

## Common Pitfalls

### Pitfall 1: Missing Export Compliance Key
**What goes wrong:** Every TestFlight/App Store submission requires manually answering encryption questions
**Why it happens:** Info.plist key not added during initial setup
**How to avoid:** Add `ITSAppUsesNonExemptEncryption = NO` to Info.plist
**Warning signs:** "Missing Compliance" warning in App Store Connect

### Pitfall 2: Outdated Screenshot Device List
**What goes wrong:** App Store rejects submission or screenshots look wrong
**Why it happens:** Apple changed mandatory sizes in 2025/2026
**How to avoid:** Use 6.9" iPhone (iPhone 16 Pro Max) and 13" iPad (iPad Pro M4/M5)
**Warning signs:** Current Snapfile lists iPhone 15 Pro Max (6.7") not iPhone 16 Pro Max (6.9")

### Pitfall 3: Simulator Not Available in CI
**What goes wrong:** `fastlane test` or `fastlane screenshots` fails with "Simulator not found"
**Why it happens:** Simulator names change with Xcode versions
**How to avoid:** Use device names matching installed Xcode version; check availability with `xcrun simctl list`
**Warning signs:** CI failures mentioning "Unable to find a simulator"

### Pitfall 4: API Key Format Issues
**What goes wrong:** Authentication fails in CI
**Why it happens:** P8 key newlines incorrectly encoded in JSON
**How to avoid:** Base64 encode the entire key content for GitHub secrets
**Warning signs:** "Invalid API key" errors in fastlane output

### Pitfall 5: Build Timeout in GitHub Actions
**What goes wrong:** macOS runner times out during build
**Why it happens:** Free tier runners have limited resources; iOS builds are slow
**How to avoid:** Use caching, avoid unnecessary clean builds, consider larger runners for production
**Warning signs:** Builds exceeding 30+ minutes consistently

## Code Examples

Verified patterns from official sources:

### Info.plist Export Compliance Entry
```xml
<!-- Source: https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing keys... -->
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
</dict>
</plist>
```

### Updated Snapfile Device List (2026 Requirements)
```ruby
# Source: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/
# 6.9" display - MANDATORY (or 6.5")
# 13" display - MANDATORY for iPad apps
devices([
  "iPhone 16 Pro Max",    # 6.9" - 1320 x 2868 px (mandatory)
  "iPhone 14 Plus",       # 6.5" - 1284 x 2778 px (fallback)
  "iPad Pro 13-inch (M4)" # 13" - 2064 x 2752 px (mandatory for iPad)
])
```

### GitHub Actions SwiftLint Step
```yaml
# Source: https://docs.fastlane.tools/actions/swiftlint/
- name: Run SwiftLint
  run: |
    brew install swiftlint
    swiftlint lint --strict --reporter github-actions-logging
  continue-on-error: false
```

### Fastlane Test Lane with SwiftLint
```ruby
# Source: https://docs.fastlane.tools/actions/swiftlint/
lane :lint do
  swiftlint(
    mode: :lint,
    strict: true,
    reporter: "github-actions-logging",
    raise_if_swiftlint_error: true
  )
end

lane :ci do
  lint
  test
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 6.7" iPhone mandatory | 6.9" OR 6.5" mandatory | 2025-2026 | Update device list |
| 12.9" iPad mandatory | 13" iPad mandatory | 2025-2026 | Update device list |
| Apple ID auth | App Store Connect API | 2019+ but now enforced | Use API keys only |
| Manual compliance | Info.plist key | Always available | Add key once |
| Xcode 15/16 runners | Xcode 16.2+ on macos-15 | 2025 | Update workflow |

**Deprecated/outdated:**
- iPhone 15 Pro Max (6.7") screenshots: No longer mandatory; use 6.9" or 6.5"
- iPad Pro 12.9" (6th gen): Scaled from 13" now
- Apple ID password authentication: Unreliable due to 2FA

## Current Project State Analysis

### Already Complete
1. **Fastfile** - Has test, build, beta, release, screenshots, frames lanes
2. **Appfile** - Configured with bundle ID, team ID, API key support
3. **Snapfile** - Screenshot configuration (needs device update)
4. **GitHub Actions test.yml** - CI on push/PR
5. **GitHub Actions testflight.yml** - Deploy on version tags
6. **Metadata structure** - en-US locale with description, keywords, etc.
7. **ScreenshotTests.swift** - 6 screenshot scenarios
8. **SnapshotHelper.swift** - fastlane integration

### Needs Completion
1. **Info.plist** - Add ITSAppUsesNonExemptEncryption = NO
2. **Snapfile** - Update device list for 2026 requirements
3. **test.yml** - Add SwiftLint step
4. **Gemfile.lock** - Generate (currently gitignored but should exist locally)
5. **Validation** - Test full workflow end-to-end

### Optional Enhancements
1. Add `frameit` configuration for device frames on screenshots
2. Add Danger for PR reviews
3. Add caching to CI workflow for faster builds

## Open Questions

Things that couldn't be fully resolved:

1. **Xcode 26 Simulator Names**
   - What we know: Current Snapfile uses "iPhone 17" which may not exist yet
   - What's unclear: Exact simulator names for Xcode 26/iOS 26
   - Recommendation: Use current devices (iPhone 16 Pro Max) and update when Xcode 26 is released

2. **GitHub Actions macos-15 + Xcode 26**
   - What we know: macos-15 runners support Xcode 16.x; Xcode 26 beta may not be available
   - What's unclear: When Xcode 26 will be available on GitHub-hosted runners
   - Recommendation: Use Xcode 16.2 for now; iOS 26 SDK requires Xcode 26

3. **Screenshot Test Reliability**
   - What we know: UI tests can be flaky, especially with animations
   - What's unclear: Current test stability with sample data
   - Recommendation: Run screenshots locally first to validate tests work

## Sources

### Primary (HIGH confidence)
- [Apple Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/) - 2026 requirements verified
- [Apple ITSAppUsesNonExemptEncryption](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption) - Official key documentation
- [fastlane App Store Deployment](https://docs.fastlane.tools/getting-started/ios/appstore-deployment/) - Official setup guide
- [fastlane snapshot](https://docs.fastlane.tools/actions/snapshot/) - Screenshot automation
- [fastlane deliver](https://docs.fastlane.tools/actions/deliver/) - Metadata upload

### Secondary (MEDIUM confidence)
- [GitHub Actions iOS CI best practices](https://www.runway.team/blog/how-to-set-up-a-ci-cd-pipeline-for-your-ios-app-fastlane-github-actions) - Workflow patterns
- [SwiftLint GitHub Actions](https://github.com/realm/SwiftLint) - Integration patterns

### Tertiary (LOW confidence)
- WebSearch results for "macos-15 Xcode 16" - Performance notes (verify with actual usage)

## Metadata

**Confidence breakdown:**
- Export compliance: HIGH - Official Apple documentation
- Screenshot requirements: HIGH - Official Apple specifications
- CI/CD patterns: HIGH - fastlane official documentation
- Device simulator names: MEDIUM - May change with new Xcode versions
- Performance optimization: LOW - Based on community reports

**Research date:** 2026-01-21
**Valid until:** 2026-04-21 (90 days - stable domain, but Apple may update requirements)
