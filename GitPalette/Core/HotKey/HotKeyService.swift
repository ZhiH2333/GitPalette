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

/// 全局热键服务。
@MainActor
final class HotKeyService: ObservableObject {
    /// 是否已授予辅助功能权限（仅用于抢焦点，不挡住热键）。
    @Published private(set) var isAccessibilityGranted: Bool = false
    /// 热键与系统快捷键冲突时的提示；无冲突为 nil
    @Published private(set) var conflictHint: String?
    /// 当前热键展示文案
    @Published private(set) var hotkeyDisplayText: String = HotKeyDefaults.displayText
    /// 变化时 UI 应打开权限说明窗（设置 / 命令入口）。
    @Published private(set) var permissionGuideToken: UUID?
    private let accessibilityService: AccessibilityPermissionService
    private var onToggle: (() -> Void)?
    private var didRegisterHandler: Bool = false

    init(accessibilityService: AccessibilityPermissionService = AccessibilityPermissionService()) {
        self.accessibilityService = accessibilityService
        executeRefreshStatus()
    }

    /// 启动热键监听；触发时回调（应接到 LauncherController.toggle）。
    func executeStart(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
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

    /// 打开辅助功能说明（设置或「/permissions」）。
    func executePresentPermissionGuide() {
        executeRefreshStatus()
        permissionGuideToken = UUID()
    }

    /// 打开系统辅助功能设置页。
    func executeOpenAccessibilitySettings() {
        accessibilityService.executeRequestAccessAndOpenSettings()
        executeRefreshStatus()
    }

    /// 冷启动时若当前进程未被信任，弹出简短说明（不挡住热键）。
    private func executePresentGuideIfNeededOnLaunch() {
        guard !isAccessibilityGranted else {
            return
        }
        permissionGuideToken = UUID()
    }

    /// 重置为默认热键 ⌘⇧G。
    func executeResetToDefaultShortcut() {
        KeyboardShortcuts.reset(.toggleLauncher)
        executeRefreshStatus()
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

    /// 热键始终唤起启动器。
    private func executeHandleHotKey() {
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
            let stored: String? = UserDefaults.standard.string(forKey: PreferencesKeys.uiLanguage)
            let language: AppLanguage = stored.flatMap(AppLanguage.init(rawValue:)) ?? .systemDefault
            conflictHint = String(
                format: L10n.text(.hotkeyConflictHint, language: language),
                hotkeyDisplayText
            )
        } else {
            conflictHint = nil
        }
    }
}
