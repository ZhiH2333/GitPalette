//
//  LauncherController.swift
//  GitPalette
//
//  启动器浮动面板控制器：present / dismiss / toggle。
//

import AppKit
import SwiftUI

/// 启动器面板控制器（主线程 API）。
@MainActor
final class LauncherController {
    private let appConfig: AppConfig
    private let recentStore: RecentGitmojiStore
    private let gitRepositoryStore: GitRepositoryStore
    private let viewModel: GitmojiListViewModel
    private let commandViewModel: LauncherCommandViewModel
    private var panel: NSPanel?
    private var hostingView: TransparentHostingView?
    private var resignObserver: NSObjectProtocol?
    private var keyMonitor: Any?
    private var activationObserver: NSObjectProtocol?
    private var focusToken: UUID = UUID()
    private var isPresenting: Bool = false
    private var previousFrontApp: NSRunningApplication?
    private let resignGate: ResignGate = ResignGate()

    init(
        appConfig: AppConfig,
        recentStore: RecentGitmojiStore,
        hotKeyService: HotKeyService,
        windowPresenter: AppWindowPresenter,
        repository: GitmojiRepository? = nil
    ) {
        self.appConfig = appConfig
        self.recentStore = recentStore
        let gitRepositoryStore: GitRepositoryStore = GitRepositoryStore()
        self.gitRepositoryStore = gitRepositoryStore
        let resolvedRepository: GitmojiRepository =
            repository ?? ((try? BundleGitmojiRepository()) ?? EmptyGitmojiRepository())
        let listViewModel: GitmojiListViewModel = GitmojiListViewModel(
            repository: resolvedRepository,
            recentStore: recentStore,
            appConfig: appConfig
        )
        self.viewModel = listViewModel
        let executor: LauncherCommandExecutor = LauncherCommandExecutor(
            preferences: appConfig,
            windowPresenter: windowPresenter,
            hotKeyService: hotKeyService,
            gitRepositoryStore: gitRepositoryStore,
            onClearRecent: {
                recentStore.executeClear()
                listViewModel.executeReloadRecentItems()
            },
            onReloadRecent: {
                listViewModel.executeReloadRecentItems()
            },
            onSuspendPanelResign: { [resignGate] in
                resignGate.isSuspended = true
            },
            onResumePanelResign: { [resignGate] in
                resignGate.isSuspended = false
            }
        )
        self.commandViewModel = LauncherCommandViewModel(executor: executor, preferences: appConfig)
        executeRegisterFrontAppTracker()
    }

    /// 清空最近使用并刷新已打开面板。
    func executeClearRecentItems() {
        recentStore.executeClear()
        viewModel.executeReloadRecentItems()
        if isPresenting {
            executeRefreshHostingContent()
        }
    }

    /// 在最近数量变更后裁剪并刷新。
    func executeReloadRecentItems() {
        viewModel.executeReloadRecentItems()
        if isPresenting {
            executeRefreshHostingContent()
        }
    }

    /// 打开面板并聚焦搜索框。
    func present() {
        assert(Thread.isMainThread)
        if isPresenting, let panel, panel.isVisible {
            executeBringToFront(panel)
            return
        }
        executeCapturePreviousFrontAppIfNeeded()
        viewModel.executeResetForPresentation()
        commandViewModel.executeReset()
        focusToken = UUID()
        let panel: NSPanel = resolvePanel()
        executeSyncPanelSize(panel)
        executeRefreshHostingContent()
        LauncherPanelFactory.executeCenterOnMouseScreen(panel)
        executeRegisterResignObserver(for: panel)
        executeRegisterKeyMonitor()
        NSApp.activate(ignoringOtherApps: true)
        LauncherPanelFactory.executePresentAnimated(panel)
        isPresenting = true
    }

