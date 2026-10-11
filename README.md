# A Guilda

> *"Quem você envia define quem eles se tornam."*

Jogo de gerenciamento narrativo em fantasia medieval, feito em **Godot 4.7**. Inspirado no loop de despacho de **Dispatch**, no estresse e nas expedições de **Darkest Dungeon** e nos mapas de rota de **Slay the Spire** e **Cult of the Lamb**. Você não é o herói — é o(a) **Mestre(a) de Despacho** da decadente Guilda do Corvo Cinzento, e decide **quem vai, com quem, e como**.

O jogo não é sobre combate. É sobre gestão de gente complicada com poder de matar dragões: egos, rivalidades, dívidas de honra e vínculos que mudam conforme você monta as parties. **Não faça o jogador administrar números. Faça-o administrar pessoas.**

![Tela de título](docs/img/18_titulo.png)

![Tela da Guilda](docs/img/1_hub.png)

## Como se joga

O jogo é dividido em **atos** e **capítulos**. Cada capítulo abre com uma cena, dura alguns dias e tem um objetivo; o resultado muda o texto dos capítulos seguintes. São dois atos, com dois capítulos cada.

1. **Mural de Quests** — pedidos chegam a cada dia, com o cartaz do inimigo, risco, prazo e atributos exigidos.
2. **Montagem de Party** — escolha de 1 a 4 aventureiros pelos cartões com retrato e nome. O preview mostra a afinidade, o estresse e as condições de cada um, mas nunca o resultado.
3. **Despacho** — o **Selo de Cera** carimba a decisão.
4. **Mapa Mágico (expedição)** — a missão vira um mapa de pergaminho com caminhos e bifurcações; os heróis andam como **miniaturas de RPG de mesa**. Em cada encruzilhada um herói **chama pelo Mapa Mágico** e você escolhe o próximo ponto: combate, tesouro, mercador, acampamento, encontro, atalho, estranho, santuário ou o guarda do alvo. Os testes são um **d20 arremessado na cena** + o atributo do herói mais apto.
5. **Resolução** — a barra do score enche até o veredito: Sucesso Limpo, Sucesso com Custo ou Falha com Revelação. O jogo conta **por que** deu assim, em até três momentos (*"Vera e Bram lutaram como uma só lâmina."*, *"Theo e Lyssa não se entenderam — e isso custou caro."*); a soma do score fica em "ver detalhes". Falhar nunca é beco sem saída: é gancho de história.
6. **Vínculos** — quem vai junto se aproxima ou se afasta. Ao cruzar limiares, você decide o que existe entre eles (Amizade, Mentoria, Rivalidade, Romance...), e isso desbloqueia **Ações de Vínculo**.
7. **Estresse** — expedições pesam. No limite, o herói **quebra** (Paranoico, Desesperado...) ou **se supera** (Corajoso, Inspirador...), e pode ganhar traços permanentes. Ele não volta só ferido: volta diferente.
8. **Bastidores** — cenas curtas na guilda e na cidade (taverna, treino, a praça, a viúva, o beco dos doentes...). Você escolhe como reagir: a escolha mexe na relação entre os heróis, na **Fama** de cada um no povo e na **Estima da cidade** pela guilda — e às vezes revela uma **melhoria nova** (a forja do ferreiro que Vera trouxe, a biblioteca que Mira salvou, a capela de Corin...).
9. **Evolução** — XP, níveis, magias, talentos, equipamento, saque e mercado. Conjuradores preparam uma magia antes do despacho.
10. **Descanso** — mande um herói descansar: recupera fadiga, PV, magias, moral, alivia o estresse e cura aflições.
11. **Guilda** — gaste o ouro em melhorias: Quadro de Relações, Enfermaria, Arquivo, Salão de Treinamento e as que os bastidores revelarem (Forja, Biblioteca, Capela, Estábulo, Taverna), que melhoram todos os heróis. A cidade grata faz preço de amigo e paga melhor; a desconfiada cobra mais.
12. **Encerrar o dia** — o dia vira, missões expiram, novos pedidos chegam. Quem não sai junto vai se afastando; quem fica com moral baixa dá um ultimato.

### Galeria

