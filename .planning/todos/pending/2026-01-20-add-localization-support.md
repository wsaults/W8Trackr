---
created: 2026-01-20T21:16
title: Add localization support
area: ui
files: []
---

## Problem

The app currently uses hardcoded English strings throughout the UI. For international App Store release, the app needs localization support to reach users in their native language. Key areas needing localization:

- Dashboard labels ("Current Weight", "Weekly Change", "Goal Prediction")
- Settings section titles and labels
- Button text ("Save", "Cancel", "Delete")
- Alert messages and confirmation dialogs
- Date and number formatting (already partially handled by SwiftUI formatters)
- Weight unit labels (lb/kg)
- Milestone celebration messages

## Solution

TBD - typical approach:
1. Create Localizable.strings files
2. Use `String(localized:)` or `LocalizedStringKey` throughout views
3. Start with English base, add target languages
4. Consider `LocalizedStringResource` for app intents and widgets
5. Test with pseudolocalization to catch layout issues
