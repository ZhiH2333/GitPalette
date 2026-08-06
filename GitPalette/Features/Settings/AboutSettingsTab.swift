//
//  AboutSettingsTab.swift
//  GitPalette
//
//  设置 · 关于：应用信息与菜单栏说明。
//

import SwiftUI

/// 关于设置页。
struct AboutSettingsTab: View {
    @ObservedObject var preferences: PreferencesStore
    let hotkeyDisplayText: String

    var body: some View {
        Form {
            Section(preferences.t(.sectionApp)) {
                LabeledContent(preferences.t(.name), value: preferences.appName)
                LabeledContent(preferences.t(.globalHotKey), value: hotkeyDisplayText)
                Text(preferences.t(.menuBarAssistant))
                    .foregroundStyle(.secondary)
            }
            Section(preferences.t(.sectionMenuBarIcon)) {
                Text(preferences.t(.menuBarIconHelp))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section(preferences.t(.sectionLaterP5)) {
                Text(preferences.t(.laterP5Help))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
