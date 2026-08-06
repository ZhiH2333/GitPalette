//
//  LauncherMenuView.swift
//  GitPalette
//
//  菜单栏菜单定型：启动器、复制格式、权限、设置、关于、退出。
//

import AppKit
import SwiftUI

/// 菜单栏 Extra 菜单视图。
struct LauncherMenuView: View {
    @Bindable var appConfig: AppConfig
    var launcherController: LauncherController
    var hotKeyService: HotKeyService
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("打开启动器") {
            executeOpenLauncher()
        }
        .keyboardShortcut("g", modifiers: [.command, .shift])
        if !hotKeyService.isAccessibilityGranted {
            Button("授予辅助功能权限…") {
                hotKeyService.executePresentPermissionGuide()
                executeOpenAccessibilityWindow()
            }
        }
        Divider()
        Menu("复制格式") {
            Button {
                appConfig.copyFormat = .emoji
            } label: {
                buildCopyFormatLabel(title: "emoji", format: .emoji)
            }
            Button {
                appConfig.copyFormat = .code
            } label: {
                buildCopyFormatLabel(title: ":code:", format: .code)
            }
        }
        Divider()
        SettingsLink {
            Text("设置…")
        }
        Button("关于 \(appConfig.appName)") {
            openWindow(id: AppWindowID.about)
        }
        Divider()
        Button("退出 \(appConfig.appName)") {
            executeQuitApp()
        }
        .onAppear {
            executeBootstrapHotKey()
        }
        .onChange(of: hotKeyService.permissionGuideToken) { _, token in
            guard token != nil else {
                return
            }
            executeOpenAccessibilityWindow()
        }
    }

    /// 启动热键服务（幂等）。
    private func executeBootstrapHotKey() {
        hotKeyService.executeStart {
            launcherController.toggle()
        }
        if hotKeyService.permissionGuideToken != nil {
            executeOpenAccessibilityWindow()
        }
    }

    /// 打开启动器面板。
    private func executeOpenLauncher() {
        DispatchQueue.main.async {
            launcherController.present()
        }
    }

    /// 打开辅助功能引导窗。
    private func executeOpenAccessibilityWindow() {
        DispatchQueue.main.async {
            openWindow(id: AppWindowID.accessibilityPermission)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// 复制格式菜单项标题（含勾选）。
    @ViewBuilder
    private func buildCopyFormatLabel(title: String, format: CopyFormat) -> some View {
        if appConfig.copyFormat == format {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

    /// 退出应用。
    private func executeQuitApp() {
        NSApplication.shared.terminate(nil)
    }
}
