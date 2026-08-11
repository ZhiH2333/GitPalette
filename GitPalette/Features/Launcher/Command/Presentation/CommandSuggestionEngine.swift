//
//  CommandSuggestionEngine.swift
//  GitPalette
//
//  根据当前 query 产出命令名或参数值建议（含 Tab 补全文本）。
//

import Foundation

/// 单条命令建议。
struct CommandSuggestion: Identifiable, Equatable, Sendable {
    let id: String
    /// 主文案（命令名或参数值）
    let primaryText: String
    /// 弱化次要文案（别名等）
    let secondaryText: String?
    /// 提示简述（跟随 descriptionLanguage）
    let summary: String
    /// Tab / 点击 / ↑↓ 应用的完整补全文本（不含自动尾随空格）
    let completionText: String
    /// 下一参数英文类型 ghost（仅命令名建议）；参数建议为 nil
    let argumentTypeGhost: String?

    init(
        id: String,
        primaryText: String,
        secondaryText: String?,
        summary: String,
        completionText: String,
        argumentTypeGhost: String? = nil
    ) {
        self.id = id
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.summary = summary
        self.completionText = completionText
        self.argumentTypeGhost = argumentTypeGhost
    }
}

/// 命令建议引擎。
enum CommandSuggestionEngine {
    /// 根据 query 生成建议列表。
    static func resolveSuggestions(
        for query: String,
        language: AppLanguage
    ) -> [CommandSuggestion] {
        guard query.hasPrefix("/") else {
            return []
        }
        let parse: LauncherCommandParseResult =
            LauncherCommandParser.executeParse(query, language: language)
        if let command: LauncherCommand = parse.matchedCommand {
            if command == .help {
                return executeBuildAllCommandSuggestions(language: language)
            }
            return executeBuildArgumentSuggestions(
                command: command,
                query: query,
                parse: parse,
                language: language
            )
        }
        return executeBuildCommandNameSuggestions(query: query, language: language)
    }

    /// 当前最佳补全文本（无候选时为 nil）。
    static func resolveBestCompletion(
        for query: String,
        selectedIndex: Int,
        language: AppLanguage
    ) -> String? {
        let suggestions: [CommandSuggestion] =
            resolveSuggestions(for: query, language: language)
        guard !suggestions.isEmpty else {
            return nil
        }
        let index: Int = min(max(selectedIndex, 0), suggestions.count - 1)
        return suggestions[index].completionText
    }

    /// 未选定命令时：按前缀 / 包含匹配命令名。
    private static func executeBuildCommandNameSuggestions(
        query: String,
        language: AppLanguage
    ) -> [CommandSuggestion] {
        let body: String = String(query.dropFirst())
        let token: String = body.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? body
        let prefix: String = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if prefix.isEmpty {
            return executeBuildAllCommandSuggestions(language: language)
        }
        let matches: [(command: LauncherCommand, matchedViaAlias: Bool)] =
            LauncherCommandRegistry.resolvePrefixMatches(prefix: prefix)
        return matches.map { executeMakeCommandSuggestion($0.command, language: language) }
    }

    /// 全部命令建议（「/」或 /help）。
    private static func executeBuildAllCommandSuggestions(
        language: AppLanguage
    ) -> [CommandSuggestion] {
        LauncherCommandRegistry.allCommands.map {
            executeMakeCommandSuggestion($0, language: language)
        }
    }

    /// 构造命令名建议行。
    private static func executeMakeCommandSuggestion(
        _ command: LauncherCommand,
        language: AppLanguage
    ) -> CommandSuggestion {
        let aliasText: String? = command.aliases.isEmpty
            ? nil
            : command.aliases.map { "/" + $0 }.joined(separator: " · ")
        return CommandSuggestion(
            id: "cmd-" + command.name,
            primaryText: command.displayName,
            secondaryText: aliasText,
            summary: command.summary(language: language),
            completionText: command.displayName,
            argumentTypeGhost: command.argumentTypePlaceholder
        )
    }

