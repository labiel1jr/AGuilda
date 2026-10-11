# Changelog — A Guilda

Histórico de versões, da mais recente para a mais antiga. Datas dos commits no repositório.

---

## Botões com arte e mais 8 cenas do resultado — 2026-10-11

- **Botões de madeira, pergaminho, escolha, perigo, medalhão e barra do hub** (`UIKit.button` escolhe a peça pelo texto ou pelo tipo pedido). Só o estado normal foi entregue; hover, pressionado e desativado são o mesmo desenho clareado ou escurecido por código.
- **20 ícones de ação** à esquerda dos rótulos conhecidos (Voltar, Continuar, Seguir viagem, Assistir cena…); selo preto do alvo no botão Enfrentar.
- **Hub**: navegação numa linha própria abaixo do título (Guilda, Mercado, Quadro, Livro… Encerrar dia), com o ícone no nicho da placa; menu ☰ no medalhão.
- **8 cenas do resultado** novas: poderes, preparação, fome, desgaste, sorte, azar, sozinho e povo. Falta `povo_contra`.
- `art/tools/preparar_botoes.py` recorta as peças e a folha de ícones (rótulos da folha vieram desalinhados; recorte pelo desenho).

## Sistemas de missão grande (Alvorada, passo 1) — 2026-10-10

- **Arcos de missões** (`Arcs`): missões que só abrem com uma flag, ramos cancelados pela escolha oposta, flags vindas de missões e de eventos da rota.
- **Decisão de arco**: tela depois do resultado com a cena, a fala de cada herói que esteve lá e as escolhas; quem apoiou a escolha feita ganha moral, quem queria outra ganha estresse.
- **Rota fixa**: missão pode desenhar a própria expedição (`route.fixed`), com eventos de qualquer grupo.
- Ainda sem conteúdo: `data/decisions.json` vazio até a Etapa 1 da Alvorada.

## Arte do quadro de avisos e cenas genéricas integradas — 2026-10-11

- **Quadro de avisos com arte**: o quadro (recortado da cena da praça que veio do artista) é a moldura do painel; cada pedido usa o papel do cartaz com o prego da arte e um **selo de cera por tipo** — comum, urgente (último dia), pessoal (missão pessoal) e lendário; quadro vazio mostra o cartaz da pena.
- **12 cenas genéricas do resultado** integradas (sinergia, dupla lendária, conflito, Ação de Vínculo, destaques dos 5 atributos, cansaço, aflição, virtude).
- Entregues e guardadas para depois: prego avulso, cartaz arrancado (4 quadros), restos de papel (6 peças).
- Observações para o artista: o quadro veio como cena (não como moldura) e o selo urgente veio aplicado sobre um cartaz — ambos foram recortados.

## Especificação dos botões — 2026-10-11

- `art/specs/cenario/botoes.json`: sistema de botões por material — madeira com latão (ações principais), pergaminho (voltar e consultar), tira de pergaminho com fita (escolhas da história), lacre (decisões sem volta), selo (despacho e enfrentar), medalhão (ícones) e placa da barra do hub — com 5 estados, 9-slice, 20 ícones de ação e o tema do Godot. Substitui o `ui_botao` genérico.

## A cidade, novos bastidores e o quadro de avisos — 2026-10-10

- **Fama no povo** (por herói, −5 a 10) e **Estima da cidade** (guilda, 0 a 20), separada da Reputação com o Conselho (`scripts/systems/town_system.gd`). Mudam com bastidores e com missões na cidade e na estrada; a estima muda os preços e a recompensa; a fama entra no score de diplomacia (termo **Povo**) e no resultado contado ("A cidade conhece Bram: as portas se abriram").
- **13 bastidores novos**: na cidade (canções na praça, o telhado da viúva, o boato sobre Senna, o menino que queria ser paladino, a bolsa do nobre, o beco dos doentes, a festa da cidade), entre heróis (o pão dos órfãos, com Theo e Lyssa) e os que **revelam melhorias** (o ferreiro Dorin, os livros do arquivista, a sala consagrada, os cavalos velhos, o porão da taverna). Escolhas com custo ficam bloqueadas sem ouro.
- **Melhorias ocultas**: Forja, Biblioteca, Capela, Estábulo e Taverna aparecem quando um bastidor as revela e são construídas com ouro; o efeito vale para todos os heróis.
- **Quadro de Avisos** no hub: moldura de madeira, pedidos como papéis pregados e levemente tortos, arrancados ao montar a party. Arte especificada em `art/specs/cenario/quadro_avisos.json` (quadro com telhadinho e o corvo entalhado, cartaz, selos por tipo de pedido, pregos, restos de papel); substitui o antigo `guilda_mural`.
- **Montagem de party:** cada aventureiro é um cartão com o **retrato e o nome embaixo**, os atributos da missão e o estado; selecionado ganha borda dourada e ✓, indisponível fica apagado com o motivo. A party selecionada também mostra os retratos.
- **Quadro de Relações:** com 7 aventureiros a grade passava da tela e escondia o "Voltar"; agora há um "Voltar" no topo e a grade rola.
- **Livro:** as páginas esquerda e direita voltaram a ter a mesma largura (um título longo sem quebra de linha alargava a direita) e o conteúdo se afastou do ornamento do canto da moldura.
- Fama no Livro; Estima no topo do hub (com explicação ao passar o mouse); saves antigos ganham os campos novos.

