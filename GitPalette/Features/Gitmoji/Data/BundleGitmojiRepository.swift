//
//  BundleGitmojiRepository.swift
//  GitPalette
//
//  从 Bundle 内固化 JSON 加载 Gitmoji，支持本地不区分大小写搜索。
//

import Foundation

/// 基于 Bundle JSON 的 Gitmoji 仓库。
final class BundleGitmojiRepository: GitmojiRepository {
    private(set) var all: [Gitmoji]
    private let resourceName: String
    private let resourceExtension: String
    private let bundle: Bundle

    init(
        resourceName: String = "gitmojis",
        resourceExtension: String = "json",
        bundle: Bundle = .main
    ) throws {
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
        self.bundle = bundle
        self.all = try Self.executeLoadFromBundle(
            resourceName: resourceName,
            resourceExtension: resourceExtension,
            bundle: bundle
        )
    }

    func search(query: String) -> [Gitmoji] {
        let trimmed: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return all
        }
        let tokens: [String] = GitmojiChineseAliases.expandTokens(from: trimmed.lowercased())
        return all.filter { item in
            Self.executeMatches(item: item, tokens: tokens)
        }
    }

    /// 从 Bundle 解码 JSON。
    private static func executeLoadFromBundle(
        resourceName: String,
        resourceExtension: String,
        bundle: Bundle
    ) throws -> [Gitmoji] {
        guard let url: URL = bundle.url(
            forResource: resourceName,
            withExtension: resourceExtension
        ) else {
            throw GitmojiRepositoryError.resourceNotFound
        }
        let data: Data = try Data(contentsOf: url)
        let collection: GitmojiCollection = try JSONDecoder().decode(
            GitmojiCollection.self,
            from: data
        )
        return collection.gitmojis
    }

    /// 判断条目是否匹配任一搜索 token。
    private static func executeMatches(item: Gitmoji, tokens: [String]) -> Bool {
        let code: String = item.code.lowercased()
        let description: String = item.description.lowercased()
        let name: String = item.name.lowercased()
        let emoji: String = item.emoji
        for token in tokens {
            if code.contains(token)
                || description.contains(token)
                || name.contains(token)
                || emoji.contains(token) {
                return true
            }
        }
        return false
    }
}
