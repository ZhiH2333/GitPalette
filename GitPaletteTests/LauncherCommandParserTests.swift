//
//  LauncherCommandParserTests.swift
//  GitPaletteTests
//

import XCTest
@testable import GitPalette

final class LauncherCommandParserTests: XCTestCase {
    @MainActor
    func testNonSlashQueryIsNotCommandMode() {
        let result = LauncherCommandParser.executeParse("sparkles", language: .english)
        XCTAssertEqual(result, .notCommandMode)
    }

    @MainActor
    func testBareSlashIsCommandModeButNotExecutable() {
        let result = LauncherCommandParser.executeParse("/", language: .english)
        XCTAssertTrue(result.isCommandMode)
        XCTAssertNil(result.matchedCommand)
        XCTAssertFalse(result.isExecutable)
    }

    @MainActor
    func testExactCommandNamesAndAliases() {
        XCTAssertEqual(
            LauncherCommandParser.executeParse("/quit", language: .english).matchedCommand,
            .quit
        )
        XCTAssertTrue(LauncherCommandParser.executeParse("/quit", language: .english).isExecutable)
        XCTAssertEqual(
            LauncherCommandParser.executeParse("/exit", language: .english).matchedCommand,
            .quit
        )
        XCTAssertEqual(
            LauncherCommandParser.executeParse("/?", language: .english).matchedCommand,
            .help
        )
        XCTAssertEqual(
            LauncherCommandParser.executeParse("/accessibility", language: .english).matchedCommand,
            .permissions
        )
    }

    @MainActor
    func testGitCommitWithoutMessageIsExecutablePreview() {
        let incomplete = LauncherCommandParser.executeParse("/git commit", language: .english)
        XCTAssertEqual(incomplete.matchedCommand, .git)
        XCTAssertTrue(incomplete.isExecutable)

        let complete = LauncherCommandParser.executeParse("/git commit ship it", language: .english)
        XCTAssertTrue(complete.isExecutable)
        XCTAssertEqual(complete.rawArgumentText, "commit ship it")
    }

    @MainActor
    func testTemplateKeepsFullArgument() {
        let result = LauncherCommandParser.executeParse("/template {emoji} {code}", language: .english)
        XCTAssertTrue(result.isExecutable)
        XCTAssertEqual(result.rawArgumentText, "{emoji} {code}")
    }

    @MainActor
    func testUnknownCommandStaysInCommandMode() {
        let result = LauncherCommandParser.executeParse("/nope", language: .english)
        XCTAssertTrue(result.isCommandMode)
        XCTAssertNil(result.matchedCommand)
        XCTAssertFalse(result.isExecutable)
    }
}
