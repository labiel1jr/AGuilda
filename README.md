# A Guilda

> *"Quem você envia define quem eles se tornam."*

Jogo de gerenciamento narrativo em fantasia medieval, inspirado no loop de despacho de **Dispatch** (AdHoc Studio). Você não é o herói — é o(a) **Mestre(a) de Despacho** da decadente Guilda do Corvo Cinzento, e decide **quem vai, com quem, e como**.

O jogo não é sobre combate. É sobre gestão de gente complicada com poder de matar dragões: egos, rivalidades, dívidas de honra e vínculos que mudam conforme você monta as parties.

![Tela de título](docs/img/18_titulo.png)

![Tela da Guilda](docs/img/1_hub.png)

## Como se joga

O jogo é dividido em **atos** e **capítulos**. Cada capítulo abre com uma cena, dura alguns dias e tem um objetivo; o resultado muda o texto dos capítulos seguintes. São dois atos, com dois capítulos cada.

1. **Mural de Quests** — pedidos chegam a cada dia, com risco, prazo e atributos exigidos.
2. **Montagem de Party** — escolha de 1 a 4 aventureiros. O preview mostra a afinidade entre eles, mas nunca o resultado.
3. **Despacho** — confirme com o Selo de Cera.
4. **Mapa Mágico (expedição)** — a missão vira um mapa de caminhos com bifurcações. Quando o grupo chega a uma encruzilhada, um herói chama pelo Mapa Mágico e você escolhe o próximo ponto: combate, tesouro, mercador, acampamento, encontro ou atalho. Cada escolha muda a preparação contra o alvo, o saque, os ferimentos, a comida e os dias de viagem.
5. **Resolução** — Sucesso Limpo, Sucesso com Custo ou Falha com Revelação. Falhar nunca é beco sem saída: é gancho de história.
6. **Vínculos** — quem vai junto se aproxima ou se afasta. Ao cruzar limiares, você decide o que existe entre eles (Amizade, Mentoria, Rivalidade, Romance...), e isso desbloqueia **Ações de Vínculo**.
7. **Bastidores** — cenas curtas na guilda (taverna, treino, brigas, segredos). Você escolhe como reagir: pagar a rodada, tomar partido, mediar.
8. **Evolução** — heróis ganham XP, sobem de nível (você escolhe o atributo e, nos níveis 3/5/7/9, uma magia ou talento), trazem saque das missões e usam armas, armaduras, acessórios e consumíveis. Conjuradores preparam uma magia antes de cada despacho; o clérigo e outros curandeiros curam na guilda.
9. **Descanso** — mande um herói descansar: ele fica o dia fora, mas recupera fadiga, PV, magias e moral. Quem está esgotado pede descanso; ignorar custa moral.
10. **Guilda** — gaste o ouro das missões em melhorias: Quadro de Relações, Enfermaria, Arquivo e Salão de Treinamento.
11. **Encerrar o dia** — aventureiros descansam, missões expiram, novos pedidos chegam. Quem não sai junto em missão vai se afastando (neglect).

| Montagem de Party | Mapa Mágico |
|---|---|
| ![Montagem de Party](docs/img/2_party.png) | ![Mapa Mágico](docs/img/6_mapa.png) |
| **Livro da Guilda** | **Resolução** |
| ![Livro da Guilda](docs/img/5_livro.png) | ![Resolução](docs/img/3_resultado.png) |
| **Abertura de capítulo** | **Melhorias da Guilda** |
| ![Capítulo](docs/img/10_capitulo.png) | ![Melhorias](docs/img/11_upgrades.png) |
| **Subida de nível** | **Equipamento** |
| ![Nível](docs/img/14_nivel.png) | ![Equipamento](docs/img/13_equipamento.png) |
| **Mercado** | **Livro com magias** |
| ![Mercado](docs/img/12_mercado.png) | ![Livro](docs/img/15_livro_mira.png) |
| **Ultimato** | **Abertura do Ato 2** |
| ![Ultimato](docs/img/16_ultimato.png) | ![Ato 2](docs/img/17_ato2.png) |
| **Epílogo** | **Livro com retrato** |
| ![Epílogo](docs/img/19_epilogo.png) | ![Livro](docs/img/5_livro.png) |
| **Mapa Mágico — floresta** | **Resultado com o cartaz riscado** |
| ![Mapa floresta](docs/img/20_mapa_floresta.png) | ![Resultado](docs/img/3_resultado.png) |
| **Bastidores no hub** | **Cena de bastidor** |
| ![Bastidores](docs/img/8_hub_bastidores.png) | ![Cena de bastidor](docs/img/9_bastidor.png) |

