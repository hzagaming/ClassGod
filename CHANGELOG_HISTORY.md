# ClassGod 历史版本记录

> 较早版本详见本文件；最新版本请查看 [CHANGELOG.md](./CHANGELOG.md)。

---

## v1.5.10 — 2026-07-22

### 修复
- **AppKit / SwiftUI 窗口生命周期**：为主菜单、HackerDesktop、Activity Monitor、AssessPrepHack 增加明确的显示/隐藏生命周期信号，窗口 `orderOut` 后会停止后台定时器、系统监控和应急检测，再次显示时按需恢复。
- **Activity Monitor 监控引用泄漏**：`ActivityMonitorViewModel` 增加幂等启动/停止保护，停止时正确调用 `SystemMonitor.stop()`，避免反复打开面板后 `SystemMonitor` / `nettop` 常驻。
- **桌面小组件锁定状态同步**：切换桌面标签锁定状态后立即刷新窗口内容，锁图标与实际拖拽状态保持一致。
- **布局重置防误触**：桌面小组件重置遵循全局“清空前确认”设置；确认后才播放重置音效和警告触感。
- **文件选择取消反馈**：Finder 文件选择器的用户取消不再被当作导入失败，不播放失败 SFX 或警告触感。
- **系统音效兼容性**：移除未文档化的硬编码 Sound ID，改为在内存中合成并缓存短 PCM/WAV 音色，避免新系统上的 `-50` 音频错误和系统音效文件路径依赖。
- **状态栏唤起窗口**：显示主面板前显式激活菜单栏应用，避免普通窗口层级的面板被当前应用遮挡。
- **启动动画资源峰值**：Chaos 动画窗口数量限制在 12–48，并自动迁移旧的高数值，避免默认 200 个 `NSWindow` 触发 AppKit 超额活动窗口告警与布局卡顿。
- **隐藏占位窗口**：应用 Scene 改用无主窗口的 `Settings` 场景，不再创建 `0×1` 的 SwiftUI 占位窗口或产生无效窗口恢复记录。
- **应用图标签名安全**：图标伪装只更新运行时应用图标，不再通过 `NSWorkspace.setIcon` 改写 `.app` bundle，避免修改已签名的应用内容。
- **Swift 6 迁移安全**：清理 SMC 后台读取、进程快照、壁纸屏幕事件、错误搜索等并发警告，并移除 `Optional` 的全局追溯协议扩展。
- **窗口缩放越界**：所有功能窗口尺寸限制到当前屏幕可见区域，缩放变化后重新夹紧位置，避免 200% 缩放时关闭按钮跑到屏幕外。
- **Widget 英文本地化**：补齐 19 个 `widget.*` 类型名称的英文回退，并新增布局重置确认文案。
- **语义键名回退**：为英文资源中 318 个缺失的点分语义键补上源文案回退，主菜单与 Widget 重要文案完成正式英译，避免英文 macOS 直接显示 `menu.*` / `button.*` 内部键名。
- **简体中文资源补全**：复用并转换现有繁中译文，补齐 175 个仅有英文/繁中的语义键，避免简中 macOS 显示内部键名。
- **质量检查**：完整 Debug / Release build、Xcode Analyze、Helper 测试、本地化 JSON 校验和代码差异检查通过。
- 版本号更新为 v1.5.10 (Build 35)

---

## v1.5.9 — 2026-07-16

### 修复
- **HackerDesktop 配置中心本地化补齐**：标题、字段占位符、About 区域和可用小组件说明改为 `hackerdesktop.*` 字符串键，避免中文界面露出英文硬编码。
- **桌面小组件 SFX 语义修正**：添加小组件、打开文件选择器、重置布局、切换编辑模式、编辑栏删除和拖拽开始改用对应 widget/layout/drag 音效，不再混用普通按钮音。
- **桌面小组件动画设置补漏**：CPU / 内存小组件数值动画现在遵循全局 `Anim.enabled` / `Anim.duration`，极速模式下不再残留写死动画。
- **Finder 文件小组件选择体验修复**：文件导入允许选择通用 Finder 项目，文件小组件不再被 `.data` 类型过度限制。
- 版本号更新为 v1.5.9 (Build 34)

---

## v1.5.8 — 2026-07-14

