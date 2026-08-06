//
//  GlassStyle.swift
//  GitPalette
//
//  Liquid Glass 设计系统占位：仅壳层预留，勿整页滥用 glassEffect。
//

import SwiftUI

/// Liquid Glass 壳层占位修饰器。
/// 面向 macOS 26 Tahoe；真正启用 `glassEffect` 时仅用于菜单/设置等壳层容器。
struct GlassStyle: ViewModifier {
    func body(content: Content) -> some View {
        // 预留：后续可改为 content.glassEffect(...)，勿对整页内容滥用。
        content
    }
}

extension View {
    /// 应用 Liquid Glass 壳层占位修饰（当前为透传）。
    func applyGlassStylePlaceholder() -> some View {
        modifier(GlassStyle())
    }
}
