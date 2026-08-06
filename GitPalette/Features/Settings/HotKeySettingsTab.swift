//
//  HotKeySettingsTab.swift
//  GitPalette
//
//  设置 · 快捷键：录制热键与辅助功能状态。
//

import SwiftUI

/// 快捷键设置页。
struct HotKeySettingsTab: View {
    var hotKeyService: HotKeyService

    var body: some View {
        Form {
            Section("启动器热键") {
                HStack {
                    Text("唤起 / 关闭启动器")
                    Spacer()
                    HotKeyRecorderView {
                        hotKeyService.executeRefreshStatus()
                    }
                }
                Text("当前：\(hotKeyService.hotkeyDisplayText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("恢复默认（\(HotKeyDefaults.displayText)）") {
                    hotKeyService.executeResetToDefaultShortcut()
                }
                if let conflictHint: String = hotKeyService.conflictHint {
                    Text(conflictHint)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Section("辅助功能权限") {
                if hotKeyService.isAccessibilityGranted {
                    Text("已授予")
                        .foregroundStyle(.green)
                } else {
                    Text("未授予：其他 App 前台时全局热键可能无法使用")
                        .foregroundStyle(.orange)
                    Button("打开系统设置…") {
                        hotKeyService.executeOpenAccessibilitySettings()
                    }
                    Button("重新检测") {
                        hotKeyService.executeRefreshStatus()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            hotKeyService.executeRefreshStatus()
        }
    }
}
