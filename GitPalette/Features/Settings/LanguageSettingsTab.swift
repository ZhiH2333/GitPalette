//
//  LanguageSettingsTab.swift
//  GitPalette
//
//  设置 · 语言：界面 / Code 翻译 / 描述。
//

import SwiftUI

/// 语言设置页。
struct LanguageSettingsTab: View {
    @ObservedObject var preferences: PreferencesStore

    var body: some View {
        Form {
            Section(preferences.t(.sectionUILanguage)) {
                Picker(preferences.t(.uiLanguage), selection: $preferences.uiLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.radioGroup)
                Text(preferences.t(.languageHintUI))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section(preferences.t(.sectionCodeTranslation)) {
                Picker(preferences.t(.codeTranslationLanguage), selection: $preferences.codeTranslationLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.radioGroup)
                Text(preferences.t(.languageHintCode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section(preferences.t(.sectionDescriptionLanguage)) {
                Picker(preferences.t(.descriptionLanguage), selection: $preferences.descriptionLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.radioGroup)
                Text(preferences.t(.languageHintDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
