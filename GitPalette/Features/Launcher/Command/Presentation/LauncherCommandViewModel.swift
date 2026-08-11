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
    /// 非法参数等状态提示（跟随 descriptionLanguage）
    @Published var statusMessage: String?
    /// 最近一次解析结果
    @Published private(set) var parseResult: LauncherCommandParseResult = .notCommandMode
    private let executor: LauncherCommandExecutor
    private let preferences: PreferencesStore
    private var cancellables: Set<AnyCancellable> = []
    private var latestQuery: String = ""

    init(executor: LauncherCommandExecutor, preferences: PreferencesStore) {
        self.executor = executor
        self.preferences = preferences
        preferences.$descriptionLanguage
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                self.executeUpdateQuery(self.latestQuery)
            }
            .store(in: &cancellables)
    }

    /// 是否处于命令模式。
    var isCommandMode: Bool {
        parseResult.isCommandMode
    }

    /// 命令提示语言（desclang）。
    private var hintLanguage: AppLanguage {
        preferences.descriptionLanguage
    }

    /// Spotlight 半透明补全后缀（相对当前 query）；无候选时为空。
    /// - 已精确匹配带参命令且尚未输入参数：显示英文类型名占位，如 ` <option>`
    /// - 前缀命中：续写剩余字符（命令名建议可附带类型占位）
    /// - 包含命中：以「 — /command」提示完整命令
    func resolveGhostSuffix(for query: String) -> String {
        guard isCommandMode else {
            return ""
        }
        if let typeGhost: String = resolveArgumentTypeGhost(for: query) {
            return typeGhost
        }
        guard suggestions.indices.contains(selectedIndex) else {
            return ""
        }
        let suggestion: CommandSuggestion = suggestions[selectedIndex]
        let completion: String = suggestion.completionText
            .trimmingCharacters(in: .whitespaces)
        guard !completion.isEmpty else {
            return ""
        }
        let queryLower: String = query.lowercased()
        let completionLower: String = completion.lowercased()
        if completionLower.hasPrefix(queryLower), completion.count >= query.count {
            let suffix: String = String(completion.dropFirst(query.count))
            if let argumentTypeGhost: String = suggestion.argumentTypeGhost {
                if suffix.trimmingCharacters(in: .whitespaces).isEmpty {
                    return query.hasSuffix(" ")
                        ? argumentTypeGhost
                        : " " + argumentTypeGhost
                }
                return suffix + " " + argumentTypeGhost
            }
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

    /// 已选定命令、尚未输入参数（或 /recent count 待数字）时的英文类型 ghost。
    private func resolveArgumentTypeGhost(for query: String) -> String? {
        guard let command: LauncherCommand = parseResult.matchedCommand else {
            return nil
        }
        let argument: String = parseResult.rawArgumentText
        if argument.isEmpty, let placeholder: String = command.argumentTypePlaceholder {
            return query.hasSuffix(" ") ? placeholder : " " + placeholder
        }
        // /recent count → 半透明 <n>
        if command == .recent {
            let parts: [String] = argument
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
            if parts.count == 1, parts[0].lowercased() == "count" {
                return query.hasSuffix(" ") ? "<n>" : " <n>"
            }
        }
        return nil
    }

    /// 面板展示前重置。
    func executeReset() {
        suggestions = []
        selectedIndex = 0
        statusMessage = nil
        parseResult = .notCommandMode
        latestQuery = ""
    }

    /// 同步 query 并刷新建议。
    func executeUpdateQuery(_ query: String) {
        latestQuery = query
        statusMessage = nil
        parseResult = LauncherCommandParser.executeParse(query, language: hintLanguage)
        guard parseResult.isCommandMode else {
            suggestions = []
            selectedIndex = 0
            return
        }
        suggestions = CommandSuggestionEngine.resolveSuggestions(
            for: query,
            language: hintLanguage
        )
        executePreferSelectionMatchingQuery(query)
    }

    /// Tab：补全当前选中候选，返回新 query；无候选返回 nil。
    func executeComplete(query: String) -> String? {
        guard parseResult.isCommandMode else {
            return nil
        }
        guard let completed: String =
            CommandSuggestionEngine.resolveBestCompletion(
                for: query,
                selectedIndex: selectedIndex,
                language: hintLanguage
            )
        else {
            return nil
        }
        if completed == query {
            return nil
        }
        return completed
    }

    /// ↑ 选中上一项，并返回应写入输入框的补全文本。
    func executeSelectPrevious() -> String? {
        guard !suggestions.isEmpty else {
            return nil
        }
        selectedIndex = max(selectedIndex - 1, 0)
        return resolveSelectedCompletionText()
    }

    /// ↓ 选中下一项，并返回应写入输入框的补全文本。
    func executeSelectNext() -> String? {
        guard !suggestions.isEmpty else {
            return nil
        }
        selectedIndex = min(selectedIndex + 1, suggestions.count - 1)
        return resolveSelectedCompletionText()
    }

    /// 选中指定下标。
    func executeSelectIndex(_ index: Int) {
        guard !suggestions.isEmpty else {
            selectedIndex = 0
            return
        }
        selectedIndex = min(max(index, 0), suggestions.count - 1)
    }

    /// 当前选中建议的补全文本。
    func resolveSelectedCompletionText() -> String? {
        guard suggestions.indices.contains(selectedIndex) else {
            return nil
        }
        return suggestions[selectedIndex].completionText
    }

    /// Return：执行当前解析结果。
    func executeConfirm(query: String) -> LauncherCommandExecutionOutcome {
        let result: LauncherCommandParseResult =
            LauncherCommandParser.executeParse(query, language: hintLanguage)
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
            LauncherCommandParser.executeParse(completedQuery, language: hintLanguage)
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

    /// 若 query 已等于某条建议的补全文本，选中该条；否则钳制下标。
    private func executePreferSelectionMatchingQuery(_ query: String) {
        let trimmedQuery: String = query.trimmingCharacters(in: .whitespaces)
        if let matchedIndex: Int = suggestions.firstIndex(where: { suggestion in
            suggestion.completionText == query
                || suggestion.completionText.trimmingCharacters(in: .whitespaces) == trimmedQuery
        }) {
            selectedIndex = matchedIndex
            return
        }
        executeClampSelectedIndex()
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
