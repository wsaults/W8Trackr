# Phase 21: Infrastructure & Migration - Context

**Gathered:** 2026-01-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Migrate existing users' SwiftData container to App Group location, enabling widget data sharing. Preserve CloudKit sync integrity throughout. This is a behind-the-scenes infrastructure change that must be invisible to users when successful.

</domain>

<decisions>
## Implementation Decisions

### Migration failure handling
- Do NOT retry automatically on failure
- Notify user that migration failed
- Require manual retry (user must explicitly trigger)
- Show clear error message explaining what happened

### App usability during migration
- App is usable immediately — do not block interaction
- Migration runs in background
- User can continue using app while migration completes

### Pre-migration widget state
- Widgets show "Open W8Trackr to complete setup" before migration
- Do not show empty placeholders or dashes

### Multi-device sync
- Trust CloudKit to reconcile data across devices
- Each device migrates independently from its local store
- CloudKit handles deduplication via existing UUID-based model

### Claude's Discretion
- Old data container retention period (delete immediately vs keep as backup)
- Migration verification strategy (count match, checksum, etc.)
- Manual retry UX (Settings button vs alert on launch)
- CloudKit sync safety during migration (disable old container sync, etc.)
- Exact migration progress UI (if any)

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches for SwiftData container migration.

</specifics>

<deferred>
## Deferred Ideas

- **HealthKit as source of truth** — Consider whether HealthKit should be the primary data source instead of SwiftData. Belongs in Phase 23 discussion.

</deferred>

---

*Phase: 21-infrastructure-migration*
*Context gathered: 2026-01-22*
