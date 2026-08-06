//
//  GitmojiListViewModel.swift
//  GitPalette
//
//  Gitmoji 列表状态与复制逻辑（含最近使用键盘导航）。
//

import AppKit
import Combine
import Foundation

/// 启动器键盘焦点区域。
enum LauncherSelectionFocus: Equatable {
    /// 最近使用横向区
    case recent
    /// 主结果列表
    case list
}

/// Gitmoji 可搜索列表 ViewModel。
@MainActor
final class GitmojiListViewModel: ObservableObject {
    /// 搜索关键词
    @Published var query: String = "" {
        didSet {
            executeHandleQueryDidChange()
        }
    }
    /// 当前焦点区域
    @Published private(set) var selectionFocus: LauncherSelectionFocus = .list
    /// 主列表选中行（相对 filtered）
    @Published var selectedIndex: Int = 0
    /// 最近使用区选中下标
    @Published var recentSelectedIndex: Int = 0
    /// 复制成功提示文案
    @Published var copyFeedbackText: String?
    /// 最近使用条目
    @Published private(set) var recentItems: [Gitmoji] = []
    private let repository: GitmojiRepository
    private let recentStore: RecentGitmojiStore
    private let appConfig: AppConfig
    private var feedbackClearTask: Task<Void, Never>?

    /// 过滤后的列表。
    var filtered: [Gitmoji] {
        repository.search(query: query)
    }

    /// 是否无任何内置数据。
    var isDataEmpty: Bool {
        repository.all.isEmpty
    }

