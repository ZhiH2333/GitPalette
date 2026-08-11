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
        if !hotKeyService.isAccessibilityGranted {
            Button(preferences.t(.grantAccessibility)) {
                hotKeyService.executePresentPermissionGuide()
                executeOpenAccessibilityWindow()
            }
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
        .onAppear {
            executeRegisterWindowHandlers()
            executeBootstrapHotKey()
        }
        .background {
            if #available(macOS 14.0, *) {
                OpenSettingsHandlerBinder(windowPresenter: windowPresenter)
            }
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

    /// 注册命令系统可用的窗口打开回调。
    private func executeRegisterWindowHandlers() {
        windowPresenter.executeRegisterHandlers(
            openAbout: { [openWindow, preferences] in
                DispatchQueue.main.async {
                    AppWindowFocus.executePrepareForWindowPresentation()
                    openWindow(id: AppWindowID.about)
                    AppWindowFocus.executeBringToFront(
                        titleContaining: ["关于", "About", preferences.appName]
                    )
                }
            },
            openPermissions: { [openWindow] in
                DispatchQueue.main.async {
                    AppWindowFocus.executePrepareForWindowPresentation()
                    openWindow(id: AppWindowID.accessibilityPermission)
                    AppWindowFocus.executeBringToFront(
                        titleContaining: ["辅助功能", "Accessibility", "权限"]
                    )
                }
            }
        )
    }

    /// 启动热键服务；已授权则打开启动器，未授权且需引导时才弹权限窗。
    private func executeBootstrapHotKey() {
        hotKeyService.executeStart {
            launcherController.toggle()
        }
        hotKeyService.executeRefreshStatus()
        executeCloseAccessibilityWindows()
        if hotKeyService.isAccessibilityGranted {
            executeOpenLauncher()
            return
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
        guard !hotKeyService.isAccessibilityGranted else {
            return
        }
        DispatchQueue.main.async {
            AppWindowFocus.executePrepareForWindowPresentation()
            openWindow(id: AppWindowID.accessibilityPermission)
            AppWindowFocus.executeBringToFront(
                titleContaining: ["辅助功能", "Accessibility", "权限"]
            )
        }
    }

    /// 关闭可能被系统恢复的辅助功能引导窗。
    private func executeCloseAccessibilityWindows() {
        for window in NSApp.windows {
            let title: String = window.title
            let isAccessibilityWindow: Bool =
                title.contains("辅助功能")
                || title.localizedCaseInsensitiveContains("Accessibility")
            if isAccessibilityWindow {
                window.close()
            }
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

/// macOS 14+：把 Environment.openSettings 接到命令开设置路径。
@available(macOS 14.0, *)
private struct OpenSettingsHandlerBinder: View {
    @ObservedObject var windowPresenter: AppWindowPresenter
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear {
                windowPresenter.executeRegisterOpenSettingsHandler {
                    openSettings()
                }
            }
    }
}
