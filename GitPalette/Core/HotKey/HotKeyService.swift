//
//  HotKeyService.swift
//  GitPalette
//
//  全局热键服务：封装 KeyboardShortcuts，不向 View 泄漏第三方 API。
//

import AppKit
import Combine
import Foundation
import KeyboardShortcuts

/// 撤销辅助功能后的 UI 反馈。
enum AccessibilityRevokeFeedback: Equatable, Sendable {
    case succeeded
    case failed
}

/// 全局热键服务。
@MainActor
final class HotKeyService: ObservableObject {
    private static let didShowGuideKey: String = "gitpalette.didShowAccessibilityGuide"

    /// 是否已授予辅助功能权限
    @Published private(set) var isAccessibilityGranted: Bool = false
    /// 热键与系统快捷键冲突时的中文提示；无冲突为 nil
    @Published private(set) var conflictHint: String?
    /// 当前热键展示文案
    @Published private(set) var hotkeyDisplayText: String = HotKeyDefaults.displayText
    /// 变化时 UI 应打开权限引导窗
    @Published private(set) var permissionGuideToken: UUID?
    /// 最近一次撤销操作反馈
    @Published private(set) var accessibilityRevokeFeedback: AccessibilityRevokeFeedback?
    private let accessibilityService: AccessibilityPermissionService
    private var onToggle: (() -> Void)?
    private var didRegisterHandler: Bool = false

    /// 当前 Bundle ID（Debug / Release 不同）。
    var accessibilityBundleID: String {
        accessibilityService.currentBundleID
    }

    init(accessibilityService: AccessibilityPermissionService = AccessibilityPermissionService()) {
        self.accessibilityService = accessibilityService
        executeRefreshStatus()
    }

    /// 启动热键监听；触发时回调（应接到 LauncherController.toggle）。
    func executeStart(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
        executeRefreshStatus()
        executeEnsureHandlerRegistered()
        executeRefreshStatus()
        executePresentGuideIfNeededOnLaunch()
    }

    /// 刷新权限与冲突状态。
    func executeRefreshStatus() {
        isAccessibilityGranted = accessibilityService.isTrusted
        executeUpdateHotkeyDisplayText()
        executeUpdateConflictHint()
    }

    /// 主动打开权限引导（菜单入口）。
    func executePresentPermissionGuide() {
        executeRefreshStatus()
        permissionGuideToken = UUID()
    }

    /// 请求辅助功能授权提示。
    func executeRequestAccessibilityAccess() {
        accessibilityService.executePromptIfNeeded()
        executeRefreshStatus()
    }

    /// 请求权限并打开系统辅助功能设置页。
    func executeOpenAccessibilitySettings() {
        accessibilityService.executeRequestAccessAndOpenSettings()
        executeRefreshStatus()
    }

    /// 撤销辅助功能授权（清 Debug + Release TCC），并提示重启后重新授权。
    func executeRevokeAccessibilityAccess() {
        let result: AccessibilityRevokeResult = accessibilityService.executeRevokeAccessibilityAccess()
        UserDefaults.standard.set(false, forKey: Self.didShowGuideKey)
        executeRefreshStatus()
        accessibilityRevokeFeedback = result.didSucceed ? .succeeded : .failed
    }

    /// 清除撤销结果提示。
    func executeClearAccessibilityRevokeFeedback() {
        accessibilityRevokeFeedback = nil
    }

    /// 重置为默认热键 ⌘⇧G。
    func executeResetToDefaultShortcut() {
        KeyboardShortcuts.reset(.toggleLauncher)
        executeRefreshStatus()
    }

    /// 首次启动且无权限时弹出引导（不静默失败）。
    private func executePresentGuideIfNeededOnLaunch() {
        guard !isAccessibilityGranted else {
            return
        }
        guard !UserDefaults.standard.bool(forKey: Self.didShowGuideKey) else {
            return
        }
        UserDefaults.standard.set(true, forKey: Self.didShowGuideKey)
        permissionGuideToken = UUID()
    }

    /// 注册 onKeyUp 处理器（只注册一次）。
    private func executeEnsureHandlerRegistered() {
        guard !didRegisterHandler else {
            return
        }
        didRegisterHandler = true
        KeyboardShortcuts.onKeyUp(for: .toggleLauncher) { [weak self] in
            Task { @MainActor in
                self?.executeHandleHotKey()
            }
        }
    }

    /// 热键触发：无权限则弹出引导；有权限则 toggle。
    private func executeHandleHotKey() {
        executeRefreshStatus()
        guard isAccessibilityGranted else {
            permissionGuideToken = UUID()
            return
        }
        onToggle?()
    }

    /// 更新展示文案。
    private func executeUpdateHotkeyDisplayText() {
        if let shortcut: KeyboardShortcuts.Shortcut = KeyboardShortcuts.getShortcut(for: .toggleLauncher) {
            hotkeyDisplayText = shortcut.description
        } else {
            hotkeyDisplayText = HotKeyDefaults.displayText
        }
    }

    /// 检测与系统快捷键冲突。
    private func executeUpdateConflictHint() {
        guard let shortcut: KeyboardShortcuts.Shortcut = KeyboardShortcuts.getShortcut(for: .toggleLauncher) else {
            conflictHint = nil
            return
        }
        if shortcut.isTakenBySystem {
            conflictHint = "当前热键 \(hotkeyDisplayText) 可能与系统快捷键冲突。请到「系统设置 → 键盘 → 键盘快捷键」中调整，或于后续版本更改 GitPalette 热键。"
        } else {
            conflictHint = nil
        }
    }
}
