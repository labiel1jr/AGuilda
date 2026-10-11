# TDD — A Guilda (Documento Técnico)

**Versão:** 0.9
**Engine:** Godot 4.7 (GDScript), renderizador `gl_compatibility`
**Resolução base:** 1280×720, `stretch/mode = canvas_items`, `aspect = expand`
**Documentos relacionados:** [GDD](GDD.md) · [Balanceamento](BALANCEAMENTO.md) · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md)

Este documento descreve **como o jogo está construído hoje**: módulos, fluxo de dados, formatos, save, testes, build Android e pipeline de arte. A dívida técnica conhecida está na seção 10.

---

## 1. Princípios

1. **Regra separada da UI.** Toda regra de jogo fica em `scripts/core/`. A UI (`scripts/ui/`) só lê o estado e chama métodos; não calcula resultado.
2. **Data-driven.** Heróis, missões, capítulos, eventos, itens, classes, rotas e traços vivem em `data/*.json`. Conteúdo novo não exige código.
3. **UI construída por código.** Há uma única cena (`scenes/main.tscn`); as telas são montadas em `main.gd` com helpers (`_panel`, `_label`, `_button`...).
4. **Estado serializável.** Todo estado mutável é feito de `Dictionary`, `Array`, `int`, `float`, `String` e `Color`, para salvar com `var_to_str`.
5. **Testável sem janela.** As regras rodam headless (`sim_test.gd`) e a UI é percorrida por um smoke test.

---

## 2. Estrutura de Pastas

| Caminho | Conteúdo |
|---|---|
| `project.godot` | Configuração; autoload `GameState` |
| `scenes/main.tscn` | Cena única com `scripts/ui/main.gd` |
| `scripts/core/game_state.gd` | Autoload `GameState` (classe `GuildState`): estado global, `new_game`, `end_day` e a API pública que repassa para os sistemas |
| `scripts/systems/relationship_system.gd` | `Relations`: afinidade, faixas, vínculos, Ações de Vínculo, descrições, treino, neglect |
| `scripts/systems/mission_system.gd` | `Missions`: slots, mural, prazos, disponibilidade, requisitos, despacho, narração |
| `scripts/systems/chapter_system.gd` | `Chapters`: atos, capítulos, recrutas, objetivo, encerramento |
| `scripts/systems/economy_system.gd` | `Economy`: melhorias e recompensa |
| `scripts/systems/departure_system.gd` | `Departures`: ultimato, promessas, saída, Irmandade |
| `scripts/systems/backstage_system.gd` | `Backstage`: sorteio e escolhas dos bastidores |
| `scripts/systems/save_system.gd` | `SaveSystem`: salvar e carregar |
| `scripts/systems/ending_system.gd` | `Endings`: epílogo |
| `scripts/systems/town_system.gd` | `Town`: Fama no povo (por herói) e Estima da cidade (guilda); preços, recompensa, termo Povo do score, efeito das missões vistas pelo povo |
| `scripts/systems/arc_system.gd` | `Arcs`: missões de arco (`requires_flag` bloqueia até a flag, `forbids_flag` cancela o ramo não escolhido, `arc_delay`), efeitos `flags`/`decision` de missão e decisões de arco (`data/decisions.json`: falas dos heróis, escolhas com flags, moral/estresse, ouro, estima). Rota fixa da expedição: `route.fixed` em missions.json |
| `scripts/systems/result_story.gd` | `ResultStory`: o porquê do resultado em frases — escolhe até 3 momentos pelo peso no score (pares, Ações de Vínculo, destaque, cansaço, condições, poderes, rota, sorte), com o estado de antes das consequências; variação determinística, sem usar o rng |
| `scripts/core/score_calc.gd` | `ScoreCalc` (estático): fórmula do score e limiares |
| `scripts/core/hero_rpg.gd` | `HeroRPG` (estático): XP, níveis, efeitos, equipamento, magias, saque, mercado |
| `scripts/core/expedition.gd` | `Expedition` (estático): grafo da rota, nós, testes d20, efeitos, modificador da rota |
| `scripts/core/mind.gd` | `Mind` (estático): estresse, ponto de ruptura, condições, traços, termo Mente |
| `scripts/ui/main.gd` | Cena principal (classe `GuildUI`): estado da interface, cores e repasses para as telas |
| `scripts/ui/screens/*.gd` | Telas (estáticas, recebem `ui: GuildUI`): `HubScreen`, `PartyScreen`, `ExpeditionScreen`, `ResultScreen`, `GuildScreens`, `ItemScreens`, `StoryScreens`, `TitleScreen` |
| `scripts/ui/components/ui_kit.gd` | `UIKit`: peças básicas sem estado (rótulo, parágrafo, painel, botão, ícone, cores de estado) |
| `scripts/ui/components/widgets.gd` | `Widgets`: retrato, cabeçalho de herói, cartaz de inimigo, chip de estresse |
| `scripts/ui/components/dice_throw.gd` | `DiceThrow`: d20 arremessado sobre o mapa nos testes (voo, quiques, parada na face, destaque de sucesso/falha/crítico); usa os sprites de `art/dice/` quando existirem, senão desenha por código |
| `scripts/ui/components/pin.gd` | Prego dos cartazes do quadro de avisos (até chegar a arte) |
| `scripts/ui/components/moments.gd` | `Moments`: cena de ruptura e de saída por cima da tela atual |
| `scripts/ui/magic_map.gd` | Mapa Mágico: desenho do pergaminho, grafo clicável, névoa, marcadores |
| `scripts/ui/guild_book.gd` | Livro da Guilda (ficha em duas páginas) |
| `scripts/ui/portrait.gd` | Retrato procedural (fallback quando não há imagem) |
| `scripts/ui/juice.gd` | `Juice` (estático): game juice sóbrio — pop, fade, piscar, tremor, clarão, contador, texto voando, máquina de escrever; opção "Reduzir movimento" em `user://settings.cfg` |
| `scripts/ui/wax_seal.gd` | Selo de cera do despacho desenhado por código |
| `data/*.json` | Conteúdo (seção 4) |
| `art/` | Retratos, cartazes, título, peças de mapa, especificações e ferramentas |
| `tests/` | Testes headless e geradores de screenshot |
| `docs/` | Documentação |

