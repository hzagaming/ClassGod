# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.19 — 2026-07-31

### 优化
- **UI / UX / VoiceOver**：窗口缩放、DestinTab 排序与批量操作、风扇筛选、AssessPrepHack 应急操作及 SuperSwitch 图标选择补齐准确的屏幕阅读器名称。
- **交互生命周期**：弹跳动画、列表按压反馈与错误百科搜索任务在视图退出时主动取消，避免窗口关闭后残留延迟状态更新。

### 修复
- **DestinTab 排序稳定性**：置顶分组改为保序分区，手动、最近使用、字母与浏览器排序不再随机打乱同组标签。
- **设置导出覆盖**：直接原子写入保存面板目标，允许可靠覆盖已有文件，并明确反馈导出成功或失败，不再静默丢失保存结果。
- **本地化准确性**：修正 DestinTab 批量操作与 AssessPrepHack 操作在英文环境仍显示中文的问题。
- **风扇筛选辅助功能**：传感器筛选按钮不再错误播报为 Clipo 清除搜索，搜索清除入口获得独立名称。
- **质量回归**：新增置顶保序、导出覆盖与英文辅助文案测试，并完成主应用、Helper、Debug / Release、Analyze、字符串目录和 plist 校验。
- 版本号更新为 v1.5.19 (Build 44)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。
- 本版本未改变风扇硬件识别、Clipo 数据、SFX 通道与壁纸 BGM 播放规则；无法获得可信 RPM 的 Apple Silicon 仍按现有只读/估算路径安全降级。
