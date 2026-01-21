//
//  LogbookLayout.swift
//  W8Trackr
//
//  Shared layout constants for logbook header and row alignment.
//

import SwiftUI

/// Layout constants ensuring header and row columns align perfectly
enum LogbookLayout {
    // MARK: - Column Spacing

    /// Spacing between columns (must match in header and rows)
    static let columnSpacing: CGFloat = 12

    // MARK: - Column Widths

    /// Date column width (day number + weekday abbreviation)
    static let dateColumnWidth: CGFloat = 40

    /// Weight column width ("000.0" with monospacedDigit)
    static let weightColumnWidth: CGFloat = 55

    /// Moving average column width (same as weight for consistency)
    static let avgColumnWidth: CGFloat = 55

    /// Weekly rate column width (arrow + "0.0")
    static let rateColumnWidth: CGFloat = 50

    /// Notes indicator column width (icon width)
    static let notesColumnWidth: CGFloat = 24

    // MARK: - Row Dimensions

    /// Vertical padding within each row
    static let rowVerticalPadding: CGFloat = 4

    /// Minimum row height for iOS accessibility touch targets
    static let minRowHeight: CGFloat = 44

    // MARK: - Header Dimensions

    /// Vertical padding for header (matches AppTheme.Spacing.xs)
    static let headerVerticalPadding: CGFloat = 8
}
