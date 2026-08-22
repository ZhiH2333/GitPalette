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
    /// 界面语言
    @Published var uiLanguage: AppLanguage {
        didSet { executePersistUILanguage() }
    }
    /// Code 翻译语言（English 仅 shortcode；简体中文追加译名）
    @Published var codeTranslationLanguage: AppLanguage {
        didSet { executePersistCodeTranslationLanguage() }
    }
    /// 描述语言
    @Published var descriptionLanguage: AppLanguage {
        didSet { executePersistDescriptionLanguage() }
    }
    /// 菜单栏点击行为：下拉菜单 / 直接打开启动器。
    @Published var menuBarClickBehavior: MenuBarClickBehavior {
        didSet { executePersistMenuBarClickBehavior() }
    }

    init(
        appName: String = PreferencesStore.resolveAppDisplayName(),
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
        self.uiLanguage = Self.executeLoadLanguage(key: PreferencesKeys.uiLanguage, fallback: .systemDefault)
        self.codeTranslationLanguage = Self.executeLoadLanguage(
            key: PreferencesKeys.codeTranslationLanguage,
            fallback: .english
        )
        self.descriptionLanguage = Self.executeLoadLanguage(
            key: PreferencesKeys.descriptionLanguage,
            fallback: .systemDefault
        )
        self.menuBarClickBehavior = Self.executeLoadMenuBarClickBehavior()
    }

    /// 按当前格式生成复制文本（code / description 遵循对应语言偏好）。
    func resolveCopyText(for item: Gitmoji) -> String {
        switch copyFormat {
        case .emoji:
            return item.emoji
        case .code:
            return resolveLocalizedCode(for: item)
        case .customTemplate:
            return executeApplyTemplate(copyTemplate, item: item)
        }
    }

    /// 列表 / 复制用的本地化 code。
    func resolveLocalizedCode(for item: Gitmoji) -> String {
        GitmojiLocalization.resolveCodeText(for: item, language: codeTranslationLanguage)
    }

    /// 列表 / 复制用的本地化描述。
    func resolveLocalizedDescription(for item: Gitmoji) -> String {
        GitmojiLocalization.resolveDescriptionText(for: item, language: descriptionLanguage)
    }

    /// 将模板占位符替换为条目字段。
    private func executeApplyTemplate(_ template: String, item: Gitmoji) -> String {
        let trimmed: String = template.isEmpty ? Self.defaultCopyTemplate : template
        return trimmed
            .replacingOccurrences(of: "{emoji}", with: item.emoji)
            .replacingOccurrences(of: "{code}", with: resolveLocalizedCode(for: item))
            .replacingOccurrences(of: "{name}", with: item.name)
            .replacingOccurrences(of: "{description}", with: resolveLocalizedDescription(for: item))
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

    private func executePersistUILanguage() {
        UserDefaults.standard.set(uiLanguage.rawValue, forKey: PreferencesKeys.uiLanguage)
    }

    private func executePersistCodeTranslationLanguage() {
        UserDefaults.standard.set(
            codeTranslationLanguage.rawValue,
            forKey: PreferencesKeys.codeTranslationLanguage
        )
    }

    private func executePersistDescriptionLanguage() {
        UserDefaults.standard.set(
            descriptionLanguage.rawValue,
            forKey: PreferencesKeys.descriptionLanguage
        )
    }

    private func executePersistMenuBarClickBehavior() {
        UserDefaults.standard.set(
            menuBarClickBehavior.rawValue,
            forKey: PreferencesKeys.menuBarClickBehavior
        )
    }

    private static func executeLoadMenuBarClickBehavior() -> MenuBarClickBehavior {
        guard let raw: String = UserDefaults.standard.string(forKey: PreferencesKeys.menuBarClickBehavior) else {
            return .menu
        }
        return MenuBarClickBehavior(rawValue: raw) ?? .menu
    }

    /// 与系统设置辅助功能列表一致的显示名（Debug 为 GitPalette - Debug）。
    static func resolveAppDisplayName() -> String {
        let bundle: Bundle = .main
        if let displayName: String = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !displayName.isEmpty {
            return displayName
        }
        if let bundleName: String = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !bundleName.isEmpty {
            return bundleName
        }
        return "GitPalette"
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

    private static func executeLoadLanguage(key: String, fallback: AppLanguage) -> AppLanguage {
        guard let raw: String = UserDefaults.standard.string(forKey: key) else {
            return fallback
        }
        return AppLanguage(rawValue: raw) ?? fallback
    }
}

/// 历史类型名别名。
typealias AppConfig = PreferencesStore
