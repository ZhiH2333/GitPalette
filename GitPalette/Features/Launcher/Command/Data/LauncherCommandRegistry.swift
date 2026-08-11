//
//  LauncherCommandRegistry.swift
//  GitPalette
//
//  命令静态目录与按名称 / 别名查询。
//

import Foundation

/// 启动器命令静态目录。
enum LauncherCommandRegistry {
    /// 全部命令（稳定顺序）。
    static let allCommands: [LauncherCommand] = LauncherCommand.allCases

    /// 按精确 token（小写、无 /）解析命令。
    static func resolveExactCommand(token: String) -> LauncherCommand? {
        let normalized: String = executeNormalizeToken(token)
        if normalized.isEmpty {
            return nil
        }
        for command in allCommands {
            if command.name == normalized {
                return command
            }
            if command.aliases.contains(normalized) {
                return command
            }
        }
        return nil
    }

    /// 按前缀匹配命令（用于建议列表）；返回 (命令, 是否命中别名)。
    static func resolvePrefixMatches(prefix: String) -> [(command: LauncherCommand, matchedViaAlias: Bool)] {
        let normalized: String = executeNormalizeToken(prefix)
        if normalized.isEmpty {
            return allCommands.map { ($0, false) }
        }
        var exactName: [(LauncherCommand, Bool)] = []
        var prefixName: [(LauncherCommand, Bool)] = []
        var aliasHits: [(LauncherCommand, Bool)] = []
        var seen: Set<LauncherCommand> = []
        for command in allCommands {
            if command.name == normalized {
                exactName.append((command, false))
                seen.insert(command)
                continue
            }
            if command.name.hasPrefix(normalized) {
                prefixName.append((command, false))
                seen.insert(command)
                continue
            }
            if command.aliases.contains(where: { $0 == normalized || $0.hasPrefix(normalized) }) {
                if !seen.contains(command) {
                    aliasHits.append((command, true))
                    seen.insert(command)
                }
            }
        }
        return exactName + prefixName + aliasHits
    }

    /// 规范化 token：去前导 /、小写、去空白。
    private static func executeNormalizeToken(_ token: String) -> String {
        var value: String = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("/") {
            value = String(value.dropFirst())
        }
        return value.lowercased()
    }
}
