//
//  GitLogRowView.swift
//  GitPalette
//
//  提交历史图列表行。
//

import SwiftUI

/// git log --graph 单行。
struct GitLogRowView: View {
    let entry: GitLogEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(entry.graphPrefix)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if !entry.hash.isEmpty {
                Text(entry.hash)
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.subject.isEmpty ? " " : entry.subject)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                if let decorations: String = entry.decorations, !decorations.isEmpty {
                    Text(decorations)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
