# ClassGod 开发指南

## 项目定位

ClassGod 本质上是一个**紧急切屏工具**——帮用户在关键时刻（比如老师来了、老板路过）瞬间切回指定页面。当前版本 v1.5.58 (Build 83)，核心逻辑是 AppleScript + Carbon HotKey + SwiftUI。

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
- `SwitchTarget` / `AppIconStyle` / `WallpaperPlaybackMode` / `ClipoItem`：SuperSwitch、图标伪装、壁纸与剪贴板中心相关模型
- `ClassGodNote` / `NotesSnapshot`：本地笔记与持久化快照模型
- `FocusFlowPhase` / `FocusFlowPreset` / `FocusFlowDailyStats`：专注流阶段、节奏预设与每日统计模型
- `RecallCard` / `RecallPolicy`：本地问答卡、输入校验与间隔复习规则
- `SwitchDrillSession` / `SwitchDrillTarget`：快切演练状态机、已注册目标与反应/切换计时
- `ReadingLanePolicy` / `ReadingLaneSession`：保留 Unicode 字符的阅读分段、进度与回看规则
- `ScreenCurtainSession`：使用单调时钟的临时幕布期限与退出状态
- `NumberSprintPolicy` / `NumberSprintSession`：十题心算生成、运算均衡与首次/重试/揭晓计分
- `ReturnApplication` / `ReturnDockPolicy`：以 PID、bundle ID 和启动时间识别原应用进程
- `TeachBackSession`：四步讲解草稿、Unicode 输入限制与人工自检
- `QuietDevice`：音频输出 UID 与显示名称；恢复以 UID 定位
- `GitHubRelease` / `GitHubReleaseAsset` / `AppVersion`：更新元数据、安装资产与版本比较模型

