# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.35 — 2026-08-16

### 优化
- **窗口自适应一致性**：主面板、添加标签、AssessPrep、BrowserBypasser、DestinTab、SuperSwitch、Hacker Desktop、风扇面板及 General / Advanced / Fan Control 设置中的默认间距、边距、描边和说明文字统一跟随 50%–200% 窗口缩放；DestinTab 扫描线密度同步适配缩放比例。
- **VoiceOver 控件语义**：Fake Lock 模式、URL 与浏览器选中态，以及风扇自定义规则的启用、目标风扇、转速模式、传感器、比较条件和阈值补齐准确的可访问性标签。
- **交互反馈去重**：重复选择当前浏览器或强调色、在默认强调色上重置时保持安静；真实重置、Fake Lock 导航锁切换与停止会话继续提供一次明确的 SFX / 触感反馈。

### 修复
- **Fake Lock 导航过期回写**：前进 / 后退 AppleScript 使用独立代际令牌；停止、重启会话或发起新导航后，迟到结果不能覆盖当前状态或播放错误的成功反馈。
- **Fake Lock 会话配置漂移**：启动与活动期间锁定模式、浏览器、URL 和全屏配置，避免界面显示与实际浏览器会话不一致；停止服务时恢复 Ready 状态，活动时不再显示重复 Start 操作。
- **版本信息硬编码**：高级设置中的 Build 文案改为字符串目录格式化值，英文与简体中文环境分别使用对应标点和“Build / 构建”表达。
- **质量回归**：主应用 168 项、Helper 17 项测试全部通过，并完成 Debug / Release、Analyze、字符串目录编译产物、Helper 嵌入与签名校验。
- 版本号更新为 v1.5.35 (Build 60)

### 说明
- SFX 使用内存生成的短音色，无外部音频资源；壁纸 BGM 的多屏静音、音量、循环、任务与观察者清理已复查，本版本不改变既有播放策略。
- AppleScript、macOS 权限授权与真实 SMC 风扇写入依赖本机应用、系统授权和硬件，自动化验证仅覆盖策略、编译与安全降级路径。
- 当前构建仍为 Apple Silicon arm64 本地 ad-hoc 签名；公开分发仍需要 Developer ID Application / Installer 签名与 Apple 公证。

## v1.5.34 — 2026-08-16

### 优化
- **英文目录完整生效**：把主 App 275 条与 Widget 2 条已有英文译文从待处理状态确认为可发布状态；英文构建不再因目录状态回退显示标识符键名。
- **设置页自适应缩放**：风扇自定义规则、快捷键提示、浏览器信息与强调色控件的字号、间距、尺寸统一跟随 50%–200% 窗口缩放。
- **语言覆盖说明**：明确英语为开发与回退语言、简体中文覆盖主要界面，其余八种语言为渐进式翻译，未覆盖内容安全回退英语。

### 修复
- **DestinTab 导入错误未本地化**：文件读取失败与文件选择失败现在共用已本地化的格式化反馈，英文和简体中文构建均不会显示硬编码文本或字符串键。
- **导入设置破坏 UI**：偏好加载、导入、保存和导出会统一规范透明度、缩放、面板尺寸、圆角、行高与最大标签数；非有限值回退默认值，越界值限制到实际控件范围。
- **无效语言设置残留**：移除从未参与运行时语言选择的 `preferredLanguage` 持久化路径；实际默认语言继续由 App 的 `en` 开发语言与系统本地化机制决定。
- **质量回归**：主应用 167 项、Helper 17 项测试全部通过，并完成 Debug / Release、Analyze、字符串目录编译产物、Helper 嵌入与签名校验。
- 版本号更新为 v1.5.34 (Build 59)

### 说明
- SFX 的并发上限、延迟音效取消与开关复核，以及壁纸 BGM 的多屏静音、音量同步、任务和观察者清理均已复查，本版本无需改变稳定行为。
- 当前构建仍为 Apple Silicon arm64 本地 ad-hoc 签名；公开分发仍需要 Developer ID Application / Installer 签名与 Apple 公证。

## v1.5.33 — 2026-08-15

