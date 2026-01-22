//
//  ScreenshotTests.swift
//  W8TrackrUITests
//
//  Screenshot tests for App Store captures using fastlane snapshot
//

import XCTest

final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    @MainActor
    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // Wait for initial app load
        _ = app.wait(for: .runningForeground, timeout: 5)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot Tests

    @MainActor
    func test01_Dashboard() throws {
        // Dashboard is the first tab, should already be visible
        // Wait for dashboard content to load
        let dashboard = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboard.exists)

        // Small delay to let chart and data render
        sleep(1)

        snapshot("01_dashboard")
    }

    @MainActor
    func test02_Logbook() throws {
        // Navigate to Logbook tab
        let logbook = app.tabBars.buttons["Logbook"]
        XCTAssertTrue(logbook.waitForExistence(timeout: 5))
        logbook.tap()

        // Wait for content to appear
        sleep(1)

        snapshot("02_logbook")
    }

    @MainActor
    func test03_Settings() throws {
        // Navigate to Settings tab
        let settings = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        // Wait for content to appear
        sleep(1)

        snapshot("03_settings")
    }

    @MainActor
    func test04_AddWeight() throws {
        // Navigate to Dashboard first (in case we're on another tab)
        let dashboard = app.tabBars.buttons["Dashboard"]
        if dashboard.exists {
            dashboard.tap()
        }

        // Look for add weight button - could be a plus button or "Add Weight"
        let addButton = app.buttons["Add Weight"]
        let plusButton = app.buttons.matching(identifier: "addWeight").firstMatch

        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
        } else if plusButton.waitForExistence(timeout: 3) {
            plusButton.tap()
        } else {
            // Try navigation bar button
            let navAddButton = app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1)
            if navAddButton.exists {
                navAddButton.tap()
            }
        }

        // Wait for sheet to present
        sleep(1)

        snapshot("04_add_weight")
    }

    @MainActor
    func test05_Chart() throws {
        // Navigate to Dashboard for chart view
        let dashboard = app.tabBars.buttons["Dashboard"]
        if dashboard.exists {
            dashboard.tap()
        }

        // Scroll to chart section if needed
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }

        sleep(1)

        snapshot("05_chart")
    }

    @MainActor
    func test06_WeeklySummary() throws {
        // Navigate to Dashboard
        let dashboard = app.tabBars.buttons["Dashboard"]
        if dashboard.exists {
            dashboard.tap()
        }

        // Scroll to weekly summary section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeUp()
        }

        sleep(1)

        snapshot("06_weekly_summary")
    }
}
