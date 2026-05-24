# ClassGod

> 上课摸鱼怕被逮？游戏打到一半老师突然靠近？—— ClassGod 就是你最靠谱的放风小弟。

ClassGod 是一个 macOS 菜单栏上的**紧急避险工具**，专门帮你在关键时刻**秒切回学习页面**，让老师和家长以为你一直在认真学习。

## 它能干嘛

- **常驻菜单栏，无 Dock 图标**：偷偷摸摸藏在右上角，一般人发现不了
- **一键保存当前网页**：正在刷的 B 站、微博、游戏页面，绑定个快捷键，老师来了秒切回课件
- **全局快捷键切屏**：按一下快捷键，瞬间跳转到指定页面，连鼠标都不用动
- **死了的页面也能复活**：就算你把那个标签关了，ClassGod 也会帮你重新打开
- **本地存储，不上传云端**：你的摸鱼记录只有你自己知道
- **完整设置面板**：20+ 参数随便调，动画、音效、外观全都能改

## 系统要求

- macOS 14.0 或更高版本
- 需要给 **Accessibility** 和 **Automation** 权限（不然怎么帮你切屏糊弄老师）

## 技术栈

- SwiftUI + AppKit
- AppleScript（偷偷控制浏览器）
- Carbon Event HotKeys（全局快捷键）
- UserDefaults（本地存配置）

## 项目结构

```
ClassGod/
├── ClassGodApp.swift              # 应用入口
├── ClassGod.entitlements          # 权限配置
├── Info.plist
├── Assets.xcassets/
├── Models/
│   ├── AppPreferences.swift       # 设置数据
│   ├── BrowserTab.swift           # 摸鱼页面数据
│   └── BrowserType.swift          # 浏览器枚举
├── Services/
│   ├── BrowserDetector.swift      # 探测你在看啥
│   ├── BrowserSwitcher.swift      # 帮你瞬间切走
│   ├── PreferencesManager.swift   # 管理设置
│   ├── ShortcutManager.swift      # 全局快捷键
│   └── StorageManager.swift       # 本地存储
├── Utilities/
│   ├── AnimationHelper.swift      # 动画引擎
│   └── SoundEffectManager.swift   # 音效反馈
├── ViewModels/
│   └── TabListViewModel.swift
└── Views/
    ├── MenuBarView.swift          # 主面板
    ├── AddTabView.swift           # 添加摸鱼页面
    ├── ShortcutPicker.swift       # 录快捷键
    └── Settings/                  # 设置面板
```

## v0.3 新特性 🔥

- [x] **10 语言本地化**：简体中文（源）、繁体中文、英语、日语、韩语、法语、德语、西班牙语、俄语、葡萄牙语
- [x] **黑客风格黑白 UI**：纯黑背景 + 白色线条 + 等宽字体，帅就完事了
- [x] **2 秒启动动画**：每次打开都有 Hanazar Products 开屏，仪式感拉满
- [x] **设置面板增强**：新增 6 个可调参数
  - 面板圆角半径
  - 菜单栏标签数量徽章
  - 显示面板时自动探测当前标签
  - 键盘上下箭头导航
  - 切换前延迟（毫秒）
  - 极速模式（一键关闭所有动画）
- [x] **关于页面**：Release Notes、GitHub 仓库、开发者 Profile 一键直达
- [x] **权限实时检测**：主面板打开时自动检查权限状态，图标变红提醒
- [x] **极致速度优化**：Fast 动画从 80ms 降到 30ms，新增极速模式 0ms

## v0.2 功能清单

- [x] 菜单栏常驻，无 Dock 图标（低调摸鱼）
- [x] 保存浏览器标签（Safari / Chrome / Edge）
- [x] 本地持久化存储
- [x] 为每个页面绑定全局快捷键
- [x] 按下快捷键瞬间切回页面
- [x] 标签关了也能自动重新打开
- [x] 编辑/删除已保存的页面
- [x] 权限提示（第一次用会弹窗，记得点允许）
- [x] 5-Tab 设置面板（20+ 参数随便调）
- [x] 动画速度控制（嫌动画墨迹可以直接关掉）
- [x] 全局呼出快捷键自定义
- [x] 音效反馈（切屏有声音提醒）
- [x] 震动反馈（有手感）
- [x] 快捷键冲突检测
- [x] URL 匹配精度可调
- [x] 浏览器未运行时的行为控制
- [x] 外观自定义（图标/尺寸/主题）
- [x] 数据导入/导出
- [x] Toast 通知
- [x] 删除确认（防手滑）

## 权限说明

ClassGod 需要两个权限才能帮你糊弄老师：

1. **Accessibility（辅助功能）**：探测当前前台是不是浏览器
2. **Automation（AppleEvents）**：远程控制浏览器切标签

第一次用的时候系统会弹窗问你要不要允许，**一定要点允许**，不然没法帮你放风。

## 更新日志

见 [CHANGELOG.md](CHANGELOG.md)

## 免责声明

ClassGod 只是为了**应付检查**和**提高效率**，**不包含**以下功能：
- 隐藏窗口或假装在干活
- 绕过学校网络封锁
- 偷偷切屏玩游戏

**摸鱼有风险，使用需谨慎。被逮了别赖我。**

## 许可证

MIT License — 随便用，随便改，但被抓了别找我。
