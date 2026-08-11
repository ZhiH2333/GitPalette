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
    /// Tab 补全：传入当前文本，返回补全后文本；nil 表示无补全。
    let onRequestComplete: ((String) -> String?)?

    init(
        text: Binding<String>,
        placeholder: String,
        focusToken: UUID,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onRequestComplete: ((String) -> String?)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.focusToken = focusToken
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.onRequestComplete = onRequestComplete
    }

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
            executeMoveCursorToEnd(in: nsView)
        }
        nsView.font = .systemFont(ofSize: LauncherChrome.searchTextPointSize, weight: .regular)
        nsView.placeholderString = placeholder
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onCancel = onCancel
        context.coordinator.onRequestComplete = onRequestComplete
        context.coordinator.executeSyncFocus(focusToken: focusToken, field: nsView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            onSubmit: onSubmit,
            onCancel: onCancel,
            onRequestComplete: onRequestComplete
        )
    }

    /// 将插入点移到文本末尾。
    private func executeMoveCursorToEnd(in field: NSTextField) {
        let length: Int = (field.stringValue as NSString).length
        let range: NSRange = NSRange(location: length, length: 0)
        if let editor: NSText = field.currentEditor() {
            editor.selectedRange = range
            return
        }
        DispatchQueue.main.async {
            field.currentEditor()?.selectedRange = range
        }
    }

    /// 承接 NSTextFieldDelegate，桥接文本与 Esc/Return/Tab。
    final class Coordinator: NSObject, NSTextFieldDelegate {
        private let text: Binding<String>
        var onSubmit: () -> Void
        var onCancel: () -> Void
        var onRequestComplete: ((String) -> String?)?
        private var lastFocusToken: UUID?

        init(
            text: Binding<String>,
            onSubmit: @escaping () -> Void,
            onCancel: @escaping () -> Void,
            onRequestComplete: ((String) -> String?)?
        ) {
            self.text = text
            self.onSubmit = onSubmit
            self.onCancel = onCancel
            self.onRequestComplete = onRequestComplete
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
            // Tab 在 NSTextField 中走 insertTab:，不会走 complete:；必须拦截以免全选 / 跳焦点。
            if commandSelector == #selector(NSResponder.insertTab(_:))
                || commandSelector == #selector(NSResponder.complete(_:)) {
                executeApplyCompletion(in: textView)
                return true
            }
            if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
                return true
            }
            return false
        }

        /// 应用 Tab 补全并移动光标到末尾。
        private func executeApplyCompletion(in textView: NSTextView) {
            guard let onRequestComplete else {
                return
            }
            let current: String = textView.string
            guard let completed: String = onRequestComplete(current) else {
                return
            }
            textView.string = completed
            text.wrappedValue = completed
            let end: Int = (completed as NSString).length
            textView.setSelectedRange(NSRange(location: end, length: 0))
        }
    }
}
