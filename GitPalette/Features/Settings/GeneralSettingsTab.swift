//
//  GeneralSettingsTab.swift
//  GitPalette
//
//  设置 · 通用：外观、复制格式、最近使用。
//

import SwiftUI

/// 通用设置页。
struct GeneralSettingsTab: View {
    @ObservedObject var preferences: PreferencesStore
    var launcherController: LauncherController

    var body: some View {
        Form {
            if AppearanceStyle.isLiquidGlassAvailable {
                Section(preferences.t(.sectionAppearance)) {
                    Picker(preferences.t(.launcherStyle), selection: $preferences.appearanceStyle) {
                        ForEach(AppearanceStyle.allCases) { style in
                            Text(style.displayName(language: preferences.uiLanguage)).tag(style)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
            }
            Section(preferences.t(.sectionCopyFormat)) {
                Picker(preferences.t(.format), selection: $preferences.copyFormat) {
                    ForEach(CopyFormat.allCases) { format in
                        Text(format.displayName(language: preferences.uiLanguage)).tag(format)
                    }
                }
                .pickerStyle(.radioGroup)
                if preferences.copyFormat == .customTemplate {
                    TextField(preferences.t(.template), text: $preferences.copyTemplate)
                    Text(preferences.t(.templatePlaceholders))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(preferences.t(.templatePreviewPrefix) + executePreviewSample())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section(preferences.t(.sectionRecent)) {
                Stepper(
                    value: $preferences.recentMaxCount,
                    in: PreferencesStore.recentMaxCountRange
                ) {
                    Text(preferences.t(.recentKeepCount) + "\(preferences.recentMaxCount)")
                }
                .onChangeCompat(of: preferences.recentMaxCount) { _ in
                    launcherController.executeReloadRecentItems()
                }
                Button(preferences.t(.clearRecent), role: .destructive) {
                    launcherController.executeClearRecentItems()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    /// 用固定样例预览模板效果。
    private func executePreviewSample() -> String {
        let sample = Gitmoji(
            emoji: "✨",
            entity: "✨",
            code: ":sparkles:",
            description: "Introduce new features.",
            name: "sparkles",
            semver: "minor"
        )
        return preferences.resolveCopyText(for: sample)
    }
}
