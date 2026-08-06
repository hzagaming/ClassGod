# ClassGod 历史版本记录

> 较早版本详见本文件；最新版本请查看 [CHANGELOG.md](./CHANGELOG.md)。

---

## v1.5.25 — 2026-08-05

### 优化
- **启动与主页路径**：ClassGod 品牌启动界面在即时动画或减少动态效果下仍至少展示 1 秒，随后始终进入主 Panel；Widget Center 只从主页入口打开。
- **官方 Widget Center**：入口名称、19 个 Widget kind、分类和刷新目标统一为单一目录，打开后默认进入官方 Widgets 合集，不再先显示数据录入页。
- **天气参数完整性**：支持城市、当前/体感/最高/最低温、湿度、九种天气状态、摄氏/华氏切换及更新时间；切换单位会同步换算全部温度。
- **Widget 数据效率**：ClassGod 常驻期间每 60 秒同步系统快照，配置变化只刷新对应 Widget kind，只有手动操作才刷新全部 19 个时间线。
- **Widget UI / UX**：Todo、Notes、Files、App Launcher、Terminal 与 ASCII Art 补齐清晰空状态，文本和列表按不同 Widget 尺寸限制渲染量，避免空白或溢出。

### 修复
- **天气固定占位覆盖**：移除每 5 秒强制写回 `24° / cloud.sun.fill` 的旧路径，天气配置现在会规范化后稳定保存并正确显示。
- **系统 Widget 长期陈旧**：系统指标不再依赖打开 Widget Center 才更新；关闭中心后降为低频宿主同步，避免数据停滞和持续高频采样。
- **待办编辑丢失**：输入待办文字会触发防抖保存，关闭窗口不再丢失只编辑未勾选的任务。
- **重复标识与损坏载荷**：待办、文件、应用和终端日志在进入 SwiftUI 前处理重复 ID、空项、超长文本、无穷数及分量大于总量等异常。
- **终端空状态回填**：用户主动清空日志后保持为空，不再在下次打开时误恢复示例日志；重复日志使用稳定序号渲染，不再产生 `ForEach` 标识冲突。
- **分类与刷新偏差**：System Info 统一归入 System，并与实际系统快照刷新集合保持一致。
- **质量回归**：新增启动呈现、宿主刷新、天气换算/边界、Widget 目录和载荷归一化测试，完成主应用 117 项、Helper 17 项、Debug / Release、Analyze、字符串目录、plist、产物内容与签名校验。
- 版本号更新为 v1.5.25 (Build 50)

### 说明
- 天气数据继续由用户在 Widget Center 手动维护，本版本未接入或虚构 WeatherKit 实时数据。
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；跨进程同步仍需配置 `group.com.hanazar.classgod`。
- 本版本已复查主面板、风扇识别、Clipo、短音效通道与视频/GIF 壁纸 BGM 生命周期；不改变硬件安全降级、Clipo 归档、SFX 音色和壁纸播放规则。

---

## v1.5.24 — 2026-08-05

### 优化
- **主面板信息完整性**：功能卡片说明支持两行显示，Clipo 等较长描述在默认窗口宽度下不再被省略号截断。
- **浏览器切换准确性**：Host-only 模式改为按 URL authority 边界匹配，跨 Safari、Chrome 与 Edge 不再把相似域名或查询参数中的目标域名误认成现有标签。
- **快捷键录制 UX**：录制器只接受 Carbon 能实际注册的字母、数字、符号与 F1–F12 组合，并剔除 Caps Lock、Fn、数字键盘等无效修饰状态。
- **壁纸导入反馈**：批量导入会统计部分/全部失败并显示本地化提示；用户主动取消原生选择器时保持安静，不再输出误导性失败日志。
- **错误百科交互**：纯空格查询恢复为默认列表；错误 Toast 会等待知识库首次加载完成后再关联百科条目。
- **SuperSwitch SFX / 触感**：成功音效与成功触感只在应用真实激活或启动后播放，失败路径统一使用失败反馈。

### 修复
- **浏览器检测分隔错误**：活动标签标题自身含记录分隔符时改为从最后边界拆分，不再把标题片段当成 URL；空 URL 响应会安全拒绝。
- **AppleScript 字面量错误**：URL 中的反斜杠与引号按 AppleScript 语法正确转义，避免脚本创建失败或字符串被截断。
- **Host-only 误切标签**：修复 `notexample.com` 与 `evil.test/?next=example.com` 被错误匹配为 `example.com` 的问题，并支持路径、查询、片段和端口边界。
- **无效快捷键状态**：无受支持修饰键的非功能键、未知键码及仅带 Caps Lock/Fn 的组合不再被录制为看似有效但无法注册的快捷键。
- **电池百分比异常**：系统返回最大容量为 0、负容量或超范围容量时统一输出有限的 0–100% 值，Activity Monitor 与 Widget 不再出现无穷数。
- **SuperSwitch 假成功反馈**：应用激活失败、启动回调无应用实例或应用不存在时不再先播放成功音效。
- **启动序列过期回调**：启动视图消失后所有延迟阶段失效，计时器立即释放，旧序列不会再次执行完成回调；重新显示会从干净状态启动。
- **错误百科首次关联丢失**：Toast 不再在后台线程抢先搜索尚未加载的索引，避免首次错误永远缺少百科入口。
- **质量回归**：新增浏览器解析/Host 边界、AppleScript 转义、快捷键捕获、电池归一化、壁纸导入、应用切换、启动代际与知识库等待测试，并完成主应用 112 项、Helper 17 项、Debug / Release、Analyze、字符串目录和 plist 校验。
- 版本号更新为 v1.5.24 (Build 49)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。
- 本版本已复查风扇识别、Clipo 持久化、官方 Widget 数值边界、短音效通道与视频/GIF 壁纸 BGM 生命周期；不改变 Clipo 归档格式、SFX 音色和壁纸播放规则。无法获得可信 RPM 的 Apple Silicon 仍按只读/估算路径安全降级。

---

## v1.5.23 — 2026-08-02

### 优化
- **Permission Center 全量引导**：20 项权限全部进入逐项设置流程，新增搜索、类别/状态筛选、核心/建议/可选级别、五态授权反馈与完整统计。
- **权限交互一致性**：原生申请、重新检查与打开系统设置统一走同一动作策略；异步权限在系统回调完成后即时刷新，请求期间显示等待态并阻止重复触发。
- **窗口 UIUX / SFX**：全部功能窗口统一使用目标可见性与过渡代际，快速开关可立即反向，重复动作不会叠加开关音效。

### 修复
- **首次权限申请失效**：Accessibility、输入监控和屏幕录制的布尔预检不再把首次 `false` 误判为确定拒绝，按钮会先执行系统原生申请。
- **权限重复请求竞态**：同一权限的快速双击会合并为单次请求；Location、Bluetooth、EventKit 与其他异步权限完成后安全释放等待态。
- **通知设置入口**：通知权限改为打开 ClassGod 对应的应用级系统通知页面，不再使用无效的 Privacy 锚点。
- **风扇通知越权弹窗**：风扇页面不再自行申请通知权限，只在 Permission Center 已授权且达到阈值时投递，并合并重叠的状态检查。
- **窗口关闭回调竞态**：旧淡出动画完成回调不再把刚重新打开的主窗口、Clipo、风扇、权限中心或其他功能窗口再次隐藏。
- **启动隐藏窗口误判**：关闭“启动时显示主面板”后，Chaos 动画结束会真正隐藏主窗口，第一次菜单栏点击即可正常显示。
- **风扇通知实时性**：通知授权查询返回时重新核验当前温度与阈值，降温、调整阈值或关闭通知后不会按旧采样误报。
- **多屏壁纸窗口泄漏**：桌面播放器改用稳定 Display ID 复用与清理，屏幕配置刷新不再为同一显示器叠加窗口或 BGM。
- **Clipo 去重准确性**：指纹加入载荷层级和长度边界，结构不同但拼接字节相同的剪贴板表示不再被误判为重复。
- **Widget 异常快照**：写入和时间线读取同时过滤负数、`NaN` 与无穷值，避免损坏指标在百分比或整数渲染时崩溃。
- **质量回归**：新增权限动作/请求互斥、通知投递、窗口过渡和启动呈现策略测试，并完成主应用 102 项、Helper 17 项、Debug / Release、Analyze、字符串目录和 plist 校验。
- 版本号更新为 v1.5.23 (Build 48)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。
- 本版本已复查风扇识别、Clipo、官方 Widget、短音效通道与视频/GIF 壁纸 BGM 生命周期；不改变现有硬件识别、Clipo 归档格式、SFX 音色和壁纸播放规则。无法获得可信 RPM 的 Apple Silicon 仍按只读/估算路径安全降级。

