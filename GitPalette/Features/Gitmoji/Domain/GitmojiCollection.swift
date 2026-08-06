//
//  GitmojiCollection.swift
//  GitPalette
//
//  官方 API 根对象解码容器。
//

import Foundation

/// 官方 `gitmojis` 数组根容器。
struct GitmojiCollection: Codable, Sendable {
    let gitmojis: [Gitmoji]
}
