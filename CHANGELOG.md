# ClassGod 更新日志

> 查看更早版本记录请移步 [CHANGELOG_HISTORY.md](./CHANGELOG_HISTORY.md)。

---

## v1.5.16 — 2026-07-29

### 优化
- **UI / UX / 辅助功能**：快捷键录制、HackerDesktop 待办勾选与 Activity Monitor 进程选择改为原生按钮，补齐键盘操作和 VoiceOver 名称；全局快捷键点击区域随窗口缩放一致变化。
- **动画一致性**：快捷键录制脉冲统一使用全局动画速度，并继续遵循即时模式与系统“减少动态效果”。
- **SFX 并发播放**：Chaos 同名短音效使用最多 4 个可复用通道，真正支持有限重叠；普通反馈仍保持互斥，避免无限创建播放器。
- **官方 Widget 性能**：一次时间线请求复用同一个共享存储读取器，减少重复的 App Group entitlement 与容器检查。

### 修复
- **Clipo 导入安全**：导入与本地恢复按实时捕获相同的 10 MB 单表示、20 MB 单载荷预算校验；读取后再次确认 300 MB 归档上限，拒绝异常图片/二进制载荷并规范化快捷槽编号。
- **Clipo 统计准确性**：今日统计按 `lastUsedAt` 计算，当天再次使用已有历史项后会正确计入。
- **风扇名称识别**：补充来源即使没有实时 RPM，也能用具体硬件名称替换 `Detected` / `Fan N` 通用名称。
- **温度刷新稳定性**：传感器 SwiftUI identity 固定为硬件 key，所有后备来源完成后统一去重，避免每 0.5 秒重建整行、趋势闪动及重复 key 字典崩溃。
- **启动音效清理**：取消或结束 Chaos 动画时使已排队的 burst 失效，并停止残留并发通道。
- **质量回归**：补充 Clipo 预算、风扇名称/传感器 identity、音效通道与本地化测试，并完成主应用、Helper、Debug / Release、Analyze、字符串目录和 plist 校验。
- 版本号更新为 v1.5.16 (Build 41)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。
- `F0CR` / `F1CR` 的 `ui16` RPM 缩放缺少可靠硬件资料，本版本继续安全拒绝未知格式，不凭猜测生成读数。
