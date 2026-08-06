# GitPalette

面向 macOS 的菜单栏 Gitmoji 助手（Menu Bar Agent）。当前处于 **P4：原生 Settings 与偏好持久化**。

## 产品定位

- **形态**：`LSUIElement` 菜单栏应用，无 Dock 图标
- **能力**：Spotlight 启动器、本地搜索复制、全局热键、可配置偏好
- **平台**：macOS 13+（Tahoe / macOS 26 可用液态玻璃），Swift 6 + SwiftUI
- **语言**：界面 / Code 翻译 / 描述 可分别切换 English 与简体中文
- **依赖**：KeyboardShortcuts（唯一 SPM）

## 设置与偏好

打开 **设置…**（菜单栏或系统 Settings 场景）包含三页：

| Tab | 内容 |
|-----|------|
| **通用** | 启动器外观、复制格式、最近使用 |
| **语言** | 界面语言、Code 翻译、描述语言（English / 简体中文） |
| **快捷键** | 录制全局热键（立即生效）、恢复默认 ⌘⇧G、辅助功能权限 |
| **关于** | 应用信息、菜单栏图标说明；AI/API Key 标注为 P5 |

### 复制格式

- `emoji`：仅表情
- `:code:`：仅 shortcode
- **自定义模板**：支持 `{emoji}` `{code}` `{name}` `{description}`，默认 `{emoji} `

偏好存于 `UserDefaults`（`PreferencesKeys`），运行时由 **`PreferencesStore`** 持有；启动器与设置共用同一实例，修改后 Return 复制立即生效。

### 全局热键

- 默认 **⌘⇧G**，可在「快捷键」页用录制器修改；旧键立即失效、新键立即可用（仍需辅助功能权限）
- 持久化由 KeyboardShortcuts 负责
- 配置默认值集中在 `HotKeyDefaults`

### 辅助功能权限

1. **系统设置 → 隐私与安全性 → 辅助功能** → 勾选 GitPalette  
2. 未授权时有中文引导，不静默失败

### 菜单栏图标

应用为 LSUIElement：启动后图标在菜单栏，**无 Dock 图标**。详见设置「关于」页说明。

## 架构（偏好相关）

```
Core/Config/
  PreferencesStore.swift   # 运行时偏好（= AppConfig 别名）
  PreferencesKeys.swift
  CopyFormat.swift
  HotKeyDefaults.swift
Core/HotKey/
  HotKeyService.swift
  HotKeyRecorderView.swift # 封装 Recorder，不泄漏到业务 View 细节
Features/Settings/
  SettingsView.swift       # Tab：通用 / 快捷键 / 关于
  GeneralSettingsTab.swift
  HotKeySettingsTab.swift
  AboutSettingsTab.swift
```

## 阶段路线

1. P0–P3 ✅  
2. **P4 Settings / 偏好（当前）** ✅  
3. P5 AI（可选，含 API Key）  
4. P6 在线同步等  

## 如何运行

1. `⌘R` → 授予辅助功能  
2. ⌘⇧G 唤起启动器；设置中改复制格式 / 热键后验证立即生效与重启保持  
3. 清空最近使用后，启动器顶部最近区应消失  

```bash
xcodebuild -scheme GitPalette -configuration Debug build
```

### 验收要点

- [x] 改复制格式后启动器 Return 结果立即符合新格式  
- [x] 改热键后旧键失效、新键可用  
- [x] 设置项重启后保持  
- [x] P3 热键唤起无回归  
