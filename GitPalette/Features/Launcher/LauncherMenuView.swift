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
    @ObservedObject var windowPresenter: AppWindowPresenter
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(preferences.t(.openLauncher)) {
            executeOpenLauncher()
        }
        Divider()
        Menu(preferences.t(.copyFormatMenu)) {
            ForEach(CopyFormat.allCases) { format in
                Button {
                    preferences.copyFormat = format
                } label: {
                    buildCopyFormatLabel(format: format)
                }
            }
        }
        Divider()
        SettingsMenuItem(preferences: preferences)
        Button(preferences.t(.about) + preferences.appName) {
            executeOpenAboutWindow()
        }
        Divider()
        Button(preferences.t(.quit) + preferences.appName) {
            executeQuitApp()
        }
        .onChangeCompat(of: hotKeyService.permissionGuideToken) { token in
            guard token != nil else {
                return
            }
            guard !hotKeyService.isAccessibilityGranted else {
                return
            }
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
        guard !hotKeyService.isAccessibilityGranted else {
            return
        }
        DispatchQueue.main.async {
            AppWindowFocus.executePrepareForWindowPresentation()
            openWindow(id: AppWindowID.accessibilityPermission)
            AppWindowFocus.executeBringToFront(identifier: AppWindowID.accessibilityPermission)
        }
    }

    /// 复制格式菜单项标题（含勾选）。
    @ViewBuilder
    private func buildCopyFormatLabel(format: CopyFormat) -> some View {
        let title: String = format.displayName(language: preferences.uiLanguage)
        if preferences.copyFormat == format {
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
