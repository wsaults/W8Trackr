---
created: 2026-01-20T21:20
title: Add full test coverage
area: testing
files: []
---

## Problem

Current test coverage is unknown. The app has core functionality that needs comprehensive unit and integration tests to ensure reliability before App Store submission:

- TrendCalculator (EWMA smoothing, Holt forecasting, moving averages)
- MilestoneCalculator (progress calculation, milestone generation)
- Weight entry validation and persistence
- Goal progress calculations
- Date range filtering logic
- Logbook filtering and row data building
- HealthKit sync operations (mock-based)
- Notification scheduling logic
- CloudKit sync status handling

## Solution

TBD - typical approach:
1. Run code coverage report to identify gaps
2. Prioritize business logic (calculators, validators)
3. Add unit tests for TrendCalculator and MilestoneCalculator
4. Add integration tests for SwiftData operations
5. Add UI tests for critical user flows (if not already present)
6. Set up CI coverage threshold
7. Consider snapshot tests for complex views
