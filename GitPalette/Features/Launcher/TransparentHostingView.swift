//
//  TransparentHostingView.swift
//  GitPalette
//
//  透明 NSHostingView：避免圆角外出现系统默认矩形底。
//

import AppKit
import SwiftUI

/// 强制透明的 Hosting 视图（圆角外侧不画遮罩）。
final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }

    required init(rootView: Content) {
        super.init(rootView: rootView)
        executeConfigureClearBackground()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        executeConfigureClearBackground()
    }

    override func layout() {
        super.layout()
        executeConfigureClearBackground()
    }

    /// 清除默认背景与不透明标记。
    private func executeConfigureClearBackground() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
    }
}
