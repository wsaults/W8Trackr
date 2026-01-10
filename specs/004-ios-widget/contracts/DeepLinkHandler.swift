//
//  DeepLinkHandler.swift
//  W8Trackr
//
//  Contract: URL scheme handling for widget deep links
//

import SwiftUI

// MARK: - Deep Link Routes

/// URL routes supported by the app
enum DeepLinkRoute: String {
    case addWeight = "addWeight"
    case logbook = "logbook"
    case summary = "summary"
    case settings = "settings"

    /// Construct full URL for this route
    var url: URL {
        URL(string: "w8trackr://\(rawValue)")!
    }
}

// MARK: - Deep Link Handler

/// Handles incoming URL scheme requests from widgets
struct DeepLinkHandler {

    /// URL scheme for the app
    static let scheme = "w8trackr"

    /// Parse incoming URL and return corresponding route
    /// - Parameter url: Incoming URL from widget tap
    /// - Returns: Route if valid, nil otherwise
    static func route(for url: URL) -> DeepLinkRoute? {
        guard url.scheme == scheme else { return nil }
        guard let host = url.host else { return nil }
        return DeepLinkRoute(rawValue: host)
    }
}

// MARK: - Navigation State

/// Observable state for handling navigation from deep links
@MainActor
class NavigationState: ObservableObject {
    /// Currently selected tab
    @Published var selectedTab: Tab = .summary

    /// Whether to show add weight sheet
    @Published var showAddWeight = false

    /// App tabs
    enum Tab: String, CaseIterable {
        case summary
        case logbook
        case settings
    }

    /// Handle deep link navigation
    /// - Parameter route: Route to navigate to
    func navigate(to route: DeepLinkRoute) {
        switch route {
        case .addWeight:
            selectedTab = .summary
            showAddWeight = true

        case .logbook:
            selectedTab = .logbook

        case .summary:
            selectedTab = .summary

        case .settings:
            selectedTab = .settings
        }
    }
}

// MARK: - View Extension

extension View {

    /// Handle deep links from widget taps
    ///
    /// Usage in root view:
    /// ```swift
    /// ContentView()
    ///     .handleDeepLinks(navigationState: navigationState)
    /// ```
    func handleDeepLinks(navigationState: NavigationState) -> some View {
        self.onOpenURL { url in
            if let route = DeepLinkHandler.route(for: url) {
                navigationState.navigate(to: route)
            }
        }
    }
}
