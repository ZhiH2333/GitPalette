//
//  AppConfig.swift
//  GitPalette
//
//  应用级配置：Observation 状态源，复制格式持久化到 UserDefaults。
//

import Foundation
import Observation

/// 应用级配置。
@Observable
final class AppConfig {
    private static let copyFormatKey: String = "gitpalette.copyFormat"

    /// 应用显示名称
    let appName: String
    /// 默认全局热键展示文案（与 HotKeyDefaults 对齐）
    let defaultHotkeyPlaceholder: String
    /// Gitmoji API 地址占位（本阶段不发起网络请求）
    let gitmojiAPIURL: String
    /// 复制格式（emoji / :code: 等）
    var copyFormat: CopyFormat {
        didSet { executePersistCopyFormat() }
    }

    init(
        appName: String = "GitPalette",
        defaultHotkeyPlaceholder: String = HotKeyDefaults.displayText,
        gitmojiAPIURL: String = "https://gitmoji.dev/api/gitmojis",
        copyFormat: CopyFormat? = nil
    ) {
        self.appName = appName
        self.defaultHotkeyPlaceholder = defaultHotkeyPlaceholder
        self.gitmojiAPIURL = gitmojiAPIURL
        if let copyFormat {
            self.copyFormat = copyFormat
        } else if let raw: String = UserDefaults.standard.string(forKey: Self.copyFormatKey),
                  let stored: CopyFormat = CopyFormat(rawValue: raw) {
            self.copyFormat = stored
        } else {
            self.copyFormat = .emoji
        }
    }

    /// 将复制格式写入 UserDefaults。
    private func executePersistCopyFormat() {
        UserDefaults.standard.set(copyFormat.rawValue, forKey: Self.copyFormatKey)
    }
}
