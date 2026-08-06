//
//  LauncherPanelContentView.swift
//  GitPalette
//
//  启动器浮动面板 SwiftUI 根视图：玻璃外壳 + 列表内容。
//

import SwiftUI

/// 启动器面板内容根视图。
struct LauncherPanelContentView: View {
    @Bindable var appConfig: AppConfig
    @Bindable var viewModel: GitmojiListViewModel
    let focusToken: UUID
    let onDismiss: () -> Void
    let onConfirmCopy: () -> Void

    var body: some View {
        GitmojiListView(
            appConfig: appConfig,
            viewModel: viewModel,
            focusToken: focusToken,
            onDismiss: onDismiss,
            onConfirmCopy: onConfirmCopy
        )
        .applyLauncherGlassShell()
        .padding(2)
    }
}
