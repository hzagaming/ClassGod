# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

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
