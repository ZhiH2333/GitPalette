//
//  GitStatusParserTests.swift
//  GitPaletteTests
//

import XCTest
@testable import GitPalette

final class GitStatusParserTests: XCTestCase {
    @MainActor
    func testParsesModifiedAddedDeletedUntrackedAndRenamed() {
        let porcelain = """
         M src/App.swift
        A  new.txt
         D gone.md
        ?? untracked.swift
        R  old.txt -> new.txt
        """
        let entries = GitStatusParser.executeParse(porcelain)
        XCTAssertEqual(entries.count, 5)
        XCTAssertEqual(entries[0].kind, .modified)
        XCTAssertFalse(entries[0].isStaged)
        XCTAssertEqual(entries[0].relativePath, "src/App.swift")
        XCTAssertEqual(entries[1].kind, .added)
        XCTAssertTrue(entries[1].isStaged)
        XCTAssertEqual(entries[2].kind, .deleted)
        XCTAssertEqual(entries[3].kind, .untracked)
        XCTAssertFalse(entries[3].isStaged)
        XCTAssertEqual(entries[4].kind, .renamed)
        XCTAssertEqual(entries[4].originalPath, "old.txt")
        XCTAssertEqual(entries[4].relativePath, "new.txt")
        XCTAssertTrue(entries[4].isStaged)
    }

    @MainActor
    func testUnquotesEscapedQuotesAndBackslashes() {
        let porcelain = #"?? "file with \"quotes\".txt""#
        let entries = GitStatusParser.executeParse(porcelain)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].relativePath, #"file with "quotes".txt"#)
    }

    @MainActor
    func testIgnoresLinesThatAreTooShort() {
        XCTAssertEqual(GitStatusParser.executeParse("M\n"), [])
        XCTAssertEqual(GitStatusParser.executeParse(""), [])
    }

    @MainActor
    func testConflictedUnmergedPathShouldNotLookLikeOrdinaryModified() {
        let entries = GitStatusParser.executeParse("UU conflicted.swift\n")
        XCTAssertEqual(entries.count, 1)
        XCTAssertNotEqual(
            entries[0].kind,
            .modified,
            "merge conflicts should not be classified as modified"
        )
    }

    @MainActor
    func testCopiedPathShouldNotBeClassifiedAsRenamed() {
        let entries = GitStatusParser.executeParse("C  src/a.swift -> src/b.swift\n")
        XCTAssertEqual(entries.count, 1)
        XCTAssertNotEqual(
            entries[0].kind,
            .renamed,
            "copied files should not be classified as renamed"
        )
    }

    @MainActor
    func testUnquotesPorcelainOctalEscapesForNonASCIIPaths() {
        let quoted = "?? \"\\344\\270\\255.txt\""
        let entries = GitStatusParser.executeParse(quoted)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].relativePath, "中.txt")
    }
}
