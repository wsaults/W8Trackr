//
//  Entry.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Foundation
import SwiftData

@Model
final class WeightEntry {
    var weight: Decimal
    var date = Date.now
}
