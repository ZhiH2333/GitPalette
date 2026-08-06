//
//  GitmojiChineseAliases.swift
//  GitPalette
//
//  中文搜索别名：将常见中文关键词映射到英文 token / name。
//

import Foundation

/// Gitmoji 中文搜索别名表。
enum GitmojiChineseAliases {
    /// 中文关键词 → 额外匹配 token（英文描述片段或 name）
    static let map: [String: [String]] = [
        "性能": ["performance", "zap"],
        "优化": ["performance", "zap", "recycle"],
        "加速": ["performance", "zap"],
        "缺陷": ["bug"],
        "错误": ["bug", "fix"],
        "修复": ["bug", "fix", "ambulance", "adhesive"],
        "新功能": ["sparkles", "feature"],
        "特性": ["sparkles", "feature"],
        "文档": ["memo", "documentation"],
        "测试": ["test", "white-check-mark", "test-tube"],
        "重构": ["recycle", "refactor"],
        "依赖": ["arrow", "pushpin", "heavy-plus", "heavy-minus"],
        "配置": ["wrench", "configuration"],
        "安全": ["lock", "security"],
        "部署": ["rocket", "deploy"],
        "样式": ["lipstick", "style", "ui"],
        "界面": ["lipstick", "ui"],
        "删除": ["fire", "remove", "wastebasket", "coffin"],
        "合并": ["merge", "twisted"],
        "发布": ["bookmark", "release"],
        "无障碍": ["wheelchair", "accessibility"],
        "国际化": ["globe", "i18n", "localization"],
        "实验": ["alembic", "experiment"],
        "架构": ["building-construction", "architectural"],
        "日志": ["loud-sound", "mute", "log"],
        "类型": ["label", "types"],
        "验证": ["safety-vest", "validation"],
        "权限": ["passport-control", "authorization"],
        "兼容": ["t-rex", "compatibility"],
        "离线": ["airplane", "offline"]
    ]

    /// 根据查询展开额外搜索 token。
    static func expandTokens(from query: String) -> [String] {
        var tokens: [String] = [query]
        for (alias, values) in map where query.contains(alias) {
            tokens.append(contentsOf: values)
        }
        return tokens
    }
}
