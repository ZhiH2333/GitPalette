//
//  GitPaletteApp.swift
//  GitPalette
//
//  应用入口：菜单栏 Agent + 启动器 + 全局热键。
//

import SwiftUI

@main
struct GitPaletteApp: App {
    @State private var appConfig: AppConfig
    @State private var launcherController: LauncherController
    @State private var hotKeyService: HotKeyService

    init() {
        let config: AppConfig = AppConfig()
        _appConfig = State(initialValue: config)
        _launcherController = State(initialValue: LauncherController(appConfig: config))
        _hotKeyService = State(initialValue: HotKeyService())
    }

    var body: some Scene {
        MenuBarExtra {
            LauncherMenuView(
                appConfig: appConfig,
                launcherController: launcherController,
                hotKeyService: hotKeyService
            )
        } label: {
            Label(appConfig.appName, systemImage: "paintpalette.fill")
        }
        Window("辅助功能权限", id: AppWindowID.accessibilityPermission) {
            AccessibilityPermissionView(hotKeyService: hotKeyService)
        }
        .windowResizability(.contentSize)
        Window("关于 \(appConfig.appName)", id: AppWindowID.about) {
            AboutView(
                appName: appConfig.appName,
                hotkeyDisplayText: hotKeyService.hotkeyDisplayText
            )
        }
        .windowResizability(.contentSize)
        Settings {
            SettingsView(appConfig: appConfig, hotKeyService: hotKeyService)
                .applyGlassStylePlaceholder()
        }
    }
}
