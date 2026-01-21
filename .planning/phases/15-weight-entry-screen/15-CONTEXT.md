# Phase 15: Weight Entry Screen - Context

**Gathered:** 2026-01-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Redesign weight entry as a full-screen form with text input, date selection, notes, and optional body fat/height fields. Replaces the current plus/minus button controls with a focused text input experience.

**Scope expanded from original:** Now includes date picker, body fat, and height fields beyond the original weight + notes simplification.

</domain>

<decisions>
## Implementation Decisions

### Input Behavior
- Weight field auto-focuses immediately when sheet opens
- Decimal pad keyboard for weight entry
- Invalid input (empty or non-numeric) disables save button — no inline error message
- Unit suffix (lb/kg) displayed inside the text field (e.g., "170.5 lb")
- Keyboard stays visible until save/cancel — no tap-to-dismiss

### Visual Layout
- Full-screen sheet (not medium detent)
- Top-to-bottom layout:
  1. Date with left/right arrows (right arrow disabled for future dates)
  2. Weight label + text input with unit suffix
  3. Notes label + text area
  4. "More..." button to expand body fat and height fields
- "More..." expands fields inline (slides in, form grows taller)
- Date picker uses left/right arrows only — no calendar popup

### Notes Field
- Text area showing 2-3 lines by default, expands as user types
- 500 character limit
- Character count shown only when under 50 characters remaining
- Form auto-scrolls to keep notes visible above keyboard

### Save Interaction
- Full-width save button at bottom of form content
- Cancel button in navigation bar (top-left)
- Dismiss immediately after successful save — no success indicator
- Confirm discard dialog if user has unsaved changes and tries to dismiss

### Claude's Discretion
- Exact spacing and padding values
- Field border/background styling
- Animation timing for "More..." expansion
- Keyboard avoidance implementation details
- Arrow icon choice for date navigation

</decisions>

<specifics>
## Specific Ideas

- Date arrows should feel responsive — tap to move one day at a time
- Weight field should be the primary focus — largest/most prominent element
- "More..." should feel optional — body fat and height are secondary data points

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within expanded phase scope

</deferred>

---

*Phase: 15-weight-entry-screen*
*Context gathered: 2026-01-21*
