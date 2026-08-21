//
//  CommandSuggestionEngineTests.swift
//  GitPaletteTests
//

import XCTest
@testable import GitPalette

final class CommandSuggestionEngineTests: XCTestCase {
    @MainActor
    func testSlashListsCommandsIncludingGit() {
        let suggestions = CommandSuggestionEngine.resolveSuggestions(
            for: "/",
            language: .english
        )
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.contains(where: { $0.completionText == "/git" }))
        XCTAssertTrue(suggestions.contains(where: { $0.completionText == "/quit" }))
    }

    @MainActor
    func testGitSubcommandCandidatesDoNotIncludeCheckout() {
        let suggestions = CommandSuggestionEngine.resolveSuggestions(
            for: "/git ",
            language: .english
        )
        let values = suggestions.map(\.primaryText)
        XCTAssertTrue(values.contains("status"))
        XCTAssertTrue(values.contains("commit"))
        XCTAssertFalse(values.contains("checkout"))
    }

    @MainActor
    func testUseSuggestsLinkedRepositories() {
        let repos = [
            GitRepository(
                id: "1",
                displayName: "Alpha",
                resolvablePath: GitResolvablePath(storedValue: "/tmp/alpha")
            ),
            GitRepository(
                id: "2",
                displayName: "Beta App",
                resolvablePath: GitResolvablePath(storedValue: "/tmp/beta")
            )
        ]
        let suggestions = CommandSuggestionEngine.resolveSuggestions(
            for: "/git use ",
            language: .english,
            linkedRepositories: repos
        )
        XCTAssertEqual(suggestions.map(\.primaryText), ["Alpha", "Beta App"])
        XCTAssertEqual(suggestions[1].completionText, "/git use \"Beta App\"")
    }

    @MainActor
    func testCommitHasNoArgumentSuggestions() {
        let suggestions = CommandSuggestionEngine.resolveSuggestions(
            for: "/git commit ",
            language: .english
        )
        XCTAssertEqual(suggestions, [])
    }

    @MainActor
    func testBestCompletionForGitPrefix() {
        let completion = CommandSuggestionEngine.resolveBestCompletion(
            for: "/gi",
            selectedIndex: 0,
            language: .english
        )
        XCTAssertEqual(completion, "/git")
    }
}
