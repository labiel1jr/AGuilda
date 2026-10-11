# Referências de RPG — guia de planejamento

**Para que serve:** orientar o preenchimento de dados (`data/*.json`) e o planejamento de melhorias usando os princípios de um RPG de mesa clássico (D&D 5ª edição) como referência de **funcionamento**, sem virar um RPG tradicional — o pilar continua sendo *administrar pessoas, não números* ([Análise](ANALISE_E_MELHORIAS.md)).
**Documentos relacionados:** [GDD](GDD.md) · [Balanceamento](BALANCEAMENTO.md) · [Narrativa](NARRATIVA.md) · [Roadmap](ROADMAP.md)

> **Fontes consultadas (fora do repositório):** o *Guia do Mestre*, o *Compêndio de Magias*, o *Manual dos Monstros* e um *Resumo das Raças* de D&D 5e, em traduções de fãs, entregues pelo autor do projeto como material de estudo. Uma cópia fica na pasta local `referencias/` do projeto, **ignorada pelo Git e pelo Godot** (está no `.gitignore`): serve para consulta na máquina de quem desenvolve e nunca vai para o GitHub nem para o APK. São obras protegidas por direitos autorais: **não versionar esses arquivos no repositório nem copiar seus textos, nomes próprios ou tabelas para o jogo**. Este documento resume conceitos de design em palavras próprias e aponta como adaptá-los ao A Guilda.

---

## 1. Como usar este guia

