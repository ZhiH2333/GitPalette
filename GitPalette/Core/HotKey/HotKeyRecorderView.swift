//
//  HotKeyRecorderView.swift
//  GitPalette
//
//  热键录制控件封装，避免 Settings 直接依赖 KeyboardShortcuts API 细节。
//

import KeyboardShortcuts
import SwiftUI

/// 全局热键录制视图。
struct HotKeyRecorderView: View {
    var onShortcutChanged: () -> Void

    var body: some View {
        KeyboardShortcuts.Recorder(for: .toggleLauncher)
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                onShortcutChanged()
            }
    }
}
