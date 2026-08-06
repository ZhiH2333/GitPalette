//
//  AccessibilityPermissionService.swift
//  GitPalette
//
//  辅助功能权限查询与系统设置跳转。
//

import ApplicationServices
import AppKit
import Foundation

/// 辅助功能权限服务。
@MainActor
final class AccessibilityPermissionService {
    /// 当前进程是否已获辅助功能信任。
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// 弹出系统权限提示（若尚未授权）。
    func executePromptIfNeeded() {
        // 使用字面量键名，避免 Swift 6 对 kAXTrustedCheckOptionPrompt 全局可变状态的并发检查报错。
        let options: CFDictionary = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// 打开「系统设置 → 隐私与安全性 → 辅助功能」。
    func executeOpenAccessibilitySettings() {
        let candidates: [String] = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.Settings.PrivacySecurity.extension?Privacy_Accessibility"
        ]
        for raw in candidates {
            guard let url: URL = URL(string: raw) else {
                continue
            }
            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
