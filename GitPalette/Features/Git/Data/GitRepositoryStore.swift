//
//  GitRepositoryStore.swift
//  GitPalette
//
//  已链接仓库列表与当前仓库（UserDefaults 路径字符串；接口可替换为书签）。
//

import Foundation

/// 已链接 Git 仓库持久化。
final class GitRepositoryStore {
    private let defaults: UserDefaults
    private let repositoriesKey: String
    private let activeIDKey: String
    private let fileManager: FileManager

    init(
        defaults: UserDefaults = .standard,
        repositoriesKey: String = PreferencesKeys.linkedGitRepositories,
        activeIDKey: String = PreferencesKeys.activeGitRepositoryID,
        fileManager: FileManager = .default
    ) {
        self.defaults = defaults
        self.repositoriesKey = repositoriesKey
        self.activeIDKey = activeIDKey
        self.fileManager = fileManager
    }

    /// 读取已链接仓库（每次校验路径与 .git；失效项仍保留以便提示）。
    func loadRepositories() -> [GitRepository] {
        executeLoadRawRepositories()
    }

    /// 当前活跃仓库；未链接或名称无法解析时抛错。
    func resolveActiveRepository() throws -> GitRepository {
        let repositories: [GitRepository] = executeLoadRawRepositories()
        if repositories.isEmpty {
            throw GitCommandError.noLinkedRepository
        }
        let activeID: String? = defaults.string(forKey: activeIDKey)
        let selected: GitRepository?
        if let activeID {
            selected = repositories.first(where: { $0.id == activeID })
        } else {
            selected = repositories.first
        }
        guard let repository: GitRepository = selected else {
            throw GitCommandError.noLinkedRepository
        }
        try executeValidateRepositoryStillValid(repository)
        return repository
    }

    /// 链接本地路径；非 git 仓库不写入。
    func executeLink(path: String) throws -> GitRepository {
        let expanded: String = executeNormalizeUserPath(path)
        let standardized: String = URL(fileURLWithPath: expanded).standardizedFileURL.path
        try executeValidateGitDirectory(at: standardized)
        var repositories: [GitRepository] = executeLoadRawRepositories()
        if let existing: GitRepository = repositories.first(where: { $0.path == standardized }) {
            defaults.set(existing.id, forKey: activeIDKey)
            return existing
        }
        let url: URL = URL(fileURLWithPath: standardized)
        let repository: GitRepository = GitRepository(
            id: UUID().uuidString,
            displayName: url.lastPathComponent,
            resolvablePath: GitResolvablePath(storedValue: standardized)
        )
        repositories.append(repository)
        executeSave(repositories: repositories)
        defaults.set(repository.id, forKey: activeIDKey)
        return repository
    }

    /// 按展示名切换当前仓库。
    func executeUse(name: String) throws -> GitRepository {
        let repositories: [GitRepository] = executeLoadRawRepositories()
        guard let repository: GitRepository = executeFindRepository(named: name, in: repositories) else {
            throw GitCommandError.repositoryNameNotFound(name)
        }
        try executeValidateRepositoryStillValid(repository)
        defaults.set(repository.id, forKey: activeIDKey)
        return repository
    }

    /// 按展示名移除；若移除当前活跃项则切到列表首个。
    func executeUnlink(name: String) throws -> GitUnlinkOutcome {
        var repositories: [GitRepository] = executeLoadRawRepositories()
        guard let index: Int = executeFindRepositoryIndex(named: name, in: repositories) else {
            throw GitCommandError.repositoryNameNotFound(name)
        }
        let removed: GitRepository = repositories.remove(at: index)
        executeSave(repositories: repositories)
        let previousActive: String? = defaults.string(forKey: activeIDKey)
        let didRemoveActive: Bool = previousActive == removed.id || previousActive == nil
        if repositories.isEmpty {
            defaults.removeObject(forKey: activeIDKey)
            return GitUnlinkOutcome(removed: removed, newActive: nil, needsUse: true)
        }
        if didRemoveActive {
            let next: GitRepository = repositories[0]
            defaults.set(next.id, forKey: activeIDKey)
            return GitUnlinkOutcome(removed: removed, newActive: next, needsUse: false)
        }
        return GitUnlinkOutcome(removed: removed, newActive: repositories.first(where: { $0.id == previousActive }), needsUse: false)
    }

    /// 校验目录存在且包含 .git。
    func executeValidateGitDirectory(at path: String) throws {
        var isDirectory: ObjCBool = false
        let exists: Bool = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        if !exists || !isDirectory.boolValue {
            throw GitCommandError.pathDoesNotExist(path)
        }
        let gitURL: URL = URL(fileURLWithPath: path).appendingPathComponent(".git")
        if !fileManager.fileExists(atPath: gitURL.path) {
            throw GitCommandError.notGitRepository(path)
        }
    }

    /// 路径与 .git 是否仍有效。
    func executeValidateRepositoryStillValid(_ repository: GitRepository) throws {
        do {
            try executeValidateGitDirectory(at: repository.path)
        } catch GitCommandError.pathDoesNotExist {
            throw GitCommandError.repositoryPathInvalid(repository.path)
        } catch GitCommandError.notGitRepository {
            throw GitCommandError.repositoryPathInvalid(repository.path)
        }
    }

    /// 去掉用户输入的成对引号并展开 ~。
    private func executeNormalizeUserPath(_ path: String) -> String {
        var trimmed: String = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 2 {
            let hasDoubleQuotes: Bool = trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"")
            let hasSingleQuotes: Bool = trimmed.hasPrefix("'") && trimmed.hasSuffix("'")
            if hasDoubleQuotes || hasSingleQuotes {
                trimmed = String(trimmed.dropFirst().dropLast())
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return (trimmed as NSString).expandingTildeInPath
    }

    /// 解码持久化列表。
    private func executeLoadRawRepositories() -> [GitRepository] {
        guard let data: Data = defaults.data(forKey: repositoriesKey) else {
            return []
        }
        let decoded: [GitRepository]? = try? JSONDecoder().decode([GitRepository].self, from: data)
        return decoded ?? []
    }

    /// 写入列表。
    private func executeSave(repositories: [GitRepository]) {
        guard let data: Data = try? JSONEncoder().encode(repositories) else {
            return
        }
        defaults.set(data, forKey: repositoriesKey)
    }

    /// 按名称（不区分大小写）查找。
    private func executeFindRepository(named name: String, in repositories: [GitRepository]) -> GitRepository? {
        let lower: String = name.lowercased()
        return repositories.first { $0.displayName.lowercased() == lower || $0.id == name }
    }

    /// 按名称查找下标。
    private func executeFindRepositoryIndex(named name: String, in repositories: [GitRepository]) -> Int? {
        let lower: String = name.lowercased()
        return repositories.firstIndex { $0.displayName.lowercased() == lower || $0.id == name }
    }
}

/// 移除仓库后的后续状态。
struct GitUnlinkOutcome: Equatable, Sendable {
    let removed: GitRepository
    let newActive: GitRepository?
    let needsUse: Bool
}
