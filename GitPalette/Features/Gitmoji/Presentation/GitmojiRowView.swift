//
//  GitmojiRowView.swift
//  GitPalette
//
//  单行 Gitmoji 展示（Spotlight 级选中圆角）。
//

import SwiftUI

/// Gitmoji 列表行。
struct GitmojiRowView: View {
    let item: Gitmoji
    let codeText: String
    let descriptionText: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(item.emoji)
                .font(.title2)
                .frame(width: 40, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(codeText)
                    .font(.body.weight(.medium).monospaced())
                    .lineLimit(1)
                Text(descriptionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            isSelected
                ? Color.accentColor.opacity(0.22)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: LauncherChrome.rowCornerRadius, style: .continuous)
        )
        .contentShape(Rectangle())
    }
}
