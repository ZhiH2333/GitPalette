//
//  LauncherCommand.swift
//  GitPalette
//
//  启动器「/」命令枚举：名称、别名、简述与参数取值域。
//

import Foundation

/// 启动器斜杠命令。
enum LauncherCommand: String, CaseIterable, Identifiable, Sendable {
    case settings
    case general
    case hotkey
    case about
    case permissions
    case language
    case codelang
    case desclang
    case style
    case format
    case template
    case recent
    case quit
    case hide
    case menubar
    case help

    var id: String { rawValue }

    /// 规范命令名（不含前导 /）。
    var name: String { rawValue }

    /// 带前导 / 的展示名。
    var displayName: String { "/" + rawValue }

    /// 别名（不含前导 /，小写）。
    var aliases: [String] {
        switch self {
        case .settings:
            return ["setting", "preferences"]
        case .hotkey:
            return ["shortcut"]
        case .permissions:
            return ["accessibility"]
        case .quit:
            return ["exit"]
        case .help:
            return ["?", "commands"]
        case .menubar:
            return ["menuclick"]
        case .general, .about, .language, .codelang, .desclang,
                .style, .format, .template, .recent, .hide:
            return []
        }
    }

    /// 命令提示简述（跟随 descriptionLanguage / desclang）。
    func summary(language: AppLanguage) -> String {
        let key: L10nKey
        switch self {
        case .settings:
            key = .cmdSummarySettings
        case .general:
            key = .cmdSummaryGeneral
        case .hotkey:
            key = .cmdSummaryHotkey
        case .about:
            key = .cmdSummaryAbout
        case .permissions:
            key = .cmdSummaryPermissions
        case .language:
            key = .cmdSummaryLanguage
        case .codelang:
            key = .cmdSummaryCodelang
        case .desclang:
            key = .cmdSummaryDesclang
        case .style:
            key = .cmdSummaryStyle
        case .format:
            key = .cmdSummaryFormat
        case .template:
            key = .cmdSummaryTemplate
        case .recent:
            key = .cmdSummaryRecent
        case .quit:
            key = .cmdSummaryQuit
        case .hide:
            key = .cmdSummaryHide
        case .menubar:
            key = .cmdSummaryMenubar
        case .help:
            key = .cmdSummaryHelp
        }
        return L10n.text(key, language: language)
    }

    // TODO(后续): /reset — 一键恢复默认设置（本阶段不实现）

    /// 参数取值域描述（无参数时为 nil；命令 token 本身保持英文）。
    var argumentDomainDescription: String? {
        switch self {
        case .settings:
            return "general | language | hotkey | commands"
        case .language, .codelang, .desclang:
            return "english | chinese"
        case .style:
            return "auto | liquid（glass）| material"
        case .format:
            return "emoji | code | template"
        case .template:
            return "{emoji} {code} {name} {description}"
        case .recent:
            return "clear | count <n>"
        case .menubar:
            return "menu | launcher"
        case .general, .hotkey, .about, .permissions, .quit, .hide, .help:
            return nil
        }
    }

    /// 下一参数的英文类型名占位（半透明 ghost），无参数时为 nil。
    /// 例如 `/settings` → ` <option>`；用类型名，不用取值域描述。
    var argumentTypePlaceholder: String? {
        switch self {
        case .settings:
            return "<option>"
        case .language, .codelang, .desclang:
            return "<language>"
        case .style:
            return "<style>"
        case .format:
            return "<format>"
        case .template:
            return "<template>"
        case .recent:
            return "<action>"
        case .menubar:
            return "<menu|launcher>"
        case .general, .hotkey, .about, .permissions, .quit, .hide, .help:
            return nil
        }
    }

}
