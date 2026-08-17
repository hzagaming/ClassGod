# ClassGod

**Una herramienta local de macOS para cambiar de contexto en un instante. Un atajo te devuelve a la pestaña, app o espacio de trabajo seguro correcto.**

[English](../../README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · **Español** · [Português](README.pt.md) · [Русский](README.ru.md)

> Versión actual: **v1.5.36 (Build 61)**. Descarga el DMG o PKG desde [GitHub Releases](https://github.com/hzagaming/ClassGod/releases/latest).

## Qué es ClassGod

ClassGod vive en la barra de menús de macOS. Guarda un destino del navegador y asígnale un atajo global: la app activa la pestaña coincidente o vuelve a abrir la URL guardada si la pestaña ya no existe.

También integra portapapeles local, cambio de apps, modos de navegador protegido, widgets nativos, control de ventiladores, monitor de actividad, fondos dinámicos y un centro de permisos. Los datos permanecen en el Mac, los permisos opcionales se pueden omitir y toda operación privilegiada requiere aprobación explícita.

## Funciones principales

| Módulo | Función |
| --- | --- |
| **DestinTab** | Guarda destinos de Safari, Chrome y Edge con búsqueda, orden, fijado, acciones por lotes y atajos individuales. |
| **SuperSwitch** | Activa o inicia apps y objetivos seleccionados mediante atajos globales. |
| **Fake Lock** | Abre un navegador y una URL en Safe Browser o MapTest Bypass, con bloqueo independiente de navegación atrás/adelante. |
| **Clipo** | Historial local del portapapeles, espacios rápidos, búsqueda, fijado, importación/exportación y retención controlada. |
| **Permission Center** | Muestra estado en vivo, propósito, método de detección y enlace exacto de ajustes para cada permiso compatible. |
| **Fan Control** | Lee temperaturas y ventiladores disponibles con modos System, Max, Manual y Custom; el Helper privilegiado solo se usa tras aprobarlo. |
| **Widgets** | 19 widgets WidgetKit nativos para sistema, tiempo, notas, tareas, archivos, terminal y lanzamiento de apps. |
| **Herramientas de escritorio** | Activity Monitor, fondos dinámicos, Hacker Desktop, Error Hub, BrowserBypasser y herramientas AssessPrep. |

## Privacidad

- Sin analítica, telemetría, cuentas, backend de ClassGod ni cargas en segundo plano.
- Preferencias, pestañas, historial del portapapeles, datos de widgets y ajustes multimedia permanecen en local.
- El estado de los permisos se consulta y muestra localmente desde macOS.
- Los permisos opcionales se pueden omitir; las funciones afectadas se degradan de forma segura.
- Tras dos confirmaciones, el desinstalador completo elimina datos, Helper, LaunchDaemon, recibos y decisiones de permisos de ClassGod.

## Requisitos

- macOS 14.0 o posterior
- Descargas actuales para Apple Silicon (`arm64`)
- Safari, Google Chrome o Microsoft Edge
- Accesibilidad y Automatización para el flujo principal del navegador
- Puede requerirse aprobación de administrador para el PKG, el Helper de ventiladores o una desinstalación completa

## Instalación

Abre el DMG y arrastra **ClassGod** a **Applications**, o ejecuta el PKG para instalar la app en `/Applications`. En el primer inicio puedes completar o aplazar temporalmente la guía de permisos.

Los artefactos públicos actuales usan firma ad-hoc y no están notarizados por Apple. En el primer inicio puede ser necesario ir a **Ajustes del Sistema → Privacidad y seguridad → Abrir igualmente**. Instala únicamente archivos cuyo origen y suma de verificación puedas confirmar.

## Inicio rápido

1. Inicia ClassGod y espera a que la animación de marca abra el panel principal.
2. Autoriza Accesibilidad y Automatización del navegador para el flujo principal. Puedes omitir los permisos opcionales.
3. Abre **DestinTab**, guarda la pestaña actual y graba un atajo.
4. Pulsa el atajo desde cualquier app para activar la pestaña coincidente o volver a abrir la URL guardada.

Se admiten letras, números y F1–F12; los modificadores registrables son Command, Option, Control y Shift.

## Límites de permisos

Los permisos de privacidad de macOS deben ser concedidos por el usuario. Ningún DMG, PKG, app, script o Helper privilegiado puede aceptar solicitudes TCC en su nombre.

| Nivel | Ejemplos | Comportamiento |
| --- | --- | --- |
| **Esencial** | Accesibilidad, Automatización | Detecta y controla los navegadores compatibles. |
| **Recomendado** | Monitorización de entrada, grabación de pantalla, notificaciones, acceso total al disco | Habilita atajos, capturas, avisos y flujos de archivos relacionados. |
| **Opcional** | Cámara, micrófono, fotos, ubicación, contactos, calendario, recordatorios, Bluetooth, reconocimiento de voz, red local | Solo se solicita para la función correspondiente y se puede omitir. |

## Idiomas

El inglés es el idioma de desarrollo y de respaldo. El inglés y el chino simplificado cubren ampliamente la app; los demás idiomas se traducen de forma progresiva y recurren al inglés donde aún no hay traducción.

## Compilar desde el código fuente

```bash
git clone https://github.com/hzagaming/ClassGod.git
cd ClassGod
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  build
```

La app usa SwiftUI + AppKit + MVVM. Una fase de Xcode compila e integra `ClassGodHelper`. App Sandbox está desactivado intencionadamente por AppleEvents, Accesibilidad, el controlador de fondos y el Helper aprobado por el usuario.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  test

cd ClassGodHelper && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

## Cambios y contribuciones

Consulta [CHANGELOG.md](../../CHANGELOG.md) para versiones actuales y [CHANGELOG_HISTORY.md](../../CHANGELOG_HISTORY.md) para el historial anterior. Mantén los cambios enfocados, conserva el procesamiento local, localiza cada texto visible y añade pruebas de regresión para cambios de comportamiento.

## Uso responsable

ClassGod es una herramienta de productividad y cambio de contexto. Úsala solo en dispositivos, sesiones, evaluaciones y cuentas que estés autorizado a controlar. No concede permiso para eludir políticas, supervisión, controles de acceso o normas académicas.

## Licencia

ClassGod se distribuye bajo la [licencia MIT](../../LICENSE).
