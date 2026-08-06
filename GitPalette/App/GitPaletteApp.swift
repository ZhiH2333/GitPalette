//
//  GitPaletteApp.swift
//  GitPalette
//
//  应用入口：菜单栏 Agent + 启动器 + 全局热键 + Settings。
//

import SwiftUI

@main
struct GitPaletteApp: App {
    @State private var preferences: PreferencesStore
    @State private var recentStore: RecentGitmojiStore
    @State private var launcherController: LauncherController
    @State private var hotKeyService: HotKeyService

    init() {
        let preferences: PreferencesStore = PreferencesStore()
        let recentStore: RecentGitmojiStore = RecentGitmojiStore(
            resolveMaxCount: { preferences.recentMaxCount }
        )
        _preferences = State(initialValue: preferences)
        _recentStore = State(initialValue: recentStore)
        _launcherController = State(
            initialValue: LauncherController(
                appConfig: preferences,
                recentStore: recentStore
            )
        )
        _hotKeyService = State(initialValue: HotKeyService())
    }

    var body: some Scene {
        MenuBarExtra {
            LauncherMenuView(
                preferences: preferences,
                launcherController: launcherController,
                hotKeyService: hotKeyService
            )
        } label: {
            Label(preferences.appName, systemImage: "paintpalette.fill")
        }
        Window("辅助功能权限", id: AppWindowID.accessibilityPermission) {
            AccessibilityPermissionView(hotKeyService: hotKeyService)
        }
        .windowResizability(.contentSize)
        Window("关于 \(preferences.appName)", id: AppWindowID.about) {
            AboutView(
                appName: preferences.appName,
                hotkeyDisplayText: hotKeyService.hotkeyDisplayText
            )
        }
        .windowResizability(.contentSize)
        Settings {
            SettingsView(
                preferences: preferences,
                hotKeyService: hotKeyService,
                launcherController: launcherController
            )
        }
    }
}