### 修复
- **Fake Lock 过期任务回写**：为启动与全屏流程增加代际令牌；停止会话、关闭服务或再次启动后，旧 AppleScript 结果不能重新激活状态或覆盖最新提示。
- **Fake Lock 错误误报**：重复启动处于 Working 状态时静默合并，不再错误提示 URL 无效；停止操作同步清除 Working 状态。
- **快捷键修饰位污染**：录制和偏好解码统一过滤 Caps Lock、Fn、Numeric Pad 等 Carbon 不支持的标志，只保存 Command、Option、Control 与 Shift。
- **快捷键事件穿透**：录制期间消费无效按键和 flagsChanged 事件，避免 Return、Tab、方向键或单键误触当前窗口控件。
- **Activity Monitor 空白搜索**：搜索词统一裁剪首尾空白，纯空白查询不再隐藏全部进程。
- **质量回归**：主应用 164 项、Helper 17 项测试全部通过，并完成 Debug / Release、Analyze、字符串目录、Helper 嵌入与签名校验。
- 版本号更新为 v1.5.33 (Build 58)

### 说明
- 当前构建仍为 Apple Silicon arm64 本地 ad-hoc 签名；公开分发仍需要 Developer ID Application / Installer 签名与 Apple 公证。

## v1.5.32 — 2026-08-10

### 优化
- **权限分级 UX**：权限门禁按核心必需、建议授权、可选权限分组；可选项固定到底部，仅两项核心权限参与自动解锁进度。
- **会话级跳过**：新增“暂时跳过并使用”，不写入偏好；用户可先进入主界面，未授权功能继续按现有权限检查安全降级。
- **本地隐私承诺**：权限门禁与 Permission Center 明确说明权限状态和用户数据在本机处理，不含遥测、后台上传或 ClassGod 后端。
- **卸载范围可见**：设置页在二次确认前列明权限、用户数据、Helper/LaunchDaemon 与安装收据四类清理内容。

### 修复
- **Input Monitoring / Screen Recording 无法跳转**：原生请求未通过时立即打开对应系统设置，精确深链失败时回退“隐私与安全”根页。
- **可选权限错误阻塞门禁**：门禁解锁不再要求 20 项全部完成；建议与可选权限不会阻止主功能启动。
- **TCC 清理覆盖不足**：卸载时重置主 App、Widget 与 Helper 三个权限域，并清除应用产生的通知请求和已投递通知。
- **卸载残留补全**：新增主 App 容器、Application Scripts、Cookies/HTTPStorages、系统级 Application Support/Cache 等精确 ClassGod 路径，并补充 Widget defaults 清理。
- **Helper 注销中断卸载**：SMAppService 注销改为前置尽力清理；即使失败，管理员脚本仍会 bootout、终止并删除 Helper 与 LaunchDaemon。
- **质量回归**：主应用 161 项、Helper 17 项测试全部通过，并完成 Debug / Release、Analyze、字符串目录、Helper 嵌入与签名校验。
- 版本号更新为 v1.5.32 (Build 57)

### 说明
- `tccutil reset All <bundle_id>` 按 macOS 官方命令行为重置对应应用的隐私决定；通知授权等系统注册会随 App 删除由 macOS 管理。
- 当前构建仍为本地 ad-hoc 签名，正式分发仍需要 Developer ID、Installer 签名与 Apple 公证。

## v1.5.31 — 2026-08-09

### 优化
- **自适应实时检测**：未解决权限保持 100ms 轮询，完整授权项目每 10 个周期全量复核一次；权限撤销仍会在一秒内重新锁定，同时显著减少已授权状态的重复系统查询。
- **实时状态反馈**：权限门禁与 Permission Center 增加“实时 · 100ms”标识，部分授权使用独立黄色状态，底栏改为显示真实的最新检查时间。
- **空任务消除**：全部可检测权限已授权时跳过 100ms 空扫描，不再反复创建无工作内容的异步任务；功能页单次请求也不会遗留永久权限轮询。

### 修复
- **部分授权误判完整**：PhotoKit `.limited`、EventKit `.writeOnly`、UserNotifications `.provisional/.ephemeral` 不再映射为已授权，只有完整访问才能解锁门禁。
- **授权请求等待过久**：实时检测发现请求项目已完整授权后立即清除 Checking 状态，迟到的系统回调保持幂等。
- **重叠刷新范围丢失**：检查期间到达的即时扫描与全量扫描请求现在会合并为最完整范围，不会因 100ms 轮询覆盖用户手动刷新。
- **Contacts 平台兼容**：按 macOS SDK 真实可用状态处理 Contacts，移除仅其他 Apple 平台支持的 Limited 测试假设。
- **质量回归**：主应用 158 项、Helper 17 项测试全部通过，并完成 Debug / Release、Analyze、字符串目录、版本、Helper 嵌入和签名校验。
- 版本号更新为 v1.5.31 (Build 56)

### 说明
- PKG 仍不能替用户直接授予 TCC 权限；部分授权也必须由用户在系统设置中升级为完整授权。
- 当前 PKG 仍缺少 Developer ID Installer 签名与 Apple 公证，仅用于本机安装测试。
