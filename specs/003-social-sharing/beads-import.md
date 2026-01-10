# Social Sharing - Beads Import

**Feature**: 003-social-sharing
**Generated**: 2025-01-09
**Source**: specs/003-social-sharing/tasks.md

## Epic Structure

```
Social Sharing (epic)
├── Setup (epic) - 4 tasks
├── Foundational (epic) - 8 tasks ← blocks all US*
├── US1: Share Milestone Achievement (epic) - 11 tasks 🎯 MVP
├── US2: Share Progress Summary (epic) - 11 tasks
├── US3: Privacy Controls (epic) - 6 tasks
└── Polish (epic) - 10 tasks ← depends on US1-3
```

## Create Commands

Run these commands to create the beads hierarchy:

```bash
# =============================================================================
# ROOT EPIC
# =============================================================================
bd create "Social Sharing" -t epic -p 1 -d "Enable users to share milestone achievements and progress summaries with friends/family via native iOS share sheet"

# =============================================================================
# PHASE 1: SETUP (4 tasks)
# =============================================================================
bd create "Setup: Shared Infrastructure" -t epic -p 1 -d "Create foundational types and @AppStorage keys for sharing preferences"

bd create "Create ShareType enum" -t task -p 1 -d "W8Trackr/Models/ShareType.swift"
bd create "Create SharingPreferences with @AppStorage keys" -t task -p 1 -d "W8Trackr/Models/SharingPreferences.swift"
bd create "Create ShareableContent stub with Transferable placeholder" -t task -p 1 -d "W8Trackr/Models/ShareableContent.swift"
bd create "Create ShareMessageTemplate enum" -t task -p 1 -d "W8Trackr/Models/ShareMessageTemplate.swift"

# =============================================================================
# PHASE 2: FOUNDATIONAL (8 tasks) - BLOCKS ALL USER STORIES
# =============================================================================
bd create "Foundational: ShareContentGenerator TDD" -t epic -p 1 -d "Implement ShareContentGenerator service with full TDD. Blocks all user stories."

# Tests (Write First - RED)
bd create "Test: ShareContentGenerator milestone message generation" -t task -p 1 -d "W8TrackrTests/ShareContentGeneratorTests.swift - privacy mode, full mode, milestone percentages"
bd create "Test: ShareContentGenerator duration formatting" -t task -p 1 -d "W8TrackrTests/ShareContentGeneratorTests.swift - days, months, years, relative dates"
bd create "Test: ShareableContent Transferable conformance" -t task -p 1 -d "W8TrackrTests/ShareableContentTests.swift - fullText, preview, transfer representation"

# Implementation (GREEN)
bd create "Implement ShareContentGenerator.generateMilestoneMessage()" -t task -p 1 -d "W8Trackr/Services/ShareContentGenerator.swift"
bd create "Implement ShareContentGenerator.formatDuration()" -t task -p 1 -d "W8Trackr/Services/ShareContentGenerator.swift"
bd create "Implement ShareContentGenerator.canShareMilestone()" -t task -p 1 -d "W8Trackr/Services/ShareContentGenerator.swift"
bd create "Implement ShareableContent Transferable conformance" -t task -p 1 -d "W8Trackr/Models/ShareableContent.swift"
bd create "Add sample data extensions to ShareableContent" -t task -p 1 -d "W8Trackr/Models/ShareableContent.swift - for previews"

# =============================================================================
# PHASE 3: US1 - SHARE MILESTONE ACHIEVEMENT (11 tasks) 🎯 MVP
# =============================================================================
bd create "US1: Share Milestone Achievement" -t epic -p 1 -d "Users can share milestone achievements via native share sheet within 2 taps (SC-001)"

# Tests (Write First - RED)
bd create "US1: Test ShareMilestone content generation" -t task -p 1 -d "W8TrackrTests/ShareMilestoneTests.swift - creates content, respects privacy, includes progress"
bd create "US1: Test generateMilestoneContent privacy modes" -t task -p 1 -d "W8TrackrTests/ShareContentGeneratorTests.swift - hide weights, show weights, neutral language"

# Implementation (GREEN)
bd create "US1: Implement ShareContentGenerator.generateMilestoneContent()" -t task -p 1 -d "W8Trackr/Services/ShareContentGenerator.swift"
bd create "US1: Create SharePreviewView" -t task -p 1 -d "W8Trackr/Views/SharePreviewView.swift - preview with message and optional image"
bd create "US1: Create ShareButton component" -t task -p 1 -d "W8Trackr/Views/ShareButton.swift - reusable ShareLink wrapper"
bd create "US1: Add share button to milestone celebration view" -t task -p 1 -d "Integrate with 002-goal-notifications"
bd create "US1: Add Copy to Clipboard fallback" -t task -p 1 -d "W8Trackr/Views/SharePreviewView.swift - FR-011"

# Image Rendering
bd create "US1: Test ProgressImageRenderer milestone rendering" -t task -p 1 -d "W8TrackrTests/ProgressImageRendererTests.swift - returns UIImage, standard size, progress ring"
bd create "US1: Implement MilestoneGraphicView" -t task -p 1 -d "W8Trackr/Services/ProgressImageRenderer.swift"
bd create "US1: Implement ProgressImageRenderer.renderMilestoneImage()" -t task -p 1 -d "W8Trackr/Services/ProgressImageRenderer.swift - uses ImageRenderer"
bd create "US1: Integrate image rendering into SharePreviewView" -t task -p 1 -d "When includeGraphic preference is true"

# =============================================================================
# PHASE 4: US2 - SHARE PROGRESS SUMMARY (11 tasks)
# =============================================================================
bd create "US2: Share Progress Summary" -t epic -p 2 -d "Users can share overall journey progress from summary view"

# Tests (Write First - RED)
bd create "US2: Test generateProgressContent methods" -t task -p 2 -d "W8TrackrTests/ShareContentGeneratorTests.swift - weight change, trend, privacy, tone"
bd create "US2: Test canShareProgress validation" -t task -p 2 -d "W8TrackrTests/ShareContentGeneratorTests.swift - 7+ days, 2+ entries"

# Implementation (GREEN)
bd create "US2: Implement ShareContentGenerator.generateProgressContent()" -t task -p 2 -d "W8Trackr/Services/ShareContentGenerator.swift"
bd create "US2: Implement ShareContentGenerator.generateProgressMessage()" -t task -p 2 -d "W8Trackr/Services/ShareContentGenerator.swift - weight-neutral language"
bd create "US2: Implement ShareContentGenerator.canShareProgress()" -t task -p 2 -d "W8Trackr/Services/ShareContentGenerator.swift - validation"
bd create "US2: Add Share Progress button to SummaryView" -t task -p 2 -d "W8Trackr/Views/SummaryView.swift"
bd create "US2: Show Log more entries guidance" -t task -p 2 -d "When canShareProgress returns false"

# Image Rendering
bd create "US2: Test ProgressImageRenderer progress rendering" -t task -p 2 -d "W8TrackrTests/ProgressImageRendererTests.swift - returns UIImage, progress bar, duration"
bd create "US2: Implement ProgressGraphicView" -t task -p 2 -d "W8Trackr/Services/ProgressImageRenderer.swift"
bd create "US2: Implement ProgressImageRenderer.renderProgressImage()" -t task -p 2 -d "W8Trackr/Services/ProgressImageRenderer.swift - uses ImageRenderer"
bd create "US2: Integrate progress image into share flow" -t task -p 2 -d "When includeGraphic preference is true"

# =============================================================================
# PHASE 5: US3 - PRIVACY CONTROLS (6 tasks)
# =============================================================================
bd create "US3: Privacy Controls" -t epic -p 3 -d "Users can configure sharing privacy settings in Settings"

# Tests (Write First - RED)
bd create "US3: Test SharingPreferences defaults" -t task -p 3 -d "W8TrackrTests/SharingPreferencesTests.swift - privacy-first, persistence"
bd create "US3: Test share content respects privacy settings" -t task -p 3 -d "Integration tests - hide weights, hide dates, include graphic"

# Implementation (GREEN)
bd create "US3: Create SharingPreferencesSection view" -t task -p 3 -d "SettingsView component"
bd create "US3: Add sharing preferences to SettingsView" -t task -p 3 -d "W8Trackr/Views/SettingsView.swift - toggles and hashtag field"
bd create "US3: Verify SharePreviewView updates on settings change" -t task -p 3 -d "Instant refresh"
bd create "US3: Add VoiceOver labels to preference controls" -t task -p 3 -d "FR-008 accessibility"

# =============================================================================
# PHASE 6: POLISH (10 tasks)
# =============================================================================
bd create "Polish: Integration and Cross-Cutting Concerns" -t epic -p 4 -d "Connect all components, add milestone history sharing, final polish"

# Milestone History Integration
bd create "Add share button to milestone detail view" -t task -p 4 -d "Milestone history integration"
bd create "Ensure past milestones can be shared" -t task -p 4 -d "US1 Scenario 1.2"

# Edge Cases
bd create "Handle: No achievements yet" -t task -p 4 -d "Share option hidden/disabled"
bd create "Handle: Weight gain goal" -t task -p 4 -d "Neutral language verification"
bd create "Handle: No goal set" -t task -p 4 -d "Progress shares disabled"
bd create "Handle: Profile name not set" -t task -p 4 -d "Generic message, no placeholders"

# Performance & Polish
bd create "Verify share preview load time < 1 second" -t task -p 4 -d "SC-002"
bd create "Verify 2-tap share initiation path" -t task -p 4 -d "SC-001"
bd create "Add haptic feedback on successful share" -t task -p 4 -d "Polish"
bd create "Run quickstart.md full validation" -t task -p 4 -d "Complete manual testing checklist"
```

