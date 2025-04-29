//
//  W8TrackrApp.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import SwiftData
import SwiftUI

@main
struct W8TrackrApp: App {
    var body: some Scene {
        WindowGroup {
            SummaryView()
        }
        .modelContainer(for: [WeightEntry.self])
    }
}
