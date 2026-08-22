//
//  AppDelegate.swift
//  GitPalette
//
//  处理冷启动与从启动台 / Finder 再次打开：立刻唤起启动器。
//

import AppKit

/// 应用级打开 / 再打开事件（启动台点击已在后台的应用也会走到这里）。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var launcherController: LauncherController?
    private var isPresentScheduled: Bool = false

    /// 绑定启动器控制器（须在 didFinishLaunching 前完成）。
    func executeAttach(launcherController: LauncherController) {
        self.launcherController = launcherController
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        executePresentLauncher()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        executePresentLauncher()
        return true
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        executePresentLauncher()
        return true
    }

    /// 合并同一轮事件中的多次打开请求，避免启动动画叠两次。
    private func executePresentLauncher() {
        guard !isPresentScheduled else {
            return
        }
        isPresentScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            self.isPresentScheduled = false
            self.launcherController?.present()
        }
    }
}