### 修复
- **HackerDesktop 保存防抖**：Widget 配置中心的文本输入不再每个字符都立刻刷新 WidgetKit timeline，改为短延迟合并保存，关闭窗口时仍会强制落盘，减少卡顿和无谓刷新。
- **桌面小组件编辑器本地化**：`DesktopWidgetEditor` 的启用说明、编辑布局、重置、空状态、添加小组件/桌面标签、数量标题等用户可见文案接入 `Localizable.xcstrings`。
- **桌面小组件编辑器 SFX/触感补齐**：启用开关、编辑模式、重置、添加、文件导入成功/失败补齐一致的音效和触感反馈。
- **缩放细节修复**：桌面小组件编辑器的部分描边线宽和空状态垂直间距补齐 `zoomScale`，避免窗口缩放后局部视觉重量不一致。
- 版本号更新为 v1.5.8 (Build 33)

---

## v1.5.7 — 2026-07-14

### 修复
- **设置 Slider 音效节流**：`SettingsSliderRow` 拖动时不再对每一次数值变化连续播放按钮音效和触感，避免设置页 SFX 变成高频噪声。
- **Wallpaper 动画速度补漏**：`WallpaperPlayerView` 的壁纸切换淡入/淡出、Quick Access Bar hover 显隐改为读取 `Anim.enabled` / `Anim.duration`，极速模式下不再残留写死动画。
- **HackerDesktop Widget 状态提示**：同步说明改为准确描述 WidgetKit App Group 要求与本地回退存储，并在系统监控区显示当前使用的是共享 App Group 还是本地回退存储。
- **本地化补齐**：新增 `hackerdesktop.shared_active` / `hackerdesktop.local_fallback` 状态文案，并更新 `hackerdesktop.sync_notice` 的 zh-Hans / en 文案。
- 版本号更新为 v1.5.7 (Build 32)

---

## v1.5.6 — 2026-07-13

### 修复
- **设置页缩放一致性**：`CollapsibleSection`、`SettingsToggleRow`、`SettingsSliderRow`、`SettingsPickerRow`、`SettingsActionRow`、`SectionResetButton` 现在完整跟随 `windowZoomScale`，不再只有外框缩放而字体、间距、图标尺寸保持原大小。
- **动画速度设置补漏**：设置页折叠/hover 动画与主菜单功能按钮按压动画统一改为读取 `Anim.enabled` / `Anim.duration`，极速模式下不再残留写死动画时长。
- **设置交互反馈补齐**：折叠设置分组时补齐触感反馈；重置按钮文案改用既有 `button.reset` 本地化键。
- **Widget 本地构建回退**：`WidgetDataStore` / `WidgetExtensionStore` 在 App Group 容器不可用时回退到 `UserDefaults.standard`，避免未签名本地构建下 HackerDesktop / Widget 数据读写静默失效。
- **HackerDesktop 同步提示修正**：同步说明不再无条件声称 App Group 一定可用，新增 `hackerdesktop.sync_notice` 本地化文案说明共享容器与本地回退行为。
- 版本号更新为 v1.5.6 (Build 31)

---

## v1.5.5 — 2026-07-07

### 修复
- **删除类操作的音效/触感时序**：`BrowserBypasser`、`AssessPrepHack`、`SuperSwitch` 的删除确认弹窗此前会在打开确认框时就播放"已删除"音效与警告触感，取消也不例外；现在改为只在用户实际点击确认删除时才触发，打开确认框仅播放普通点击音效。
- **桌面小组件音效补齐**：桌面悬浮小组件的关闭（`xmark`）与锁定切换按钮、组件编辑器里的垃圾桶删除按钮此前完全没有音效/触感反馈；接入了此前已定义但从未被调用的 `playWidgetDeleted()` / `playWidgetLocked()`。
- **进程管理器 Quit/Force Quit 反馈**：`ActivityMonitorView` 终止进程的右键菜单操作此前没有任何反馈；现在按终止结果播放成功/失败音效并触发警告触感。
- **AssessPrep 新增面板反馈缺失**：`AddPanicAppView` 的关闭按钮和保存操作此前没有音效反馈，和同类 Add/Edit 面板不一致，现已补齐。
- **动画速度设置未生效的例外**：`FanControlView`（Toast、温度告警高亮）、`WallpaperBrowserView`（悬停/按压反馈）、`BrowserBypasserView` / `SuperSwitchView`（行按压反馈）中若干处使用了写死的动画时长，忽略了用户的"动画速度"/"极速模式"设置；统一改为读取 `Anim.enabled` / `Anim.duration`。
- **SuperSwitch 面板本地化缺失**：`SuperSwitchView` 是唯一完全未接入本地化字符串目录的功能面板（标题、空状态、添加/编辑目标表单等均为英文硬编码字符串），现已补充 `superswitch.*` / `field.bundle_identifier` / `field.icon` 等键值（含 zh-Hans 源文案与 en 翻译），并复用既有的 `button.cancel` / `button.delete` / `button.edit` / `button.add` / `button.save` / `field.name` 键。
- **DestinTab / BrowserBypasser 副标题与提示未本地化**：这两个面板的副标题及 DestinTab 的"重复 URL"tooltip 此前是被 Xcode 自动提取但无任何翻译的英文字面量，中文用户也会看到英文；现改用 `destintab.subtitle` / `bypass.subtitle` / `destintab.duplicate_url(s_detected)` 正式键并补齐 zh-Hans / en 文案。
- **圆角缩放遗漏**：`BrowserBypasserView`、`AssessPrepHackView`、`AddPanicAppView` 中各一处 `.cornerRadius(4)` 未乘以 `zoomScale`，与同一窗口内其他圆角不一致，现已修正。
- **SMC 温度读取稳定性**：Apple Silicon HID 温度传感器读取时移除对 `Product` 字段的强制类型转换，避免异常传感器属性导致进程崩溃。
- **HackerDesktop Widget 配置保存**：Clock / Weather / Crypto / Quote / Terminal Logs 编辑后立即保存并刷新 Widget 数据，修复改完马上关闭窗口可能丢失配置的问题；同时移除重复写入 `weatherCity`。
- **源码版本号同步**：补齐 `ClassGod/Info.plist` 的 v1.5.5 (Build 30)，避免源码 plist 与 Xcode build settings / 公告不一致。
- 版本号更新为 v1.5.5 (Build 30)

