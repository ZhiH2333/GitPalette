//
//  L10n.swift
//  GitPalette
//
//  界面文案英 / 简体中文本地化。
//

import Foundation

/// 界面文案键。
enum L10nKey: String, Sendable {
    case tabGeneral
    case tabHotKey
    case tabLanguage
    case sectionAppearance
    case launcherStyle
    case appearanceHintLiquidAvailable
    case appearanceHintLiquidUnavailable
    case sectionCopyFormat
    case format
    case template
    case templatePlaceholders
    case templatePreviewPrefix
    case sectionRecent
    case recentKeepCount
    case clearRecent
    case sectionUILanguage
    case sectionCodeTranslation
    case sectionDescriptionLanguage
    case uiLanguage
    case codeTranslationLanguage
    case descriptionLanguage
    case languageHintUI
    case languageHintCode
    case languageHintDescription
    case sectionLauncherHotKey
    case toggleLauncher
    case currentHotKey
    case resetDefaultHotKey
    case sectionAccessibility
    case accessibilityGranted
    case accessibilityDenied
    case openSystemSettings
    case recheck
    case menuBarAssistant
    case aboutMenuBarNote
    case versionFormat
    case openLauncher
    case grantAccessibility
    case copyFormatMenu
    case settings
    case about
    case quit
    case searchPlaceholder
    case recentUsed
    case noGitmojiData
    case noMatch
    case noData
    case noResult
    case recentCount
    case itemCount
    case copied
    case hintWithRecent
    case hintListOnly
    case clear
    case needAccessibilityTitle
    case needAccessibilityBody
    case later
    case styleAutomatic
    case styleLiquidGlass
    case styleMaterial
    case formatEmoji
    case formatCode
    case formatCustomTemplate
}

/// 界面文案表。
enum L10n {
    /// 按界面语言取文案。
    static func text(_ key: L10nKey, language: AppLanguage) -> String {
        switch language {
        case .english:
            return english[key] ?? key.rawValue
        case .simplifiedChinese:
            return simplifiedChinese[key] ?? english[key] ?? key.rawValue
        }
    }

    private static let english: [L10nKey: String] = [
        .tabGeneral: "General",
        .tabHotKey: "Hotkey",
        .tabLanguage: "Language",
        .sectionAppearance: "Appearance",
        .launcherStyle: "Launcher style",
        .appearanceHintLiquidAvailable: "Automatic uses Liquid Glass on macOS 26 and frosted glass on older systems. You can also lock a style.",
        .appearanceHintLiquidUnavailable: "This system does not support Liquid Glass; choosing it falls back to frosted glass. Upgrade to macOS 26 for Liquid Glass.",
        .sectionCopyFormat: "Copy format",
        .format: "Format",
        .template: "Template",
        .templatePlaceholders: "Placeholders: {emoji} {code} {name} {description}",
        .templatePreviewPrefix: "Preview: ✨ / :sparkles: → ",
        .sectionRecent: "Recent",
        .recentKeepCount: "Keep count: ",
        .clearRecent: "Clear recent",
        .sectionUILanguage: "Interface language",
        .sectionCodeTranslation: "Code translation",
        .sectionDescriptionLanguage: "Description language",
        .uiLanguage: "Interface",
        .codeTranslationLanguage: "Code",
        .descriptionLanguage: "Description",
        .languageHintUI: "Controls menus, settings, and launcher chrome text.",
        .languageHintCode: "English keeps :bug:. 简体中文 shows :bug: 缺陷 in the list and when copying code.",
        .languageHintDescription: "Controls the subtitle under each code, e.g. “Fix a bug.” → “修复一个 Bug.”",
        .sectionLauncherHotKey: "Launcher hotkey",
        .toggleLauncher: "Show / hide launcher",
        .currentHotKey: "Current: ",
        .resetDefaultHotKey: "Reset to default (%@)",
        .sectionAccessibility: "Accessibility",
        .accessibilityGranted: "Granted",
        .accessibilityDenied: "Not granted: the global hotkey may not work when another app is frontmost",
        .openSystemSettings: "Open System Settings…",
        .recheck: "Recheck",
        .menuBarAssistant: "Menu bar Gitmoji assistant",
        .aboutMenuBarNote: "Runs in the menu bar and does not appear in the Dock. Look for the palette icon on the right side of the menu bar.",
        .versionFormat: "Version %@ (%@)",
        .openLauncher: "Open Launcher",
        .grantAccessibility: "Grant Accessibility…",
        .copyFormatMenu: "Copy format",
        .settings: "Settings…",
        .about: "About ",
        .quit: "Quit ",
        .searchPlaceholder: "Search Gitmoji",
        .recentUsed: "Recent",
        .noGitmojiData: "No Gitmoji data",
        .noMatch: "No matching Gitmoji",
        .noData: "No data",
        .noResult: "No results",
        .recentCount: "Recent ",
        .itemCount: " items",
        .copied: "Copied",
        .hintWithRecent: "↑↓←→ select · ⏎ copy",
        .hintListOnly: "↑↓ select · ⏎ copy",
        .clear: "Clear",
        .needAccessibilityTitle: "Accessibility required",
        .needAccessibilityBody: "The global hotkey needs GitPalette allowed in System Settings → Privacy & Security → Accessibility so it can open the launcher while other apps are frontmost.",
        .later: "Later",
        .styleAutomatic: "Automatic",
        .styleLiquidGlass: "Liquid Glass",
        .styleMaterial: "Frosted glass",
        .formatEmoji: "emoji",
        .formatCode: ":code:",
        .formatCustomTemplate: "Custom template"
    ]