## Resultado contado em frases — 2026-10-10

- A tela de resultado mostra **por que** a missão deu certo ou errado, em até 3 momentos com frase e imagem: par em sinergia ou conflito, Ação de Vínculo, destaque por atributo, cansaço, aflição/virtude, poderes, preparação, fome, desgaste, sorte, azar, ir sozinho. A soma do score foi para "ver detalhes".
- `scripts/systems/result_story.gd` (`ResultStory`) monta os momentos no despacho, antes das consequências; não muda o estado (equivalência idêntica).
- `data/result_story.json`: textos por tipo e por resultado, e frases/imagens próprias de pares — Vera e Bram: *"Vera e Bram lutaram como uma só lâmina."*; Lyssa e Mira; Theo e Lyssa.
- **Primeiras cenas entregues e integradas:** Vera e Bram ("como uma só lâmina"), Lyssa e Mira (a porta das runas) e Theo e Lyssa (a discussão enquanto o inimigo foge). `preparar_assets.py` trata `cena_*` como imagem cheia (960×394). Falta a variação de derrota de Vera e Bram.
- `art/specs/cenas/cenas_resultado.json`: 22 cenas ilustradas (P0: Vera e Bram golpeando juntos como uma só lâmina; genéricas por tipo de momento; outros pares). Sem a imagem, o cartão mostra os retratos ligados por um fio.

## Documentação e screenshots — 2026-10-10

- README reorganizado (como se joga, galeria nova com selo, dado, ruptura, mapas por bioma; estrutura em código, dados e arte; como adicionar eventos de rota e arte; testes).
- GDD (mapa com miniaturas e dado, Livro, arte e game juice) e TDD (miniaturas, dado) atualizados.
- Screenshots de `docs/img` regeneradas com as artes integradas; `tests/screenshots.gd` espera as animações terminarem antes de capturar.

## Dado arremessado nos testes — 2026-10-10

- Nos testes do mapa, um d20 é **arremessado sobre a cena**: voa girando, quica duas vezes (achata e levanta poeira), para na face do resultado e ganha aura verde (sucesso) ou vermelha (falha); 20 natural solta raios dourados, 1 natural racha. O painel do teste continua no topo do mapa e mostra a conta quando o dado para.
- Faces do d20 entregues numa folha única (`art/ArtesEmGeral/dado_d20_faces.png`), recortadas por `preparar_assets.py` em `art/dice/d20_face_01..20.png`: o dado usa a arte no voo (face sorteada trocando) e na parada. A tira "rolando", impacto, poeira e destaques ainda são desenhados por código.
- `art/specs/cenario/dado.json`: especificação dos sprites (20 faces, tira rolando, impacto, poeira, sombra, brilhos de sucesso/falha, crítico e falha crítica); substitui o antigo `ui_d20`.

## Refatoração: main.gd separado em telas e componentes — 2026-10-10

- `scripts/ui/main.gd` (1.870 → ~300 linhas) guarda o estado da interface e repassa para as telas.
- Telas em `scripts/ui/screens/`: `HubScreen`, `PartyScreen`, `ExpeditionScreen`, `ResultScreen`, `GuildScreens`, `ItemScreens`, `StoryScreens`, `TitleScreen`.
- Componentes em `scripts/ui/components/`: `UIKit` (peças básicas), `Widgets` (retrato, cartaz, estresse), `Moments` (ruptura e saída). O Livro passou a usar o `UIKit`.
- Verificação: testes de regras e de telas OK, `equivalencia.gd` idêntico, screenshots das telas iguais (diferenças só de dados aleatórios da partida de teste).
- Correções: textos com quebra de linha literal passaram a usar `\n`; uma rolagem de dado nova fecha a anterior (não fica janela esquecida).

## APK fora do Git — 2026-10-10

- O APK de teste saiu do repositório (o commit que o adicionou foi removido do histórico). Os builds Android ficam na pasta do Google Drive do projeto, citada no README e no TDD §8.

## Refatoração: GameState separado em sistemas — 2026-10-10