---

## 3. Arquitetura

```
             ┌────────────── data/*.json ──────────────┐
             ▼                                         │
      GameState (autoload, estado)  ◄── save/load (user://saves)
        │   ▲        ▲        ▲        ▲
        │   │        │        │        │
   ScoreCalc HeroRPG Expedition  Mind   (módulos estáticos: func f(gs, ...))
        ▲
        │ lê estado / chama métodos
   main.gd ── magic_map.gd ── guild_book.gd ── portrait.gd   (UI)
```

- Os módulos estáticos recebem o `GameState` como primeiro parâmetro (`gs`) e não guardam estado próprio. Isso mantém um só lugar de verdade e simplifica o save.
- `GameState` guarda o estado e orquestra (`new_game`, `end_day`). As regras ficam nos sistemas de `scripts/systems/` (um por assunto) e nos módulos de `scripts/core/` (`ScoreCalc`, `HeroRPG`, `Expedition`, `Mind`). A seção "API pública" do `GameState` repassa para os sistemas, para a UI e os testes continuarem chamando `gs.<função>`; código novo de regra pode chamar o sistema direto (`Relations.pair_value(gs, a, b)`).
- Nos sistemas, o estado é tipado (`gs: GuildState`) e as constantes são lidas pela classe (`GuildState.BANDS`).

### 3.1 Fluxo de uma missão

```
main._on_dispatch(m)
  └─ Expedition.start(gs, m, party, prepared)      → gs.expedition = {grafo, provisões, ...}
main.show_map(m)                                   → MagicMap.setup(..., gs.expedition)
  loop:
    MagicMap.node_chosen(pos) → main._on_node_chosen → MagicMap.move_to(pos)
    MagicMap.arrived(pos)     → Expedition.enter(gs, pos)  → {event | shop | boss}
    evento: main._show_call   → Expedition.choose(gs, opção) → teste d20 + Expedition.apply(fx)
                                                               └─ Mind.add_stress / gain_trait ...
main._on_face_boss()
  └─ Expedition.finish(gs)
       └─ gs.dispatch(m, party, prepared, route)
            ├─ ScoreCalc.compute(..., route.mod)   → Mind.score_bonus, HeroRPG.power_bonus ...
            ├─ fadiga, PV, moral, reputação, ouro, saque da rota, afinidade, flags
            ├─ HeroRPG.after_mission (XP, saque, níveis)
            └─ Mind.after_mission (estresse, virtude se gasta, traços)
main.show_result(res) → eventos de vínculo / subidas de nível → hub
```