---

## v1.5.22 — 2026-08-02

### 优化
- **AppleScript 响应性**：AssessPrep 周期检测、焦点守护及 BrowserBypasser 扫描/注入移到后台执行，UI 不再被重复脚本阻塞。
- **多屏壁纸协调**：多显示器视频壁纸指定唯一播放协调屏，其余屏幕只负责画面同步，不再重复输出音频或推进播放列表。
- **等待态反馈**：BrowserBypasser 扫描和权限引导等待期间显示禁用状态，避免按钮看似可重复触发。

### 修复
- **多屏 BGM 重叠与跳项**：修复每块屏幕同时播放视频音轨，以及多个播放器结束事件导致列表一次跳过多张壁纸的问题。
- **Clipo 选择捕获竞态**：连续保存不同快捷槽时只保留最新任务，旧任务不再争用或恢复全局剪贴板。
- **浏览器延迟切换竞态**：快速点击多个标签时取消旧延迟请求，并抑制已过期 AppleScript 回调与 Toast，不再连续切屏。
- **绕过工具生命周期**：重复启用焦点守护不会遗留失去引用的 Timer；停止或关闭后旧后台脚本结果不会回写，扫描失败会清除旧检测横幅。
- **AssessPrep 英文本地化**：修正标题、空状态、操作、技术说明、Toast 和错误提示在英文环境仍显示中文的问题。
- **质量回归**：新增 Clipo 捕获所有权、延迟切换、异步结果代际及多屏音频/循环策略测试，并完成主应用 92 项、Helper 17 项、Debug / Release、Analyze、字符串目录和 plist 校验。
- 版本号更新为 v1.5.22 (Build 47)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。
- 本版本已复查风扇识别、SystemMonitor、官方 Widget、短音效通道与 GIF 生命周期；除多屏视频 BGM 协调外不改变现有硬件识别、SFX 音色和数据格式。无法获得可信 RPM 的 Apple Silicon 仍按只读/估算路径安全降级。

---

## v1.5.21 — 2026-08-01

### 优化
- **系统监控刷新协调**：Activity Monitor、风扇面板与 HackerDesktop 分别登记刷新需求，始终采用活跃窗口所需的最快频率，窗口关闭后自动恢复剩余频率。
- **监控数据准确性**：网络和进程速率按真实采样间隔归一化；进程扫描禁止重叠，避免高负载下的乱序刷新。
- **交互生命周期**：权限引导和快捷键冲突提示的延迟任务均可取消，快速返回、跳过、关闭或重复操作不会再触发过期回调。

### 修复
- **动态隐藏选择安全**：DestinTab 在搜索、排序、置顶或显示上限变化后，只统计并删除点击瞬间仍可见的已选标签，不再误删隐藏项。
- **多窗口刷新冲突**：修复较慢窗口覆盖较快监控频率，以及最快窗口关闭后没有恢复剩余客户端频率的问题。
- **网络首帧峰值**：首次采样不再把系统累计流量当作瞬时速度，2 秒等非默认刷新频率下也不会高估速率；计数器回绕安全归零。
- **进程采样竞态**：停止监控后拒绝旧扫描结果回写，最后一个客户端退出时重置 CPU、网络和进程采样基线。
- **权限引导竞态**：等待权限刷新期间阻止重复继续，并在返回、跳过、完成或关闭时取消待执行步骤，避免重复跳步。
- **通知本地化**：高温系统通知补齐简体中文和英文标题、正文，不再固定显示英文。
- **质量回归**：新增可见选择、多客户端间隔、单调计数器、权限步骤与通知本地化测试，并完成主应用 89 项、Helper 17 项、Debug / Release、Analyze、字符串目录和 plist 校验。
- 版本号更新为 v1.5.21 (Build 46)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。
- 本版本已复查风扇识别、Clipo、SFX 音色/通道与视频/GIF 壁纸 BGM 生命周期，未改变现有安全规则；无法获得可信 RPM 的 Apple Silicon 仍按只读/估算路径安全降级。

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

---

## v1.5.17 — 2026-07-30

### 优化
- **壁纸库交互与辅助功能**：壁纸选择和删除拆分为独立原生按钮，避免嵌套按钮误触；关闭、删除按钮补齐 VoiceOver 名称。
- **错误 Toast 体验**：关闭任意 Toast 后剩余窗口平滑补位，新 Toast 不再与旧窗口重叠；百科入口与批量选择数量补齐简中/英文文案。

### 修复
- **Clipo 延迟粘贴竞态**：连续快速粘贴只执行最新请求并保留操作前的原始剪贴板快照；等待期间内容被用户或其他 Clipo 操作修改时取消旧回调，避免误贴、错误恢复或重复发送 `⌘V`。
- **视频壁纸 BGM 生命周期**：异步视频加载加入请求代际校验，同一路径快速移除再载入时拒绝旧结果，避免重复播放器、残留观察者与幽灵循环/音频回调。
- **错误百科本地化**：修复旧百科入口翻译未进入简体中文产物的问题，并移除废弃英文 Toast 字符串。
- **质量回归**：新增 Clipo 请求所有权、视频加载代际、Toast 布局与本地化测试，并完成主应用、Helper、Debug / Release、Analyze、字符串目录和 plist 校验。
- 版本号更新为 v1.5.17 (Build 42)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。
- 本版本未改变风扇硬件识别规则；无法获得可信 RPM 的 Apple Silicon 仍按现有只读/估算路径安全降级。

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

---

## v1.5.15 — 2026-07-29

### 优化
- **Clipo 响应与持久化**：历史、槽位和设置写入改为短延迟合并，退出时强制保存最新快照，减少连续复制与编辑时的磁盘写入。
- **前台目标跟踪**：Clipo 独立监听应用激活事件，即使关闭剪贴板监控，也能可靠回到最后一个外部应用执行粘贴。
- **UI / UX / 辅助功能**：全部功能窗口、错误 Toast、最大化和启动页统一遵循动画速度、即时模式及系统“减少动态效果”；Clipo、HackerDesktop 和风扇页面补齐关键 VoiceOver 名称。
- **SFX / BGM**：Clipo 粘贴不再让关闭音与成功音互相截断；壁纸视频音量统一限制为有限的 0–100% 范围，避免异常持久化值传入播放器。

