//
//  AboutView.swift
//  GitPalette
//
//  关于窗口：图标、版本与版权信息。
//

import AppKit
import SwiftUI

/// 关于信息视图。
struct AboutView: View {
    @ObservedObject var preferences: PreferencesStore

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)
            Text(preferences.appName)
                .font(.title2.weight(.semibold))
            Text(preferences.t(.menuBarAssistant))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(resolveVersionLine())
                .font(.caption)
                .foregroundStyle(.secondary)
            if let copyright: String = resolveCopyrightLine() {
                Text(copyright)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            Text(preferences.t(.aboutMenuBarNote))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(width: 320)
    }

    /// 从 Bundle 组装版本行。
    private func resolveVersionLine() -> String {
        let shortVersion: String = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
        let buildVersion: String = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"
        return String(
            format: preferences.t(.versionFormat),
            shortVersion,
            buildVersion
        )
    }

    /// 从 Bundle 读取可读版权；空则返回 nil。
    private func resolveCopyrightLine() -> String? {
        let copyright: String? = Bundle.main.object(
            forInfoDictionaryKey: "NSHumanReadableCopyright"
        ) as? String
        guard let copyright, !copyright.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return copyright
    }
}
