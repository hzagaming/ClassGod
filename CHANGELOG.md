# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.18 — 2026-07-30

### 优化
- **UI / UX / VoiceOver**：AssessPrepHack、SuperSwitch、BrowserBypasser、DestinTab、Activity Monitor、Permission Center 与错误百科的关闭、添加、刷新、编辑、置顶、删除和搜索清除入口补齐可读名称。
- **壁纸导入响应**：图片与视频复制移到后台执行，大文件导入不再阻塞主窗口；安全作用域访问完成后及时释放，导入成功音效只在实际写入后播放。

### 修复
- **SuperSwitch Toast 竞态**：快速连续操作会取消旧隐藏回调，前一个 Toast 不再提前关闭后一个 Toast；窗口销毁时同步释放待执行任务。
- **错误百科复制反馈**：每段代码独立显示复制成功状态，快速复制其他示例时旧回调不会清除新反馈，关闭详情后不再残留延迟状态更新。
- **Activity Monitor 生命周期**：权限提示检查归入 ViewModel 并随监控启停取消，窗口隐藏后不再被旧回调重新写入提示状态。
- **质量回归**：新增临时反馈代际、权限提示策略与壁纸导入类型测试，并完成主应用、Helper、Debug / Release、Analyze、字符串目录和 plist 校验。
- 版本号更新为 v1.5.18 (Build 43)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。
- 本版本未改变风扇硬件识别、Clipo 数据与壁纸 BGM 播放规则；无法获得可信 RPM 的 Apple Silicon 仍按现有只读/估算路径安全降级。
