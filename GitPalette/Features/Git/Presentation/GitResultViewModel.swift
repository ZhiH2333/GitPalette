//
//  GitResultViewModel.swift
//  GitPalette
//
//  「/git」执行后保持打开的结果面板状态。
//

import Foundation
import Combine

/// 结果视图类型。
enum GitResultKind: Equatable, Sendable {
    case status
    case add
    case commit
    case repos
}

/// 异步执行阶段。
enum GitResultPhase: Equatable, Sendable {
    case running
    case completed
    case failed
}

/// Git 命令结果 ViewModel。
@MainActor
final class GitResultViewModel: ObservableObject {
    /// 视图类型
    @Published private(set) var kind: GitResultKind
    /// 执行阶段
    @Published private(set) var phase: GitResultPhase = .running
    /// 结构化改动
    @Published private(set) var entries: [GitStatusEntry] = []
    /// add 模式下的选中路径
    @Published private(set) var selectedPaths: Set<String> = []
    /// 当前高亮行
    @Published var highlightedIndex: Int = 0
    /// 仓库列表（repos）
    @Published private(set) var repositories: [GitRepository] = []
    /// 当前活跃仓库 id
    @Published private(set) var activeRepositoryID: String?
    /// 空态 / 成功摘要
    @Published private(set) var summaryText: String?
    /// 错误文案
    @Published private(set) var errorMessage: String?
    private let store: GitRepositoryStore
    private let language: AppLanguage
    private var commitMessage: String?
    private var activeRepository: GitRepository?

    init(
        kind: GitResultKind,
        store: GitRepositoryStore,
        language: AppLanguage,
        commitMessage: String? = nil
    ) {
        self.kind = kind
        self.store = store
        self.language = language
        self.commitMessage = commitMessage
    }

    /// 是否处于 add 多选。
    var isAddMode: Bool {
        kind == .add && phase == .completed
    }

    /// 是否可对 Return 执行暂存。
    var canConfirmAdd: Bool {
        isAddMode && !selectedPaths.isEmpty
    }

    /// 启动对应加载。
    func executeStart() {
        switch kind {
        case .status:
            Task { await executeLoadStatus() }
        case .add:
            Task { await executeLoadStatus() }
        case .commit:
            Task { await executeCommit() }
        case .repos:
            executeLoadRepos()
        }
    }

    /// ↑ 高亮上一行。
    func executeSelectPrevious() {
        guard !entries.isEmpty else {
            return
        }
        highlightedIndex = max(highlightedIndex - 1, 0)
    }

    /// ↓ 高亮下一行。
    func executeSelectNext() {
        guard !entries.isEmpty else {
            return
        }
        highlightedIndex = min(highlightedIndex + 1, entries.count - 1)
    }

    /// Space 切换当前行选中。
    func executeToggleHighlightedSelection() {
        guard isAddMode, entries.indices.contains(highlightedIndex) else {
            return
        }
        let path: String = entries[highlightedIndex].relativePath
        if selectedPaths.contains(path) {
            selectedPaths.remove(path)
        } else {
            selectedPaths.insert(path)
        }
    }

    /// 全选当前列表路径。
    func executeSelectAll() {
        guard isAddMode else {
            return
        }
        selectedPaths = Set(entries.map(\.relativePath))
    }

    /// 点击行：高亮；add 模式下同时切换选中。
    func executeActivateRow(at index: Int) {
        guard entries.indices.contains(index) else {
            return
        }
        highlightedIndex = index
    }

    /// Return：对选中路径 git add 后刷新 status。
    func executeConfirmAdd() {
        guard isAddMode else {
            return
        }
        Task { await executeStageSelected() }
    }

    /// 加载工作区状态。
    private func executeLoadStatus() async {
        phase = .running
        errorMessage = nil
        summaryText = nil
        do {
            let repository: GitRepository = try store.resolveActiveRepository()
            activeRepository = repository
            let result: GitProcessResult = try await GitProcessRunner.executeRun(
                repositoryPath: repository.path,
                arguments: ["status", "--porcelain=v1"]
            )
            if result.exitCode != 0 {
                throw GitCommandError.nonZeroExit(exitCode: result.exitCode, stderr: result.stderr)
            }
            entries = GitStatusParser.executeParse(result.stdout)
            highlightedIndex = 0
            if kind == .add {
                selectedPaths = []
            }
            if entries.isEmpty {
                summaryText = L10n.text(.gitWorkingTreeClean, language: language)
            }
            phase = .completed
        } catch let error as GitCommandError {
            phase = .failed
            errorMessage = error.localizedMessage(language: language)
        } catch {
            phase = .failed
            errorMessage = GitCommandError.processLaunchFailed(error.localizedDescription)
                .localizedMessage(language: language)
        }
    }