- `scripts/core/game_state.gd` (1.100 → ~550 linhas) agora guarda o estado e orquestra; as regras foram para 8 sistemas estáticos em `scripts/systems/`: `Relations`, `Missions`, `Chapters`, `Economy`, `Departures`, `Backstage`, `SaveSystem`, `Endings`.
- A API pública do `GameState` foi mantida (repasses), então UI, testes e módulos não mudaram.
- Novo `tests/equivalencia.gd`: partida roteirizada e determinística; o hash do estado de 3 partidas, dia a dia (168 pontos), é idêntico antes e depois da separação.

## Primeiras artes integradas — 2026-10-10

- 56 artes entregues em `art/ArtesEmGeral/` (pasta ignorada pelo Godot com `.gdignore`); `art/tools/preparar_assets.py` remove o fundo branco, recorta e gera os PNGs nos destinos das specs.
- **Itens:** ícones dos 18 itens no Mercado, Baú, Equipamento e no mercador da rota (com provisões).
- **Mapa:** os heróis andam como miniaturas de RPG de mesa (sombra, passos, espelhadas ao voltar), com o balão "!" sobre quem chama; o círculo com inicial fica como reserva.
- **Livro:** páginas de pergaminho com moldura ornamental, lombada costurada, o livro aberto como mesa ao fundo e a capa no botão do hub.
- **Ícone do jogo:** projeto, Android (principal e adaptativo frente/fundo/monocromático) e `.ico` provisório do Windows gerado da arte mestre.
- `art/tools/marcar_status.py` atualiza o índice: 39 integrados, 17 entregues (ferramentas, moedas, base genérica), estados das miniaturas e ícone do Windows ainda pendentes.

## Game juice v1 — 2026-10-09

Feedback visual sóbrio, só código (`scripts/ui/juice.gd`), sem mudar regras:

- **Despacho:** o Selo de Cera carimba o mapa (queda, tremor curto, respingo de lacre).
- **Montagem:** o herói escolhido entra com um pulo; par em Conflito Aberto pisca em vermelho.
- **Mapa:** o caminho se desenha em dourado enquanto o grupo anda; as miniaturas dão passos; ganhos e perdas sobem como texto (+15 ouro, −1 provisões) e o contador pulsa; quem se fere, se estressa ou se cura pisca; flash vermelho ao chegar no alvo.
- **Dado d20:** gira, para no resultado com a conta (rolagem + mod = total) e o veredito; 20 natural tem clarão dourado, 1 natural tem tremor.
- **Resultado:** a barra do score enche contando até o total, com as linhas de custo e limpo; o veredito "carimba" (clarão no limpo, tremor na falha) e o X de lacre é pintado no cartaz.
- **Momentos de personagem:** ponto de ruptura (virtude com luz dourada, aflição com clarão vermelho e tremor) e saída da guilda (retrato desbota) em cena própria, com texto letra a letra; vínculo formado mostra os dois retratos ligados por um fio; subida de nível com brilho; ultimato tira a cor da tela.
- **Hub e Livro:** transição de dia (a tela escurece e volta com o novo dia), cartazes do dia entram em sequência, páginas do Livro aparecem e os pips de PV/moral/estresse enchem um a um.
- **Opção "Reduzir movimento"** no menu (sem tremor, sem zoom, animações curtas), salva em `user://settings.cfg`.

## Arte do Livro, do mapa e miniaturas dos heróis — 2026-10-09

- `art/specs/cenario/livro.json` (18 assets): livro aberto de couro e pergaminho, páginas, lombada, capa, capitular iluminada, moldura de retrato, caixas de atributo, pips de tinta, abas por herói, orelhas de folhear e animação de virar página.
- `art/specs/cenario/mapa_pergaminho.json` (11 assets): folha de mapa de RPG envelhecida por bioma, moldura cartográfica, vincos e vinheta em sobreposição, rosa dos ventos, cartela de título, escala, rio e caminhos a nanquim. Substitui `fundo_pergaminho_mapa`.
- `art/specs/tokens_herois.json` (10 assets): cada herói vira uma miniatura pintada de RPG de mesa sobre base na cor dele, com estados (parado, andando, chamando, ferido, aflito, virtude), mais base genérica, sombra e balão de chamada.
- `_indice.json`: 282 assets (281 ativos).

## Ícone do jogo e build Android — 2026-10-09

- `art/specs/cenario/icone.json`: ícone do jogo (corvo sobre o selo de cera) para Android — principal 192, adaptativo frente/fundo/monocromático 432 — e Windows (.ico de 16 a 256), com arte mestre 1024; registrado no `_indice.json`.
- Preset de exportação Android (`export_presets.cfg`), compressão ETC2/ASTC e ícone provisório (`icon.png`, recorte da tela de título).

