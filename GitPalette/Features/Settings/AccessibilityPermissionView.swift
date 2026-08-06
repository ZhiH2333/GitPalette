//
//  AccessibilityPermissionView.swift
//  GitPalette
//
//  辅助功能权限引导（中文）。
//

import SwiftUI

/// 辅助功能权限引导视图。
struct AccessibilityPermissionView: View {
    @ObservedObject var hotKeyService: HotKeyService
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("需要辅助功能权限")
                .font(.title2.weight(.semibold))
            Text("全局热键 \(hotKeyService.hotkeyDisplayText) 需要在「系统设置 → 隐私与安全性 → 辅助功能」中允许 GitPalette，才能在其他应用前台时唤起启动器。")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let conflictHint: String = hotKeyService.conflictHint {
                Text(conflictHint)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button("打开系统设置") {
                    hotKeyService.executeOpenAccessibilitySettings()
                }
                .keyboardShortcut(.defaultAction)
                Button("重新检测") {
                    hotKeyService.executeRefreshStatus()
                }
                Spacer()
                if let onDismiss {
                    Button("稍后") {
                        onDismiss()
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            hotKeyService.executeRequestAccessibilityAccess()
            hotKeyService.executeRefreshStatus()
        }
    }
}
