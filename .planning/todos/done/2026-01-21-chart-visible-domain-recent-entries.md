---
created: 2026-01-21T10:15
title: Chart should show recent entries on load, not prediction line
area: ui
files:
  - W8Trackr/Views/Components/WeightChartView.swift
---

## Problem

When the weight chart loads, it currently positions the visible domain to show the far-right future prediction line area rather than centering on the most recent actual weight entries. Users expect to see their recent data immediately, not scroll back to find it.

The chart's visible domain calculation may be prioritizing the prediction end date (14 days in the future) rather than the last actual entry date.

## Solution

TBD - likely involves adjusting the chart's initial visible domain to:
1. End at the most recent entry date (or a few days after)
2. Show prediction line only when user scrolls right
3. Or calculate visible domain based on actual data, not prediction range
