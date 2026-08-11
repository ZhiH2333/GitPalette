//
//  LauncherCommandExecutor.swift
//  GitPalette
//
//  将已解析合法命令映射为对 Preferences / 窗口 / 面板的真实调用。
//

import AppKit
import Foundation

/// 命令执行结果。
enum LauncherCommandExecutionOutcome: Equatable, Sendable {
    /// 已执行且应关闭面板；可选择是否把焦点交还唤起前的应用
    case dismissed(shouldRestoreFocus: Bool)
    /// 已处理但保持面板（如 /help、参数非法）
    case keptOpen(message: String?)
    /// 退出应用（面板可不再关心）
    case quitApp
}

/// 命令执行器。
@MainActor
final class LauncherCommandExecutor {
    private let preferences: PreferencesStore
    private let windowPresenter: AppWindowPresenter
    private let hotKeyService: HotKeyService
    private let onClearRecent: () -> Void
    private let onReloadRecent: () -> Void

    init(
        preferences: PreferencesStore,
        windowPresenter: AppWindowPresenter,
        hotKeyService: HotKeyService,
        onClearRecent: @escaping () -> Void,
        onReloadRecent: @escaping () -> Void
    ) {
        self.preferences = preferences
        self.windowPresenter = windowPresenter
        self.hotKeyService = hotKeyService
        self.onClearRecent = onClearRecent
        self.onReloadRecent = onReloadRecent
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
}
