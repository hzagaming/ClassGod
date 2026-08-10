# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

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

## v1.5.30 — 2026-08-09

### 优化
- **100ms 权限实时检测**：权限门禁和 Permission Center 可见时以 100ms 周期静默复核全部可检测权限，授权结果变化会立即更新对应状态、按钮和总进度。
- **低开销状态发布**：后台实时检测仅在权限状态或详情真实改变时刷新 SwiftUI；用户主动刷新仍会更新时间，避免高频无效重绘。
- **授权对象说明**：权限状态严格对应当前运行的 App；测试时必须给 `/Applications/ClassGod.app` 授权，给 Xcode DerivedData 中的调试副本授权不会解锁已安装版本。

### 修复
- **授权后仍显示 Allow**：旧实现会丢弃检查期间到达的普通刷新；现在所有重叠刷新都会保留并合并执行，从系统设置返回和用户手动刷新不再失效。
- **通知状态固定延迟**：移除 `DispatchSemaphore` 与最坏 500ms 等待，改为异步读取通知授权状态，不再拖慢整轮权限检查。
- **Automation 永久未授权**：`System Events` 未运行时 `AEDeterminePermissionToAutomateTarget` 会返回 `procNotFound`；现在先在后台启动目标，再执行状态检测和系统授权请求。
- **状态检查生命周期**：进入权限窗口立即启动实时检测，离开窗口或应用终止时立即取消任务，不在后台持续轮询。
- **质量回归**：新增实时检测周期、刷新保留、状态变化发布与 Apple Events 目标准备测试，并复查原生门禁、签名身份和完整构建链。
- 版本号更新为 v1.5.30 (Build 55)

### 说明
- PKG 仍不能替用户直接授予 TCC 权限，这是 macOS 的系统安全边界；应用只能发起官方提示、打开对应设置并实时读取系统结果。
- 部分 macOS 权限由系统明确要求退出并重新打开 App 后生效；此时门禁会保持锁定，重新启动后在首轮检查中自动识别。
- 当前 PKG 仍缺少 Developer ID Installer 签名与 Apple 公证，仅用于本机安装测试。
