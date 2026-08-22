//
//  LauncherChrome.swift
//  GitPalette
//
//  启动器 Spotlight 风格尺寸与外观常量（液态玻璃 / 毛玻璃共用）。
//

import CoreGraphics

/// 启动器视觉度量（贴近系统 Spotlight）。
enum LauncherChrome {
    /// 外壳圆角（Spotlight / Raycast 级大圆角）
    static let cornerRadius: CGFloat = 28
    /// 内容宽度
    static let contentWidth: CGFloat = 640
    /// 内容高度
    static let contentHeight: CGFloat = 440
    /// Hosting / Panel 外框（阴影由系统窗口绘制，不计入尺寸）
    static let panelWidth: CGFloat = contentWidth
    static let panelHeight: CGFloat = contentHeight
    /// 搜索行高度
    static let searchRowMinHeight: CGFloat = 58
    /// 搜索放大镜字号
    static let searchIconPointSize: CGFloat = 22
    /// 搜索文字字号
    static let searchTextPointSize: CGFloat = 22
    /// 列表选中圆角
    static let rowCornerRadius: CGFloat = 10
    /// 列表水平内边距
    static let listHorizontalPadding: CGFloat = 12
    /// Footer 水平内边距（贴近系统状态栏节奏）
    static let footerHorizontalPadding: CGFloat = 16
    /// Footer 垂直内边距
    static let footerVerticalPadding: CGFloat = 10
    /// Footer 元素间距
    static let footerSpacing: CGFloat = 8
}
