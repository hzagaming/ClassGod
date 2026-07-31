# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.20 — 2026-07-31

### 优化
- **DestinTab 批量体验**：全选严格跟随搜索、排序与面板显示上限，不再把用户看不到的标签计入选择范围。
- **Toast 与启动动画生命周期**：错误 Toast、风扇反馈和 Hacker Reveal 的延迟任务均可取消；揭示动画完成后立即停止高频字符计时器。

### 修复
- **隐藏标签误删**：修复 DestinTab 在显示数量受限时“全选”会选中并删除隐藏标签的问题。
- **批量状态准确性**：标签从其他窗口删除或重新载入后主动清理失效选择 ID，删除数量只统计真实存在的标签。
- **Toast 竞态**：手动关闭全局错误 Toast 会取消对应自动关闭任务，全部关闭会统一清理；风扇连续反馈不再被旧回调提前隐藏。
- **启动动画残留**：Hacker Reveal 随视图退出取消等待序列，不再在窗口关闭后修改状态或保留 40ms 计时器。
- **质量回归**：新增批量选择边界、失效选择清理和 Toast 任务取消测试，并完成主应用、Helper、Debug / Release、Analyze、字符串目录和 plist 校验。
- 版本号更新为 v1.5.20 (Build 45)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。
- 本版本未改变风扇硬件识别、Clipo 数据格式、SFX 音色/通道与壁纸 BGM 播放规则；无法获得可信 RPM 的 Apple Silicon 仍按现有只读/估算路径安全降级。
