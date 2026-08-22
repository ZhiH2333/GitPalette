//
//  LauncherPanelFactory.swift
//  GitPalette
//
//  创建并配置 Spotlight 风格 NSPanel（AppKit 桥接集中处）。
//

import AppKit

/// 启动器面板工厂。
enum LauncherPanelFactory {
    /// 面板默认尺寸（与 LauncherChrome 对齐）。
    static let panelSize: NSSize = NSSize(
        width: LauncherChrome.panelWidth,
        height: LauncherChrome.panelHeight
    )

    /// 创建 borderless 浮动面板（需成为 key 以支持输入；失焦由 Controller 关闭）。
    static func makePanel() -> LauncherPanel {
        let panel = LauncherPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        // canJoinAllSpaces 与 moveToActiveSpace 互斥；启动器跟当前 Space 即可。
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // 系统阴影按窗口 alpha（圆角透明）绘制，不计入窗口 frame。
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        // 交给系统窗口动画（macOS 26+ 为默认开窗动效）。
        panel.animationBehavior = resolveAnimationBehavior()
        panel.alphaValue = 1
        return panel
    }

    /// 解析系统窗口动画行为：26+ 用文档窗口默认开合；更低系统用 utility 淡入淡出。
    static func resolveAnimationBehavior() -> NSWindow.AnimationBehavior {
        if #available(macOS 26.0, *) {
            return .documentWindow
        }
        return .utilityWindow
    }

    /// 关闭后交还焦点的延迟，避免打断系统关窗动画。
    static func resolveDismissFocusDelay() -> TimeInterval {
        if #available(macOS 26.0, *) {
            return 0.28
        }
        return 0.16
    }

    /// 以系统动画显示面板。
    static func executePresentAnimated(_ panel: NSPanel) {
        panel.animationBehavior = resolveAnimationBehavior()
        panel.alphaValue = 1
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
    }

    /// 以系统动画隐藏面板。
    static func executeDismissAnimated(_ panel: NSPanel) {
        panel.animationBehavior = resolveAnimationBehavior()
        panel.orderOut(nil)
    }

    /// 将面板在鼠标所在屏幕居中（略偏上，贴近 Spotlight）。
    static func executeCenterOnMouseScreen(_ panel: NSPanel) {
        let mouseLocation: NSPoint = NSEvent.mouseLocation
        let screen: NSScreen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens[0]
        let visible: NSRect = screen.visibleFrame
        let size: NSSize = panel.frame.size
        let origin: NSPoint = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2 + 48
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }
}
