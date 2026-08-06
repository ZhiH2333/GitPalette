//
//  GitmojiListView.swift
//  GitPalette
//
//  可搜索 Gitmoji 列表（供启动器浮动面板承载）。
//

import SwiftUI

/// Gitmoji 搜索与复制主界面。
struct GitmojiListView: View {
    @Bindable var appConfig: AppConfig
    @Bindable var viewModel: GitmojiListViewModel
    let focusToken: UUID
    let onDismiss: () -> Void
    let onConfirmCopy: () -> Void
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            buildToolbar()
            Divider().opacity(0.35)
            if shouldShowRecentSection {
                buildRecentSection()
                Divider().opacity(0.35)
            }
            buildResultArea()
            buildFooter()
        }
        .frame(width: 560, height: 420)
        .onAppear {
            executeFocusSearchField()
        }
        .onChange(of: focusToken) { _, _ in
            executeFocusSearchField()
        }
    }

    /// 是否展示最近使用区。
    private var shouldShowRecentSection: Bool {
        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.recentItems.isEmpty
            && !viewModel.isDataEmpty
    }

    /// 构建顶部搜索与格式切换。
    @ViewBuilder
    private func buildToolbar() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("搜索 Gitmoji…", text: $viewModel.query)
                .textFieldStyle(.plain)
                .font(.title3)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .focused($isSearchFocused)
                .onSubmit {
                    onConfirmCopy()
                }
            HStack {
                Text("复制格式")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("复制格式", selection: $appConfig.copyFormat) {
                    ForEach(CopyFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 160)
                Spacer(minLength: 0)
                Text("↑↓ 选择 · ⏎ 复制 · Esc 关闭")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    /// 构建最近使用区。
    @ViewBuilder
    private func buildRecentSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近使用")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.recentItems) { item in
                        Button {
                            viewModel.executeCopy(item)
                            onDismiss()
                        } label: {
                            Text(item.emoji)
                                .font(.title2)
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                        .help(item.code)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    /// 构建结果区（列表或空态）。
    @ViewBuilder
    private func buildResultArea() -> some View {
        if viewModel.isDataEmpty {
            buildEmptyState(message: "暂无 Gitmoji 数据")
        } else if viewModel.filtered.isEmpty {
            buildEmptyState(message: "未找到匹配的 Gitmoji")
        } else {
            buildList()
        }
    }

    /// 构建空态文案。
    @ViewBuilder
    private func buildEmptyState(message: String) -> some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 构建主列表（不用 List，避免 NSTableView 再吃一次方向键导致跳项）。
    @ViewBuilder
    private func buildList() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(viewModel.filtered.enumerated()), id: \.element.id) { index, item in
                        GitmojiRowView(item: item, isSelected: index == viewModel.selectedIndex)
                            .id(item.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.executeSelectIndex(index)
                                viewModel.executeCopy(item)
                                onDismiss()
                            }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            .onChange(of: viewModel.selectedIndex) { _, newValue in
                executeScrollToSelection(proxy: proxy, index: newValue)
            }
        }
    }

    /// 构建底部状态栏。
    @ViewBuilder
    private func buildFooter() -> some View {
        HStack {
            Text(resolveFooterCountText())
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if let feedback: String = viewModel.copyFeedbackText {
                Text(feedback)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    /// 底部计数文案。
    private func resolveFooterCountText() -> String {
        if viewModel.isDataEmpty {
            return "无数据"
        }
        if viewModel.filtered.isEmpty {
            return "无结果"
        }
        return "共 \(viewModel.filtered.count) 项 · 第 \(viewModel.selectedIndex + 1) 项"
    }

    /// 聚焦搜索框。
    private func executeFocusSearchField() {
        DispatchQueue.main.async {
            isSearchFocused = true
        }
    }

    /// 将选中行滚入可视区域。
    private func executeScrollToSelection(proxy: ScrollViewProxy, index: Int) {
        let items: [Gitmoji] = viewModel.filtered
        guard items.indices.contains(index) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.12)) {
            proxy.scrollTo(items[index].id, anchor: .center)
        }
    }
}
