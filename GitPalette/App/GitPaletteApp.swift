//
//  GitPaletteApp.swift
//  GitPalette
//
//  应用入口：菜单栏 Agent 壳层 + 启动器浮动面板控制器。
//

import SwiftUI

@main
struct GitPaletteApp: App {
    @State private var appConfig: AppConfig
    @State private var launcherController: LauncherController

    init() {
        let config: AppConfig = AppConfig()
        _appConfig = State(initialValue: config)
        _launcherController = State(initialValue: LauncherController(appConfig: config))
    }

    var body: some Scene {
        MenuBarExtra {
            LauncherMenuView(launcherController: launcherController)
        } label: {
            Label(appConfig.appName, systemImage: "paintpalette.fill")
        }
        Settings {
            SettingsView(appConfig: appConfig)
                .applyGlassStylePlaceholder()
        }
    }
}
