//
//  GitPaletteApp.swift
//  GitPalette
//
//  应用入口：菜单栏 Agent + 启动器 + 全局热键 + Settings。
//

import SwiftUI

@main
struct GitPaletteApp: App {
    @StateObject private var preferences: PreferencesStore
    @StateObject private var hotKeyService: HotKeyService
    private let recentStore: RecentGitmojiStore
    private let launcherController: LauncherController

    init() {
        let preferences: PreferencesStore = PreferencesStore()
        let recentStore: RecentGitmojiStore = RecentGitmojiStore(
            resolveMaxCount: { preferences.recentMaxCount }
        )
        _preferences = StateObject(wrappedValue: preferences)
        _hotKeyService = StateObject(wrappedValue: HotKeyService())
        self.recentStore = recentStore
        self.launcherController = LauncherController(
            appConfig: preferences,
            recentStore: recentStore
        )
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
        Window(preferences.t(.needAccessibilityTitle), id: AppWindowID.accessibilityPermission) {
            AccessibilityPermissionView(
                preferences: preferences,
                hotKeyService: hotKeyService
            )
            .applyWindowForegroundFocus()
        }
        .windowResizability(.contentSize)
        Window(preferences.t(.about) + preferences.appName, id: AppWindowID.about) {
            AboutView(preferences: preferences)
                .applyWindowForegroundFocus()
        }
        .windowResizability(.contentSize)
        Settings {
            SettingsView(
                preferences: preferences,
                hotKeyService: hotKeyService,
                launcherController: launcherController
            )
            .applyWindowForegroundFocus()
        }
    }
}
