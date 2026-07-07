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

## 最新公告：v1.5.5

### UI/UX/SFX 一致性修复

- [x] **删除操作反馈时序修复**：BrowserBypasser / AssessPrepHack / SuperSwitch 的删除确认弹窗此前在打开确认框时就误播放"已删除"音效，取消也会触发；现在只在确认删除时才播放
- [x] **桌面小组件音效接入**：桌面悬浮小组件关闭 / 锁定切换 / 编辑器删除按钮补齐了此前定义却从未使用的音效与触感反馈
- [x] **进程管理器终止反馈**：Activity Monitor 的 Quit / Force Quit 操作补充成功/失败音效与触感
- [x] **动画速度设置生效范围修复**：Fan Control、Wallpaper Browser、BrowserBypasser、SuperSwitch 中若干写死时长的动画现在正确遵循"动画速度"/"极速模式"设置
- [x] **SuperSwitch 面板本地化补齐**：此前唯一完全未本地化的功能面板，现已接入字符串目录
- [x] **圆角缩放遗漏修复**：多处 `cornerRadius` 未随窗口缩放比例联动的问题

## 历史公告：v1.5.4

### 深度修复：工程配置、Widget、UI/UX/SFX 清理

- [x] **版本统一**：实际构建产物更新为 v1.5.4 (Build 29)，Bundle ID 统一为 `com.hanazar.classgod`
- [x] **Widget Extension 修复**：主 App 正式依赖并嵌入 `ClassGodWidget.appex`
- [x] **Widget 权限修复**：Widget target 启用 Sandbox 并使用 `ClassGodWidget.entitlements`
- [x] **共享容器说明**：`WidgetDataStore` 保留 `group.com.hanazar.classgod` 入口；App Group 需要开发证书/Team 签名，本地构建不强制启用
- [x] **退出清理修复**：退出时补齐 Activity Monitor / Permission Center 窗口清理，取消状态栏后台刷新任务并断开 SMC Helper socket
- [x] **Helper 测试接入**：修复 `ClassGodHelper` 下 `swift test` 报 `no tests found`
- [x] **UI/UX/SFX 修复**：补齐主菜单、设置、AssessPrep 面板的本地化遗漏、窗口缩放和触感反馈

## 历史公告：v0.4.4

### 全新体验：开机混乱弹窗动画 v5
启动 ClassGod 后，你会看到+听到：
1. **全屏黑色开屏**（2秒，Hanazar Products 渐显）
2. **白色屏幕闪烁** + 系统错误音效 burst
3. **突然弹出 50 个小窗口**密密麻麻覆盖整个屏幕——10 种风格：终端乱码、系统错误、黄色警告、紫色日志、崩溃报告、矩阵字符、Windows 蓝屏、十六进制 dump、JSON 错误、编译错误
4. **红色屏幕闪烁**（第 15/30 个弹窗时）
5. **主窗口混在第 3-4 个弹窗中一起诞生**，从底层慢慢显现
6. **弹窗逐个关闭**，主窗口逐渐清晰，最终完全显现

### 架构升级
- [x] 主 UI 从 NSPopover 改为**独立浮动窗口**，无边框、可拖动、有圆角阴影
- [x] 菜单栏图标和 Dock 图标全部保留，点击图标显示/隐藏独立窗口

### 修复 & 优化
- [x] 弹窗数量 **50**，10 种风格，网格分布全覆盖
- [x] **屏幕闪烁效果**（白色 + 红色），配合音效更有冲击力
- [x] 弹窗全部无边框，纯静态渲染，零卡顿
- [x] **主窗口混入弹窗一起显现**
- [x] **超级黑客 SFX**：系统错误音效连环播放
- [x] 主窗口默认尺寸调大（380×500）
- [x] 主 UI 扫描线覆盖层，增强 CRT 显示器感
- [x] Header 添加版本号 + 渐变分隔线
- [x] TabRow hover/focus 白色边框高亮
- [x] Footer 按钮添加图标 + 渐变背景
- [x] 修复全局呼出快捷键注册/录制问题
- [x] 修复 F1-F12 标签快捷键、快捷键冲突检测等问题
- [x] 修复浏览器无窗口时无法打开目标 URL 等问题
- [x] 修复空状态页图标颜色、自动探测 Toast、动画速度值等问题
- [x] 补齐面板圆角、主题、徽章、切换延迟等设置项的真实联动
- [x] 菜单栏图标标签数量徽章真正生效
- [x] TabRow 键盘导航焦点高亮
- [x] 版本号更新为 v0.4.4 (Build 10)

## 历史公告：v0.3.2

- [x] 修复启动后主 UI 不自动出现的问题：Run 之后会先显示开屏，再自动弹出主面板
- [x] 菜单栏图标改为 macOS template 图标，深色/浅色菜单栏都能看清
- [x] 标签数量徽章改为菜单栏文字徽章，避免自绘图标隐身
- [x] 版本号更新为 v0.3.2 (Build 5)

## 历史公告：v0.3.1

- [x] 修复全局呼出快捷键注册/录制问题，设置窗口里录快捷键也能稳定生效
- [x] 修复 F1-F12 标签快捷键、快捷键冲突检测、Carbon handler 清理等快捷键边界问题
- [x] 修复浏览器无窗口时无法打开目标 URL、清空全部后主面板不同步、打开面板音效重复播放等问题
- [x] 修复空状态页图标使用系统强调色（蓝色）的问题，统一为黑白主题白色
- [x] 修复自动探测当前标签时误弹 Toast 的问题（静默探测不应打扰用户）
- [x] 修复 Toast 在主面板关闭后残留、下次打开仍显示的问题
- [x] 修复动画速度实际值与设定不符的问题（Fast 0.08s → 0.03s，Normal 0.2s → 0.1s）
- [x] 补齐面板圆角、主题、徽章、切换延迟、默认浏览器、清空确认等设置项的真实联动
- [x] 菜单栏图标标签数量徽章真正生效：启用后在图标右上角显示红色数字徽章
- [x] TabRow 键盘导航焦点高亮：启用键盘导航后，Tab 键聚焦的标签有明显白色高亮背景
- [x] 增加手动添加标签入口，并对自动探测保存做去重
- [x] 版本号更新为 v0.3.1 (Build 4)，部署目标统一为 macOS 14.0+

## 历史公告：v0.3 新特性

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
