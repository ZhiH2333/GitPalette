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
                if hotKeyService.isAccessibilityGranted {
                    Label(preferences.t(.accessibilityGranted), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                } else {
                    Label(preferences.t(.accessibilityDenied), systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(preferences.t(.grantAccessibility)) {
                        hotKeyService.executeOpenAccessibilitySettings()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                Button(preferences.t(.revokeAccessibility)) {
                    hotKeyService.executeRevokeAccessibilityAccess()
                }
                Button(preferences.t(.openSystemSettings)) {
                    hotKeyService.executeOpenAccessibilitySettings()
                }
                Button(preferences.t(.recheck)) {
                    hotKeyService.executeRefreshStatus()
                }
                if let feedback: AccessibilityRevokeFeedback = hotKeyService.accessibilityRevokeFeedback {
                    Text(resolveRevokeMessage(feedback))
                        .font(.caption)
                        .foregroundStyle(feedback == .succeeded ? Color.secondary : Color.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            hotKeyService.executeRefreshStatus()
        }
    }

    /// 撤销结果文案。
    private func resolveRevokeMessage(_ feedback: AccessibilityRevokeFeedback) -> String {
        switch feedback {
        case .succeeded:
            return preferences.t(.accessibilityRevokeSucceeded)
        case .failed:
            return preferences.t(.accessibilityRevokeFailed)
        }
    }
}
