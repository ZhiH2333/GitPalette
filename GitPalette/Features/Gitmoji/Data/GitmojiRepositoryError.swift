//
//  GitmojiRepositoryError.swift
//  GitPalette
//
//  Gitmoji 仓库错误定义。
//

import Foundation

/// Bundle / 仓库加载错误。
enum GitmojiRepositoryError: Error, LocalizedError {
    case resourceNotFound

    var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            return "未找到 Bundle 内的 gitmojis.json"
        }
    }
}