### 修复
- **Clipo 数据兼容**：按 UTF-16 正确解析对应剪贴板文本；敏感应用列表去除空项、空白与大小写重复，并限制异常超长 Bundle ID。
- **Clipo 剪贴板竞态**：粘贴和保存选区后的延迟恢复仅在剪贴板未被用户再次修改时执行，不再覆盖用户刚复制的新内容。
- **风扇识别稳定性**：Direct SMC 的 `FNum` 仅按 `ui8` / `ui16` / `ui32` 大端格式解析；重复风扇记录逐字段补齐实时 RPM 与有效范围，Helper 遇到重复 SMC key 不再崩溃。
- **官方 Widget 时间线**：Uptime Widget 会根据每个时间线条目推进运行时长；应用启动深链拒绝空段、尾点和超长 Bundle ID，并修正 CPU 核心数本地化。
- **启动与转场**：即时动画或“减少动态效果”会跳过 Splash 等待、Chaos 多窗口及爆发音效；取消启动动画后，延迟回调不会重新显示窗口或播放残留音效。
- **质量回归**：补充 Clipo、风扇、动画、Widget、壁纸音频与本地化回归测试，并完成 Debug / Release、Helper、Analyze、字符串目录和 plist 校验。
- 版本号更新为 v1.5.15 (Build 40)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。
- `F0CR` / `F1CR` 的 `ui16` RPM 缩放缺少可靠硬件资料，本版本继续安全拒绝未知格式，不凭猜测生成读数。

---

## v1.5.14 — 2026-07-28

### 新增
- **Clipo 剪贴板中心**：新增历史、搜索/类型筛选、置顶、9 个快捷槽、统计、敏感应用过滤、导入导出与全局快捷键，并统一为 ClassGod 客户端视觉风格。
- **19 个官方 WidgetKit 小组件**：系统监控、时钟/日历、天气、待办、便签、文件、应用启动器及 Hacker 工具全部迁移为 macOS 官方 Widget；移除旧桌面悬浮窗口实现。
- **文件与应用启动器配置**：HackerDesktop 可直接选择文件和应用；应用 Widget 通过校验后的 `classgod://launch` 深链安全启动目标应用。

### 优化
- **风扇与温度识别**：Helper、Direct SMC、IORegistry 与 HID 按字段补全硬件数据；RPM/温度仅按明确格式解码，风扇数量支持 `ui8` / `ui16` / `ui32`，并支持部分温度来源补齐和重复风扇 ID 安全合并，避免错误单位与假读数。
- **Widget 时间线与本地化**：未来 15 分钟按分钟生成时间线，时钟不再冻结；日历遵循地区首日与本地化星期顺序，扩展补齐独立简中/英文资源。
- **UI / UX / SFX / BGM**：整理窗口转场音效的互斥播放，补齐壁纸音频启停、音量、播放模式与 VoiceOver 状态；非视频壁纸会正确禁用音频控制。
- **数据与权限体验**：Clipo 单项、单次载荷、历史总量与导入文件均设安全上限；清空、重置和覆盖导入增加确认，辅助功能状态在应用重新激活时刷新。

### 修复
- **Clipo 重启崩溃**：修复已保存设置后再次启动会在设置归一化中无限递归、最终栈溢出的严重问题，并补充幂等回归测试。
- **Clipo 来源与持久化**：快速呼出时保留最后一个外部应用为来源，敏感 Bundle ID 改为大小写不敏感；退出前等待保存队列完成，并取消残留选区任务。
- **Widget 数据正确性**：修复电池 0–1 比例未转换为百分比、放电状态误判为充电、时间线使用过期更新时间，以及日历重复星期 ID 造成的渲染不稳定。
- **菜单栏交互**：点击状态项本身不再被“点击窗口外关闭”监听误判。
- **质量回归**：主应用测试、Helper 测试、Debug / Release 构建、Xcode Analyze、字符串目录与 plist 校验全部纳入发布检查。
- 版本号更新为 v1.5.14 (Build 39)

### 说明
- 未带有效 App Group provisioning 的本地签名构建会让主应用与 Widget 分别使用隔离的标准存储，并在 HackerDesktop 显示明确警告；启用跨进程同步仍需为主应用与 Widget 配置 `group.com.hanazar.classgod`。

---

## v1.5.13 — 2026-07-26

### 优化
- **壁纸播放性能**：GIF 暂停时停止帧计时器，恢复播放时继续动画，并限制异常超短帧延迟，降低无意义的计时器开销。
- **声音反馈一致性**：顶层功能窗口打开、返回与关闭仅播放对应的转场音效，避免与通用点击音效叠播。
- **辅助功能与文案**：壁纸桌面/电源开关补齐 VoiceOver 名称；壁纸与标签页导入导出使用各自的上下文文案，并修正英文返回按钮。

### 修复
- **壁纸文件删除边界**：受管文件改为按标准化父目录精确判断，避免相似路径前缀被误认为壁纸目录。
- **GIF 播放状态**：GIF 现在跟随壁纸总开关和暂停状态，不再在暂停或关闭后继续后台刷新。
- **自动化覆盖**：新增 GIF 状态/帧延迟、受管目录边界和本地化回归测试。
- 版本号更新为 v1.5.13 (Build 38)

---

## v1.5.12 — 2026-07-26

### 优化
- **主菜单辅助功能**：功能入口、风扇入口和关闭按钮补齐 VoiceOver 名称，屏幕阅读器不再只播报“button”。
- **快捷键录制体验**：通用与全局快捷键录制均支持 Esc 取消，清除快捷键时同步退出录制并释放事件监听。
- **错误提示交互**：错误详情入口与关闭按钮拆分为独立点击区域，避免嵌套按钮造成误触。

### 修复
- **视频壁纸音频状态**：视频结束时先检查启用与播放状态；暂停或关闭后不再自动恢复声音，列表/随机模式也不再短暂重播旧视频。
- **错误 Toast 异步补全**：知识库结果按原 Toast ID 回填并保留 identity，多条错误并发出现时不再串条或显示不同步。
- **壁纸删除本地化**：补齐删除确认消息的简中/英文文案，不再显示 `wallpaper.delete_message` 内部键名。
- **自动化覆盖**：新增错误 Toast identity、壁纸循环策略与删除确认本地化测试。
- 版本号更新为 v1.5.12 (Build 37)

---

## v1.5.11 — 2026-07-23

### 新增
- **Permission Center 权限目录扩充**：从 12 项扩展为 20 项，补齐输入监控、文件与文件夹、开发者工具、应用管理、照片、媒体与 Apple Music、语音识别、本地网络，并按功能分类展示。
- **自动化测试覆盖**：主 App 新增 12 项测试，Helper 扩展为 6 项测试，覆盖刷新迁移、权限目录、Apple Events 状态、设置链接、壁纸播放状态、SMC 风扇键、数据源合并及采样策略。

### 优化
- **0.5 秒实时硬件刷新**：风扇面板、主菜单摘要、菜单栏与 HackerDesktop 风扇 Widget 统一使用 0.5 秒默认/最小刷新间隔；旧偏好一次迁移到新默认值。
- **SMC / Helper 硬件识别**：缓存动态 SMC 枚举，按数据类型解析温度，支持十六进制风扇索引，并让 App 与 Helper 重扫同步清除硬件缓存。
- **多数据源按字段合并**：Helper 分别补齐缺失的风扇与温度，不再因 SMC 只返回其中一类就错过 `powermetrics` / HID 后备数据。
- **按需采样策略**：仅在风扇或温度缺少独立来源时持续运行 `powermetrics`；有独立温度来源且确认无备用风扇数据时自动停止，降低无风扇机型开销。
- **Permission Center 本地化**：权限中心、风扇面板、Widget 与硬件诊断文案补齐 zh-Hans / en，修复英文环境仍显示中文以及中文环境显示硬编码英文的问题。
- **交互与辅助功能**：设置控件补齐 VoiceOver 标签，禁用入口不再响应交互，提高次要文字对比度，并统一尊重系统“减少动态效果”。

