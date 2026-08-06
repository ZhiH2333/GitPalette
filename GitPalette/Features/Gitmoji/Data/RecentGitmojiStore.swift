//
//  RecentGitmojiStore.swift
//  GitPalette
//
//  最近使用的 Gitmoji（UserDefaults 持久化 code 列表）。
//

import Foundation

/// 最近使用记录存储。
final class RecentGitmojiStore {
    private let defaults: UserDefaults
    private let storageKey: String
    private let maxCount: Int

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "gitpalette.recentGitmojiCodes",
        maxCount: Int = 8
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.maxCount = maxCount
    }

    /// 读取最近使用的 code 列表（新到旧）。
    func loadCodes() -> [String] {
        defaults.stringArray(forKey: storageKey) ?? []
    }

    /// 将指定 code 记为最近使用。
    func executeRecord(code: String) {
        var codes: [String] = loadCodes().filter { $0 != code }
        codes.insert(code, at: 0)
        if codes.count > maxCount {
            codes = Array(codes.prefix(maxCount))
        }
        defaults.set(codes, forKey: storageKey)
    }
}
