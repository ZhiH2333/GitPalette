//
//  GitLogEntry.swift
//  GitPalette
//
//  git log --graph --oneline 的单行结构化结果。
//

import Foundation

/// 提交历史图中的一行（含纯 graph 连接行）。
struct GitLogEntry: Identifiable, Equatable, Sendable {
    let id: String
    let graphPrefix: String
    let hash: String
    let decorations: String?
    let subject: String
}
