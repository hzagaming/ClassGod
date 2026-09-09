# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.53 — 2026-09-09

### 修复与优化
- **禁用动效完整性修复**：通用 hover 缩放现在读取 SwiftUI 环境禁用状态；控件禁用时立即回到静止比例并清除残留 hover，不再表现为仍可操作。
- **设置操作行状态统一**：`SettingsActionRow` 补齐与 Toggle、Picker 相同的禁用视觉策略；卸载进行中不会继续显示高亮、描边或完整交互权重。
- **真实场景修复**：快捷键已处于默认组合时，禁用的重置按钮不再响应鼠标悬停缩放；重新启用后仍保留正常反馈。
- **UI / UX 与动效深度复核**：复查 19 个功能窗口、近期设置与壁纸改动、主面板、Todo、Schedule、Focus Flow、Fake Lock、自定义 hover / press、Reduce Motion、极速动画与 VoiceOver 状态，未发现新的阻塞问题。
- **SFX / BGM 深度复核**：复查 248 个声音调用点、窗口语义音色与有限重叠声道；壁纸继续遵循默认静音、归一化音量、主屏出声、副屏静音与播放器销毁清理，项目不新增持续 BGM。
- **生命周期与更新安全复核**：Timer、NSEvent monitor、NotificationCenter observer 与 AVPlayer 均保持对应清理；更新仍限制到可信 GitHub HTTPS 端点，并校验正式版本、大小与 SHA-256。
- **回归保护**：新增禁用 hover 组合测试，覆盖启用、禁用与非悬停状态，防止复用控件再次泄漏交互暗示。

### 验证
- **质量回归**：主应用 253 项、Helper 17 项测试全部通过，并完成 Analyze、Debug / Release 构建、隔离配置原生启动冒烟、字符串目录解析与版本一致性检查。
- 版本号更新为 v1.5.53 (Build 78)

### 说明
- 当前公开构建仍仅提供 Apple Silicon arm64，App 使用 ad-hoc 签名，PKG 未使用 Developer ID Installer 签名，且尚未经过 Apple 公证。
- 首次打开时，macOS 可能要求在“系统设置 → 隐私与安全性”中手动确认。
