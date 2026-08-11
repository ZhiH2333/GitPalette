//
//  LauncherCommandParseResult.swift
//  GitPalette
//
//  「/」命令解析结果。
//

import Foundation

/// 命令解析结果。
struct LauncherCommandParseResult: Equatable, Sendable {
    /// 是否处于命令模式（以 / 开头）
    let isCommandMode: Bool
    /// 已精确匹配的命令（名称或别名完全相等）
    let matchedCommand: LauncherCommand?
    /// 命令名之后的原始参数文本（已去掉首尾空白）
    let rawArgumentText: String
    /// 当前输入是否可合法执行
    let isExecutable: Bool
    /// 若不可执行时的本地化原因（跟随 descriptionLanguage）
    let validationMessage: String?

    /// 非命令模式占位。
    static let notCommandMode: LauncherCommandParseResult = LauncherCommandParseResult(
        isCommandMode: false,
        matchedCommand: nil,
        rawArgumentText: "",
        isExecutable: false,
        validationMessage: nil
    )
}

/// 将用户输入解析为命令结果。
enum LauncherCommandParser {
    /// 解析查询字符串。
    static func executeParse(
        _ query: String,
        language: AppLanguage
    ) -> LauncherCommandParseResult {
        guard query.hasPrefix("/") else {
            return .notCommandMode
        }
        let body: String = String(query.dropFirst())
        if body.isEmpty {
            return LauncherCommandParseResult(
                isCommandMode: true,
                matchedCommand: nil,
                rawArgumentText: "",
                isExecutable: false,
                validationMessage: nil
            )
        }
        let split: (token: String, argument: String) = executeSplitCommandAndArgument(body)
        let tokenLower: String = split.token.lowercased()
        guard let command: LauncherCommand =
            LauncherCommandRegistry.resolveExactCommand(token: tokenLower)
        else {
            return LauncherCommandParseResult(
                isCommandMode: true,
                matchedCommand: nil,
                rawArgumentText: split.argument,
                isExecutable: false,
                validationMessage: nil
            )
        }
        let validation: (isExecutable: Bool, message: String?) =
            executeValidate(command: command, argument: split.argument, language: language)
        return LauncherCommandParseResult(
            isCommandMode: true,
            matchedCommand: command,
            rawArgumentText: split.argument,
            isExecutable: validation.isExecutable,
            validationMessage: validation.message
        )
    }

    /// 拆分命令 token 与剩余参数（首个空白分隔；template 保留后续整段）。
    private static func executeSplitCommandAndArgument(
        _ body: String
    ) -> (token: String, argument: String) {
        let trimmed: String = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let spaceIndex: String.Index =
            trimmed.firstIndex(where: { $0.isWhitespace })
        else {
            return (trimmed, "")
        }
        let token: String = String(trimmed[..<spaceIndex])
        let afterSpace: String.Index = trimmed.index(after: spaceIndex)
        let argument: String = String(trimmed[afterSpace...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (token, argument)
    }

    /// 校验参数是否合法完整。
    private static func executeValidate(
        command: LauncherCommand,
        argument: String,
        language: AppLanguage
    ) -> (isExecutable: Bool, message: String?) {
        switch command {
        case .settings:
            return executeValidateSettings(argument, language: language)
        case .general, .hotkey, .about, .permissions, .quit, .hide, .help:
            if argument.isEmpty {
                return (true, nil)
            }
            return (false, L10n.text(.cmdRejectsArguments, language: language))
        case .language, .codelang, .desclang:
            return executeValidateLanguage(argument, language: language)
        case .style:
            return executeValidateStyle(argument, language: language)
        case .format:
            return executeValidateFormat(argument, language: language)
        case .template:
            if argument.isEmpty {
                return (false, L10n.text(.cmdNeedTemplate, language: language))
            }
            return (true, nil)
        case .menubar:
            return executeValidateMenubar(argument, language: language)
        case .recent:
            return executeValidateRecent(argument, language: language)
        }
    }

    /// 校验 /menubar 参数。
    private static func executeValidateMenubar(
        _ argument: String,
        language: AppLanguage
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (false, L10n.text(.cmdUnsupportedMenubarArg, language: language))
        }
        let lower: String = argument.lowercased()
        if lower == "menu" || lower == "launcher" {
            return (true, nil)
        }
        return (false, L10n.text(.cmdUnsupportedMenubarArg, language: language))
    }

    /// 校验 /settings 参数。
    private static func executeValidateSettings(
        _ argument: String,
        language: AppLanguage
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (true, nil)
        }
        let lower: String = argument.lowercased()
        if lower == "general" || lower == "language" || lower == "hotkey" {
            return (true, nil)
        }
        return (false, L10n.text(.cmdUnsupportedSettingsTab, language: language))
    }

