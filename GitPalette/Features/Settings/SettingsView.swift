//
//  SettingsView.swift
//  GitPalette
//
//  原生 Settings：通用 / 快捷键 / 关于。
//

import SwiftUI

/// 设置窗口根视图（系统标准 Tab，不过度玻璃化）。
struct SettingsView: View {
    @Bindable var preferences: PreferencesStore
    var hotKeyService: HotKeyService
    var launcherController: LauncherController

    var body: some View {
        TabView {
            Tab("通用", systemImage: "gearshape") {
                GeneralSettingsTab(
                    preferences: preferences,
                    launcherController: launcherController
                )
            }
            Tab("快捷键", systemImage: "keyboard") {
                HotKeySettingsTab(hotKeyService: hotKeyService)
            }
            Tab("关于", systemImage: "info.circle") {
                AboutSettingsTab(
                    preferences: preferences,
                    hotkeyDisplayText: hotKeyService.hotkeyDisplayText
                )
            }
        }
        .frame(width: 460, height: 360)
    }
}