---

## v1.5.4 — 2026-07-01

### 修复
- **版本与 Bundle ID 统一**：修正 Xcode build settings 与源码公告不一致的问题，实际构建产物更新为 v1.5.4 (Build 29)，Bundle ID 统一为 `com.hanazar.classgod`。
- **Widget Extension 集成修复**：
  - 修复 `ClassGod` 主 target 未依赖 / 未嵌入 `ClassGodWidget.appex` 的问题。
  - 修复 Widget target 未使用 `ClassGodWidget.entitlements`、未启用 Sandbox 的问题。
  - 保留 `WidgetDataStore` 的 `group.com.hanazar.classgod` 共享容器入口；App Group capability 需要开发证书/Team 签名，本地 `Sign to Run Locally` 构建不强制启用，避免标准 build 失败。
- **退出清理与后台任务**：退出应用时补齐 Activity Monitor / Permission Center 窗口清理，取消状态栏 SMC 刷新任务，并断开 `SMCHelperClient` socket。
- **Helper 测试接入**：为 `ClassGodHelper` Swift Package 接入测试 target，修复 `swift test` 报 `no tests found` 的问题。
- **UI/UX/SFX 细节修复**：
  - 修复主菜单功能说明、设置标题、AssessPrep 面板按钮 / 空状态 / 帮助文本的本地化遗漏。
  - 修复设置窗口标题栏未随 `windowZoomScale` 缩放的问题。
  - 为主菜单入口、设置、退出、风扇摘要打开、AssessPrep 行操作补齐触感反馈。
- 版本号更新为 v1.5.4 (Build 29)

---

## v1.5.3 — 2026-06-13

### 修复
- **Localizable.xcstrings 损坏**：修复 `setting.keyboard_nav.subtitle` 被错误嵌套到 `About` 键下导致的 Xcode 编译失败，新增并校验 376 条缺失的 zh-Hans 本地化键值。
- **UI/UX/SFX/BGM 修复与缩放一致性**：
  - 修复 `PermissionCenterService`、`PermissionCenterView`、多个 Model 的 `displayName`、ViewModel 的 toast/error 文案的本地化为中文。
  - 为 `DestinTabView`、`BrowserBypasserView`、`SuperSwitchView`、`AssessPrepHackView`、`PermissionCenterView`、`ActivityMonitorView`、`ErrorHubView`、`HackerDesktopView`、`FanControlView` 等补充音效与触感反馈。
  - 修复 `WindowZoomControlBar`、`ShortcutPicker`、`SettingsSliderRow` 等组件未按 `windowZoomScale` / `zoomScale` 缩放的问题。
  - 修复 `safeLinkButton`、`SectionHeader`、`browserRow`、`categoryButton` 等复用组件的 `LocalizedStringKey` 参数类型，使 SwiftUI 字面量自动参与本地化。
- 版本号更新为 v1.5.3 (Build 28)

---

## v1.5.2 — 2026-06-13

