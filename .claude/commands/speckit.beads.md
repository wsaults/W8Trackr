---
description: Generate Beads/Gastown epic hierarchy and bd create commands from tasks.md for multi-agent orchestration.
handoffs:
  - label: View Tasks
    agent: speckit.tasks
    prompt: View the tasks for this feature
    send: false
  - label: Implement Project
    agent: speckit.implement
    prompt: Start the implementation in phases
    send: true
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.specify/scripts/bash/check-prerequisites.sh --json` from repo root and parse FEATURE_DIR. Verify tasks.md exists in FEATURE_DIR.

2. **Load source documents**: Read from FEATURE_DIR:
   - **Required**: tasks.md (phases, task IDs, descriptions, file paths)
   - **Required**: spec.md (feature name, user story titles for epic names)
   - **Optional**: plan.md (for summary description)

3. **Parse tasks.md structure**:
   - Extract feature name from header
   - Identify all phases (Setup, Foundational, User Stories, Polish)
   - For each phase: extract phase name, purpose, task count
   - For each task: extract ID, [P] marker, [Story] label, description
   - Note dependencies mentioned in the Dependencies section

4. **Generate beads-import.md**: Use `.specify/templates/beads-template.md` as structure, fill with:
   - Feature name and metadata
   - Epic structure tree diagram
   - Root epic `bd create` command with feature summary
   - Phase epic `bd create` commands (one per phase)
   - Task `bd create` commands grouped under their phase epic
   - Priority mapping: P1 for Setup/Foundational/US1, P2 for US2, P3 for US3, etc.
   - Dependency commands section (blocks relationships between epics)
   - Task summary table
   - MVP scope section

5. **Report**: Output path to generated beads-import.md and summary:
   - Total epic count
   - Total task count
   - Epic hierarchy preview
   - Dependency graph summary

Context for beads generation: $ARGUMENTS

## Beads Generation Rules

### Epic Structure

Every feature generates this hierarchy:

```
[Feature Name] (root epic)
├── Setup (epic) - P1
├── Foundational (epic) - P1, blocks all US*
├── US1: [Story Title] (epic) - P1 🎯 MVP
├── US2: [Story Title] (epic) - P2
├── US3: [Story Title] (epic) - P3
└── Polish (epic) - P4, depends on all US*
```

### bd create Command Format

**Epics**:
```bash
bd create "[Epic Name]" -t epic -p [priority] -d "[Description from phase purpose or spec]"
```

**Tasks**:
```bash
bd create "[Task description without ID/markers]" -t task -p [priority] -d "[File path or additional context]"
```

### Priority Mapping

| Phase | Priority |
|-------|----------|
| Setup | 1 |
| Foundational | 1 |
| US1 (MVP) | 1 |
| US2 | 2 |
| US3 | 3 |
| US4+ | 4+ |
| Polish | (highest US priority + 1) |

### Task Transformation Rules

1. **Strip markers**: Remove `- [ ]`, task ID, `[P]`, `[US*]` from description
2. **Extract file path**: Use file path as `-d` description
3. **Clean title**: Use remaining description as task title
4. **Preserve order**: Tasks within a phase maintain their execution order

Example transformation:
```
Input:  - [ ] T012 [P] [US1] Create User model in src/models/user.py
Output: bd create "Create User model" -t task -p 1 -d "src/models/user.py"
```

### Dependency Rules

Generate these dependency commands:

1. **Foundational blocks all user stories**:
   ```bash
   bd dep add <US*-epic-id> <Foundational-epic-id> --type blocks
   ```

2. **Later stories may depend on earlier stories** (if noted in tasks.md):
   ```bash
   bd dep add <US3-epic-id> <US1-epic-id> --type blocks
   ```

3. **Polish depends on all user stories**:
   ```bash
   bd dep add <Polish-epic-id> <US*-epic-id> --type blocks
   ```

### Output Format

The generated beads-import.md should be immediately usable:
- Copy/paste `bd create` commands into terminal
- Commands are grouped by phase with clear section headers
- Dependency commands are separate (run after all creates)
- Summary table shows task counts per epic
