//
//  L10nAndAliasTests.swift
//  GitPaletteTests
//

import XCTest
@testable import GitPalette

final class L10nAndAliasTests: XCTestCase {
    @MainActor
    func testEnglishGitRuntimeCopyShouldNotBeChinese() {
        let keys: [L10nKey] = [
            .gitWorkingTreeClean,
            .gitErrorNoLinkedRepository,
            .gitErrorPathDoesNotExist,
            .gitErrorNotGitRepository,
            .gitErrorRepositoryNameNotFound,
            .gitErrorProcessLaunchFailed,
            .gitErrorNonZeroExit,
            .gitErrorNoStagedChanges,
            .gitErrorNoSelectedPaths,
            .gitErrorRepositoryPathInvalid,
            .gitCommitSucceeded,
            .gitCommitFileCountSuffix,
            .gitLinkSucceeded,
            .gitUseSucceeded,
            .gitUnlinkSucceeded,
            .gitUnlinkNeedsUse,
            .gitReposActiveMark,
            .gitResultRunning
        ]
        for key in keys {
            let text = L10n.text(key, language: .english)
            XCTAssertFalse(
                text.containsChineseScalars,
                "English L10n for \(key.rawValue) is still Chinese: \(text)"
            )
        }
    }

    @MainActor
    func testChineseAliasesExpandSearchTokens() {
        let tokens = GitmojiChineseAliases.expandTokens(from: "修复登录")
        XCTAssertTrue(tokens.contains("修复登录"))
        XCTAssertTrue(tokens.contains("bug"))
        XCTAssertTrue(tokens.contains("fix"))
    }

    @MainActor
    func testCommandRegistryResolvesAliases() {
        XCTAssertEqual(LauncherCommandRegistry.resolveExactCommand(token: "exit"), .quit)
        XCTAssertEqual(LauncherCommandRegistry.resolveExactCommand(token: "/help"), .help)
        XCTAssertNil(LauncherCommandRegistry.resolveExactCommand(token: "nope"))
    }

    @MainActor
    func testGitmojiBundleLoadsAndSearches() throws {
        let repository = try BundleGitmojiRepository()
        XCTAssertFalse(repository.all.isEmpty)
        let sparkles = repository.search(query: "sparkles")
        XCTAssertTrue(sparkles.contains(where: { $0.code == ":sparkles:" }))
        XCTAssertEqual(repository.search(query: "   ").count, repository.all.count)
    }
}

private extension String {
    var containsChineseScalars: Bool {
        unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(scalar.value)
        }
    }
}