### 新增
- **全面 UI/UX/SFX/BGM 修复与本地化补全**：
  - 为 MenuBar 功能按钮、设置页组件、权限中心、活动监视器、HackerDesktop、错误百科、风扇控制、应急应用、壁纸引擎等视图补充中文（zh-Hans）本地化键值
  - `FeatureButton`、`Settings*Row`、`CollapsibleSection`、`TabButton`、`ConfigSection`、`StatBadge`、`sortableHeader`、`summaryItem`、`DiagnosticRow`、`footerButton`、`browserRow` 等复用组件改为接受 `LocalizedStringKey`，调用处字面量自动参与本地化
  - 新增大量用户可见字符串键值：状态标签、诊断信息、按钮标题、提示文本、Alert 标题等

### 优化
- **交互反馈一致性提升**：
  - `AddTabView` 的浏览器 Picker 和置顶 Toggle 增加音效与触感反馈
  - `HackerDesktopView` 的 Tab 切换与待办完成操作增加音效与触感反馈
  - `AddPanicAppView` 的绕过技术选择增加音效与触感反馈
- **窗口圆角缩放一致性**：所有功能窗口（含设置、壁纸浏览器、HackerDesktop、错误中心）统一使用 `panelCornerRadius * windowZoomScale`
- **壁纸填充模式**：GIF 动态壁纸改为 `scaleAxesIndependently` 以填满桌面
- **错误中心主题色**：错误百科与详情页统一使用 `severity.colorHex` 主题色，移除硬编码 iOS 色调

### 修复
- **FanControl 状态与可用性**：
  - 无风扇时 Boost 按钮禁用并降低透明度
  - 模式按钮在无风扇时禁用
  - 修复风扇状态文本在 helper/回退场景下的显示逻辑
- **MenuBarView 风扇摘要定时器**：移除 `.onAppear` 与卡片 `onAppear` 中的重复注册，避免生命周期混乱
- 版本号更新为 v1.5.2 (Build 27)

---

## v1.5.1 — 2026-06-12

### 新增
- **主应用直接读取 Apple Silicon HID 温度传感器**：通过 `IOHIDEventSystemClient` 私有 API 读取 `AppleARMPMUTempSensor` / `AppleEmbeddedNVMeTemperatureSensor` 的实时温度事件，即使不启动特权 helper，风扇面板也能显示 `PMU tdie*`、`PMU tcal`、`NAND CH0 temp`、`gas gauge battery` 等真实温度
- **Helper `powermetrics` 后备数据源**：当传统 SMC keys 在 Apple Silicon M5 Pro 等设备上返回空数据时，特权 helper 会定期以 root 执行 `powermetrics --samplers smc`，解析 CPU/GPU/IO die 温度与风扇 RPM，并通过 socket 返回给主应用
- **Helper 自清理旧实例**：新 helper 启动时会自动 `SIGTERM` 其他 `ClassGodHelper` 进程，避免旧 helper 占用 socket 导致新 helper `bind() failed: 48`

### 优化
- **`SMCService` 独立 CPU 负载估计**：不再依赖 `SystemMonitor.shared.thermal`，而是在 `SMCService` 内部直接通过 `host_statistics` 读取 CPU 负载，结合 `ProcessInfo.thermalState` 生成动态的 `CPU Estimated` / `GPU Estimated`，即使 `SystemMonitor` 未启动也能显示

### 修复
- **移除 Start Helper 脚本中多余的嵌套 `sudo`**：脚本本身已通过 `with administrator privileges` 以 root 运行，内部再调 `sudo` 可能失败；改为直接 `killall ClassGodHelper; ClassGodHelper`
- 版本号更新为 v1.5.1 (Build 26)

---



## v1.4.2 — 2026-06-09

### 优化
- **Activity Monitor 真正实时化**：
  - 刷新间隔从 2.0s 缩短到 1.0s，过程列表更新更跟手
  - 新增 `NettopMonitor`，通过 `nettop -P -d -x -J bytes_in,bytes_out -L 0 -s 1` 采集真实的**逐进程网络收发字节**
  - `SystemMonitor` 直接消费 nettop 提供的每秒增量，取代原来按 CPU 比例估算网络流量的方案
  - Disk / Energy / Network 全部改为**速率化展示**（Read/Write MB/s、Recv/Sent KB/s、Energy W），避免累计值越滚越大
  - `ActivityMonitorViewModel` 的排序与默认 Tab 排序全部切换为速率字段
  - 底部摘要改为展示 Total Read/Write 速度和 Download/Upload 速度，并移除 "estimated by CPU share" 提示

### 修复
- 修复 `NettopMonitor` 解析逻辑：原实现把每一行都当作独立快照发射，导致前后样本无法对齐；新实现按 `time` 表头分组整屏样本，并跳过首屏累积总值
- 版本号更新为 v1.4.2 (Build 17)

---

