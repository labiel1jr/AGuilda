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
4. **Mapa Mágico** — você acompanha a party pelo mapa: a rota se revela em dourado, os marcadores avançam e cada ponto de interesse narra o que acontece. Você assiste, não controla.
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

## Estado atual — v0.7 (salvar, finais e retratos)

- **Salvar e carregar**: tela de título (Continuar / Novo jogo / Carregar), 3 espaços de save e salvamento automático ao fim de cada dia. Menu ☰ no hub. O save usa `var_to_str` (preserva inteiros e cores) e guarda só o estado mutável — os JSON de conteúdo são recarregados, então correções de texto valem para saves antigos.
- **Finais variáveis**: epílogo ao fim do Ato 2 — quatro finais (*A Lenda do Corvo Cinzento*, *A Guilda Reconstruída*, *Os Que Ficaram*, *Cinzas e Recomeço*) conforme flags, reputação e quem deixou a guilda; um desfecho por herói (inclusive quem saiu) e uma linha por vínculo formado (Romance, Mentoria, Irmandade...). Tudo em `data/endings.json`.
- **Retratos gerados por código**: busto na cor do herói, detalhe de raça (barba anã, orelhas élficas, presas de meio-orc, halfling menor) e emblema da classe. Aparecem no título, no Livro, no ultimato, na subida de nível e no epílogo. Um `portrait` com imagem em `heroes.json` substitui o retrato gerado.

## v0.6 (Ato 2)

- **Ato 2 — A Lista de Nomes**: Capítulo 3 "Nomes na Lista" (objetivo: convencer o Conselho) e Capítulo 4 "O Ninho do Corvo" (missão final **lendária**, exige 4 aventureiros). 12 missões novas. Ao fim de um ato, o jogo segue para o próximo.
- **Missões pessoais**: *O Irmão de Senna*, *A Última Carta* (Mira) e *O Julgamento da Ordem* (Theo) exigem o herói e mudam a moral dele e as flags da história.
- **Bastidores ligados à história**: eventos com condição de capítulo (`chapters`) ou de flag (`requires_flag`) — a primeira noite na guilda, a chegada de Corin, Senna encontrando o nome do irmão, a véspera do Ninho...
- **Saída por moral baixa (GDD §5.7)**: herói com moral ≤ 1 dá um **ultimato**. Pagar bônus, dar folga, prometer a próxima missão ou deixar partir. Ignorado por um dia, ele vai embora; promessa não cumprida em 2 dias também. O equipamento volta ao Baú. Vínculo de **Irmandade** ("Até o Fim"): o par parte junto.

## v0.5 (RPG)

- **XP e níveis**: XP por missão (risco × resultado; falha também ensina) e por treino. Cada nível dá PV pela classe e +1 atributo à escolha (máx. 10). Níveis 3/5/7/9: conjuradores escolhem 1 de 2 magias; os demais, 1 de 2 talentos.
- **Equipamento**: Arma, Armadura, Acessório e 2 Consumíveis por herói; armaduras respeitam a classe (leve/média/pesada). Baú da Guilda guarda o saque.
- **Saque e Mercado**: missões trazem itens (limpo sempre, custo 50%, falha 30%); o Mercado vende o básico e compra pela metade. Itens raros (★) só vêm de missões.
- **Magias**: Mira (Maga), Theo (Paladino), Bram (Bardo) e Corin (Clérigo). Na montagem da party você escolhe a magia que cada conjurador leva; ela gasta 1 espaço. Magias de cura também são lançadas na guilda pelo Livro.
- **Irmão Corin**, clérigo, entra no elenco no Capítulo 2.
- **Poderes**: novo termo do score — itens, talentos e magias somam até **+3**, para não quebrar a calibragem.
- **Descanso ativo**: descansar recupera tudo (inclusive magia); ficar parado recupera pouco e não recupera magia. Herói com fadiga máxima ou PV baixo pede descanso.

## v0.4

