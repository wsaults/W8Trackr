---
created: 2026-01-20T21:18
title: Add full accessibility support
area: ui
files: []
---

## Problem

The app needs comprehensive accessibility support for users with disabilities. Current state is unknown - likely has basic SwiftUI accessibility but needs audit and enhancement for:

- VoiceOver support (labels, hints, traits)
- Dynamic Type support (text scaling)
- Reduce Motion support (animation alternatives)
- Color contrast compliance (WCAG standards)
- Touch target sizes (44pt minimum)
- Keyboard navigation support
- Screen reader announcements for state changes
- Chart accessibility (data sonification or alternative representations)

## Solution

TBD - typical approach:
1. Run Accessibility Inspector audit on all screens
2. Add `.accessibilityLabel()` and `.accessibilityHint()` where needed
3. Test with VoiceOver enabled
4. Verify Dynamic Type at all size classes
5. Add `.accessibilityAction()` for custom interactions
6. Consider `.accessibilityChartDescriptor()` for weight trend chart
7. Test with Reduce Motion enabled
8. Verify color contrast ratios meet WCAG AA standards