### 修复
- **实时刷新任务堆积**：所有 0.5 秒硬件 UI 入口增加在途门闩，慢读取时合并重叠 tick，避免后台任务持续排队。
- **风扇模式恢复时序**：首次硬件探测完成后才恢复保存模式；重新打开面板会从偏好重新载入模式。
- **Boost 关闭安全**：Boost 期间关闭风扇窗口后保持系统控制，不再先释放风扇又错误恢复旧模式。
- **硬件重扫主线程阻塞**：SMC / Helper 重扫移到后台执行，完成后刷新状态、定时器与控制规则。
- **Apple Events 被动检查**：Permission Center 使用 `AEDeterminePermissionToAutomateTarget(..., askUserIfNeeded: false)`，被动刷新不再执行 AppleScript 或触发 Automation 弹窗。
- **权限窗口状态陈旧**：Permission Center 每次重新显示都会刷新；重复刷新会合并，系统设置 URL 改为安全构造。
- **首次权限引导跳项与过度请求**：引导列表在打开时固定，只包含 Accessibility / Automation 两项核心切屏权限；已授权项目的重新检查不再调用请求 API。
- **Wallpaper 播放模式未保存**：视频壁纸播放模式切换现在会持久化，音量、静音与播放状态同步路径保持一致。
- **Wallpaper 动画与音频状态**：修复相同帧数 GIF 切换后仍显示旧内容、壁纸视图关闭后计时器/播放器未立即停止，以及暂停状态重启后丢失。
- **SFX 线程安全**：所有 `NSSound` 创建、缓存与播放回到 AppKit 主线程，避免后台线程竞争和偶发播放异常。
- **版本显示回退过时**：移除 Splash、主菜单和 About 中的旧版本硬编码回退。
- **Widget 构建警告**：移除非可选 `hostName` 后无效的空值合并。
- **Helper 稳定性**：HID 传感器 Product 属性改为安全类型转换，避免异常 IORegistry 数据触发崩溃。
- 版本号更新为 v1.5.11 (Build 36)

---

## v1.5.10 — 2026-07-22

### 修复
- **AppKit / SwiftUI 窗口生命周期**：为主菜单、HackerDesktop、Activity Monitor、AssessPrepHack 增加明确的显示/隐藏生命周期信号，窗口 `orderOut` 后会停止后台定时器、系统监控和应急检测，再次显示时按需恢复。
- **Activity Monitor 监控引用泄漏**：`ActivityMonitorViewModel` 增加幂等启动/停止保护，停止时正确调用 `SystemMonitor.stop()`，避免反复打开面板后 `SystemMonitor` / `nettop` 常驻。
- **桌面小组件锁定状态同步**：切换桌面标签锁定状态后立即刷新窗口内容，锁图标与实际拖拽状态保持一致。
- **布局重置防误触**：桌面小组件重置遵循全局“清空前确认”设置；确认后才播放重置音效和警告触感。
- **文件选择取消反馈**：Finder 文件选择器的用户取消不再被当作导入失败，不播放失败 SFX 或警告触感。
- **系统音效兼容性**：移除未文档化的硬编码 Sound ID，改为在内存中合成并缓存短 PCM/WAV 音色，避免新系统上的 `-50` 音频错误和系统音效文件路径依赖。
- **状态栏唤起窗口**：显示主面板前显式激活菜单栏应用，避免普通窗口层级的面板被当前应用遮挡。
- **启动动画资源峰值**：Chaos 动画窗口数量限制在 12–48，并自动迁移旧的高数值，避免默认 200 个 `NSWindow` 触发 AppKit 超额活动窗口告警与布局卡顿。
- **隐藏占位窗口**：应用 Scene 改用无主窗口的 `Settings` 场景，不再创建 `0×1` 的 SwiftUI 占位窗口或产生无效窗口恢复记录。
- **应用图标签名安全**：图标伪装只更新运行时应用图标，不再通过 `NSWorkspace.setIcon` 改写 `.app` bundle，避免修改已签名的应用内容。
- **Swift 6 迁移安全**：清理 SMC 后台读取、进程快照、壁纸屏幕事件、错误搜索等并发警告，并移除 `Optional` 的全局追溯协议扩展。
- **窗口缩放越界**：所有功能窗口尺寸限制到当前屏幕可见区域，缩放变化后重新夹紧位置，避免 200% 缩放时关闭按钮跑到屏幕外。
- **Widget 英文本地化**：补齐 19 个 `widget.*` 类型名称的英文回退，并新增布局重置确认文案。
- **语义键名回退**：为英文资源中 318 个缺失的点分语义键补上源文案回退，主菜单与 Widget 重要文案完成正式英译，避免英文 macOS 直接显示 `menu.*` / `button.*` 内部键名。
- **简体中文资源补全**：复用并转换现有繁中译文，补齐 175 个仅有英文/繁中的语义键，避免简中 macOS 显示内部键名。
- **质量检查**：完整 Debug / Release build、Xcode Analyze、Helper 测试、本地化 JSON 校验和代码差异检查通过。
- 版本号更新为 v1.5.10 (Build 35)

---

## v1.5.9 — 2026-07-16

### 修复
- **HackerDesktop 配置中心本地化补齐**：标题、字段占位符、About 区域和可用小组件说明改为 `hackerdesktop.*` 字符串键，避免中文界面露出英文硬编码。
- **桌面小组件 SFX 语义修正**：添加小组件、打开文件选择器、重置布局、切换编辑模式、编辑栏删除和拖拽开始改用对应 widget/layout/drag 音效，不再混用普通按钮音。
- **桌面小组件动画设置补漏**：CPU / 内存小组件数值动画现在遵循全局 `Anim.enabled` / `Anim.duration`，极速模式下不再残留写死动画。
- **Finder 文件小组件选择体验修复**：文件导入允许选择通用 Finder 项目，文件小组件不再被 `.data` 类型过度限制。
- 版本号更新为 v1.5.9 (Build 34)

---

## v1.5.8 — 2026-07-14

### 修复
- **HackerDesktop 保存防抖**：Widget 配置中心的文本输入不再每个字符都立刻刷新 WidgetKit timeline，改为短延迟合并保存，关闭窗口时仍会强制落盘，减少卡顿和无谓刷新。
- **桌面小组件编辑器本地化**：`DesktopWidgetEditor` 的启用说明、编辑布局、重置、空状态、添加小组件/桌面标签、数量标题等用户可见文案接入 `Localizable.xcstrings`。
- **桌面小组件编辑器 SFX/触感补齐**：启用开关、编辑模式、重置、添加、文件导入成功/失败补齐一致的音效和触感反馈。
- **缩放细节修复**：桌面小组件编辑器的部分描边线宽和空状态垂直间距补齐 `zoomScale`，避免窗口缩放后局部视觉重量不一致。
- 版本号更新为 v1.5.8 (Build 33)

---

## v1.5.7 — 2026-07-14

### 修复
- **设置 Slider 音效节流**：`SettingsSliderRow` 拖动时不再对每一次数值变化连续播放按钮音效和触感，避免设置页 SFX 变成高频噪声。
- **Wallpaper 动画速度补漏**：`WallpaperPlayerView` 的壁纸切换淡入/淡出、Quick Access Bar hover 显隐改为读取 `Anim.enabled` / `Anim.duration`，极速模式下不再残留写死动画。
- **HackerDesktop Widget 状态提示**：同步说明改为准确描述 WidgetKit App Group 要求与本地回退存储，并在系统监控区显示当前使用的是共享 App Group 还是本地回退存储。
- **本地化补齐**：新增 `hackerdesktop.shared_active` / `hackerdesktop.local_fallback` 状态文案，并更新 `hackerdesktop.sync_notice` 的 zh-Hans / en 文案。
- 版本号更新为 v1.5.7 (Build 32)

