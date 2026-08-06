//
//  SettingsView.swift
//  GitPalette
//
//  设置场景极简：复制格式 + 热键/权限提示（完整表单留给 P4）。
//

import SwiftUI

/// 设置窗口内容。
struct SettingsView: View {
    @Bindable var appConfig: AppConfig
    var hotKeyService: HotKeyService

    var body: some View {
        Form {
            Section("复制") {
                Picker("复制格式", selection: $appConfig.copyFormat) {
                    Text("emoji").tag(CopyFormat.emoji)
                    Text(":code:").tag(CopyFormat.code)
                }
                .pickerStyle(.segmented)
            }
            Section("全局热键") {
                Text("默认热键：\(hotKeyService.hotkeyDisplayText)")
                    .foregroundStyle(.secondary)
                if hotKeyService.isAccessibilityGranted {
                    Text("辅助功能权限：已授予")
                        .foregroundStyle(.green)
                } else {
                    Text("辅助功能权限：未授予（热键在其他 App 中可能无法使用）")
                        .foregroundStyle(.orange)
                    Button("打开系统设置…") {
                        hotKeyService.executeOpenAccessibilitySettings()
                    }
                    Button("重新检测权限") {
                        hotKeyService.executeRefreshStatus()
                    }
                }
                if let conflictHint: String = hotKeyService.conflictHint {
                    Text(conflictHint)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 280)
        .navigationTitle("设置")
        .onAppear {
            hotKeyService.executeRefreshStatus()
        }
    }
}