`gs.dispatch` continua aceitando chamada direta sem rota (`route = {}`), usada pelos testes.

### 3.2 Fluxo de um dia

`GameState.end_day()`: pedidos de descanso ignorados → descanso/recuperação (+ `Mind.end_day`) → heróis ainda na estrada continuam ocupados (`away_until`) → missões expiram → neglect → saídas (ultimatos e promessas) → vira o dia → fecha capítulo se acabou → sorteia bastidores → novos pedidos de descanso e ultimatos → novos pedidos no mural. A UI salva em `auto` depois.

---

## 4. Dados (`data/`)

Cada JSON tem um campo `_doc` explicando o formato.

| Arquivo | Conteúdo |
|---|---|
| `heroes.json` | Heróis (atributos, classe, raça, nível, PV, proficiências, personalidade, retrato, magias, capítulo de recrutamento) e grade de afinidade inicial `affinity[a][b]` |
| `missions.json` | Missões: tipo, risco, bioma, atributos, dia de chegada, prazo, tags, oculto, textos por resultado, efeitos por resultado, inimigos, pesos de rota opcionais |
| `chapters.json` | Atos e capítulos: duração, missões, objetivo, flags, textos de abertura por flag, encerramentos |
| `backstage.json` | Eventos de bastidor: condições (afinidade, capítulo, flag), texto, escolhas e efeitos |
| `upgrades.json` | Ouro inicial, recompensa por risco, estima inicial (`town`) e melhorias (custo, reputação, `hidden`, `effects` que valem para todos os heróis) |
| `classes.json` | XP, níveis, classes, magias e talentos (tipos de efeito) |
| `items.json` | Itens, tabelas de saque por risco, chance por resultado |
| `route.json` | Mapa de expedição: camadas, provisões, CD por risco, tipos de nó, pesos por bioma, eventos e efeitos |
| `traits.json` | Estresse, aflições, virtudes, traços |
| `result_story.json` | Textos e imagens dos momentos do resultado, por tipo e por par |
| `narration.json` | Frases de narração do mapa |
| `book.json` | Seções trancadas do Livro |
| `ultimatum.json` | Texto e escolhas do ultimato |
| `endings.json` | Finais, desfechos por herói e por vínculo |

### 4.1 Sistema de efeitos

Itens, talentos, magias preparadas, traços e condições usam a mesma lista `effects: [{type, ...}]`, reunida por `HeroRPG.hero_effects` (que inclui `Mind.effects`). Tipos: `attr`, `mission_type`, `score`, `affinity`, `damage_reduction`, `fatigue_resist`, `heal_after`, `morale_after`, `xp_pct`, `reveal_hidden`, `mind`, `biome`, `stress_resist`. `"party": true` faz o efeito valer para o grupo.

### 4.2 Efeitos da rota (`route.json`)

`gold`, `provisions`, `hp`, `hp_one`, `bonus`, `item` (`"loot"` sorteia pela tabela do risco), `days`, `affinity`, `stress`, `stress_one`, `guild_gold`, `lose_item` (slot), `trait` (`"pos"`, `"neg"` ou id). Opções podem ter `test {attr, dc}` com ramos `ok`/`fail` e `requires {guild_gold, gold, provisions}`.

### 4.3 Armadilha conhecida

JSON não distingue `int` de `float`: números lidos viram `float`. Converter com `int()` ao usar como índice, contador ou comparação exata.

---

## 5. Estado e Save

