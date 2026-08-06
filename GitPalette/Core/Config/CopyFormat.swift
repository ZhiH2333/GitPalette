//
//  CopyFormat.swift
//  GitPalette
//
//  复制格式占位枚举（本阶段仅默认值，无剪贴板逻辑）。
//

import Foundation

/// Gitmoji 复制格式占位。
enum CopyFormat: String, CaseIterable, Sendable {
    /// 仅表情符号
    case emoji
    /// 仅代码（如 `:sparkles:`）
    case code
    /// 表情 + 描述
    case emojiAndDescription
}
