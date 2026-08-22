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
            Section(preferences.t(.menuBarBehavior)) {
                Picker(preferences.t(.menuBarBehavior), selection: $preferences.menuBarClickBehavior) {
                    ForEach(MenuBarClickBehavior.allCases) { behavior in
                        Text(behavior.displayName(language: preferences.uiLanguage)).tag(behavior)
                    }
                }
                .pickerStyle(.radioGroup)
                Text(preferences.t(.menuBarBehaviorHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
                Text(preferences.t(.needAccessibilityBody))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if hotKeyService.isAccessibilityGranted {
                    Label(preferences.t(.accessibilityGranted), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                Button(preferences.t(.openSystemSettings)) {
                    hotKeyService.executeOpenAccessibilitySettings()
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
