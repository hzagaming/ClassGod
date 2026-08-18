# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.41 — 2026-08-19

### 修复与安全
- **更新来源约束**：自动更新入口只接受 `github.com/hzagaming/ClassGod/releases/download/` 下的本仓库资产，重定向终点限定为可信 GitHub 域，拒绝第三方 HTTPS、伪造域名、用户信息与自定义端口。
- **更新完整性链路**：继续强制校验 GitHub SHA-256、精确文件大小、安全文件名与容量上限；来源验证失败时不会下载、缓存或打开安装包。

### UI / UX
- **权限状态准确性**：权限门与权限中心从固定“实时 · 100ms”改为“实时 · 自适应”，准确反映按权限能力动态轮询、系统回调、应用激活与手动刷新共同工作的实际策略。

### 验证
- **质量回归**：主应用 198 项、Helper 17 项测试全部通过，并完成 Debug / Release、Analyze、字符串目录、版本一致性、Helper / LaunchDaemon / Widget 嵌入与签名校验。
- 版本号更新为 v1.5.41 (Build 66)

### 说明
- 当前公开构建仍仅提供 Apple Silicon arm64，App 使用 ad-hoc 签名，PKG 未使用 Developer ID Installer 签名，且尚未经过 Apple 公证。
- 首次打开时，macOS 可能要求在“系统设置 → 隐私与安全性”中手动确认。
