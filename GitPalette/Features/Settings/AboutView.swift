//
//  AboutView.swift
//  GitPalette
//
//  关于页极简占位。
//

import SwiftUI

/// 关于信息视图。
struct AboutView: View {
    let appName: String
    let hotkeyDisplayText: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            Text(appName)
                .font(.title2.weight(.semibold))
            Text("菜单栏 Gitmoji 助手")
                .foregroundStyle(.secondary)
            Text("全局热键：\(hotkeyDisplayText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 280, height: 200)
    }
}
