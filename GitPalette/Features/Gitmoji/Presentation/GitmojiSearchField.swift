//
//  GitmojiSearchField.swift
//  GitPalette
//
//  AppKit 搜索框：Spotlight 大字号；半透明补全后缀；Esc 走 doCommandBy。
//

import AppKit
import SwiftUI

/// Esc 安全的 Spotlight 风格搜索输入框（AppKit 桥接）。
struct GitmojiSearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    /// 半透明补全后缀（不含已输入部分）；空则不绘制。
    let ghostSuffix: String
    let focusToken: UUID
    let onSubmit: () -> Void
    let onCancel: () -> Void
    /// Tab / → 补全：传入当前文本，返回补全后文本；nil 表示无补全。
    let onRequestComplete: ((String) -> String?)?
    /// git add 结果视图：拦截空格 / A，不写入输入框，转为切换勾选 / 全选。
    let shouldConsumeGitAddKeys: Bool
    /// 空格被拦截时触发：切换当前高亮行勾选。
    let onGitAddToggleHighlighted: (() -> Void)?
    /// A 被拦截时触发：全选。
    let onGitAddSelectAll: (() -> Void)?

    init(
        text: Binding<String>,
        placeholder: String,
        ghostSuffix: String = "",
        focusToken: UUID,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onRequestComplete: ((String) -> String?)? = nil,
        shouldConsumeGitAddKeys: Bool = false,
        onGitAddToggleHighlighted: (() -> Void)? = nil,
        onGitAddSelectAll: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.ghostSuffix = ghostSuffix
        self.focusToken = focusToken
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.onRequestComplete = onRequestComplete
        self.shouldConsumeGitAddKeys = shouldConsumeGitAddKeys
        self.onGitAddToggleHighlighted = onGitAddToggleHighlighted
        self.onGitAddSelectAll = onGitAddSelectAll
    }

    func makeNSView(context: Context) -> SpotlightSearchContainer {
        let container: SpotlightSearchContainer = SpotlightSearchContainer()
        container.field.delegate = context.coordinator
        container.field.target = context.coordinator
        container.field.action = #selector(Coordinator.executeSubmit)
        context.coordinator.container = container
        return container
    }

    func updateNSView(_ nsView: SpotlightSearchContainer, context: Context) {
        let field: NSTextField = nsView.field
        if field.stringValue != text {
            // 编辑中必须同步 field editor；只写 stringValue 会把插入点打回行首。
            executeApplyExternalText(text, to: field)
        }
        field.font = .systemFont(ofSize: LauncherChrome.searchTextPointSize, weight: .regular)
        field.placeholderString = placeholder
        nsView.executeUpdateGhost(
            suffix: ghostSuffix,
            font: field.font ?? .systemFont(ofSize: LauncherChrome.searchTextPointSize)
        )
        context.coordinator.container = nsView
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onCancel = onCancel
        context.coordinator.onRequestComplete = onRequestComplete
        context.coordinator.shouldConsumeGitAddKeys = shouldConsumeGitAddKeys
        context.coordinator.onGitAddToggleHighlighted = onGitAddToggleHighlighted
        context.coordinator.onGitAddSelectAll = onGitAddSelectAll
        context.coordinator.ghostSuffix = ghostSuffix
        context.coordinator.executeSyncFocus(focusToken: focusToken, field: field)
        context.coordinator.executeEnsureFieldEditorTransparent(field: field)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            onSubmit: onSubmit,
            onCancel: onCancel,
            onRequestComplete: onRequestComplete
        )
    }

    /// 外部（↑↓ 补全等）写入文本：同步 cell + field editor，并把插入点放到末尾。
    private func executeApplyExternalText(_ newText: String, to field: NSTextField) {
        field.stringValue = newText
        let end: Int = (newText as NSString).length
        let endRange: NSRange = NSRange(location: end, length: 0)
        if let editor: NSTextView = field.currentEditor() as? NSTextView {
            if editor.string != newText {
                editor.string = newText
            }
            editor.setSelectedRange(endRange)
            return
        }
        if let editor: NSText = field.currentEditor() {
            editor.string = newText
            editor.selectedRange = endRange
            return
        }
        DispatchQueue.main.async {
            if let editor: NSTextView = field.currentEditor() as? NSTextView {
                if editor.string != newText {
                    editor.string = newText
                }
                editor.setSelectedRange(endRange)
            } else {
                field.currentEditor()?.selectedRange = endRange
            }
        }
    }

    /// 承接 NSTextFieldDelegate，桥接文本与 Esc/Return/Tab/→。
    /// 注意：不要把 field editor 的 delegate 直接替换成本对象——NSTextField 依赖自己
    /// 是 field editor 的 delegate 才能把文本变化转发成 controlTextDidChange /
    /// NSControlTextDidChangeNotification；替换后 SwiftUI 的 text 绑定会彻底失效
    /// （输入框视觉上能打字，但 query 绑定永远不更新，命令模式随之整体失效）。
    /// 因此 git add 的空格 / A 拦截改为：让输入正常发生，controlTextDidChange 里
    /// 检测出「刚插入了单个空格 / a / A」时撤回文本并改为触发勾选 / 全选回调。
    final class Coordinator: NSObject, NSTextFieldDelegate {
        private let text: Binding<String>
        var onSubmit: () -> Void
        var onCancel: () -> Void
        var onRequestComplete: ((String) -> String?)?
        var shouldConsumeGitAddKeys: Bool = false
        var onGitAddToggleHighlighted: (() -> Void)?
        var onGitAddSelectAll: (() -> Void)?
        var ghostSuffix: String = ""
        weak var container: SpotlightSearchContainer?
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
            let newValue: String = field.stringValue
            let oldValue: String = text.wrappedValue
            if shouldConsumeGitAddKeys,
               let insertedChar: Character = Self.executeDetectSingleInsertedChar(old: oldValue, new: newValue) {
                if insertedChar == " " {
                    executeRevertFieldText(field: field, to: oldValue)
                    onGitAddToggleHighlighted?()
                    return
                }
                if insertedChar == "a" || insertedChar == "A" {
                    executeRevertFieldText(field: field, to: oldValue)
                    onGitAddSelectAll?()
                    return
                }
            }
            text.wrappedValue = newValue
            if let container {
                container.executeUpdateGhost(
                    suffix: ghostSuffix,
                    font: field.font ?? .systemFont(ofSize: LauncherChrome.searchTextPointSize)
                )
            }
            executeEnsureFieldEditorTransparent(field: field)
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            guard let field: NSTextField = obj.object as? NSTextField else {
                return
            }
            executeEnsureFieldEditorTransparent(field: field)
        }

        func executeSyncFocus(focusToken: UUID, field: NSTextField) {
            guard lastFocusToken != focusToken else {
                return
            }
            lastFocusToken = focusToken
            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
                self.executeEnsureFieldEditorTransparent(field: field)
            }
        }

        /// 让 field editor 透明，以便下层半透明补全可见。
        func executeEnsureFieldEditorTransparent(field: NSTextField) {
            guard let editor: NSTextView = field.currentEditor() as? NSTextView else {
                return
            }
            editor.drawsBackground = false
            editor.backgroundColor = .clear
        }

        /// 把字段文本 + field editor 一并撤回到给定值，光标放末尾。
        private func executeRevertFieldText(field: NSTextField, to value: String) {
            field.stringValue = value
            let length: Int = (value as NSString).length
            let endRange: NSRange = NSRange(location: length, length: 0)
            if let editor: NSTextView = field.currentEditor() as? NSTextView {
                if editor.string != value {
                    editor.string = value
                }
                editor.setSelectedRange(endRange)
            }
        }

        /// 若 new 相对 old 恰好多了一个字符（任意位置插入），返回该字符；否则 nil。
        private static func executeDetectSingleInsertedChar(old: String, new: String) -> Character? {
            guard new.count == old.count + 1 else {
                return nil
            }
            let oldChars: [Character] = Array(old)
            let newChars: [Character] = Array(new)
            var prefixLength: Int = 0
            while prefixLength < oldChars.count,
                  prefixLength < newChars.count,
                  oldChars[prefixLength] == newChars[prefixLength] {
                prefixLength += 1
            }
            guard prefixLength < newChars.count else {
                return nil
            }
            let inserted: Character = newChars[prefixLength]
            let remainderOld: [Character] = Array(oldChars[prefixLength...])
            let remainderNew: [Character] = Array(newChars[(prefixLength + 1)...])
            guard remainderOld == remainderNew else {
                return nil
            }
            return inserted
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
            // ↑↓ 由 LauncherController 本地监视负责选中；此处吞掉，避免单行 field editor
            // 把 moveUp: 解释成「插入点移到行首」。
            if commandSelector == #selector(NSResponder.moveUp(_:))
                || commandSelector == #selector(NSResponder.moveDown(_:))
                || commandSelector == #selector(NSResponder.moveUpAndModifySelection(_:))
                || commandSelector == #selector(NSResponder.moveDownAndModifySelection(_:)) {
                return true
            }
            // Spotlight：光标在末尾时 → 采纳半透明补全。
            if commandSelector == #selector(NSResponder.moveRight(_:))
                || commandSelector == #selector(NSResponder.moveRightAndModifySelection(_:)) {
                if executeTryAcceptGhost(in: textView) {
                    return true
                }
            }
            return false
        }

        /// 光标在末尾且存在 ghost 时采纳补全。
        private func executeTryAcceptGhost(in textView: NSTextView) -> Bool {
            guard !ghostSuffix.isEmpty else {
                return false
            }
            let selected: NSRange = textView.selectedRange()
            let end: Int = (textView.string as NSString).length
            guard selected.length == 0, selected.location == end else {
                return false
            }
            executeApplyCompletion(in: textView)
            return true
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
            if let container {
                container.executeUpdateGhost(
                    suffix: "",
                    font: container.field.font
                        ?? .systemFont(ofSize: LauncherChrome.searchTextPointSize)
                )
            }
        }
    }
}

