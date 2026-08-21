//
//  RecentGitmojiStoreTests.swift
//  GitPaletteTests
//

import XCTest
@testable import GitPalette

final class RecentGitmojiStoreTests: XCTestCase {
    @MainActor
    func testRecordsNewestFirstAndRespectsMaxCount() {
        let suite = "GitPaletteTests.recent.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        var maxCount = 3
        let store = RecentGitmojiStore(
            defaults: defaults,
            storageKey: "recent",
            resolveMaxCount: { maxCount }
        )

        store.executeRecord(code: ":a:")
        store.executeRecord(code: ":b:")
        store.executeRecord(code: ":c:")
        store.executeRecord(code: ":d:")
        XCTAssertEqual(store.loadCodes(), [":d:", ":c:", ":b:"])

        store.executeRecord(code: ":b:")
        XCTAssertEqual(store.loadCodes(), [":b:", ":d:", ":c:"])

        maxCount = 2
        XCTAssertEqual(store.loadCodes(), [":b:", ":d:"])

        store.executeClear()
        XCTAssertEqual(store.loadCodes(), [])
        defaults.removePersistentDomain(forName: suite)
    }
}
