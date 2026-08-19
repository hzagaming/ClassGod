# ClassGod

**Un outil macOS local de changement de contexte d’urgence. Un raccourci suffit pour revenir au bon onglet, à la bonne app ou à un espace de travail sûr.**

[English](../../README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Français** · [Deutsch](README.de.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md)

> Version actuelle : **v1.5.42 (Build 67)**. Téléchargez le DMG ou le PKG depuis [GitHub Releases](https://github.com/hzagaming/ClassGod/releases/latest).

## À propos de ClassGod

ClassGod réside dans la barre des menus de macOS. Enregistrez une destination de navigateur et associez-lui un raccourci global : l’app active l’onglet correspondant ou rouvre l’URL enregistrée si cet onglet n’existe plus.

Elle réunit aussi un presse-papiers local, un sélecteur d’apps, des modes de navigateur protégé, des widgets natifs, le contrôle des ventilateurs, un moniteur d’activité, des fonds d’écran dynamiques et un centre d’autorisations. Les données restent sur le Mac, les autorisations facultatives peuvent être ignorées et toute opération privilégiée exige l’accord explicite de l’utilisateur.

## Fonctionnalités principales

| Module | Fonction |
| --- | --- |
| **DestinTab** | Enregistre des destinations Safari, Chrome et Edge avec recherche, tri, épinglage, actions groupées et raccourcis individuels. |
| **SuperSwitch** | Active ou lance des apps et des cibles avec des raccourcis globaux. |
| **Fake Lock** | Ouvre un navigateur et une URL en mode Safe Browser ou MapTest Bypass, avec verrouillage indépendant du retour et de l’avance. |
| **Clipo** | Historique local du presse-papiers, emplacements rapides, recherche, épinglage, import/export et rétention contrôlée. |
| **Permission Center** | Affiche l’état en direct, l’usage, la méthode de détection et le réglage système exact de chaque autorisation prise en charge. |
| **Fan Control** | Lit les températures et ventilateurs disponibles, avec les modes System, Max, Manual et Custom ; le Helper privilégié n’est utilisé qu’après approbation. |
| **Widgets** | 19 widgets WidgetKit natifs pour le système, la météo, les notes, les tâches, les fichiers, le terminal et le lancement d’apps. |
| **Outils de bureau** | Activity Monitor, fonds d’écran dynamiques, Hacker Desktop, Error Hub, BrowserBypasser et outils AssessPrep. |

## Confidentialité

- Aucun outil d’analyse, aucune télémétrie, aucun compte, aucun serveur ClassGod et aucun téléversement en arrière-plan.
- Les préférences, onglets, historiques du presse-papiers, données de widgets et réglages multimédias restent en local.
- L’état des autorisations est lu et affiché localement depuis macOS.
- Les autorisations facultatives peuvent être ignorées ; les fonctions concernées se dégradent proprement.
- Après deux confirmations, le programme de désinstallation complète supprime les données, le Helper, le LaunchDaemon, les reçus et les décisions d’autorisation propres à ClassGod.

## Configuration requise

- macOS 14.0 ou version ultérieure
- Builds téléchargeables actuels pour Apple Silicon (`arm64`)
- Safari, Google Chrome ou Microsoft Edge
- Accessibilité et Automatisation pour le flux principal de navigation
- Une approbation administrateur peut être requise pour le PKG, le Helper de ventilation ou une désinstallation complète

## Installation

Ouvrez le DMG et glissez **ClassGod** dans **Applications**, ou exécutez le PKG pour installer l’app dans `/Applications`. Au premier démarrage, le guide des autorisations peut être terminé ou temporairement ignoré.

Les fichiers publics actuels utilisent une signature ad-hoc et ne sont pas notariés par Apple. Au premier lancement, macOS peut demander **Réglages Système → Confidentialité et sécurité → Ouvrir quand même**. N’installez que des fichiers dont vous pouvez vérifier la source et la somme de contrôle.

## Démarrage rapide

1. Lancez ClassGod et attendez l’animation de marque avant l’ouverture du panneau principal.
2. Autorisez Accessibilité et l’Automatisation du navigateur pour utiliser la fonction principale. Les autorisations facultatives peuvent être ignorées.
3. Ouvrez **DestinTab**, enregistrez l’onglet actuel et définissez un raccourci.
4. Utilisez ce raccourci depuis n’importe quelle app pour activer l’onglet ou rouvrir l’URL enregistrée.

Les touches prises en charge sont les lettres, les chiffres et F1–F12. Les modificateurs enregistrables sont Command, Option, Control et Shift.

## Limites des autorisations

Les autorisations de confidentialité macOS doivent être accordées par l’utilisateur. Aucun DMG, PKG, app, script ou Helper privilégié ne peut accepter les demandes TCC à sa place.

| Niveau | Exemples | Comportement |
| --- | --- | --- |
| **Essentiel** | Accessibilité, Automatisation | Détection et contrôle des navigateurs pris en charge. |
| **Recommandé** | Surveillance de la saisie, enregistrement de l’écran, notifications, accès complet au disque | Active les raccourcis, captures, alertes et traitements de fichiers associés. |
| **Facultatif** | Caméra, micro, photos, localisation, contacts, calendrier, rappels, Bluetooth, reconnaissance vocale, réseau local | Demandé uniquement par la fonction concernée et peut être ignoré. |

## Langues

L’anglais est la langue de développement et de repli. L’anglais et le chinois simplifié couvrent largement l’app ; les autres langues sont traduites progressivement et se replient sur l’anglais lorsqu’une traduction manque.

## Compiler depuis les sources

```bash
git clone https://github.com/hzagaming/ClassGod.git
cd ClassGod
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  build
```

L’app utilise SwiftUI + AppKit + MVVM. Une phase Xcode compile et intègre `ClassGodHelper`. App Sandbox est volontairement désactivé en raison d’AppleEvents, de l’Accessibilité, du contrôleur de fond d’écran et du Helper approuvé par l’utilisateur.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  test

cd ClassGodHelper && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

## Mises à jour et contributions

Consultez [CHANGELOG.md](../../CHANGELOG.md) pour les versions actuelles et [CHANGELOG_HISTORY.md](../../CHANGELOG_HISTORY.md) pour l’historique. Gardez les modifications ciblées, préservez le traitement local, traduisez chaque chaîne visible et ajoutez des tests de régression pour tout changement de comportement.

## Utilisation responsable

ClassGod est un outil de productivité et de changement de contexte. Utilisez-le uniquement sur les appareils, sessions, évaluations et comptes que vous êtes autorisé à contrôler. Il n’autorise pas à contourner les politiques, la surveillance, les contrôles d’accès ou les règles académiques.

## Licence

ClassGod est distribué sous [licence MIT](../../LICENSE).
