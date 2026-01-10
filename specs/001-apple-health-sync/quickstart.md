# Quickstart: Apple Health Integration

**Feature**: 001-apple-health-sync
**Date**: 2025-01-09

This guide walks through verifying the Apple Health integration feature after implementation.

## Prerequisites

- iOS device (not simulator, for full HealthKit functionality)
- Apple Health app with some existing weight data (optional, for import testing)
- W8Trackr app installed

## Setup Steps

### 1. Enable Health Sync

1. Open W8Trackr
2. Navigate to **Settings** tab
3. Find **Apple Health** section
4. Toggle **Sync with Apple Health** to ON
5. System permission dialog appears:
   - Grant both **Read** and **Write** access
   - Tap **Allow**

**Expected**: Sync toggle remains ON, status shows "Connected"

### 2. Test Export (P1)

1. From Summary or Logbook, tap **+** to add new weight entry
2. Enter weight: `175.5 lb` (or your preferred unit)
3. Tap **Save**

**Verify in Apple Health**:
1. Open Apple Health app
2. Go to **Browse** → **Body Measurements** → **Weight**
3. Check **Show All Data**

**Expected**: Entry from W8Trackr appears with timestamp matching your entry

### 3. Test Import (P2)

*Skip if no prior Health data exists*

If you had weight data in Health before enabling sync:

1. After enabling sync, check for import prompt
2. Choose **Import existing data**
3. Wait for import to complete (progress shown for large datasets)

**Verify in W8Trackr**:
1. Go to **Logbook** tab
2. Look for entries with Health badge/indicator

**Expected**: Historical Health entries appear, visually distinguishable from manual entries

### 4. Test Bidirectional Sync (P3)

**From another source to W8Trackr**:
1. Add a weight entry directly in Apple Health:
   - Health app → Browse → Weight → Add Data
   - Enter weight and date
2. Return to W8Trackr
3. Pull to refresh or wait ~1 minute

**Expected**: New Health entry appears in W8Trackr Logbook

**From W8Trackr to Apple Health** (verify edit sync):
1. In W8Trackr, edit an existing weight entry
2. Save changes
3. Check Apple Health

**Expected**: Health entry updates to match edited value

### 5. Test Edge Cases

**Permission Revocation**:
1. Go to iOS Settings → Privacy & Security → Health → W8Trackr
2. Disable all access
3. Return to W8Trackr

**Expected**: App functions normally, sync toggle disabled, prompt to re-enable

**Delete Sync**:
1. Delete a weight entry in W8Trackr
2. Check Apple Health

**Expected**: Corresponding Health entry is removed

**Offline Behavior**:
1. Enable Airplane mode
2. Add a weight entry in W8Trackr
3. Disable Airplane mode

**Expected**: Entry syncs to Health once connectivity restored

## Verification Checklist

| Test | Pass/Fail | Notes |
|------|-----------|-------|
| Enable sync permissions | ☐ | |
| Export new entry | ☐ | |
| Edit syncs to Health | ☐ | |
| Delete syncs to Health | ☐ | |
| Import historical data | ☐ | |
| External entry imports | ☐ | |
| Permission revoke graceful | ☐ | |
| Offline queue works | ☐ | |
| Chart includes all sources | ☐ | |

## Troubleshooting

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| Sync toggle won't enable | Health not available (iPad) | Feature should be hidden |
| Entry not appearing in Health | Permission denied | Check Settings → Privacy → Health |
| Import shows no data | Read permission denied | Re-request via Settings |
| Duplicate entries | Imported same data twice | Check for sync identifier match |
| Old entries not syncing | Background delivery disabled | Check entitlements |

## Performance Benchmarks

| Operation | Target | Measurement Method |
|-----------|--------|-------------------|
| Enable sync | <30s | Time from toggle to first sync |
| Export new entry | <5s | Time from save to Health appearance |
| Import 365 days | <10s | Time from confirm to complete |
| External entry sync | <1 min | Time from Health entry to W8Trackr |

## Success Criteria Validation

| Criteria | How to Verify |
|----------|---------------|
| SC-001: Enable in <30s | Time the full enable flow |
| SC-002: Export <5s | Timestamp comparison |
| SC-003: External sync <1 min | Add in Health, check W8Trackr |
| SC-004: Import 365 days <10s | Generate test data, time import |
| SC-005: 100% accuracy | Compare entry values cross-app |
| SC-006: Works without Health | Disable permissions, use app |
| SC-007: No UX degradation | Subjective - no confusion/errors |
