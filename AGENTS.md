# ClassGod 开发指南

## 项目背景

ClassGod 是一个 macOS 菜单栏应用，帮助学生快速切换回重要的课堂网页和学习资料页面。v0.1 MVP 专注于稳定性与核心功能，不做过度设计。

## 技术约束

- **平台**：macOS 14.0+
- **语言**：Swift 5.9+
- **UI 框架**：SwiftUI（视图）+ AppKit（菜单栏、状态项）
- **架构**：MVVM
- **权限**：必须禁用 App Sandbox，否则 AppleScript 和 Accessibility 无法正常工作

## 核心模块说明

### Models
- `BrowserType`：支持 Safari、Chrome、Edge 三种浏览器，提供 bundle ID 映射
- `BrowserTab`：Codable 数据模型，包含标题、URL、浏览器类型、快捷键信息

### Services
- `BrowserDetector`：通过 AppleScript 获取当前最前端浏览器窗口的活动标签页信息
- `BrowserSwitcher`：通过 AppleScript 在对应浏览器中查找并切换至指定标签；若标签不存在则新建标签打开 URL
- `ShortcutManager`：基于 Carbon `RegisterEventHotKey` 注册全局快捷键，支持 ⌘⌥⌃⇧ 组合
- `StorageManager`：基于 UserDefaults + JSON 编码实现本地数据持久化

### Views & ViewModels
- `MenuBarView`：Popover 面板主视图，展示标签列表、空状态、操作按钮
- `AddTabView`：添加/编辑标签的 Sheet 弹窗
- `ShortcutPicker`：快捷键录制组件，监听 keyDown + flagsChanged 事件
- `TabListViewModel`：@MainActor 管理的业务状态，协调 Service 层交互

## 开发规范

1. **最小修改原则**：只做实现功能所必需的修改
2. **错误处理**：AppleScript 调用必须处理 errorInfo，失败时优雅降级（如直接 open URL）
3. **主线程约束**：所有 UI 更新和 `@Published` 属性修改必须在主线程执行；AppleScript 调用在全局队列执行
4. **权限检查**：启动时主动提示 Accessibility 权限，但不应阻塞核心功能
5. **快捷键冲突**：Carbon HotKey 注册失败时静默忽略，不崩溃

## 编译与运行

```bash
cd ClassGod
xcodebuild -project ClassGod.xcodeproj -scheme ClassGod -destination 'platform=macOS' build
```

运行后应用会出现在菜单栏（右上角），首次使用需要授予 Accessibility 和 Automation 权限。

## 已知限制（v0.1）

- 快捷键仅支持字母键（A-Z）和数字键（0-9）以及 F1-F12
- 不支持多显示器环境下的窗口定位优化
- Safari 标签匹配基于 URL 前缀匹配，可能误匹配
- 不支持 Firefox（v0.2 可考虑）
