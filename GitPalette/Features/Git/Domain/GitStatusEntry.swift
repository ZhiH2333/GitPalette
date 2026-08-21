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
    case conflicted
    case copied

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
        case .conflicted:
            return "UU"
        case .copied:
            return "C"
        }
    }

    /// 状态名（跟随描述语言）。
    func displayName(language: AppLanguage) -> String {
        switch self {
        case .modified:
            return L10n.text(.gitStatusModified, language: language)
        case .added:
            return L10n.text(.gitStatusAdded, language: language)
        case .deleted:
            return L10n.text(.gitStatusDeleted, language: language)
        case .untracked:
            return L10n.text(.gitStatusUntracked, language: language)
        case .renamed:
            return L10n.text(.gitStatusRenamed, language: language)
        case .conflicted:
            return L10n.text(.gitStatusConflicted, language: language)
        case .copied:
            return L10n.text(.gitStatusCopied, language: language)
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
