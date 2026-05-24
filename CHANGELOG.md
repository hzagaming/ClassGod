# ClassGod 更新日志

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
