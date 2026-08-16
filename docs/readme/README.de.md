# ClassGod

**Ein lokal arbeitender Notfall-Kontextwechsler und Desktop-Werkzeugkasten für macOS. Mit einem Kurzbefehl zurück zum richtigen Browser-Tab, zur App oder zum sicheren Arbeitsbereich.**

[English](../../README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · **Deutsch** · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md)

> Aktuelle Version: **v1.5.33 (Build 58)**. DMG oder PKG stehen unter [GitHub Releases](https://github.com/hzagaming/ClassGod/releases/latest) bereit.

## Was ist ClassGod?

ClassGod läuft in der macOS-Menüleiste. Speichere ein Browserziel und weise ihm einen globalen Kurzbefehl zu. Die App aktiviert den passenden Tab oder öffnet die gespeicherte URL erneut, wenn der Tab nicht mehr existiert.

Zusätzlich bündelt ClassGod eine lokale Zwischenablage, App-Wechsel, geschützte Browsermodi, native Widgets, Lüftersteuerung, Aktivitätsanzeige, dynamische Hintergrundbilder und ein Berechtigungszentrum. Daten bleiben auf dem Mac, optionale Berechtigungen können übersprungen werden und privilegierte Aktionen benötigen immer eine ausdrückliche Zustimmung.

## Hauptfunktionen

| Modul | Funktion |
| --- | --- |
| **DestinTab** | Speichert Safari-, Chrome- und Edge-Ziele mit Suche, Sortierung, Anheften, Stapelaktionen und eigenen Kurzbefehlen. |
| **SuperSwitch** | Aktiviert oder startet ausgewählte Apps und Ziele über globale Kurzbefehle. |
| **Fake Lock** | Öffnet Browser und URL als Safe Browser oder MapTest Bypass und kann Zurück-/Vorwärtsnavigation getrennt sperren. |
| **Clipo** | Lokaler Zwischenablageverlauf, Schnellplätze, Suche, Anheften, Import/Export und kontrollierte Aufbewahrung. |
| **Permission Center** | Zeigt Live-Status, Zweck, Prüfverfahren und den genauen Systemeinstellungs-Link jeder unterstützten Berechtigung. |
| **Fan Control** | Liest verfügbare Temperatur- und Lüfterdaten mit System-, Max-, Manual- und Custom-Modus; der privilegierte Helper läuft nur nach Freigabe. |
| **Widgets** | 19 native WidgetKit-Widgets für System, Wetter, Notizen, Aufgaben, Dateien, Terminal und App-Start. |
| **Desktop-Werkzeuge** | Activity Monitor, dynamische Hintergrundbilder, Hacker Desktop, Error Hub, BrowserBypasser und AssessPrep-Werkzeuge. |

## Datenschutz

- Keine Analyse, Telemetrie, Konten, ClassGod-Server oder Hintergrund-Uploads.
- Einstellungen, Tabs, Zwischenablageverlauf, Widget-Daten und Medienkonfiguration bleiben lokal.
- Berechtigungszustände werden lokal von macOS gelesen und angezeigt.
- Optionale Berechtigungen können übersprungen werden; betroffene Funktionen fallen sicher zurück.
- Die vollständige Deinstallation entfernt nach zwei Bestätigungen App-Daten, Helper, LaunchDaemon, Installationsbelege und ClassGod-Berechtigungsentscheidungen.

## Voraussetzungen

- macOS 14.0 oder neuer
- Aktuelle Downloads für Apple Silicon (`arm64`)
- Safari, Google Chrome oder Microsoft Edge
- Bedienungshilfen und Automation für den zentralen Browserablauf
- Eine Administratorfreigabe kann für das PKG, den Lüfter-Helper oder die vollständige Deinstallation erforderlich sein

## Installation

Öffne das DMG und ziehe **ClassGod** nach **Applications**, oder führe das PKG aus, um die App unter `/Applications` zu installieren. Der Berechtigungsassistent kann beim ersten Start abgeschlossen oder vorübergehend übersprungen werden.

Die öffentlichen Artefakte sind derzeit ad-hoc signiert und nicht von Apple notarisiert. Beim ersten Start kann **Systemeinstellungen → Datenschutz & Sicherheit → Dennoch öffnen** erforderlich sein. Installiere nur Dateien, deren Quelle und Prüfsumme du verifizieren kannst.

## Schnellstart

1. Starte ClassGod und warte nach der Markenanimation auf das Hauptpanel.
2. Erlaube Bedienungshilfen und Browser-Automation für den Kernablauf. Optionale Berechtigungen können übersprungen werden.
3. Öffne **DestinTab**, speichere den aktuellen Browser-Tab und zeichne einen Kurzbefehl auf.
4. Drücke ihn in einer beliebigen App, um den passenden Tab zu aktivieren oder die gespeicherte URL neu zu öffnen.

Unterstützt werden Buchstaben, Zahlen und F1–F12; registrierbare Modifikatoren sind Command, Option, Control und Shift.

## Berechtigungsgrenzen

macOS-Datenschutzberechtigungen müssen vom Benutzer selbst erteilt werden. DMG, PKG, App, Skript oder privilegierter Helper können TCC-Abfragen nicht stellvertretend bestätigen.

| Stufe | Beispiele | Verhalten |
| --- | --- | --- |
| **Kern** | Bedienungshilfen, Automation | Erkennt und steuert unterstützte Browser. |
| **Empfohlen** | Eingabeüberwachung, Bildschirmaufnahme, Mitteilungen, Festplattenvollzugriff | Aktiviert zugehörige Kurzbefehle, Aufnahmen, Hinweise und lokale Dateifunktionen. |
| **Optional** | Kamera, Mikrofon, Fotos, Standort, Kontakte, Kalender, Erinnerungen, Bluetooth, Spracherkennung, lokales Netzwerk | Wird nur für die jeweilige Funktion angefragt und kann übersprungen werden. |

## Sprachen

Englisch ist Entwicklungs- und Rückfallsprache für nicht übersetzte Texte. Die App-Kataloge enthalten Englisch, vereinfachtes und traditionelles Chinesisch, Japanisch, Koreanisch, Französisch, Deutsch, Spanisch, Portugiesisch und Russisch.

## Aus dem Quellcode bauen

```bash
git clone https://github.com/hzagaming/ClassGod.git
cd ClassGod
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  build
```

Die App verwendet SwiftUI + AppKit + MVVM. Eine Xcode-Buildphase kompiliert und bettet `ClassGodHelper` ein. App Sandbox ist wegen AppleEvents, Bedienungshilfen, Hintergrundsteuerung und des vom Benutzer genehmigten Helpers bewusst deaktiviert.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  test

cd ClassGodHelper && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

## Änderungen und Beiträge

Aktuelle Versionen stehen in [CHANGELOG.md](../../CHANGELOG.md), ältere Einträge in [CHANGELOG_HISTORY.md](../../CHANGELOG_HISTORY.md). Änderungen sollten gezielt bleiben, lokale Datenverarbeitung bewahren, alle sichtbaren Texte lokalisieren und Verhaltensänderungen mit Regressionstests abdecken.

## Verantwortungsvolle Nutzung

ClassGod ist ein Produktivitäts- und Kontextwechselwerkzeug. Verwende es nur auf Geräten, Sitzungen, Prüfungen und Konten, die du kontrollieren darfst. Es erteilt keine Erlaubnis, Richtlinien, Überwachung, Zugriffskontrollen oder akademische Regeln zu umgehen.

## Lizenz

ClassGod steht unter der [MIT-Lizenz](../../LICENSE).
