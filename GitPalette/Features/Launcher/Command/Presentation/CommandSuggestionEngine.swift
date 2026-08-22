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
    /// 行首 SF Symbol
    let systemImageName: String

    init(
        id: String,
        primaryText: String,
        secondaryText: String?,
        summary: String,
        completionText: String,
        argumentTypeGhost: String? = nil,
        systemImageName: String = CommandSuggestion.commandSystemImageName
    ) {
        self.id = id
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.summary = summary
        self.completionText = completionText
        self.argumentTypeGhost = argumentTypeGhost
        self.systemImageName = systemImageName
    }

    /// 普通斜杠命令图标。
    static let commandSystemImageName: String = "chevron.left.forwardslash.chevron.right"
    /// /git 命令名图标。
    static let gitSystemImageName: String = "arrow.triangle.branch"

    /// /git 子命令对应的 SF Symbol。
    static func resolveGitSubcommandSystemImageName(_ subcommand: String) -> String {
        switch subcommand.lowercased() {
        case "link":
            return "link"
        case "repos":
            return "folder"
        case "use":
            return "checkmark.circle"
        case "unlink":
            return gitSystemImageName
        case "status":
            return "list.bullet.rectangle"
        case "add":
            return "plus.square"
        case "commit":
            return "square.and.pencil"
        default:
            return gitSystemImageName
        }
    }
}