1. Antes de criar conteúdo (missão, bastidor, magia, item, capítulo), olhe a seção correspondente abaixo.
2. Use o conceito, não o número: o A Guilda tem escala própria (atributos 1–10, score por média, CD por risco).
3. Toda ideia nova passa pelo teste da [Análise §25](ANALISE_E_MELHORIAS.md#25-teste-de-qualidade-de-uma-mecânica): afeta decisão? afeta personagem? cria consequência?

---

## 2. Mundo e campanha

| Conceito de mesa | O que é | Como já está no A Guilda | Próximo passo possível |
|---|---|---|---|
| **Panorama do mundo** | Poucos fatos fortes que o jogador sente (quem manda, o que ameaça, o que é estranho) | Cidade, Conselho de Guildas, a lista de nomes, o Ninho do Corvo | Documentar 5–7 "verdades do mundo" na Narrativa e checar cada missão contra elas |
| **Deuses e fé** | Religiões que dão cor e conflito, não regras | Corin, a Ordem de Theo, santuários na rota | Um panteão curto (3–4 cultos) ligado a bastidores e à Capela |
| **Assentamentos** | Cada lugar tem quem manda, do que vive, o que teme | A cidade (Estima), vilas no mapa | Fichas curtas por local recorrente (Pedravale, Vaurel, Marrow, Karst) |
| **Facções e organizações** | Grupos com objetivo, lema, símbolo e missões típicas; servem de patrono, aliado ou inimigo | Conselho, Ordem, os fundadores do Corvo | Facções com **renome** próprio (ver §3) e missões de facção |
| **Estágios de jogo** | Faixas de poder: local → regional → reino → mundo; o tipo de ameaça cresce com elas | Ato 1 (cidade e arredores) → Ato 2 (a lista, o Ninho) | Usar como régua: risco *lendário* só no estágio "reino" |
| **Eventos de campanha** | Grandes viradas que mudam o mundo (guerra, praga, queda de um governante) | Noite do Corvo, Audiência no Conselho | Eventos de capítulo que mudam o mural e os bastidores por alguns dias |
| **Estilo e tom** | Equilíbrio entre combate, exploração e interação | Despacho + rota + bastidores | Medir na simulação a proporção de tipos de missão por capítulo |

---

## 3. Personagens e progressão

- **Renome:** em mesa, um número por facção mede a posição do personagem dentro dela e libera títulos e favores. **No A Guilda:** já temos *Fama no povo* (por herói) e *Estima da cidade* (pela guilda). Próximo passo natural: renome com **facções** (Conselho, Ordem, submundo), cada uma com benefícios e missões próprias — e conflitos entre elas.
- **Antecedentes e vínculos pessoais:** ganchos que ligam o personagem ao mundo. **No A Guilda:** traço, ideal, vínculo e defeito do Livro; missões pessoais de Senna, Mira e Theo. Falta: arcos para Lyssa, Bram, Vera e Corin (Roadmap P1), escritos a partir do *vínculo* e do *defeito* de cada um.
- **Experiência:** em mesa, XP vem de desafios superados (e pode vir de marcos de história). **No A Guilda:** XP por risco × resultado. Ideia: **XP de marco** ao concluir capítulos e missões pessoais, para premiar história e não só combate.
- **Recompensas além de ouro:** títulos, medalhas, cartas de recomendação, favores, direitos especiais, treinamento, propriedades, bênçãos. **No A Guilda:** traços positivos, melhorias reveladas. Ideia: **títulos** por feitos (ex.: "Escudo da Viúva"), visíveis no Livro, com efeito pequeno e muito sabor.
- **Loucura (curta, longa, permanente):** em mesa, efeitos mentais por duração. **No A Guilda:** estresse → aflição (até descansar) e traços negativos (permanentes). Ideia: separar aflições "de uma missão" das que pedem cura na Capela, e tornar raras as permanentes.

---

## 4. Aventuras e encontros

| Conceito | Adaptação no A Guilda |
|---|---|
| **Elementos de uma boa aventura**: gancho claro, objetivo, complicação, clímax, recompensa e consequência | Cada missão em `missions.json` deve ter: pedido (gancho), objetivo, **complicação** (requisito oculto, tag, evento de rota) e textos de consequência por resultado |
| **Tipos de aventura** (local, investigação, intriga, exploração, defesa) | Já temos combate, diplomacia, exploração, furtividade; variar o *formato* dentro do tipo |
| **Complicações** (traição, prazo, inocentes no caminho, dilema moral) | Eventos de rota e requisitos ocultos; criar complicações que dependem de **quem foi** (pilar da Análise §14) |
| **Dificuldade de encontro** proporcional ao grupo | Risco + CD por risco + limiares do score ([Balanceamento §1](BALANCEAMENTO.md)) |
| **Encontros aleatórios** com propósito (ambiente, recurso, pista) | Nós da rota; cada evento deve dar ou tirar algo que importe para o alvo |
| **Ambientes** (masmorra, ermo, cidade) e **sobrevivência** (comida, clima, perder-se) | Biomas, provisões, fome, névoa; ideia: clima por bioma afetando a rota |
| **Armadilhas** detectáveis e com pista | Eventos de tesouro com teste; dar sempre uma pista no texto antes da escolha |
| **Perseguições** | Ideia de evento de rota em 2–3 escolhas encadeadas |

---

## 5. Entre aventuras (tempo livre)

Em mesa, o tempo entre aventuras tem custo de vida, manutenção de propriedades e atividades (treinar, trabalhar, pesquisar, criar itens, farrear, construir fortaleza). **É exatamente a camada da guilda do A Guilda:**

| Atividade de mesa | No A Guilda hoje | Ideia de evolução |
|---|---|---|
| Descansar e recuperar | Descanso ativo | — |
| Treinar | Salão de Treinamento (dupla) | Treino individual de atributo com custo de dias |
| Pesquisar / estudar | Biblioteca (XP) | Pesquisa que revela o requisito oculto de uma missão |
| Criar itens | — | Forja: criar/melhorar arma com ouro + dias |
| Farrear | Taverna, bastidores | Farra com chance de bastidor bom ou ruim |
| Trabalhar por ouro | — | Herói ocioso rende ouro ou fama |
| Manter propriedades | — | Custo de manutenção semanal das melhorias (decisão de gastar) |
| Construir fortaleza | Melhorias da guilda | Reconstrução visível do salão por etapas |

Regra de ouro para esta camada: **toda atividade deve gerar uma história ou uma relação**, não só um número.

---

## 6. Tesouro e itens

- **Tesouro por faixa de desafio**: mais risco, melhor tesouro. **No A Guilda:** `items.json → loot` por risco e chance por resultado.
- **Raridade** (comum → lendário) e **itens com personalidade** (que têm vontade própria). Ideia: a *Lâmina do Corvo* como item com vontade — prefere certos heróis e reclama de outros (afinidade com o item).
- **Itens consumíveis** como decisão tática. **No A Guilda:** poções, tônico, pergaminho de bravura; manter poucos e significativos.
- **Artefatos** como motor de enredo. Ideia: um artefato por ato, ligado à história do Corvo.

---

## 7. Magia

### 7.1 Conceitos de funcionamento (e o que adotar)

| Conceito de mesa | Como funciona | Adaptação no A Guilda |
|---|---|---|
| **Nível da magia** | Magias têm nível de poder; conjuradores acessam níveis maiores ao subir | Magias novas nos marcos (níveis 3/5/7/9); ao criar magia, definir para qual marco ela é |
| **Espaços de magia** | Recurso limitado gasto ao conjurar e recuperado no descanso | Já existe: espaços por nível, gastos ao preparar para a missão, recuperados no descanso |
| **Conhecidas × preparadas** | Saber a magia ≠ estar pronta para usar | Já existe: `spells_known` × a magia **preparada** antes do despacho |
| **Truques** | Efeitos pequenos e ilimitados | Ideia: um efeito narrativo sem custo por conjurador (só texto e pequenos bônus de rota) |
| **Rituais** | Conjurar devagar, sem gastar espaço | Ideia: magias de cura/descoberta usáveis **na guilda** sem gastar espaço, gastando o dia |
| **Concentração** | Só um efeito sustentado por vez; quebra com dano | Já é o espírito da "uma magia preparada por missão"; ideia: magia de concentração se perde se o conjurador ficar com ⅓ do PV na rota |
| **Componentes** (verbal, gestual, material) | Custos e restrições de conjuração | Componente **material** como custo em ouro de magias fortes |
| **Escolas** (abjuração, conjuração, adivinhação, encantamento, evocação, ilusão, necromancia, transmutação) | Tema e sabor | Campo `escola` em cada magia de `classes.json`, usado para ícone, cor e eventos (ex.: necromancia assusta o povo e baixa a fama) |
| **Conjurar em nível maior** | Gastar mais recurso para mais efeito | Ideia: gastar 2 espaços para dobrar o efeito da magia preparada |
| **Magia no mundo** | Quão comum é a magia muda a sociedade | Na cidade, magia é rara e temida: base para bastidores com Mira e Corin |

### 7.2 Como criar uma magia para o jogo (passo a passo)

1. **Propósito:** que decisão ela cria? (ex.: arriscar uma missão de combate com a maga, que é frágil)
2. **Classe e marco:** quem aprende e em que nível (3, 5, 7 ou 9).
3. **Escola** (sabor) e **tipo de efeito** do nosso sistema (`score`, `mission_type`, `affinity`, `damage_reduction`, `heal_after`, `reveal_hidden`, `stress_resist`...).
4. **Tamanho do efeito** comparável às magias do mesmo marco (ver `classes.json`): +1 de score é forte; +2 só em marcos altos ou com custo.
5. **Onde vale:** na missão (preparada), na guilda (`hub`) ou nos dois.
6. **Custo:** espaço de magia; magias fortes podem ter custo de ouro (componente material).
7. **Texto de uma linha** que diga o que acontece na história, não só o número.

---

## 8. Conduzindo o jogo (o "mestre" é o sistema)

- **O papel dos dados:** rolar só quando há chance real de falhar e consequência interessante. **No A Guilda:** testes da rota e sorte do score — evitar testes sem consequência.
- **Valores de habilidade e CD:** CD fixa por dificuldade, modificador pelo atributo. **No A Guilda:** CD por risco + `atributo − 5` (ver [Balanceamento §5](BALANCEAMENTO.md)).
- **Interação social:** atitude do outro lado (hostil, indiferente, amistoso) muda o que é possível. **No A Guilda:** Estima da cidade e Fama — próximo passo: atitude de PNJs recorrentes.
- **Exploração e recursos:** luz, comida, tempo. **No A Guilda:** provisões e dias.
- **Doenças e venenos:** condições com duração e cura. Ideia: condição física (ferida infeccionada, veneno) curável na Enfermaria/Capela.

---

## 9. Oficina (criação de conteúdo novo)

Princípios para qualquer coisa nova (monstro/inimigo, magia, item, opção de personagem):

1. **Comparar com o que já existe** do mesmo nível e ajustar para não ficar acima.
2. **Uma ideia forte por elemento** (o inimigo que rouba, a magia que revela, o item que tem vontade).
3. **Testar na simulação** (`sim_test.gd`) e olhar o efeito nos números de [Balanceamento §7](BALANCEAMENTO.md).
4. **Escrever o texto antes do número**: se não houver uma frase boa para o efeito, o efeito provavelmente não precisa existir.

---

## 10. Raças e convivência

As raças de um RPG de mesa trazem três coisas: **corpo** (tamanho, sentidos, resistência), **cultura** (idade, costumes, idioma, ofícios) e **lugar no mundo** (como os outros as veem). No A Guilda, o que interessa é o terceiro ponto — raça como **fonte de relação e de consequência**, nunca como estereótipo que decide quem é bom.

### 10.1 Nosso elenco

| Herói | Raça | Ganchos de convivência (para bastidores, rota e povo) |
|---|---|---|
| Theo, Mira, Corin | Humanos | Vida curta e pressa; maioria na cidade; a Ordem de Theo e o templo de Corin são instituições humanas |
| Lyssa | Meio-elfa | Entre dois mundos: nem os elfos nem os humanos a reconhecem por inteiro; vive mais que os amigos humanos |
| Senna | Meio-orc | Alvo de desconfiança do povo (já usado no bastidor do boato); força e resistência à exaustão; laços de clã |
| Bram | Halfling | Pequeno, subestimado, sortudo; "não tem medo porque não sabe que devia ter" |
| Vera | Anã | Vida longa: viu a antiga guilda inteira morrer; ofício de pedra e metal (o ferreiro Dorin); resistente a venenos |

### 10.2 Como usar raça no jogo

- **Interação entre raças como bastidor:** diferenças de idade e de memória (Vera e Bram: ela já enterrou gente da idade dele), costumes à mesa, idiomas, ofícios (a anã e a forja), fé.
- **O olhar do povo:** a Fama no povo pode ter **viés inicial** contra quem a cidade estranha (meio-orc), que se desfaz com feitos — um arco de reconhecimento, não uma penalidade fixa.
- **Pequenos traços com sabor** (no máximo um por raça, sempre narrativo antes de numérico):
  - *Halfling — sorte:* em testes da rota, um 1 natural de Bram pode ser rolado de novo.
  - *Anã — resistência:* imune à condição de veneno (quando ela existir).
  - *Meio-orc — tenacidade:* uma vez por missão, não cai abaixo de 1 PV num evento de rota.
  - *Meio-elfa — dois mundos:* vantagem em eventos de NPC de origem élfica ou fronteiriça.
  - *Visão no escuro (anã, meio-elfa, meio-orc):* menos estresse em eventos noturnos e de caverna.
- **Novos heróis:** escolher a raça pelo **conflito que ela traz para o elenco** (quem ela incomoda, quem ela protege), não pelo bônus.

---

## 11. Monstros e inimigos

### 11.1 O que um bom inimigo tem

Um bestiário de mesa descreve cada criatura por: **tipo** (morto-vivo, fera, humanoide, monstruosidade, elemental, constructo, fada, demônio...), **tamanho**, **desafio** (o nível de grupo que ele ameaça), **onde vive**, **como se comporta**, **o que quer**, e, nos mais fortes, um **covil** com efeitos próprios e **ações especiais** que mudam a luta. É o mesmo esqueleto das nossas fichas em `art/specs/inimigos/`.

| Conceito do bestiário | No A Guilda hoje | Próximo passo |
|---|---|---|
| Desafio × nível do grupo | Risco da missão (baixo → lendário) e nível do inimigo (comum, elite, chefe) | Régua escrita: que risco cada tipo de criatura pode ter em cada ato |
| Habitat | Bioma da missão | Tabela de criaturas por bioma para sortear eventos de combate e guardas do alvo |
| Comportamento e motivação | Texto do cartaz e da missão | Toda ficha de inimigo com "o que ele quer" — vira complicação e diálogo |
| Covil | Nó do alvo no mapa | Efeito de covil no último nó (ex.: névoa que dá estresse, armadilhas que tiram provisão) |
| Ações especiais / lendárias | — | Chefes lendários com uma regra própria na resolução (ex.: segunda fase que exige preparação na rota) |
| Fraquezas e resistências | Requisito oculto, preparação | Fraqueza descoberta em evento de rota = bônus contra o alvo (já existe como "preparação"; ligar ao inimigo específico) |
| Grupos e hierarquia (bando, líder, xamã) | Inimigo comum + chefe | Missões com "bando" (vários comuns) × "caçada" (um elite) com textos diferentes |

### 11.2 Criaturas por bioma (ideias de uso)

Usar arquétipos de folclore e fantasia de domínio comum; **evitar criaturas e nomes que são marca registrada do cenário de origem** (ex.: os aberrantes de olho único flutuante, os devoradores de mente, as raças planares exclusivas) — criar versões próprias quando precisar desse papel.

| Bioma | Arquétipos que combinam | Ganchos |
|---|---|---|
| Floresta | lobos e feras, aranhas gigantes, espíritos da mata, fadas traiçoeiras, bandidos | Caça, trilhas perdidas, pactos com a floresta |
| Pântano | mortos-vivos, bruxas, povo-sapo, limos, fogos-fátuos | Doença, ilusões, rituais (Rituais no Pântano) |
| Montanha | ogros, trolls, grifos, serpes, gigantes, golens antigos | Minas, ninhos, ruínas anãs (Vera) |
| Estrada | bandidos, gnolls, cães selvagens, cavaleiros caídos | Caravanas, pedágios, emboscadas |
| Cidade | ladrões, cultistas, metamorfos, mortos-vivos nos esgotos, nobres corruptos | Intriga, espionagem, o povo como testemunha (Fama) |

### 11.3 Ficha de inimigo novo (checklist)

1. Arquétipo e **papel na história** (por que essa criatura, nesta missão, agora).
2. Bioma, **risco** e nível (comum, elite, chefe).
3. **O que quer** e **como se comporta** (foge? negocia? protege algo?).
4. Uma **fraqueza** que a rota pode revelar e uma **complicação** que pune o grupo errado.
5. Se for chefe: efeito de **covil** e, se lendário, uma regra especial.
6. Ficha de arte em `art/specs/inimigos/` no padrão das existentes.

---

## 12. Ideias candidatas (para o Roadmap, depois da v1.0)

Priorizar pelas que reforçam pessoas e consequências:

- [ ] Renome por facção (Conselho, Ordem, submundo) com benefícios e conflitos
- [ ] Títulos e honrarias por feitos, no Livro
- [ ] XP de marco por capítulo e missão pessoal
- [ ] Atividades de tempo livre: treino individual, pesquisa que revela o oculto, criação de itens na Forja
- [ ] Escola de magia e magias de ritual usáveis na guilda
- [ ] Item com vontade própria (Lâmina do Corvo)
- [ ] Condições físicas (veneno, doença) e aflições de curta/longa duração
- [ ] Atitude de PNJs recorrentes (hostil → aliado) ligada à Estima
- [ ] Traços de raça com sabor (sorte do halfling, resistência anã, tenacidade meio-orc, dois mundos da meio-elfa)
- [ ] Viés inicial do povo por raça que se desfaz com feitos (arco de reconhecimento)
- [ ] Tabela de criaturas por bioma para eventos de combate e guardas do alvo
- [ ] Efeito de covil no nó do alvo e regra especial para chefes lendários
- [ ] Missões de "bando" × "caçada" e fraquezas de inimigo reveladas na rota