## v1.4.1 — 2026-06-09

### 新增
- **ClassGodHelper 特权辅助工具**：
  - 独立的 Swift Package (`ClassGodHelper`)，作为 root 守护进程运行，通过 Unix domain socket 与主应用通信
  - 支持在 Apple Silicon 上绕过用户空间 SMC 限制，读取真实风扇 RPM、温度传感器
  - 支持 `setFanMode` / `setFanRPM` 写入风扇目标转速（System / Max / Manual / Auto Max / Custom）
  - 使用 `getpeereid` 对连接客户端进行 UID 校验（默认读取 `SUDO_UID`）
  - 自动嵌入到 `ClassGod.app/Contents/MacOS/ClassGodHelper`，通过 Xcode Run Script 阶段随主应用一起编译
- Fan Control 诊断面板新增 **Privileged Helper** 状态行：
  - 绿色：辅助工具已连接，完整 SMC 读写可用
  - 黄色：Apple Silicon 需要 root 辅助工具才能解锁风扇控制
  - 一键复制启动命令按钮：`sudo "/Applications/ClassGod.app/Contents/MacOS/ClassGodHelper"`

### 优化
- `SMCService` 优先通过 `SMCHelperClient` 访问 Helper；Helper 不可用时回退到原有直连 / IORegistry 兜底
- `SMCService.updateFanAccessReason()` 在 Helper 可用时显示正向提示

### 优化
- **Error Encyclopedia（报错知识库）性能与架构重写**：
  - 将 14,000+ 行 Swift 硬编码数据抽取为 `ErrorKnowledgeBase.json`（约 778 KB），作为 Bundle 资源随应用打包，显著减少编译时间和二进制体积
  - `ErrorKnowledgeBase` 改为异步延迟加载：首次打开 Error Hub 时才在后台线程解码 JSON 并构建索引，避免应用启动时阻塞主线程
  - 新增倒排索引（inverted index）实现 O(1) 量级的 token 查找，搜索结果按相关性排序，搜索耗时从 O(n×m) 降到接近 O(命中数)
  - 预计算分类/ID/标题字典，`entries(for:)`、`entry(withID:)`、`findRelated(to:)` 均为 O(1) 或 O(相关数)
  - `ErrorHubView` 增加 150 ms 搜索防抖（debounce）并将搜索任务放到后台线程，UI 不再因快速输入卡顿
  - Error Hub 增加加载/失败占位 UI，支持重试
  - `ErrorToastManager.show(error:)` 先立即弹出 Toast，再在后台查询知识库并自动补全关联条目，避免错误提示延迟

### 修复
- 修复 Wallpaper Engine 无法在桌面真正显示的问题：
  - `DesktopWallpaperWindow` 层级改为 `CGWindowLevelForKey(.desktopIconWindow) + 1`，确保渲染在 Finder 桌面窗口之上从而真正可见（macOS Sonoma+ 中 Finder 桌面背景与图标在同一窗口，无法通过公开 API 插入两者中间；`ignoresMouseEvents = true` 保证鼠标事件仍可穿透到桌面图标）
  - `showWallpapers()` 使用 `orderFront(nil)` 替代 `orderBack(nil)`，避免窗口被系统壁纸覆盖
  - `toggleShowOnDesktop()` 在引擎未开启时自动联动启用并选中首张壁纸，减少用户误操作
  - `addWallpaper(from:)` 自动将导入的文件复制到 Application Support 目录，避免原文件移动/删除后壁纸失效
  - `removeWallpaper(_:)` 删除已复制的壁纸文件，防止应用支持目录堆积
- 修复 `FanControlView` 中 `showToast(message:)` 为 internal，避免从 View 调用时编译错误
- 版本号更新为 v1.4.1 (Build 16)

---

## v1.4.0 — 2026-06-08

### 新增
- **Permission Center 权限控制中心**：
  - Hacker 风格面板，按 Core / Browser / System / Hardware / Optional 分类展示所有 macOS 权限
  - 实时检测 Accessibility、AppleEvents、Screen Recording、Full Disk、Mic、Camera、Location、Notifications、Contacts、Reminders、Calendar、Bluetooth 授权状态
  - 一键请求权限或跳转系统设置对应页面
  - 顶部总进度条与分类筛选
  - First-Time Setup onboarding 引导新用户逐条授权
  - UI 完整使用 `zoomScale` 适配窗口缩放
- **Activity Monitor 活动监视器**：
  - 5 个标签页：CPU / Memory / Energy / Disk / Network
  - 基于 `proc_pidinfo` + `proc_pid_rusage(RUSAGE_INFO_V6)` 的真实进程数据
  - 支持搜索、排序、强制退出/正常退出
  - 权限不足时顶部提示 banner，UI 使用 `zoomScale` 缩放
