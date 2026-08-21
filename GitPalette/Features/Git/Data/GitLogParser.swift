//
//  GitLogParser.swift
//  GitPalette
//
//  解析 `git log --graph --decorate --oneline` 输出。
//

import Foundation

/// graph + oneline 解析器。
enum GitLogParser {
    private static let hashPattern: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: "[0-9a-fA-F]{7,40}")
        } catch {
            preconditionFailure("GitLogParser hash pattern is invalid")
        }
    }()

    /// 将 stdout 解析为图行。
    static func executeParse(_ stdout: String) -> [GitLogEntry] {
        if stdout.isEmpty {
            return []
        }
        let lines: [String] = stdout.components(separatedBy: "\n").map { line in
            if line.hasSuffix("\r") {
                return String(line.dropLast())
            }
            return line
        }
        var entries: [GitLogEntry] = []
        for (index, line) in lines.enumerated() {
            if line.isEmpty && index == lines.count - 1 {
                continue
            }
            entries.append(executeParseLine(line, index: index))
        }
        return entries
    }

    /// 解析单行 graph / oneline。
    private static func executeParseLine(_ line: String, index: Int) -> GitLogEntry {
        let nsLine: NSString = line as NSString
        let range: NSRange = NSRange(location: 0, length: nsLine.length)
        let match: NSTextCheckingResult? = hashPattern.firstMatch(in: line, options: [], range: range)
        guard let match, match.numberOfRanges >= 1, match.range.location != NSNotFound else {
            return GitLogEntry(
                id: "\(index)|\(line)",
                graphPrefix: line,
                hash: "",
                decorations: nil,
                subject: ""
            )
        }
        let hashRange: NSRange = match.range
        let graphPrefix: String = nsLine.substring(to: hashRange.location)
        let hash: String = nsLine.substring(with: hashRange)
        let afterHashLocation: Int = hashRange.location + hashRange.length
        let rest: String = nsLine.substring(from: afterHashLocation)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if rest.hasPrefix("("), let closeIndex: String.Index = rest.firstIndex(of: ")") {
            let inner: String = String(rest[rest.index(after: rest.startIndex)..<closeIndex])
            let decorations: String? = inner.isEmpty ? nil : inner
            let afterClose: String.Index = rest.index(after: closeIndex)
            let subject: String = String(rest[afterClose...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return GitLogEntry(
                id: "\(index)|\(line)",
                graphPrefix: graphPrefix,
                hash: hash,
                decorations: decorations,
                subject: subject
            )
        }
        return GitLogEntry(
            id: "\(index)|\(line)",
            graphPrefix: graphPrefix,
            hash: hash,
            decorations: nil,
            subject: rest
        )
    }
}
