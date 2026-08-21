//
//  GitRepository.swift
//  GitPalette
//
//  已链接的本地 Git 仓库标识。
//

import Foundation

/// 可解析为本地文件 URL 的仓库路径。
/// 当前实现为纯路径字符串；后续可替换为安全作用域书签而不改上层调用。
struct GitResolvablePath: Equatable, Sendable, Codable {
    /// 持久化存储值（路径字符串）
    let storedValue: String

    /// 解析为文件 URL。
    func resolveFileURL() -> URL {
        URL(fileURLWithPath: storedValue)
    }
}

/// 已链接仓库。
struct GitRepository: Identifiable, Equatable, Sendable, Codable {
    /// 稳定标识
    let id: String
    /// 展示名（通常为目录名）
    let displayName: String
    /// 可解析路径
    let resolvablePath: GitResolvablePath

    /// 本地路径字符串。
    var path: String {
        resolvablePath.storedValue
    }

    /// 解析工作区根目录 URL。
    func resolveFileURL() -> URL {
        resolvablePath.resolveFileURL()
    }
}
