//
//  GitmojiSearchField.swift
//  GitPalette
//
//  AppKit 搜索框：Spotlight 大字号；Esc 走 doCommandBy，避免系统提示音。
//

import AppKit
import SwiftUI

/// Esc 安全的 Spotlight 风格搜索输入框（AppKit 桥接）。
struct GitmojiSearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let focusToken: UUID
    let onSubmit: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field: NSTextField = NSTextField()
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: LauncherChrome.searchTextPointSize, weight: .regular)
        field.placeholderString = placeholder
        field.lineBreakMode = .byTruncatingTail
        field.maximumNumberOfLines = 1
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.delegate = context.coordinator
        field.target = context.coordinator
        field.action = #selector(Coordinator.executeSubmit)
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        nsView.font = .systemFont(ofSize: LauncherChrome.searchTextPointSize, weight: .regular)
        nsView.placeholderString = placeholder
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onCancel = onCancel
        context.coordinator.executeSyncFocus(focusToken: focusToken, field: nsView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit, onCancel: onCancel)
    }

    /// 承接 NSTextFieldDelegate，桥接文本与 Esc/Return。
    final class Coordinator: NSObject, NSTextFieldDelegate {
        private let text: Binding<String>
        var onSubmit: () -> Void
        var onCancel: () -> Void
        private var lastFocusToken: UUID?

        init(text: Binding<String>, onSubmit: @escaping () -> Void, onCancel: @escaping () -> Void) {
            self.text = text
            self.onSubmit = onSubmit
            self.onCancel = onCancel
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field: NSTextField = obj.object as? NSTextField else {
                return
            }
            text.wrappedValue = field.stringValue
        }

        func executeSyncFocus(focusToken: UUID, field: NSTextField) {
            guard lastFocusToken != focusToken else {
                return
            }
            lastFocusToken = focusToken
            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
            }
        }

        @objc func executeSubmit() {
            onSubmit()
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                onCancel()
                return true
            }
            if commandSelector == #selector(NSResponder.insertNewline(_:))
                || commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
                onSubmit()
                return true
            }
            if commandSelector == #selector(NSResponder.complete(_:)) {
                return true
            }
            return false
        }
    }
}
