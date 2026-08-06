//
//  GitPaletteApp.swift
//  GitPalette
//
//  应用入口：菜单栏 Agent 壳层 + 临时启动器窗口。
//

import SwiftUI

@main
struct GitPaletteApp: App {
    @State private var appConfig: AppConfig = AppConfig()

    var body: some Scene {
        MenuBarExtra {
            LauncherMenuView()
        } label: {
            Label(appConfig.appName, systemImage: "paintpalette.fill")
        }
        Window("启动器", id: "launcher") {
            GitmojiListView(appConfig: appConfig)
        }
        .defaultSize(width: 480, height: 560)
        Settings {
            SettingsView(appConfig: appConfig)
                .applyGlassStylePlaceholder()
        }
    }
}
