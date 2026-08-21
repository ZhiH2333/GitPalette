//
//  GitSubcommand.swift
//  GitPalette
//
//  /git 子命令解析与参数校验。
//

import Foundation

/// /git 子命令。
enum GitSubcommand: Equatable, Sendable {
    case link(path: String?)
    case repos
    case use(name: String)
    case unlink(name: String)
    case status
    case add
    case commit(message: String)

    /// 规范子命令名。
    var name: String {
        switch self {
        case .link:
            return "link"
        case .repos:
            return "repos"
        case .use:
            return "use"
        case .unlink:
            return "unlink"
        case .status:
            return "status"
        case .add:
            return "add"
        case .commit:
            return "commit"
        }
    }

    /// 解析 /git 后的参数文本。
    static func executeParse(
        argument: String,
        language: AppLanguage
    ) -> (subcommand: GitSubcommand?, isExecutable: Bool, message: String?) {
        let trimmed: String = argument.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return (nil, false, L10n.text(.cmdNeedGitSubcommand, language: language))
        }
        let split: (head: String, rest: String) = executeSplitHead(trimmed)
        let head: String = split.head.lowercased()
        switch head {
        case "link":
            let path: String = executeUnquote(split.rest)
            if path.isEmpty {
                return (.link(path: nil), true, nil)
            }
            return (.link(path: path), true, nil)
        case "repos":
            if split.rest.isEmpty {
                return (.repos, true, nil)
            }
            return (nil, false, L10n.text(.cmdGitReposNoExtraArgs, language: language))
        case "use":
            let name: String = executeUnquote(split.rest)
            if name.isEmpty {
                return (nil, false, L10n.text(.cmdNeedGitRepositoryName, language: language))
            }
            return (.use(name: name), true, nil)
        case "unlink":
            let name: String = executeUnquote(split.rest)
            if name.isEmpty {
                return (nil, false, L10n.text(.cmdNeedGitRepositoryName, language: language))
            }
            return (.unlink(name: name), true, nil)
        case "status":
            if split.rest.isEmpty {
                return (.status, true, nil)
            }
            return (nil, false, L10n.text(.cmdGitStatusNoExtraArgs, language: language))
        case "add":
            if split.rest.isEmpty {
                return (.add, true, nil)
            }
            return (nil, false, L10n.text(.cmdGitAddNoExtraArgs, language: language))
        case "commit":
            let message: String = executeUnquote(split.rest)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if message.isEmpty {
                return (nil, false, L10n.text(.cmdNeedGitCommitMessage, language: language))
            }
            return (.commit(message: message), true, nil)
        default:
            return (nil, false, L10n.text(.cmdUnsupportedSubcommand, language: language))
        }
    }

    /// 查询是否已进入 /git（含子命令与参数）。
    static func executeIsGitQuery(_ query: String) -> Bool {
        let trimmed: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("/") else {
            return false
        }
        let afterSlash: String = String(trimmed.dropFirst())
        let commandSplit: (head: String, rest: String) = executeSplitHead(afterSlash)
        return commandSplit.head.lowercased() == "git"
    }

    /// 取出 /git 后的子命令 token；未进入 git 或尚无子命令则为 nil。
    static func executeGitSubcommandHead(_ query: String) -> String? {
        let trimmed: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("/") else {
            return nil
        }
        let afterSlash: String = String(trimmed.dropFirst())
        let commandSplit: (head: String, rest: String) = executeSplitHead(afterSlash)
        guard commandSplit.head.lowercased() == "git" else {
            return nil
        }
        let subcommandSplit: (head: String, rest: String) = executeSplitHead(commandSplit.rest)
        if subcommandSplit.head.isEmpty {
            return nil
        }
        return subcommandSplit.head.lowercased()
    }

    /// 查询是否已进入 /git commit（含后续消息）。
    static func executeIsCommitQuery(_ query: String) -> Bool {
        executeGitSubcommandHead(query) == "commit"
    }

    /// 拆分子命令 token 与剩余参数。
    private static func executeSplitHead(_ argument: String) -> (head: String, rest: String) {
        guard let spaceIndex: String.Index = argument.firstIndex(where: { $0.isWhitespace }) else {
            return (argument, "")
        }
        let head: String = String(argument[..<spaceIndex])
        let after: String.Index = argument.index(after: spaceIndex)
        let rest: String = String(argument[after...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (head, rest)
    }

    /// 去掉成对引号。
    private static func executeUnquote(_ raw: String) -> String {
        let trimmed: String = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 2, trimmed.hasPrefix("\""), trimmed.hasSuffix("\"") {
            return String(trimmed.dropFirst().dropLast())
        }
        if trimmed.count >= 2, trimmed.hasPrefix("'"), trimmed.hasSuffix("'") {
            return String(trimmed.dropFirst().dropLast())
        }
        return trimmed
    }
}
