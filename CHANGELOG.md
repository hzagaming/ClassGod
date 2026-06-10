# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.4.7 — 2026-06-11

### 修复
- **关闭风扇面板后风扇不回 system**：`FanControlViewModel.stopMonitoring()` 现在会在面板关闭时将所有风扇设回 `.system` 模式，避免风扇被卡在最后一次命令的 RPM
- **修复 `isUsingIORegistryFallback` 被错误重置**：`readAll()` 中 `isUsingIORegistryFallback = false` 曾无条件覆盖之前的正确设置，导致 IORegistry fallback 状态显示不正确
- **修复 `fanAccessReason` 被覆盖**：当 helper socket 存在但返回空数据时，具体的诊断提示不再被 `updateFanAccessReason()` 的通用消息覆盖
- **清理无意义的 AppleSPU fan placeholder**：移除只检测但不创建风扇条目的死代码
- 版本号更新为 v1.4.7 (Build 22)

---

## v1.4.6 — 2026-06-10

### 修复
- **Helper socket 权限修复**：创建 Unix socket 后执行 `chmod 666`，解决普通用户无法连接 root helper 的问题（之前 socket 只有 root 可写）
- **Helper 启动时自动打印发现的传感器数量**：方便用户验证 helper 实际能读到多少传感器
- **PMU 传感器命名去重**：给每个 `AppleARMPMUTempSensor` 加上 locationID 后缀，避免 50+ 个传感器显示同名
- **Helper 返回空数据时的诊断提示**：`SMCService.readAll()` 当 helper socket 存在但返回空时，更新 `fanAccessReason` 提示用户重启 helper
- 版本号更新为 v1.4.6 (Build 21)

---

## v1.4.5 — 2026-06-10

### 新增
- **Auto Max 规则传感器新增 `Average CPU`**：替代 `Highest CPU` 作为默认选项，取所有 CPU/Cluster 传感器平均值，避免单核瞬时尖峰导致误触发

### 优化
- **传感器发现大幅增强**：
  - `ClassGodHelper` 温度键列表从 18 个扩展到 34 个，与主 app 完全一致
  - Helper 和主 app 均新增 **SMC 动态键枚举**：读取 `#KEY` 总键数，遍历所有键的 4CC 码和类型码，自动发现机器专属温度传感器（`T` 前缀 + `sp78`/`sp79`/`sp7a`/`sp5a`/`si8c` 类型）
  - `AppleARMIODevice` IORegistry 扫描扩展：除 `"T"` 前缀外，新增扫描 `"PMU"`、`"ANE"`、`"ISP"` 相关属性以及 `"location"` 字符串指向温度通道的条目
- **风扇控制策略 relaxed**：
  - 默认规则阈值：70°C → **80°C**
  - 默认目标转速：100% → **60%**
  - 触发持续时长：3s → **5s**
  - 渐进时间：21s → **10s**
  - 默认传感器：`Highest CPU` → **`Average CPU`**

### 修复
- **规则停用后风扇不释放**：`evaluateAutoMaxRules()` 每次循环开头清空 `fanTargets`，规则消失后不再残留旧 target
- **Auto Max 无规则激活时回 system**：`applyGradualRamp()` 当 `fanTargets.isEmpty` 时，对所有风扇调用 `setFanMode(.system)`，把控制权交还 macOS
- **Thermal State 伪传感器污染**：`readThermalStateTemperatures()` 返回的 35/50/70/90°C 传感器统一标记 `isEstimated = true`，Auto Max 规则不再误把它们当作真实硬件读数参与 `highestCPU` 计算
- 版本号更新为 v1.4.5 (Build 20)

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
