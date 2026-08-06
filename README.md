# GitPalette

面向 macOS 的菜单栏 Gitmoji 助手（Menu Bar Agent）。当前仓库处于 **App Shell 阶段**：只搭建架构骨架与占位 UI，不包含搜索、复制、全局热键、AI 或网络同步。

## 产品定位

- **形态**：`LSUIElement` 菜单栏应用，无 Dock 图标，无主窗口业务
- **目标体验**：快捷唤起 Gitmoji 调色板，快速搜索并复制到提交信息（后续阶段）
- **平台**：macOS 26（Tahoe），Swift 6 + SwiftUI，面向 Liquid Glass
- **状态管理**：Observation（`@Observable`），不引入 TCA / Combine 全家桶
- **依赖**：本阶段零第三方 SPM

## 架构与目录

```
GitPalette/
├── App/                      # 应用入口与 Scene 组装
│   └── GitPaletteApp.swift
├── Core/                     # 跨功能共享层
│   ├── Config/               # AppConfig、CopyFormat 等配置
│   └── DesignSystem/         # Liquid Glass 壳层占位修饰
├── Features/                 # 按功能垂直切片
│   ├── Launcher/             # 菜单栏 Extra 占位菜单
│   ├── Gitmoji/              # 空占位 View，后续搜索 / 数据
│   ├── Settings/             # 设置场景占位
│   └── AI/                   # 空占位 View，后续 AI 能力
└── Assets.xcassets/
```

```text
┌─────────────────────────────────────────┐
│              App（Scene 壳）              │
│   MenuBarExtra  ·  Settings Scene        │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┐
    ▼                   ▼
 Features/*          Core/*
 Launcher            Config
 Settings            DesignSystem
 Gitmoji（占位）
 AI（占位）
```

本阶段已实现：

| 模块 | 说明 |
|------|------|
| `AppConfig` | `appName`、热键占位 `"⌘⇧G"`、`gitmojiAPIURL`、`copyFormat` 默认值 |
| `LauncherMenuView` | 「打开启动器（占位）」「设置（占位）」「退出」 |
| `SettingsView` | 设置窗占位 `Text` |
| `GlassStyle` | Liquid Glass 壳层预留，勿整页滥用 `glassEffect` |

本阶段**明确不做**：Gitmoji 数据 / 搜索 / 剪贴板 / ⌘⇧G 热键注册 / AI / 网络请求 / 登录 / Sparkle / Dock 主窗口。

## 阶段路线

1. **Shell（当前）**：Menu Bar Agent 壳、目录分层、AppConfig、占位 UI、README
2. **Gitmoji 核心**：本地/缓存数据、搜索面板、复制格式
3. **热键与面板**：全局热键 ⌘⇧G、NSPanel / 启动器体验
4. **设置完善**：偏好持久化、启动项、格式选项
5. **AI（可选）**：提交信息建议等增强能力
6. **分发**：签名、公证、Sparkle 更新（如需要）

## 如何运行

### 环境要求

- macOS 26（Tahoe）或更高
- Xcode 26+（Swift 6）

### 步骤

1. 打开 `GitPalette.xcodeproj`
2. 选择 scheme **GitPalette**，目标为本机 Mac
3. 按 `⌘R` 运行
4. 菜单栏应出现调色板图标（`paintpalette.fill`）
5. 点击菜单项验证不崩溃；「设置（占位）」可打开设置窗；「退出」可结束进程

### 命令行编译（可选）

```bash
xcodebuild -scheme GitPalette -configuration Debug build
```

### 验收要点

- [x] 无 Dock 图标（`LSUIElement = YES`）
- [x] 菜单栏有图标与三项占位菜单
- [x] 设置场景可打开
- [x] 无 Gitmoji / 热键 / AI 业务代码混入
- [x] 目录与本文架构描述一致
