//
//  GitmojiShortcodeRenderer.swift
//  GitPalette
//
//  将提交说明中的 gitmoji shortcode（如 `:bug:`）替换为对应 emoji。
//

import Foundation

/// 提交说明中的 gitmoji shortcode 渲染。
enum GitmojiShortcodeRenderer {
    private static let cachedLookup: [String: String] = executeLoadLookup()

    /// 将文本中已知的 `:code:` 替换为 emoji；未知 token 保持原样。
    static func executeRender(_ text: String, lookup: [String: String]? = nil) -> String {
        let map: [String: String] = lookup ?? cachedLookup
        guard !map.isEmpty, text.contains(":") else {
            return text
        }
        var result: String = ""
        var index: String.Index = text.startIndex
        while index < text.endIndex {
            if text[index] == ":",
               let closing: String.Index = text[text.index(after: index)...].firstIndex(of: ":") {
                let token: String = String(text[index...closing])
                if token.count >= 3, let emoji: String = map[token.lowercased()] {
                    result.append(emoji)
                    index = text.index(after: closing)
                    continue
                }
            }
            result.append(text[index])
            index = text.index(after: index)
        }
        return result
    }

    /// 从内置 gitmoji 表建立 `:code:` → emoji。
    private static func executeLoadLookup() -> [String: String] {
        guard let repository: BundleGitmojiRepository = try? BundleGitmojiRepository() else {
            return [:]
        }
        var map: [String: String] = [:]
        map.reserveCapacity(repository.all.count)
        for item in repository.all {
            map[item.code.lowercased()] = item.emoji
        }
        return map
    }
}
