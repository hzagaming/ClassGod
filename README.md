# ClassGod

ClassGod 是一个 macOS 菜单栏学习效率工具，帮助学生把重要的课堂网页、学习资料页面或常用窗口绑定到全局快捷键，在需要时快速切回对应页面。

## 功能特性

- **常驻菜单栏**：无 Dock 图标，常驻 macOS 菜单栏，随时可用
- **保存浏览器标签**：支持 Safari、Google Chrome、Microsoft Edge
- **自动检测当前标签**：一键保存当前浏览器标签的标题和 URL
- **全局快捷键**：为每个保存的标签绑定自定义快捷键，随时切换
- **智能切换**：按下快捷键后自动切回对应浏览器标签；若标签已关闭，自动重新打开 URL
- **本地存储**：所有配置保存在本地，无需云端
- **完整设置面板**：20+ 可调参数，动画/音效/外观/行为全覆盖
- **音效与震动反馈**：每次操作都有即时反馈

## 系统要求

- macOS 14.0 或更高版本
- 需要授予 **Accessibility** 和 **Automation** 权限以控制浏览器

## 技术栈

- SwiftUI + AppKit
- AppleScript（浏览器标签检测与切换）
- Carbon Event HotKeys（全局快捷键）
- UserDefaults（本地数据持久化）

## 项目结构

```
ClassGod/
├── ClassGodApp.swift              # App 入口，菜单栏模式
├── ClassGod.entitlements          # 权限声明（禁用沙盒，允许 Automation）
├── Info.plist                     # 自定义配置
├── Assets.xcassets/
├── Models/
│   ├── AppPreferences.swift       # 偏好设置数据模型
│   ├── BrowserTab.swift           # 数据模型：标签信息 + 快捷键
│   └── BrowserType.swift          # 浏览器枚举：Safari / Chrome / Edge
├── Services/
│   ├── BrowserDetector.swift      # AppleScript 检测当前浏览器标签
│   ├── BrowserSwitcher.swift      # AppleScript 切换/重新打开标签
│   ├── PreferencesManager.swift   # 偏好设置存储与管理
│   ├── ShortcutManager.swift      # Carbon 全局热键注册与管理
│   └── StorageManager.swift       # UserDefaults 本地存储
├── Utilities/
│   ├── AnimationHelper.swift      # 全局动画引擎与修饰符
│   └── SoundEffectManager.swift   # 音效与震动反馈管理
├── ViewModels/
│   └── TabListViewModel.swift     # 业务逻辑与状态管理
└── Views/
    ├── MenuBarView.swift          # 菜单栏主视图（Popover 面板）
    ├── AddTabView.swift           # 添加/编辑标签弹窗
    ├── ShortcutPicker.swift       # 快捷键录制组件
    └── Settings/                  # 设置面板（5 个 Tab）
        ├── GeneralSettingsView.swift
        ├── ShortcutsSettingsView.swift
        ├── AppearanceSettingsView.swift
        ├── BrowserSettingsView.swift
        └── AdvancedSettingsView.swift
```

## v0.2 功能清单

- [x] 菜单栏常驻，无 Dock 图标
- [x] 检测并保存当前浏览器标签（Safari / Chrome / Edge）
- [x] 本地持久化存储标签列表
- [x] 为每个标签绑定全局快捷键
- [x] 按下快捷键切换回对应浏览器标签
- [x] 标签关闭时自动重新打开 URL
- [x] 编辑/删除已保存的标签
- [x] Accessibility & AppleEvents 权限提示
- [x] 完整 5-Tab 设置面板（20+ 参数）
- [x] 动画速度控制（Off / Fast / Normal）
- [x] 全局呼出快捷键自定义
- [x] 音效反馈（10 种系统音效）
- [x] 震动反馈（成功/警告/通用）
- [x] 快捷键冲突检测与覆盖确认
- [x] URL 匹配精度（Exact / Prefix / Host）
- [x] 浏览器未运行行为控制
- [x] 外观自定义（图标/尺寸/主题/紧凑模式）
- [x] 数据导入/导出（JSON）
- [x] Toast 通知系统
- [x] 删除确认对话框

## 权限说明

ClassGod 需要以下系统权限才能正常工作：

1. **Accessibility**（辅助功能）：用于检测当前前台应用是否为浏览器
2. **Automation**（AppleEvents）：用于通过 AppleScript 控制 Safari、Chrome、Edge 获取标签信息和切换标签

首次使用相关功能时，系统会弹出授权提示，请前往 **系统设置 > 隐私与安全性 > 辅助功能 / AppleEvents** 中启用。

## 更新日志

见 [CHANGELOG.md](CHANGELOG.md)

## 免责声明

ClassGod 仅用于提升个人学习效率，**不包含**以下功能：
- 隐藏窗口或伪装页面
- 绕过学校网络或设备管理
- 偷偷切屏或规避监控

## 许可证

MIT License
