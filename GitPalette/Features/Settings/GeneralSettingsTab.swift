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
            Section("外观") {
                Picker("启动器风格", selection: $preferences.appearanceStyle) {
                    ForEach(AppearanceStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
                Text(resolveAppearanceHint())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
                .onChangeCompat(of: preferences.recentMaxCount) { _ in
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

    /// 外观选项说明。
    private func resolveAppearanceHint() -> String {
        if AppearanceStyle.isLiquidGlassAvailable {
            return "自动：在 macOS 26 使用液态玻璃，更低系统使用毛玻璃。也可手动固定风格。"
        }
        return "当前系统不支持液态玻璃；选择「液态玻璃」时会回退为毛玻璃。升级到 macOS 26 后可使用液态玻璃。"
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
