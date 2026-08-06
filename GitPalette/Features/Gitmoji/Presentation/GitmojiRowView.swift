//
//  GitmojiRowView.swift
//  GitPalette
//
//  单行 Gitmoji 展示。
//

import SwiftUI

/// Gitmoji 列表行。
struct GitmojiRowView: View {
    let item: Gitmoji
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.title2)
                .frame(width: 36, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.code)
                    .font(.body.monospaced())
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }
}
