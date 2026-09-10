<div align="center">
  <img src="ClassGod/ClassGod/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="112" alt="ClassGod app icon">
  <h1>ClassGod</h1>
  <p><strong>A local-first emergency context switcher for macOS.</strong></p>
  <p>Jump back to the right browser tab, app, or safe workspace in one shortcut.</p>

  <p>
    <a href="docs/readme/README.zh-Hans.md">简体中文</a> ·
    <a href="docs/readme/README.zh-Hant.md">繁體中文</a> ·
    <a href="docs/readme/README.ja.md">日本語</a> ·
    <a href="docs/readme/README.ko.md">한국어</a> ·
    <a href="docs/readme/README.fr.md">Français</a> ·
    <a href="docs/readme/README.de.md">Deutsch</a> ·
    <a href="docs/readme/README.es.md">Español</a> ·
    <a href="docs/readme/README.pt.md">Português</a> ·
    <a href="docs/readme/README.ru.md">Русский</a>
  </p>

  <p>
    <a href="https://github.com/hzagaming/ClassGod/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/hzagaming/ClassGod?style=flat-square"></a>
    <img alt="macOS 14 or later" src="https://img.shields.io/badge/macOS-14.0%2B-111111?style=flat-square&logo=apple">
    <img alt="Swift 5.9 or later" src="https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white">
    <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-2ea44f?style=flat-square"></a>
    <img alt="Local first" src="https://img.shields.io/badge/data-local--only-00bcd4?style=flat-square">
  </p>
</div>

