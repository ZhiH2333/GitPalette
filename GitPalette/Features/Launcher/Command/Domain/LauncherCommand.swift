//
//  LauncherCommand.swift
//  GitPalette
//
//  启动器「/」命令枚举：名称、别名、简述与参数取值域。
//

import Foundation

/// 启动器斜杠命令。
enum LauncherCommand: String, CaseIterable, Identifiable, Sendable {
    case settings
    case general
    case hotkey
    case about
    case permissions
    case language
    case codelang
    case desclang
    case style
    case format
    case template
    case recent
    case quit
    case hide
    case help

    var id: String { rawValue }

    /// 规范命令名（不含前导 /）。
    var name: String { rawValue }

    /// 带前导 / 的展示名。
    var displayName: String { "/" + rawValue }

    /// 别名（不含前导 /，小写）。
    var aliases: [String] {
        switch self {
        case .settings:
            return ["setting", "preferences"]
        case .hotkey:
            return ["shortcut"]
        case .permissions:
            return ["accessibility"]
        case .quit:
            return ["exit"]
        case .help:
            return ["?", "commands"]
        case .general, .about, .language, .codelang, .desclang,
                .style, .format, .template, .recent, .hide:
            return []
        }
    }

    /// 中文简述。
    var summary: String {
        switch self {
        case .settings:
            return "打开设置（可选 general / language / hotkey）"
        case .general:
            return "打开设置 · 通用"
        case .hotkey:
            return "打开设置 · 快捷键"
        case .about:
            return "打开关于窗口"
        case .permissions:
            return "打开辅助功能权限引导"
        case .language:
            return "设置界面语言（english / chinese）"
        case .codelang:
            return "设置 Code 翻译语言（english / chinese）"
        case .desclang:
            return "设置描述语言（english / chinese）"
        case .style:
            return "设置外观（auto / liquid / material）"
        case .format:
            return "设置复制格式（emoji / code / template）"
        case .template:
            return "设置自定义复制模板内容"
        case .recent:
            return "最近使用：clear 或 count <5…20>"
        case .quit:
            return "退出应用"
        case .hide:
            return "关闭启动器面板"
        case .help:
            return "列出全部命令"
        }
    }

    // TODO(后续): /reset — 一键恢复默认设置（本阶段不实现）

    /// 参数取值域描述（无参数时为 nil）。
    var argumentDomainDescription: String? {
        switch self {
        case .settings:
            return "general | language | hotkey（可省略，默认 general）"
        case .language, .codelang, .desclang:
            return "english | chinese（中文 / zh）"
        case .style:
            return "auto | liquid（glass）| material"
        case .format:
            return "emoji | code | template"
        case .template:
            return "任意模板文本（如 {emoji} {code}）"
        case .recent:
            return "clear | count <n>"
        case .general, .hotkey, .about, .permissions, .quit, .hide, .help:
            return nil
        }
    }

    /// 补全命令名后是否追加尾随空格（表示还可继续补参数）。
    var shouldAppendTrailingSpaceAfterName: Bool {
        switch self {
        case .settings, .language, .codelang, .desclang,
                .style, .format, .template, .recent:
            return true
        case .general, .hotkey, .about, .permissions, .quit, .hide, .help:
            return false
        }
    }

    /// 是否为「仅浏览」命令（执行无副作用）。
    var isViewOnly: Bool {
        self == .help
    }
}
