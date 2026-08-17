# ClassGod

**macOS 向けのローカルファーストな緊急コンテキスト切り替え／デスクトップツール。ショートカット一つで、目的のブラウザタブ、アプリ、安全なワークスペースに戻れます。**

[English](../../README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · **日本語** · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md)

> 現在のリリース：**v1.5.36 (Build 61)**。[GitHub Releases](https://github.com/hzagaming/ClassGod/releases/latest) から DMG または PKG をダウンロードできます。

## ClassGod について

ClassGod は macOS のメニューバーに常駐します。ブラウザの移動先とグローバルショートカットを保存すると、どのアプリからでもすぐに戻れます。対象タブが存在すれば有効化し、閉じられていれば保存済み URL を開き直します。

ローカルクリップボード、アプリ切り替え、ブラウザ保護モード、ネイティブ Widget、ファン制御、アクティビティモニタ、動的壁紙、権限センターも統合しています。データは Mac 内に保持され、任意権限なしでも安全に縮退し、特権操作には常にユーザーの明示的な承認が必要です。

## 主な機能

| モジュール | 機能 |
| --- | --- |
| **DestinTab** | Safari、Chrome、Edge の移動先を保存し、検索、並べ替え、ピン留め、一括操作、個別ショートカットを提供します。 |
| **SuperSwitch** | 指定したアプリやターゲットをグローバルショートカットで有効化または起動します。 |
| **Fake Lock** | Safe Browser または MapTest Bypass でブラウザと URL を開き、戻る／進む操作を個別にロックできます。 |
| **Clipo** | ローカルのクリップボード履歴、クイックスロット、検索、ピン留め、インポート／エクスポート、自動削除を提供します。 |
| **Permission Center** | 対応する全権限の状態、用途、検出方法、正確なシステム設定リンクを表示します。 |
| **Fan Control** | 利用可能な温度とファン情報を読み取り、System、Max、Manual、Custom モードを提供します。承認時のみ特権 Helper を使用します。 |
| **Widgets** | システム、天気、メモ、タスク、ファイル、ターミナル、アプリランチャーを含む 19 個の WidgetKit ウィジェットです。 |
| **デスクトップツール** | Activity Monitor、動的壁紙、Hacker Desktop、Error Hub、BrowserBypasser、AssessPrep ツールを収録しています。 |

## プライバシー

- 分析、テレメトリ、アカウント、ClassGod バックエンド、バックグラウンドアップロードはありません。
- 設定、タブ、クリップボード履歴、Widget データ、メディア設定はローカルに保存されます。
- 権限状態は macOS からローカルに読み取り、その場で表示します。
- 任意権限はスキップでき、関連機能は安全に縮退します。
- 完全アンインストーラは二重確認後にアプリデータ、Helper、LaunchDaemon、レシート、ClassGod の権限決定を削除します。

## 動作要件

- macOS 14.0 以降
- 現在の配布ビルドは Apple Silicon（`arm64`）向け
- Safari、Google Chrome、Microsoft Edge
- 中核のブラウザ操作にはアクセシビリティとオートメーション権限が必要
- PKG、ファン制御 Helper の導入、または完全アンインストールで管理者承認が必要になる場合があります

## インストール

DMG は開いて **ClassGod** を **Applications** にドラッグします。PKG はインストーラを実行すると `/Applications` に導入されます。初回起動時の権限ガイドは完了または一時的にスキップできます。

現在の公開成果物は ad-hoc 署名で、Apple の公証を受けていません。初回起動時に **システム設定 → プライバシーとセキュリティ → このまま開く** が必要な場合があります。出所とチェックサムを確認できるファイルだけを利用してください。

## クイックスタート

1. ClassGod を起動し、ブランドアニメーション後にメインパネルを開きます。
2. 中核の切り替え機能を使う場合は、アクセシビリティとブラウザのオートメーションを許可します。任意権限はスキップできます。
3. **DestinTab** で現在のブラウザタブを保存し、ショートカットを記録します。
4. 任意のアプリからショートカットを押すと、一致するタブを有効化するか保存 URL を開き直します。

キーは英字、数字、F1–F12 に対応し、修飾キーは Command、Option、Control、Shift を登録できます。

## 権限の境界

macOS のプライバシー権限はユーザー本人が許可する必要があります。DMG、PKG、アプリ、スクリプト、特権 Helper が TCC 権限を代理で承認することはできません。

| レベル | 例 | 動作 |
| --- | --- | --- |
| **中核** | アクセシビリティ、オートメーション | 対応ブラウザの検出と制御に使用します。 |
| **推奨** | 入力監視、画面収録、通知、フルディスクアクセス | 関連するショートカット、キャプチャ、通知、ローカルファイル機能を有効にします。 |
| **任意** | カメラ、マイク、写真、位置情報、連絡先、カレンダー、リマインダー、Bluetooth、音声認識、ローカルネットワーク | 対象機能でのみ要求され、スキップできます。 |

## 言語

英語が開発言語およびフォールバックです。英語と簡体字中国語はアプリの主要部分を広くカバーし、その他の言語は段階的に翻訳され、未翻訳部分では英語にフォールバックします。

## ソースからビルド

```bash
git clone https://github.com/hzagaming/ClassGod.git
cd ClassGod
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  build
```

アプリは SwiftUI + AppKit + MVVM で構成され、Xcode のビルドフェーズが `ClassGodHelper` をコンパイルして埋め込みます。AppleEvents、アクセシビリティ、壁紙制御、ユーザー承認済み Helper の要件により、App Sandbox は意図的に無効です。

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  test

cd ClassGodHelper && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

## 更新・コントリビューション

現在の履歴は [CHANGELOG.md](../../CHANGELOG.md)、過去の履歴は [CHANGELOG_HISTORY.md](../../CHANGELOG_HISTORY.md) を参照してください。変更は対象を限定し、データのローカル処理を維持し、ユーザー向け文字列を翻訳し、動作変更には回帰テストを追加してください。

## 責任ある利用

ClassGod は生産性とコンテキスト切り替えのためのツールです。管理権限を持つ端末、ブラウザセッション、評価、アカウントでのみ使用してください。組織ポリシー、監視、アクセス制御、学則を回避する権利を与えるものではありません。

## ライセンス

ClassGod は [MIT License](../../LICENSE) で提供されます。
