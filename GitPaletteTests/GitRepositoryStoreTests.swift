//
//  GitRepositoryStoreTests.swift
//  GitPaletteTests
//

import XCTest
@testable import GitPalette

final class GitRepositoryStoreTests: XCTestCase {
    @MainActor
    func testLinkUseUnlinkAndActiveSelection() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }
        let store = harness.store

        XCTAssertThrowsError(try store.resolveActiveRepository()) { error in
            XCTAssertEqual(error as? GitCommandError, .noLinkedRepository)
        }

        let linkedFirst = try store.executeLink(path: harness.first.path)
        XCTAssertEqual(linkedFirst.displayName, "First")
        XCTAssertEqual(try store.resolveActiveRepository().id, linkedFirst.id)

        let linkedSecond = try store.executeLink(path: harness.second.path)
        XCTAssertEqual(try store.resolveActiveRepository().id, linkedSecond.id)

        let used = try store.executeUse(name: "First")
        XCTAssertEqual(used.id, linkedFirst.id)

        let outcome = try store.executeUnlink(name: "First")
        XCTAssertEqual(outcome.removed.id, linkedFirst.id)
        XCTAssertEqual(outcome.newActive?.id, linkedSecond.id)
        XCTAssertFalse(outcome.needsUse)
        XCTAssertEqual(try store.resolveActiveRepository().id, linkedSecond.id)

        let last = try store.executeUnlink(name: "Second")
        XCTAssertTrue(last.needsUse)
        XCTAssertThrowsError(try store.resolveActiveRepository())
    }

    @MainActor
    func testRejectsNonGitDirectory() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }
        let plain = harness.tempRoot.appendingPathComponent("plain", isDirectory: true)
        try FileManager.default.createDirectory(at: plain, withIntermediateDirectories: true)
        XCTAssertThrowsError(try harness.store.executeLink(path: plain.path)) { error in
            XCTAssertEqual(error as? GitCommandError, .notGitRepository(plain.path))
        }
    }

    @MainActor
    func testRelinkSamePathReturnsExistingAndActivatesIt() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }
        let first = try harness.store.executeLink(path: harness.first.path)
        _ = try harness.store.executeLink(path: harness.second.path)
        let again = try harness.store.executeLink(path: harness.first.path)
        XCTAssertEqual(again.id, first.id)
        XCTAssertEqual(try harness.store.resolveActiveRepository().id, first.id)
    }

    private struct Harness {
        let suiteName: String
        let defaults: UserDefaults
        let tempRoot: URL
        let first: URL
        let second: URL
        let store: GitRepositoryStore

        func cleanup() {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: tempRoot)
        }
    }

    @MainActor
    private func makeHarness() throws -> Harness {
        let suiteName = "GitPaletteTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitPaletteTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        let first = try makeFakeRepo(named: "First", in: tempRoot)
        let second = try makeFakeRepo(named: "Second", in: tempRoot)
        let store = GitRepositoryStore(
            defaults: defaults,
            repositoriesKey: "test.repos",
            activeIDKey: "test.active"
        )
        return Harness(
            suiteName: suiteName,
            defaults: defaults,
            tempRoot: tempRoot,
            first: first,
            second: second,
            store: store
        )
    }

    private func makeFakeRepo(named name: String, in tempRoot: URL) throws -> URL {
        let url = tempRoot.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: url.appendingPathComponent(".git", isDirectory: true),
            withIntermediateDirectories: true
        )
        return url
    }
}
