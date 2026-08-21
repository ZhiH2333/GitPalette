//
//  GitStatusEntry.swift
//  GitPalette
//
//  git status --porcelain 的结构化条目。
//

import Foundation

/// 工作区文件状态类型。
enum GitStatusKind: String, Equatable, Sendable {
    case modified
    case added
    case deleted
    case untracked
    case renamed

    /// porcelain 风格短标记。
    var porcelainMark: String {
        switch self {
        case .modified:
            return "M"
        case .added:
            return "A"
        case .deleted:
            return "D"
        case .untracked:
            return "??"
        case .renamed:
            return "R"
        }
    }

    /// 状态名（跟随描述语言）。
    func displayName(language: AppLanguage) -> String {
        let isChinese: Bool = language == .simplifiedChinese
        switch self {
        case .modified:
            return isChinese ? "已修改" : "Modified"
        case .added:
            return isChinese ? "新增" : "Added"
        case .deleted:
            return isChinese ? "已删除" : "Deleted"
        case .untracked:
            return isChinese ? "未跟踪" : "Untracked"
        case .renamed:
            return isChinese ? "已重命名" : "Renamed"
        }
    }
}

/// 单条工作区改动。
struct GitStatusEntry: Identifiable, Equatable, Sendable {
    /// 相对仓库根的路径（重命名时为新路径）
    let relativePath: String
    /// 状态类型
    let kind: GitStatusKind
    /// 索引区（X）非空且非 `?` 时视为已暂存
    let isStaged: Bool
    /// 重命名前的原路径
    let originalPath: String?

    var id: String {
        if let originalPath {
            return originalPath + " -> " + relativePath
        }
        return relativePath
    }
}
