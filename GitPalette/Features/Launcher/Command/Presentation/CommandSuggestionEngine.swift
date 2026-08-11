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
    /// 中文简述
    let summary: String
    /// Tab / 点击应用的完整补全文本
    let completionText: String
}

/// 命令建议引擎。
enum CommandSuggestionEngine {
    /// 根据 query 生成建议列表。
    static func resolveSuggestions(for query: String) -> [CommandSuggestion] {
        guard query.hasPrefix("/") else {
            return []
        }
        let parse: LauncherCommandParseResult = LauncherCommandParser.executeParse(query)
        if let command: LauncherCommand = parse.matchedCommand {
            if command == .help {
                return executeBuildAllCommandSuggestions()
            }
            return executeBuildArgumentSuggestions(command: command, query: query, parse: parse)
        }
        return executeBuildCommandNameSuggestions(query: query)
    }

    /// 当前最佳补全文本（无候选时为 nil）。
    static func resolveBestCompletion(for query: String, selectedIndex: Int) -> String? {
        let suggestions: [CommandSuggestion] = resolveSuggestions(for: query)
        guard !suggestions.isEmpty else {
            return nil
        }
        let index: Int = min(max(selectedIndex, 0), suggestions.count - 1)
        return suggestions[index].completionText
    }

    /// 未选定命令时：按前缀 / 包含匹配命令名。
    private static func executeBuildCommandNameSuggestions(query: String) -> [CommandSuggestion] {
        let body: String = String(query.dropFirst())
        let token: String = body.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? body
        let prefix: String = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if prefix.isEmpty {
            return executeBuildAllCommandSuggestions()
        }
        let matches: [(command: LauncherCommand, matchedViaAlias: Bool)] =
            LauncherCommandRegistry.resolvePrefixMatches(prefix: prefix)
        return matches.map { executeMakeCommandSuggestion($0.command) }
    }

    /// 全部命令建议（「/」或 /help）。
    private static func executeBuildAllCommandSuggestions() -> [CommandSuggestion] {
        LauncherCommandRegistry.allCommands.map { executeMakeCommandSuggestion($0) }
    }

    /// 构造命令名建议行。
    private static func executeMakeCommandSuggestion(
        _ command: LauncherCommand
    ) -> CommandSuggestion {
        let aliasText: String? = command.aliases.isEmpty
            ? nil
            : command.aliases.map { "/" + $0 }.joined(separator: " · ")
        let completion: String
        if command.shouldAppendTrailingSpaceAfterName {
            completion = command.displayName + " "
        } else {
            completion = command.displayName
        }
        return CommandSuggestion(
            id: "cmd-" + command.name,
            primaryText: command.displayName,
            secondaryText: aliasText,
            summary: command.summary,
            completionText: completion
        )
    }

    /// 已选定命令时：参数候选。
    private static func executeBuildArgumentSuggestions(
        command: LauncherCommand,
        query: String,
        parse: LauncherCommandParseResult
    ) -> [CommandSuggestion] {
        switch command {
        case .settings:
            return executeFilterArgumentCandidates(
                command: command,
                query: query,
                argumentPrefix: parse.rawArgumentText,
                candidates: [
                    ("general", "通用设置"),
                    ("language", "语言设置"),
                    ("hotkey", "快捷键设置")
                ]
            )
        case .language, .codelang, .desclang:
            return executeFilterArgumentCandidates(
                command: command,
                query: query,
                argumentPrefix: parse.rawArgumentText,
                candidates: [
                    ("english", "English"),
                    ("chinese", "简体中文（zh）")
                ]
            )
        case .style:
            return executeFilterArgumentCandidates(
                command: command,
                query: query,
                argumentPrefix: parse.rawArgumentText,
                candidates: [
                    ("auto", "自动"),
                    ("liquid", "液态玻璃（glass）"),
                    ("material", "毛玻璃")
                ]
            )
        case .format:
            return executeFilterArgumentCandidates(
                command: command,
                query: query,
                argumentPrefix: parse.rawArgumentText,
                candidates: [
                    ("emoji", "仅表情"),
                    ("code", "仅 shortcode"),
                    ("template", "自定义模板")
                ]
            )
        case .recent:
            return executeBuildRecentSuggestions(query: query, argument: parse.rawArgumentText)
        case .template:
            if parse.rawArgumentText.isEmpty {
                return [
                    CommandSuggestion(
                        id: "arg-template-hint",
                        primaryText: "{emoji} {code}",
                        secondaryText: nil,
                        summary: "示例模板（可自由编辑）",
                        completionText: "/template {emoji} {code}"
                    )
                ]
            }
            return []
        case .general, .hotkey, .about, .permissions, .quit, .hide, .help:
            return [executeMakeCommandSuggestion(command)]
        }
    }

    /// /recent 参数建议。
    private static func executeBuildRecentSuggestions(
        query: String,
        argument: String
    ) -> [CommandSuggestion] {
        let parts: [String] = argument.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if parts.isEmpty {
            return [
                CommandSuggestion(
                    id: "arg-recent-clear",
                    primaryText: "clear",
                    secondaryText: nil,
                    summary: "清空最近使用",
                    completionText: "/recent clear"
                ),
                CommandSuggestion(
                    id: "arg-recent-count",
                    primaryText: "count",
                    secondaryText: nil,
                    summary: "设置保留数量（5…20）",
                    completionText: "/recent count "
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
                    summary: "清空最近使用",
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
                        summary: "设置保留数量（5…20）",
                        completionText: "/recent count "
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
