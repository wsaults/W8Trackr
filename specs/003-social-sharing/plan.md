# Implementation Plan: Social Sharing

**Branch**: `003-social-sharing` | **Date**: 2025-01-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-social-sharing/spec.md`

## Summary

Social sharing enables users to celebrate their weight journey by sharing milestone achievements and progress summaries with friends and family. Implementation uses iOS's native `UIActivityViewController` (via SwiftUI's `ShareLink`) for cross-platform sharing, with privacy-first defaults hiding exact weight values unless users opt in. Shareable content includes text messages and auto-generated progress graphics.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData, UIKit (for UIActivityViewController), Core Graphics (for image generation)
**Storage**: @AppStorage for sharing preferences; relies on MilestoneAchievement model from 002-goal-notifications
**Testing**: XCTest with unit tests for content generation and privacy filtering
**Target Platform**: iOS 18.0+
**Project Type**: iOS Mobile - single app
**Performance Goals**: Share preview loads in under 1 second (SC-002)
**Constraints**: Local only (no server); privacy by default (hide exact weights)
**Scale/Scope**: Single user, sharing up to 4 milestone types and unlimited progress summaries

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Simplicity-First | ✅ PASS | Uses native ShareLink/UIActivityViewController; no custom social network integrations; preferences in @AppStorage |
| II. TDD (NON-NEGOTIABLE) | ✅ PASS | All content generation and privacy filtering logic will have unit tests first |
| III. User-Centered Quality | ✅ PASS | Accessible share buttons; graceful fallback (clipboard); no destructive actions |

**Prohibited Patterns Check:**
- ❌ ViewModels: Not used - ShareableContent is a value type, preferences in @AppStorage
- ❌ NavigationView: Not applicable - share sheets are modal
- ❌ Combine for UI: Not used
- ❌ XCUITest: Not used - unit/integration tests only per constitution v1.1.0

## Project Structure

### Documentation (this feature)

```text
specs/003-social-sharing/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
W8Trackr/
├── Models/
│   ├── MilestoneAchievement.swift  # Existing from 002 - no changes
│   └── ShareableContent.swift      # NEW - value type for shareable data
├── Managers/
│   └── NotificationManager.swift   # Existing - no changes
├── Services/
│   ├── ShareContentGenerator.swift # NEW - generates text and image content
│   └── ProgressImageRenderer.swift # NEW - creates shareable progress graphics
├── Views/
│   ├── SharePreviewView.swift      # NEW - preview before sharing
│   ├── ShareButton.swift           # NEW - reusable share button component
│   └── SettingsView.swift          # EXTEND - add sharing preferences section

W8TrackrTests/
├── ShareContentGeneratorTests.swift  # NEW - content generation tests
├── ProgressImageRendererTests.swift  # NEW - image rendering tests
└── ShareableContentTests.swift       # NEW - privacy filtering tests
```

**Structure Decision**: Extends existing iOS Mobile structure. New `ShareContentGenerator` service for content generation (pure functions, easily testable). New `ProgressImageRenderer` for graphic generation. Preferences stored in @AppStorage (no new SwiftData models).

## Complexity Tracking

> No violations - feature aligns with all Constitution principles.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| (none) | — | — |

## Phase 0: Research (Next Step)

Research will focus on:
1. SwiftUI ShareLink API and customization options
2. Best practices for generating shareable images in SwiftUI
3. Privacy considerations for health-related data sharing

## Phase 1: Design (After Research)

Design deliverables:
1. `data-model.md` - ShareableContent struct, SharingPreferences structure
2. `contracts/` - ShareContentGenerator API, ProgressImageRenderer API
3. `quickstart.md` - Manual testing checklist for share flows and privacy scenarios
