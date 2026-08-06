//
//  LauncherMenuView.swift
//  GitPalette
//
//  菜单栏弹出菜单：打开启动器、设置、退出。
//

import AppKit
import SwiftUI

/// 菜单栏 Extra 菜单视图。
struct LauncherMenuView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("打开启动器") {
            executeOpenLauncher()
        }
        SettingsLink {
            Text("设置")
        }
        Divider()
        Button("退出") {
            executeQuitApp()
        }
    }

    /// 打开 Gitmoji 启动器窗口。
    private func executeOpenLauncher() {
        openWindow(id: "launcher")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    /// 退出应用。
    private func executeQuitApp() {
        NSApplication.shared.terminate(nil)
    }
}
