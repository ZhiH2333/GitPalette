//
//  LauncherGlassShell.swift
//  GitPalette
//
//  启动器浮层 Liquid Glass 外壳；列表内容不套玻璃。
//  底层 ultraThinMaterial 作为可读性与降级衬底，上层 glassEffect。
//

import SwiftUI

/// 启动器浮层玻璃外壳修饰器。
struct LauncherGlassShell: ViewModifier {
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 18) {
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.28), radius: 28, y: 12)
    }
}

extension View {
    /// 启动器浮层 Liquid Glass 外壳（玻璃仅包外壳）。
    func applyLauncherGlassShell(cornerRadius: CGFloat = 18) -> some View {
        modifier(LauncherGlassShell(cornerRadius: cornerRadius))
    }
}
