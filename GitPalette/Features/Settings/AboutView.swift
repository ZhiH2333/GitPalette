//
//  AboutView.swift
//  GitPalette
//
//  关于页极简占位。
//

import SwiftUI

/// 关于信息视图。
struct AboutView: View {
    @ObservedObject var preferences: PreferencesStore
    let hotkeyDisplayText: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            Text(preferences.appName)
                .font(.title2.weight(.semibold))
            Text(preferences.t(.menuBarAssistant))
                .foregroundStyle(.secondary)
            Text(preferences.t(.aboutHotKeyLine) + hotkeyDisplayText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 280, height: 200)
    }
}