    /// 暂存选中路径。
    private func executeStageSelected() async {
        guard let repository: GitRepository = activeRepository else {
            errorMessage = GitCommandError.noLinkedRepository.localizedMessage(language: language)
            phase = .failed
            return
        }
        let paths: [String] = entries
            .map(\.relativePath)
            .filter { selectedPaths.contains($0) }
        if paths.isEmpty {
            summaryText = GitCommandError.noSelectedPaths.localizedMessage(language: language)
            return
        }
        phase = .running
        errorMessage = nil
        do {
            try store.executeValidateRepositoryStillValid(repository)
            var arguments: [String] = ["add", "--"]
            arguments.append(contentsOf: paths)
            let result: GitProcessResult = try await GitProcessRunner.executeRun(
                repositoryPath: repository.path,
                arguments: arguments
            )
            if result.exitCode != 0 {
                throw GitCommandError.nonZeroExit(exitCode: result.exitCode, stderr: result.stderr)
            }
            await executeLoadStatus()
        } catch let error as GitCommandError {
            phase = .failed
            errorMessage = error.localizedMessage(language: language)
        } catch {
            phase = .failed
            errorMessage = GitCommandError.processLaunchFailed(error.localizedDescription)
                .localizedMessage(language: language)
        }
    }

    /// 仅本地 commit。
    private func executeCommit() async {
        phase = .running
        errorMessage = nil
        summaryText = nil
        let message: String = commitMessage ?? ""
        do {
            let repository: GitRepository = try store.resolveActiveRepository()
            activeRepository = repository
            let statusResult: GitProcessResult = try await GitProcessRunner.executeRun(
                repositoryPath: repository.path,
                arguments: ["status", "--porcelain=v1"]
            )
            if statusResult.exitCode != 0 {
                throw GitCommandError.nonZeroExit(exitCode: statusResult.exitCode, stderr: statusResult.stderr)
            }
            let statusEntries: [GitStatusEntry] = GitStatusParser.executeParse(statusResult.stdout)
            let stagedCount: Int = statusEntries.filter(\.isStaged).count
            if stagedCount == 0 {
                throw GitCommandError.noStagedChanges
            }
            let commitResult: GitProcessResult = try await GitProcessRunner.executeRun(
                repositoryPath: repository.path,
                arguments: ["commit", "-m", message]
            )
            if commitResult.exitCode != 0 {
                throw GitCommandError.nonZeroExit(exitCode: commitResult.exitCode, stderr: commitResult.stderr)
            }
            let hashResult: GitProcessResult = try await GitProcessRunner.executeRun(
                repositoryPath: repository.path,
                arguments: ["rev-parse", "--short", "HEAD"]
            )
            let hash: String = hashResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            summaryText = L10n.text(.gitCommitSucceeded, language: language)
                + "\(stagedCount)"
                + L10n.text(.gitCommitFileCountSuffix, language: language)
                + hash
            entries = []
            phase = .completed
        } catch let error as GitCommandError {
            phase = .failed
            errorMessage = error.localizedMessage(language: language)
        } catch {
            phase = .failed
            errorMessage = GitCommandError.processLaunchFailed(error.localizedDescription)
                .localizedMessage(language: language)
        }
    }

    /// 同步加载已链接仓库列表。
    private func executeLoadRepos() {
        phase = .running
        errorMessage = nil
        let loaded: [GitRepository] = store.loadRepositories()
        repositories = loaded
        if loaded.isEmpty {
            summaryText = L10n.text(.gitErrorNoLinkedRepository, language: language)
            activeRepositoryID = nil
            phase = .completed
            return
        }
        do {
            let active: GitRepository = try store.resolveActiveRepository()
            activeRepositoryID = active.id
        } catch {
            activeRepositoryID = nil
        }
        summaryText = nil
        phase = .completed
    }
}
