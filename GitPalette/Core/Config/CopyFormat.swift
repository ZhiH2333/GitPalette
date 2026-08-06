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
    func displayName(language: AppLanguage) -> String {
        switch self {
        case .emoji:
            return L10n.text(.formatEmoji, language: language)
        case .code:
            return L10n.text(.formatCode, language: language)
        case .customTemplate:
            return L10n.text(.formatCustomTemplate, language: language)
        }
    }
}
