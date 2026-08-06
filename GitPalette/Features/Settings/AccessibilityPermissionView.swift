//
//  AccessibilityPermissionView.swift
//  GitPalette
//
//  辅助功能权限引导。
//

import SwiftUI

/// 辅助功能权限引导视图。
struct AccessibilityPermissionView: View {
    @ObservedObject var preferences: PreferencesStore
    @ObservedObject var hotKeyService: HotKeyService
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(preferences.t(.needAccessibilityTitle))
                .font(.title2.weight(.semibold))
            Text(
                preferences.t(.needAccessibilityBody)
                    .replacingOccurrences(of: "GitPalette", with: preferences.appName)
            )
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let conflictHint: String = hotKeyService.conflictHint {
                Text(conflictHint)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button(preferences.t(.grantAccessibility)) {
                    hotKeyService.executeOpenAccessibilitySettings()
                }
                .keyboardShortcut(.defaultAction)
                Button(preferences.t(.recheck)) {
                    hotKeyService.executeRefreshStatus()
                }
                Spacer()
                if let onDismiss {
                    Button(preferences.t(.later)) {
                        onDismiss()
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            hotKeyService.executeRequestAccessibilityAccess()
            hotKeyService.executeRefreshStatus()
        }
    }
}
