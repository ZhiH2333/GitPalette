//
//  TransparentHostingView.swift
//  GitPalette
//
//  透明 NSHostingView：避免圆角外出现系统默认矩形底。
//

import AppKit
import SwiftUI

/// 强制透明的 Hosting 视图（圆角外侧不画遮罩）。
///
/// 使用 `AnyView` 去泛型，并提供显式 `deinit`，规避 Swift 6.3
/// Release（`-O`）下 `EarlyPerfInliner` 对泛型 `NSHostingView` 子类
/// 合成 `deinit` 的编译器崩溃。
final class TransparentHostingView: NSHostingView<AnyView> {
    override var isOpaque: Bool { false }

    required init(rootView: AnyView) {
        super.init(rootView: rootView)
        executeConfigureClearBackground()
    }

    convenience init(rootView: some View) {
        self.init(rootView: AnyView(rootView))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {}

    /// 更新根视图（保持 AnyView 擦除）。
    func executeSetRootView(_ rootView: some View) {
        self.rootView = AnyView(rootView)
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