---

## v1.5.6 — 2026-07-13

### 修复
- **设置页缩放一致性**：`CollapsibleSection`、`SettingsToggleRow`、`SettingsSliderRow`、`SettingsPickerRow`、`SettingsActionRow`、`SectionResetButton` 现在完整跟随 `windowZoomScale`，不再只有外框缩放而字体、间距、图标尺寸保持原大小。
- **动画速度设置补漏**：设置页折叠/hover 动画与主菜单功能按钮按压动画统一改为读取 `Anim.enabled` / `Anim.duration`，极速模式下不再残留写死动画时长。
- **设置交互反馈补齐**：折叠设置分组时补齐触感反馈；重置按钮文案改用既有 `button.reset` 本地化键。
- **Widget 本地构建回退**：`WidgetDataStore` / `WidgetExtensionStore` 在 App Group 容器不可用时回退到 `UserDefaults.standard`，避免未签名本地构建下 HackerDesktop / Widget 数据读写静默失效。
- **HackerDesktop 同步提示修正**：同步说明不再无条件声称 App Group 一定可用，新增 `hackerdesktop.sync_notice` 本地化文案说明共享容器与本地回退行为。
- 版本号更新为 v1.5.6 (Build 31)

---

## v1.5.5 — 2026-07-07

### 修复
- **删除类操作的音效/触感时序**：`BrowserBypasser`、`AssessPrepHack`、`SuperSwitch` 的删除确认弹窗此前会在打开确认框时就播放"已删除"音效与警告触感，取消也不例外；现在改为只在用户实际点击确认删除时才触发，打开确认框仅播放普通点击音效。
- **桌面小组件音效补齐**：桌面悬浮小组件的关闭（`xmark`）与锁定切换按钮、组件编辑器里的垃圾桶删除按钮此前完全没有音效/触感反馈；接入了此前已定义但从未被调用的 `playWidgetDeleted()` / `playWidgetLocked()`。
- **进程管理器 Quit/Force Quit 反馈**：`ActivityMonitorView` 终止进程的右键菜单操作此前没有任何反馈；现在按终止结果播放成功/失败音效并触发警告触感。
- **AssessPrep 新增面板反馈缺失**：`AddPanicAppView` 的关闭按钮和保存操作此前没有音效反馈，和同类 Add/Edit 面板不一致，现已补齐。
- **动画速度设置未生效的例外**：`FanControlView`（Toast、温度告警高亮）、`WallpaperBrowserView`（悬停/按压反馈）、`BrowserBypasserView` / `SuperSwitchView`（行按压反馈）中若干处使用了写死的动画时长，忽略了用户的"动画速度"/"极速模式"设置；统一改为读取 `Anim.enabled` / `Anim.duration`。
- **SuperSwitch 面板本地化缺失**：`SuperSwitchView` 是唯一完全未接入本地化字符串目录的功能面板（标题、空状态、添加/编辑目标表单等均为英文硬编码字符串），现已补充 `superswitch.*` / `field.bundle_identifier` / `field.icon` 等键值（含 zh-Hans 源文案与 en 翻译），并复用既有的 `button.cancel` / `button.delete` / `button.edit` / `button.add` / `button.save` / `field.name` 键。
- **DestinTab / BrowserBypasser 副标题与提示未本地化**：这两个面板的副标题及 DestinTab 的"重复 URL"tooltip 此前是被 Xcode 自动提取但无任何翻译的英文字面量，中文用户也会看到英文；现改用 `destintab.subtitle` / `bypass.subtitle` / `destintab.duplicate_url(s_detected)` 正式键并补齐 zh-Hans / en 文案。
- **圆角缩放遗漏**：`BrowserBypasserView`、`AssessPrepHackView`、`AddPanicAppView` 中各一处 `.cornerRadius(4)` 未乘以 `zoomScale`，与同一窗口内其他圆角不一致，现已修正。
- **SMC 温度读取稳定性**：Apple Silicon HID 温度传感器读取时移除对 `Product` 字段的强制类型转换，避免异常传感器属性导致进程崩溃。
- **HackerDesktop Widget 配置保存**：Clock / Weather / Crypto / Quote / Terminal Logs 编辑后立即保存并刷新 Widget 数据，修复改完马上关闭窗口可能丢失配置的问题；同时移除重复写入 `weatherCity`。
- **源码版本号同步**：补齐 `ClassGod/Info.plist` 的 v1.5.5 (Build 30)，避免源码 plist 与 Xcode build settings / 公告不一致。
- 版本号更新为 v1.5.5 (Build 30)

---

## v1.5.4 — 2026-07-01

### 修复
- **版本与 Bundle ID 统一**：修正 Xcode build settings 与源码公告不一致的问题，实际构建产物更新为 v1.5.4 (Build 29)，Bundle ID 统一为 `com.hanazar.classgod`。
- **Widget Extension 集成修复**：
  - 修复 `ClassGod` 主 target 未依赖 / 未嵌入 `ClassGodWidget.appex` 的问题。
  - 修复 Widget target 未使用 `ClassGodWidget.entitlements`、未启用 Sandbox 的问题。
  - 保留 `WidgetDataStore` 的 `group.com.hanazar.classgod` 共享容器入口；App Group capability 需要开发证书/Team 签名，本地 `Sign to Run Locally` 构建不强制启用，避免标准 build 失败。
- **退出清理与后台任务**：退出应用时补齐 Activity Monitor / Permission Center 窗口清理，取消状态栏 SMC 刷新任务，并断开 `SMCHelperClient` socket。
- **Helper 测试接入**：为 `ClassGodHelper` Swift Package 接入测试 target，修复 `swift test` 报 `no tests found` 的问题。
- **UI/UX/SFX 细节修复**：
  - 修复主菜单功能说明、设置标题、AssessPrep 面板按钮 / 空状态 / 帮助文本的本地化遗漏。
  - 修复设置窗口标题栏未随 `windowZoomScale` 缩放的问题。
  - 为主菜单入口、设置、退出、风扇摘要打开、AssessPrep 行操作补齐触感反馈。
- 版本号更新为 v1.5.4 (Build 29)

---

## v1.5.3 — 2026-06-13

### 修复
- **Localizable.xcstrings 损坏**：修复 `setting.keyboard_nav.subtitle` 被错误嵌套到 `About` 键下导致的 Xcode 编译失败，新增并校验 376 条缺失的 zh-Hans 本地化键值。
- **UI/UX/SFX/BGM 修复与缩放一致性**：
  - 修复 `PermissionCenterService`、`PermissionCenterView`、多个 Model 的 `displayName`、ViewModel 的 toast/error 文案的本地化为中文。
  - 为 `DestinTabView`、`BrowserBypasserView`、`SuperSwitchView`、`AssessPrepHackView`、`PermissionCenterView`、`ActivityMonitorView`、`ErrorHubView`、`HackerDesktopView`、`FanControlView` 等补充音效与触感反馈。
  - 修复 `WindowZoomControlBar`、`ShortcutPicker`、`SettingsSliderRow` 等组件未按 `windowZoomScale` / `zoomScale` 缩放的问题。
  - 修复 `safeLinkButton`、`SectionHeader`、`browserRow`、`categoryButton` 等复用组件的 `LocalizedStringKey` 参数类型，使 SwiftUI 字面量自动参与本地化。
- 版本号更新为 v1.5.3 (Build 28)

---

## v1.5.2 — 2026-06-13

