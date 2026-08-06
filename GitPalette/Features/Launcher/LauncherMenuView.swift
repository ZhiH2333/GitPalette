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
    @ObservedObject var preferences: PreferencesStore
    var launcherController: LauncherController
    @ObservedObject var hotKeyService: HotKeyService
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("打开启动器") {
            executeOpenLauncher()
        }
        if !hotKeyService.isAccessibilityGranted {
            Button("授予辅助功能权限…") {
                hotKeyService.executePresentPermissionGuide()
                executeOpenAccessibilityWindow()
            }
        }
        Divider()
        Menu("复制格式") {
            ForEach(CopyFormat.allCases) { format in
                Button {
                    preferences.copyFormat = format
                } label: {
                    buildCopyFormatLabel(format: format)
                }
            }
        }
        Divider()
        SettingsMenuItem()
        Button("关于 \(preferences.appName)") {
            executeOpenAboutWindow()
        }
        Divider()
        Button("退出 \(preferences.appName)") {
            executeQuitApp()
        }
        .onAppear {
            executeBootstrapHotKey()
        }
        .onChangeCompat(of: hotKeyService.permissionGuideToken) { token in
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

    /// 打开关于窗口并置前。
    private func executeOpenAboutWindow() {
        DispatchQueue.main.async {
            AppWindowFocus.executePrepareForWindowPresentation()
            openWindow(id: AppWindowID.about)
            AppWindowFocus.executeBringToFront(
                titleContaining: ["关于", "About", preferences.appName]
            )
        }
    }

    /// 打开辅助功能引导窗并置前。
    private func executeOpenAccessibilityWindow() {
        DispatchQueue.main.async {
            AppWindowFocus.executePrepareForWindowPresentation()
            openWindow(id: AppWindowID.accessibilityPermission)
            AppWindowFocus.executeBringToFront(
                titleContaining: ["辅助功能", "Accessibility", "权限"]
            )
        }
    }

    /// 复制格式菜单项标题（含勾选）。
    @ViewBuilder
    private func buildCopyFormatLabel(format: CopyFormat) -> some View {
        if preferences.copyFormat == format {
            Label(format.displayName, systemImage: "checkmark")
        } else {
            Text(format.displayName)
        }
    }

    /// 退出应用。
    private func executeQuitApp() {
        NSApplication.shared.terminate(nil)
    }
}
