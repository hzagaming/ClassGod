# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.28 — 2026-08-08

### 优化
- **Fake Lock**：新增 Safari、Chrome、Edge 受控浏览器会话，支持 URL 规范化、前进/后退独立锁定、全屏启动、全局快捷键启用/解除，以及强制全屏的 MapTest Bypass 模式。
- **独立窗口布局**：14 个功能窗口分别使用适配内容的默认与最小尺寸，可自由拖拽缩放；普通偏好变化不再重置用户手动调整的窗口尺寸，缩放比例变化时按现有大小等比调整。
- **主题样式**：保持 Hacker 黑色底色，新增用户自定义强调色、六组预设与重置入口；主面板、设置、Clipo、DestinTab、SuperSwitch、Wallpaper、风扇、权限、活动监视器、错误百科及其他功能统一响应主题色。
- **官方 Widgets**：19 个官方 Widget 与空状态读取共享强调色，主题修改后立即刷新时间线，黑色卡片底色保持不变。
- **Permission Center 最大化权限**：20 项权限按目录顺序逐项展示，仅跳过已确认授权项；原生提示、系统设置与人工复核状态保持真实，不伪造 macOS 授权结果。
- **风扇控制引导**：无可写风扇时明确展示 Helper 授权入口与只读原因，手动与 Auto Max 覆盖滑块的目标值反馈更直接。

### 修复
- **手动 RPM 滑块回弹**：拖动时立即写回规范化目标 RPM，再以 150ms 防抖写入硬件，采样刷新不再用旧目标值抢回 Slider 位置；越界和不可写目标安全拒绝。
- **Helper 状态误报**：应用包内 plist 与可执行 Helper 完整时，不再把 Service Management 的 `notFound` 直接误报为“缺少 Helper”并禁用授权；授权可重试，签名或服务注册失败会显示准确原因。
- **MapTest 全屏一致性**：MapTest Bypass 在执行层始终请求全屏，界面同步显示不可关闭的全屏状态；快捷键冲突或不可用时显示明确反馈。
- **功能窗口高度耦合**：DestinTab 与 Fan Control 不再读取主面板高度作为内部上限，大窗口能够完整利用可用空间。
- **主题数据健壮性**：强调色初始化、反序列化和 Widget 快照统一裁剪 RGB，损坏或非有限共享值安全回退默认色。
- **SFX / BGM 自查**：新功能的启动、停止、锁定、导航失败与浏览器选择保留短音效/触感反馈；壁纸视频音轨生命周期保持原策略，不新增持续 BGM。
- **Release 签名清理**：App 与 Widget 的 Release 构建不再注入 `get-task-allow` 调试权限，打包产物只保留功能必需的 entitlement。
- **质量回归**：新增风扇目标、Helper 包校验、权限审查、Fake Lock、窗口策略、主题与 Widget 快照测试；主应用 143 项与 Helper 17 项全部通过，并完成 Debug / Release、Analyze、字符串目录、plist、Helper 嵌入、产物版本与签名校验。
- 版本号更新为 v1.5.28 (Build 53)

### 说明
- macOS 权限仍必须由用户在系统提示或系统设置中手动批准；ClassGod 只负责完整列出、逐项引导和真实检测。
- Fake Lock 只控制用户指定的浏览器、网址、全屏与 ClassGod 本地导航按钮，不注入页面或绕过第三方安全机制；停止会话不会关闭浏览器。
- 启动路径继续保持“ClassGod 品牌界面 → Chaos 动画 → 主 Panel”，Widget Center 仍从主页入口进入。
