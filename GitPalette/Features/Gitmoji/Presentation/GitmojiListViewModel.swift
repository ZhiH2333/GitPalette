//
//  GitmojiListViewModel.swift
//  GitPalette
//
//  Gitmoji 列表状态与复制逻辑。
//

import AppKit
import Combine
import Foundation

/// Gitmoji 可搜索列表 ViewModel。
@MainActor
final class GitmojiListViewModel: ObservableObject {
    /// 搜索关键词
    @Published var query: String = "" {
        didSet {
            selectedIndex = 0
            executeClampSelectedIndex()
        }
    }
    /// 当前选中行（相对 filtered）
    @Published var selectedIndex: Int = 0
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
        selectedIndex = 0
        copyFeedbackText = nil
        executeReloadRecentItems()
    }

    /// 复制当前选中项；成功返回 true。
    @discardableResult
    func copySelected() -> Bool {
        let items: [Gitmoji] = filtered
        guard items.indices.contains(selectedIndex) else {
            return false
        }
        executeCopy(items[selectedIndex])
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

    /// 选中下一项。
    func executeSelectNext() {
        let count: Int = filtered.count
        guard count > 0 else {
            return
        }
        selectedIndex = min(selectedIndex + 1, count - 1)
    }

    /// 选中上一项。
    func executeSelectPrevious() {
        let count: Int = filtered.count
        guard count > 0 else {
            return
        }
        selectedIndex = max(selectedIndex - 1, 0)
    }

    /// 选中指定下标。
    func executeSelectIndex(_ index: Int) {
        let count: Int = filtered.count
        guard count > 0 else {
            selectedIndex = 0
            return
        }
        selectedIndex = min(max(index, 0), count - 1)
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
    }

    /// 显示短暂「已复制」提示。
    private func executeShowCopyFeedback() {
        copyFeedbackText = "已复制"
        feedbackClearTask?.cancel()
        feedbackClearTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if !Task.isCancelled {
                copyFeedbackText = nil
            }
        }
    }

    /// 保证 selectedIndex 落在过滤结果范围内。
    private func executeClampSelectedIndex() {
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
}
