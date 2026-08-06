//
//  AppearanceStyle.swift
//  GitPalette
//
//  启动器外观风格：自动 / 液态玻璃 / 毛玻璃。
//

import Foundation

/// 用户可选的外观风格。
enum AppearanceStyle: String, CaseIterable, Identifiable, Sendable {
    /// 按系统版本自动：macOS 26+ 液态玻璃，否则毛玻璃
    case automatic
    /// 液态玻璃（仅 macOS 26+；更低系统回退毛玻璃）
    case liquidGlass
    /// 毛玻璃（ultraThinMaterial）
    case material

    var id: String { rawValue }

    /// 设置展示名。
    var displayName: String {
        switch self {
        case .automatic:
            return "自动"
        case .liquidGlass:
            return "液态玻璃"
        case .material:
            return "毛玻璃"
        }
    }

    /// 当前系统是否支持液态玻璃 API。
    static var isLiquidGlassAvailable: Bool {
        if #available(macOS 26.0, *) {
            return true
        }
        return false
    }

    /// 解析实际渲染风格（考虑系统能力）。
    var resolved: ResolvedAppearanceStyle {
        switch self {
        case .automatic:
            return Self.isLiquidGlassAvailable ? .liquidGlass : .material
        case .liquidGlass:
            return Self.isLiquidGlassAvailable ? .liquidGlass : .material
        case .material:
            return .material
        }
    }
}

/// 实际应用到启动器外壳的风格。
enum ResolvedAppearanceStyle: String, Sendable {
    case liquidGlass
    case material
}
