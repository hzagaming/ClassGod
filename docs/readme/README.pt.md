# ClassGod

**Uma ferramenta macOS local para troca emergencial de contexto. Um atalho leva você de volta à aba, ao app ou ao espaço de trabalho seguro correto.**

[English](../../README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · **Português** · [Русский](README.ru.md)

> Versão atual: **v1.5.37 (Build 62)**. Baixe o DMG ou PKG em [GitHub Releases](https://github.com/hzagaming/ClassGod/releases/latest).

## O que é o ClassGod

O ClassGod fica na barra de menus do macOS. Salve um destino do navegador e associe um atalho global: o app ativa a aba correspondente ou reabre a URL salva quando a aba não existe mais.

Ele também reúne área de transferência local, troca de apps, modos de navegador protegido, widgets nativos, controle de ventoinhas, monitor de atividade, papéis de parede dinâmicos e central de permissões. Os dados permanecem no Mac, permissões opcionais podem ser ignoradas e toda operação privilegiada exige aprovação explícita.

## Principais recursos

| Módulo | Recurso |
| --- | --- |
| **DestinTab** | Salva destinos do Safari, Chrome e Edge com pesquisa, ordenação, fixação, ações em lote e atalhos individuais. |
| **SuperSwitch** | Ativa ou inicia apps e alvos selecionados por atalhos globais. |
| **Fake Lock** | Abre navegador e URL em Safe Browser ou MapTest Bypass, com bloqueio separado para voltar e avançar. |
| **Clipo** | Histórico local da área de transferência, slots rápidos, pesquisa, fixação, importação/exportação e retenção controlada. |
| **Permission Center** | Exibe estado ao vivo, finalidade, método de detecção e link exato dos ajustes de cada permissão suportada. |
| **Fan Control** | Lê temperaturas e ventoinhas disponíveis com modos System, Max, Manual e Custom; o Helper privilegiado só é usado após aprovação. |
| **Widgets** | 19 widgets WidgetKit nativos para sistema, clima, notas, tarefas, arquivos, terminal e abertura de apps. |
| **Ferramentas de desktop** | Activity Monitor, papéis de parede dinâmicos, Hacker Desktop, Error Hub, BrowserBypasser e ferramentas AssessPrep. |

## Privacidade

- Sem análise, telemetria, contas, backend do ClassGod ou upload em segundo plano.
- Preferências, abas, histórico da área de transferência, dados de widgets e configurações de mídia ficam locais.
- O estado das permissões é lido e exibido localmente pelo macOS.
- Permissões opcionais podem ser ignoradas; os recursos afetados recuam com segurança.
- Após duas confirmações, o desinstalador completo remove dados, Helper, LaunchDaemon, recibos e decisões de permissão do ClassGod.

## Requisitos

- macOS 14.0 ou posterior
- Downloads atuais para Apple Silicon (`arm64`)
- Safari, Google Chrome ou Microsoft Edge
- Acessibilidade e Automação para o fluxo principal do navegador
- Pode ser necessária aprovação de administrador para o PKG, o Helper das ventoinhas ou a desinstalação completa

## Instalação

Abra o DMG e arraste **ClassGod** para **Applications**, ou execute o PKG para instalar o app em `/Applications`. Na primeira abertura, o guia de permissões pode ser concluído ou temporariamente ignorado.

Os artefatos públicos atuais usam assinatura ad-hoc e não têm notarização da Apple. Na primeira execução, talvez seja preciso acessar **Ajustes do Sistema → Privacidade e Segurança → Abrir Mesmo Assim**. Instale apenas arquivos cuja origem e soma de verificação possam ser confirmadas.

## Início rápido

1. Inicie o ClassGod e aguarde a animação da marca abrir o painel principal.
2. Autorize Acessibilidade e Automação do navegador para o fluxo principal. Permissões opcionais podem ser ignoradas.
3. Abra **DestinTab**, salve a aba atual e grave um atalho.
4. Pressione o atalho em qualquer app para ativar a aba correspondente ou reabrir a URL salva.

São aceitos letras, números e F1–F12; os modificadores registráveis são Command, Option, Control e Shift.

## Limites de permissões

As permissões de privacidade do macOS devem ser concedidas pelo usuário. DMG, PKG, app, script ou Helper privilegiado não podem aceitar solicitações TCC em nome do usuário.

| Nível | Exemplos | Comportamento |
| --- | --- | --- |
| **Essencial** | Acessibilidade, Automação | Detecta e controla navegadores suportados. |
| **Recomendado** | Monitoramento de entrada, gravação da tela, notificações, acesso total ao disco | Ativa atalhos, capturas, alertas e fluxos de arquivos relacionados. |
| **Opcional** | Câmera, microfone, fotos, localização, contatos, calendário, lembretes, Bluetooth, reconhecimento de voz, rede local | Solicitado apenas pelo recurso correspondente e pode ser ignorado. |

## Idiomas

O inglês é o idioma de desenvolvimento e a alternativa padrão. O inglês e o chinês simplificado cobrem amplamente o app; os demais idiomas são traduzidos progressivamente e usam inglês onde ainda não há tradução.

## Compilar a partir do código-fonte

```bash
git clone https://github.com/hzagaming/ClassGod.git
cd ClassGod
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  build
```

O app usa SwiftUI + AppKit + MVVM. Uma fase do Xcode compila e incorpora `ClassGodHelper`. App Sandbox fica desativado intencionalmente por causa de AppleEvents, Acessibilidade, controle de papel de parede e o Helper aprovado pelo usuário.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ClassGod/ClassGod.xcodeproj \
  -scheme ClassGod \
  -destination 'platform=macOS' \
  test

cd ClassGodHelper && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

## Atualizações e contribuições

Consulte [CHANGELOG.md](../../CHANGELOG.md) para versões atuais e [CHANGELOG_HISTORY.md](../../CHANGELOG_HISTORY.md) para o histórico. Mantenha as alterações focadas, preserve o processamento local, traduza todo texto visível e adicione testes de regressão para mudanças de comportamento.

## Uso responsável

ClassGod é uma ferramenta de produtividade e troca de contexto. Use apenas em dispositivos, sessões, avaliações e contas que você tenha autorização para controlar. Ela não concede permissão para contornar políticas, monitoramento, controles de acesso ou regras acadêmicas.

## Licença

ClassGod é distribuído sob a [licença MIT](../../LICENSE).
