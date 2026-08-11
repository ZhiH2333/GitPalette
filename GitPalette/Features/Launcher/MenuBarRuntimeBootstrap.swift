//
//  MenuBarRuntimeBootstrap.swift
//  GitPalette
//
//  挂在 MenuBarExtra label 上的常驻引导：注册 openWindow / openSettings，并启动热键。
//  不能放在菜单内容里——菜单关闭后视图销毁，Environment action 可能失效。
//

import AppKit
import SwiftUI

/// MenuBarExtra 常驻引导视图（零尺寸，不参与命中）。
struct MenuBarRuntimeBootstrap: View {
    @ObservedObject var preferences: PreferencesStore
    var launcherController: LauncherController
    @ObservedObject var hotKeyService: HotKeyService
    @ObservedObject var windowPresenter: AppWindowPresenter
    @Environment(\.openWindow) private var openWindow
    @State private var didBootstrap: Bool = false

    var body: some View {
        Group {
            if #available(macOS 14.0, *) {
                OpenSettingsEnvironmentBinder(windowPresenter: windowPresenter)
            }
        }
        .background(
            Color.clear
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
                .onAppear {
                    executeRegisterWindowHandlers()
                    executeBootstrapIfNeeded()
                }
        )
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

    /// 启动热键；仅首次执行，避免 label 重建时重复弹启动器。
    private func executeBootstrapIfNeeded() {
        guard !didBootstrap else {
            executeRegisterWindowHandlers()
            return
        }
        didBootstrap = true
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

    private func executeOpenLauncher() {
        DispatchQueue.main.async {
            launcherController.present()
        }
    }

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
}

/// macOS 14+：从常驻视图捕获有效的 openSettings。
@available(macOS 14.0, *)
private struct OpenSettingsEnvironmentBinder: View {
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