- **桌面小组件扩展**：
  - 新增 `fanThermalList`、`fanControlDash`、`taskManager` 桌面小组件
  - 新增 5 种桌面标签页：`noteTab`、`todoTab`、`terminalTab`、`cryptoTab`、`quoteTab`
  - 标签页支持锁定、拖拽、标题栏关闭，层级为 `desktopIconWindow + 20`

### 优化
- **AssessPrepHack 强化**：
  - 改为单例 ViewModel，使用真实监考进程标识
  - 增加 Accessibility 检测与系统引导
  - 使用 `kill -STOP/CONT` 精确挂起/恢复监考进程，避免误杀
  - 新增全局 F6 紧急快捷键
- **Wallpaper Engine UI/UX 重做**：
  - 更大更清晰的信息卡片 + 居中胶囊式播放控制按钮
  - 选项行改为水平滚动，彻底解决窗口较窄或高缩放下按钮重叠问题
  - 全部尺寸、间距、描边、控制图标按 `windowZoomScale` 缩放
  - 修复缩略图文字区域在高缩放下被截断的问题
  - `WallpaperQuickAccessBar` 同样适配 `zoomScale`
- Activity Monitor 与 Permission Center 窗口统一纳入 `updateAllWindowLevels` / `updateAllWindowSizes` / `handleClickOutside` 管理

### 修复
- 补充所有可弹窗权限的 `INFOPLIST_KEY` 使用描述（Bluetooth / Calendars / Camera / Contacts / Location / Microphone / Reminders），避免系统弹窗空白或崩溃
- 修复 Location 授权状态判断兼容性（同时接受 `.authorized` 与 `.authorizedAlways`）
- 修复 Full Disk Access 检测使用的探针路径（改为系统 TCC 数据库），减少误判

- 版本号更新为 v1.4.0 (Build 14)

---

## v1.3.0 — 2026-06-04

### 新增
- **Fan Control 风扇控制模块**（对标 TG Pro）：
  - 实时温度传感器监控：支持 Intel / Apple Silicon SMC 直连 + IORegistry fallback + 系统估计三重读取
  - 风扇 RPM 实时监控与手动/自动控制
  - 三种风扇模式：System（系统自控）、Max（全速）、Auto Max（智能规则）
  - Auto Max 规则引擎：支持多规则、目标风扇选择、温度阈值、滞后（hysteresis）、持续时长条件，避免风扇频繁启停
  - 渐进式转速过渡：可配置过渡时间，避免风扇噪音突变
  - 高温系统通知：可开关，阈值可调，带 10 分钟冷却 + Basso 警告音效
  - 睡眠/唤醒自动处理：可选睡眠时切回 System 模式，唤醒后恢复先前模式
  - 温度趋势箭头（↑/↓/→）和迷你历史折线图（sparkline）
  - 临界温度视觉警告（≥85°C 行泛红光）
  - Boost 按钮：一键 30 秒全速，自动恢复
  - 传感器名称实时搜索过滤 + 分类筛选（All/CPU/GPU/Battery/Other）
  - 一键复制传感器数据到剪贴板
  - 菜单栏可选实时温/RPM 显示
  - 完整的 Settings 面板：General / Temperature / Notifications / Fan Mode / Auto Max Rules / System / About

### 优化
- 温度单位（°C/°F）全局统一，含 Menu Bar、通知、导出数据
- 传感器按温度从高到低排序
- Fan Row 显示转速百分比

### 修复
- 修复 Auto Max 规则状态残留导致的活跃指示器不准确
- 修复睡眠唤醒后风扇模式未恢复
- 修复旧版 AutoMaxRule 数据缺失新字段时全部偏好丢失
- 修复 AppleARMIODevice fallback 误报电压/频率为温度传感器
- 修复菜单栏 Fan Control 摘要在睡眠期间继续 SMC 轮询

- 版本号更新为 v1.3.0 (Build 13)

---

## v0.4.4 — 2026-05-25

### 新增
- **弹窗风格增加到 10 种**：
  - 终端乱码（绿色）、系统错误（红色）、黄色警告、紫色系统日志
  - 崩溃报告、矩阵字符块、Windows 蓝屏、十六进制 dump
  - JSON 错误（橙色）、编译错误（红色/黄色）
- **屏幕闪烁效果**：动画开始时白色全屏闪，第 15/30 个弹窗时红色闪烁
- **SFX 增强**：屏幕闪烁时配合错误音效，更有冲击力

