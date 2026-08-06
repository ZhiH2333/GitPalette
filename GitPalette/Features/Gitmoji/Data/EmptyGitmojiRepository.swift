//
//  EmptyGitmojiRepository.swift
//  GitPalette
//
//  Bundle 加载失败时的空仓库回退。
//

import Foundation

/// 空 Gitmoji 仓库（无数据）。
final class EmptyGitmojiRepository: GitmojiRepository {
    var all: [Gitmoji] { [] }

    func search(query: String) -> [Gitmoji] { [] }
}
