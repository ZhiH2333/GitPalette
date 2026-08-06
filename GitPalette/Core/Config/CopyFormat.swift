//
//  CopyFormat.swift
//  GitPalette
//
//  Gitmoji 复制格式枚举。
//

import Foundation

/// Gitmoji 复制格式。
enum CopyFormat: String, CaseIterable, Sendable {
    /// 仅表情符号
    case emoji
    /// 仅 shortcode（如 `:sparkles:`）
    case code
    /// 表情 + 描述（预留）
    case emojiAndDescription
}