/// 承载可编辑搜索框 + 底层半透明补全层。
final class SpotlightSearchContainer: NSView {
    let field: NSTextField = NSTextField()
    private let ghostField: NSTextField = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        executeConfigureSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: Self.fieldHeight)
    }

    override func layout() {
        super.layout()
        // 与改前裸 NSTextField 一致：固定行高，避免自定义容器被 SwiftUI 纵向撑高。
        let height: CGFloat = Self.fieldHeight
        let y: CGFloat = max((bounds.height - height) * 0.5, 0)
        let frame: NSRect = NSRect(x: 0, y: y, width: bounds.width, height: height)
        ghostField.frame = frame
        field.frame = frame
    }

    /// 刷新半透明补全：已输入段透明，后缀用次要色。
    func executeUpdateGhost(suffix: String, font: NSFont) {
        ghostField.font = font
        field.font = font
        let typed: String = field.stringValue
        if suffix.isEmpty || typed.isEmpty {
            ghostField.attributedStringValue = NSAttributedString(string: "")
            return
        }
        let typedAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.clear
        ]
        let ghostAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.42)
        ]
        let composed: NSMutableAttributedString = NSMutableAttributedString(
            string: typed,
            attributes: typedAttributes
        )
        composed.append(NSAttributedString(string: suffix, attributes: ghostAttributes))
        ghostField.attributedStringValue = composed
    }

    private static let fieldHeight: CGFloat = 28

    private func executeConfigureSubviews() {
        wantsLayer = true
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)

        ghostField.isEditable = false
        ghostField.isSelectable = false
        ghostField.isBordered = false
        ghostField.isBezeled = false
        ghostField.drawsBackground = false
        ghostField.focusRingType = .none
        ghostField.lineBreakMode = .byClipping
        ghostField.maximumNumberOfLines = 1
        ghostField.cell?.wraps = false
        ghostField.cell?.isScrollable = false
        ghostField.refusesFirstResponder = true
        ghostField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        ghostField.setContentHuggingPriority(.required, for: .vertical)

        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: LauncherChrome.searchTextPointSize, weight: .regular)
        field.lineBreakMode = .byTruncatingTail
        field.maximumNumberOfLines = 1
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.setContentHuggingPriority(.required, for: .vertical)
        field.setContentCompressionResistancePriority(.required, for: .vertical)

        addSubview(ghostField)
        addSubview(field)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit: NSView? = super.hitTest(point)
        if hit === ghostField {
            return field
        }
        return hit
    }
}
