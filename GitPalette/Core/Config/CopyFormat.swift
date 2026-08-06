//
//  CopyFormat.swift
//  GitPalette
//
//  Gitmoji 复制格式枚举。
//

import Foundation

/// Gitmoji 复制格式。
enum CopyFormat: String, CaseIterable, Identifiable, Sendable {
    /// 仅表情符号
    case emoji
    /// 仅 shortcode（如 `:sparkles:`）
    case code
    /// 自定义模板（如 `{emoji} `）
    case customTemplate

    var id: String { rawValue }

    /// 设置 / 菜单展示名。
    var displayName: String {
        switch self {
        case .emoji:
            return "emoji"
        case .code:
            return ":code:"
        case .customTemplate:
            return "自定义模板"
        }
    }
}
