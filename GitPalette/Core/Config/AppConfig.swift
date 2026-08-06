//
//  AppConfig.swift
//  GitPalette
//
//  应用级配置：Observation 状态源，本阶段仅占位常量与默认值。
//

import Foundation
import Observation

/// 应用级配置。
@Observable
final class AppConfig {
    /// 应用显示名称
    let appName: String
    /// 默认全局热键占位字符串（本阶段不注册热键）
    let defaultHotkeyPlaceholder: String
    /// Gitmoji API 地址占位（本阶段不发起网络请求）
    let gitmojiAPIURL: String
    /// 复制格式默认值
    var copyFormat: CopyFormat

    init(
        appName: String = "GitPalette",
        defaultHotkeyPlaceholder: String = "⌘⇧G",
        gitmojiAPIURL: String = "https://gitmoji.dev/api/gitmojis",
        copyFormat: CopyFormat = .emoji
    ) {
        self.appName = appName
        self.defaultHotkeyPlaceholder = defaultHotkeyPlaceholder
        self.gitmojiAPIURL = gitmojiAPIURL
        self.copyFormat = copyFormat
    }
}
