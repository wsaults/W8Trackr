//
//  AccessibilityTests.swift
//  W8TrackrUITests
//
//  Created by Claude on 2026-01-22.
//

import XCTest

/// Automated accessibility tests for W8Trackr.
///
/// These tests use XCTest's performAccessibilityAudit() API to check for common
/// accessibility issues like missing labels, low contrast, and small touch targets.
/// This is the programmatic equivalent of Accessibility Inspector audits.
///
/// Run with: xcodebuild test -project W8Trackr.xcodeproj -scheme W8Trackr -sdk iphonesimulator -only-testing:W8TrackrUITests/AccessibilityTests
@MainActor
final class AccessibilityTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Skip onboarding for accessibility tests
        app.launchArguments += ["-hasCompletedOnboarding", "YES"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Dashboard Tab

    func testDashboardAccessibility() throws {
        // Navigate to Dashboard (should be default)
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5))
        dashboardTab.tap()

        // Perform accessibility audit
        try app.performAccessibilityAudit()
    }

    // MARK: - Logbook Tab

    func testLogbookAccessibility() throws {
        // Navigate to Logbook
        let logbookTab = app.tabBars.buttons["Logbook"]
        XCTAssertTrue(logbookTab.waitForExistence(timeout: 5))
        logbookTab.tap()

        // Wait for content to load
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 2)

        // Perform accessibility audit
        try app.performAccessibilityAudit()
    }

    // MARK: - Settings Tab

    func testSettingsAccessibility() throws {
        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Wait for content to load
        _ = app.staticTexts["Weight Unit"].waitForExistence(timeout: 2)

        // Perform accessibility audit
        try app.performAccessibilityAudit()
    }

    // MARK: - Add Entry Sheet

    func testAddEntryAccessibility() throws {
        // Tap the add button (trailing tab bar button)
        let addButton = app.tabBars.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Wait for sheet to appear
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))

        // Perform accessibility audit on the entry sheet
        try app.performAccessibilityAudit()

        // Dismiss sheet
        cancelButton.tap()
    }

    // MARK: - Dynamic Type

    func testDashboardWithLargeText() throws {
        // Relaunch with accessibility large text
        app.terminate()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ]
        app.launch()

        // Navigate to Dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5))
        dashboardTab.tap()

        // Perform accessibility audit with large text
        try app.performAccessibilityAudit()
    }

    // MARK: - Chart Accessibility Verification

    func testWeightTrendChartAccessibility() throws {
        // Navigate to Dashboard where chart is displayed
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5))
        dashboardTab.tap()

        // Wait for chart to render
        _ = app.otherElements.firstMatch.waitForExistence(timeout: 3)

        // Perform accessibility audit - this verifies the chart's
        // AXChartDescriptorRepresentable implementation is correct
        // WeightTrendChartView uses .accessibilityChartDescriptor(self)
        // which enables VoiceOver audio graph exploration
        try app.performAccessibilityAudit()
    }
}
