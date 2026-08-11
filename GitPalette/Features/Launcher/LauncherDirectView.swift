//
//  LauncherDirectView.swift
//  GitPalette
//
//  菜单栏「打开启动器」模式：点击直接唤起 Spotlight 面板，不展示任何菜单项。
//

import AppKit
import SwiftUI

/// 直接打开启动器模式下的菜单栏内容（零 UI；面板成为主窗口后菜单自动收起）。
struct LauncherDirectView: View {
    var launcherController: LauncherController

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                launcherController.present()
            }
    }
}
