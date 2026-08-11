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
    case tabCommands
    case sectionAppearance
    case launcherStyle
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
    case revokeAccessibility
    case accessibilityRevokeSucceeded
    case accessibilityRevokeFailed
    case openSystemSettings
    case recheck
    case menuBarAssistant
    case aboutMenuBarNote
    case aboutGitHub
    case aboutReportIssue
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
    case menuBarBehavior
    case menuBarClickMenu
    case menuBarClickLauncher
    case menuBarBehaviorHint
    case hintWithRecent
    case hintListOnly
    case commandMode
    case suggestionCount
    case commandHint
    case commandSearchPlaceholder
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
    // 「/」命令提示（跟随 descriptionLanguage）
    case cmdSummarySettings
    case cmdSummaryGeneral
    case cmdSummaryHotkey
    case cmdSummaryAbout
    case cmdSummaryPermissions
    case cmdSummaryLanguage
    case cmdSummaryCodelang
    case cmdSummaryDesclang
    case cmdSummaryStyle
    case cmdSummaryFormat
    case cmdSummaryTemplate
    case cmdSummaryRecent
    case cmdSummaryQuit
    case cmdSummaryHide
    case cmdSummaryHelp
    case cmdArgSettingsGeneral
    case cmdArgSettingsLanguage
    case cmdArgSettingsHotkey
    case cmdArgSettingsCommands
    case cmdArgLangEnglish
    case cmdArgLangChinese
    case cmdArgStyleAuto
    case cmdArgStyleLiquid
    case cmdArgStyleMaterial
    case cmdArgFormatEmoji
    case cmdArgFormatCode
    case cmdArgFormatTemplate
    case cmdArgTemplateHint
    case cmdArgRecentClear
    case cmdArgRecentCount
    case cmdNoMatch
    case cmdRejectsArguments
    case cmdUnsupportedSettingsTab
    case cmdNeedLanguage
    case cmdUnsupportedLanguage
    case cmdNeedStyle
    case cmdUnsupportedStyle
    case cmdNeedFormat
    case cmdUnsupportedFormat
    case cmdNeedTemplate
    case cmdNeedRecentSubcommand
    case cmdClearNoExtraArgs
    case cmdNeedCountValue
    case cmdCountMustBeInteger
    case cmdSummaryMenubar
    case cmdArgMenubarMenu
    case cmdArgMenubarLauncher
    case cmdUnsupportedMenubarArg
    case cmdUnsupportedSubcommand
    case cmdUnknownCommand
    case cmdIncompleteArguments
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
        .tabCommands: "Commands",
        .sectionAppearance: "Appearance",
        .launcherStyle: "Launcher style",
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
        .languageHintCode: "Controls code text in the list and when copying.",
        .languageHintDescription: "Controls the description text under each code, and slash-command hint text.",
        .sectionLauncherHotKey: "Launcher hotkey",
        .toggleLauncher: "Show / hide launcher",
        .currentHotKey: "Current: ",
        .resetDefaultHotKey: "Reset to default (%@)",
        .sectionAccessibility: "Accessibility",
        .accessibilityGranted: "Granted",
        .accessibilityDenied: "Not granted: the global hotkey may not work when another app is frontmost",
        .revokeAccessibility: "Revoke Accessibility…",
        .accessibilityRevokeSucceeded: "Accessibility permission cleared. Quit and reopen the app, then grant Accessibility again.",
        .accessibilityRevokeFailed: "Could not clear automatically. Terminal commands were copied — paste them in Terminal, then quit and reopen the app to grant Accessibility again.",
        .openSystemSettings: "Open System Settings…",
        .recheck: "Recheck",
        .menuBarAssistant: "Menu bar Gitmoji assistant",
        .aboutMenuBarNote: "Runs in the menu bar and does not appear in the Dock. Look for the palette icon on the right side of the menu bar.",
        .aboutGitHub: "GitHub Repository",
        .aboutReportIssue: "Report an Issue…",
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
        .menuBarBehavior: "Menu bar click behavior",
        .menuBarClickMenu: "Menu",
        .menuBarClickLauncher: "Open Launcher",
        .menuBarBehaviorHint: "\"Menu\" shows a dropdown with settings and other entries. \"Open Launcher\" opens the Spotlight-style search panel directly; use /settings, /about etc. to access other features.",
        .hintWithRecent: "↑↓←→ select · ⏎ copy",
        .hintListOnly: "↑↓ select · ⏎ copy",
        .commandMode: "Command mode",
        .suggestionCount: " suggestions",
        .commandHint: "Tab / → complete · ↑↓ select · ⏎ run",
        .commandSearchPlaceholder: "Type a command, Tab / → to complete…",
        .clear: "Clear",
        .needAccessibilityTitle: "Accessibility required",
        .needAccessibilityBody: "The global hotkey needs GitPalette allowed in System Settings → Privacy & Security → Accessibility so it can open the launcher while other apps are frontmost.",
        .later: "Later",
        .styleAutomatic: "Automatic",
        .styleLiquidGlass: "Liquid Glass",
        .styleMaterial: "Frosted glass",
        .formatEmoji: "emoji",
        .formatCode: ":code:",
        .formatCustomTemplate: "Custom template",
        .cmdSummarySettings: "Open Settings (optional: general / language / hotkey / commands)",
        .cmdSummaryGeneral: "Open Settings · General",
        .cmdSummaryHotkey: "Open Settings · Hotkey",
        .cmdSummaryAbout: "Open About window",
        .cmdSummaryPermissions: "Open Accessibility permission guide",
        .cmdSummaryLanguage: "Set interface language (english / chinese)",
        .cmdSummaryCodelang: "Set Code translation language (english / chinese)",
        .cmdSummaryDesclang: "Set description language (english / chinese)",
        .cmdSummaryStyle: "Set appearance (auto / liquid / material)",
        .cmdSummaryFormat: "Set copy format (emoji / code / template)",
        .cmdSummaryTemplate: "Set custom copy template",
        .cmdSummaryRecent: "Recent: clear or count <5…20>",
        .cmdSummaryQuit: "Quit the app",
        .cmdSummaryHide: "Close the launcher",
        .cmdSummaryMenubar: "Set menu bar click behavior (menu / launcher)",
        .cmdArgMenubarMenu: "Dropdown menu with entries for settings, about, quit",
        .cmdArgMenubarLauncher: "Open launcher directly; settings via /settings etc.",
        .cmdUnsupportedMenubarArg: "Use menu or launcher",
        .cmdSummaryHelp: "Open all commands reference",
        .cmdArgSettingsGeneral: "General settings",
        .cmdArgSettingsLanguage: "Language settings",
        .cmdArgSettingsHotkey: "Hotkey settings",
        .cmdArgSettingsCommands: "All commands reference",
        .cmdArgLangEnglish: "English",
        .cmdArgLangChinese: "Simplified Chinese (zh)",
        .cmdArgStyleAuto: "Automatic",
        .cmdArgStyleLiquid: "Liquid Glass (glass)",
        .cmdArgStyleMaterial: "Frosted glass",
        .cmdArgFormatEmoji: "Emoji only",
        .cmdArgFormatCode: "Shortcode only",
        .cmdArgFormatTemplate: "Custom template",
        .cmdArgTemplateHint: "Example template (editable)",
        .cmdArgRecentClear: "Clear recent items",
        .cmdArgRecentCount: "Set keep count (5…20)",
        .cmdNoMatch: "No matching command",
        .cmdRejectsArguments: "This command does not accept arguments",
        .cmdUnsupportedSettingsTab: "Unsupported settings tab",
        .cmdNeedLanguage: "Please specify a language",
        .cmdUnsupportedLanguage: "Unsupported language",
        .cmdNeedStyle: "Please specify an appearance style",
        .cmdUnsupportedStyle: "Unsupported appearance style",
        .cmdNeedFormat: "Please specify a copy format",
        .cmdUnsupportedFormat: "Unsupported copy format",
        .cmdNeedTemplate: "Please enter template content",
        .cmdNeedRecentSubcommand: "Specify subcommand clear or count",
        .cmdClearNoExtraArgs: "clear does not take extra arguments",
        .cmdNeedCountValue: "Specify a count, e.g. count 8",
        .cmdCountMustBeInteger: "Count must be an integer",
        .cmdUnsupportedSubcommand: "Unsupported subcommand",
        .cmdUnknownCommand: "No matching command found",
        .cmdIncompleteArguments: "Command arguments are incomplete"
    ]

    private static let simplifiedChinese: [L10nKey: String] = [
        .tabGeneral: "通用",
        .tabHotKey: "快捷键",
        .tabLanguage: "语言",
        .tabCommands: "全部指令",
        .sectionAppearance: "外观",
        .launcherStyle: "启动器风格",
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
        .languageHintCode: "控制列表与复制时的 code 文案。",
        .languageHintDescription: "控制每条 code 下方的描述文案，以及「/」命令的提示文案。",
        .sectionLauncherHotKey: "启动器热键",
        .toggleLauncher: "唤起 / 关闭启动器",
        .currentHotKey: "当前：",
        .resetDefaultHotKey: "恢复默认（%@）",
        .sectionAccessibility: "辅助功能权限",
        .accessibilityGranted: "已授予",
        .accessibilityDenied: "未授予：其他 App 前台时全局热键可能无法使用",
        .revokeAccessibility: "撤销辅助功能权限…",
        .accessibilityRevokeSucceeded: "已清除辅助功能授权。请退出并重新打开应用，再重新授予辅助功能权限。",
        .accessibilityRevokeFailed: "无法自动清除。已复制终端命令到剪贴板，请先在「终端」执行，然后退出并重新打开应用，再重新授权。",
        .openSystemSettings: "打开系统设置…",
        .recheck: "重新检测",
        .menuBarAssistant: "菜单栏 Gitmoji 助手",
        .aboutMenuBarNote: "本应用运行在菜单栏，不会出现在 Dock。请在菜单栏右侧查找调色板图标。",
        .aboutGitHub: "GitHub 仓库",
        .aboutReportIssue: "反馈 Issue…",
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
        .menuBarBehavior: "菜单栏点击行为",
        .menuBarClickMenu: "菜单",
        .menuBarClickLauncher: "打开启动器",
        .menuBarBehaviorHint: "「菜单」点击展开下拉菜单，含设置等入口。「打开启动器」直接打开 Spotlight 搜索面板，通过 /settings、/about 等命令访问其它功能。",
        .hintWithRecent: "↑↓←→ 选择 · ⏎ 复制",
        .hintListOnly: "↑↓ 选择 · ⏎ 复制",
        .commandMode: "命令模式",
        .suggestionCount: " 条建议",
        .commandHint: "Tab / → 补全 · ↑↓ 选择 · ⏎ 执行",
        .commandSearchPlaceholder: "输入命令，Tab / → 补全…",
        .clear: "清除",
        .needAccessibilityTitle: "需要辅助功能权限",
        .needAccessibilityBody: "全局热键需要在「系统设置 → 隐私与安全性 → 辅助功能」中允许 GitPalette，才能在其他应用前台时唤起启动器。",
        .later: "稍后",
        .styleAutomatic: "自动",
        .styleLiquidGlass: "液态玻璃",
        .styleMaterial: "毛玻璃",
        .formatEmoji: "emoji",
        .formatCode: ":code:",
        .formatCustomTemplate: "自定义模板",
        .cmdSummarySettings: "打开设置（可选 general / language / hotkey / commands）",
        .cmdSummaryGeneral: "打开设置 · 通用",
        .cmdSummaryHotkey: "打开设置 · 快捷键",
        .cmdSummaryAbout: "打开关于窗口",
        .cmdSummaryPermissions: "打开辅助功能权限引导",
        .cmdSummaryLanguage: "设置界面语言（english / chinese）",
        .cmdSummaryCodelang: "设置 Code 翻译语言（english / chinese）",
        .cmdSummaryDesclang: "设置描述语言（english / chinese）",
        .cmdSummaryStyle: "设置外观（auto / liquid / material）",
        .cmdSummaryFormat: "设置复制格式（emoji / code / template）",
        .cmdSummaryTemplate: "设置自定义复制模板内容",
        .cmdSummaryRecent: "最近使用：clear 或 count <5…20>",
        .cmdSummaryQuit: "退出应用",
        .cmdSummaryHide: "关闭启动器面板",
        .cmdSummaryMenubar: "设置菜单栏点击行为（菜单 / 打开启动器）",
        .cmdArgMenubarMenu: "下拉菜单，含设置、关于、退出等入口",
        .cmdArgMenubarLauncher: "直接打开启动器；设置等功能通过 /settings 等命令访问",
        .cmdUnsupportedMenubarArg: "请使用 menu 或 launcher",
        .cmdSummaryHelp: "打开全部指令说明",
        .cmdArgSettingsGeneral: "通用设置",
        .cmdArgSettingsLanguage: "语言设置",
        .cmdArgSettingsHotkey: "快捷键设置",
        .cmdArgSettingsCommands: "全部指令说明",
        .cmdArgLangEnglish: "English",
        .cmdArgLangChinese: "简体中文（zh）",
        .cmdArgStyleAuto: "自动",
        .cmdArgStyleLiquid: "液态玻璃（glass）",
        .cmdArgStyleMaterial: "毛玻璃",
        .cmdArgFormatEmoji: "仅表情",
        .cmdArgFormatCode: "仅 shortcode",
        .cmdArgFormatTemplate: "自定义模板",
        .cmdArgTemplateHint: "示例模板（可自由编辑）",
        .cmdArgRecentClear: "清空最近使用",
        .cmdArgRecentCount: "设置保留数量（5…20）",
        .cmdNoMatch: "没有匹配的命令",
        .cmdRejectsArguments: "该命令不接受参数",
        .cmdUnsupportedSettingsTab: "不支持的设置页参数",
        .cmdNeedLanguage: "请指定语言参数",
        .cmdUnsupportedLanguage: "不支持的语言参数",
        .cmdNeedStyle: "请指定外观参数",
        .cmdUnsupportedStyle: "不支持的外观参数",
        .cmdNeedFormat: "请指定格式参数",
        .cmdUnsupportedFormat: "不支持的格式参数",
        .cmdNeedTemplate: "请输入模板内容",
        .cmdNeedRecentSubcommand: "请指定子命令 clear 或 count",
        .cmdClearNoExtraArgs: "clear 不需要额外参数",
        .cmdNeedCountValue: "请指定数量，例如 count 8",
        .cmdCountMustBeInteger: "数量必须是整数",
        .cmdUnsupportedSubcommand: "不支持的子命令",
        .cmdUnknownCommand: "未找到匹配的命令",
        .cmdIncompleteArguments: "命令参数不完整"
    ]
}

extension PreferencesStore {
    /// 按当前界面语言取文案。
    func t(_ key: L10nKey) -> String {
        L10n.text(key, language: uiLanguage)
    }
}