    /// 校验语言类参数。
    private static func executeValidateLanguage(
        _ argument: String,
        language: AppLanguage
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (false, L10n.text(.cmdNeedLanguage, language: language))
        }
        if resolveLanguage(argument) != nil {
            return (true, nil)
        }
        return (false, L10n.text(.cmdUnsupportedLanguage, language: language))
    }

    /// 校验外观参数。
    private static func executeValidateStyle(
        _ argument: String,
        language: AppLanguage
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (false, L10n.text(.cmdNeedStyle, language: language))
        }
        if resolveAppearanceStyle(argument) != nil {
            return (true, nil)
        }
        return (false, L10n.text(.cmdUnsupportedStyle, language: language))
    }

    /// 校验复制格式参数。
    private static func executeValidateFormat(
        _ argument: String,
        language: AppLanguage
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (false, L10n.text(.cmdNeedFormat, language: language))
        }
        if resolveCopyFormat(argument) != nil {
            return (true, nil)
        }
        return (false, L10n.text(.cmdUnsupportedFormat, language: language))
    }

    /// 校验 /recent 子命令。
    private static func executeValidateRecent(
        _ argument: String,
        language: AppLanguage
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (false, L10n.text(.cmdNeedRecentSubcommand, language: language))
        }
        let parts: [String] = argument.split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        guard let head: String = parts.first?.lowercased() else {
            return (false, L10n.text(.cmdNeedRecentSubcommand, language: language))
        }
        if head == "clear" {
            if parts.count == 1 {
                return (true, nil)
            }
            return (false, L10n.text(.cmdClearNoExtraArgs, language: language))
        }
        if head == "count" {
            guard parts.count >= 2 else {
                return (false, L10n.text(.cmdNeedCountValue, language: language))
            }
            guard Int(parts[1]) != nil else {
                return (false, L10n.text(.cmdCountMustBeInteger, language: language))
            }
            return (true, nil)
        }
        return (false, L10n.text(.cmdUnsupportedSubcommand, language: language))
    }

    /// 解析语言参数（不区分大小写）。
    static func resolveLanguage(_ argument: String) -> AppLanguage? {
        let lower: String = argument.lowercased()
        switch lower {
        case "english", "en":
            return .english
        case "chinese", "zh", "中文", "简体中文":
            return .simplifiedChinese
        default:
            return nil
        }
    }

    /// 解析外观参数。
    static func resolveAppearanceStyle(_ argument: String) -> AppearanceStyle? {
        let lower: String = argument.lowercased()
        switch lower {
        case "auto", "automatic":
            return .automatic
        case "liquid", "glass", "liquidglass":
            return .liquidGlass
        case "material":
            return .material
        default:
            return nil
        }
    }

    /// 解析菜单栏点击行为参数。
    static func resolveMenuBarClickBehavior(_ argument: String) -> MenuBarClickBehavior? {
        let normalized: String = argument.trimmingCharacters(in: .whitespaces).lowercased()
        if normalized.isEmpty { return nil }
        return MenuBarClickBehavior.allCases.first { $0.rawValue == normalized }
    }

    /// 解析复制格式参数。
    static func resolveCopyFormat(_ argument: String) -> CopyFormat? {
        let lower: String = argument.lowercased()
        switch lower {
        case "emoji":
            return .emoji
        case "code":
            return .code
        case "template", "customtemplate", "custom":
            return .customTemplate
        default:
            return nil
        }
    }

    /// 解析设置页参数。
    static func resolveSettingsTab(_ argument: String) -> SettingsTab? {
        if argument.isEmpty {
            return .general
        }
        switch argument.lowercased() {
        case "general":
            return .general
        case "language":
            return .language
        case "hotkey":
            return .hotkey
        default:
            return nil
        }
    }
}
