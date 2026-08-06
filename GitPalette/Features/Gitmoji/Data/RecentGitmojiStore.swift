//
//  RecentGitmojiStore.swift
//  GitPalette
//
//  最近使用的 Gitmoji（UserDefaults 持久化；数量由 PreferencesStore 控制）。
//

import Foundation

/// 最近使用记录存储。
final class RecentGitmojiStore {
    private let defaults: UserDefaults
    private let storageKey: String
    private let resolveMaxCount: () -> Int

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = PreferencesKeys.recentGitmojiCodes,
        resolveMaxCount: @escaping () -> Int = { PreferencesStore.defaultRecentMaxCount }
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.resolveMaxCount = resolveMaxCount
    }

    /// 读取最近使用的 code 列表（新到旧）。
    func loadCodes() -> [String] {
        let codes: [String] = defaults.stringArray(forKey: storageKey) ?? []
        let maxCount: Int = resolveMaxCount()
        if codes.count > maxCount {
            return Array(codes.prefix(maxCount))
        }
        return codes
    }

    /// 将指定 code 记为最近使用。
    func executeRecord(code: String) {
        let maxCount: Int = resolveMaxCount()
        var codes: [String] = loadCodes().filter { $0 != code }
        codes.insert(code, at: 0)
        if codes.count > maxCount {
            codes = Array(codes.prefix(maxCount))
        }
        defaults.set(codes, forKey: storageKey)
    }

    /// 清空最近使用。
    func executeClear() {
        defaults.removeObject(forKey: storageKey)
    }
}
