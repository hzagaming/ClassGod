# ClassGod

**macOS 本地优先的紧急切屏与桌面工具。一个快捷键回到正确的浏览器标签、应用或安全工作区。**

[English](../../README.md) · **简体中文** · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md)

> 当前版本：**v1.5.41 (Build 66)**。可从 [GitHub Releases](https://github.com/hzagaming/ClassGod/releases/latest) 下载 DMG 或 PKG。

## ClassGod 是什么

ClassGod 常驻 macOS 菜单栏。你可以保存浏览器目标、绑定全局快捷键，并从任意应用快速返回：目标标签仍存在时直接激活，标签已关闭时按保存的网址重新打开。

现在它还整合了本地剪贴板、应用切换、浏览器安全模式、原生 Widgets、风扇控制、活动监视器、动态壁纸和完整权限中心。所有功能遵循同一原则：数据留在本机，可选权限不阻塞核心使用，特权操作必须由用户明确批准。

## 主要功能

| 模块 | 功能 |
| --- | --- |
| **DestinTab** | 管理 Safari、Chrome、Edge 目标，支持搜索、排序、置顶、批量操作和独立快捷键。 |
| **SuperSwitch** | 用全局快捷键激活或启动指定应用与目标。 |
| **Fake Lock** | 以 Safe Browser 或 MapTest Bypass 模式打开指定浏览器和网址，可分别锁定前进、后退导航。 |
| **Clipo** | 本地剪贴板历史、快捷槽、搜索、置顶、导入导出和自动清理。 |
| **Permission Center** | 展示全部支持权限的实时状态、用途、检测方式和精确系统设置入口。 |
| **Fan Control** | 读取可用温度与风扇数据，支持 System、Max、Manual、Custom 模式；用户批准后可使用特权 Helper。 |
| **Widgets** | 19 个原生 WidgetKit 小组件，覆盖系统、天气、便签、任务、文件、终端和应用启动。 |
| **桌面工具** | Activity Monitor、动态壁纸、Hacker Desktop、Error Hub、BrowserBypasser 和 AssessPrep 工具。 |

## 隐私承诺

- 不包含分析、遥测、账户系统、ClassGod 后端或后台上传链路。
- 偏好、标签、剪贴板历史、Widget 数据和媒体配置全部保存在本机。
- 权限状态只从 macOS 本地读取并在本地展示。
- 可选权限可以跳过；相关功能会安全降级。
- 完全卸载工具在两次确认后清除应用数据、Helper、LaunchDaemon、安装收据和 ClassGod 对应权限决定。

## 系统要求

- macOS 14.0 或更高版本
- 当前下载构建面向 Apple Silicon（`arm64`）
- 浏览器切换支持 Safari、Google Chrome 和 Microsoft Edge
- 核心浏览器流程需要辅助功能与自动化权限
- 安装 PKG、风扇 Helper 或执行完全卸载时可能需要管理员批准

## 安装

### DMG

下载最新 `.dmg`，打开后把 **ClassGod** 拖入 **Applications**，再启动 `/Applications/ClassGod.app`。

### PKG

下载最新 `.pkg` 并运行安装器。应用将安装到 `/Applications`；首次启动可完成或暂时跳过权限引导。

当前公开构建使用 ad-hoc 签名，尚未经过 Apple 公证。首次打开可能需要前往 **系统设置 → 隐私与安全性 → 仍要打开**。请只安装来源和校验值可信的文件。

## 快速开始

1. 启动 ClassGod，等待品牌动画进入主面板。
2. 需要核心切屏时授权辅助功能和浏览器自动化；可选权限可以跳过。
3. 打开 **DestinTab**，保存当前浏览器标签并录制快捷键。
4. 在任意应用按下快捷键，ClassGod 会激活匹配标签或重新打开保存的网址。

快捷键支持字母、数字和 F1–F12；可注册修饰键为 Command、Option、Control、Shift。

## 权限边界

所有 macOS 隐私权限都必须由用户亲自授权。DMG、PKG、应用、脚本和特权 Helper 都不能替用户同意 TCC 权限。

| 级别 | 示例 | 行为 |
| --- | --- | --- |
| **核心** | 辅助功能、自动化 | 用于检测和控制支持的浏览器。 |
| **建议** | 输入监控、屏幕录制、通知、完全磁盘访问 | 启用对应快捷键、捕获、提醒和本地文件流程。 |
| **可选** | 摄像头、麦克风、照片、位置、通讯录、日历、提醒事项、蓝牙、语音识别、本地网络 | 仅在相关功能需要时申请，允许跳过。 |

Permission Center 在可见期间持续刷新可检测状态，并跳转到对应系统设置页。部分权限更改后需要重启 App 才会生效。

## 语言

英语是开发与回退语言，英语和简体中文覆盖主要界面；其余语言采用渐进式翻译，尚未覆盖的内容会安全回退到英语。

## 从源码构建

```bash
git clone https://github.com/hzagaming/ClassGod.git
cd ClassGod
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  build
```

主工程使用 SwiftUI + AppKit + MVVM；Xcode 构建阶段会编译并嵌入 `ClassGodHelper`。由于 AppleEvents、辅助功能、壁纸控制和受用户批准的特权 Helper 需求，App Sandbox 被明确禁用。

测试命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  test

cd ClassGodHelper && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

## 更新与参与

当前版本记录见 [CHANGELOG.md](../../CHANGELOG.md)，更早历史见 [CHANGELOG_HISTORY.md](../../CHANGELOG_HISTORY.md)。提交改动时请保持范围集中、数据纯本地、用户文案完整本地化，并为行为变化添加回归测试。

## 负责任使用

ClassGod 是效率和上下文切换工具。只能在你获授权控制的设备、浏览器会话、考试和账户中使用；它不会赋予绕过组织政策、监控、访问控制或学术规则的权利。

## 许可证

ClassGod 使用 [MIT License](../../LICENSE)。
