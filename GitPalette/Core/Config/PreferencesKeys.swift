//
//  PreferencesKeys.swift
//  GitPalette
//
//  UserDefaults 键名集中定义。
//

import Foundation

/// 偏好存储键。
enum PreferencesKeys {
    static let copyFormat: String = "gitpalette.copyFormat"
    static let copyTemplate: String = "gitpalette.copyTemplate"
    static let recentMaxCount: String = "gitpalette.recentMaxCount"
    static let recentGitmojiCodes: String = "gitpalette.recentGitmojiCodes"
    static let appearanceStyle: String = "gitpalette.appearanceStyle"
    static let uiLanguage: String = "gitpalette.uiLanguage"
    static let codeTranslationLanguage: String = "gitpalette.codeTranslationLanguage"
    static let descriptionLanguage: String = "gitpalette.descriptionLanguage"
    static let menuBarClickBehavior: String = "gitpalette.menuBarClickBehavior"
    static let linkedGitRepositories: String = "gitpalette.linkedGitRepositories"
    static let activeGitRepositoryID: String = "gitpalette.activeGitRepositoryID"
}
