//
//  AccessibilityPermissionService.swift
//  GitPalette
//
//  辅助功能权限查询、系统提示与设置跳转。
//

import ApplicationServices
import AppKit
import Foundation

/// 辅助功能权限服务。
@MainActor
final class AccessibilityPermissionService {
    /// TCC 提示选项键（字面量，避免 Swift 6 对全局 CF 常量的并发检查）。
    private static let trustedCheckPromptKey: String = "AXTrustedCheckOptionPrompt"

    /// 当前进程是否已获辅助功能信任。
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// 弹出系统权限提示，并让本 App 出现在「辅助功能」列表中。
    /// - Returns: 当前是否已授权。
    @discardableResult
    func executePromptIfNeeded() -> Bool {
        if AXIsProcessTrusted() {
            return true
        }
        // 必须用 NSNumber / CFBoolean；纯 Bool 桥接在部分 SDK 下不会触发弹窗与列表注册。
        let options: NSDictionary = [Self.trustedCheckPromptKey: true]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// 先请求权限（注册到系统列表），再打开辅助功能设置页。
    func executeRequestAccessAndOpenSettings() {
        _ = executePromptIfNeeded()
        executeOpenAccessibilitySettings()
    }

    /// 打开「系统设置 → 隐私与安全性 → 辅助功能」。
    func executeOpenAccessibilitySettings() {
        let candidates: [String] = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.Settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
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