### Services
- `BrowserDetector`：异步 AppleScript 获取当前最前端浏览器窗口的活动标签页
- `BrowserSwitcher`：AppleScript 切标签；找不到就新建标签打开 URL；支持 Exact/Prefix/Host 三种匹配
- `ShortcutManager`：Carbon `RegisterEventHotKey` 注册全局快捷键，带 Cocoa→Carbon 修饰符转换
- `StorageManager`：UserDefaults + JSON 编码本地持久化
- `PreferencesManager`：ObservableObject，集中管理设置，自动持久化
- `ClipoService`：剪贴板历史、快捷槽、敏感应用过滤、全局快捷键与异步持久化；数据保存在 Application Support，不写入仓库
- `WidgetDataStore`：主应用向 WidgetKit 扩展同步系统指标与配置；有效 App Group 不可用时明确回退到进程隔离的标准存储
- `SMCService`：通过 IOKit 读取 SMC 温度传感器和风扇转速，支持 Intel / Apple Silicon；支持风扇模式切换（System / Max / Manual / Custom）；Apple Silicon 上会通过 IORegistry 发现 `AppleARMPMUTempSensor`、`AppleSmartBattery`、`IOPMPowerSource` 等传感器，并标记不可读传感器为 estimated；提供 `rescan()` 与 `fanAccessReason` 用于硬件重新扫描和权限提示
- `SMCHelperClient` / `ClassGodHelper`：特权辅助工具。`ClassGodHelper` 是以 root 运行的独立 Swift Package 可执行文件，通过 Unix domain socket (`/tmp/com.hanazar.classgod.helper.sock`) 与主应用通信，使用 `getpeereid` 进行 UID 校验；`SMCHelperClient` 在主应用中同步调用 Helper 以读取真实风扇 RPM / 温度、写入风扇目标转速。Helper 通过 Xcode Run Script 阶段自动构建到 `ClassGod.app/Contents/Resources/ClassGodHelper`，LaunchDaemon plist 位于 `Contents/Library/LaunchDaemons`，由 `SMAppService` 请求玩家批准。
- `PermissionCenterService`：集中管理所有 macOS 权限（Accessibility / AppleEvents / Screen Recording / Full Disk / Mic / Camera / Location / Notifications / Contacts / Reminders / Calendar / Bluetooth）。支持实时状态检测、按 feature 分类展示、一键请求 / 跳转系统设置、First-Time Setup 引导流程。
- `NotesService`：管理多笔记、搜索、置顶、自动保存与损坏文件备份；数据保存在 Application Support，不写入仓库
- `FocusFlowService`：无漂移专注/休息计时器，支持暂停、跳过、四轮长休息和本机每日统计
- `RecallLabService`：问答卡管理、揭晓与评分、自动保存、损坏文件备份；数据保存在 Application Support
- `SwitchDrillService`：随机信号演练、目标变更取消、过期回调过滤；最近五轮成绩仅保留在内存中
- `ReadingLaneService`：本次应用会话内的学习材料与逐段阅读进度，不写入磁盘
- `ScreenCurtainController`：跨显示器临时幕布，Escape/按钮/超时/应用失焦/睡眠/屏幕变化时退出；不修改下方应用
- `NumberSprintService`：本次会话的难度选择、心算练习与结果，不写入磁盘
- `ReturnDockService`：默认关闭，目标快捷键成功跨应用切换后保留最近五条返回记录；只激活原进程，关闭功能或退出应用清空
- `TeachBackService`：本次会话的概念讲解、例子、疑问与自检，不写入磁盘
- `QuietDeskService` / `QuietAudioHardware`：Core Audio 输出主声道静音，写入后读回验证；原设备恢复失败保留重试入口，正常退出时尝试恢复，监测计时器随面板关闭清理
- `UpdateService`：启动时及每 6 小时检查 GitHub 最新正式 Release，验证 HTTPS、大小与 SHA-256 后打开 macOS 安装器

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
- `ClipoView`：剪贴板历史、快捷槽、统计和设置中心。
- `HackerDesktopView`：19 个官方 WidgetKit 小组件的数据配置中心与 Hacker 主题工具入口。
- `ActivityMonitorView` / `ActivityMonitorViewModel`：系统活动监视器（进程 / 内存 / 磁盘 / 网络 / 电池 / 能耗）。
- `ErrorHubView` / `ErrorDetailView`：Swift/macOS 错误百科中心。
- `WallpaperBrowserView`：视频/动态壁纸选择器。
- `NotesView`：Notes 风格双栏编辑器，通过跨应用、Spaces 与全屏的悬浮窗口持续显示。
- `FocusFlowView`：Good Student 模式的专注循环面板，包含进度环、节奏预设、阶段控制与每日统计。
- `RecallLabView` / `SwitchDrillView`：蓝色回忆训练与红色快切演练，共用可缩放的 `TrainingPanel` 窗口样式。
- `ReadingLaneView` / `ScreenCurtainView`：蓝色逐段阅读与红色幕布控制页；`ScreenCurtainOverlay` 为不透明的临时遮挡层。
- `NumberSprintView` / `ReturnDockView`：蓝色心算练习与红色返回台，共用 `TrainingPanel` 的缩放与关闭规则。
- `TeachBackView` / `QuietDeskView`：蓝色讲解工坊与红色静音台；静音台开关窗口不播放音效。
- `UpdateSettingsView`：软件更新状态、Release 说明、下载进度与安装入口。

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

- 快捷键支持字母、数字、Space、常用标点和 F1–F12；按物理键位记录，不支持数字小键盘
- Prefix 模式仍可能匹配相近 URL；Host-only 模式按完整 host 边界匹配
- 不支持 Firefox
- 音效由 `SoundEffectManager` 在内存中生成短 PCM/WAV 音色并通过 `NSSound(data:)` 缓存播放，不依赖未文档化 Sound ID 或外部音频文件
- 全局呼出快捷键修改后需要重启应用才能完全生效（部分情况下）
- Apple Silicon 机型上 SMC 风扇控制需要 root/系统扩展权限；现在提供 `ClassGodHelper` 特权工具，以 root 运行后可解锁完整 SMC 读/写；未运行 Helper 时回退到 IORegistry / thermalState 估计值
- `AppleARMPMUTempSensor` 的温度值在 Apple Silicon 用户空间下通常不可读，应用会列出 discovered 硬件并以 thermalState 作为占位值（标记为 estimated）
