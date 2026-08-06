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
    var launcherController: LauncherController

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

    /// 调用 LauncherController 打开浮动面板。
    private func executeOpenLauncher() {
        // 等菜单栏菜单收起后再 present，避免抢焦点失败。
        DispatchQueue.main.async {
            launcherController.present()
        }
    }

    /// 退出应用。
    private func executeQuitApp() {
        NSApplication.shared.terminate(nil)
    }
}
