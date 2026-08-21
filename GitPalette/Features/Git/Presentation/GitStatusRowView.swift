//
//  GitStatusRowView.swift
//  GitPalette
//
//  Git 状态列表行（对齐 GitmojiRowView；add 模式带 checkbox）。
//

import SwiftUI

/// Git 工作区改动行。
struct GitStatusRowView: View {
    let entry: GitStatusEntry
    let language: AppLanguage
    let isSelected: Bool
    let isChecked: Bool
    let showsCheckbox: Bool

    var body: some View {
        HStack(spacing: 14) {
            if showsCheckbox {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.body.weight(.medium))
                    .foregroundStyle(isChecked ? Color.accentColor : Color.secondary)
                    .frame(width: 22, alignment: .center)
            }
            Text(entry.kind.porcelainMark)
                .font(.body.weight(.semibold).monospaced())
                .foregroundStyle(resolveMarkColor())
                .frame(width: 40, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(resolvePrimaryText())
                    .font(.body.weight(.medium).monospaced())
                    .lineLimit(1)
                Text(entry.kind.displayName(language: language))
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

    /// 路径展示（重命名显示 old → new）。
    private func resolvePrimaryText() -> String {
        if let original: String = entry.originalPath {
            return original + " → " + entry.relativePath
        }
        return entry.relativePath
    }

    /// 状态标记颜色。
    private func resolveMarkColor() -> Color {
        switch entry.kind {
        case .modified:
            return .orange
        case .added:
            return .green
        case .deleted:
            return .red
        case .untracked:
            return .secondary
        case .renamed:
            return .blue
        }
    }
}
