//
//  GeneralSettingsTab.swift
//  GitPalette
//
//  设置 · 通用：复制格式、最近使用。
//

import SwiftUI

/// 通用设置页。
struct GeneralSettingsTab: View {
    @Bindable var preferences: PreferencesStore
    var launcherController: LauncherController

    var body: some View {
        Form {
            Section("复制格式") {
                Picker("格式", selection: $preferences.copyFormat) {
                    ForEach(CopyFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.radioGroup)
                if preferences.copyFormat == .customTemplate {
                    TextField("模板", text: $preferences.copyTemplate)
                    Text("可用占位符：{emoji} {code} {name} {description}")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("预览示例：✨ / :sparkles: → \(executePreviewSample())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section("最近使用") {
                Stepper(
                    value: $preferences.recentMaxCount,
                    in: PreferencesStore.recentMaxCountRange
                ) {
                    Text("保留数量：\(preferences.recentMaxCount)")
                }
                .onChange(of: preferences.recentMaxCount) { _, _ in
                    launcherController.executeReloadRecentItems()
                }
                Button("清空最近使用", role: .destructive) {
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
