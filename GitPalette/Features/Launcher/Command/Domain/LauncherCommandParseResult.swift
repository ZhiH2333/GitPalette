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
    /// 若不可执行时的中文原因（可选）
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
    static func executeParse(_ query: String) -> LauncherCommandParseResult {
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
            executeValidate(command: command, argument: split.argument)
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
        argument: String
    ) -> (isExecutable: Bool, message: String?) {
        switch command {
        case .settings:
            return executeValidateSettings(argument)
        case .general, .hotkey, .about, .permissions, .quit, .hide, .help:
            if argument.isEmpty {
                return (true, nil)
            }
            return (false, "该命令不接受参数")
        case .language, .codelang, .desclang:
            return executeValidateLanguage(argument)
        case .style:
            return executeValidateStyle(argument)
        case .format:
            return executeValidateFormat(argument)
        case .template:
            if argument.isEmpty {
                return (false, "请输入模板内容")
            }
            return (true, nil)
        case .recent:
            return executeValidateRecent(argument)
        }
    }

    /// 校验 /settings 参数。
    private static func executeValidateSettings(
        _ argument: String
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (true, nil)
        }
        let lower: String = argument.lowercased()
        if lower == "general" || lower == "language" || lower == "hotkey" {
            return (true, nil)
        }
        return (false, "不支持的设置页参数")
    }

    /// 校验语言类参数。
    private static func executeValidateLanguage(
        _ argument: String
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (false, "请指定语言参数")
        }
        if resolveLanguage(argument) != nil {
            return (true, nil)
        }
        return (false, "不支持的语言参数")
    }

    /// 校验外观参数。
    private static func executeValidateStyle(
        _ argument: String
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (false, "请指定外观参数")
        }
        if resolveAppearanceStyle(argument) != nil {
            return (true, nil)
        }
        return (false, "不支持的外观参数")
    }

    /// 校验复制格式参数。
    private static func executeValidateFormat(
        _ argument: String
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (false, "请指定格式参数")
        }
        if resolveCopyFormat(argument) != nil {
            return (true, nil)
        }
        return (false, "不支持的格式参数")
    }

    /// 校验 /recent 子命令。
    private static func executeValidateRecent(
        _ argument: String
    ) -> (isExecutable: Bool, message: String?) {
        if argument.isEmpty {
            return (false, "请指定子命令 clear 或 count")
        }
        let parts: [String] = argument.split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        guard let head: String = parts.first?.lowercased() else {
            return (false, "请指定子命令 clear 或 count")
        }
        if head == "clear" {
            if parts.count == 1 {
                return (true, nil)
            }
            return (false, "clear 不需要额外参数")
        }
        if head == "count" {
            guard parts.count >= 2 else {
                return (false, "请指定数量，例如 count 8")
            }
            guard Int(parts[1]) != nil else {
                return (false, "数量必须是整数")
            }
            return (true, nil)
        }
        return (false, "不支持的子命令")
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
