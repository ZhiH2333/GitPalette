//
//  GitmojiListView.swift
//  GitPalette
//
//  Spotlight 风格可搜索 Gitmoji 列表（供启动器浮动面板承载）。
//

import SwiftUI

/// Gitmoji 搜索与复制主界面（含「/」命令模式互斥展示）。
struct GitmojiListView: View {
    @ObservedObject var appConfig: AppConfig
    @ObservedObject var viewModel: GitmojiListViewModel
    @ObservedObject var commandViewModel: LauncherCommandViewModel
    let focusToken: UUID
    let onDismiss: () -> Void
    let onDismissWithoutFocusRestore: () -> Void
    let onConfirmCopy: () -> Void
    let onRequestComplete: (String) -> String?

    var body: some View {
        VStack(spacing: 0) {
            buildSpotlightSearchRow()
            Divider().opacity(0.22)
            if !commandViewModel.isCommandMode, viewModel.shouldShowRecentSection {
                buildRecentSection()
                Divider().opacity(0.18)
            }
            buildResultArea()
            buildFooter()
        }
        .frame(width: LauncherChrome.contentWidth, height: LauncherChrome.contentHeight)
        .onChangeCompat(of: viewModel.query) { newValue in
            commandViewModel.executeUpdateQuery(newValue)
        }
        .onAppear {
            commandViewModel.executeUpdateQuery(viewModel.query)
        }
    }

    /// Spotlight 风格搜索行：放大镜 + 大字号输入 + 清除。
    @ViewBuilder
    private func buildSpotlightSearchRow() -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: commandViewModel.isCommandMode ? "chevron.left.forwardslash.chevron.right" : "magnifyingglass")
                .font(.system(size: LauncherChrome.searchIconPointSize, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .center)
            GitmojiSearchField(
                text: $viewModel.query,
                placeholder: commandViewModel.isCommandMode
                    ? appConfig.t(.commandSearchPlaceholder)
                    : appConfig.t(.searchPlaceholder),
                ghostSuffix: commandViewModel.resolveGhostSuffix(for: viewModel.query),
                focusToken: focusToken,
                onSubmit: onConfirmCopy,
                onCancel: onDismiss,
                onRequestComplete: onRequestComplete,
                shouldConsumeGitAddKeys: commandViewModel.gitResultViewModel?.kind == .add
            )
            .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)
            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(appConfig.t(.clear))
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
            Text(appConfig.t(.recentUsed))
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
                            .help(appConfig.resolveLocalizedCode(for: item))
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

    /// 构建结果区（命令模式 / 列表 / 空态）。
    @ViewBuilder
    private func buildResultArea() -> some View {
        if let gitResult: GitResultViewModel = commandViewModel.gitResultViewModel {
            GitResultPanelView(
                viewModel: gitResult,
                language: appConfig.descriptionLanguage
            )
        } else if commandViewModel.isCommandMode {
            buildCommandResultArea()
        } else if viewModel.isDataEmpty {
            buildEmptyState(message: appConfig.t(.noGitmojiData))
        } else if viewModel.filtered.isEmpty {
            buildEmptyState(message: appConfig.t(.noMatch))
        } else {
            buildList()
        }
    }

    /// 命令模式结果区。
    @ViewBuilder
    private func buildCommandResultArea() -> some View {
        if let message: String = commandViewModel.statusMessage, !message.isEmpty {
            buildEmptyState(message: message)
        } else if commandViewModel.suggestions.isEmpty {
            let fallback: String =
                commandViewModel.parseResult.validationMessage ?? L10n.text(.cmdNoMatch, language: appConfig.descriptionLanguage)
            buildEmptyState(message: fallback)
        } else {
            buildCommandList()
        }
    }

    /// 命令建议列表。
    @ViewBuilder
    private func buildCommandList() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(commandViewModel.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                        CommandRowView(
                            suggestion: suggestion,
                            isSelected: index == commandViewModel.selectedIndex
                        )
                        .id(suggestion.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            executeActivateCommandSuggestion(at: index)
                        }
                    }
                }
                .padding(.horizontal, LauncherChrome.listHorizontalPadding)
                .padding(.vertical, 6)
            }
            .onChangeCompat(of: commandViewModel.selectedIndex) { newValue in
                executeScrollToCommandSelection(proxy: proxy, index: newValue)
            }
        }
    }

    /// 点击命令建议：可执行则执行并关闭，否则补全。
    private func executeActivateCommandSuggestion(at index: Int) {
        let outcome: LauncherCommandExecutionOutcome? =
            commandViewModel.executeActivateSuggestion(
                at: index,
                currentQuery: viewModel.query,
                applyCompletion: { completed in
                    viewModel.query = completed
                }
            )
        guard let outcome else {
            return
        }
        switch outcome {
        case .dismissed(let shouldRestoreFocus):
            if shouldRestoreFocus {
                onDismiss()
            } else {
                onDismissWithoutFocusRestore()
            }
        case .quitApp:
            onDismissWithoutFocusRestore()
        case .keptOpen:
            break
        case .presentingResult:
            break
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
                            codeText: appConfig.resolveLocalizedCode(for: item),
                            descriptionText: appConfig.resolveLocalizedDescription(for: item),
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
        HStack(alignment: .center, spacing: LauncherChrome.footerSpacing) {
            if commandViewModel.isCommandMode {
                Text(resolveCommandFooterStatusText())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(appConfig.t(.commandHint))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            } else {
                Picker(appConfig.t(.copyFormatMenu), selection: $appConfig.copyFormat) {
                    ForEach(CopyFormat.allCases) { format in
                        Text(format.displayName(language: appConfig.uiLanguage)).tag(format)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 140)
                Text(resolveFooterCountText())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let feedback: String = viewModel.copyFeedbackText {
                    Text(feedback)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .lineLimit(1)
                } else {
                    Text(resolveHintText())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, LauncherChrome.footerHorizontalPadding)
        .padding(.vertical, LauncherChrome.footerVerticalPadding)
    }

    /// 命令模式底部状态（跟随 UI 语言）：「命令模式 15 条建议」。
    private func resolveCommandFooterStatusText() -> String {
        if commandViewModel.gitResultViewModel != nil {
            if commandViewModel.gitResultViewModel?.kind == .add {
                return appConfig.t(.gitHintAdd)
            }
            return appConfig.t(.gitHintStatus)
        }
        if commandViewModel.suggestions.isEmpty {
            return "\(appConfig.t(.commandMode)) · \(appConfig.t(.cmdNoMatch))"
        }
        return "\(appConfig.t(.commandMode)) \(commandViewModel.suggestions.count)\(appConfig.t(.suggestionCount))"
    }

    /// 底部计数文案。
    private func resolveFooterCountText() -> String {
        if viewModel.isDataEmpty {
            return appConfig.t(.noData)
        }
        if viewModel.filtered.isEmpty {
            return appConfig.t(.noResult)
        }
        if viewModel.selectionFocus == .recent {
            return appConfig.t(.recentCount) + "\(viewModel.recentItems.count)" + appConfig.t(.itemCount)
        }
        return "\(viewModel.filtered.count)" + appConfig.t(.itemCount)
    }

    /// 底部操作提示。
    private func resolveHintText() -> String {
        if viewModel.shouldShowRecentSection {
            return appConfig.t(.hintWithRecent)
        }
        return appConfig.t(.hintListOnly)
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

    /// 将命令选中行滚入可视区域。
    private func executeScrollToCommandSelection(proxy: ScrollViewProxy, index: Int) {
        let items: [CommandSuggestion] = commandViewModel.suggestions
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
