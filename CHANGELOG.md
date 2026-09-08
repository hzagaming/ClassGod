# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.52 — 2026-09-08

### 修复与优化
- **设置禁用态修复**：Toggle 与 Picker 设置行现在读取 SwiftUI 环境禁用状态；禁用时立即清除 hover、高亮与残留交互暗示，并以统一透明度明确呈现不可操作状态。
- **真实场景一致性**：极速动画模式下的动画速度选择器、尚未开放的登录启动开关，以及 Fake Lock 的条件设置不再在禁用时错误响应悬停。
- **UI / UX 与动效深度复核**：复查 19 个功能窗口、主面板、壁纸、Todo、Schedule、Focus Flow、Fake Lock、窗口边界、自定义 hover / press、Reduce Motion、极速动画与 VoiceOver 状态，未发现新的阻塞问题。
- **SFX / BGM 深度复核**：交互与窗口音效继续只在有效动作上触发并保持有限重叠；视频壁纸继续遵循默认静音、归一化音量、主屏出声、副屏静音与播放器销毁清理，项目不新增持续 BGM。
- **更新链路复核**：自动更新继续在启动时及每 6 小时检查 GitHub 正式 Release，并在安装前校验 HTTPS、文件大小与 SHA-256；本轮未改变发布或安装权限边界。
- **回归保护**：新增禁用设置行交互策略测试，覆盖启用/禁用与 hover 组合，防止不可用控件再次表现为可点击。

### 验证
- **质量回归**：主应用 252 项、Helper 17 项测试全部通过，并完成 Analyze、Debug / Release 构建、隔离配置原生启动冒烟、字符串目录解析与版本一致性检查。
- 版本号更新为 v1.5.52 (Build 77)

### 说明
- 当前公开构建仍仅提供 Apple Silicon arm64，App 使用 ad-hoc 签名，PKG 未使用 Developer ID Installer 签名，且尚未经过 Apple 公证。
- 首次打开时，macOS 可能要求在“系统设置 → 隐私与安全性”中手动确认。
