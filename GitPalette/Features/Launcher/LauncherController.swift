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
    private let viewModel: GitmojiListViewModel
    private var panel: NSPanel?
    private var hostingController: NSHostingController<LauncherPanelContentView>?
    private var resignObserver: NSObjectProtocol?
    private var keyMonitor: Any?
    private var focusToken: UUID = UUID()
    private var isPresenting: Bool = false

    init(appConfig: AppConfig, repository: GitmojiRepository? = nil) {
        self.appConfig = appConfig
        let resolvedRepository: GitmojiRepository =
            repository ?? ((try? BundleGitmojiRepository()) ?? EmptyGitmojiRepository())
        self.viewModel = GitmojiListViewModel(
            repository: resolvedRepository,
            appConfig: appConfig
        )
    }

    /// 打开面板并聚焦搜索框。
    func present() {
        assert(Thread.isMainThread)
        if isPresenting, let panel, panel.isVisible {
            executeBringToFront(panel)
            return
        }
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
    func dismiss() {
        assert(Thread.isMainThread)
        guard isPresenting || panel?.isVisible == true else {
            return
        }
        executeUnregisterKeyMonitor()
        executeUnregisterResignObserver()
        panel?.orderOut(nil)
        isPresenting = false
    }

    /// 切换面板显隐。
    func toggle() {
        assert(Thread.isMainThread)
        if isPresenting, panel?.isVisible == true {
            dismiss()
        } else {
            present()
        }
    }

    /// 复制选中项并关闭；无结果时保持打开。
    private func executeConfirmCopy() {
        let didCopy: Bool = viewModel.copySelected()
        if didCopy {
            dismiss()
        }
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
                self?.dismiss()
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
                self?.dismiss()
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
            dismiss()
            return nil
        default:
            return event
        }
    }
}
