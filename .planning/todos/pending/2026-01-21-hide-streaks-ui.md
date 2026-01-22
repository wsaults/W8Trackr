---
created: 2026-01-21T11:30
title: Hide UI related to streaks
area: ui
files:
  - W8Trackr/Views/
---

## Problem

The app currently shows streak-related UI elements (e.g., logging streaks, consecutive days tracked). This UI should be hidden or removed as the streak feature is not a priority for the current release.

Streaks may add unnecessary complexity or pressure for users who don't track weight daily, and the feature may not be ready for launch.

## Solution

TBD - likely involves:
1. Finding all streak-related views/components
2. Either removing them entirely or hiding them behind a feature flag
3. Keeping the data model intact for future use if needed