/// 命令建议引擎。
enum CommandSuggestionEngine {
    /// 根据 query 生成建议列表。
    static func resolveSuggestions(
        for query: String,
        language: AppLanguage,
        linkedRepositories: [GitRepository] = []
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
                language: language,
                linkedRepositories: linkedRepositories
            )
        }
        return executeBuildCommandNameSuggestions(query: query, language: language)
    }

    /// 当前最佳补全文本（无候选时为 nil）。
    static func resolveBestCompletion(
        for query: String,
        selectedIndex: Int,
        language: AppLanguage,
        linkedRepositories: [GitRepository] = []
    ) -> String? {
        let suggestions: [CommandSuggestion] =
            resolveSuggestions(
                for: query,
                language: language,
                linkedRepositories: linkedRepositories
            )
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
            argumentTypeGhost: command.argumentTypePlaceholder,
            systemImageName: command == .git
                ? CommandSuggestion.gitSystemImageName
                : CommandSuggestion.commandSystemImageName
        )
    }

    /// 已选定命令时：参数候选。
    private static func executeBuildArgumentSuggestions(
        command: LauncherCommand,
        query: String,
        parse: LauncherCommandParseResult,
        language: AppLanguage,
        linkedRepositories: [GitRepository]
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
                    ("hotkey", L10n.text(.cmdArgSettingsHotkey, language: language)),
                    ("commands", L10n.text(.cmdArgSettingsCommands, language: language))
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
        case .menubar:
            return executeFilterArgumentCandidates(
                command: command,
                query: query,
                argumentPrefix: parse.rawArgumentText,
                candidates: [
                    ("menu", L10n.text(.cmdArgMenubarMenu, language: language)),
                    ("launcher", L10n.text(.cmdArgMenubarLauncher, language: language))
                ]
            )
        case .git:
            return executeBuildGitSuggestions(
                query: query,
                argument: parse.rawArgumentText,
                language: language,
                linkedRepositories: linkedRepositories
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

    /// /git 参数建议。
    private static func executeBuildGitSuggestions(
        query: String,
        argument: String,
        language: AppLanguage,
        linkedRepositories: [GitRepository]
    ) -> [CommandSuggestion] {
        let split: (head: String, rest: String) = executeSplitArgumentHead(argument)
        let head: String = split.head.lowercased()
        if head == "use" || head == "unlink" {
            return executeBuildGitRepositorySuggestions(
                subcommand: head,
                namePrefix: split.rest,
                language: language,
                linkedRepositories: linkedRepositories
            )
        }
        // commit / status / add / repos / link 在已有后续文本时不再用关键词匹配其它子命令。
        if head == "commit" || (!split.rest.isEmpty && Self.executeIsLeafGitSubcommand(head)) {
            return []
        }
        let candidates: [(value: String, summary: String)] = [
            ("link", L10n.text(.cmdArgGitLink, language: language)),
            ("repos", L10n.text(.cmdArgGitRepos, language: language)),
            ("use", L10n.text(.cmdArgGitUse, language: language)),
            ("unlink", L10n.text(.cmdArgGitUnlink, language: language)),
            ("status", L10n.text(.cmdArgGitStatus, language: language)),
            ("add", L10n.text(.cmdArgGitAdd, language: language)),
            ("commit", L10n.text(.cmdArgGitCommit, language: language))
        ]
        return executeFilterArgumentCandidates(
            command: .git,
            query: query,
            argumentPrefix: argument,
            candidates: candidates
        )
    }

    /// /git use、/git unlink：列出已链接仓库供上下选择。
    private static func executeBuildGitRepositorySuggestions(
        subcommand: String,
        namePrefix: String,
        language _: AppLanguage,
        linkedRepositories: [GitRepository]
    ) -> [CommandSuggestion] {
        if linkedRepositories.isEmpty {
            return []
        }
        let prefixLower: String = namePrefix.lowercased()
        let sorted: [GitRepository]
        if prefixLower.isEmpty {
            sorted = linkedRepositories
        } else {
            sorted = linkedRepositories.sorted { a, b in
                let aName: String = a.displayName.lowercased()
                let bName: String = b.displayName.lowercased()
                let aExact: Bool = aName == prefixLower
                let bExact: Bool = bName == prefixLower
                if aExact != bExact { return aExact }
                let aPrefix: Bool = aName.hasPrefix(prefixLower)
                let bPrefix: Bool = bName.hasPrefix(prefixLower)
                if aPrefix != bPrefix { return aPrefix }
                let aContains: Bool = aName.contains(prefixLower)
                let bContains: Bool = bName.contains(prefixLower)
                if aContains != bContains { return aContains }
                return aName < bName
            }
        }
        return sorted.map { repository in
            let quotedName: String = executeQuoteIfNeeded(repository.displayName)
            return CommandSuggestion(
                id: "arg-git-\(subcommand)-\(repository.id)",
                primaryText: repository.displayName,
                secondaryText: nil,
                summary: repository.path,
                completionText: "/git \(subcommand) \(quotedName)",
                systemImageName: CommandSuggestion.resolveGitSubcommandSystemImageName(subcommand)
            )
        }
    }

    /// 仓库名含空白时加双引号。
    private static func executeQuoteIfNeeded(_ value: String) -> String {
        if value.contains(where: { $0.isWhitespace }) {
            return "\"" + value + "\""
        }
        return value
    }

    /// 不再接受后续参数的 git 子命令。
    private static func executeIsLeafGitSubcommand(_ head: String) -> Bool {
        switch head {
        case "commit", "status", "add", "repos", "link":
            return true
        default:
            return false
        }
    }

    /// 拆分首个参数 token 与剩余文本。
    private static func executeSplitArgumentHead(_ argument: String) -> (head: String, rest: String) {
        let trimmed: String = argument.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let spaceIndex: String.Index = trimmed.firstIndex(where: { $0.isWhitespace }) else {
            return (trimmed, "")
        }
        let head: String = String(trimmed[..<spaceIndex])
        let after: String.Index = trimmed.index(after: spaceIndex)
        let rest: String = String(trimmed[after...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (head, rest)
    }

    /// /recent 参数建议（Spotlight 风格：始终展示全部子命令，仅排序不隐藏）。
    private static func executeBuildRecentSuggestions(
        query: String,
        argument: String,
        language: AppLanguage
    ) -> [CommandSuggestion] {
        let clearSuggestion: CommandSuggestion = CommandSuggestion(
            id: "arg-recent-clear",
            primaryText: "clear",
            secondaryText: nil,
            summary: L10n.text(.cmdArgRecentClear, language: language),
            completionText: "/recent clear"
        )
        let countSuggestion: CommandSuggestion = CommandSuggestion(
            id: "arg-recent-count",
            primaryText: "count",
            secondaryText: nil,
            summary: L10n.text(.cmdArgRecentCount, language: language),
            completionText: "/recent count"
        )
        let all: [CommandSuggestion] = [clearSuggestion, countSuggestion]
        let parts: [String] = argument.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if parts.isEmpty {
            return all
        }
        let head: String = parts[0].lowercased()
        guard parts.count == 1 else {
            // 已输入 count + 数字 → 仍展示两者以便切回
            if head == "count" { return all }
            return all
        }
        // 按匹配度排序：精确 → 前缀 → 包含 → 其余
        return all.sorted { a, b in
            let aVal: String = a.primaryText.lowercased()
            let bVal: String = b.primaryText.lowercased()
            let aExact: Bool = aVal == head
            let bExact: Bool = bVal == head
            if aExact != bExact { return aExact }
            let aPrefix: Bool = aVal.hasPrefix(head)
            let bPrefix: Bool = bVal.hasPrefix(head)
            if aPrefix != bPrefix { return aPrefix }
            let aContains: Bool = aVal.contains(head)
            let bContains: Bool = bVal.contains(head)
            if aContains != bContains { return aContains }
            return aVal < bVal
        }
    }

    /// Spotlight 风格：始终展示全部候选，仅按前缀匹配重排序（不过滤）。
    /// 高亮由 executePreferSelectionMatchingQuery 负责。
    private static func executeFilterArgumentCandidates(
        command: LauncherCommand,
        query: String,
        argumentPrefix: String,
        candidates: [(value: String, summary: String)]
    ) -> [CommandSuggestion] {
        let prefixLower: String = argumentPrefix.lowercased()
        let sorted: [(String, String)]
        if prefixLower.isEmpty {
            sorted = candidates
        } else {
            // 精确匹配 → 前缀匹配 → 包含匹配 → 其余
            sorted = candidates.sorted { a, b in
                let aExact: Bool = a.value == prefixLower
                let bExact: Bool = b.value == prefixLower
                if aExact != bExact { return aExact }
                let aPrefix: Bool = a.value.hasPrefix(prefixLower)
                let bPrefix: Bool = b.value.hasPrefix(prefixLower)
                if aPrefix != bPrefix { return aPrefix }
                let aContains: Bool = a.value.contains(prefixLower)
                let bContains: Bool = b.value.contains(prefixLower)
                if aContains != bContains { return aContains }
                return a.value < b.value
            }
        }
        return sorted.map { value, summary in
            CommandSuggestion(
                id: "arg-\(command.name)-\(value)",
                primaryText: value,
                secondaryText: nil,
                summary: summary,
                completionText: "/\(command.name) \(value)",
                systemImageName: command == .git
                    ? CommandSuggestion.resolveGitSubcommandSystemImageName(value)
                    : CommandSuggestion.commandSystemImageName
            )
        }
    }
}
