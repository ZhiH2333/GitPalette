//
//  GitCommandError.swift
//  GitPalette
//
//  Git 命令本地错误。
//

import Foundation

/// Git 命令执行错误。
enum GitCommandError: Error, Equatable, LocalizedError {
    /// 尚未链接任何仓库
    case noLinkedRepository
    /// 路径不存在
    case pathDoesNotExist(String)
    /// 路径存在但不是 git 仓库
    case notGitRepository(String)
    /// 按名称找不到已链接仓库
    case repositoryNameNotFound(String)
    /// 启动 git 进程失败
    case processLaunchFailed(String)
    /// git 非零退出
    case nonZeroExit(exitCode: Int32, stderr: String)
    /// 没有已暂存改动
    case noStagedChanges
    /// 没有可暂存的选中路径
    case noSelectedPaths
    /// 仓库路径已失效
    case repositoryPathInvalid(String)

    /// 面向用户的本地化说明。
    func localizedMessage(language: AppLanguage) -> String {
        let isChinese: Bool = language == .simplifiedChinese
        switch self {
        case .noLinkedRepository:
            return isChinese
                ? "尚未链接任何仓库，请先执行 /git link"
                : "No repository linked. Run /git link first."
        case .pathDoesNotExist(let path):
            return (isChinese ? "路径不存在：" : "Path does not exist: ") + path
        case .notGitRepository(let path):
            return (isChinese ? "不是 Git 仓库：" : "Not a git repository: ") + path
        case .repositoryNameNotFound(let name):
            return (isChinese ? "未找到已链接仓库：" : "Linked repository not found: ") + name
        case .processLaunchFailed(let reason):
            return (isChinese ? "无法启动 git 进程：" : "Failed to start git: ") + reason
        case .nonZeroExit(_, let stderr):
            let trimmed: String = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            let prefix: String = isChinese ? "git 命令失败：" : "git command failed: "
            if trimmed.isEmpty {
                return prefix
            }
            return prefix + trimmed
        case .noStagedChanges:
            return isChinese ? "没有已暂存的改动，无法提交" : "No staged changes to commit."
        case .noSelectedPaths:
            return isChinese ? "请先用空格勾选要暂存的文件" : "Select files with Space before adding."
        case .repositoryPathInvalid(let path):
            return (isChinese ? "仓库路径已失效：" : "Repository path is no longer valid: ") + path
        }
    }

    var errorDescription: String? {
        localizedMessage(language: .simplifiedChinese)
    }
}
