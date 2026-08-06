//
//  LauncherMenuView.swift
//  GitPalette
//
//  菜单栏弹出菜单占位内容。
//

import AppKit
import SwiftUI

/// 菜单栏 Extra 菜单占位视图。
struct LauncherMenuView: View {
    var body: some View {
        Button("打开启动器（占位）") {
            executeOpenLauncherPlaceholder()
        }
        SettingsLink {
            Text("设置（占位）")
        }
        Divider()
        Button("退出") {
            executeQuitApp()
        }
    }

    /// 打开启动器占位（本阶段不打开面板、不触发搜索）。
    private func executeOpenLauncherPlaceholder() {
        // 后续阶段：唤起 Gitmoji 搜索面板
    }

    /// 退出应用。
    private func executeQuitApp() {
        NSApplication.shared.terminate(nil)
    }
}
