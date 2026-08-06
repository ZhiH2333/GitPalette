//
//  LauncherGlassShell.swift
//  GitPalette
//
//  启动器浮层外壳：macOS 26+ 可液态玻璃，其余为毛玻璃。
//  阴影用圆角 fill + blur 叠层，避免 .shadow 在透明 Hosting 下变成硬边方影。
//

import SwiftUI

/// 启动器浮层玻璃外壳修饰器。
struct LauncherGlassShell: ViewModifier {
    let style: AppearanceStyle
    let cornerRadius: CGFloat

    init(
        style: AppearanceStyle,
        cornerRadius: CGFloat = LauncherChrome.cornerRadius
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            buildSoftShadow(shape: shape)
            buildChrome(content: content, shape: shape)
        }
    }

    /// 柔和圆角阴影（远距扩散 + 近距接触影）。
    @ViewBuilder
    private func buildSoftShadow(shape: RoundedRectangle) -> some View {
        shape
            .fill(Color.black.opacity(0.22))
            .blur(radius: LauncherChrome.shadowFarBlur)
            .offset(y: 14)
            .allowsHitTesting(false)
        shape
            .fill(Color.black.opacity(0.14))
            .blur(radius: LauncherChrome.shadowNearBlur)
            .offset(y: 5)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func buildChrome(
        content: Content,
        shape: RoundedRectangle
    ) -> some View {
        switch style.resolved {
        case .liquidGlass:
            buildLiquidGlass(content: content, shape: shape)
        case .material:
            buildMaterial(content: content, shape: shape)
        }
    }

    @ViewBuilder
    private func buildLiquidGlass(
        content: Content,
        shape: RoundedRectangle
    ) -> some View {
        if #available(macOS 26.0, *) {
            content
                .clipShape(shape)
                .glassEffect(.regular, in: shape)
        } else {
            buildMaterial(content: content, shape: shape)
        }
    }

    private func buildMaterial(
        content: Content,
        shape: RoundedRectangle
    ) -> some View {
        content
            .background(.regularMaterial, in: shape)
            .overlay {
                shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
            .clipShape(shape)
    }
}

extension View {
    /// 启动器浮层外壳（按偏好与系统能力切换液态玻璃 / 毛玻璃）。
    func applyLauncherGlassShell(
        style: AppearanceStyle,
        cornerRadius: CGFloat = LauncherChrome.cornerRadius
    ) -> some View {
        modifier(LauncherGlassShell(style: style, cornerRadius: cornerRadius))
    }
}
