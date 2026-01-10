<!--
  SYNC IMPACT REPORT
  ==================
  Version Change: 1.0.0 → 1.1.0 (MINOR - added UI test prohibition)

  Modified Principles:
  - II. Test-Driven Development: Added "No UI tests" rule

  Added Sections: None
  Removed Sections: None

  Templates Requiring Updates:
  - .specify/templates/plan-template.md: ✅ No changes needed
  - .specify/templates/spec-template.md: ✅ No changes needed
  - .specify/templates/tasks-template.md: ✅ No changes needed
  - .specify/templates/checklist-template.md: ✅ No changes needed
  - .specify/templates/agent-file-template.md: ✅ No changes needed

  Follow-up TODOs: None
-->

# W8Trackr Constitution

## Core Principles

### I. Simplicity-First Architecture

Every architectural decision MUST favor simplicity over flexibility.

**Non-Negotiable Rules:**
- **No ViewModels**: Views own their state directly via `@State`, `@Binding`, `@Query`
- **No unnecessary abstractions**: Repository patterns, protocol-heavy architectures, and service layers are prohibited unless justified in a Complexity Tracking table
- **Direct data flow**: SwiftData `@Query` binds directly to views; no intermediate layers
- **YAGNI**: Do not build for hypothetical future requirements

**Rationale**: Complex architectures create cognitive overhead without proportional benefit for a focused weight tracking app. The SwiftUI + SwiftData stack is expressive enough to handle all W8Trackr requirements without additional abstraction layers.

### II. Test-Driven Development (NON-NEGOTIABLE)

All feature implementation MUST follow the TDD cycle. This principle cannot be waived.

**Non-Negotiable Rules:**
- **Red-Green-Refactor**: Tests MUST be written and fail before implementation begins
- **Unit tests required**: All business logic (weight conversions, trend calculations, date handling) MUST have unit test coverage
- **Integration tests for user flows**: Critical user journeys MUST have integration test validation
- **No implementation without failing tests**: PRs that add functionality without corresponding tests MUST be rejected
- **No UI tests**: UI tests (XCUITest) are prohibited. Unit and integration tests provide sufficient coverage; manual device testing validates UI.

**Rationale**: Weight tracking is health-related data. Users trust the app to correctly store, convert, and display their weight. Bugs in weight conversion or trend calculation directly harm user trust and potentially health decisions. UI tests are excluded because they are brittle, slow, and high-maintenance for a focused app where manual testing suffices.

### III. User-Centered Quality

All features MUST prioritize user experience and code quality in equal measure.

**Non-Negotiable Rules:**
- **SwiftLint enforcement**: All code MUST pass SwiftLint checks before merge
- **Accessibility**: Interactive elements MUST support VoiceOver and Dynamic Type
- **Error states**: All user-facing operations MUST have graceful error handling and user feedback
- **Performance**: Weight chart rendering MUST maintain 60fps scrolling with up to 365 days of data
- **Destructive actions**: Any operation that deletes user data MUST require explicit confirmation

**Rationale**: A weight tracking app is used daily. Poor UX or quality issues compound into user abandonment. Code quality gates (SwiftLint) catch issues before they reach users.

## Technical Standards

**Platform Requirements:**
- iOS 18.0+ minimum deployment target
- Swift 5.9+ with modern language features
- SwiftUI for all UI (no UIKit except where SwiftUI lacks capability)
- SwiftData for persistence (no Core Data, no third-party ORMs)
- Swift Charts for visualization

**Prohibited Patterns:**
- `NavigationView` (use `NavigationStack`)
- Combine for UI binding (use `@Published` in `ObservableObject` only for services)
- Manual `NSPredicate` (use `#Predicate` macro)
- Force unwrapping without guard (except `fatalError` for programmer errors)
- UI tests (XCUITest)

## Development Workflow

### TDD Cycle (Mandatory for All Features)

1. **Write failing test(s)** that define expected behavior
2. **Get user/reviewer approval** of test approach before implementation
3. **Verify tests fail** for the right reason
4. **Implement minimum code** to make tests pass
5. **Refactor** while keeping tests green
6. **Commit** with reference to test coverage

### Code Review Requirements

- All PRs MUST be reviewed before merge
- Reviewer MUST verify TDD compliance (tests exist and cover the change)
- Reviewer MUST check Constitution alignment (simplicity, no prohibited patterns)

### Quality Gates

- [ ] SwiftLint passes with zero warnings
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Build succeeds on simulator
- [ ] No new SwiftData model migrations without explicit approval

## Governance

### Amendment Procedure

1. **Propose**: Create a PR modifying this constitution with rationale
2. **Review**: At least one reviewer must approve
3. **Document**: Update Sync Impact Report (comment at top of file)
4. **Version**: Increment version per semantic versioning rules below

### Versioning Policy

- **MAJOR**: Principle removed or redefined (backward-incompatible governance change)
- **MINOR**: New principle added, existing principle materially expanded
- **PATCH**: Clarifications, typo fixes, non-semantic refinements

### Compliance Review

- Constitution compliance MUST be verified during code review
- Violations MUST be either fixed or justified in a Complexity Tracking table
- The Complexity Tracking table is the ONLY mechanism for waiving constitution rules

**Version**: 1.1.0 | **Ratified**: 2025-01-09 | **Last Amended**: 2025-01-09
