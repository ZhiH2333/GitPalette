//
//  HotKeyDefaults.swift
//  GitPalette
//
//  全局热键默认值（集中配置，P4 可改为用户可配置）。
//

import Foundation

/// 全局热键默认配置。
enum HotKeyDefaults {
    /// UserDefaults / 快捷键名称标识（勿含点号）
    static let shortcutName: String = "toggleLauncher"
    /// 展示用默认热键文案
    static let displayText: String = "⌘⇧G"
    /// 默认主键字符
    static let keyEquivalent: String = "g"
}
