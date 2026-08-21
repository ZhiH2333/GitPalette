//
//  GitResultPanelView.swift
//  GitPalette
//
//  Git 命令结果列表（复用 LazyVStack + ScrollViewReader）。
//

import SwiftUI

/// Git 结果面板。
struct GitResultPanelView: View {
    @ObservedObject var viewModel: GitResultViewModel
    let language: AppLanguage

    var body: some View {
        if viewModel.phase == .running {
            buildMessageState(
                systemImage: "arrow.triangle.2.circlepath",
                message: L10n.text(.gitResultRunning, language: language)
            )
        } else if viewModel.phase == .failed, let errorMessage: String = viewModel.errorMessage, !errorMessage.isEmpty {
            buildMessageState(systemImage: "exclamationmark.triangle", message: errorMessage)
        } else if viewModel.kind == .repos {
            buildReposList()
        } else if viewModel.kind == .commit {
            buildCommitLogList()
        } else if viewModel.entries.isEmpty {
            buildMessageState(
                systemImage: CommandSuggestion.resolveGitSubcommandSystemImageName("status"),
                message: viewModel.summaryText ?? L10n.text(.gitWorkingTreeClean, language: language)
            )
        } else {
            buildStatusList()
        }
    }

    /// 空态 / 错误 / 进行中。
    @ViewBuilder
    private func buildMessageState(systemImage: String, message: String) -> some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 结构化改动列表。
    @ViewBuilder
    private func buildStatusList() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if let summary: String = viewModel.summaryText, !summary.isEmpty, !viewModel.entries.isEmpty {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                    }
                    ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                        GitStatusRowView(
                            entry: entry,
                            language: language,
                            isSelected: index == viewModel.highlightedIndex,
                            isChecked: viewModel.selectedPaths.contains(entry.relativePath),
                            showsCheckbox: viewModel.kind == .add
                        )
                        .id(entry.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.executeActivateRow(at: index)
                        }
                    }
                }
                .padding(.horizontal, LauncherChrome.listHorizontalPadding)
                .padding(.vertical, 6)
            }
            .onChangeCompat(of: viewModel.highlightedIndex) { newValue in
                executeScrollToEntry(proxy: proxy, index: newValue)
            }
        }
    }

    /// 提交历史图。
    @ViewBuilder
    private func buildCommitLogList() -> some View {
        if viewModel.logEntries.isEmpty {
            buildMessageState(
                systemImage: CommandSuggestion.resolveGitSubcommandSystemImageName("commit"),
                message: resolveCommitEmptyMessage()
            )
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        if let summary: String = viewModel.summaryText, !summary.isEmpty {
                            Text(summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                        }
                        ForEach(Array(viewModel.logEntries.enumerated()), id: \.element.id) { index, entry in
                            GitLogRowView(
                                entry: entry,
                                isSelected: index == viewModel.highlightedIndex
                            )
                            .id(entry.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.executeActivateRow(at: index)
                            }
                        }
                    }
                    .padding(.horizontal, LauncherChrome.listHorizontalPadding)
                    .padding(.vertical, 6)
                }
                .onChangeCompat(of: viewModel.highlightedIndex) { newValue in
                    executeScrollToLogEntry(proxy: proxy, index: newValue)
                }
            }
        }
    }

    /// 已链接仓库列表。
    @ViewBuilder
    private func buildReposList() -> some View {
        if viewModel.repositories.isEmpty {
            buildMessageState(
                systemImage: CommandSuggestion.resolveGitSubcommandSystemImageName("repos"),
                message: viewModel.summaryText ?? L10n.text(.gitErrorNoLinkedRepository, language: language)
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(viewModel.repositories.enumerated()), id: \.element.id) { index, repository in
                        HStack(spacing: 14) {
                            Image(systemName: CommandSuggestion.resolveGitSubcommandSystemImageName("repos"))
                                .font(.body.weight(.medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 40, alignment: .center)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    Text(repository.displayName)
                                        .font(.body.weight(.medium).monospaced())
                                        .lineLimit(1)
                                    if repository.id == viewModel.activeRepositoryID {
                                        Text(L10n.text(.gitReposActiveMark, language: language))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                Text(repository.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            index == viewModel.highlightedIndex
                                ? Color.accentColor.opacity(0.22)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: LauncherChrome.rowCornerRadius, style: .continuous)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.executeActivateRow(at: index)
                        }
                    }
                }
                .padding(.horizontal, LauncherChrome.listHorizontalPadding)
                .padding(.vertical, 6)
            }
        }
    }

    /// 无提交列表时的空态文案。
    private func resolveCommitEmptyMessage() -> String {
        if let errorMessage: String = viewModel.errorMessage, !errorMessage.isEmpty {
            return errorMessage
        }
        return viewModel.summaryText ?? L10n.text(.gitLogEmpty, language: language)
    }

    /// 滚到高亮行。
    private func executeScrollToEntry(proxy: ScrollViewProxy, index: Int) {
        let items: [GitStatusEntry] = viewModel.entries
        guard items.indices.contains(index) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.12)) {
            proxy.scrollTo(items[index].id, anchor: .center)
        }
    }

    /// 滚到高亮提交行。
    private func executeScrollToLogEntry(proxy: ScrollViewProxy, index: Int) {
        let items: [GitLogEntry] = viewModel.logEntries
        guard items.indices.contains(index) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.12)) {
            proxy.scrollTo(items[index].id, anchor: .center)
        }
    }
}
