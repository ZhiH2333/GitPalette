//
//  LauncherPanelContentView.swift
//  GitPalette
//
//  启动器浮动面板 SwiftUI 根视图：玻璃外壳 + 列表内容。
//

import SwiftUI

/// 启动器面板内容根视图。
struct LauncherPanelContentView: View {
    @ObservedObject var appConfig: AppConfig
    @ObservedObject var viewModel: GitmojiListViewModel
    @ObservedObject var commandViewModel: LauncherCommandViewModel
    let focusToken: UUID
    let onDismiss: () -> Void
    let onDismissWithoutFocusRestore: () -> Void
    let onConfirmCopy: () -> Void
    let onRequestComplete: (String) -> String?

    var body: some View {
        GitmojiListView(
            appConfig: appConfig,
            viewModel: viewModel,
            commandViewModel: commandViewModel,
            focusToken: focusToken,
            onDismiss: onDismiss,
            onDismissWithoutFocusRestore: onDismissWithoutFocusRestore,
            onConfirmCopy: onConfirmCopy,
            onRequestComplete: onRequestComplete
        )
        .applyLauncherGlassShell(style: appConfig.appearanceStyle)
        .frame(width: LauncherChrome.contentWidth, height: LauncherChrome.contentHeight)
        .background(Color.clear)
    }
}
