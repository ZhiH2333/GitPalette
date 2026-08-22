//
//  AccessibilityPermissionView.swift
//  GitPalette
//
//  辅助功能说明窗口。
//

import AppKit
import SwiftUI

/// 辅助功能说明视图。
struct AccessibilityPermissionView: View {
    @ObservedObject var preferences: PreferencesStore
    @ObservedObject var hotKeyService: HotKeyService
    var onDismiss: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 8) {
                    Text(preferences.t(.needAccessibilityTitle))
                        .font(.title3.weight(.semibold))
                    Text(preferences.t(.needAccessibilityBody))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, 20)
            HStack(spacing: 12) {
                Spacer()
                Button(preferences.t(.later)) {
                    executeDismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button(preferences.t(.openSystemSettings)) {
                    hotKeyService.executeOpenAccessibilitySettings()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private func executeDismiss() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}