## Estado atual — v0.9

Dois atos (4 capítulos, 24 missões), 7 aventureiros, afinidade assimétrica com vínculos e Ações de Vínculo, mapa de expedição com escolhas de rota, estresse com virtudes e aflições, traços, progressão de RPG leve, melhorias da guilda, bastidores, ultimatos, salvar/carregar e quatro finais.

O histórico de cada versão está no [Changelog](docs/CHANGELOG.md) e o que vem a seguir no [Roadmap](docs/ROADMAP.md). A próxima meta é a **v1.0 — Vertical Slice**: consolidar e polir o núcleo antes de novos sistemas.

## Documentação

| Documento | Conteúdo |
|---|---|
| [GDD](docs/GDD.md) | Design do jogo como ele é hoje |
| [TDD](docs/TDD.md) | Arquitetura, dados, save, testes e pipeline de arte |
| [Balanceamento](docs/BALANCEAMENTO.md) | Fórmulas, constantes e resultados de simulação |
| [Narrativa](docs/NARRATIVA.md) | Elenco, relações, capítulos, missões pessoais e finais |
| [Roadmap](docs/ROADMAP.md) | Prioridades até a v1.0 e depois |
| [Changelog](docs/CHANGELOG.md) | Histórico de versões |
| [Análise e Melhorias](docs/ANALISE_E_MELHORIAS.md) | Direção de design e plano de consolidação |

## Rodar

Requer **Godot 4.7**. Abra a pasta no editor e pressione **F5**.

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `data/heroes.json` | Elenco: atributos, cor, traço e grade de afinidade inicial (`a → b`) |
| `data/missions.json` | Missões: risco, atributos, prazo, tags, requisito oculto e textos de resultado |
| `scripts/core/score_calc.gd` | Fórmula de score e limiares |
| `scripts/core/game_state.gd` | Autoload `GameState`: elenco, afinidade, vínculos, despacho, fadiga, moral, reputação, dias |
| `data/narration.json` | Narração do Mapa Mágico por partida, bioma e resultado |
| `data/backstage.json` | Eventos de bastidor: condições, texto e escolhas com efeitos |
| `data/chapters.json` | Atos e capítulos: abertura, duração, missões, objetivo, flags e encerramentos |
| `data/upgrades.json` | Ouro inicial, recompensas por risco e melhorias da guilda |
| `data/classes.json` | XP, níveis, classes, magias e talentos (com os tipos de efeito documentados) |
| `data/items.json` | Itens, tabelas de saque e mercado |
| `scripts/core/hero_rpg.gd` | Regras de RPG: XP, nível, efeitos, equipamento, magias, saque, mercado |
| `data/ultimatum.json` | Texto e escolhas do ultimato por moral baixa |
| `data/endings.json` | Finais, desfechos por herói e por vínculo |
| `scripts/ui/portrait.gd` | Retrato procedural dos heróis |
| `art/MapParts/<tipo>/` | Peças de mapa a nanquim (trees, hills, mountains, towns, cities) usadas pelo Mapa Mágico |
| `art/enemies/` | Cartazes dos inimigos (mural, destino do mapa, resultado) |
| `art/specs/` | Especificações para artistas: heróis e wallpaper (`art/specs/`), inimigos (`art/specs/inimigos/`) e cenário, objetos, interface, fundos e efeitos (`art/specs/cenario/`, com `_indice.json` de 237 assets por prioridade) |
| `art/tools/` | Scripts que preparam retratos e cartazes (conversão e remoção de fundo) |
| `data/book.json` | Seções trancadas do Livro (slots de expansão por versão) |
| `scripts/ui/main.gd` | Telas, montadas por código |
| `data/traits.json` | Estresse, aflições, virtudes e traços |
| `scripts/core/mind.gd` | Regras de estresse, ponto de ruptura, condições, traços e termo Mente |
| `data/route.json` | Mapa de expedição: tipos de nó, pesos por bioma, eventos com testes e efeitos |
| `scripts/core/expedition.gd` | Expedição: geração do grafo, nós, testes d20, efeitos e modificador da rota |
| `scripts/ui/magic_map.gd` | Mapa Mágico: desenho do bioma, grafo de caminhos clicável, névoa e marcadores |
| `scripts/ui/guild_book.gd` | Livro da Guilda: ficha em duas páginas |
| `tests/` | Testes headless de regras e telas, e gerador de screenshots |
| `docs/GDD.md` | Game Design Document |

