# ClassGod

**macOS 本機優先的緊急切換與桌面工具。一個快捷鍵回到正確的瀏覽器分頁、App 或安全工作區。**

[English](../../README.md) · [简体中文](README.zh-Hans.md) · **繁體中文** · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md)

> 目前版本：**v1.5.34 (Build 59)**。可從 [GitHub Releases](https://github.com/hzagaming/ClassGod/releases/latest) 下載 DMG 或 PKG。

## ClassGod 是什麼

ClassGod 常駐 macOS 選單列。你可以儲存瀏覽器目標、綁定全域快捷鍵，並從任何 App 快速返回：目標分頁仍存在時直接啟用，分頁已關閉時依儲存的網址重新開啟。

它也整合本機剪貼簿、App 切換、瀏覽器安全模式、原生 Widgets、風扇控制、活動監視器、動態桌布和完整權限中心。所有功能遵循同一原則：資料留在本機、選用權限不阻擋核心使用、特權操作必須由使用者明確批准。

## 主要功能

| 模組 | 功能 |
| --- | --- |
| **DestinTab** | 管理 Safari、Chrome、Edge 目標，支援搜尋、排序、置頂、批次操作與獨立快捷鍵。 |
| **SuperSwitch** | 透過全域快捷鍵啟用或啟動指定 App 與目標。 |
| **Fake Lock** | 以 Safe Browser 或 MapTest Bypass 模式開啟指定瀏覽器與網址，可分別鎖定上一頁、下一頁導覽。 |
| **Clipo** | 本機剪貼簿記錄、快捷槽、搜尋、置頂、匯入匯出與自動清理。 |
| **Permission Center** | 顯示所有支援權限的即時狀態、用途、檢測方式和精確系統設定入口。 |
| **Fan Control** | 讀取可用溫度與風扇資料，支援 System、Max、Manual、Custom 模式；使用者批准後可使用特權 Helper。 |
| **Widgets** | 19 個原生 WidgetKit 小工具，涵蓋系統、天氣、筆記、任務、檔案、終端機與 App 啟動。 |
| **桌面工具** | Activity Monitor、動態桌布、Hacker Desktop、Error Hub、BrowserBypasser 與 AssessPrep 工具。 |

## 隱私承諾

- 不包含分析、遙測、帳戶系統、ClassGod 後端或背景上傳路徑。
- 偏好、分頁、剪貼簿記錄、Widget 資料與媒體設定全部保存在本機。
- 權限狀態只從 macOS 本機讀取並在本機顯示。
- 選用權限可略過；相關功能會安全降級。
- 完整解除安裝工具在兩次確認後清除 App 資料、Helper、LaunchDaemon、安裝收據與 ClassGod 對應權限決定。

## 系統需求

- macOS 14.0 或以上版本
- 目前下載版本面向 Apple Silicon（`arm64`）
- 瀏覽器切換支援 Safari、Google Chrome 與 Microsoft Edge
- 核心瀏覽器流程需要輔助使用與自動化權限
- 安裝 PKG、風扇 Helper 或執行完整解除安裝時可能需要管理員批准

## 安裝

### DMG

下載最新 `.dmg`，開啟後將 **ClassGod** 拖入 **Applications**，再啟動 `/Applications/ClassGod.app`。

### PKG

下載最新 `.pkg` 並執行安裝程式。App 會安裝到 `/Applications`；首次啟動可完成或暫時略過權限導覽。

目前公開版本使用 ad-hoc 簽署，尚未通過 Apple 公證。首次開啟可能需要前往 **系統設定 → 隱私權與安全性 → 強制打開**。請只安裝來源與校驗值可信的檔案。

## 快速開始

1. 啟動 ClassGod，等待品牌動畫進入主面板。
2. 需要核心切換時授予輔助使用和瀏覽器自動化權限；選用權限可略過。
3. 開啟 **DestinTab**，儲存目前瀏覽器分頁並錄製快捷鍵。
4. 在任何 App 按下快捷鍵，ClassGod 會啟用符合的分頁或重新開啟儲存的網址。

快捷鍵支援字母、數字與 F1–F12；可註冊修飾鍵為 Command、Option、Control、Shift。

## 權限邊界

所有 macOS 隱私權限都必須由使用者親自授予。DMG、PKG、App、腳本或特權 Helper 都不能代替使用者同意 TCC 權限。

| 等級 | 範例 | 行為 |
| --- | --- | --- |
| **核心** | 輔助使用、自動化 | 用於偵測和控制支援的瀏覽器。 |
| **建議** | 輸入監控、螢幕錄製、通知、完整磁碟存取 | 啟用相關快捷鍵、擷取、提醒與本機檔案流程。 |
| **選用** | 相機、麥克風、照片、位置、聯絡人、行事曆、提醒事項、藍牙、語音辨識、本機網路 | 僅在相關功能需要時要求，可略過。 |

Permission Center 在顯示期間持續更新可檢測狀態，並連結至相應系統設定頁。部分權限變更後需重新啟動 App 才會生效。

## 語言

英文是開發與回退語言，英文和簡體中文廣泛覆蓋主要介面；其餘語言採漸進式翻譯，尚未覆蓋的內容會安全回退至英文。

## 從原始碼建置

```bash
git clone https://github.com/hzagaming/ClassGod.git
cd ClassGod
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  build
```

主工程使用 SwiftUI + AppKit + MVVM；Xcode 建置階段會編譯並嵌入 `ClassGodHelper`。因 AppleEvents、輔助使用、桌布控制及使用者批准的特權 Helper 需求，App Sandbox 明確停用。

測試命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  test

cd ClassGodHelper && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

## 更新與參與

目前版本記錄見 [CHANGELOG.md](../../CHANGELOG.md)，更早歷史見 [CHANGELOG_HISTORY.md](../../CHANGELOG_HISTORY.md)。提交修改時請保持範圍集中、資料純本機、所有使用者文字完整本地化，並為行為變更加入回歸測試。

## 負責任使用

ClassGod 是效率與內容切換工具。只能在你獲授權控制的裝置、瀏覽器工作階段、評量和帳戶上使用；它不授予繞過組織政策、監控、存取控制或學術規則的權利。

## 授權條款

ClassGod 採用 [MIT License](../../LICENSE)。
