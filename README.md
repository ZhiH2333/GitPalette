# GitPalette

面向 macOS 的菜单栏 Gitmoji 助手（Menu Bar Agent）。当前处于 **P3：全局热键 ⌘⇧G + Menu Bar 定型**。

## 产品定位

- **形态**：`LSUIElement` 菜单栏应用，无 Dock 图标
- **能力**：Spotlight 风格启动器、本地 Gitmoji 搜索复制、全局热键唤起
- **平台**：macOS 26（Tahoe），Swift 6 + SwiftUI
- **依赖**：KeyboardShortcuts（唯一 SPM）

## 全局热键与权限

默认热键：**⌘⇧G**（配置集中在 `HotKeyDefaults` / `HotKeyService`，P4 可改为用户可配置）。

### 辅助功能权限（必做）

全局热键需在系统中允许本应用访问辅助功能，否则在其他 App 前台时无法可靠唤起：

1. 打开 **系统设置 → 隐私与安全性 → 辅助功能**
2. 找到并勾选 **GitPalette**
3. 若列表中没有，先运行一次应用，或点击应用内「打开系统设置」后添加

未授权时：

- 首次启动会弹出中文引导窗（不静默失败）
- 菜单栏提供「授予辅助功能权限…」
- 设置页显示权限状态与「重新检测」

若热键与系统快捷键冲突，应用内会显示橙色提示，可到 **系统设置 → 键盘 → 键盘快捷键** 调整冲突项。

## 架构与目录（增量）

```
Core/
  Config/HotKeyDefaults.swift     # 默认 ⌘⇧G
  HotKey/
    HotKeyService.swift           # 封装 KeyboardShortcuts
    HotKeyShortcutName.swift
    AccessibilityPermissionService.swift
Features/
  Launcher/                       # NSPanel + Menu Bar
  Settings/                       # 极简设置 / 权限引导 / 关于
```

热键触发路径：`⌘⇧G` → `HotKeyService` → `LauncherController.toggle()`。

## 阶段路线

1. P0 Shell ✅
2. P1 Gitmoji 搜索复制 ✅
3. P2 浮动面板 + 键盘 ✅
4. **P3 全局热键（当前）** ✅
5. P4 完整设置 / 可配置热键
6. P5 AI（可选）与分发

## 如何运行

1. `⌘R` 运行后，按提示授予辅助功能权限
2. 在任意 App 中按 **⌘⇧G** 唤起 / 再按关闭
3. 唤起后可直接输入搜索；↑↓ 选择；⏎ 复制；Esc 关闭
4. 菜单栏：打开启动器、复制格式、设置、关于、退出

```bash
xcodebuild -scheme GitPalette -configuration Debug build
```

### 验收要点

- [x] 授予辅助功能后，任意 App 前台 ⌘⇧G 可 toggle
- [x] 唤起后可立即键盘搜索
- [x] 未授权有中文引导，不静默失败
- [x] P2 键盘闭环无回归
