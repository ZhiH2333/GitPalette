//
//  LauncherPanel.swift
//  GitPalette
//
//  可成为 key 的 borderless 浮动面板，以便 TextField 接收输入。
//

import AppKit

/// 启动器专用 NSPanel：强制允许成为 key / main。
final class LauncherPanel: NSPanel {
    /// Esc 兜底（搜索框未聚焦时）；不调用 super，避免 NSBeep。
    var onCancelOperation: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancelOperation?()
    }
}
