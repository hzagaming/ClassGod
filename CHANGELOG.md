# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

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