    /// 已选定命令时：参数候选。
    private static func executeBuildArgumentSuggestions(
        command: LauncherCommand,
        query: String,
        parse: LauncherCommandParseResult,
        language: AppLanguage
    ) -> [CommandSuggestion] {
        switch command {
        case .settings:
            return executeFilterArgumentCandidates(
                command: command,
                query: query,
                argumentPrefix: parse.rawArgumentText,
                candidates: [
                    ("general", L10n.text(.cmdArgSettingsGeneral, language: language)),
                    ("language", L10n.text(.cmdArgSettingsLanguage, language: language)),
                    ("hotkey", L10n.text(.cmdArgSettingsHotkey, language: language))
                ]
            )
        case .language, .codelang, .desclang:
            return executeFilterArgumentCandidates(
                command: command,
                query: query,
                argumentPrefix: parse.rawArgumentText,
                candidates: [
                    ("english", L10n.text(.cmdArgLangEnglish, language: language)),
                    ("chinese", L10n.text(.cmdArgLangChinese, language: language))
                ]
            )
        case .style:
            return executeFilterArgumentCandidates(
                command: command,
                query: query,
                argumentPrefix: parse.rawArgumentText,
                candidates: [
                    ("auto", L10n.text(.cmdArgStyleAuto, language: language)),
                    ("liquid", L10n.text(.cmdArgStyleLiquid, language: language)),
                    ("material", L10n.text(.cmdArgStyleMaterial, language: language))
                ]
            )
        case .format:
            return executeFilterArgumentCandidates(
                command: command,
                query: query,
                argumentPrefix: parse.rawArgumentText,
                candidates: [
                    ("emoji", L10n.text(.cmdArgFormatEmoji, language: language)),
                    ("code", L10n.text(.cmdArgFormatCode, language: language)),
                    ("template", L10n.text(.cmdArgFormatTemplate, language: language))
                ]
            )
        case .recent:
            return executeBuildRecentSuggestions(
                query: query,
                argument: parse.rawArgumentText,
                language: language
            )
        case .template:
            if parse.rawArgumentText.isEmpty {
                return [
                    CommandSuggestion(
                        id: "arg-template-hint",
                        primaryText: "{emoji} {code}",
                        secondaryText: nil,
                        summary: L10n.text(.cmdArgTemplateHint, language: language),
                        completionText: "/template {emoji} {code}"
                    )
                ]
            }
            return []
        case .general, .hotkey, .about, .permissions, .quit, .hide, .help:
            return [executeMakeCommandSuggestion(command, language: language)]
        }
    }

    /// /recent 参数建议。
    private static func executeBuildRecentSuggestions(
        query: String,
        argument: String,
        language: AppLanguage
    ) -> [CommandSuggestion] {
        let parts: [String] = argument.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if parts.isEmpty {
            return [
                CommandSuggestion(
                    id: "arg-recent-clear",
                    primaryText: "clear",
                    secondaryText: nil,
                    summary: L10n.text(.cmdArgRecentClear, language: language),
                    completionText: "/recent clear"
                ),
                CommandSuggestion(
                    id: "arg-recent-count",
                    primaryText: "count",
                    secondaryText: nil,
                    summary: L10n.text(.cmdArgRecentCount, language: language),
                    completionText: "/recent count"
                )
            ]
        }
        let head: String = parts[0].lowercased()
        if "clear".hasPrefix(head), parts.count == 1 {
            return [
                CommandSuggestion(
                    id: "arg-recent-clear",
                    primaryText: "clear",
                    secondaryText: nil,
                    summary: L10n.text(.cmdArgRecentClear, language: language),
                    completionText: "/recent clear"
                )
            ].filter { _ in "clear".hasPrefix(head) }
        }
        if "count".hasPrefix(head) {
            if parts.count == 1 {
                return [
                    CommandSuggestion(
                        id: "arg-recent-count",
                        primaryText: "count",
                        secondaryText: nil,
                        summary: L10n.text(.cmdArgRecentCount, language: language),
                        completionText: "/recent count"
                    )
                ]
            }
            return []
        }
        if head == "clear" || head == "count" {
            return []
        }
        return []
    }

    /// 按参数前缀过滤候选并生成补全。
    private static func executeFilterArgumentCandidates(
        command: LauncherCommand,
        query: String,
        argumentPrefix: String,
        candidates: [(value: String, summary: String)]
    ) -> [CommandSuggestion] {
        let prefixLower: String = argumentPrefix.lowercased()
        let filtered: [(String, String)]
        if prefixLower.isEmpty {
            filtered = candidates
        } else {
            filtered = candidates.filter { candidate in
                candidate.value.hasPrefix(prefixLower)
                    || candidate.value == prefixLower
            }
        }
        if filtered.isEmpty {
            return []
        }
        // 已有完整唯一参数时不再展示建议（避免 Return 前干扰）。
        if filtered.count == 1,
           filtered[0].0 == prefixLower,
           !query.hasSuffix(" ") {
            return [
                CommandSuggestion(
                    id: "arg-\(command.name)-\(filtered[0].0)",
                    primaryText: filtered[0].0,
                    secondaryText: nil,
                    summary: filtered[0].1,
                    completionText: "/\(command.name) \(filtered[0].0)"
                )
            ]
        }
        return filtered.map { value, summary in
            CommandSuggestion(
                id: "arg-\(command.name)-\(value)",
                primaryText: value,
                secondaryText: nil,
                summary: summary,
                completionText: "/\(command.name) \(value)"
            )
        }
    }
}