## Especificações de assets de cenário — 2026-10-08

- `art/specs/cenario/`: guia de estilo (`_estilo_cenario.json`), índice com 237 assets (`_indice.json`, prioridades P0–P3 e status de produção) e um JSON por categoria: ícones de nó do mapa, marcos/terreno/veículos do mapa, itens e ferramentas, objetos da guilda, fundos, interface e efeitos.
- Sem personagens vivos ou mortos-vivos; modelo e prefixos para novos assets.
- Regra de entrega: JPG com fundo branco puro completo, em `<pasta do destino>/originais/`; o jogo remove o branco e gera o PNG.

## Documentação — 2026-10-07

- GDD reescrito para a v0.9 (plataforma Godot 4.7, mapa de expedição, estresse, progressão).
- Novos: TDD, Roadmap, Changelog, Balanceamento e Narrativa.
- README aponta para a documentação e deixa o histórico de versões para este arquivo.

## v0.9 — Estresse, traços e novos encontros — 2026-10-07

- **Estresse** 0–10 com ponto de ruptura: Virtude (Corajoso, Focado, Estoico, Inspirador; dura 2 missões) ou Aflição (Paranoico, Egoísta, Desesperado, Irracional, Medroso; dura até um descanso).
- **Traços** permanentes positivos e negativos, alguns por bioma; até 4 por herói.
- Novo termo **Mente** no score (±3).
- Mapa: **Guarda do alvo** (miniboss obrigatório em risco médio+), **Estranho** (NPC), **Santuário**, eventos de perda (arma, armadura, comida, sanidade), opções com requisito de ouro ou provisões.
- Estresse, condição e traços no Livro, na montagem e no mapa; saves antigos migram ao carregar.
- Balanceamento: aflição e colapso não tiram moral, falha dá +2 de estresse, herói aflito pede descanso.

## v0.8 — Mapa de expedição — 2026-10-07

- Missão vira grafo em camadas com bifurcações e névoa; o jogador escolhe o caminho.
- **Chamadas ao vivo:** o herói mais apto apresenta o evento; testes d20 + (atributo − 5) com rolagem visível.
- Nós: combate, tesouro, mercador, acampamento, encontro, atalho.
- Provisões, fome, bolsa da rota, itens achados, preparação contra o alvo, dias de atraso.
- Termo **Rota** no score; saque da rota depende do resultado.
- Quadro de Relações com retratos.
- Correção: herói na estrada não pede descanso.

## Arte — 2026-10-06

- Mapa Mágico em pergaminho com peças de mapa a nanquim por bioma.
- Cartazes dos inimigos no mural, no mapa e no resultado (riscado na vitória), incluindo a Lâmina de Capa Preta.
- Retratos dos heróis e tela de título ilustrada.
- Especificações de pixel art (heróis, wallpaper, inimigos) e scripts de preparo de imagem.

## v0.7 — Salvar, finais e retratos — 2026-10-06

- Tela de título, 3 espaços de save e salvamento automático (`var_to_str`).
- Quatro finais, desfecho por herói e linha por vínculo.
- Retratos procedurais por raça e classe.

## v0.6 — Ato 2 — 2026-10-06

- Ato 2 "A Lista de Nomes" (Capítulos 3 e 4), 12 missões novas, missão final lendária.
- Missões pessoais de Senna, Mira e Theo.
- Bastidores ligados a capítulo e flag.
- Ultimato por moral baixa e saída de aventureiros; Irmandade "Até o Fim".

## v0.5 — RPG — 2026-10-05

- XP, níveis, atributos à escolha, magias e talentos nos marcos.
- Equipamento, consumíveis, saque, mercado e Baú da Guilda.
- Magias preparadas antes do despacho; cura na guilda.
- Corin, o clérigo, entra no Capítulo 2.
- Descanso ativo e pedidos de descanso.

## v0.4 — Capítulos e melhorias — 2026-10-05

- Ato 1 com dois capítulos, objetivos e flags.
- Ouro, recompensas e melhorias: Quadro de Relações, Enfermaria, Arquivo, Salão de Treinamento.

## v0.3 — Mapa, Livro e bastidores — 2026-10-05

- Mapa Mágico (rota animada) e Livro da Guilda (ficha estilo D&D).
- Eventos de bastidor e neglect.

## v0.2 — MVP em Godot — 2026-10-05

- Projeto inicial em Godot 4.7: despacho, party de 1 a 4, afinidade assimétrica (vale o menor lado), faixas, eventos de limiar, Ações de Vínculo, fadiga, moral, reputação e slots.
- Fórmula de score normalizada (média em vez de soma) e limiares calibrados (GDD v0.3.1).
