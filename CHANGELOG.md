# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.39 — 2026-08-18

### 新增
- **本地 Notes 工作区**：新增多笔记双栏编辑页面，支持搜索、置顶、选择、删除、自动标题与本地自动保存；标题、正文和笔记总数均有明确边界。
- **跨空间悬浮笔记**：Notes 使用独立悬浮窗口，可跨应用、桌面空间和全屏工作区持续显示，且不受“点击窗口外自动关闭”影响。
- **软件更新中心**：设置中新增更新页面；应用启动时自动检查 GitHub 最新正式 Release，并每 6 小时复查，展示 Release 说明、下载进度与安装状态。

### 修复与安全
- **更新包完整性**：自动更新只接受 HTTPS PKG/DMG，优先 PKG，并强制校验 GitHub SHA-256、精确文件大小、响应状态、文件名和容量上限；缺少或格式错误的摘要会拒绝自动安装。
- **笔记持久化安全**：笔记以原子写入保存到 Application Support；损坏快照会保留备份，应用退出前会等待最后一次保存完成。
- **更新任务清理**：应用退出时取消检查任务、下载任务、进度任务与周期定时器，避免后台资源残留。
- **质量回归**：主应用 190 项、Helper 17 项测试全部通过，并完成 Debug / Release、Analyze、字符串目录、版本一致性、Helper / LaunchDaemon / Widget 嵌入与签名校验。
- 版本号更新为 v1.5.39 (Build 64)

### 说明
- Notes 数据保存在 `~/Library/Application Support/ClassGod/Notes/notes.json`，不会写入仓库或上传。
- 校验完成后会自动打开 macOS Installer；安装仍由系统界面完成，并可能要求管理员授权或在“隐私与安全性”中确认。
- 当前构建仍为 Apple Silicon arm64 本地 ad-hoc 签名；公开分发仍需要 Developer ID Application / Installer 签名与 Apple 公证。
