//
//  LauncherPanelFactory.swift
//  GitPalette
//
//  创建并配置 Spotlight 风格 NSPanel（AppKit 桥接集中处）。
//

import AppKit

/// 启动器面板工厂。
enum LauncherPanelFactory {
    /// 面板默认尺寸。
    static let panelSize: NSSize = NSSize(width: 568, height: 428)

    /// 创建 borderless 浮动面板（需成为 key 以支持输入；失焦由 Controller 关闭）。
    static func makePanel() -> NSPanel {
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
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        return panel
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
