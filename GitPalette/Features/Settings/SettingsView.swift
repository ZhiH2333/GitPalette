//
//  SettingsView.swift
//  GitPalette
//
//  设置场景：复制格式等偏好。
//

import SwiftUI

/// 设置窗口内容。
struct SettingsView: View {
    @Bindable var appConfig: AppConfig

    var body: some View {
        Form {
            Section("复制") {
                Picker("复制格式", selection: $appConfig.copyFormat) {
                    Text("emoji").tag(CopyFormat.emoji)
                    Text(":code:").tag(CopyFormat.code)
                }
                .pickerStyle(.segmented)
                Text("当前热键（占位）：\(appConfig.defaultHotkeyPlaceholder)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 180)
        .navigationTitle("设置")
    }
}

#Preview {
    SettingsView(appConfig: AppConfig())
}
