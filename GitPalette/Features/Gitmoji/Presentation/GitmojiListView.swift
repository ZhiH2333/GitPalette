//
//  GitmojiListView.swift
//  GitPalette
//
//  可搜索 Gitmoji 列表 UI（临时启动器窗口内容）。
//

import SwiftUI

/// Gitmoji 搜索与复制主界面。
struct GitmojiListView: View {
    @Bindable var appConfig: AppConfig
    @State private var viewModel: GitmojiListViewModel
    @FocusState private var isSearchFocused: Bool

    init(appConfig: AppConfig, repository: GitmojiRepository? = nil) {
        self.appConfig = appConfig
        let resolvedRepository: GitmojiRepository
        if let repository {
            resolvedRepository = repository
        } else {
            resolvedRepository = (try? BundleGitmojiRepository()) ?? EmptyGitmojiRepository()
        }
        _viewModel = State(
            initialValue: GitmojiListViewModel(
                repository: resolvedRepository,
                appConfig: appConfig
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            buildToolbar()
            Divider()
            if shouldShowRecentSection {
                buildRecentSection()
                Divider()
            }
            buildList()
            buildFooter()
        }
        .frame(minWidth: 420, minHeight: 480)
        .onAppear {
            isSearchFocused = true
        }
    }

    /// 是否展示最近使用区（仅空查询且有记录时）。
    private var shouldShowRecentSection: Bool {
        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.recentItems.isEmpty
    }

    /// 构建顶部搜索与格式切换。
    @ViewBuilder
    private func buildToolbar() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("搜索 code、描述、名称…", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)
                .focused($isSearchFocused)
                .onSubmit {
                    viewModel.copySelected()
                }
            HStack {
                Text("复制格式")
                    .foregroundStyle(.secondary)
                Picker("复制格式", selection: $appConfig.copyFormat) {
                    Text("emoji").tag(CopyFormat.emoji)
                    Text(":code:").tag(CopyFormat.code)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
                Spacer()
                Button("复制") {
                    viewModel.copySelected()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(12)
    }

    /// 构建最近使用横向区。
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    /// 构建主列表。
    @ViewBuilder
    private func buildList() -> some View {
        List(Array(viewModel.filtered.enumerated()), id: \.element.id) { index, item in
            GitmojiRowView(item: item, isSelected: index == viewModel.selectedIndex)
                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.executeSelectIndex(index)
                    viewModel.executeCopy(item)
                }
        }
        .listStyle(.plain)
    }

    /// 构建底部状态栏。
    @ViewBuilder
    private func buildFooter() -> some View {
        HStack {
            Text("共 \(viewModel.filtered.count) 项")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if let feedback: String = viewModel.copyFeedbackText {
                Text(feedback)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
