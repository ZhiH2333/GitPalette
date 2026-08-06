//
//  ViewCompatibility.swift
//  GitPalette
//
//  macOS 13+ 兼容的 SwiftUI 辅助扩展。
//

import SwiftUI

extension View {
    /// 兼容 macOS 13 的 onChange（单参数）；14+ 使用双参数 API。
    @ViewBuilder
    func onChangeCompat<V: Equatable>(
        of value: V,
        perform action: @escaping (V) -> Void
    ) -> some View {
        if #available(macOS 14.0, *) {
            onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            onChange(of: value, perform: action)
        }
    }
}
