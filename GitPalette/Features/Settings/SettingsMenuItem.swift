//
//  SettingsMenuItem.swift
//  GitPalette
//
//  设置菜单入口：macOS 14+ 使用 openSettings；13 回退旧 Selector。
//

import AppKit
import SwiftUI

/// 菜单栏「设置…」项。
struct SettingsMenuItem: View {
    var body: some View {
        if #available(macOS 14.0, *) {
            SettingsOpenButtonModern()
        } else {
            Button("设置…") {
                SettingsWindowOpener.executeOpenLegacy()
            }
        }
    }
}

/// macOS 14+：通过 Environment.openSettings 打开 Settings 场景。
@available(macOS 14.0, *)
private struct SettingsOpenButtonModern: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("设置…") {
            AppWindowFocus.executePrepareForWindowPresentation()
            openSettings()
            AppWindowFocus.executeBringSettingsToFront()
        }
    }
}

/// 仅 macOS 13 可用的偏好窗口打开方式。
enum SettingsWindowOpener {
    @MainActor
    static func executeOpenLegacy() {
        AppWindowFocus.executePrepareForWindowPresentation()
        if NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil) == false {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        AppWindowFocus.executeBringSettingsToFront()
    }
}
