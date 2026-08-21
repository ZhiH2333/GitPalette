//
//  CommandsSettingsTab.swift
//  GitPalette
//
//  设置 · 全部指令：树形浏览斜杠命令与参数。
//

import SwiftUI

/// 全部指令说明页（Outline 树）。
struct CommandsSettingsTab: View {
    @ObservedObject var preferences: PreferencesStore

    var body: some View {
        List {
            OutlineGroup(
                CommandHelpNode.resolveRoots(language: preferences.uiLanguage),
                children: \.children
            ) { node in
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.title)
                        .font(node.isCommand ? .body.monospaced() : .body)
                    if let detail: String = node.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.inset)
    }
}

/// 指令帮助树节点。
struct CommandHelpNode: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String?
    let isCommand: Bool
    let children: [CommandHelpNode]?

    /// 由全部命令生成根节点。
    static func resolveRoots(language: AppLanguage) -> [CommandHelpNode] {
        LauncherCommandRegistry.allCommands.map { command in
            executeMakeCommandNode(command, language: language)
        }
    }

    /// 构造单条命令节点及其参数子树。
    private static func executeMakeCommandNode(
        _ command: LauncherCommand,
        language: AppLanguage
    ) -> CommandHelpNode {
        let argumentNodes: [CommandHelpNode] = executeMakeArgumentNodes(
            for: command,
            language: language
        )
        return CommandHelpNode(
            id: "cmd-" + command.name,
            title: command.displayName,
            detail: command.summary(language: language),
            isCommand: true,
            children: argumentNodes.isEmpty ? nil : argumentNodes
        )
    }

    /// 构造参数 / 子命令节点。
    private static func executeMakeArgumentNodes(
        for command: LauncherCommand,
        language: AppLanguage
    ) -> [CommandHelpNode] {
        switch command {
        case .settings:
            return [
                executeMakeArgumentNode(
                    command: command,
                    value: "general",
                    summaryKey: .cmdArgSettingsGeneral,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "language",
                    summaryKey: .cmdArgSettingsLanguage,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "hotkey",
                    summaryKey: .cmdArgSettingsHotkey,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "commands",
                    summaryKey: .cmdArgSettingsCommands,
                    language: language
                )
            ]
        case .language, .codelang, .desclang:
            return [
                executeMakeArgumentNode(
                    command: command,
                    value: "chinese",
                    summaryKey: .cmdArgLangChinese,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "english",
                    summaryKey: .cmdArgLangEnglish,
                    language: language
                )
            ]
        case .style:
            return [
                executeMakeArgumentNode(
                    command: command,
                    value: "auto",
                    summaryKey: .cmdArgStyleAuto,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "liquid",
                    summaryKey: .cmdArgStyleLiquid,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "material",
                    summaryKey: .cmdArgStyleMaterial,
                    language: language
                )
            ]
        case .format:
            return [
                executeMakeArgumentNode(
                    command: command,
                    value: "emoji",
                    summaryKey: .cmdArgFormatEmoji,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "code",
                    summaryKey: .cmdArgFormatCode,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "template",
                    summaryKey: .cmdArgFormatTemplate,
                    language: language
                )
            ]
        case .menubar:
            return [
                executeMakeArgumentNode(
                    command: command,
                    value: "menu",
                    summaryKey: .cmdArgMenubarMenu,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "launcher",
                    summaryKey: .cmdArgMenubarLauncher,
                    language: language
                )
            ]
        case .recent:
            return [
                executeMakeArgumentNode(
                    command: command,
                    value: "clear",
                    summaryKey: .cmdArgRecentClear,
                    language: language
                ),
                CommandHelpNode(
                    id: "arg-\(command.name)-count",
                    title: "count",
                    detail: L10n.text(.cmdArgRecentCount, language: language),
                    isCommand: false,
                    children: [
                        CommandHelpNode(
                            id: "arg-\(command.name)-count-n",
                            title: "<n>",
                            detail: "5…20",
                            isCommand: false,
                            children: nil
                        )
                    ]
                )
            ]
        case .template:
            return [
                CommandHelpNode(
                    id: "arg-template-hint",
                    title: "{emoji} {code}",
                    detail: L10n.text(.cmdArgTemplateHint, language: language),
                    isCommand: false,
                    children: nil
                )
            ]
        case .git:
            return [
                executeMakeArgumentNode(
                    command: command,
                    value: "link",
                    summaryKey: .cmdArgGitLink,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "repos",
                    summaryKey: .cmdArgGitRepos,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "use",
                    summaryKey: .cmdArgGitUse,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "unlink",
                    summaryKey: .cmdArgGitUnlink,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "status",
                    summaryKey: .cmdArgGitStatus,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "add",
                    summaryKey: .cmdArgGitAdd,
                    language: language
                ),
                executeMakeArgumentNode(
                    command: command,
                    value: "commit",
                    summaryKey: .cmdArgGitCommit,
                    language: language
                )
            ]
        case .general, .hotkey, .about, .permissions, .quit, .hide, .help:
            return []
        }
    }

    /// 构造单层参数节点。
    private static func executeMakeArgumentNode(
        command: LauncherCommand,
        value: String,
        summaryKey: L10nKey,
        language: AppLanguage
    ) -> CommandHelpNode {
        CommandHelpNode(
            id: "arg-\(command.name)-\(value)",
            title: value,
            detail: L10n.text(summaryKey, language: language),
            isCommand: false,
            children: nil
        )
    }
}
