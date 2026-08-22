//
//  AppWindowFocus.swift
//  GitPalette
//
//  LSUIElement 应用打开设置 / 关于等窗口时置前并抢焦点。
//

import AppKit
import Foundation

/// 菜单栏 Agent 的窗口前置与激活辅助。
@MainActor
enum AppWindowFocus {
    /// 打开窗口前激活，但保持 accessory，避免出现在 Dock。
    static func executePrepareForWindowPresentation() {
        if NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    /// 按窗口 identifier 前置（比标题子串可靠）。
    static func executeBringToFront(identifier: String) {
        executePrepareForWindowPresentation()
        executeScheduleBringToFront { window in
            window.identifier?.rawValue == identifier
        }
    }

    /// 关闭匹配 identifier 的窗口。
    static func executeCloseWindows(identifier: String) {
        for window in NSApp.windows where window.identifier?.rawValue == identifier {
            window.close()
        }
    }

    /// 将匹配标题的可见窗口置前并成为 key。
    static func executeBringToFront(titleContaining fragments: [String]) {
        executePrepareForWindowPresentation()
        executeScheduleBringToFront { window in
            let title: String = window.title
            return fragments.contains { fragment in
                title.localizedCaseInsensitiveContains(fragment)
            }
        }
    }

    /// 将设置窗口置前（标题因系统语言可能为 Settings / 设置 / 偏好设置）。
    static func executeBringSettingsToFront() {
        executePrepareForWindowPresentation()
        executeScheduleBringToFront { window in
            if resolveIsSettingsWindow(window) {
                return true
            }
            let title: String = window.title
            let tokens: [String] = ["Settings", "设置", "偏好设置", "Preferences"]
            return tokens.contains { title.localizedCaseInsensitiveContains($0) }
        }
    }

    /// 当前视图所属窗口置前（供 onAppear 调用）。
    static func executeFocusHostingWindow(of view: NSView?) {
        executePrepareForWindowPresentation()
        guard let window: NSWindow = view?.window else {
            return
        }
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    /// 若已无普通可见窗口，恢复菜单栏 Agent 的 accessory 策略。
    static func executeRevertToAccessoryIfNeeded() {
        let hasVisibleStandardWindow: Bool = NSApp.windows.contains { window in
            guard window.isVisible, !(window is NSPanel) else {
                return false
            }
            // 排除状态栏 / 菜单相关不可见壳窗。
            if window.frame.width <= 1 || window.frame.height <= 1 {
                return false
            }
            return true
        }
        if !hasVisibleStandardWindow, NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    /// 延迟查找并前置窗口（SwiftUI openWindow / Settings 异步创建）。
    private static func executeScheduleBringToFront(
        matching predicate: @escaping (NSWindow) -> Bool
    ) {
        let delays: [TimeInterval] = [0.05, 0.2]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                executePrepareForWindowPresentation()
                guard let window: NSWindow = NSApp.windows.reversed().first(where: { candidate in
                    (candidate.isVisible || candidate.isMiniaturized) && predicate(candidate)
                }) else {
                    return
                }
                window.deminiaturize(nil)
                window.collectionBehavior.insert(.moveToActiveSpace)
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    /// 启发式识别 Settings 场景窗口。
    private static func resolveIsSettingsWindow(_ window: NSWindow) -> Bool {
        let typeName: String = String(describing: type(of: window))
        if typeName.localizedCaseInsensitiveContains("Settings") {
            return true
        }
        let autosave: String = window.frameAutosaveName
        if autosave.localizedCaseInsensitiveContains("Settings")
            || autosave.localizedCaseInsensitiveContains("Preferences") {
            return true
        }
        return false
    }
}