A regra de jogo fica em `scripts/core`; a UI só lê o estado e chama métodos. Heróis, missões e textos novos entram pelos JSON, sem mexer em código.

### Criando eventos de bastidor

Adicione um objeto em `data/backstage.json`:

```json
{"id": "duelo", "title": "Duelo ao amanhecer", "min": -5, "max": -2, "weight": 2, "once": false,
 "heroes": ["senna", null],
 "text": "{a} desafia {b} na frente de todos.",
 "choices": [
   {"label": "Permitir o duelo", "aff": [1, 1], "fatigue": {"a": 1, "b": 1}, "result": "..."},
   {"label": "Proibir", "morale": {"a": -1}, "result": "..."}
 ]}
```

- `min`/`max`: faixa de afinidade do par. `heroes`: fixa um ou os dois heróis (`null` = qualquer). `once`: aparece uma vez por jogo.
- Efeitos: `aff` = [a→b, b→a], `morale` e `fatigue` por `a`/`b`. Mudanças de afinidade disparam os eventos de vínculo normalmente.

### Criando capítulos

Em `data/chapters.json`, adicione o capítulo à lista `chapters` e o id dele em `acts[].chapters`. As missões do capítulo ficam em `missions.json` com `day` relativo ao início do capítulo. Objetivos: `{"type": "reputation", "min": N}` ou `{"type": "mission", "mission": "<id>"}`. `intro_flags` acrescenta texto conforme as flags de capítulos anteriores (`"!flag"` = flag ausente).

### Expandindo o Livro da Guilda

- **Campo novo na ficha:** adicione no herói em `heroes.json`. Todos os campos da ficha são opcionais, com valor padrão em `GameState.new_game`.
- **Retrato:** preencha `"portrait": "res://art/portraits/vera.png"`. Sem imagem, o livro mostra a inicial na cor do herói.
- **Seção nova:** entre como trancada em `data/book.json` (`page`, `title`, `version`, `desc`). Quando for implementada, remova da lista e desenhe em `guild_book.gd` (`_left_page` ou `_right_page`).

## Testes

```bash
godot --headless --path . -s res://tests/sim_test.gd
godot --headless --path . -s res://tests/ui_smoke.gd
```

`sim_test.gd` confere a calibragem do score, as regras de afinidade, RPG, capítulos, save, expedição e estresse, e joga 150 partidas aleatórias (2 atos). `tests/screenshots.gd` (com janela, sem `--headless`) regenera as imagens em `user://shots`. Detalhes no [TDD](docs/TDD.md#7-testes).

## Roadmap

Ver [docs/ROADMAP.md](docs/ROADMAP.md).

## Créditos

Design: Rafael Jr. Detalhes completos em [docs/GDD.md](docs/GDD.md).
