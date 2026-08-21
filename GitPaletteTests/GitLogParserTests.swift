//
//  GitLogParserTests.swift
//  GitPaletteTests
//

import XCTest
@testable import GitPalette

final class GitLogParserTests: XCTestCase {
    @MainActor
    func testParsesOnelineWithDecorations() {
        let stdout = "* abcdef1 (HEAD -> main, origin/main) first commit\n"
        let entries = GitLogParser.executeParse(stdout)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].hash, "abcdef1")
        XCTAssertEqual(entries[0].decorations, "HEAD -> main, origin/main")
        XCTAssertEqual(entries[0].subject, "first commit")
        XCTAssertTrue(entries[0].graphPrefix.contains("*"))
    }

    @MainActor
    func testParsesOnelineWithoutDecorations() {
        let stdout = "* abcdef1 subject only\n"
        let entries = GitLogParser.executeParse(stdout)
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0].decorations)
        XCTAssertEqual(entries[0].subject, "subject only")
    }

    @MainActor
    func testKeepsGraphOnlyLinesWithoutHash() {
        let stdout = "|/\n"
        let entries = GitLogParser.executeParse(stdout)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].hash, "")
        XCTAssertEqual(entries[0].graphPrefix, "|/")
    }

    @MainActor
    func testEmptyStdoutIsEmptyList() {
        XCTAssertEqual(GitLogParser.executeParse(""), [])
    }
}
