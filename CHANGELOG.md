# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

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
