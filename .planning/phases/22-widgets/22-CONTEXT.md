# Phase 22: Widgets - Context

**Gathered:** 2026-01-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Home screen widgets (small, medium, large) showing current weight, progress toward goal, and recent trends. Widgets read from App Group container and update when user modifies data in main app. Tapping opens main app.

</domain>

<decisions>
## Implementation Decisions

### Visual Style
- Match main W8Trackr app's visual style (colors, fonts, styling)
- Large widget sparkline uses filled area chart (gradient fill below line, like Apple Fitness widgets)
- Adapt to system dark/light mode
- Weight number is the dominant visual element — large and bold as hero

### Data Display
- Whole numbers only for weight values (no decimals in widgets)
- Large widget chart shows last 7 days of data
- Unit display follows user's preference from main app (lb/kg)

### Update Behavior
- No "last updated" timestamp shown — keep widgets clean
- Empty state (no entries): "Add your first weigh-in" prompt with app icon
- No goal set: "Set a goal to track progress" prompt
- Tapping any widget size opens main app dashboard (no deep linking to specific screens)

### Trend Presentation
- Trend based on last 7 days comparison
- Use neutral colors for trend indicators (no red/green judgment)
- Direction shown without implying good/bad

### Claude's Discretion
- Small widget: What to show alongside weight (trend arrow, date, etc.)
- Medium widget: How to display progress (percentage, pounds remaining, visual treatment)
- Trend indicator style: Arrow icons, colors, or combination
- Neutral threshold definition for when to show "no change"
- Loading/placeholder states
- Exact spacing, typography, and chart styling

</decisions>

<specifics>
## Specific Ideas

- Filled area chart for sparkline (like Apple Fitness widgets)
- Weight should feel prominent at a glance — this is the hero data

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 22-widgets*
*Context gathered: 2026-01-22*
