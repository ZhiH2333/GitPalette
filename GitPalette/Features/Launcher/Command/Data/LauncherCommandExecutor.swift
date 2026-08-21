//
//  LauncherCommandExecutor.swift
//  GitPalette
//
//  将已解析合法命令映射为对 Preferences / 窗口 / 面板的真实调用。
//

import AppKit
import Foundation

/// 命令执行结果。
enum LauncherCommandExecutionOutcome {
    /// 已执行且应关闭面板；可选择是否把焦点交还唤起前的应用
    case dismissed(shouldRestoreFocus: Bool)
    /// 已处理但保持面板（如 /help、参数非法）
    case keptOpen(message: String?)
    /// 退出应用（面板可不再关心）
    case quitApp
    /// 已执行且保持打开，切换到结果视图
    case presentingResult(GitResultViewModel)
}

/// 命令执行器。
@MainActor
final class LauncherCommandExecutor {
    private let preferences: PreferencesStore
    private let windowPresenter: AppWindowPresenter
    private let hotKeyService: HotKeyService
    private let gitRepositoryStore: GitRepositoryStore
    private let onClearRecent: () -> Void
    private let onReloadRecent: () -> Void
    private let onSuspendPanelResign: () -> Void
    private let onResumePanelResign: () -> Void

    /// 已链接仓库（供 /git use、/git unlink 建议列表）。
    func loadLinkedGitRepositories() -> [GitRepository] {
        gitRepositoryStore.loadRepositories()
    }

    /// 当前活跃仓库；未链接或路径失效时为 nil。
    func resolveActiveLinkedRepository() -> GitRepository? {
        try? gitRepositoryStore.resolveActiveRepository()
    }

    init(
        preferences: PreferencesStore,
        windowPresenter: AppWindowPresenter,
        hotKeyService: HotKeyService,
        gitRepositoryStore: GitRepositoryStore,
        onClearRecent: @escaping () -> Void,
        onReloadRecent: @escaping () -> Void,
        onSuspendPanelResign: @escaping () -> Void,
        onResumePanelResign: @escaping () -> Void
    ) {
        self.preferences = preferences
        self.windowPresenter = windowPresenter
        self.hotKeyService = hotKeyService
        self.gitRepositoryStore = gitRepositoryStore
        self.onClearRecent = onClearRecent
        self.onReloadRecent = onReloadRecent
        self.onSuspendPanelResign = onSuspendPanelResign
        self.onResumePanelResign = onResumePanelResign
    }

    /// 命令提示语言（跟随 desclang）。
    private var hintLanguage: AppLanguage {
        preferences.descriptionLanguage
    }

    /// 执行已解析且可执行的命令；非法时返回本地化提示并保持打开。
    func execute(
        parseResult: LauncherCommandParseResult
    ) -> LauncherCommandExecutionOutcome {
        guard parseResult.isCommandMode else {
            return .keptOpen(message: nil)
        }
        guard let command: LauncherCommand = parseResult.matchedCommand else {
            return .keptOpen(message: L10n.text(.cmdUnknownCommand, language: hintLanguage))
        }
        guard parseResult.isExecutable else {
            return .keptOpen(
                message: parseResult.validationMessage
                    ?? L10n.text(.cmdIncompleteArguments, language: hintLanguage)
            )
        }
        return executeCommand(command, argument: parseResult.rawArgumentText)
    }