### 优化
- **主窗口默认尺寸调大**：width 320→380，maxHeight 400→500
- **主 UI 扫描线覆盖层**：整个面板添加 subtle 扫描线效果，增强 CRT 显示器感
- **Header 改进**：添加版本号小字、底部渐变分隔线
- **TabRow 改进**：hover/focus 时添加白色边框高亮，背景更不透明
- **Footer 改进**：保存按钮改为渐变背景、底部按钮添加图标
- 版本号更新为 v0.4.4 (Build 10)

## v0.4.3 — 2026-05-25

### 优化
- **开机混乱弹窗动画第四次重做**：
  - 弹窗数量固定为 **50** 个（8×6 网格 + 额外填充）
  - **主窗口混入弹窗中显现**：第 3 个弹窗弹出时主窗口开始 alpha→0.45，第 8 个时→0.65，之后随弹窗关闭进度逐步提升到 1.0
  - 主窗口从一开始就藏在弹窗底层，和弹窗一起「诞生」在混乱中
  - **超级黑客 SFX**：弹窗出现时叠加播放系统错误音效（Basso、Funk、Glass、Tock 等），营造系统崩溃的听觉冲击
  - 新增 `playGlitchSound()` 和 `playGlitchBurst(count:)` 音效方法
  - 弹窗抖动更剧烈（3-6 次，±8px），更有故障感
- 版本号更新为 v0.4.3 (Build 9)

## v0.4.2 — 2026-05-25

### 优化
- **开机混乱弹窗动画第三次重做**：
  - 弹窗数量从 28-36 增加到 **45-55**，屏幕几乎看不到空白
  - 采用**网格分布算法**（7×5 网格 + 额外随机填充），确保均匀覆盖无死角
  - 弹窗全部改为**无边框样式**（borderless），最大化内容展示区域
  - 新增 **BlueScreen 蓝屏视图**（模拟 Windows 蓝屏）和 **HexDump 十六进制视图**
  - 所有弹窗内容改为**纯静态渲染**，删除 Timer/Combine/实时刷新，彻底消除卡顿
  - 主窗口使用 `orderBack(nil)` 确保在弹窗最底层，alpha=0 完全不闪烁
  - 弹窗关闭后精准计数，全部关闭后主窗口才渐显
- 版本号更新为 v0.4.2 (Build 8)

## v0.3.2 — 2026-05-25

### 修复
- 修复启动后主 UI 不自动出现的问题：新安装和旧偏好迁移后默认会在启动时弹出主面板
- 修复菜单栏图标在部分深色/浅色菜单栏环境下不明显的问题，改用 macOS 原生 template 图标渲染
- 标签数量徽章改为菜单栏文字徽章，避免自绘图标造成入口不可见
- 版本号更新为 v0.3.2 (Build 5)

---

## v0.4.1 — 2026-05-25

### 优化
- **开机混乱弹窗动画全面重做**：
  - 弹窗数量从 16-22 增加到 **28-36**，几乎覆盖整个屏幕
  - 弹窗尺寸更大（320-520×200-360），允许重叠和部分超出屏幕边界
  - 弹窗显示速度更快（0.03-0.08s 间隔密集出现）
  - 弹窗关闭时精准计数，确保全部关闭后才显现主窗口
  - 主窗口现在在动画开始前就创建并置于底层（alpha=0），等弹窗全部退去后才渐显
- **性能优化**：终端乱码刷新 0.05s→0.15s，矩阵雨 0.06s→0.12s、列数 15→8，减少 CPU 占用避免卡顿
- 版本号更新为 v0.4.1 (Build 7)

## v0.4.0 — 2026-05-25

### 新增
- **独立浮动窗口主 UI**：主面板从 NSPopover 改为无边框独立 NSWindow，可拖动、有阴影、圆角裁切
- **开机混乱弹窗动画**：启动时 Splash Screen 结束后，装饰性小窗口在屏幕上弹跳出现，模拟系统崩溃/终端乱码/错误警告的混乱场面，然后逐个关闭，最后主窗口渐显
  - 终端乱码风：绿色等宽字体滚动 hex dump
  - 系统错误风：红色警告图标 + 错误信息
  - 崩溃报告风：模拟 macOS crash report 堆栈
  - 矩阵雨风：绿色字符雨下落动画
- **窗口拖动支持**：主窗口任意位置可拖动（`DraggableWindow`）