    /// 当前是否应展示最近使用区。
    var shouldShowRecentSection: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !recentItems.isEmpty
            && !isDataEmpty
    }

    init(
        repository: GitmojiRepository,
        recentStore: RecentGitmojiStore = RecentGitmojiStore(),
        appConfig: AppConfig
    ) {
        self.repository = repository
        self.recentStore = recentStore
        self.appConfig = appConfig
        executeReloadRecentItems()
    }

    /// 打开面板前重置搜索与选中。
    func executeResetForPresentation() {
        query = ""
        selectionFocus = .list
        selectedIndex = 0
        recentSelectedIndex = 0
        copyFeedbackText = nil
        executeReloadRecentItems()
        executeClampSelection()
    }

    /// 复制当前选中项；成功返回 true。
    @discardableResult
    func copySelected() -> Bool {
        guard let item: Gitmoji = resolveFocusedItem() else {
            return false
        }
        executeCopy(item)
        return true
    }

    /// 复制指定条目并记入最近使用。
    func executeCopy(_ item: Gitmoji) {
        let text: String = resolveCopyText(for: item)
        executeWritePasteboard(text)
        recentStore.executeRecord(code: item.code)
        executeReloadRecentItems()
        executeShowCopyFeedback()
    }

    /// 方向下：最近区 → 列表首项；列表内下移。
    func executeSelectNext() {
        switch selectionFocus {
        case .recent:
            guard !filtered.isEmpty else {
                return
            }
            selectionFocus = .list
            selectedIndex = 0
        case .list:
            let count: Int = filtered.count
            guard count > 0 else {
                return
            }
            selectedIndex = min(selectedIndex + 1, count - 1)
        }
    }

    /// 方向上：列表首项 → 最近区；列表内上移。
    func executeSelectPrevious() {
        switch selectionFocus {
        case .recent:
            return
        case .list:
            if selectedIndex <= 0, shouldShowRecentSection {
                selectionFocus = .recent
                executeClampRecentSelectedIndex()
                return
            }
            let count: Int = filtered.count
            guard count > 0 else {
                if shouldShowRecentSection {
                    selectionFocus = .recent
                    executeClampRecentSelectedIndex()
                }
                return
            }
            selectedIndex = max(selectedIndex - 1, 0)
        }
    }

    /// 方向右：仅在最近区移动。
    func executeSelectRight() {
        guard selectionFocus == .recent, shouldShowRecentSection else {
            return
        }
        let count: Int = recentItems.count
        guard count > 0 else {
            return
        }
        recentSelectedIndex = min(recentSelectedIndex + 1, count - 1)
    }

    /// 方向左：仅在最近区移动。
    func executeSelectLeft() {
        guard selectionFocus == .recent, shouldShowRecentSection else {
            return
        }
        let count: Int = recentItems.count
        guard count > 0 else {
            return
        }
        recentSelectedIndex = max(recentSelectedIndex - 1, 0)
    }

    /// 选中主列表指定下标。
    func executeSelectIndex(_ index: Int) {
        selectionFocus = .list
        let count: Int = filtered.count
        guard count > 0 else {
            selectedIndex = 0
            return
        }
        selectedIndex = min(max(index, 0), count - 1)
    }

    /// 选中最近使用指定下标。
    func executeSelectRecentIndex(_ index: Int) {
        guard shouldShowRecentSection else {
            return
        }
        selectionFocus = .recent
        let count: Int = recentItems.count
        guard count > 0 else {
            recentSelectedIndex = 0
            return
        }
        recentSelectedIndex = min(max(index, 0), count - 1)
    }

    /// 当前焦点对应的条目。
    private func resolveFocusedItem() -> Gitmoji? {
        switch selectionFocus {
        case .recent:
            guard recentItems.indices.contains(recentSelectedIndex) else {
                return nil
            }
            return recentItems[recentSelectedIndex]
        case .list:
            let items: [Gitmoji] = filtered
            guard items.indices.contains(selectedIndex) else {
                return nil
            }
            return items[selectedIndex]
        }
    }

    /// 按当前格式解析复制文本。
    private func resolveCopyText(for item: Gitmoji) -> String {
        appConfig.resolveCopyText(for: item)
    }

    /// 写入系统剪贴板。
    private func executeWritePasteboard(_ text: String) {
        let pasteboard: NSPasteboard = .general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// 刷新最近使用列表。
    func executeReloadRecentItems() {
        let codes: [String] = recentStore.loadCodes()
        let lookup: [String: Gitmoji] = Dictionary(
            uniqueKeysWithValues: repository.all.map { ($0.code, $0) }
        )
        recentItems = codes.compactMap { lookup[$0] }
        executeClampSelection()
    }

    /// 搜索变化时重置列表选中，并在隐藏最近区时切回列表。
    private func executeHandleQueryDidChange() {
        selectedIndex = 0
        if !shouldShowRecentSection, selectionFocus == .recent {
            selectionFocus = .list
        }
        executeClampSelection()
    }

    /// 显示短暂「已复制」提示。
    private func executeShowCopyFeedback() {
        copyFeedbackText = appConfig.t(.copied)
        feedbackClearTask?.cancel()
        feedbackClearTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if !Task.isCancelled {
                copyFeedbackText = nil
            }
        }
    }

    /// 钳制两区选中下标，并校正非法焦点。
    private func executeClampSelection() {
        executeClampListSelectedIndex()
        executeClampRecentSelectedIndex()
        if selectionFocus == .recent, !shouldShowRecentSection {
            selectionFocus = .list
        }
    }

    /// 保证 selectedIndex 落在过滤结果范围内。
    private func executeClampListSelectedIndex() {
        let count: Int = filtered.count
        if count == 0 {
            selectedIndex = 0
            return
        }
        if selectedIndex >= count {
            selectedIndex = count - 1
        }
        if selectedIndex < 0 {
            selectedIndex = 0
        }
    }

    /// 保证 recentSelectedIndex 落在最近列表范围内。
    private func executeClampRecentSelectedIndex() {
        let count: Int = recentItems.count
        if count == 0 {
            recentSelectedIndex = 0
            return
        }
        if recentSelectedIndex >= count {
            recentSelectedIndex = count - 1
        }
        if recentSelectedIndex < 0 {
            recentSelectedIndex = 0
        }
    }
}
