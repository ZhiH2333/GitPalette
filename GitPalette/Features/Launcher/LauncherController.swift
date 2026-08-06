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
@Observable
final class LauncherController {
    private let appConfig: AppConfig
    private let recentStore: RecentGitmojiStore
    private let viewModel: GitmojiListViewModel
    private var panel: NSPanel?
    private var hostingController: NSHostingController<LauncherPanelContentView>?
    private var resignObserver: NSObjectProtocol?
    private var keyMonitor: Any?
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
        previousFrontApp = NSWorkspace.shared.frontmostApplication
        viewModel.executeResetForPresentation()
        focusToken = UUID()
        let panel: NSPanel = resolvePanel()
        executeRefreshHostingContent()
        LauncherPanelFactory.executeCenterOnMouseScreen(panel)
        executeRegisterResignObserver(for: panel)
        executeRegisterKeyMonitor()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
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
        panel?.orderOut(nil)
        isPresenting = false
        if shouldRestoreFocus {
            executeRestorePreviousAppFocus()
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

    /// 将焦点交还给唤起前的前台应用，避免 LSUIElement 残留抢焦。
    private func executeRestorePreviousAppFocus() {
        let previous: NSRunningApplication? = previousFrontApp
        previousFrontApp = nil
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
        let created: NSPanel = LauncherPanelFactory.makePanel()
        let hosting: NSHostingController<LauncherPanelContentView> = NSHostingController(
            rootView: buildContentView()
        )
        hosting.view.frame = NSRect(origin: .zero, size: LauncherPanelFactory.panelSize)
        hosting.view.autoresizingMask = [.width, .height]
        created.contentView = hosting.view
        self.panel = created
        self.hostingController = hosting
        return created
    }

    /// 刷新 Hosting 根视图（焦点令牌 / 回调）。
    private func executeRefreshHostingContent() {
        hostingController?.rootView = buildContentView()
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

    /// 将已显示面板置前并刷新焦点。
    private func executeBringToFront(_ panel: NSPanel) {
        focusToken = UUID()
        executeRefreshHostingContent()
        executeRegisterKeyMonitor()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
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

    /// 本地键盘监视：搜索框聚焦时仍保证 ↑↓ / Esc 可用。
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

    /// 处理面板内快捷键；返回 nil 表示已消费（唯一选中移动入口，避免与 SwiftUI 重复）。
    private func executeHandleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard isPresenting, panel?.isKeyWindow == true else {
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
        case 53:
            dismiss(shouldRestoreFocus: true)
            return nil
        default:
            return event
        }
    }
}
