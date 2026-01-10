# [FEATURE NAME] - Beads Import

**Feature**: [###-feature-name]
**Generated**: [DATE]
**Source**: specs/[###-feature-name]/tasks.md

## Epic Structure

```
[Feature Name] (epic)
├── Setup (epic)
├── Foundational (epic) ← blocks all US*
├── US1: [Story Title] (epic) 🎯 MVP
├── US2: [Story Title] (epic)
├── US3: [Story Title] (epic) ← [note any dependencies]
└── Polish (epic) ← depends on US1-N
```

## Create Commands

Run these commands to create the beads hierarchy:

```bash
# =============================================================================
# ROOT EPIC
# =============================================================================
bd create "[Feature Name]" -t epic -p 1 -d "[Feature summary from spec or plan]"

# =============================================================================
# PHASE 1: SETUP ([N] tasks)
# =============================================================================
bd create "Setup: [Setup Purpose]" -t epic -p 1 -d "[Phase purpose from tasks.md]"

# [Generate bd create for each task in Setup phase]
# bd create "[Task title]" -t task -p 1 -d "[File path]"

# =============================================================================
# PHASE 2: FOUNDATIONAL ([N] tasks) - BLOCKS ALL USER STORIES
# =============================================================================
bd create "Foundational: [Foundational Purpose]" -t epic -p 1 -d "[Phase purpose]. Blocks all user stories."

# [Generate bd create for each task in Foundational phase]
# Tests first if TDD required
# bd create "[Test task title]" -t task -p 1 -d "[Test file path]"
# Then implementation
# bd create "[Impl task title]" -t task -p 1 -d "[Source file path]"

# =============================================================================
# PHASE 3: US1 - [USER STORY 1 TITLE] ([N] tasks) 🎯 MVP
# =============================================================================
bd create "US1: [Story Title]" -t epic -p 1 -d "[Story goal from tasks.md]"

# [Generate bd create for each task with [US1] label]
# bd create "US1: [Task title]" -t task -p 1 -d "[File path]"

# =============================================================================
# PHASE 4: US2 - [USER STORY 2 TITLE] ([N] tasks)
# =============================================================================
bd create "US2: [Story Title]" -t epic -p 2 -d "[Story goal from tasks.md]"

# [Generate bd create for each task with [US2] label]
# bd create "US2: [Task title]" -t task -p 2 -d "[File path]"

# =============================================================================
# PHASE 5: US3 - [USER STORY 3 TITLE] ([N] tasks)
# =============================================================================
bd create "US3: [Story Title]" -t epic -p 3 -d "[Story goal from tasks.md]. [Note dependencies if any]"

# [Generate bd create for each task with [US3] label]
# bd create "US3: [Task title]" -t task -p 3 -d "[File path]"

# =============================================================================
# PHASE N: POLISH ([N] tasks)
# =============================================================================
bd create "Polish: Cross-Cutting Concerns" -t epic -p [N] -d "[Phase purpose from tasks.md]"

# [Generate bd create for each task in Polish phase]
# bd create "[Task title]" -t task -p [N] -d "[File path or description]"
```

## Dependencies

After creating all beads, run these to set up the dependency graph:

```bash
# Get the IDs from bd list output, then:

# Foundational blocks all user stories
bd dep add <US1-epic-id> <Foundational-epic-id> --type blocks
bd dep add <US2-epic-id> <Foundational-epic-id> --type blocks
bd dep add <US3-epic-id> <Foundational-epic-id> --type blocks

# [Add any inter-story dependencies noted in tasks.md]
# Example: US3 depends on US1 AND US2
# bd dep add <US3-epic-id> <US1-epic-id> --type blocks
# bd dep add <US3-epic-id> <US2-epic-id> --type blocks

# Polish depends on all user stories
bd dep add <Polish-epic-id> <US1-epic-id> --type blocks
bd dep add <Polish-epic-id> <US2-epic-id> --type blocks
bd dep add <Polish-epic-id> <US3-epic-id> --type blocks

# Parent-child relationships (epics contain their tasks)
# bd dep add <task-id> <epic-id> --type parent-child
# (Run for each task under its respective phase epic)
```

## Task Summary

| Phase | Epic | Tasks | Priority |
|-------|------|-------|----------|
| Setup | [Setup Epic Name] | [N] | P1 |
| Foundational | [Foundational Epic Name] | [N] | P1 |
| US1 | [US1 Epic Name] | [N] | P1 🎯 MVP |
| US2 | [US2 Epic Name] | [N] | P2 |
| US3 | [US3 Epic Name] | [N] | P3 |
| Polish | Cross-Cutting Concerns | [N] | P[N] |
| **Total** | | **[TOTAL]** | |

## MVP Scope

Complete through **US1: [Story Title]** for minimum viable product:
- Setup ([N] tasks)
- Foundational ([N] tasks)
- US1 ([N] tasks)
- **Total MVP: [N] tasks**

## Notes

- [Note any constitution requirements like TDD, no UI tests, etc.]
- Tests must be written and fail before implementation (if TDD required)
- Each user story is independently testable
- Epics should be completed in priority order unless parallelizing

## Sources

- [Beads CLAUDE.md](https://github.com/steveyegge/beads/blob/main/CLAUDE.md)
- [Beads Quickstart](https://github.com/steveyegge/beads/blob/main/docs/QUICKSTART.md)
- [Gastown README](https://github.com/steveyegge/gastown)
