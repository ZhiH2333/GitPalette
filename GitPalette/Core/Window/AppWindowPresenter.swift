//
//  AppWindowPresenter.swift
//  GitPalette
//
//  极薄窗口打开门面：供命令执行器与菜单栏复用。
//

import AppKit
import Combine
import Foundation

/// 应用窗口打开与设置 Tab 导航。
@MainActor
final class AppWindowPresenter: ObservableObject {
    /// 设置窗口当前 / 待选中的 Tab
    @Published var settingsTab: SettingsTab = .general
    private var openSettingsHandler: (() -> Void)?
    private var openAboutHandler: (() -> Void)?
    private var openPermissionsHandler: (() -> Void)?

    /// 由具备 openWindow 的 View 注册回调。
    func executeRegisterHandlers(
        openAbout: @escaping () -> Void,
        openPermissions: @escaping () -> Void
    ) {
        openAboutHandler = openAbout
        openPermissionsHandler = openPermissions
    }

    /// 由具备 openSettings 的 View 注册回调（macOS 14+）。
    func executeRegisterOpenSettingsHandler(_ openSettings: @escaping () -> Void) {
        openSettingsHandler = openSettings
    }

    /// 打开设置并定位到指定 Tab。
    func executeOpenSettings(tab: SettingsTab = .general) {
        settingsTab = tab
        if let openSettingsHandler {
            AppWindowFocus.executePrepareForWindowPresentation()
            openSettingsHandler()
            AppWindowFocus.executeBringSettingsToFront()
            return
        }
        SettingsWindowOpener.executeOpenLegacy()
        AppWindowFocus.executeBringSettingsToFront()
    }

    /// 打开关于窗口。
    func executeOpenAbout() {
        AppWindowFocus.executePrepareForWindowPresentation()
        openAboutHandler?()
    }

    /// 打开辅助功能权限引导窗口。
    func executeOpenPermissions() {
        AppWindowFocus.executePrepareForWindowPresentation()
        openPermissionsHandler?()
    }
}