- Estado mutável listado em `GameState.SAVE_KEYS` (heróis, afinidade, vínculos, missões, dia, reputação, ouro, capítulo, flags, bastidores, ultimatos, inventário...).
- `save_game(slot)` grava `{version, meta, rng_state, state}` com `var_to_str` em `user://saves/save_<slot>.sav`. `var_to_str` preserva `int` e `Color`, que o JSON perderia.
- `load_game(slot)` chama `new_game()` para recarregar os JSON de conteúdo e só então sobrepõe o estado. Por isso correções de texto e de dados valem para saves antigos.
- **Migração:** campos novos de herói são garantidos ao carregar (`Mind.ensure`: `stress`, `condition`, `traits`, `away_until`...). `SAVE_VERSION` só muda se o formato quebrar.
- Espaços: `auto` (fim de cada dia) e `1`, `2`, `3`.
- A expedição em andamento (`gs.expedition`) **não é salva**: só se salva no hub.

---

## 6. UI

- Cada tela é um módulo estático em `ui/screens/` que monta a tela em `ui.root` (um `VBoxContainer`) depois de `ui._clear()`. O estado da interface (party em montagem, mapa aberto, momentos) fica na `main` (`GuildUI`). Navegação por chamadas diretas (`ui.show_hub()`, `PartyScreen.show_party(ui, m)`...). Peças sem estado vêm do `UIKit`.
- **Mapa Mágico** (`magic_map.gd`): `Control` com `_draw()` próprio. Recebe a expedição por referência, emite `node_chosen(pos)` e `arrived(pos)`, mostra tooltip por nó (`_get_tooltip`). Peças de `art/MapParts/<tipo>/` são carregadas listando a pasta (funciona no editor e exportado, removendo o sufixo `.import`).
- **Game juice:** só visual, nunca muda o estado. Momentos de personagem são enfileirados pelo núcleo em `gs.pending_moments` (ruptura em `Mind`, saída em `GameState._depart`; não salvos) e encenados por `main._play_moments()` no hub, no mapa e no resultado.
- **Miniaturas:** o Mapa Mágico desenha `art/tokens/<id>_parado.png` com sombra e balão "!" sobre quem chama; sem a arte, um círculo com a inicial.
- **Dado:** `DiceThrow` (componente) arremessa o d20 sobre o mapa; usa `art/dice/d20_face_NN.png` e, quando existirem, a tira `d20_rolando.png`.
- **Retratos:** `h.portrait` aponta para `res://art/portraits/<id>.png`; sem imagem, usa `portrait.gd`.
- **Cartazes:** `res://art/enemies/<id>.png`, na ordem de `mission.enemies` (chefe primeiro; o segundo vira o guarda do alvo no mapa).

---

## 7. Testes

Rodar com o executável de console do Godot:

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/sim_test.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/ui_smoke.gd
Godot_v4.7.2-stable_win64_console.exe --path . -s res://tests/screenshots.gd
Godot_v4.7.2-stable_win64_console.exe --path . -s res://tests/map_biomes.gd
```

| Teste | O que cobre |
|---|---|
| `sim_test.gd` | Calibragem do score, regras de afinidade, neglect, bastidores, capítulos, melhorias, RPG, Ato 2, save, finais, expedição (grafo conexo em todas as missões, efeitos, dado, fome, saque, atraso), estresse/condições/traços, e **150 partidas aleatórias** (que também percorrem as expedições) com estatísticas |
| `ui_smoke.gd` | Abre todas as telas, percorre uma expedição pela UI, salva e carrega; falha em qualquer erro de script |
| `screenshots.gd` | Gera as imagens de `docs/img` (precisa de janela) |
| `map_biomes.gd` | Uma imagem do mapa por bioma |
| `equivalencia.gd` | Partida roteirizada com semente fixa: imprime um hash do estado a cada dia. Rodar antes e depois de uma refatoração e comparar a saída prova que o comportamento não mudou |
| `juice_shots.gd` | Imagens dos momentos de juice (selo, dado, resultado, ruptura) |

Saída esperada: `RESULTADO: OK (0 falha(s))` e `UI SMOKE OK`. Depois de criar um `class_name` novo, rodar `--import` uma vez para o Godot registrá-lo.

---

## 8. Build Android

- Preset `Android` em `export_presets.cfg`: pacote `com.labiel1jr.aguilda`, arm64, paisagem, tela cheia, ícones adaptativos de `art/icon/`. Fora do APK: `tests/`, `docs/`, `art/specs/`, `art/tools/`, `art/ArtesEmGeral/` e os originais das imagens.
- Requisitos instalados: templates de exportação do Godot 4.7.2, JDK 17, Android SDK (build-tools 35, platform-tools) e o keystore de debug do Godot (configurados nas Configurações do Editor).
- Gerar (debug, para teste):

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug "Android" export/android/AGuilda.apk
```

