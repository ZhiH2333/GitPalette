//
//  GitmojiRepository.swift
//  GitPalette
//
//  Gitmoji 数据仓库协议（预留网络实现，本阶段仅 Bundle）。
//

import Foundation

/// Gitmoji 数据访问协议。
protocol GitmojiRepository {
    /// 全部 Gitmoji。
    var all: [Gitmoji] { get }
    /// 按关键词本地搜索；空查询返回全部。
    func search(query: String) -> [Gitmoji]
}
