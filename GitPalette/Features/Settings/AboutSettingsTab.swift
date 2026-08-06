//
//  AboutSettingsTab.swift
//  GitPalette
//
//  设置 · 关于：应用信息与菜单栏说明。
//

import SwiftUI

/// 关于设置页。
struct AboutSettingsTab: View {
    let preferences: PreferencesStore
    let hotkeyDisplayText: String

    var body: some View {
        Form {
            Section("应用") {
                LabeledContent("名称", value: preferences.appName)
                LabeledContent("全局热键", value: hotkeyDisplayText)
                Text("菜单栏 Gitmoji 助手")
                    .foregroundStyle(.secondary)
            }
            Section("菜单栏图标") {
                Text("GitPalette 为菜单栏应用（LSUIElement）。启动后图标显示在菜单栏右侧，Dock 中不会出现图标。若找不到图标，请检查菜单栏是否被其他图标挤占，或确认应用进程仍在运行。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section("后续（P5）") {
                Text("AI Provider / API Key 等能力将在 P5 提供，本阶段不存储任何密钥。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
