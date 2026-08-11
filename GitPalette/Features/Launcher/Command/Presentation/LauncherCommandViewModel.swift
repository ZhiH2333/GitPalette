//
//  LauncherCommandViewModel.swift
//  GitPalette
//
//  命令模式状态：候选列表、选中下标、补全与执行。
//

import Foundation
import Combine

/// 启动器「/」命令模式 ViewModel（与 Gitmoji 焦点互斥）。
@MainActor
final class LauncherCommandViewModel: ObservableObject {
    /// 当前建议列表
    @Published private(set) var suggestions: [CommandSuggestion] = []
    /// 选中下标
    @Published var selectedIndex: Int = 0
    /// 非法参数等中文状态提示
    @Published var statusMessage: String?
    /// 最近一次解析结果
    @Published private(set) var parseResult: LauncherCommandParseResult = .notCommandMode
    private let executor: LauncherCommandExecutor

    init(executor: LauncherCommandExecutor) {
        self.executor = executor
    }

    /// 是否处于命令模式。
    var isCommandMode: Bool {
        parseResult.isCommandMode
    }

    /// Spotlight 半透明补全后缀（相对当前 query）；无候选时为空。
    /// 前缀命中：续写剩余字符；包含命中：以「 — /command」提示完整命令。
    func resolveGhostSuffix(for query: String) -> String {
        guard isCommandMode else {
            return ""
        }
        guard suggestions.indices.contains(selectedIndex) else {
            return ""
        }
        let completion: String = suggestions[selectedIndex].completionText
            .trimmingCharacters(in: .whitespaces)
        guard !completion.isEmpty else {
            return ""
        }
        let queryLower: String = query.lowercased()
        let completionLower: String = completion.lowercased()
        if completionLower.hasPrefix(queryLower), completion.count >= query.count {
            let suffix: String = String(completion.dropFirst(query.count))
            if suffix.trimmingCharacters(in: .whitespaces).isEmpty {
                return ""
            }
            return suffix
        }
        // 包含匹配等非整词续写：半透明提示完整命令。
        if query.hasPrefix("/"), query.count > 1 {
            return " — " + completion
        }
        return ""
    }

    /// 面板展示前重置。
    func executeReset() {
        suggestions = []
        selectedIndex = 0
        statusMessage = nil
        parseResult = .notCommandMode
    }

    /// 同步 query 并刷新建议。
    func executeUpdateQuery(_ query: String) {
        statusMessage = nil
        parseResult = LauncherCommandParser.executeParse(query)
        guard parseResult.isCommandMode else {
            suggestions = []
            selectedIndex = 0
            return
        }
        suggestions = CommandSuggestionEngine.resolveSuggestions(for: query)
        executeClampSelectedIndex()
    }

    /// Tab：补全当前选中候选，返回新 query；无候选返回 nil。
    func executeComplete(query: String) -> String? {
        guard parseResult.isCommandMode else {
            return nil
        }
        guard let completed: String =
            CommandSuggestionEngine.resolveBestCompletion(
                for: query,
                selectedIndex: selectedIndex
            )
        else {
            return nil
        }
        if completed == query {
            return nil
        }
        return completed
    }

    /// ↑ 选中上一项。
    func executeSelectPrevious() {
        guard !suggestions.isEmpty else {
            return
        }
        selectedIndex = max(selectedIndex - 1, 0)
    }

    /// ↓ 选中下一项。
    func executeSelectNext() {
        guard !suggestions.isEmpty else {
            return
        }
        selectedIndex = min(selectedIndex + 1, suggestions.count - 1)
    }

    /// 选中指定下标。
    func executeSelectIndex(_ index: Int) {
        guard !suggestions.isEmpty else {
            selectedIndex = 0
            return
        }
        selectedIndex = min(max(index, 0), suggestions.count - 1)
    }

    /// Return：执行当前解析结果。
    func executeConfirm(query: String) -> LauncherCommandExecutionOutcome {
        let result: LauncherCommandParseResult = LauncherCommandParser.executeParse(query)
        parseResult = result
        let outcome: LauncherCommandExecutionOutcome = executor.execute(parseResult: result)
        if case .keptOpen(let message) = outcome {
            statusMessage = message
        }
        return outcome
    }

    /// 点击建议行：可执行则执行，否则应用补全文本。
    func executeActivateSuggestion(
        at index: Int,
        currentQuery: String,
        applyCompletion: (String) -> Void
    ) -> LauncherCommandExecutionOutcome? {
        guard suggestions.indices.contains(index) else {
            return nil
        }
        executeSelectIndex(index)
        // /help 仅供浏览，点击无副作用。
        if parseResult.matchedCommand == .help {
            return nil
        }
        let suggestion: CommandSuggestion = suggestions[index]
        let completedQuery: String = suggestion.completionText
        let completedParse: LauncherCommandParseResult =
            LauncherCommandParser.executeParse(completedQuery)
        if completedParse.isExecutable, completedParse.matchedCommand?.isViewOnly != true {
            applyCompletion(completedQuery)
            executeUpdateQuery(completedQuery)
            return executeConfirm(query: completedQuery)
        }
        if completedQuery != currentQuery {
            applyCompletion(completedQuery)
            executeUpdateQuery(completedQuery)
        }
        return nil
    }

    /// 钳制选中下标。
    private func executeClampSelectedIndex() {
        if suggestions.isEmpty {
            selectedIndex = 0
            return
        }
        if selectedIndex >= suggestions.count {
            selectedIndex = suggestions.count - 1
        }
        if selectedIndex < 0 {
            selectedIndex = 0
        }
    }
}
