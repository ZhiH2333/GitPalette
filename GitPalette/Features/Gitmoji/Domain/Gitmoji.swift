//
//  Gitmoji.swift
//  GitPalette
//
//  Gitmoji 领域模型，字段对齐官方 API JSON。
//

import Foundation

/// 单条 Gitmoji。
struct Gitmoji: Codable, Identifiable, Hashable, Sendable {
    /// 使用 shortcode 作为稳定标识
    var id: String { code }
    /// 表情符号
    let emoji: String
    /// HTML 实体或等价表示
    let entity: String
    /// Shortcode，如 `:sparkles:`
    let code: String
    /// 英文描述
    let description: String
    /// 名称（通常与 code 去冒号后一致）
    let name: String
    /// 语义化版本影响：major / minor / patch，可为 null
    let semver: String?
}
