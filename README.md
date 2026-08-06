# GitPalette

面向 macOS 的菜单栏 Gitmoji 助手（Menu Bar Agent）。当前处于 **P2：Spotlight 风格浮动面板 + 纯键盘闭环**。

## 产品定位

- **形态**：`LSUIElement` 菜单栏应用，无 Dock 图标
- **当前能力**：内置 Gitmoji 搜索复制 + 居中浮动面板 + ↑↓/⏎/Esc 键盘操作
- **平台**：macOS 26（Tahoe），Swift 6 + SwiftUI，面向 Liquid Glass
- **状态管理**：Observation（`@Observable`）
- **依赖**：零第三方 SPM

## 架构与目录

```
GitPalette/
├── App/
│   └── GitPaletteApp.swift
├── Core/
│   ├── Config/
│   └── DesignSystem/            # GlassStyle、LauncherGlassShell
├── Features/
│   ├── Launcher/                # 浮动面板 AppKit 桥接（集中）
│   │   ├── LauncherController.swift   # present / dismiss / toggle
│   │   ├── LauncherPanelFactory.swift # NSPanel 创建与多屏居中
│   │   ├── LauncherPanelContentView.swift
│   │   └── LauncherMenuView.swift
│   ├── Gitmoji/
│   │   ├── Domain/
│   │   ├── Data/
│   │   └── Presentation/        # ListView + ViewModel + Row
│   ├── Settings/
│   └── AI/                      # 空占位
├── Resources/
│   └── gitmojis.json
└── Assets.xcassets/
```

```text
MenuBarExtra 「打开启动器」
        │
        ▼
LauncherController.present()
        │
        ▼
   NSPanel（borderless / floating）
        │
        ▼
 NSHostingView → LauncherPanelContentView
        │
        ▼
   glass 外壳 + GitmojiListView
```

### 面板与键盘

| 操作 | 行为 |
|------|------|
| ↑ / ↓ | 移动选中（不会越界） |
| ⏎ | 按当前格式复制并关闭 |
| Esc | 关闭面板 |
| 输入 | 本地过滤，选中重置为 0 |
| 失焦 / 点外部 | 关闭面板（推荐行为） |

Liquid Glass：仅浮层外壳使用 `.glassEffect` + `ultraThinMaterial` 衬底；列表内容保持清晰可读。

### 明确不做（本阶段）

全局热键 ⌘⇧G、AI、网络强制拉取 Gitmoji、自动 commit。

## 阶段路线

1. **P0 Shell** ✅
2. **P1 Gitmoji 搜索复制** ✅
3. **P2 浮动面板 + 键盘（当前）** ✅
4. **P3 全局热键 ⌘⇧G**
5. **P4 AI（可选）**
6. **P5 分发**

## 如何运行

1. 打开 `GitPalette.xcodeproj` → `⌘R`
2. 菜单栏调色板 → **打开启动器**
3. 不依赖鼠标：输入 → ↑↓ → ⏎ 复制并关闭；Esc 关闭
4. 试搜 `bug` / `sparkles` / `性能`；切换 emoji / `:code:`

```bash
xcodebuild -scheme GitPalette -configuration Debug build
```

### 验收要点

- [x] 纯键盘：打开 → 输入 → 选中 → 复制 → 面板关闭
- [x] Esc / 无结果 / 选中不越界
- [x] 玻璃圆角阴影浮层；亮暗色可读
- [x] P1 搜索/复制/最近使用无回归