| Montagem de Party | Mapa Mágico (miniaturas e mercador) |
|---|---|
| ![Montagem de Party](docs/img/2_party.png) | ![Mapa Mágico](docs/img/6_mapa.png) |
| **Selo de Cera no despacho** | **Dado d20 arremessado no teste** |
| ![Selo](docs/img/21_selo.png) | ![Dado](docs/img/22_dado.png) |
| **Dado em voo** | **Falha crítica (1 natural)** |
| ![Dado em voo](docs/img/23_dado_voo.png) | ![Falha crítica](docs/img/24_dado_falha.png) |
| **Resolução** | **Ponto de ruptura** |
| ![Resolução](docs/img/3_resultado.png) | ![Ruptura](docs/img/25_ruptura.png) |
| **Livro da Guilda** | **Livro com magias** |
| ![Livro da Guilda](docs/img/5_livro.png) | ![Livro](docs/img/15_livro_mira.png) |
| **Quadro de Relações** | **Mercado** |
| ![Quadro de Relações](docs/img/4_relacoes.png) | ![Mercado](docs/img/12_mercado.png) |
| **Equipamento** | **Subida de nível** |
| ![Equipamento](docs/img/13_equipamento.png) | ![Nível](docs/img/14_nivel.png) |
| **Mapa — floresta** | **Mapa — montanha** |
| ![Mapa floresta](docs/img/20_mapa_floresta.png) | ![Mapa montanha](docs/img/26_mapa_montanha.png) |
| **Decisão de arco** | **Ultimato** |
| ![Decisão](docs/img/27_decisao.png) | ![Ultimato](docs/img/16_ultimato.png) |
| **Bastidores no hub** | **Cena de bastidor** |
| ![Bastidores](docs/img/8_hub_bastidores.png) | ![Cena de bastidor](docs/img/9_bastidor.png) |
| **Abertura de capítulo** | **Melhorias da Guilda** |
| ![Capítulo](docs/img/10_capitulo.png) | ![Melhorias](docs/img/11_upgrades.png) |
| **Ultimato** | **Abertura do Ato 2** |
| ![Ultimato](docs/img/16_ultimato.png) | ![Ato 2](docs/img/17_ato2.png) |
| **Epílogo** | |
| ![Epílogo](docs/img/19_epilogo.png) | |

## Estado atual — v0.9

- **Jogo:** dois atos (4 capítulos, 24 missões), 7 aventureiros, afinidade assimétrica com vínculos e Ações de Vínculo, mapa de expedição com escolhas de rota, estresse com virtudes e aflições, traços, progressão de RPG leve, melhorias da guilda, bastidores, ultimatos, salvar/carregar e quatro finais.
- **Game juice:** Selo de Cera, d20 arremessado, placar crescente, momentos de personagem (ruptura, saída, vínculo, nível), transição de dia e opção **Reduzir movimento**.
- **Arte integrada:** retratos e cartazes, ícones dos 18 itens, miniaturas dos heróis no mapa, páginas do Livro, ícone do jogo (Android e Windows) e as 20 faces do d20. O que ainda falta está no índice de assets (`art/specs/cenario/_indice.json`).
- **Código:** regras separadas em sistemas (`scripts/systems/`) e interface separada em telas e componentes (`scripts/ui/screens/`, `scripts/ui/components/`), com equivalência provada por teste.

O histórico de cada versão está no [Changelog](docs/CHANGELOG.md) e o que vem a seguir no [Roadmap](docs/ROADMAP.md). A próxima meta é a **v1.0 — Vertical Slice**: consolidar e polir o núcleo antes de novos sistemas.

## Documentação

| Documento | Conteúdo |
|---|---|
| [GDD](docs/GDD.md) | Design do jogo como ele é hoje |
| [TDD](docs/TDD.md) | Arquitetura, dados, save, testes, build Android e pipeline de arte |
| [Balanceamento](docs/BALANCEAMENTO.md) | Fórmulas, constantes e resultados de simulação |
| [Narrativa](docs/NARRATIVA.md) | Elenco, relações, capítulos, missões pessoais e finais |
| [Roadmap](docs/ROADMAP.md) | Prioridades até a v1.0 e depois |
| [Changelog](docs/CHANGELOG.md) | Histórico de versões |
| [Análise e Melhorias](docs/ANALISE_E_MELHORIAS.md) | Direção de design e plano de consolidação |
| [Plano: Alvorada Rubra](docs/PLANO_ALVORADA.md) | Primeira missão grande: arco em Vau-Salgado, decisão moral, dois ramos, três finais |
| [Referências de RPG](docs/REFERENCIAS_RPG.md) | Princípios de RPG de mesa (campanha, aventuras, tempo livre, tesouro, magia, raças, monstros) adaptados ao jogo, para preencher dados e planejar melhorias |