- A pasta `export/` está no `.gitignore`: **APKs não vão para o Git** (deixam o repositório pesado para sempre). Renomeie para `AGuilda-v<versão>-debug.apk` e copie para a pasta do Google Drive do projeto: [https://drive.google.com/drive/folders/1H7azjgFBsBbRIVLfLPu_LGSzMqcmbnkc?usp=drive_link](https://drive.google.com/drive/folders/1H7azjgFBsBbRIVLfLPu_LGSzMqcmbnkc?usp=drive_link).
- Release para loja: exige um keystore próprio de release (não versionado) configurado no preset.

## 9. Pipeline de Arte

- Especificações (JSON) para gerar imagens: `art/specs/` (heróis, wallpaper) e `art/specs/inimigos/` (com `_indice.json` ligando inimigos a missões).
- Cenário, objetos, interface, fundos e efeitos (sem personagens): `art/specs/cenario/` — `_estilo_cenario.json` (famílias de estilo, regras, modelo para assets novos), `_indice.json` (todos os assets com prioridade, status e destino) e um arquivo por categoria. O ícone do jogo (Android e Windows) está em `art/specs/cenario/icone.json`; a arte do Livro em `livro.json`; o pergaminho do mapa em `mapa_pergaminho.json`; as miniaturas dos heróis no mapa em `art/specs/tokens_herois.json`. Os artistas entregam **JPG com fundo branco puro** em `<pasta do destino>/originais/`; a ferramenta remove o branco e gera o PNG no destino.
- Originais em `art/portraits/originais/`, `art/enemies/originais/`, `art/geralimagem/originais/`.
- `python art/tools/preparar_assets.py`: artes de cenário, itens, livro, miniaturas e ícone entregues em `art/ArtesEmGeral/<id>.jpg` (pasta com `.gdignore`) → PNG no `destino` de cada asset do `_indice.json` (remove o branco a partir das bordas, trata buracos fechados, recorta, reduz; imagens cheias como o livro aberto e o fundo do ícone não são recortadas). `python art/tools/marcar_status.py` atualiza o status de produção no índice e nos arquivos de categoria.
- `python art/tools/preparar_retratos.py` e `python art/tools/preparar_inimigos.py`: leem o formato pelo conteúdo (há JPEG com extensão `.png`), removem o fundo por *flood fill* a partir das bordas (fundo branco, xadrez falso, madeira ou pedra, amostrado na borda), fecham rasgos com fechamento morfológico e salvam PNG RGBA 256×256.

---

## 10. Dívida Técnica e Plano de Refatoração

| Ponto | Situação | Plano |
|---|---|---|
| ~~`game_state.gd` (~1.100 linhas)~~ | **Feito (2026-10-10):** separado em 8 sistemas em `scripts/systems/`; o `GameState` ficou com ~550 linhas (estado, orquestração e repasses). Provado sem mudança de comportamento por `tests/equivalencia.gd` | Futuro: a UI chamar os sistemas direto e os repasses diminuírem |
| ~~`main.gd` (~1.900 linhas)~~ | **Feito (2026-10-10):** 8 telas em `ui/screens/` e 3 componentes em `ui/components/`; a `main` ficou com ~300 linhas (estado da UI e repasses). Lógica provada idêntica por `equivalencia.gd`; telas comparadas por screenshot | Futuro: botões e sinais chamarem as telas direto e os repasses diminuírem |
| Pasta `systems/` | Os sistemas extraídos do `GameState` estão em `systems/`; `Expedition`, `Mind`, `HeroRPG` e `ScoreCalc` continuam em `core/` | Mover os quatro para `systems/` numa próxima limpeza (só caminho de arquivo; os `class_name` não mudam) |
| Expedição não salva | Sair no meio do mapa perde o progresso da rota | Salvar `gs.expedition` se houver menu dentro do mapa |
| Formato de texto do resultado | Mostra a soma inteira do score | Explicação narrativa com números como detalhe opcional (P1) |

A refatoração deve manter `sim_test.gd` e `ui_smoke.gd` verdes a cada passo, sem mudar comportamento.
