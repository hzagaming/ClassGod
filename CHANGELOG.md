# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.4.4 — 2026-06-10

### 优化
- **`SystemMonitor.readProcesses()` 完全后台化**：
  - 将繁重的逐进程 `proc_pidinfo` / `proc_pid_rusage` / `proc_pidpath` 调用全部放入 `DispatchQueue.global(.userInitiated)` 并发队列
  - `group.wait()` 不再阻塞 `MainActor` 定时器回调，UI 不会再因进程枚举产生明显卡顿
- **`ProcessMonitorInfo.id` 稳定性**：`Identifiable` 的 `id` 从每次刷新的 `UUID()` 改为稳定的 `pid`，`ForEach` diffing 大幅减轻，Activity Monitor 行选择状态可持久保持
- **`ActivityMonitorViewModel.energyAccumulator` 防泄漏**：`updateEnergyHistory()` 每次只保留当前存活进程的条目，退出 PIDs 不再无限累积
- **`FanControlSettingsView` 传感器读取异步化**：`AutoMaxRuleRow.onAppear` 中 `SMCService.readTemperatures()` 改为 `Task.detached` 后台执行，避免设置页展开时主线程阻塞

### 修复
- **`ErrorToastManager` 窗口泄漏**：`dismiss(id:)` 中增加 `windows.removeValue(forKey: id)`，Toast 关闭后对应的 `NSPanel` 被正确释放
- **`NettopMonitor` 终止后自重启**：`stop()` 时先 `terminationHandler = nil` 再 `terminate()`，避免 `nettop` 被外部停止后触发 handler 自动重启
- **`NettopMonitor` 首样本丢弃**：`flushedSampleCount >= 2` 修正为 `>= 1`，第一个有效 delta 即可被消费
- **`SystemMonitor` `proc_pid_rusage` 指针重绑定**：修正为 `withMemoryRebound(to: rusage_info_t.self)`，消除未定义行为
- **`SystemMonitor` BPS 计算防溢出**：`UInt64(Double)` 转换前增加上限钳制（`scaled < Double(UInt64.max)`），防止极端 delta 导致运行时溢出
- **`MenuBarView` `updateFanSummary()` 编译错误**：修复 `'weak' may only be applied to class` 与 missing `await` 错误，风扇摘要读取完全异步
- 版本号更新为 v1.4.4 (Build 19)

---

## v1.4.3 — 2026-06-10

### 优化
- **Fan Control 数据实时性大幅提升**：
  - 刷新间隔下限从 1.0s 降到 **0.5s**，设置滑块支持 0.5s 步进，默认更新间隔改为 1.0s
  - `SMCHelperClient` 改为**持久连接**：复用 Unix socket fd，避免每次读/写都经历 connect/teardown；超时从 3s 缩短到 1s，失败自动重连
  - `ClassGodHelper` 新增 `readAll` 命令，一次 socket 往返同时返回 fans + temps，减少一半往返
  - `SMCService` 新增 `readAll()` 统一入口，带 **250ms TTL 缓存**，多个 UI 表面（面板、桌面小组件、菜单栏）共享同一份快照，避免重复 SMC/Helper 访问
  - Helper 可用时**完全跳过** 29 键 direct-SMC 遍历（省去最多 87 次 `IOConnectCallStructMethod`）
  - 所有风扇/温度读取（`FanControlViewModel`、`桌面小组件`、`菜单栏`）全部移到**后台线程** (`Task.detached`)，UI 不再因 SMC I/O 卡顿
  - 风扇 Slider 增加 **150ms debounce**，拖动时不再连续往 Helper/SMC 写数据
  - Auto Max 规则评估间隔从固定 2.0s 改为跟随用户设置的更新间隔

### 修复
- 恢复 `readAll()` 中缺失的 IORegistry fan fallback，确保无 Helper 且无 direct-SMC 时仍能显示风扇
- 版本号更新为 v1.4.3 (Build 18)
