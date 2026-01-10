//
//  SnapshotHelper.swift
//  W8TrackrUITests
//
//  fastlane snapshot helper for capturing App Store screenshots
//

import Foundation
import XCTest

var deviceLanguage = ""
var locale = ""

func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
    Snapshot.setupSnapshot(app, waitForAnimations: waitForAnimations)
}

func snapshot(_ name: String, waitForLoadingIndicator: Bool = true) {
    if waitForLoadingIndicator {
        Snapshot.snapshot(name, timeWaitingForIdle: 20)
    } else {
        Snapshot.snapshot(name, timeWaitingForIdle: 0)
    }
}

enum Snapshot {
    static var app: XCUIApplication?
    static var waitForAnimations = true
    static var cacheDirectory: URL?
    static var screenshotsDirectory: URL? {
        return cacheDirectory?.appendingPathComponent("screenshots", isDirectory: true)
    }

    static func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
        Snapshot.app = app
        Snapshot.waitForAnimations = waitForAnimations

        do {
            let cacheDir = try getCacheDirectory()
            Snapshot.cacheDirectory = cacheDir
            setLanguage(app)
            setLocale(app)
            setLaunchArguments(app)
        } catch {
            NSLog("Snapshot: Error setting up snapshot: \(error)")
        }
    }

    static func setLanguage(_ app: XCUIApplication) {
        guard let cacheDirectory = cacheDirectory else { return }

        let path = cacheDirectory.appendingPathComponent("language.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            deviceLanguage = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
            app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))"]
        } catch {
            NSLog("Snapshot: Couldn't detect language, using device default.")
        }
    }

    static func setLocale(_ app: XCUIApplication) {
        guard let cacheDirectory = cacheDirectory else { return }

        let path = cacheDirectory.appendingPathComponent("locale.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            locale = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
        } catch {
            NSLog("Snapshot: Couldn't detect locale, using device default.")
        }

        if locale.isEmpty, !deviceLanguage.isEmpty {
            locale = Locale(identifier: deviceLanguage).identifier
        }

        if !locale.isEmpty {
            app.launchArguments += ["-AppleLocale", "\"\(locale)\""]
        }
    }

    static func setLaunchArguments(_ app: XCUIApplication) {
        guard let cacheDirectory = cacheDirectory else { return }

        let path = cacheDirectory.appendingPathComponent("snapshot-launch_arguments.txt")

        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-ui_testing"]

        do {
            let launchArguments = try String(contentsOf: path, encoding: .utf8)
            let regex = try NSRegularExpression(pattern: "(\\\".+?\\\"|\\S+)", options: [])
            let matches = regex.matches(
                in: launchArguments,
                options: [],
                range: NSRange(location: 0, length: launchArguments.count)
            )

            let results = matches.map { result -> String in
                (launchArguments as NSString).substring(with: result.range)
            }

            app.launchArguments += results
        } catch {
            NSLog("Snapshot: Couldn't detect launch arguments, none were provided.")
        }
    }

    static func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
        if timeout > 0, waitForAnimations {
            waitForLoadingIndicatorToDisappear(within: timeout)
        }

        NSLog("Snapshot: Taking snapshot '\(name)'")

        sleep(1) // Small delay to ensure UI is settled

        guard let app = app else {
            NSLog("Snapshot: App not set up, call setupSnapshot first")
            return
        }

        let screenshot = app.screenshot()
        guard let screenshotsDir = screenshotsDirectory else {
            NSLog("Snapshot: Screenshots directory not found")
            return
        }

        do {
            try FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
            let fileURL = screenshotsDir.appendingPathComponent("\(name).png")
            try screenshot.pngRepresentation.write(to: fileURL)
            NSLog("Snapshot: Saved screenshot to \(fileURL.path)")
        } catch {
            NSLog("Snapshot: Error saving screenshot: \(error)")
        }
    }

    static func waitForLoadingIndicatorToDisappear(within timeout: TimeInterval) {
        guard let app = app else { return }

        let networkLoadingIndicator = app.otherElements.deviceStatusBars.networkLoadingIndicators.element
        let networkLoadingIndicatorDisappeared = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: networkLoadingIndicator
        )

        _ = XCTWaiter.wait(for: [networkLoadingIndicatorDisappeared], timeout: timeout)
    }

    static func getCacheDirectory() throws -> URL {
        let cachePath = "Library/Caches/tools.fastlane"

        // Check simulator data container
        guard let simulatorHostHome = ProcessInfo().environment["SIMULATOR_HOST_HOME"] else {
            throw SnapshotError.cannotFindSimulatorHomeDirectory
        }

        let simulatorCacheDir = URL(fileURLWithPath: simulatorHostHome).appendingPathComponent(cachePath)
        if FileManager.default.fileExists(atPath: simulatorCacheDir.path) {
            return simulatorCacheDir
        }

        // Fallback to current user home
        let homeDir = URL(fileURLWithPath: NSHomeDirectory())
        return homeDir.appendingPathComponent(cachePath)
    }
}

enum SnapshotError: Error, LocalizedError {
    case cannotFindSimulatorHomeDirectory

    var errorDescription: String? {
        switch self {
        case .cannotFindSimulatorHomeDirectory:
            return "Couldn't find simulator home directory"
        }
    }
}

private extension XCUIElementAttributes {
    var isNetworkLoadingIndicator: Bool {
        if hasAllowListedIdentifier { return false }
        let hasOldLoadingIndicatorSize = frame.size == CGSize(width: 10, height: 20)
        let hasNewLoadingIndicatorSize = frame.size.width.isBetween(46, and: 47) && frame.size.height.isBetween(2, and: 3)
        return hasOldLoadingIndicatorSize || hasNewLoadingIndicatorSize
    }

    var hasAllowListedIdentifier: Bool {
        let dominated = ["label", "currentTime", "elapsedTime", "time"]
        return dominated.contains(identifier)
    }

    func isStatusBar(_ deviceWidth: CGFloat) -> Bool {
        guard elementType == .statusBar else { return false }
        return frame.width == deviceWidth
    }
}

private extension XCUIElementQuery {
    var networkLoadingIndicators: XCUIElementQuery {
        let isNetworkLoadingIndicator = NSPredicate { evaluatedObject, _ in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }
            return element.isNetworkLoadingIndicator
        }
        return containing(isNetworkLoadingIndicator)
    }

    var deviceStatusBars: XCUIElementQuery {
        guard let app = Snapshot.app else {
            fatalError("Snapshot: Call setupSnapshot before using snapshot")
        }

        let deviceWidth = app.frame.width
        let isStatusBar = NSPredicate { evaluatedObject, _ in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }
            return element.isStatusBar(deviceWidth)
        }
        return containing(isStatusBar)
    }
}

private extension CGFloat {
    func isBetween(_ min: CGFloat, and max: CGFloat) -> Bool {
        return self >= min && self <= max
    }
}
