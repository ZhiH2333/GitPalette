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
    private let viewModel: GitmojiListViewModel
    private var panel: NSPanel?
    private var hostingView: TransparentHostingView<LauncherPanelContentView>?
    private var resignObserver: NSObjectProtocol?
    private var keyMonitor: Any?
    private var activationObserver: NSObjectProtocol?
    private var focusToken: UUID = UUID()
    private var isPresenting: Bool = false
    private var previousFrontApp: NSRunningApplication?

    init(
        appConfig: AppConfig,
        recentStore: RecentGitmojiStore,
        repository: GitmojiRepository? = nil
    ) {
        self.appConfig = appConfig
        self.recentStore = recentStore
        let resolvedRepository: GitmojiRepository =
            repository ?? ((try? BundleGitmojiRepository()) ?? EmptyGitmojiRepository())
        self.viewModel = GitmojiListViewModel(
            repository: resolvedRepository,
            recentStore: recentStore,
            appConfig: appConfig
        )
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

    /// 复制选中项并关闭；无结果时保持打开。
    private func executeConfirmCopy() {
        let didCopy: Bool = viewModel.copySelected()
        if didCopy {
            dismiss(shouldRestoreFocus: true)
        }
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
        let hosting: TransparentHostingView<LauncherPanelContentView> = TransparentHostingView(
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
        hostingView?.rootView = buildContentView()
    }

    /// 构建面板 SwiftUI 内容。
    private func buildContentView() -> LauncherPanelContentView {
        LauncherPanelContentView(
            appConfig: appConfig,
            viewModel: viewModel,
            focusToken: focusToken,
            onDismiss: { [weak self] in
                self?.dismiss(shouldRestoreFocus: true)
            },
            onConfirmCopy: { [weak self] in
                self?.executeConfirmCopy()
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
                self?.dismiss(shouldRestoreFocus: false)
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

    /// 处理 ↑↓←→；Esc 原样放行给字段编辑器。
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
        switch event.keyCode {
        case 126:
            viewModel.executeSelectPrevious()
            return nil
        case 125:
            viewModel.executeSelectNext()
            return nil
        case 123:
            guard viewModel.selectionFocus == .recent else {
                return event
            }
            viewModel.executeSelectLeft()
            return nil
        case 124:
            guard viewModel.selectionFocus == .recent else {
                return event
            }
            viewModel.executeSelectRight()
            return nil
        default:
            return event
        }
    }
}