    private static let simplifiedChinese: [L10nKey: String] = [
        .tabGeneral: "通用",
        .tabHotKey: "快捷键",
        .tabLanguage: "语言",
        .sectionAppearance: "外观",
        .launcherStyle: "启动器风格",
        .appearanceHintLiquidAvailable: "自动：在 macOS 26 使用液态玻璃，更低系统使用毛玻璃。也可手动固定风格。",
        .appearanceHintLiquidUnavailable: "当前系统不支持液态玻璃；选择「液态玻璃」时会回退为毛玻璃。升级到 macOS 26 后可使用液态玻璃。",
        .sectionCopyFormat: "复制格式",
        .format: "格式",
        .template: "模板",
        .templatePlaceholders: "可用占位符：{emoji} {code} {name} {description}",
        .templatePreviewPrefix: "预览示例：✨ / :sparkles: → ",
        .sectionRecent: "最近使用",
        .recentKeepCount: "保留数量：",
        .clearRecent: "清空最近使用",
        .sectionUILanguage: "界面语言",
        .sectionCodeTranslation: "Code 翻译",
        .sectionDescriptionLanguage: "描述语言",
        .uiLanguage: "界面",
        .codeTranslationLanguage: "Code",
        .descriptionLanguage: "描述",
        .languageHintUI: "控制菜单、设置与启动器界面文案。",
        .languageHintCode: "English 保持 :bug:；简体中文在列表与复制 code 时显示为 :bug: 缺陷。",
        .languageHintDescription: "控制每条 code 下方描述，例如 “Fix a bug.” → “修复一个 Bug。”",
        .sectionLauncherHotKey: "启动器热键",
        .toggleLauncher: "唤起 / 关闭启动器",
        .currentHotKey: "当前：",
        .resetDefaultHotKey: "恢复默认（%@）",
        .sectionAccessibility: "辅助功能权限",
        .accessibilityGranted: "已授予",
        .accessibilityDenied: "未授予：其他 App 前台时全局热键可能无法使用",
        .openSystemSettings: "打开系统设置…",
        .recheck: "重新检测",
        .menuBarAssistant: "菜单栏 Gitmoji 助手",
        .aboutMenuBarNote: "本应用运行在菜单栏，不会出现在 Dock。请在菜单栏右侧查找调色板图标。",
        .versionFormat: "版本 %@ (%@)",
        .openLauncher: "打开启动器",
        .grantAccessibility: "授予辅助功能权限…",
        .copyFormatMenu: "复制格式",
        .settings: "设置…",
        .about: "关于 ",
        .quit: "退出 ",
        .searchPlaceholder: "搜索 Gitmoji",
        .recentUsed: "最近使用",
        .noGitmojiData: "暂无 Gitmoji 数据",
        .noMatch: "未找到匹配的 Gitmoji",
        .noData: "无数据",
        .noResult: "无结果",
        .recentCount: "最近 ",
        .itemCount: " 项",
        .copied: "已复制",
        .hintWithRecent: "↑↓←→ 选择 · ⏎ 复制",
        .hintListOnly: "↑↓ 选择 · ⏎ 复制",
        .clear: "清除",
        .needAccessibilityTitle: "需要辅助功能权限",
        .needAccessibilityBody: "全局热键需要在「系统设置 → 隐私与安全性 → 辅助功能」中允许 GitPalette，才能在其他应用前台时唤起启动器。",
        .later: "稍后",
        .styleAutomatic: "自动",
        .styleLiquidGlass: "液态玻璃",
        .styleMaterial: "毛玻璃",
        .formatEmoji: "emoji",
        .formatCode: ":code:",
        .formatCustomTemplate: "自定义模板"
    ]
}

extension PreferencesStore {
    /// 按当前界面语言取文案。
    func t(_ key: L10nKey) -> String {
        L10n.text(key, language: uiLanguage)
    }
}
