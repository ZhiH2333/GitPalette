//
//  PreferencesStore.swift
//  GitPalette
//
//  应用偏好运行时源：启动器与 Settings 共用同一实例。
//

import Foundation
import Combine

/// 应用偏好存储（ObservableObject + UserDefaults）。
@MainActor
final class PreferencesStore: ObservableObject {
    /// 默认自定义模板
    static let defaultCopyTemplate: String = "{emoji} "
    /// 最近使用数量默认 / 范围
    static let defaultRecentMaxCount: Int = 8
    static let recentMaxCountRange: ClosedRange<Int> = 5...20

    /// 应用显示名称
    let appName: String
    /// 默认热键展示文案
    let defaultHotkeyPlaceholder: String
    /// Gitmoji API 地址占位
    let gitmojiAPIURL: String
    /// 复制格式
    @Published var copyFormat: CopyFormat {
        didSet { executePersistCopyFormat() }
    }
    /// 自定义模板（占位符：{emoji} {code} {name} {description}）
    @Published var copyTemplate: String {
        didSet { executePersistCopyTemplate() }
    }
    /// 最近使用最大条数
    @Published var recentMaxCount: Int {
        didSet { executePersistRecentMaxCount() }
    }
    /// 启动器外观风格
    @Published var appearanceStyle: AppearanceStyle {
        didSet { executePersistAppearanceStyle() }
    }

    init(
        appName: String = "GitPalette",
        defaultHotkeyPlaceholder: String = HotKeyDefaults.displayText,
        gitmojiAPIURL: String = "https://gitmoji.dev/api/gitmojis"
    ) {
        self.appName = appName
        self.defaultHotkeyPlaceholder = defaultHotkeyPlaceholder
        self.gitmojiAPIURL = gitmojiAPIURL
        self.copyFormat = Self.executeLoadCopyFormat()
        self.copyTemplate = Self.executeLoadCopyTemplate()
        self.recentMaxCount = Self.executeLoadRecentMaxCount()
        self.appearanceStyle = Self.executeLoadAppearanceStyle()
    }

    /// 按当前格式生成复制文本。
    func resolveCopyText(for item: Gitmoji) -> String {
        switch copyFormat {
        case .emoji:
            return item.emoji
        case .code:
            return item.code
        case .customTemplate:
            return executeApplyTemplate(copyTemplate, item: item)
        }
    }

    /// 将模板占位符替换为条目字段。
    private func executeApplyTemplate(_ template: String, item: Gitmoji) -> String {
        let trimmed: String = template.isEmpty ? Self.defaultCopyTemplate : template
        return trimmed
            .replacingOccurrences(of: "{emoji}", with: item.emoji)
            .replacingOccurrences(of: "{code}", with: item.code)
            .replacingOccurrences(of: "{name}", with: item.name)
            .replacingOccurrences(of: "{description}", with: item.description)
    }

    private func executePersistCopyFormat() {
        UserDefaults.standard.set(copyFormat.rawValue, forKey: PreferencesKeys.copyFormat)
    }

    private func executePersistCopyTemplate() {
        UserDefaults.standard.set(copyTemplate, forKey: PreferencesKeys.copyTemplate)
    }

    private func executePersistRecentMaxCount() {
        let lower: Int = Self.recentMaxCountRange.lowerBound
        let upper: Int = Self.recentMaxCountRange.upperBound
        let clamped: Int = min(max(recentMaxCount, lower), upper)
        if clamped != recentMaxCount {
            recentMaxCount = clamped
            return
        }
        UserDefaults.standard.set(clamped, forKey: PreferencesKeys.recentMaxCount)
    }

    private func executePersistAppearanceStyle() {
        UserDefaults.standard.set(appearanceStyle.rawValue, forKey: PreferencesKeys.appearanceStyle)
    }

    private static func executeLoadCopyFormat() -> CopyFormat {
        guard let raw: String = UserDefaults.standard.string(forKey: PreferencesKeys.copyFormat) else {
            return .emoji
        }
        if raw == "emojiAndDescription" {
            if UserDefaults.standard.string(forKey: PreferencesKeys.copyTemplate) == nil {
                UserDefaults.standard.set(
                    "{emoji} {description}",
                    forKey: PreferencesKeys.copyTemplate
                )
            }
            UserDefaults.standard.set(
                CopyFormat.customTemplate.rawValue,
                forKey: PreferencesKeys.copyFormat
            )
            return .customTemplate
        }
        return CopyFormat(rawValue: raw) ?? .emoji
    }

    private static func executeLoadCopyTemplate() -> String {
        let stored: String? = UserDefaults.standard.string(forKey: PreferencesKeys.copyTemplate)
        if let stored, !stored.isEmpty {
            return stored
        }
        return defaultCopyTemplate
    }

    private static func executeLoadRecentMaxCount() -> Int {
        let stored: Int = UserDefaults.standard.object(forKey: PreferencesKeys.recentMaxCount) as? Int
            ?? defaultRecentMaxCount
        return min(
            max(stored, recentMaxCountRange.lowerBound),
            recentMaxCountRange.upperBound
        )
    }

    private static func executeLoadAppearanceStyle() -> AppearanceStyle {
        guard let raw: String = UserDefaults.standard.string(forKey: PreferencesKeys.appearanceStyle) else {
            return .automatic
        }
        return AppearanceStyle(rawValue: raw) ?? .automatic
    }
}

/// 历史类型名别名。
typealias AppConfig = PreferencesStore
