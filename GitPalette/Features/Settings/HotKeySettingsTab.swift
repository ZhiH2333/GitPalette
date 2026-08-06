//
//  HotKeySettingsTab.swift
//  GitPalette
//
//  设置 · 快捷键：录制热键与辅助功能状态。
//

import SwiftUI

/// 快捷键设置页。
struct HotKeySettingsTab: View {
    @ObservedObject var preferences: PreferencesStore
    @ObservedObject var hotKeyService: HotKeyService

    var body: some View {
        Form {
            Section(preferences.t(.sectionLauncherHotKey)) {
                HStack {
                    Text(preferences.t(.toggleLauncher))
                    Spacer()
                    HotKeyRecorderView {
                        hotKeyService.executeRefreshStatus()
                    }
                }
                Text(preferences.t(.currentHotKey) + hotKeyService.hotkeyDisplayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(
                    String(
                        format: preferences.t(.resetDefaultHotKey),
                        HotKeyDefaults.displayText
                    )
                ) {
                    hotKeyService.executeResetToDefaultShortcut()
                }
                if let conflictHint: String = hotKeyService.conflictHint {
                    Text(conflictHint)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Section(preferences.t(.sectionAccessibility)) {
                if hotKeyService.isAccessibilityGranted {
                    Text(preferences.t(.accessibilityGranted))
                        .foregroundStyle(.green)
                } else {
                    Text(preferences.t(.accessibilityDenied))
                        .foregroundStyle(.orange)
                    Button(preferences.t(.openSystemSettings)) {
                        hotKeyService.executeOpenAccessibilitySettings()
                    }
                    Button(preferences.t(.recheck)) {
                        hotKeyService.executeRefreshStatus()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            hotKeyService.executeRefreshStatus()
        }
    }
}
