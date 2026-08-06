# GitPalette

面向 macOS 的菜单栏 Gitmoji 助手（Menu Bar Agent）。当前处于 **P1：Gitmoji 本地搜索与复制**（P0 壳层保留）。

## 产品定位

- **形态**：`LSUIElement` 菜单栏应用，无 Dock 图标
- **当前能力**：内置 Gitmoji 列表、本地关键词过滤、复制 emoji / `:code:`、最近使用（UserDefaults）
- **平台**：macOS 26（Tahoe），Swift 6 + SwiftUI，面向 Liquid Glass
- **状态管理**：Observation（`@Observable`），不引入 TCA / Combine 全家桶
- **依赖**：零第三方 SPM

## 架构与目录

```
GitPalette/
├── App/
│   └── GitPaletteApp.swift          # MenuBarExtra + Window(启动器) + Settings
├── Core/
│   ├── Config/                      # AppConfig、CopyFormat
│   └── DesignSystem/                # Liquid Glass 壳层占位
├── Features/
│   ├── Launcher/                    # 菜单栏菜单（打开启动器）
│   ├── Gitmoji/
│   │   ├── Domain/                  # Gitmoji 模型、中文别名
│   │   ├── Data/                    # Repository、Bundle 加载、最近使用
│   │   └── Presentation/            # ListView + ViewModel + Row
│   ├── Settings/                    # 复制格式设置
│   └── AI/                          # 空占位（未实现）
├── Resources/
│   └── gitmojis.json                # 官方 API 固化数据（离线）
└── Assets.xcassets/
```

```text
┌──────────────────────────────────────────────┐
│                 App（Scene 壳）                 │
│  MenuBarExtra · Window(启动器) · Settings     │
└──────────────────────┬───────────────────────┘
                       │
         ┌─────────────┴─────────────┐
         ▼                           ▼
   Features/Gitmoji               Core/*
   Domain → Data → Presentation   Config / DesignSystem
```

### P1 已实现

| 模块 | 说明 |
|------|------|
| `Gitmoji` / `GitmojiCollection` | 对齐官方 JSON 字段解码 |
| `BundleGitmojiRepository` | Bundle 加载；`all` / `search(query:)` |
| `GitmojiListViewModel` | `query`、`filtered`、`selectedIndex`、`copySelected()` |
| `GitmojiListView` | TextField + List；复制反馈「已复制」 |
| `RecentGitmojiStore` | 最近 8 条，UserDefaults 持久化 |
| `AppConfig.copyFormat` | emoji / `:code:`，设置与启动器内可切换并持久化 |

### 明确不做（本阶段）

全局热键 ⌘⇧G、NSPanel Spotlight 面板、AI、网络强制拉取、自动 commit、失焦关闭浮动窗。

## 阶段路线

1. **P0 Shell**：Menu Bar Agent 壳、目录分层、AppConfig ✅
2. **P1 Gitmoji 核心（当前）**：Bundle 数据、本地搜索、复制、最近使用 ✅
3. **P2 热键与面板**：全局热键 ⌘⇧G、NSPanel / 启动器体验
4. **P3 设置完善**：启动项等更多偏好
5. **P4 AI（可选）**：提交信息建议等
6. **P5 分发**：签名、公证、Sparkle（如需要）

## 如何运行

### 环境要求

- macOS 26（Tahoe）或更高
- Xcode 26+（Swift 6）

### 步骤

1. 打开 `GitPalette.xcodeproj`
2. 选择 scheme **GitPalette**，目标为本机 Mac
3. 按 `⌘R` 运行
4. 菜单栏点击调色板图标 → **打开启动器**
5. 无需网络即可浏览完整列表；试搜 `bug` / `sparkles` / `性能`
6. 回车或点「复制」；在文本编辑器粘贴验证
7. 切换复制格式（emoji / `:code:`）；关闭再开确认最近使用仍在

### 命令行编译

```bash
xcodebuild -scheme GitPalette -configuration Debug build
```

### 验收要点

- [x] 离线可见完整 Gitmoji 列表（Bundle JSON）
- [x] 关键词过滤（含中文别名如「性能」→ performance）
- [x] 复制 emoji / `:code:` 行为正确
- [x] 最近使用跨启动保留（UserDefaults）
- [x] 菜单栏壳无回归（LSUIElement + MenuBarExtra）