### 新增
- **全面 UI/UX/SFX/BGM 修复与本地化补全**：
  - 为 MenuBar 功能按钮、设置页组件、权限中心、活动监视器、HackerDesktop、错误百科、风扇控制、应急应用、壁纸引擎等视图补充中文（zh-Hans）本地化键值
  - `FeatureButton`、`Settings*Row`、`CollapsibleSection`、`TabButton`、`ConfigSection`、`StatBadge`、`sortableHeader`、`summaryItem`、`DiagnosticRow`、`footerButton`、`browserRow` 等复用组件改为接受 `LocalizedStringKey`，调用处字面量自动参与本地化
  - 新增大量用户可见字符串键值：状态标签、诊断信息、按钮标题、提示文本、Alert 标题等

### 优化
- **交互反馈一致性提升**：
  - `AddTabView` 的浏览器 Picker 和置顶 Toggle 增加音效与触感反馈
  - `HackerDesktopView` 的 Tab 切换与待办完成操作增加音效与触感反馈
  - `AddPanicAppView` 的绕过技术选择增加音效与触感反馈
- **窗口圆角缩放一致性**：所有功能窗口（含设置、壁纸浏览器、HackerDesktop、错误中心）统一使用 `panelCornerRadius * windowZoomScale`
- **壁纸填充模式**：GIF 动态壁纸改为 `scaleAxesIndependently` 以填满桌面
- **错误中心主题色**：错误百科与详情页统一使用 `severity.colorHex` 主题色，移除硬编码 iOS 色调

### 修复
- **FanControl 状态与可用性**：
  - 无风扇时 Boost 按钮禁用并降低透明度
  - 模式按钮在无风扇时禁用
  - 修复风扇状态文本在 helper/回退场景下的显示逻辑
- **MenuBarView 风扇摘要定时器**：移除 `.onAppear` 与卡片 `onAppear` 中的重复注册，避免生命周期混乱
- 版本号更新为 v1.5.2 (Build 27)

---

## v1.5.1 — 2026-06-12

### 新增
- **主应用直接读取 Apple Silicon HID 温度传感器**：通过 `IOHIDEventSystemClient` 私有 API 读取 `AppleARMPMUTempSensor` / `AppleEmbeddedNVMeTemperatureSensor` 的实时温度事件，即使不启动特权 helper，风扇面板也能显示 `PMU tdie*`、`PMU tcal`、`NAND CH0 temp`、`gas gauge battery` 等真实温度
- **Helper `powermetrics` 后备数据源**：当传统 SMC keys 在 Apple Silicon M5 Pro 等设备上返回空数据时，特权 helper 会定期以 root 执行 `powermetrics --samplers smc`，解析 CPU/GPU/IO die 温度与风扇 RPM，并通过 socket 返回给主应用
- **Helper 自清理旧实例**：新 helper 启动时会自动 `SIGTERM` 其他 `ClassGodHelper` 进程，避免旧 helper 占用 socket 导致新 helper `bind() failed: 48`

### 优化
- **`SMCService` 独立 CPU 负载估计**：不再依赖 `SystemMonitor.shared.thermal`，而是在 `SMCService` 内部直接通过 `host_statistics` 读取 CPU 负载，结合 `ProcessInfo.thermalState` 生成动态的 `CPU Estimated` / `GPU Estimated`，即使 `SystemMonitor` 未启动也能显示

### 修复
- **移除 Start Helper 脚本中多余的嵌套 `sudo`**：脚本本身已通过 `with administrator privileges` 以 root 运行，内部再调 `sudo` 可能失败；改为直接 `killall ClassGodHelper; ClassGodHelper`
- 版本号更新为 v1.5.1 (Build 26)

---



## v1.4.2 — 2026-06-09

### 优化
- **Activity Monitor 真正实时化**：
  - 刷新间隔从 2.0s 缩短到 1.0s，过程列表更新更跟手
  - 新增 `NettopMonitor`，通过 `nettop -P -d -x -J bytes_in,bytes_out -L 0 -s 1` 采集真实的**逐进程网络收发字节**
  - `SystemMonitor` 直接消费 nettop 提供的每秒增量，取代原来按 CPU 比例估算网络流量的方案
  - Disk / Energy / Network 全部改为**速率化展示**（Read/Write MB/s、Recv/Sent KB/s、Energy W），避免累计值越滚越大
  - `ActivityMonitorViewModel` 的排序与默认 Tab 排序全部切换为速率字段
  - 底部摘要改为展示 Total Read/Write 速度和 Download/Upload 速度，并移除 "estimated by CPU share" 提示

### 修复
- 修复 `NettopMonitor` 解析逻辑：原实现把每一行都当作独立快照发射，导致前后样本无法对齐；新实现按 `time` 表头分组整屏样本，并跳过首屏累积总值
- 版本号更新为 v1.4.2 (Build 17)

---

## v1.4.1 — 2026-06-09

### 新增
- **ClassGodHelper 特权辅助工具**：
  - 独立的 Swift Package (`ClassGodHelper`)，作为 root 守护进程运行，通过 Unix domain socket 与主应用通信
  - 支持在 Apple Silicon 上绕过用户空间 SMC 限制，读取真实风扇 RPM、温度传感器
  - 支持 `setFanMode` / `setFanRPM` 写入风扇目标转速（System / Max / Manual / Auto Max / Custom）
  - 使用 `getpeereid` 对连接客户端进行 UID 校验（默认读取 `SUDO_UID`）
  - 自动嵌入到 `ClassGod.app/Contents/MacOS/ClassGodHelper`，通过 Xcode Run Script 阶段随主应用一起编译
- Fan Control 诊断面板新增 **Privileged Helper** 状态行：
  - 绿色：辅助工具已连接，完整 SMC 读写可用
  - 黄色：Apple Silicon 需要 root 辅助工具才能解锁风扇控制
  - 一键复制启动命令按钮：`sudo "/Applications/ClassGod.app/Contents/MacOS/ClassGodHelper"`

### 优化
- `SMCService` 优先通过 `SMCHelperClient` 访问 Helper；Helper 不可用时回退到原有直连 / IORegistry 兜底
- `SMCService.updateFanAccessReason()` 在 Helper 可用时显示正向提示

### 优化
- **Error Encyclopedia（报错知识库）性能与架构重写**：
  - 将 14,000+ 行 Swift 硬编码数据抽取为 `ErrorKnowledgeBase.json`（约 778 KB），作为 Bundle 资源随应用打包，显著减少编译时间和二进制体积
  - `ErrorKnowledgeBase` 改为异步延迟加载：首次打开 Error Hub 时才在后台线程解码 JSON 并构建索引，避免应用启动时阻塞主线程
  - 新增倒排索引（inverted index）实现 O(1) 量级的 token 查找，搜索结果按相关性排序，搜索耗时从 O(n×m) 降到接近 O(命中数)
  - 预计算分类/ID/标题字典，`entries(for:)`、`entry(withID:)`、`findRelated(to:)` 均为 O(1) 或 O(相关数)
  - `ErrorHubView` 增加 150 ms 搜索防抖（debounce）并将搜索任务放到后台线程，UI 不再因快速输入卡顿
  - Error Hub 增加加载/失败占位 UI，支持重试
  - `ErrorToastManager.show(error:)` 先立即弹出 Toast，再在后台查询知识库并自动补全关联条目，避免错误提示延迟

