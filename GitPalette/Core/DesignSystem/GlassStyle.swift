//
//  GlassStyle.swift
//  GitPalette
//
//  通用壳层占位修饰（非启动器浮层）。
//

import SwiftUI

/// 通用壳层占位修饰器。
struct GlassStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    /// 应用通用壳层占位修饰。
    func applyGlassStylePlaceholder() -> some View {
        modifier(GlassStyle())
    }
}
