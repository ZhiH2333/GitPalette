//
//  CommandRowView.swift
//  GitPalette
//
//  命令建议行 UI（视觉对齐 GitmojiRowView）。
//

import SwiftUI

/// 命令建议列表行。
struct CommandRowView: View {
    let suggestion: CommandSuggestion
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(suggestion.primaryText)
                        .font(.body.weight(.medium).monospaced())
                        .lineLimit(1)
                    if let secondary: String = suggestion.secondaryText, !secondary.isEmpty {
                        Text(secondary)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                Text(suggestion.summary)
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