### 修复
- 修复 Wallpaper Engine 无法在桌面真正显示的问题：
  - `DesktopWallpaperWindow` 层级改为 `CGWindowLevelForKey(.desktopIconWindow) + 1`，确保渲染在 Finder 桌面窗口之上从而真正可见（macOS Sonoma+ 中 Finder 桌面背景与图标在同一窗口，无法通过公开 API 插入两者中间；`ignoresMouseEvents = true` 保证鼠标事件仍可穿透到桌面图标）
  - `showWallpapers()` 使用 `orderFront(nil)` 替代 `orderBack(nil)`，避免窗口被系统壁纸覆盖
  - `toggleShowOnDesktop()` 在引擎未开启时自动联动启用并选中首张壁纸，减少用户误操作
  - `addWallpaper(from:)` 自动将导入的文件复制到 Application Support 目录，避免原文件移动/删除后壁纸失效
  - `removeWallpaper(_:)` 删除已复制的壁纸文件，防止应用支持目录堆积
- 修复 `FanControlView` 中 `showToast(message:)` 为 internal，避免从 View 调用时编译错误
- 版本号更新为 v1.4.1 (Build 16)

---

## v1.4.0 — 2026-06-08

### 新增
- **Permission Center 权限控制中心**：
  - Hacker 风格面板，按 Core / Browser / System / Hardware / Optional 分类展示所有 macOS 权限
  - 实时检测 Accessibility、AppleEvents、Screen Recording、Full Disk、Mic、Camera、Location、Notifications、Contacts、Reminders、Calendar、Bluetooth 授权状态
  - 一键请求权限或跳转系统设置对应页面
  - 顶部总进度条与分类筛选
  - First-Time Setup onboarding 引导新用户逐条授权
  - UI 完整使用 `zoomScale` 适配窗口缩放
- **Activity Monitor 活动监视器**：
  - 5 个标签页：CPU / Memory / Energy / Disk / Network
  - 基于 `proc_pidinfo` + `proc_pid_rusage(RUSAGE_INFO_V6)` 的真实进程数据
  - 支持搜索、排序、强制退出/正常退出
  - 权限不足时顶部提示 banner，UI 使用 `zoomScale` 缩放
- **桌面小组件扩展**：
  - 新增 `fanThermalList`、`fanControlDash`、`taskManager` 桌面小组件
  - 新增 5 种桌面标签页：`noteTab`、`todoTab`、`terminalTab`、`cryptoTab`、`quoteTab`
  - 标签页支持锁定、拖拽、标题栏关闭，层级为 `desktopIconWindow + 20`

### 优化
- **AssessPrepHack 强化**：
  - 改为单例 ViewModel，使用真实监考进程标识
  - 增加 Accessibility 检测与系统引导
  - 使用 `kill -STOP/CONT` 精确挂起/恢复监考进程，避免误杀
  - 新增全局 F6 紧急快捷键
- **Wallpaper Engine UI/UX 重做**：
  - 更大更清晰的信息卡片 + 居中胶囊式播放控制按钮
  - 选项行改为水平滚动，彻底解决窗口较窄或高缩放下按钮重叠问题
  - 全部尺寸、间距、描边、控制图标按 `windowZoomScale` 缩放
  - 修复缩略图文字区域在高缩放下被截断的问题
  - `WallpaperQuickAccessBar` 同样适配 `zoomScale`
- Activity Monitor 与 Permission Center 窗口统一纳入 `updateAllWindowLevels` / `updateAllWindowSizes` / `handleClickOutside` 管理

### 修复
- 补充所有可弹窗权限的 `INFOPLIST_KEY` 使用描述（Bluetooth / Calendars / Camera / Contacts / Location / Microphone / Reminders），避免系统弹窗空白或崩溃
- 修复 Location 授权状态判断兼容性（同时接受 `.authorized` 与 `.authorizedAlways`）
- 修复 Full Disk Access 检测使用的探针路径（改为系统 TCC 数据库），减少误判

- 版本号更新为 v1.4.0 (Build 14)

---

## v1.3.0 — 2026-06-04

### 新增
- **Fan Control 风扇控制模块**（对标 TG Pro）：
  - 实时温度传感器监控：支持 Intel / Apple Silicon SMC 直连 + IORegistry fallback + 系统估计三重读取
  - 风扇 RPM 实时监控与手动/自动控制
  - 三种风扇模式：System（系统自控）、Max（全速）、Auto Max（智能规则）
  - Auto Max 规则引擎：支持多规则、目标风扇选择、温度阈值、滞后（hysteresis）、持续时长条件，避免风扇频繁启停
  - 渐进式转速过渡：可配置过渡时间，避免风扇噪音突变
  - 高温系统通知：可开关，阈值可调，带 10 分钟冷却 + Basso 警告音效
  - 睡眠/唤醒自动处理：可选睡眠时切回 System 模式，唤醒后恢复先前模式
  - 温度趋势箭头（↑/↓/→）和迷你历史折线图（sparkline）
  - 临界温度视觉警告（≥85°C 行泛红光）
  - Boost 按钮：一键 30 秒全速，自动恢复
  - 传感器名称实时搜索过滤 + 分类筛选（All/CPU/GPU/Battery/Other）
  - 一键复制传感器数据到剪贴板
  - 菜单栏可选实时温/RPM 显示
  - 完整的 Settings 面板：General / Temperature / Notifications / Fan Mode / Auto Max Rules / System / About

### 优化
- 温度单位（°C/°F）全局统一，含 Menu Bar、通知、导出数据
- 传感器按温度从高到低排序
- Fan Row 显示转速百分比

### 修复
- 修复 Auto Max 规则状态残留导致的活跃指示器不准确
- 修复睡眠唤醒后风扇模式未恢复
- 修复旧版 AutoMaxRule 数据缺失新字段时全部偏好丢失
- 修复 AppleARMIODevice fallback 误报电压/频率为温度传感器
- 修复菜单栏 Fan Control 摘要在睡眠期间继续 SMC 轮询

- 版本号更新为 v1.3.0 (Build 13)

---

## v0.4.4 — 2026-05-25

### 新增
- **弹窗风格增加到 10 种**：
  - 终端乱码（绿色）、系统错误（红色）、黄色警告、紫色系统日志
  - 崩溃报告、矩阵字符块、Windows 蓝屏、十六进制 dump
  - JSON 错误（橙色）、编译错误（红色/黄色）
- **屏幕闪烁效果**：动画开始时白色全屏闪，第 15/30 个弹窗时红色闪烁
- **SFX 增强**：屏幕闪烁时配合错误音效，更有冲击力

### 优化
- **主窗口默认尺寸调大**：width 320→380，maxHeight 400→500
- **主 UI 扫描线覆盖层**：整个面板添加 subtle 扫描线效果，增强 CRT 显示器感
- **Header 改进**：添加版本号小字、底部渐变分隔线
- **TabRow 改进**：hover/focus 时添加白色边框高亮，背景更不透明
- **Footer 改进**：保存按钮改为渐变背景、底部按钮添加图标
- 版本号更新为 v0.4.4 (Build 10)

## v0.4.3 — 2026-05-25

### 优化
- **开机混乱弹窗动画第四次重做**：
  - 弹窗数量固定为 **50** 个（8×6 网格 + 额外填充）
  - **主窗口混入弹窗中显现**：第 3 个弹窗弹出时主窗口开始 alpha→0.45，第 8 个时→0.65，之后随弹窗关闭进度逐步提升到 1.0
  - 主窗口从一开始就藏在弹窗底层，和弹窗一起「诞生」在混乱中
  - **超级黑客 SFX**：弹窗出现时叠加播放系统错误音效（Basso、Funk、Glass、Tock 等），营造系统崩溃的听觉冲击
  - 新增 `playGlitchSound()` 和 `playGlitchBurst(count:)` 音效方法
  - 弹窗抖动更剧烈（3-6 次，±8px），更有故障感
- 版本号更新为 v0.4.3 (Build 9)

## v0.4.2 — 2026-05-25