    /// 关闭面板。
    /// - Parameter shouldRestoreFocus: 是否把焦点交还唤起前的应用（失焦关闭时为 false）。
    func dismiss(shouldRestoreFocus: Bool = true) {
        assert(Thread.isMainThread)
        guard isPresenting || panel?.isVisible == true else {
            return
        }
        executeUnregisterKeyMonitor()
        executeUnregisterResignObserver()
        panel?.makeFirstResponder(nil)
        if let panel {
            LauncherPanelFactory.executeDismissAnimated(panel)
        }
        isPresenting = false
        if shouldRestoreFocus {
            let previous: NSRunningApplication? = previousFrontApp
            previousFrontApp = nil
            let delay: TimeInterval = LauncherPanelFactory.resolveDismissFocusDelay()
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.executeRestoreAppFocus(previous)
            }
        } else {
            previousFrontApp = nil
        }
    }

    /// 切换面板显隐。
    func toggle() {
        assert(Thread.isMainThread)
        if isPresenting, panel?.isVisible == true {
            dismiss(shouldRestoreFocus: true)
        } else {
            present()
        }
    }

    /// 复制选中项或执行命令；无结果时保持打开。
    private func executeConfirmCopy() {
        if commandViewModel.isCommandMode {
            executeConfirmCommand()
            return
        }
        let didCopy: Bool = viewModel.copySelected()
        if didCopy {
            dismiss(shouldRestoreFocus: true)
        }
    }

    /// 执行当前斜杠命令。
    private func executeConfirmCommand() {
        if let gitResult: GitResultViewModel = commandViewModel.gitResultViewModel {
            if gitResult.isAddMode {
                gitResult.executeConfirmAdd()
                return
            }
            if gitResult.kind == .status {
                gitResult.executeStart()
                return
            }
            return
        }
        let outcome: LauncherCommandExecutionOutcome =
            commandViewModel.executeConfirm(query: viewModel.query)
        switch outcome {
        case .dismissed(let shouldRestoreFocus):
            dismiss(shouldRestoreFocus: shouldRestoreFocus)
        case .quitApp:
            dismiss(shouldRestoreFocus: false)
        case .keptOpen:
            executeRefreshHostingContent()
        case .presentingResult:
            executeRefreshHostingContent()
        }
    }

    /// Tab 补全命令。
    private func executeCompleteCommand(current: String) -> String? {
        guard current.hasPrefix("/") else {
            return nil
        }
        commandViewModel.executeUpdateQuery(current)
        guard let completed: String = commandViewModel.executeComplete(query: current) else {
            return nil
        }
        // 由 SearchField Coordinator 写回 text；此处先写 query 会触发 stringValue 赋值并全选。
        commandViewModel.executeUpdateQuery(completed)
        return completed
    }

    /// 持续记住「非自身」的前台 App。
    private func executeRegisterFrontAppTracker() {
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app: NSRunningApplication =
                notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            else {
                return
            }
            guard app.processIdentifier != NSRunningApplication.current.processIdentifier else {
                return
            }
            Task { @MainActor in
                guard let self, !self.isPresenting else {
                    return
                }
                self.previousFrontApp = app
            }
        }
        executeCapturePreviousFrontAppIfNeeded()
    }

    /// 若当前前台不是自身，则更新 previousFrontApp。
    private func executeCapturePreviousFrontAppIfNeeded() {
        guard let front: NSRunningApplication = NSWorkspace.shared.frontmostApplication else {
            return
        }
        guard front.processIdentifier != NSRunningApplication.current.processIdentifier else {
            return
        }
        previousFrontApp = front
    }

    /// 激活指定应用（若仍有效且非自身）。
    private func executeRestoreAppFocus(_ previous: NSRunningApplication?) {
        guard let previous, previous.processIdentifier != NSRunningApplication.current.processIdentifier else {
            return
        }
        previous.activate()
    }

    /// 获取或创建面板。
    private func resolvePanel() -> NSPanel {
        if let panel {
            return panel
        }
        let created: LauncherPanel = LauncherPanelFactory.makePanel()
        let hosting: TransparentHostingView = TransparentHostingView(
            rootView: buildContentView()
        )
        hosting.frame = NSRect(origin: .zero, size: LauncherPanelFactory.panelSize)
        hosting.autoresizingMask = [.width, .height]
        created.contentView = hosting
        created.onCancelOperation = { [weak self] in
            self?.dismiss(shouldRestoreFocus: true)
        }
        self.panel = created
        self.hostingView = hosting
        return created
    }

    /// 刷新 Hosting 根视图（焦点令牌 / 回调）。
    private func executeRefreshHostingContent() {
        hostingView?.executeSetRootView(buildContentView())
    }

    /// 构建面板 SwiftUI 内容。
    private func buildContentView() -> LauncherPanelContentView {
        LauncherPanelContentView(
            appConfig: appConfig,
            viewModel: viewModel,
            commandViewModel: commandViewModel,
            focusToken: focusToken,
            onDismiss: { [weak self] in
                self?.dismiss(shouldRestoreFocus: true)
            },
            onDismissWithoutFocusRestore: { [weak self] in
                self?.dismiss(shouldRestoreFocus: false)
            },
            onConfirmCopy: { [weak self] in
                self?.executeConfirmCopy()
            },
            onRequestComplete: { [weak self] current in
                self?.executeCompleteCommand(current: current)
            }
        )
    }

    /// 同步面板与 Hosting 尺寸到当前 Chrome 常量。
    private func executeSyncPanelSize(_ panel: NSPanel) {
        let size: NSSize = LauncherPanelFactory.panelSize
        hostingView?.frame = NSRect(origin: .zero, size: size)
        panel.setContentSize(size)
    }

    /// 将已显示面板置前并刷新焦点。
    private func executeBringToFront(_ panel: NSPanel) {
        focusToken = UUID()
        executeRefreshHostingContent()
        executeRegisterKeyMonitor()
        NSApp.activate(ignoringOtherApps: true)
        LauncherPanelFactory.executePresentAnimated(panel)
    }

    /// 监听失焦以关闭面板。
    private func executeRegisterResignObserver(for panel: NSPanel) {
        executeUnregisterResignObserver()
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.resignGate.isSuspended else {
                    return
                }
                self.dismiss(shouldRestoreFocus: false)
            }
        }
    }

    /// 移除失焦监听。
    private func executeUnregisterResignObserver() {
        if let resignObserver {
            NotificationCenter.default.removeObserver(resignObserver)
            self.resignObserver = nil
        }
    }

    /// 本地键盘监视：仅处理 ↑↓。Esc 必须交给响应链（TextField doCommandBy），否则会 NSBeep。
    private func executeRegisterKeyMonitor() {
        executeUnregisterKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.executeHandleKeyEvent(event) ?? event
        }
    }

    /// 移除键盘监视。
    private func executeUnregisterKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    /// 将 ↑↓ 选中的命令补全写入输入框（实文本，而非半透明 ghost）。
    private func executeApplyCommandSelection(_ completed: String?) {
        guard let completed, completed != viewModel.query else {
            return
        }
        // 先标记跳过建议重建，再写 query（onChange → executeUpdateQuery）。
        commandViewModel.executeBeginArrowCompletionApply()
        viewModel.query = completed
    }

    /// 处理 ↑↓←→；命令模式下仅 ↑↓，不进入最近使用区逻辑。
    private func executeHandleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard isPresenting, panel?.isKeyWindow == true else {
            return event
        }
        if event.keyCode == 53 {
            return event
        }
        if event.modifierFlags.contains(.command)
            || event.modifierFlags.contains(.option)
            || event.modifierFlags.contains(.control) {
            return event
        }
        if let gitResult: GitResultViewModel = commandViewModel.gitResultViewModel {
            return executeHandleGitResultKey(event, gitResult: gitResult)
        }
        let isCommandMode: Bool = viewModel.query.hasPrefix("/")
        switch event.keyCode {
        case 126:
            if isCommandMode {
                executeApplyCommandSelection(
                    commandViewModel.executeSelectPrevious()
                )
            } else {
                viewModel.executeSelectPrevious()
            }
            return nil
        case 125:
            if isCommandMode {
                executeApplyCommandSelection(
                    commandViewModel.executeSelectNext()
                )
            } else {
                viewModel.executeSelectNext()
            }
            return nil
        case 123:
            guard !isCommandMode, viewModel.selectionFocus == .recent else {
                return event
            }
            viewModel.executeSelectLeft()
            return nil
        case 124:
            guard !isCommandMode, viewModel.selectionFocus == .recent else {
                return event
            }
            viewModel.executeSelectRight()
            return nil
        default:
            return event
        }
    }

    /// Git 结果视图下的方向键 / Space / 全选。
    private func executeHandleGitResultKey(
        _ event: NSEvent,
        gitResult: GitResultViewModel
    ) -> NSEvent? {
        switch event.keyCode {
        case 126:
            gitResult.executeSelectPrevious()
            return nil
        case 125:
            gitResult.executeSelectNext()
            return nil
        default:
            // Space / A 在 git add 模式下由 GitmojiSearchField 的
            // controlTextDidChange 拦截并转为勾选 / 全选（详见该文件注释），
            // 这里不再重复处理，避免 delegate 链路与本地监视双重触发。
            return event
        }
    }

    /// 打开系统文件夹选择器时暂停面板失焦关闭。
    private final class ResignGate {
        var isSuspended: Bool = false
    }
}
