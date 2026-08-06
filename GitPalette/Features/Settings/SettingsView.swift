//
//  SettingsView.swift
//  GitPalette
//
//  设置场景占位视图。
//

import SwiftUI

/// 设置窗口占位内容。
struct SettingsView: View {
    var body: some View {
        Text("设置（占位）")
            .font(.title2)
            .frame(width: 360, height: 220)
            .navigationTitle("设置")
    }
}

#Preview {
    SettingsView()
}
