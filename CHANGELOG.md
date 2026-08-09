# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.29 — 2026-08-09

### 优化
- **PKG 首次启动门禁**：保留 ClassGod 品牌启动与 Chaos 动画，动画结束后检查完整 20 项权限；15 项必须由 macOS 真实检测为已授权，5 项不可可靠查询的系统权限必须打开对应设置页后逐项人工确认。
- **权限撤销保护**：应用每次重新激活都会复查权限；任意已检测权限被撤销后立即隐藏主面板和功能窗口，停止功能服务并重新进入权限门禁。
- **完全卸载工具**：设置的高级页面新增独立卸载区，通过两次破坏性确认与一次管理员授权后，删除应用、Helper、LaunchDaemon、偏好、Clipo、壁纸、Widget 容器、缓存、TCC 记录和 PKG 收据。
- **PKG 部署适配**：卸载路径与收据统一绑定 `/Applications/ClassGod.app` 和 `com.hanazar.classgod.pkg`，拒绝临时目录、其他 App 或宽泛目录目标。

### 修复
- **门禁前后台泄漏**：主面板在权限完成前只作为无业务内容的动画锚点，不再提前初始化 Tab 快捷键、Clipo、Fake Lock、Panic、Widget 同步、壁纸或风扇状态轮询。
- **重新授权后窗口失效**：强制锁定窗口时同步推进转场代际，权限恢复后主面板能够可靠重新显示，不会残留旧的“目标可见”状态。
- **人工权限误确认**：Files and Folders、Developer Tools、App Management、Media Library 与 Local Network 只有实际打开对应系统设置后才能标记完成，且可随时取消确认。
- **Helper 卸载残留**：删除文件前先通过 `SMAppService.unregister()` 注销特权 Helper；已注销或未安装状态安全跳过，真实失败会中止并给出错误。
- **卸载命令安全**：全部路径和用户参数使用 Shell 引号，清理计划只接受精确 App、用户 Library 子路径及三个明确系统路径。
- **UI / UX / SFX / BGM 自查**：权限门禁使用黑底自定义强调色、完整进度、状态、系统设置、人工确认、刷新与退出；卸载等待和失败均有明确反馈，未改变现有短音效及壁纸 BGM 策略。
- **质量回归**：新增启动门禁、人工复核、卸载范围、Shell 注入防护与本地化测试；完成主应用、Helper、Debug / Release、Analyze、字符串目录、Helper 嵌入、版本、签名与 PKG 内容校验。
- 版本号更新为 v1.5.29 (Build 54)

### 说明
- macOS 不允许 PKG 安装器代替用户授予 TCC 权限；本版本在首次启动时逐项请求/引导，全部完成后才进入主 Panel。
- “完全卸载”只删除 ClassGod 明确拥有的本地路径和权限记录，不触碰浏览器或其他 App 数据；系统统一日志、备份等由 macOS 管理的历史记录不在应用控制范围内。
- 公开分发 PKG 仍需要有效的 Developer ID Installer / Application 证书和 Apple 公证。