## Dependencies

After creating all beads, run these to set up the dependency graph:

```bash
# Get the IDs from bd list output, then:

# Foundational blocks all user stories
bd dep add <US1-epic-id> <Foundational-epic-id> --type blocks
bd dep add <US2-epic-id> <Foundational-epic-id> --type blocks
bd dep add <US3-epic-id> <Foundational-epic-id> --type blocks

# Polish depends on all user stories
bd dep add <Polish-epic-id> <US1-epic-id> --type blocks
bd dep add <Polish-epic-id> <US2-epic-id> --type blocks
bd dep add <Polish-epic-id> <US3-epic-id> --type blocks

# Parent-child relationships (epics contain their tasks)
# Run bd list to get IDs, then add parent-child for each task under its epic
```

## Task Summary

| Phase | Epic | Tasks | Priority |
|-------|------|-------|----------|
| Setup | Shared Infrastructure | 4 | P1 |
| Foundational | ShareContentGenerator TDD | 8 | P1 |
| US1 | Share Milestone Achievement | 11 | P1 🎯 MVP |
| US2 | Share Progress Summary | 11 | P2 |
| US3 | Privacy Controls | 6 | P3 |
| Polish | Integration and Cross-Cutting | 10 | P4 |
| **Total** | | **50** | |

## MVP Scope

Complete through **US1: Share Milestone Achievement** for minimum viable product:
- Setup (4 tasks)
- Foundational (8 tasks)
- US1 (11 tasks)
- **Total MVP: 23 tasks**

## Dependency Graph

```
                    Setup (4)
                       │
                       ▼
                 Foundational (8)
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
    US1 (11)       US2 (11)       US3 (6)
    P1 🎯 MVP       P2             P3
        │              │              │
        └──────────────┼──────────────┘
                       │
                       ▼
                 Polish (10)
                    P4
```

## Notes

- Constitution v1.1.0 mandates TDD - tests MUST fail before implementation
- No XCUITest per constitution - unit/integration tests only
- @AppStorage for preferences, not SwiftData (simplicity principle)
- Uses existing MilestoneAchievement from 002-goal-notifications
- Each user story is independently testable after Foundational phase

## Sources

- [Beads CLAUDE.md](https://github.com/steveyegge/beads/blob/main/CLAUDE.md)
- [Beads Quickstart](https://github.com/steveyegge/beads/blob/main/docs/QUICKSTART.md)
- [Gastown README](https://github.com/steveyegge/gastown)
