# Changelog

## [0.2.0] - 2026-05-22

### 新增功能

- **完整设置面板**：5 个 Tab（General / Shortcuts / Appearance / Browser / Advanced），20+ 可调参数
- **动画速度控制**：三档可调（Off / Fast / Normal），追求极致响应或保留动画反馈
- **全局呼出快捷键自定义**：点击录制即可绑定新快捷键，动态生效
- **音效系统**：10 种系统音效覆盖所有操作（切屏、保存、删除、冲突等）
- **震动反馈**：成功/警告/通用三档震动模式
- **快捷键冲突检测**：添加时自动检测，支持覆盖确认
- **URL 匹配精度**：Exact / Prefix / Host only 三种模式
- **浏览器未运行行为**：Launch & Open / Launch Only / Do Nothing
- **外观自定义**：5 种菜单栏图标、面板尺寸、行高、紧凑模式、主题跟随系统
- **数据导入/导出**：JSON 格式备份与恢复偏好设置
- **Toast 通知**：切屏/保存成功时的视觉反馈，时长可调
- **悬停发光效果**：标签行悬停时的柔和高亮
- **删除确认**：可配置的单条删除和清空全部确认对话框

### 修复的 Bug

- **Critical**: AppleScript 字符串转义错误（`"` → `""`），避免 URL 含引号时语法错误
- **Critical**: Cocoa ModifierFlags 未转换直接传给 Carbon API，导致快捷键注册失败
- **Critical**: Carbon Event Handler 从未移除，造成内存泄漏
- **Critical**: NSEvent 本地/全局监听器在视图消失时未清理，造成内存泄漏和事件吞没
- **Critical**: 菜单栏视图 retain cycle（`onShowToast` 闭包强引用 self）
- **Critical**: `|||` 分隔符不安全，改为 ASCII Record Separator (`\u{001E}`)
- **Critical**: `hostOnly` 匹配在 AppleScript 内循环调用 `do shell script`，存在 shell 注入风险，改为 Swift 层提取 host
- **Critical**: `.doNothing` 偏好设置被错误地应用在所有情况下，现在只在浏览器未运行时生效
- **High**: BrowserDetector 同步 AppleScript 阻塞主线程，改为后台异步执行
- **High**: Info.plist 版本号（0.1.0）与 Xcode build settings（1.0）不一致，统一为 0.2.0
- **High**: `ClassGod.entitlements` 包含无效的 `com.apple.security.accessibility`，已移除
- **Medium**: `BrowserTab` 合成 `Equatable` 比较了 `createdAt`，改为仅比较 `id`
- **Medium**: `BrowserType` rawValue 使用进程名（可能本地化变化），改为稳定英文代码
- **Medium**: `BrowserSwitcher` 错误信息被丢弃，现在正确传递失败原因
- **Medium**: `BrowserSwitcher` `make new window with properties {URL:...}` 兼容性差，改为 tell front window
- **Medium**: `AnimationHelper` Shake/AnimatedNumber 动画无法取消，快速触发时错乱，改为可取消的 DispatchWorkItem
- **Medium**: `MenuBarView` Toast 定时器在视图消失后仍触发，改为可取消的 DispatchWorkItem
- **Medium**: `PreferencesManager` `onPreferencesChanged` 每次赋值都触发（即使值未变），现在只在值变化时触发
- **Medium**: `PreferencesManager` 导出文件名含冒号，改为连字符
- **Medium**: `PreferencesManager` 导入不验证文件大小，现在限制 10MB
- **Low**: `AppDelegate` 缺少 `applicationWillTerminate`，现在正确注销热键和状态项
- **Low**: `SoundEffectManager` 使用未文档化的系统 Sound ID，已添加注释说明风险

### 架构改进

- 新增 `PreferencesManager`：集中管理所有用户偏好设置（Codable + UserDefaults）
- 新增 `SoundEffectManager` + `HapticManager`：统一反馈控制
- 新增 `AnimationHelper`：全局动画引擎 `Anim.with()` / `Anim.enabled`
- 新增 `AppPreferences` 数据模型：支持版本号和未来迁移
- 重构 `BrowserSwitcher`：统一 AppleScript 执行层，分离切换/打开逻辑
- 重构 `ShortcutManager`：添加 Cocoa→Carbon 修饰符转换，正确管理 EventHandlerRef

---

## [0.1.0] - 2026-05-22

### 初始版本

- 菜单栏常驻应用，无 Dock 图标
- 支持 Safari、Chrome、Edge 浏览器标签检测
- 一键保存当前浏览器标签（标题 + URL）
- 为每个标签绑定全局快捷键（⌘⌥⌃⇧ + 字母/数字/F键）
- 按下快捷键自动切换回对应浏览器标签
- 标签关闭时自动重新打开 URL
- 本地 UserDefaults 持久化存储
- 编辑/删除已保存的标签
- Accessibility & AppleEvents 权限提示
