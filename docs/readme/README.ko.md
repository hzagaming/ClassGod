# ClassGod

**macOS용 로컬 우선 긴급 컨텍스트 전환 및 데스크톱 도구입니다. 단축키 하나로 올바른 브라우저 탭, 앱 또는 안전한 작업 공간으로 돌아갑니다.**

[English](../../README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · **한국어** · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md)

> 현재 릴리스: **v1.5.38 (Build 63)**. [GitHub Releases](https://github.com/hzagaming/ClassGod/releases/latest)에서 DMG 또는 PKG를 다운로드할 수 있습니다.

## ClassGod 소개

ClassGod는 macOS 메뉴 막대에서 실행됩니다. 브라우저 대상을 저장하고 전역 단축키를 지정하면 어느 앱에서든 빠르게 돌아갈 수 있습니다. 대상 탭이 있으면 활성화하고, 닫혔다면 저장한 URL을 다시 엽니다.

로컬 클립보드, 앱 전환, 브라우저 보호 모드, 네이티브 Widget, 팬 제어, 활동 모니터, 동적 배경화면, 권한 센터도 통합합니다. 데이터는 Mac에 남고, 선택 권한이 없어도 안전하게 기능을 축소하며, 권한 상승 작업은 항상 사용자의 명시적 승인을 요구합니다.

## 주요 기능

| 모듈 | 기능 |
| --- | --- |
| **DestinTab** | Safari, Chrome, Edge 대상을 저장하고 검색, 정렬, 고정, 일괄 작업, 개별 단축키를 제공합니다. |
| **SuperSwitch** | 지정한 앱과 대상을 전역 단축키로 활성화하거나 실행합니다. |
| **Fake Lock** | Safe Browser 또는 MapTest Bypass 모드로 브라우저와 URL을 열고 뒤로/앞으로 이동을 각각 잠급니다. |
| **Clipo** | 로컬 클립보드 기록, 빠른 슬롯, 검색, 고정, 가져오기/내보내기, 자동 정리를 제공합니다. |
| **Permission Center** | 지원하는 모든 권한의 실시간 상태, 용도, 감지 방식과 정확한 시스템 설정 링크를 보여 줍니다. |
| **Fan Control** | 사용 가능한 온도 및 팬 데이터를 읽고 System, Max, Manual, Custom 모드를 제공합니다. 승인된 경우에만 권한 Helper를 사용합니다. |
| **Widgets** | 시스템, 날씨, 메모, 할 일, 파일, 터미널, 앱 실행기를 포함한 19개의 WidgetKit 위젯입니다. |
| **데스크톱 도구** | Activity Monitor, 동적 배경화면, Hacker Desktop, Error Hub, BrowserBypasser, AssessPrep 도구를 포함합니다. |

## 개인정보 보호

- 분석, 원격 측정, 계정 시스템, ClassGod 백엔드 또는 백그라운드 업로드가 없습니다.
- 설정, 탭, 클립보드 기록, Widget 데이터와 미디어 구성은 로컬에 저장됩니다.
- 권한 상태는 macOS에서 로컬로 읽어 화면에 표시합니다.
- 선택 권한은 건너뛸 수 있으며 관련 기능은 안전하게 축소됩니다.
- 완전 제거 도구는 두 번 확인한 뒤 앱 데이터, Helper, LaunchDaemon, 설치 영수증과 ClassGod 권한 결정을 삭제합니다.

## 요구 사항

- macOS 14.0 이상
- 현재 배포 빌드는 Apple Silicon(`arm64`)용
- Safari, Google Chrome 또는 Microsoft Edge
- 핵심 브라우저 작업에는 손쉬운 사용과 자동화 권한 필요
- PKG, 팬 제어 Helper 설치 또는 완전 제거 시 관리자 승인이 필요할 수 있음

## 설치

DMG를 열어 **ClassGod**를 **Applications**로 드래그하거나, PKG 설치 프로그램을 실행해 `/Applications`에 설치합니다. 첫 실행의 권한 안내는 완료하거나 일시적으로 건너뛸 수 있습니다.

현재 공개 파일은 ad-hoc 서명이며 Apple 공증을 받지 않았습니다. 첫 실행 시 **시스템 설정 → 개인정보 보호 및 보안 → 확인 없이 열기**가 필요할 수 있습니다. 출처와 체크섬을 확인할 수 있는 파일만 설치하세요.

## 빠른 시작

1. ClassGod를 실행하고 브랜드 애니메이션 뒤 메인 패널을 엽니다.
2. 핵심 전환 기능을 사용할 때 손쉬운 사용 및 브라우저 자동화를 허용합니다. 선택 권한은 건너뛸 수 있습니다.
3. **DestinTab**에서 현재 브라우저 탭을 저장하고 단축키를 기록합니다.
4. 어느 앱에서든 단축키를 누르면 일치하는 탭을 활성화하거나 저장한 URL을 다시 엽니다.

지원 키는 문자, 숫자, F1–F12이며 등록 가능한 보조 키는 Command, Option, Control, Shift입니다.

## 권한 경계

macOS 개인정보 보호 권한은 사용자가 직접 허용해야 합니다. DMG, PKG, 앱, 스크립트 또는 권한 Helper가 사용자를 대신해 TCC 권한을 승인할 수 없습니다.

| 수준 | 예시 | 동작 |
| --- | --- | --- |
| **핵심** | 손쉬운 사용, 자동화 | 지원 브라우저 감지와 제어에 사용합니다. |
| **권장** | 입력 모니터링, 화면 기록, 알림, 전체 디스크 접근 | 관련 단축키, 캡처, 알림 및 로컬 파일 기능을 활성화합니다. |
| **선택** | 카메라, 마이크, 사진, 위치, 연락처, 캘린더, 미리 알림, Bluetooth, 음성 인식, 로컬 네트워크 | 해당 기능에서만 요청하며 건너뛸 수 있습니다. |

## 언어

영어가 개발 언어이자 기본 언어입니다. 영어와 중국어 간체는 앱의 주요 부분을 폭넓게 지원하며, 나머지 언어는 단계적으로 번역되고 아직 번역되지 않은 부분은 영어로 표시됩니다.

## 소스에서 빌드

```bash
git clone https://github.com/hzagaming/ClassGod.git
cd ClassGod
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  build
```

앱은 SwiftUI + AppKit + MVVM으로 구성되며 Xcode 빌드 단계가 `ClassGodHelper`를 컴파일해 포함합니다. AppleEvents, 손쉬운 사용, 배경화면 제어 및 사용자가 승인한 Helper 때문에 App Sandbox는 의도적으로 비활성화되어 있습니다.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  test

cd ClassGodHelper && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

## 업데이트 및 기여

현재 변경 사항은 [CHANGELOG.md](../../CHANGELOG.md), 이전 기록은 [CHANGELOG_HISTORY.md](../../CHANGELOG_HISTORY.md)를 참고하세요. 변경 범위를 좁게 유지하고, 로컬 데이터 처리를 보존하고, 사용자 문자열을 현지화하며, 동작 변경에 회귀 테스트를 추가해 주세요.

## 책임 있는 사용

ClassGod는 생산성과 컨텍스트 전환 도구입니다. 관리 권한이 있는 기기, 브라우저 세션, 평가 및 계정에서만 사용하세요. 조직 정책, 모니터링, 접근 제어 또는 학업 규칙을 우회할 권한을 제공하지 않습니다.

## 라이선스

ClassGod는 [MIT License](../../LICENSE)로 제공됩니다.