> Source version: **v1.5.55 (Build 80)**. Published downloads are available on [GitHub Releases](https://github.com/hzagaming/ClassGod/releases/latest).

## Why ClassGod

ClassGod lives in the macOS menu bar and gives you a fast, predictable way to return to a prepared context. Save a browser destination, assign a global shortcut, and ClassGod activates the matching tab—or opens it again when the tab no longer exists.

It has grown into a focused desktop toolkit while keeping the same rule: user data stays on the Mac, features degrade safely without optional permissions, and every privileged action remains visible to the user.

## Highlights

| Area | What it does |
| --- | --- |
| **DestinTab** | Saves Safari, Chrome, and Edge destinations with search, sorting, pinning, batch actions, and per-tab shortcuts. |
| **SuperSwitch** | Activates or launches selected apps and targets with independent global shortcuts. |
| **Fake Lock** | Opens a chosen browser and URL in Safe Browser or MapTest Bypass mode, with configurable back/forward navigation locks. |
| **Clipo** | Keeps local clipboard history, quick slots, search, pinning, import/export, and controlled retention. |
| **Notes** | Keeps searchable local notes in an optional floating window that follows every app, Space, and full-screen workspace. |
| **Todo** | Organizes local tasks with smart lists, projects, priorities, subtasks, recurrence, search, and a Focus Pulse dashboard. |
| **Schedule Lab** | Builds a local weekly timetable with live status, conflict detection, overlap lanes, locations, notes, and colors. |
| **Focus Flow** | Runs drift-free focus and recovery cycles with three rhythms, long-break cadence, and local daily statistics. |
| **Recall Lab** | Good Student: creates local question cards, reveals answers on demand, and schedules reviews from your recall rating. |
| **Switch Drill** | Bad Student: rehearses registered destination shortcuts with randomized cues, separate reaction/switch timing, and the last five results. |
| **Reading Lane** | Good Student: reads pasted study material one passage at a time, with manual progress, backtracking, and a reflection prompt. |
| **Screen Curtain** | Bad Student: temporarily covers connected displays, with Escape dismissal and automatic return after 15–120 seconds. |
| **Number Sprint** | Good Student: ten arithmetic questions in three levels, with retries, answer reveal, and separate first-try and corrected scores. |
| **Return Dock** | Bad Student: opt-in return tickets after successful DestinTab or SuperSwitch target shortcuts, returning to the original running app. |
| **Teach Back** | Good Student: develops a concept through an explanation, example, and open questions, with a self-check and plain-text copy. |
| **Quiet Desk** | Bad Student: temporarily mutes a supported default audio output and keeps a restoration for that exact device without changing its volume. |
| **Software Update** | Checks stable GitHub releases automatically, verifies installer metadata and SHA-256, then opens the macOS Installer. |
| **Permission Center** | Shows every supported macOS permission, its live state, why it is used, and the exact system settings destination. |
| **Fan Control** | Reads available temperature and fan data, supports System, Max, Manual, and Custom policies, and uses a privileged helper when approved. |
| **Widgets** | Provides 19 native WidgetKit widgets, including system, weather, notes, tasks, files, terminal, and launcher views. |
| **Desktop tools** | Includes Activity Monitor, dynamic wallpapers, Hacker Desktop, Error Hub, BrowserBypasser, and AssessPrep tools. |
| **Personalization** | Uses a black visual base with a custom accent, scalable windows, animation controls, sound effects, and haptic feedback. |

Recall Lab and Switch Drill are additions in the current development tree. Recall cards stay in Application Support; drill results last only for the current app session. A drill executes the selected shortcut with its existing settings, so it really switches apps or browser tabs.

Reading Lane and Screen Curtain also belong to the development build. Reading material and progress remain in memory until quit. The curtain is a visual cover, not a lock or recording blocker; switching apps, sleep, or display changes dismiss it.

Number Sprint and Return Dock keep session data in memory. Return Dock defaults to off, keeps five tickets, and clears them when disabled or on quit. It does not reopen closed apps or restore browser tabs, windows, or cursor positions.

Teach Back and Quiet Desk bring the development menu to eleven features per student mode. Teach Back drafts stay in memory until quit; the worksheet provides self-checks, not automatic fact checking. Quiet Desk controls the writable main mute property of one output device and remembers its UID for restoration. Closing the panel keeps it muted; normal quit attempts restoration. Unsupported outputs, microphones, and independently routed audio are outside its scope.

## Privacy by design

- ClassGod has no analytics, telemetry, account system, ClassGod backend, or background upload path.
- Preferences, tabs, clipboard history, widgets, and media configuration are stored locally.
- Permission status is read from macOS and displayed locally.
- Optional permissions remain optional; unavailable features show a safe fallback.
- The complete uninstaller removes ClassGod data, helper files, launch services, receipts, and app-specific permission decisions after two confirmations.

See [Permissions](#permissions) for the platform limits that no installer can bypass.

## Requirements

- macOS 14.0 or later
- Apple Silicon (`arm64`) for the current downloadable builds
- Safari, Google Chrome, or Microsoft Edge for browser switching
- Accessibility and Automation approval for the core browser workflow
- Administrator approval may be required for PKG installation, the optional fan-control helper, or a complete uninstall

## Install

### DMG

1. Download the latest `.dmg` from [Releases](https://github.com/hzagaming/ClassGod/releases/latest).
2. Open it and drag **ClassGod** to **Applications**.
3. Launch `/Applications/ClassGod.app`.

### PKG

1. Download the latest `.pkg` from [Releases](https://github.com/hzagaming/ClassGod/releases/latest).
2. Run the installer; ClassGod is installed in `/Applications`.
3. Launch ClassGod and complete or temporarily skip the permission guide.

Current public artifacts are ad-hoc signed and are not Apple-notarized. On first launch, macOS may require **System Settings → Privacy & Security → Open Anyway**. Never install a package whose source or checksum you cannot verify.

## Quick start

1. Launch ClassGod and wait for the brand animation to open the main panel.
2. Approve Accessibility and browser Automation when you want the core switching workflow. Optional permissions can be skipped.
3. Open **DestinTab**, capture the current browser tab, and assign a supported global shortcut.
4. Press the shortcut from any app. ClassGod activates the matching tab or recreates it using the saved URL.

Supported shortcut keys are letters, numbers, and F1–F12. Registerable modifiers are Command, Option, Control, and Shift.

## Permissions

macOS privacy permissions must be granted by the user. A DMG, PKG, app, script, or privileged helper cannot approve TCC prompts on the user's behalf.

| Level | Examples | Behavior |
| --- | --- | --- |
| **Core** | Accessibility, Automation | Required for detecting and controlling supported browsers. |
| **Recommended** | Input Monitoring, Screen Recording, Notifications, Full Disk Access | Enables related shortcuts, capture, alerts, and local file workflows. |
| **Optional** | Camera, Microphone, Photos, Location, Contacts, Calendar, Reminders, Bluetooth, Speech Recognition, Local Network | Requested only for the feature that uses them and can be skipped. |

Permission Center refreshes detectable state while visible and links to the appropriate system settings pane. Some macOS permissions require restarting the app before a changed decision takes effect.

## Languages

English is the development language and fallback. English and Simplified Chinese cover the main app broadly; the other declared locales are progressively translated and fall back to English where a translation is not yet available.

| Language | Locale | README |
| --- | --- | --- |
| English | `en` | This file |
| Simplified Chinese | `zh-Hans` | [简体中文](docs/readme/README.zh-Hans.md) |
| Traditional Chinese | `zh-Hant` | [繁體中文](docs/readme/README.zh-Hant.md) |
| Japanese | `ja` | [日本語](docs/readme/README.ja.md) |
| Korean | `ko` | [한국어](docs/readme/README.ko.md) |
| French | `fr` | [Français](docs/readme/README.fr.md) |
| German | `de` | [Deutsch](docs/readme/README.de.md) |
| Spanish | `es` | [Español](docs/readme/README.es.md) |
| Portuguese | `pt` | [Português](docs/readme/README.pt.md) |
| Russian | `ru` | [Русский](docs/readme/README.ru.md) |

## Build from source

```bash
git clone https://github.com/hzagaming/ClassGod.git
cd ClassGod
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  build
```

The project build phase compiles `ClassGodHelper` and embeds it in the app. App Sandbox is intentionally disabled because browser AppleEvents, Accessibility, the wallpaper controller, and the approved privileged helper require capabilities that a sandboxed build cannot provide.

Run the app tests with:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  test
```

Run the helper tests separately:

```bash
cd ClassGodHelper
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

## Architecture

| Layer | Main responsibilities |
| --- | --- |
| SwiftUI + AppKit | Menu bar UI, independent feature windows, native widgets, visual and interaction feedback. |
| Models + ViewModels | Preferences, tabs, bypass rules, widgets, fan policies, and feature state. |
| Services | Browser detection/switching, shortcuts, permissions, storage, SMC access, wallpapers, and local clipboard processing. |
| ClassGodHelper | Optional root helper communicating through a UID-checked Unix domain socket for supported SMC operations. |

Key paths:

```text
ClassGod/ClassGod/         Main macOS application
ClassGod/ClassGodWidget/   WidgetKit extension
ClassGod/ClassGodTests/    App tests
ClassGodHelper/            Privileged helper Swift package and tests
```

## Latest changes: v1.5.55

Training buttons now scale their text and hit areas with the panel, with distinct primary, secondary, destructive, and disabled states. Wallpaper auto-advance is cancelled when playback controls or the selected item change, so a queued completion cannot undo a pause, re-enable a disabled wallpaper, or override manual selection. Hiding or replacing desktop wallpaper content explicitly stops its video, audio, and animated-image playback.

Read [CHANGELOG.md](CHANGELOG.md) for current releases and [CHANGELOG_HISTORY.md](CHANGELOG_HISTORY.md) for older history.

## Contributing

Keep changes focused, preserve local-only data handling, localize every user-visible string, and add regression coverage for behavior changes. For security-sensitive changes, explain the permission boundary and failure mode in the pull request.

## Responsible use

ClassGod is a productivity and context-switching utility. Use it only on systems, browser sessions, assessments, and accounts you are authorized to control. It does not grant permission to bypass organizational policy, monitoring, access controls, or academic rules.

## License

ClassGod is available under the [MIT License](LICENSE).