## Rodar

Requer **Godot 4.7**. Abra a pasta no editor e pressione **F5**.

### APK de teste (Android)

Os APKs **não ficam no Git**. Eles são publicados na pasta do Google Drive do projeto:
**[A Guilda — builds Android](https://drive.google.com/drive/folders/1H7azjgFBsBbRIVLfLPu_LGSzMqcmbnkc?usp=drive_link)**

Nome dos arquivos: `AGuilda-v<versão>-debug.apk` (ex.: `AGuilda-v0.9-debug.apk`). Como gerar: ver [TDD §8](docs/TDD.md#8-build-android).

## Estrutura

### Código

| Caminho | Conteúdo |
|---|---|
| `scripts/core/game_state.gd` | Autoload `GameState`: estado da guilda, início de jogo, fim do dia e API pública |
| `scripts/systems/` | Regras por assunto: relações, missões e despacho, capítulos, economia, cidade (fama e estima), saídas, bastidores, save, finais, resultado contado em frases |
| `scripts/core/score_calc.gd` | Fórmula de score e limiares |
| `scripts/core/hero_rpg.gd` | RPG: XP, nível, efeitos, equipamento, magias, saque, mercado |
| `scripts/core/expedition.gd` | Expedição: grafo de nós, testes d20, efeitos e modificador da rota |
| `scripts/core/mind.gd` | Estresse, ponto de ruptura, condições, traços e termo Mente |
| `scripts/ui/main.gd` | Cena principal: estado da interface e repasses |
| `scripts/ui/screens/` | Telas: hub, montagem de party, expedição, resultado, guilda, itens, história, título |
| `scripts/ui/components/` | Peças de interface: kit básico, widgets de herói/inimigo, momentos de personagem, dado arremessado |
| `scripts/ui/magic_map.gd` | Mapa Mágico: pergaminho, grafo clicável, névoa e miniaturas |
| `scripts/ui/guild_book.gd` | Livro da Guilda: ficha em duas páginas |
| `scripts/ui/juice.gd` | Game juice: pop, fade, tremor, clarão, contadores, texto voando |
| `tests/` | Testes de regras, de telas e de equivalência, e geradores de screenshot |

A regra de jogo fica em `scripts/core` e `scripts/systems`; a UI só lê o estado e chama métodos.

### Dados (`data/`)

| Arquivo | Conteúdo |
|---|---|
| `heroes.json` | Elenco: atributos, classe, personalidade, retrato e grade de afinidade inicial (`a → b`) |
| `missions.json` | Missões: risco, atributos, prazo, tags, requisito oculto, inimigos e textos de resultado |
| `chapters.json` | Atos e capítulos: abertura, duração, missões, objetivo, flags e encerramentos |
| `route.json` | Mapa de expedição: tipos de nó, pesos por bioma, eventos com testes e efeitos |
| `traits.json` | Estresse, aflições, virtudes e traços |
| `result_story.json` | Resultado contado em frases: momentos por tipo (sinergia, conflito, destaque, aflição, rota, sorte...), textos por resultado e frases/imagens próprias de pares |
| `backstage.json` | Eventos de bastidor: condições (par, afinidade, capítulo, flag, estima), texto e escolhas com efeitos (afinidade, moral, fadiga, estresse, fama, estima, ouro, revelar melhoria) |
| `classes.json` / `items.json` | Classes, magias, talentos / itens, saque e mercado |
| `upgrades.json` | Ouro inicial, recompensas, estima inicial da cidade e melhorias da guilda (comuns e ocultas, com efeitos nos heróis) |
| `ultimatum.json` / `endings.json` | Ultimato por moral baixa / finais e desfechos |
| `narration.json` / `book.json` | Narração do mapa / seções trancadas do Livro |

Heróis, missões, eventos e textos novos entram pelos JSON, sem mexer em código.

### Arte (`art/`)

| Caminho | Conteúdo |
|---|---|
| `art/specs/` | Especificações para artistas (JSON): heróis e wallpaper, inimigos (`inimigos/`), miniaturas (`tokens_herois.json`), cenas ilustradas do resultado (`cenas/cenas_resultado.json`) e cenário/objetos/interface/fundos/efeitos/livro/mapa/ícone/dado (`cenario/`, com `_indice.json` de todos os assets por prioridade e status de produção) |
| `art/ArtesEmGeral/` | Artes entregues pelos artistas, com o nome do id do asset (pasta ignorada pelo Godot) |
| `art/items/`, `art/tokens/`, `art/book/`, `art/icon/`, `art/dice/` | Artes processadas que o jogo usa |
| `art/portraits/`, `art/enemies/`, `art/MapParts/` | Retratos, cartazes de inimigos e peças de mapa a nanquim |
| `art/tools/` | `preparar_assets.py` (remove o fundo branco, recorta e gera os PNGs), `marcar_status.py` (status no índice), `preparar_retratos.py` e `preparar_inimigos.py` |

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
- Efeitos: `aff` = [a→b, b→a], `morale`, `fatigue`, `stress` e `fame` por `a`/`b`; `esteem` (Estima da cidade); `gold` (negativo = custo, bloqueia a escolha sem ouro); `reveal_upgrade` (revela uma melhoria oculta de `upgrades.json`). Condições extras: `min_esteem`/`max_esteem` e `reveals` (a cena some quando a melhoria já é conhecida). Mudanças de afinidade disparam os eventos de vínculo normalmente.

### Criando eventos de rota

Em `data/route.json → events.<tipo de nó>`: cada evento tem `title`, `text` (com `{heroi}`) e `options`. Uma opção pode ter `test {attr, dc}` com ramos `ok`/`fail`, `requires {guild_gold, gold, provisions}` e efeitos `fx` (`gold`, `provisions`, `hp`, `hp_one`, `bonus`, `item`, `days`, `affinity`, `stress`, `stress_one`, `guild_gold`, `lose_item`, `trait`). Detalhes no [TDD §4.2](docs/TDD.md#42-efeitos-da-rota-routejson).

### Criando capítulos

Em `data/chapters.json`, adicione o capítulo à lista `chapters` e o id dele em `acts[].chapters`. As missões do capítulo ficam em `missions.json` com `day` relativo ao início do capítulo. Objetivos: `{"type": "reputation", "min": N}` ou `{"type": "mission", "mission": "<id>"}`. `intro_flags` acrescenta texto conforme as flags de capítulos anteriores (`"!flag"` = flag ausente).

### Adicionando arte

1. O artista entrega `art/ArtesEmGeral/<id>.jpg` (fundo branco) com o id do asset em `art/specs/cenario/_indice.json`.
2. `python art/tools/preparar_assets.py` gera o PNG no destino do asset.
3. `python art/tools/marcar_status.py` atualiza o status de produção no índice.

## Testes

```bash
godot --headless --path . -s res://tests/sim_test.gd
godot --headless --path . -s res://tests/ui_smoke.gd
godot --headless --path . -s res://tests/equivalencia.gd
```

- `sim_test.gd`: calibragem do score, regras de afinidade, RPG, capítulos, save, expedição e estresse, e 150 partidas aleatórias (2 atos).
- `ui_smoke.gd`: abre todas as telas, percorre uma expedição, rola o dado, encena momentos, salva e carrega.
- `equivalencia.gd`: partida roteirizada com semente fixa; o hash do estado por dia prova que uma refatoração não mudou o comportamento.
- `screenshots.gd`, `map_biomes.gd` e `juice_shots.gd` (com janela, sem `--headless`) regeneram as imagens em `user://shots`.

Detalhes no [TDD](docs/TDD.md#7-testes).

## Roadmap

Ver [docs/ROADMAP.md](docs/ROADMAP.md).

## Créditos

Design: Rafael Jr. Detalhes completos em [docs/GDD.md](docs/GDD.md).
