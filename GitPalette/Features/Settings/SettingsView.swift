//
//  SettingsView.swift
//  GitPalette
//
//  原生 Settings：通用 / 语言 / 快捷键。
//

import SwiftUI

/// 设置窗口根视图（系统标准 Tab，不过度玻璃化）。
struct SettingsView: View {
    @ObservedObject var preferences: PreferencesStore
    @ObservedObject var hotKeyService: HotKeyService
    var launcherController: LauncherController

    var body: some View {
        TabView {
            GeneralSettingsTab(
                preferences: preferences,
                launcherController: launcherController
            )
            .tabItem {
                Label(preferences.t(.tabGeneral), systemImage: "gearshape")
            }
            LanguageSettingsTab(preferences: preferences)
                .tabItem {
                    Label(preferences.t(.tabLanguage), systemImage: "globe")
                }
            HotKeySettingsTab(
                preferences: preferences,
                hotKeyService: hotKeyService
            )
            .tabItem {
                Label(preferences.t(.tabHotKey), systemImage: "keyboard")
            }
        }
        .frame(width: 480, height: 400)
    }
}
