//
//  GitmojiListView.swift
//  GitPalette
//
//  Spotlight 风格可搜索 Gitmoji 列表（供启动器浮动面板承载）。
//

import SwiftUI

/// Gitmoji 搜索与复制主界面。
struct GitmojiListView: View {
    @ObservedObject var appConfig: AppConfig
    @ObservedObject var viewModel: GitmojiListViewModel
    let focusToken: UUID
    let onDismiss: () -> Void
    let onConfirmCopy: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            buildSpotlightSearchRow()
            Divider().opacity(0.22)
            if viewModel.shouldShowRecentSection {
                buildRecentSection()
                Divider().opacity(0.18)
            }
            buildResultArea()
            buildFooter()
        }
        .frame(width: LauncherChrome.contentWidth, height: LauncherChrome.contentHeight)
    }

    /// Spotlight 风格搜索行：放大镜 + 大字号输入 + 清除。
    @ViewBuilder
    private func buildSpotlightSearchRow() -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: LauncherChrome.searchIconPointSize, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .center)
            GitmojiSearchField(
                text: $viewModel.query,
                placeholder: "搜索 Gitmoji",
                focusToken: focusToken,
                onSubmit: onConfirmCopy,
                onCancel: onDismiss
            )
            .frame(maxWidth: .infinity, minHeight: 28)
            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("清除")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(minHeight: LauncherChrome.searchRowMinHeight)
    }

    /// 构建最近使用区（支持键盘左右选中）。
    @ViewBuilder
    private func buildRecentSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近使用")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(viewModel.recentItems.enumerated()), id: \.element.id) { index, item in
                            Button {
                                viewModel.executeSelectRecentIndex(index)
                                viewModel.executeCopy(item)
                                onDismiss()
                            } label: {
                                Text(item.emoji)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        resolveRecentItemBackground(isSelected: isRecentSelected(index)),
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(
                                                isRecentSelected(index)
                                                    ? Color.accentColor.opacity(0.85)
                                                    : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    }
                            }
                            .buttonStyle(.plain)
                            .help(item.code)
                            .id(item.id)
                        }
                    }
                }
                .onChangeCompat(of: viewModel.recentSelectedIndex) { newValue in
                    executeScrollToRecentSelection(proxy: proxy, index: newValue)
                }
                .onChangeCompat(of: viewModel.selectionFocus) { focus in
                    if focus == .recent {
                        executeScrollToRecentSelection(proxy: proxy, index: viewModel.recentSelectedIndex)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    /// 最近项是否处于键盘选中。
    private func isRecentSelected(_ index: Int) -> Bool {
        viewModel.selectionFocus == .recent && index == viewModel.recentSelectedIndex
    }

    /// 最近项背景。
    private func resolveRecentItemBackground(isSelected: Bool) -> Color {
        if isSelected {
            return Color.accentColor.opacity(0.22)
        }
        return Color.primary.opacity(0.06)
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
                        GitmojiRowView(
                            item: item,
                            isSelected: viewModel.selectionFocus == .list
                                && index == viewModel.selectedIndex
                        )
                        .id(item.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.executeSelectIndex(index)
                            viewModel.executeCopy(item)
                            onDismiss()
                        }
                    }
                }
                .padding(.horizontal, LauncherChrome.listHorizontalPadding)
                .padding(.vertical, 6)
            }
            .onChangeCompat(of: viewModel.selectedIndex) { newValue in
                guard viewModel.selectionFocus == .list else {
                    return
                }
                executeScrollToSelection(proxy: proxy, index: newValue)
            }
            .onChangeCompat(of: viewModel.selectionFocus) { focus in
                if focus == .list {
                    executeScrollToSelection(proxy: proxy, index: viewModel.selectedIndex)
                }
            }
        }
    }

    /// 构建底部状态栏（格式切换 + 计数，不抢搜索焦点）。
    @ViewBuilder
    private func buildFooter() -> some View {
        HStack(spacing: 10) {
            Picker("复制格式", selection: $appConfig.copyFormat) {
                ForEach(CopyFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: 140)
            Text(resolveFooterCountText())
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if let feedback: String = viewModel.copyFeedbackText {
                Text(feedback)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            } else {
                Text(resolveHintText())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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
        if viewModel.selectionFocus == .recent {
            return "最近 \(viewModel.recentItems.count) 项"
        }
        return "\(viewModel.filtered.count) 项"
    }

    /// 底部操作提示。
    private func resolveHintText() -> String {
        if viewModel.shouldShowRecentSection {
            return "↑↓←→ 选择 · ⏎ 复制"
        }
        return "↑↓ 选择 · ⏎ 复制"
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

    /// 将最近选中项滚入可视区域。
    private func executeScrollToRecentSelection(proxy: ScrollViewProxy, index: Int) {
        let items: [Gitmoji] = viewModel.recentItems
        guard items.indices.contains(index) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.12)) {
            proxy.scrollTo(items[index].id, anchor: .center)
        }
    }
}
