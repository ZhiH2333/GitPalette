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
        } else if viewModel.kind == .commit, let summary: String = viewModel.summaryText {
            buildMessageState(systemImage: "checkmark.circle", message: summary)
        } else if viewModel.entries.isEmpty {
            buildMessageState(
                systemImage: "checkmark.circle",
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

    /// 已链接仓库列表。
    @ViewBuilder
    private func buildReposList() -> some View {
        if viewModel.repositories.isEmpty {
            buildMessageState(
                systemImage: "folder",
                message: viewModel.summaryText ?? L10n.text(.gitErrorNoLinkedRepository, language: language)
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.repositories) { repository in
                        HStack(spacing: 14) {
                            Image(systemName: "folder")
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
                    }
                }
                .padding(.horizontal, LauncherChrome.listHorizontalPadding)
                .padding(.vertical, 6)
            }
        }
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
}