    /// 分派具体命令。
    private func executeCommand(
        _ command: LauncherCommand,
        argument: String
    ) -> LauncherCommandExecutionOutcome {
        switch command {
        case .settings:
            let tab: SettingsTab = LauncherCommandParser.resolveSettingsTab(argument) ?? .general
            windowPresenter.executeOpenSettings(tab: tab)
            return .dismissed(shouldRestoreFocus: false)
        case .general:
            windowPresenter.executeOpenSettings(tab: .general)
            return .dismissed(shouldRestoreFocus: false)
        case .hotkey:
            windowPresenter.executeOpenSettings(tab: .hotkey)
            return .dismissed(shouldRestoreFocus: false)
        case .about:
            windowPresenter.executeOpenAbout()
            return .dismissed(shouldRestoreFocus: false)
        case .permissions:
            hotKeyService.executePresentPermissionGuide()
            windowPresenter.executeOpenPermissions()
            return .dismissed(shouldRestoreFocus: false)
        case .language:
            guard let language: AppLanguage = LauncherCommandParser.resolveLanguage(argument) else {
                return .keptOpen(message: L10n.text(.cmdUnsupportedLanguage, language: hintLanguage))
            }
            preferences.uiLanguage = language
            return .dismissed(shouldRestoreFocus: true)
        case .codelang:
            guard let language: AppLanguage = LauncherCommandParser.resolveLanguage(argument) else {
                return .keptOpen(message: L10n.text(.cmdUnsupportedLanguage, language: hintLanguage))
            }
            preferences.codeTranslationLanguage = language
            return .dismissed(shouldRestoreFocus: true)
        case .desclang:
            guard let language: AppLanguage = LauncherCommandParser.resolveLanguage(argument) else {
                return .keptOpen(message: L10n.text(.cmdUnsupportedLanguage, language: hintLanguage))
            }
            preferences.descriptionLanguage = language
            return .dismissed(shouldRestoreFocus: true)
        case .style:
            guard let style: AppearanceStyle =
                LauncherCommandParser.resolveAppearanceStyle(argument)
            else {
                return .keptOpen(message: L10n.text(.cmdUnsupportedStyle, language: hintLanguage))
            }
            preferences.appearanceStyle = style
            return .dismissed(shouldRestoreFocus: true)
        case .format:
            guard let format: CopyFormat = LauncherCommandParser.resolveCopyFormat(argument) else {
                return .keptOpen(message: L10n.text(.cmdUnsupportedFormat, language: hintLanguage))
            }
            preferences.copyFormat = format
            return .dismissed(shouldRestoreFocus: true)
        case .template:
            preferences.copyTemplate = argument
            return .dismissed(shouldRestoreFocus: true)
        case .recent:
            return executeRecent(argument)
        case .git:
            return executeGit(argument)
        case .menubar:
            guard let behavior: MenuBarClickBehavior =
                LauncherCommandParser.resolveMenuBarClickBehavior(argument)
            else {
                return .keptOpen(message: L10n.text(.cmdUnsupportedMenubarArg, language: hintLanguage))
            }
            preferences.menuBarClickBehavior = behavior
            return .dismissed(shouldRestoreFocus: true)
        case .quit:
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
            return .quitApp
        case .hide:
            return .dismissed(shouldRestoreFocus: true)
        case .help:
            windowPresenter.executeOpenSettings(tab: .commands)
            return .dismissed(shouldRestoreFocus: false)
        }
    }

    /// 执行 /recent 子命令。
    private func executeRecent(_ argument: String) -> LauncherCommandExecutionOutcome {
        let parts: [String] = argument.split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        guard let head: String = parts.first?.lowercased() else {
            return .keptOpen(message: L10n.text(.cmdNeedRecentSubcommand, language: hintLanguage))
        }
        if head == "clear" {
            onClearRecent()
            return .dismissed(shouldRestoreFocus: true)
        }
        if head == "count" {
            guard parts.count >= 2, let value: Int = Int(parts[1]) else {
                return .keptOpen(message: L10n.text(.cmdCountMustBeInteger, language: hintLanguage))
            }
            let lower: Int = PreferencesStore.recentMaxCountRange.lowerBound
            let upper: Int = PreferencesStore.recentMaxCountRange.upperBound
            preferences.recentMaxCount = min(max(value, lower), upper)
            onReloadRecent()
            return .dismissed(shouldRestoreFocus: true)
        }
        return .keptOpen(message: L10n.text(.cmdUnsupportedSubcommand, language: hintLanguage))
    }

    /// 执行 /git 子命令。
    private func executeGit(_ argument: String) -> LauncherCommandExecutionOutcome {
        let parsed: (subcommand: GitSubcommand?, isExecutable: Bool, message: String?) =
            GitSubcommand.executeParse(argument: argument, language: hintLanguage)
        guard parsed.isExecutable, let subcommand: GitSubcommand = parsed.subcommand else {
            return .keptOpen(message: parsed.message)
        }
        switch subcommand {
        case .link(let path):
            return executeGitLink(path: path)
        case .repos:
            return executePresentGitResult(kind: .repos)
        case .use(let name):
            return executeGitUse(name: name)
        case .unlink(let name):
            return executeGitUnlink(name: name)
        case .status:
            return executePresentGitResult(kind: .status)
        case .add:
            return executePresentGitResult(kind: .add)
        case .commit(let message):
            return executePresentGitResult(kind: .commit, commitMessage: message)
        }
    }

