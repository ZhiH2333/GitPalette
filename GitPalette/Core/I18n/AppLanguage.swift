//
//  AppLanguage.swift
//  GitPalette
//
//  应用支持的语言（界面 / code 翻译 / 描述共用）。
//

import Foundation

/// 应用语言。
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    /// English
    case english
    /// 简体中文
    case simplifiedChinese

    var id: String { rawValue }

    /// 设置展示名（始终双语对照，避免切语言后看不懂选项）。
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        }
    }

    /// 根据系统语言给出默认值。
    static var systemDefault: AppLanguage {
        let codes: [String] = Locale.preferredLanguages.map { $0.lowercased() }
        if codes.contains(where: { $0.hasPrefix("zh") }) {
            return .simplifiedChinese
        }
        return .english
    }
}
