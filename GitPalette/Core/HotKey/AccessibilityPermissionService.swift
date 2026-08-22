//
//  AccessibilityPermissionService.swift
//  GitPalette
//
//  辅助功能权限查询、系统提示、设置跳转与撤销（tccutil）。
//

import ApplicationServices
import AppKit
import Foundation

/// 撤销辅助功能权限的结果。
struct AccessibilityRevokeResult: Sendable {
    /// 是否至少有一条 tccutil 成功
    let didSucceed: Bool
    /// 已尝试重置的 Bundle ID 列表
    let bundleIDs: [String]
    /// 可粘贴的终端命令（失败时供用户手动执行）
    let terminalCommand: String
}

/// 辅助功能权限服务。
@MainActor
final class AccessibilityPermissionService {
    /// TCC 提示选项键（字面量，避免 Swift 6 对全局 CF 常量的并发检查）。
    private static let trustedCheckPromptKey: String = "AXTrustedCheckOptionPrompt"
    /// Release Bundle ID
    static let releaseBundleID: String = "com.zh.GitPalette"
    /// Debug Bundle ID（与 Release 分离，避免 TCC 互相踩踏）
    static let debugBundleID: String = "com.zh.GitPalette.debug"

    /// 当前进程是否已获辅助功能信任。
    var isTrusted: Bool {
        let options: NSDictionary = [Self.trustedCheckPromptKey: false]
        if AXIsProcessTrustedWithOptions(options) {
            return true
        }
        return AXIsProcessTrusted()
    }

    /// 当前运行实例的 Bundle ID。
    var currentBundleID: String {
        Bundle.main.bundleIdentifier ?? Self.releaseBundleID
    }

    /// 当前 `.app` 路径，便于在系统设置中核对勾选的是哪一份。
    var currentBundlePath: String {
        Bundle.main.bundlePath
    }

    /// 弹出系统权限提示，并让本 App 出现在「辅助功能」列表中。
    /// - Returns: 当前是否已授权。
    @discardableResult
    func executePromptIfNeeded() -> Bool {
        if isTrusted {
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

    /// 尝试撤销当前实例授权；失败时打开系统设置供手动关掉开关。
    func executeRevokeAccessibilityAccess() -> AccessibilityRevokeResult {
        let uniqueTargets: [String] = [currentBundleID]
        var didSucceed: Bool = false
        for bundleID in uniqueTargets {
            if executeRunTccutilReset(bundleID: bundleID) {
                didSucceed = true
            }
        }
        if !didSucceed {
            executeOpenAccessibilitySettings()
        }
        let command: String = uniqueTargets
            .map { "tccutil reset Accessibility \($0)" }
            .joined(separator: "\n")
        return AccessibilityRevokeResult(
            didSucceed: didSucceed,
            bundleIDs: uniqueTargets,
            terminalCommand: command
        )
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

    /// 调用 `/usr/bin/tccutil reset Accessibility <bundleID>`。
    private func executeRunTccutilReset(bundleID: String) -> Bool {
        let process: Process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", bundleID]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
