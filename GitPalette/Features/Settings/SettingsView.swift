//
//  SettingsView.swift
//  GitPalette
//
//  原生 Settings：通用 / 快捷键 / 关于。
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
                Label("通用", systemImage: "gearshape")
            }
            HotKeySettingsTab(hotKeyService: hotKeyService)
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }
            AboutSettingsTab(
                preferences: preferences,
                hotkeyDisplayText: hotKeyService.hotkeyDisplayText
            )
            .tabItem {
                Label("关于", systemImage: "info.circle")
            }
        }
        .frame(width: 460, height: 400)
    }
}
