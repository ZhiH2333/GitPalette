//
//  GitPaletteApp.swift
//  GitPalette
//
//  应用入口：菜单栏 Agent 壳层（无 Dock 主窗口业务）。
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
        Settings {
            SettingsView()
                .applyGlassStylePlaceholder()
        }
    }
}
