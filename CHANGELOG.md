# ClassGod 更新日志

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
