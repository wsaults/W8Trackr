---
created: 2026-01-22T16:45
title: Fix HealthKit settings link destination
area: ui
files:
  - W8Trackr/Views/SettingsView.swift:448-457
---

## Problem

When HealthKit integration is rejected by the user and they tap "Open Settings" in the permission alert, the app opens the wrong location. Currently it uses `UIApplication.openSettingsURLString` which takes users to the app's general Settings page, not to the Health access settings.

The correct destination should be Settings → Health → Data Access & Devices, where users can toggle W8Trackr's HealthKit permissions.

## Solution

TBD - Research the correct URL scheme:
- `x-apple-health://` may open the Health app directly
- May need to use a deep link to Settings → Health
- If no direct link exists, update the alert message to guide users manually: "Go to Settings → Health → Data Access & Devices → W8Trackr"
