//
//  GitmojiLocalization.swift
//  GitPalette
//
//  Gitmoji code 译名与描述本地化。
//

import Foundation

/// 单条 Gitmoji 中文译名。
struct GitmojiZhEntry: Codable, Sendable {
    let codeName: String
    let description: String
}

/// Gitmoji 本地化解析。
enum GitmojiLocalization {
    private static let zhTable: [String: GitmojiZhEntry] = executeLoadZhTable()

    /// 解析展示 / 复制用的 code 文本。
    /// English → `:bug:`；简体中文 → `:bug: 缺陷`。
    static func resolveCodeText(for item: Gitmoji, language: AppLanguage) -> String {
        switch language {
        case .english:
            return item.code
        case .simplifiedChinese:
            guard let name: String = zhTable[item.name]?.codeName, !name.isEmpty else {
                return item.code
            }
            return "\(item.code) \(name)"
        }
    }

    /// 解析展示 / 复制用的描述文本。
    static func resolveDescriptionText(for item: Gitmoji, language: AppLanguage) -> String {
        switch language {
        case .english:
            return item.description
        case .simplifiedChinese:
            return zhTable[item.name]?.description ?? item.description
        }
    }

    /// 解析 code 译名（不含 shortcode）；无译名时返回 nil。
    static func resolveCodeName(for item: Gitmoji, language: AppLanguage) -> String? {
        switch language {
        case .english:
            return nil
        case .simplifiedChinese:
            let name: String? = zhTable[item.name]?.codeName
            if let name, !name.isEmpty {
                return name
            }
            return nil
        }
    }

    private static func executeLoadZhTable() -> [String: GitmojiZhEntry] {
        guard let url: URL = Bundle.main.url(forResource: "gitmoji_zh", withExtension: "json") else {
            return [:]
        }
        guard let data: Data = try? Data(contentsOf: url) else {
            return [:]
        }
        return (try? JSONDecoder().decode([String: GitmojiZhEntry].self, from: data)) ?? [:]
    }
}
