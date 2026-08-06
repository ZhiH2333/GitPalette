//
//  HotKeyShortcutName.swift
//  GitPalette
//
//  KeyboardShortcuts.Name 注册（仅 HotKey 层可见）。
//

import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// 切换启动器（默认 ⌘⇧G）。
    static let toggleLauncher = Self(
        HotKeyDefaults.shortcutName,
        initial: .init(.g, modifiers: [.command, .shift])
    )
}
