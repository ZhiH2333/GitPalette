//
//  WindowFocusOnAppear.swift
//  GitPalette
//
//  SwiftUI 窗口内容出现时置前抢焦点，关闭后恢复 accessory。
//

import AppKit
import SwiftUI

/// 将 NSView 桥入 SwiftUI，用于拿到所属 NSWindow（仅首次解析时回调）。
private struct WindowAccessor: NSViewRepresentable {
    var onResolve: (NSWindow) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResolve: onResolve)
    }

    func makeNSView(context: Context) -> NSView {
        let view: NSView = NSView(frame: .zero)
        context.coordinator.executeTryResolve(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onResolve = onResolve
        context.coordinator.executeTryResolve(from: nsView)
    }

    final class Coordinator {
        var onResolve: (NSWindow) -> Void
        private var didResolve: Bool = false

        init(onResolve: @escaping (NSWindow) -> Void) {
            self.onResolve = onResolve
        }

        func executeTryResolve(from view: NSView) {
            guard !didResolve else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.didResolve, let window: NSWindow = view.window else {
                    return
                }
                self.didResolve = true
                self.onResolve(window)
            }
        }
    }
}

extension View {
    /// 窗口首次显示时激活应用并成为 key；消失后尝试恢复 LSUIElement。
    func applyWindowForegroundFocus(identifier: String? = nil) -> some View {
        background(
            WindowAccessor { window in
                if let identifier {
                    window.identifier = NSUserInterfaceItemIdentifier(identifier)
                }
                AppWindowFocus.executeFocusHostingWindow(of: window.contentView)
            }
        )
        .onAppear {
            AppWindowFocus.executePrepareForWindowPresentation()
        }
        .onDisappear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                AppWindowFocus.executeRevertToAccessoryIfNeeded()
            }
        }
    }
}