- **Capítulos (GDD §9)**: Ato 1 com "Herança de Cinzas" (objetivo: Reputação 6+) e "Ecos do Corvo" (objetivo: sobreviver à missão final *A Noite do Corvo*, que exige 3+ aventureiros). Abertura, encerramento com objetivo cumprido ou não, flags que mudam o texto do capítulo seguinte e tela de fim de ato. Falhar não encerra o jogo.
- **Ouro**: missões pagam recompensa (limpo = inteira, custo = metade, falha = nada).
- **Melhorias da Guilda (GDD §7)**:
  - *Quadro de Relações* — sem ele, a afinidade aparece só como impressão ("Se dão bem", "Mal se olham"); com ele, números e o Quadro.
  - *Enfermaria* — descanso recupera um estado de fadiga a mais e o dobro de PV.
  - *Arquivo da Guilda* — histórico de missões de cada dupla no Quadro.
  - *Salão de Treinamento* — 1 treino de dupla por dia: +1 de afinidade, os dois ficam Cansados.
  - Slots de missão seguem liberados pela reputação (5 → 2 slots, 12 → 3 slots).

- 6 aventureiros (Theo, Lyssa, Mira, Senna, Bram, Vera) com atributos e grade de afinidade assimétrica.
- 10 missões, com tags de composição (exige especialista, proíbe herói) e requisito oculto.
- Score normalizado: `Base + Cobertura + Afinidade + Vínculo + Oculto + Sorte` (GDD §5.6).
- Fadiga (Pronto / Cansado / Exausto), moral, reputação e slots de despacho por dia.
- Eventos de vínculo em +3, +6, +9, −3 e −5, com escolha de rótulo.
- Ações de Vínculo: Impulso do Mentor, Cobertura Mútua, Esforço Extra, Competição, Sincronia Perfeita.
- **Mapa Mágico** (GDD §13): 5 biomas desenhados por código, rota sinuosa revelada aos poucos, marcadores por herói, 3 waypoints com narração e botão de acelerar.
- **Livro da Guilda** (GDD §14): ficha D&D 5e resumida — retrato, classe, raça, nível, PV, moral, status, proficiências, histórico, atributos com modificador, personalidade (Traço, Ideal, Vínculo, Defeito) e barras de afinidade.
- PV: missões com custo ou falha ferem; o descanso cura; com 0 PV o herói fica Incapacitado.
- **Eventos de bastidor**: até 2 cenas por dia, sorteadas por afinidade do par, com escolhas que mudam afinidade, moral e fadiga. Inclui cenas exclusivas de duplas (Vera & Bram, Theo & Lyssa, Mira & Lyssa) e a regra "escolher um lado" (+2 / −1 de moral).
- **Neglect**: par com afinidade +3 ou mais perde 1 a cada 3 dias sem missão juntos, nunca abaixo do valor inicial. Herói 4 dias sem missão perde 1 de moral.
- Quadro de Relações (com dias sem missão juntos no tooltip).

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
| `art/tools/` | Scripts que preparam retratos e cartazes (conversão e remoção de fundo) |
| `data/book.json` | Seções trancadas do Livro (slots de expansão por versão) |
| `scripts/ui/main.gd` | Telas, montadas por código |
| `scripts/ui/magic_map.gd` | Mapa Mágico: desenho do bioma, rota, waypoints e marcadores |
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

`sim_test.gd` confere a tabela de calibragem do GDD, as regras de assimetria, fadiga e Mentoria, e joga 150 partidas aleatórias (2 atos). `tests/screenshots.gd` (com janela, sem `--headless`) regenera as imagens em `user://shots`.

## Roadmap

- [x] **v0.1** — loop de despacho
- [x] **v0.2** — party, afinidade, Ações de Vínculo
- [x] **v0.3** — Mapa Mágico, Livro da Guilda, eventos de bastidor, neglect
- [x] **v0.4** — capítulos, Ato 1 completo, upgrades da guilda
- [x] **v0.5** — níveis, equipamento, saque, mercado, magias, clérigo, descanso ativo
- [x] **v0.6** — Ato 2, missões pessoais, bastidores ligados à história, saída de aventureiros por moral baixa
- [x] **v0.7** — salvar/carregar, finais variáveis, retratos gerados por código
- [ ] **v0.8** — trilha e efeitos sonoros, arte ilustrada, minigame opcional (GDD §5.9), opções (volume, velocidade do mapa)
- [ ] **v1.0** — arte, trilha sonora, minigame opcional, finais variáveis

## Créditos

Design: Rafael Jr. Detalhes completos em [docs/GDD.md](docs/GDD.md).
