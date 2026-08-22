//
//  GitSubcommandTests.swift
//  GitPaletteTests
//

import XCTest
@testable import GitPalette

final class GitSubcommandTests: XCTestCase {
    @MainActor
    func testParsesKnownSubcommands() {
        XCTAssertEqual(
            GitSubcommand.executeParse(argument: "status", language: .english).subcommand,
            .status
        )
        XCTAssertEqual(
            GitSubcommand.executeParse(argument: "add", language: .english).subcommand,
            .add
        )
        XCTAssertEqual(
            GitSubcommand.executeParse(argument: "repos", language: .english).subcommand,
            .repos
        )
        XCTAssertEqual(
            GitSubcommand.executeParse(argument: "link", language: .english).subcommand,
            .link(path: nil)
        )
        XCTAssertEqual(
            GitSubcommand.executeParse(argument: "link ~/code/app", language: .english).subcommand,
            .link(path: "~/code/app")
        )
        XCTAssertEqual(
            GitSubcommand.executeParse(argument: "use Demo", language: .english).subcommand,
            .use(name: "Demo")
        )
        XCTAssertEqual(
            GitSubcommand.executeParse(argument: "commit fix bug", language: .english).subcommand,
            .commit(message: "fix bug")
        )
    }

    @MainActor
    func testEmptyCommitOpensHistoryPreview() {
        let parsed = GitSubcommand.executeParse(argument: "commit", language: .english)
        XCTAssertTrue(parsed.isExecutable)
        XCTAssertEqual(parsed.subcommand, .commit(message: ""))
    }

    @MainActor
    func testWhitespaceOnlyCommitOpensHistoryPreview() {
        let parsed = GitSubcommand.executeParse(argument: "commit    ", language: .english)
        XCTAssertTrue(parsed.isExecutable)
        XCTAssertEqual(parsed.subcommand, .commit(message: ""))
    }

    @MainActor
    func testQuotedWhitespaceOnlyCommitOpensHistoryPreview() {
        let parsed = GitSubcommand.executeParse(argument: "commit \"   \"", language: .english)
        XCTAssertTrue(parsed.isExecutable)
        XCTAssertEqual(parsed.subcommand, .commit(message: ""))
    }

    @MainActor
    func testRejectsExtraArgsOnStatusAddRepos() {
        XCTAssertFalse(GitSubcommand.executeParse(argument: "status extra", language: .english).isExecutable)
        XCTAssertFalse(GitSubcommand.executeParse(argument: "add extra", language: .english).isExecutable)
        XCTAssertFalse(GitSubcommand.executeParse(argument: "repos extra", language: .english).isExecutable)
    }

    @MainActor
    func testQueryHelpers() {
        XCTAssertTrue(GitSubcommand.executeIsGitQuery("/git"))
        XCTAssertTrue(GitSubcommand.executeIsGitQuery("/git commit hello"))
        XCTAssertFalse(GitSubcommand.executeIsGitQuery("git status"))
        XCTAssertEqual(GitSubcommand.executeGitSubcommandHead("/git commit hello"), "commit")
        XCTAssertTrue(GitSubcommand.executeIsCommitQuery("/git commit hello"))
        XCTAssertTrue(GitSubcommand.executeIsCommitQuery("/git commit "))
        XCTAssertFalse(GitSubcommand.executeIsCommitQuery("/git commit"))
        XCTAssertFalse(GitSubcommand.executeIsCommitQuery("/git status"))
    }

    @MainActor
    func testUnknownSubcommandIsNotExecutable() {
        let parsed = GitSubcommand.executeParse(argument: "checkout main", language: .english)
        XCTAssertFalse(parsed.isExecutable)
        XCTAssertNil(parsed.subcommand)
    }
}
