# ClassGod 开发指南

## 项目定位

ClassGod 本质上是一个**紧急切屏工具**——帮用户在关键时刻（比如老师来了、老板路过）瞬间切回指定页面。当前版本 v1.5.3 (Build 28)，核心逻辑是 AppleScript + Carbon HotKey + SwiftUI。

## 技术约束

- **平台**：macOS 14.0+
- **语言**：Swift 5.9+
- **UI**：SwiftUI（视图）+ AppKit（菜单栏、状态项）
- **架构**：MVVM
- **权限**：禁用 App Sandbox，否则 AppleScript 和 Accessibility 没法工作

## 核心模块

### Models
- `BrowserType`：Safari、Chrome、Edge，提供 bundle ID 映射
- `BrowserTab`：Codable 数据模型，包含标题、URL、浏览器类型、快捷键信息
- `AppPreferences`：所有用户设置，带 version 字段支持未来迁移
- `TemperatureUnit` / `FanControlMode`：风扇控制相关枚举
- `BypassRule` / `BypassType`：浏览器绕过规则模型
- `AssessPrepHack` / `AssessPrepBypassTechnique`：应急绕过技术模型
- `SwitchTarget` / `AppIconStyle` / `WallpaperPlaybackMode` / `HackerWidget`：SuperSwitch、图标伪装、壁纸、桌面小组件相关模型

### Services
- `BrowserDetector`：异步 AppleScript 获取当前最前端浏览器窗口的活动标签页
- `BrowserSwitcher`：AppleScript 切标签；找不到就新建标签打开 URL；支持 Exact/Prefix/Host 三种匹配
- `ShortcutManager`：Carbon `RegisterEventHotKey` 注册全局快捷键，带 Cocoa→Carbon 修饰符转换
- `StorageManager`：UserDefaults + JSON 编码本地持久化
- `PreferencesManager`：ObservableObject，集中管理设置，自动持久化
- `SMCService`：通过 IOKit 读取 SMC 温度传感器和风扇转速，支持 Intel / Apple Silicon；支持风扇模式切换（System / Max / Manual / Custom）；Apple Silicon 上会通过 IORegistry 发现 `AppleARMPMUTempSensor`、`AppleSmartBattery`、`IOPMPowerSource` 等传感器，并标记不可读传感器为 estimated；提供 `rescan()` 与 `fanAccessReason` 用于硬件重新扫描和权限提示
- `SMCHelperClient` / `ClassGodHelper`：特权辅助工具。`ClassGodHelper` 是以 root 运行的独立 Swift Package 可执行文件，通过 Unix domain socket (`/tmp/com.hanazar.classgod.helper.sock`) 与主应用通信，使用 `getpeereid` 进行 UID 校验；`SMCHelperClient` 在主应用中同步调用 Helper 以读取真实风扇 RPM / 温度、写入风扇目标转速。Helper 通过 Xcode Run Script 阶段自动构建并复制到 `ClassGod.app/Contents/MacOS/ClassGodHelper`。
- `PermissionCenterService`：集中管理所有 macOS 权限（Accessibility / AppleEvents / Screen Recording / Full Disk / Mic / Camera / Location / Notifications / Contacts / Reminders / Calendar / Bluetooth）。支持实时状态检测、按 feature 分类展示、一键请求 / 跳转系统设置、First-Time Setup 引导流程。

### Utilities
- `SoundEffectManager`：系统音效播放，可开关
- `HapticManager`：震动反馈，可开关
- `AnimationHelper`：全局动画引擎 `Anim.with()`，读取用户设置的 animationSpeed

### Views & ViewModels
- `MenuBarView`：Popover 面板主视图，支持动画、Toast、悬停效果
- `AddTabView`：添加/编辑标签的 Sheet 弹窗
- `ShortcutPicker`：快捷键录制组件，带自动清理
- `TabListViewModel`：@MainActor 业务状态，协调 Service 层
- `FanControlView` / `FanControlViewModel`：风扇控制面板，含温度列表、风扇转速条、诊断信息；支持 Manual 模式下滑块控制、Custom 模式下基于传感器阈值的规则控制；UI 使用 `zoomScale` 适配窗口缩放
- `FanControlSettingsView`：风扇控制设置页（更新间隔、温度单位、Auto Max / Custom 规则编辑器，支持选择具体传感器与百分比/RPM 目标）
- `PermissionCenterView` / `PermissionCenterService`：Hacker 风格权限控制中心，分组展示、进度条、按 category 筛选、First-Time Setup 引导 Sheet；UI 使用 `zoomScale` 适配窗口缩放，集成到主菜单。
- `DestinTabView`：浏览器标签管理器；支持搜索、排序、批量选择、置顶。
- `BrowserBypasserView` / `BrowserBypasserViewModel`：浏览器锁定绕过规则管理器。
- `SuperSwitchView` / `SuperSwitchViewModel`：应急应用/目标快速切换器。
- `AssessPrepHackView` / `AssessPrepHackViewModel`：AssessPrep 反锁定配置面板。
- `HackerDesktopView`：桌面小组件配置中心与 Hacker 主题工具入口。
- `ActivityMonitorView` / `ActivityMonitorViewModel`：系统活动监视器（进程 / 内存 / 磁盘 / 网络 / 电池 / 能耗）。
- `ErrorHubView` / `ErrorDetailView`：Swift/macOS 错误百科中心。
- `WallpaperBrowserView`：视频/动态壁纸选择器。

## 开发规范

1. **最小修改**：只做实现功能必需的修改
2. **错误处理**：AppleScript 必须处理 errorInfo，失败时优雅降级
3. **主线程约束**：UI 更新在主线程；AppleScript 在全局队列
4. **权限检查**：启动时不阻塞核心功能；所有权限集中到 `PermissionCenterView` 管理，feature 页面按需降级提示
5. **快捷键冲突**：Carbon HotKey 注册失败时静默忽略，不崩
6. **资源清理**：所有 NSEvent monitor、Carbon handler 必须在 dismiss/deinit 时移除
7. **本地化**：所有用户可见字符串必须加入 `Localizable.xcstrings`。复用组件的参数类型应使用 `LocalizedStringKey`（而非 `String`），这样 SwiftUI 字面量才能自动被字符串目录收录/本地化。

## 编译运行

```bash
cd ClassGod
xcodebuild -project ClassGod.xcodeproj -scheme ClassGod -destination 'platform=macOS' build
```

## 已知限制

- 快捷键只支持字母、数字、F1-F12
- Safari 标签匹配基于 URL 前缀或 host，可能误匹配
- 不支持 Firefox
- 音效使用未文档化的系统 Sound ID，未来 macOS 更新可能失效
- 全局呼出快捷键修改后需要重启应用才能完全生效（部分情况下）
- Apple Silicon 机型上 SMC 风扇控制需要 root/系统扩展权限；现在提供 `ClassGodHelper` 特权工具，以 root 运行后可解锁完整 SMC 读/写；未运行 Helper 时回退到 IORegistry / thermalState 估计值
- `AppleARMPMUTempSensor` 的温度值在 Apple Silicon 用户空间下通常不可读，应用会列出 discovered 硬件并以 thermalState 作为占位值（标记为 estimated）