### 优化
- **开机混乱弹窗动画第三次重做**：
  - 弹窗数量从 28-36 增加到 **45-55**，屏幕几乎看不到空白
  - 采用**网格分布算法**（7×5 网格 + 额外随机填充），确保均匀覆盖无死角
  - 弹窗全部改为**无边框样式**（borderless），最大化内容展示区域
  - 新增 **BlueScreen 蓝屏视图**（模拟 Windows 蓝屏）和 **HexDump 十六进制视图**
  - 所有弹窗内容改为**纯静态渲染**，删除 Timer/Combine/实时刷新，彻底消除卡顿
  - 主窗口使用 `orderBack(nil)` 确保在弹窗最底层，alpha=0 完全不闪烁
  - 弹窗关闭后精准计数，全部关闭后主窗口才渐显
- 版本号更新为 v0.4.2 (Build 8)

## v0.3.2 — 2026-05-25

### 修复
- 修复启动后主 UI 不自动出现的问题：新安装和旧偏好迁移后默认会在启动时弹出主面板
- 修复菜单栏图标在部分深色/浅色菜单栏环境下不明显的问题，改用 macOS 原生 template 图标渲染
- 标签数量徽章改为菜单栏文字徽章，避免自绘图标造成入口不可见
- 版本号更新为 v0.3.2 (Build 5)

---

## v0.4.1 — 2026-05-25

### 优化
- **开机混乱弹窗动画全面重做**：
  - 弹窗数量从 16-22 增加到 **28-36**，几乎覆盖整个屏幕
  - 弹窗尺寸更大（320-520×200-360），允许重叠和部分超出屏幕边界
  - 弹窗显示速度更快（0.03-0.08s 间隔密集出现）
  - 弹窗关闭时精准计数，确保全部关闭后才显现主窗口
  - 主窗口现在在动画开始前就创建并置于底层（alpha=0），等弹窗全部退去后才渐显
- **性能优化**：终端乱码刷新 0.05s→0.15s，矩阵雨 0.06s→0.12s、列数 15→8，减少 CPU 占用避免卡顿
- 版本号更新为 v0.4.1 (Build 7)

## v0.4.0 — 2026-05-25

### 新增
- **独立浮动窗口主 UI**：主面板从 NSPopover 改为无边框独立 NSWindow，可拖动、有阴影、圆角裁切
- **开机混乱弹窗动画**：启动时 Splash Screen 结束后，装饰性小窗口在屏幕上弹跳出现，模拟系统崩溃/终端乱码/错误警告的混乱场面，然后逐个关闭，最后主窗口渐显
  - 终端乱码风：绿色等宽字体滚动 hex dump
  - 系统错误风：红色警告图标 + 错误信息
  - 崩溃报告风：模拟 macOS crash report 堆栈
  - 矩阵雨风：绿色字符雨下落动画
- **窗口拖动支持**：主窗口任意位置可拖动（`DraggableWindow`）

### 修复
- 修复 `AppPreferences.default` 参数顺序导致的编译错误，并为旧版设置增加缺省值迁移
- 修复全局呼出快捷键的 Cocoa/Carbon 修饰符转换
- 修复 Carbon 热键事件处理器误吞其他热键事件的问题
- 修复设置页录制全局快捷键时前台窗口无法捕获按键的问题
- 修复 F1-F12 作为标签快捷键时无法无修饰键保存的问题
- 修复浏览器已启动但没有窗口时无法新建标签打开目标 URL 的问题
- 修复清空全部标签后主面板列表和已注册快捷键不同步的问题
- 修复打开主面板时音效重复播放的问题
- 修复空状态页图标使用系统强调色（蓝色）的问题，统一为黑白主题白色
- 修复自动探测当前标签时误弹 Toast 的问题
- 修复 Toast 在主面板关闭后残留的问题
- 修复动画速度实际值与设定不符的问题（Fast 0.08s → 0.03s，Normal 0.2s → 0.1s）

### 优化
- 补齐面板圆角、主题、徽章、切换延迟、默认浏览器、清空确认等设置项的真实联动
- 菜单栏图标标签数量徽章真正生效
- TabRow 键盘导航焦点高亮
- 导出设置时默认文件名改为带时间戳的完整 JSON 文件名
- 项目部署目标调整为 macOS 14.0
- 版本号更新为 v0.4.0 (Build 6)

---

## v0.3.0 — 2025-05-22

### 新增
- **10 语言本地化**：支持简体中文（源）、繁体中文、英语、日语、韩语、法语、德语、西班牙语、俄语、葡萄牙语
- **黑客风格黑白 UI**：纯黑背景 + 白色细线条边框 + 等宽字体，极简极酷
- **2 秒启动动画**：全屏黑色开屏，显示 Hanazar Products / ClassGod，每次冷启动都有仪式感
- **设置面板增强**：
  - 面板圆角半径可调（0~24px）
  - 菜单栏标签数量徽章开关
  - 显示面板时自动探测当前标签
  - 键盘上下箭头导航开关
  - 切换前延迟（0~500ms）
  - 极速模式（一键禁用所有动画）
- **关于页面重构**：
  - 版本号自动读取 Bundle
  - Release Notes 链接按钮
  - GitHub 仓库链接按钮
  - 开发者 GitHub Profile（hzagaming）链接按钮
- **权限实时检测**：主面板打开时自动检查 Accessibility 权限，未授权时图标变红并弹窗提醒

### 优化
- **动画速度大幅提升**：Fast 模式从 80ms 降至 30ms，Normal 从 200ms 降至 100ms
- **极速模式**：新增全局开关，一键禁用所有动画，追求最快速度
- **按钮响应优化**：减少 hover/press 动画延迟

### 变更
- 主面板 UI 全面重构为黑白黑客风格
- 所有用户可见文本提取到 `Localizable.xcstrings` String Catalog
- `InfoPlist.xcstrings` 独立管理权限描述本地化
- 版本号统一为 v0.3.0 (Build 3)

---

## v0.2.0 — 2025-05-22

### 新增
- 5-Tab 设置面板（General / Shortcuts / Appearance / Browser / Advanced）
- 20+ 可调参数（动画速度、音效、震动、主题、图标样式等）
- 全局呼出快捷键自定义（默认 ⌘⇧C）
- 快捷键冲突检测与覆盖提示
- URL 匹配精度三档可调（Exact / Prefix / Host Only）
- 浏览器未运行时的行为控制（Launch & Open / Launch Only / Do Nothing）
- 外观自定义（图标样式、面板尺寸、主题、行高、紧凑模式）
- 数据导入/导出（JSON 格式）
- Toast 通知系统
- 删除/清空确认对话框
- 音效反馈（10 种系统音效）
- 震动反馈（Haptic）

### 修复
- AppleScript 字符串转义修复（`"` → `""`）
- Cocoa→Carbon 修饰符转换修复
- Carbon 事件处理器内存泄漏修复
- ShortcutPicker 事件监听器泄漏修复
- MenuBarView retain cycle 修复
- 分隔符从 `|||` 改为 ASCII 记录分隔符 `\u{001E}`
- `hostOnly` URL 匹配消除 shell 注入风险
- `.doNothing` 逻辑修复
- BrowserDetector 异步化
- BrowserTab.Equatable 简化为仅比较 `id`

---

## v0.1.0 — 2025-05-22

### 新增
- 菜单栏常驻应用（LSUIElement，无 Dock 图标）
- 探测前台浏览器标签（Safari / Chrome / Edge）
- 保存标签并绑定全局快捷键
- 按下快捷键切换回指定标签
- 标签关闭后可重新打开
- 编辑/删除已保存标签
- 本地持久化存储（UserDefaults）
- Accessibility / Automation 权限申请
