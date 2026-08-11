//
//  MenuBarClickBehavior.swift
//  GitPalette
//
//  菜单栏点击行为：下拉菜单 / 直接打开启动器。
//

import Foundation

/// 菜单栏图标点击行为。
enum MenuBarClickBehavior: String, CaseIterable, Identifiable, Sendable {
    /// 点击展开下拉菜单（设置 / 关于 / 退出等入口）
    case menu
    /// 点击直接打开 Spotlight 启动器（设置等通过 / 命令访问）
    case launcher

    var id: String { rawValue }

    /// 跟随 UI 语言的展示名。
    func displayName(language: AppLanguage) -> String {
        switch self {
        case .menu:
            return L10n.text(.menuBarClickMenu, language: language)
        case .launcher:
            return L10n.text(.menuBarClickLauncher, language: language)
        }
    }
}
