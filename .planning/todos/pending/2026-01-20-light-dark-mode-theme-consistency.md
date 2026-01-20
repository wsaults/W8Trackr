---
created: 2026-01-20T08:55
title: Ensure consistent light/dark mode theme support
area: ui
files:
  - W8Trackr/Theme/Colors.swift
  - W8Trackr/Theme/AppTheme.swift
  - W8Trackr/Theme/Gradients.swift
---

## Problem

The app needs to fully support light/dark mode with consistent theme usage. This means:
- All colors should adapt to the current color scheme
- Using SwiftUI proper semantic colors where appropriate
- AppTheme, AppColors, and AppGradients should respect system appearance
- No hardcoded colors that break in one mode or the other

Currently the app has a Theme folder with Colors.swift, AppTheme.swift, and Gradients.swift but needs audit to ensure full light/dark mode compatibility.

## Solution

TBD - Audit theme files and views for:
1. Hardcoded colors that don't adapt
2. Insufficient contrast in either mode
3. Missing Color asset catalog entries for adaptive colors
4. Views using raw colors instead of theme colors