    /// 仅打开 commit 历史预览，不执行 git commit。
    func executeMakeCommitLogViewModel() -> GitResultViewModel {
        let viewModel: GitResultViewModel = GitResultViewModel(
            kind: .commit,
            store: gitRepositoryStore,
            language: hintLanguage,
            commitMessage: nil
        )
        viewModel.executeStart()
        return viewModel
    }

    /// 链接仓库（路径或文件夹选择器）。
    private func executeGitLink(path: String?) -> LauncherCommandExecutionOutcome {
        let resolvedPath: String?
        if let path, !path.isEmpty {
            resolvedPath = path
        } else {
            onSuspendPanelResign()
            resolvedPath = windowPresenter.executePickDirectory()
            onResumePanelResign()
            if resolvedPath == nil {
                return .keptOpen(message: nil)
            }
        }
        guard let resolvedPath else {
            return .keptOpen(message: nil)
        }
        do {
            let repository: GitRepository = try gitRepositoryStore.executeLink(path: resolvedPath)
            return .keptOpen(
                message: L10n.text(.gitLinkSucceeded, language: hintLanguage) + repository.displayName
            )
        } catch let error as GitCommandError {
            return .keptOpen(message: error.localizedMessage(language: hintLanguage))
        } catch {
            return .keptOpen(
                message: GitCommandError.processLaunchFailed(error.localizedDescription)
                    .localizedMessage(language: hintLanguage)
            )
        }
    }

    /// 切换当前仓库。
    private func executeGitUse(name: String) -> LauncherCommandExecutionOutcome {
        do {
            let repository: GitRepository = try gitRepositoryStore.executeUse(name: name)
            return .keptOpen(
                message: L10n.text(.gitUseSucceeded, language: hintLanguage) + repository.displayName
            )
        } catch let error as GitCommandError {
            return .keptOpen(message: error.localizedMessage(language: hintLanguage))
        } catch {
            return .keptOpen(
                message: GitCommandError.processLaunchFailed(error.localizedDescription)
                    .localizedMessage(language: hintLanguage)
            )
        }
    }

    /// 移除已链接仓库。
    private func executeGitUnlink(name: String) -> LauncherCommandExecutionOutcome {
        do {
            let outcome: GitUnlinkOutcome = try gitRepositoryStore.executeUnlink(name: name)
            if outcome.needsUse {
                return .keptOpen(
                    message: L10n.text(.gitUnlinkSucceeded, language: hintLanguage)
                        + outcome.removed.displayName
                        + "。 "
                        + L10n.text(.gitUnlinkNeedsUse, language: hintLanguage)
                )
            }
            let suffix: String
            if let next: GitRepository = outcome.newActive {
                suffix = L10n.text(.gitUseSucceeded, language: hintLanguage) + next.displayName
            } else {
                suffix = ""
            }
            return .keptOpen(
                message: L10n.text(.gitUnlinkSucceeded, language: hintLanguage)
                    + outcome.removed.displayName
                    + (suffix.isEmpty ? "" : "。 " + suffix)
            )
        } catch let error as GitCommandError {
            return .keptOpen(message: error.localizedMessage(language: hintLanguage))
        } catch {
            return .keptOpen(
                message: GitCommandError.processLaunchFailed(error.localizedDescription)
                    .localizedMessage(language: hintLanguage)
            )
        }
    }

    /// 打开结果视图并异步执行。
    private func executePresentGitResult(
        kind: GitResultKind,
        commitMessage: String? = nil
    ) -> LauncherCommandExecutionOutcome {
        let viewModel: GitResultViewModel = GitResultViewModel(
            kind: kind,
            store: gitRepositoryStore,
            language: hintLanguage,
            commitMessage: commitMessage
        )
        if kind == .commit, let commitMessage, !commitMessage.isEmpty {
            viewModel.executeConfirmCommit(message: commitMessage)
        } else {
            viewModel.executeStart()
        }
        return .presentingResult(viewModel)
    }
}
