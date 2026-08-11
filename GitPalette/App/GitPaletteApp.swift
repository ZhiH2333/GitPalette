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
    @StateObject private var windowPresenter: AppWindowPresenter
    private let recentStore: RecentGitmojiStore
    private let launcherController: LauncherController

    init() {
        let preferences: PreferencesStore = PreferencesStore()
        let recentStore: RecentGitmojiStore = RecentGitmojiStore(
            resolveMaxCount: { preferences.recentMaxCount }
        )
        let hotKeyService: HotKeyService = HotKeyService()
        let windowPresenter: AppWindowPresenter = AppWindowPresenter()
        _preferences = StateObject(wrappedValue: preferences)
        _hotKeyService = StateObject(wrappedValue: hotKeyService)
        _windowPresenter = StateObject(wrappedValue: windowPresenter)
        self.recentStore = recentStore
        self.launcherController = LauncherController(
            appConfig: preferences,
            recentStore: recentStore,
            hotKeyService: hotKeyService,
            windowPresenter: windowPresenter
        )
    }

    var body: some Scene {
        MenuBarExtra {
            LauncherMenuView(
                preferences: preferences,
                launcherController: launcherController,
                hotKeyService: hotKeyService,
                windowPresenter: windowPresenter
            )
        } label: {
            Label(preferences.appName, systemImage: "paintpalette.fill")
                .background {
                    MenuBarRuntimeBootstrap(
                        preferences: preferences,
                        launcherController: launcherController,
                        hotKeyService: hotKeyService,
                        windowPresenter: windowPresenter
                    )
                }
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
                windowPresenter: windowPresenter,
                launcherController: launcherController
            )
            .applyWindowForegroundFocus()
        }
    }
}
