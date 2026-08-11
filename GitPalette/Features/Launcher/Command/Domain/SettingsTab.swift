//
//  SettingsTab.swift
//  GitPalette
//
//  设置窗口 Tab 标识（供命令直达与 SettingsView 联动）。
//

import Foundation

/// 设置窗口选项卡。
enum SettingsTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case general
    case language
    case hotkey

    var id: String { rawValue }
}