### 修复
- 修复 `AppPreferences.default` 参数顺序导致的编译错误，并为旧版设置增加缺省值迁移
- 修复全局呼出快捷键的 Cocoa/Carbon 修饰符转换
- 修复 Carbon 热键事件处理器误吞其他热键事件的问题
- 修复设置页录制全局快捷键时前台窗口无法捕获按键的问题
- 修复 F1-F12 作为标签快捷键时无法无修饰键保存的问题
- 修复浏览器已启动但没有窗口时无法新建标签打开目标 URL 的问题
- 修复清空全部标签后主面板列表和已注册快捷键不同步的问题
- 修复打开主面板时音效重复播放的问题
- 修复空状态页图标使用系统强调色（蓝色）的问题，统一为黑白主题白色
- 修复自动探测当前标签时误弹 Toast 的问题
- 修复 Toast 在主面板关闭后残留的问题
- 修复动画速度实际值与设定不符的问题（Fast 0.08s → 0.03s，Normal 0.2s → 0.1s）

### 优化
- 补齐面板圆角、主题、徽章、切换延迟、默认浏览器、清空确认等设置项的真实联动
- 菜单栏图标标签数量徽章真正生效
- TabRow 键盘导航焦点高亮
- 导出设置时默认文件名改为带时间戳的完整 JSON 文件名
- 项目部署目标调整为 macOS 14.0
- 版本号更新为 v0.4.0 (Build 6)

---

## v0.3.0 — 2025-05-22

### 新增
- **10 语言本地化**：支持简体中文（源）、繁体中文、英语、日语、韩语、法语、德语、西班牙语、俄语、葡萄牙语
- **黑客风格黑白 UI**：纯黑背景 + 白色细线条边框 + 等宽字体，极简极酷
- **2 秒启动动画**：全屏黑色开屏，显示 Hanazar Products / ClassGod，每次冷启动都有仪式感
- **设置面板增强**：
  - 面板圆角半径可调（0~24px）
  - 菜单栏标签数量徽章开关
  - 显示面板时自动探测当前标签
  - 键盘上下箭头导航开关
  - 切换前延迟（0~500ms）
  - 极速模式（一键禁用所有动画）
- **关于页面重构**：
  - 版本号自动读取 Bundle
  - Release Notes 链接按钮
  - GitHub 仓库链接按钮
  - 开发者 GitHub Profile（hzagaming）链接按钮
- **权限实时检测**：主面板打开时自动检查 Accessibility 权限，未授权时图标变红并弹窗提醒

### 优化
- **动画速度大幅提升**：Fast 模式从 80ms 降至 30ms，Normal 从 200ms 降至 100ms
- **极速模式**：新增全局开关，一键禁用所有动画，追求最快速度
- **按钮响应优化**：减少 hover/press 动画延迟

### 变更
- 主面板 UI 全面重构为黑白黑客风格
- 所有用户可见文本提取到 `Localizable.xcstrings` String Catalog
- `InfoPlist.xcstrings` 独立管理权限描述本地化
- 版本号统一为 v0.3.0 (Build 3)

---

## v0.2.0 — 2025-05-22

### 新增
- 5-Tab 设置面板（General / Shortcuts / Appearance / Browser / Advanced）
- 20+ 可调参数（动画速度、音效、震动、主题、图标样式等）
- 全局呼出快捷键自定义（默认 ⌘⇧C）
- 快捷键冲突检测与覆盖提示
- URL 匹配精度三档可调（Exact / Prefix / Host Only）
- 浏览器未运行时的行为控制（Launch & Open / Launch Only / Do Nothing）
- 外观自定义（图标样式、面板尺寸、主题、行高、紧凑模式）
- 数据导入/导出（JSON 格式）
- Toast 通知系统
- 删除/清空确认对话框
- 音效反馈（10 种系统音效）
- 震动反馈（Haptic）

### 修复
- AppleScript 字符串转义修复（`"` → `""`）
- Cocoa→Carbon 修饰符转换修复
- Carbon 事件处理器内存泄漏修复
- ShortcutPicker 事件监听器泄漏修复
- MenuBarView retain cycle 修复
- 分隔符从 `|||` 改为 ASCII 记录分隔符 `\u{001E}`
- `hostOnly` URL 匹配消除 shell 注入风险
- `.doNothing` 逻辑修复
- BrowserDetector 异步化
- BrowserTab.Equatable 简化为仅比较 `id`

---

## v0.1.0 — 2025-05-22

### 新增
- 菜单栏常驻应用（LSUIElement，无 Dock 图标）
- 探测前台浏览器标签（Safari / Chrome / Edge）
- 保存标签并绑定全局快捷键
- 按下快捷键切换回指定标签
- 标签关闭后可重新打开
- 编辑/删除已保存标签
- 本地持久化存储（UserDefaults）
- Accessibility / Automation 权限申请
