//
//  SettingsView.swift
//  GitPalette
//
//  原生 Settings：通用 / 语言 / 快捷键 / 全部指令。
//

import SwiftUI

/// 设置窗口根视图（系统标准 Tab，不过度玻璃化）。
struct SettingsView: View {
    @ObservedObject var preferences: PreferencesStore
    @ObservedObject var hotKeyService: HotKeyService
    @ObservedObject var windowPresenter: AppWindowPresenter
    var launcherController: LauncherController

    var body: some View {
        TabView(selection: $windowPresenter.settingsTab) {
            GeneralSettingsTab(
                preferences: preferences,
                launcherController: launcherController
            )
            .tabItem {
                Label(preferences.t(.tabGeneral), systemImage: "gearshape")
            }
            .tag(SettingsTab.general)
            LanguageSettingsTab(preferences: preferences)
                .tabItem {
                    Label(preferences.t(.tabLanguage), systemImage: "globe")
                }
                .tag(SettingsTab.language)
            HotKeySettingsTab(
                preferences: preferences,
                hotKeyService: hotKeyService
            )
            .tabItem {
                Label(preferences.t(.tabHotKey), systemImage: "keyboard")
            }
            .tag(SettingsTab.hotkey)
            CommandsSettingsTab(preferences: preferences)
                .tabItem {
                    Label(preferences.t(.tabCommands), systemImage: "list.bullet.indent")
                }
                .tag(SettingsTab.commands)
        }
        .frame(width: 480, height: 400)
    }
}
