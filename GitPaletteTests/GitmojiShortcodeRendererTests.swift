//
//  GitmojiShortcodeRendererTests.swift
//  GitPaletteTests
//

import XCTest
@testable import GitPalette

final class GitmojiShortcodeRendererTests: XCTestCase {
    @MainActor
    func testReplacesKnownShortcodesAndLeavesUnknown() {
        let lookup: [String: String] = [
            ":bug:": "🐛",
            ":sparkles:": "✨"
        ]
        XCTAssertEqual(
            GitmojiShortcodeRenderer.executeRender(":bug: fix login", lookup: lookup),
            "🐛 fix login"
        )
        XCTAssertEqual(
            GitmojiShortcodeRenderer.executeRender(":sparkles: :bug: both", lookup: lookup),
            "✨ 🐛 both"
        )
        XCTAssertEqual(
            GitmojiShortcodeRenderer.executeRender(":not_a_gitmoji: keep", lookup: lookup),
            ":not_a_gitmoji: keep"
        )
        XCTAssertEqual(
            GitmojiShortcodeRenderer.executeRender("plain subject", lookup: lookup),
            "plain subject"
        )
    }

    @MainActor
    func testRendersOfficialBugCodeFromBundle() throws {
        let repository = try BundleGitmojiRepository()
        let bug = repository.all.first { $0.code == ":bug:" }
        XCTAssertNotNil(bug)
        let rendered = GitmojiShortcodeRenderer.executeRender(":bug: crash on launch")
        XCTAssertEqual(rendered, "\(bug!.emoji) crash on launch")
        XCTAssertFalse(rendered.contains(":bug:"))
    }
}
