//
//  GitStatusParser.swift
//  GitPalette
//
//  解析 `git status --porcelain=v1` 输出。
//

import Foundation

/// porcelain v1 解析器。
enum GitStatusParser {
    /// 将 stdout 解析为结构化条目。
    static func executeParse(_ porcelain: String) -> [GitStatusEntry] {
        let lines: [String] = porcelain.split(whereSeparator: \.isNewline).map(String.init)
        var entries: [GitStatusEntry] = []
        for line in lines {
            if let entry: GitStatusEntry = executeParseLine(line) {
                entries.append(entry)
            }
        }
        return entries
    }

    /// 解析单行 porcelain。
    private static func executeParseLine(_ line: String) -> GitStatusEntry? {
        guard line.count >= 3 else {
            return nil
        }
        let xy: String = String(line.prefix(2))
        let rest: String = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        if rest.isEmpty {
            return nil
        }
        let kind: GitStatusKind = resolveKind(xy: xy)
        let isStaged: Bool = executeIsStaged(xy: xy)
        if kind == .renamed {
            let parts: (original: String, current: String)? = executeSplitRename(rest)
            if let parts {
                return GitStatusEntry(
                    relativePath: parts.current,
                    kind: .renamed,
                    isStaged: isStaged,
                    originalPath: parts.original
                )
            }
        }
        return GitStatusEntry(
            relativePath: executeUnquotePath(rest),
            kind: kind,
            isStaged: isStaged,
            originalPath: nil
        )
    }

    /// 由 XY 推导展示类型。
    private static func resolveKind(xy: String) -> GitStatusKind {
        if xy == "??" {
            return .untracked
        }
        let x: Character = xy.first ?? " "
        let y: Character = xy.count > 1 ? xy[xy.index(after: xy.startIndex)] : " "
        if x == "R" || y == "R" || x == "C" || y == "C" {
            return .renamed
        }
        if x == "D" || y == "D" {
            return .deleted
        }
        if x == "A" || y == "A" {
            return .added
        }
        if x == "M" || y == "M" {
            return .modified
        }
        return .modified
    }

    /// 索引区已暂存。
    private static func executeIsStaged(xy: String) -> Bool {
        guard let x: Character = xy.first else {
            return false
        }
        return x != " " && x != "?"
    }

    /// 拆分 `old -> new`。
    private static func executeSplitRename(_ rest: String) -> (original: String, current: String)? {
        let separator: String = " -> "
        guard let range: Range<String.Index> = rest.range(of: separator) else {
            return nil
        }
        let original: String = executeUnquotePath(String(rest[..<range.lowerBound]).trimmingCharacters(in: .whitespaces))
        let current: String = executeUnquotePath(String(rest[range.upperBound...]).trimmingCharacters(in: .whitespaces))
        if original.isEmpty || current.isEmpty {
            return nil
        }
        return (original, current)
    }

    /// 去掉 porcelain 引号转义。
    private static func executeUnquotePath(_ raw: String) -> String {
        var path: String = raw.trimmingCharacters(in: .whitespaces)
        guard path.count >= 2, path.hasPrefix("\""), path.hasSuffix("\"") else {
            return path
        }
        path = String(path.dropFirst().dropLast())
        path = path.replacingOccurrences(of: "\\\"", with: "\"")
        path = path.replacingOccurrences(of: "\\\\", with: "\\")
        path = path.replacingOccurrences(of: "\\t", with: "\t")
        path = path.replacingOccurrences(of: "\\n", with: "\n")
        return path
    }
}
