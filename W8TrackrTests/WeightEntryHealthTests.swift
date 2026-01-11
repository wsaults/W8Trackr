//
//  WeightEntryHealthTests.swift
//  W8TrackrTests
//
//  Tests for WeightEntry sync fields used by HealthKit integration.
//  Following TDD: these tests are written FIRST, before implementation.
//

import Testing
import Foundation
@testable import W8Trackr

// MARK: - WeightEntry Sync Field Tests

struct WeightEntrySyncFieldTests {

    // MARK: - healthKitUUID Field Tests

    @Test func newEntryHasNilHealthKitUUID() {
        let entry = WeightEntry(weight: 175.0)
        #expect(entry.healthKitUUID == nil)
    }

    @Test func healthKitUUIDCanBeSet() {
        let entry = WeightEntry(weight: 175.0)
        let testUUID = "12345678-1234-1234-1234-123456789abc"
        entry.healthKitUUID = testUUID
        #expect(entry.healthKitUUID == testUUID)
    }

    // MARK: - source Field Tests

    @Test func newEntryHasW8TrackrAsDefaultSource() {
        let entry = WeightEntry(weight: 175.0)
        #expect(entry.source == "W8Trackr")
    }

    @Test func sourceCanBeSetToExternalApp() {
        let entry = WeightEntry(weight: 175.0)
        entry.source = "Withings Scale"
        #expect(entry.source == "Withings Scale")
    }

    // MARK: - syncVersion Field Tests

    @Test func newEntryHasSyncVersionOfOne() {
        let entry = WeightEntry(weight: 175.0)
        #expect(entry.syncVersion == 1)
    }

    @Test func syncVersionIncrements() {
        let entry = WeightEntry(weight: 175.0)
        entry.syncVersion += 1
        #expect(entry.syncVersion == 2)
    }

    // MARK: - pendingHealthSync Field Tests

    @Test func newEntryHasPendingHealthSyncTrue() {
        // New entries should be marked for sync when Health sync is enabled
        let entry = WeightEntry(weight: 175.0)
        #expect(entry.pendingHealthSync == true)
    }

    @Test func pendingHealthSyncCanBeCleared() {
        let entry = WeightEntry(weight: 175.0)
        entry.pendingHealthSync = false
        #expect(entry.pendingHealthSync == false)
    }
}

// MARK: - WeightEntry Computed Property Tests

struct WeightEntryComputedPropertyTests {

    @Test func isImportedReturnsTrueForExternalSource() {
        let entry = WeightEntry(weight: 175.0)
        entry.source = "Withings Scale"
        #expect(entry.isImported == true)
    }

    @Test func isImportedReturnsFalseForW8TrackrSource() {
        let entry = WeightEntry(weight: 175.0)
        entry.source = "W8Trackr"
        #expect(entry.isImported == false)
    }

    @Test func needsSyncReturnsTrueWhenPending() {
        let entry = WeightEntry(weight: 175.0)
        entry.pendingHealthSync = true
        #expect(entry.needsSync == true)
    }

    @Test func needsSyncReturnsFalseWhenNotPending() {
        let entry = WeightEntry(weight: 175.0)
        entry.pendingHealthSync = false
        #expect(entry.needsSync == false)
    }
}
