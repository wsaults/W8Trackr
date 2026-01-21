# Phase 14: Add Entry UI - Context

**Gathered:** 2026-01-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the floating action button (FAB) with an iOS 26 Liquid Glass tab bar bottom accessory for adding weight entries. The FAB is removed from the dashboard. The accessory uses `.tabViewBottomAccessory()` modifier and gets automatic Liquid Glass styling.

</domain>

<decisions>
## Implementation Decisions

### Button appearance
- Use plus icon (`systemName: "plus"`) — universal "add" affordance
- No text label — icon-only for compact accessory appearance
- Let Liquid Glass provide the capsule background automatically
- Match app's accent color for the icon tint

### Minimize behavior
- Use `.tabBarMinimizeBehavior(.onScrollDown)` as specified in roadmap
- Accessory slides inline when tab bar minimizes (default iOS 26 behavior)
- No custom minimize behavior — follow platform conventions

### Tap experience
- Present WeightEntrySheet as modal sheet (existing pattern)
- Use `.sheet(isPresented:)` presentation
- No custom transition animation — system default

### Claude's Discretion
- Exact placement within tab bar accessory area
- Whether to add haptic feedback on tap
- Any additional accessibility labels beyond the icon

</decisions>

<specifics>
## Specific Ideas

- Reference from roadmap: [Hacking with Swift - TabView Bottom Accessory](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-tabview-accessory)
- FAB removal location: SummaryView/Dashboard overlay
- Wire to existing WeightEntrySheet presentation

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 14-add-entry-ui*
*Context gathered: 2026-01-21*
