# GDD — A GUILDA
### "Quem você envia define quem eles se tornam"

**Versão:** 0.9 — Estresse, traços e mapa de expedição
**Gênero:** Gerenciamento narrativo / Estratégia leve / Drama de fantasia
**Inspiração mecânica:** Dispatch (despacho e consequência), Darkest Dungeon (estresse, aflições, acampamento), Slay the Spire e Cult of the Lamb (mapa de nós com bifurcações)
**Inspiração temática:** Fantasia medieval, tom de campanha de RPG de mesa
**Plataforma:** Godot 4.7 (desktop: Windows, Linux e macOS)
**Documentos relacionados:** [TDD](TDD.md) · [Balanceamento](BALANCEAMENTO.md) · [Narrativa](NARRATIVA.md) · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md) · [Análise e Melhorias](ANALISE_E_MELHORIAS.md)

> Este documento descreve o jogo **como ele é hoje**. Fórmulas detalhadas e números de calibragem estão no [Balanceamento](BALANCEAMENTO.md); elenco, capítulos e finais estão na [Narrativa](NARRATIVA.md); o que ainda não existe está no [Roadmap](ROADMAP.md).

---

## 1. Visão Geral

Você não é o herói. Você é quem **decide quem é o herói de cada história**.

Você é o(a) **Mestre de Despacho** da Guilda do Corvo Cinzento, uma guilda de aventureiros decadente. Pedidos chegam todos os dias e sua função é decidir **quem vai, com quem, e como** — e depois acompanhar a expedição pelo Mapa Mágico, decidindo o caminho quando o grupo chama.

O jogo não é sobre combate tático. É sobre gestão de gente complicada — egos, rivalidades, dívidas de honra, romances — e sobre como as escolhas moldam quem cada aventureiro se torna.

**Frase de direção:** *Não faça o jogador administrar números. Faça-o administrar pessoas.* A melhor party não é necessariamente a mais forte: é a que cria a melhor história.

---

## 2. Pilares de Design

1. **A escolha "ótima" raramente é a melhor escolha.** Mandar o mais forte nem sempre é certo se ele está em conflito com o grupo, exausto, estressado ou carregando um trauma ligado à missão.
2. **Consequência é narrativa, não só numérica.** Falhar não é *game over* — é um aventureiro voltando mudado, ferido, aflito, ressentido ou mais próximo de outro.
3. **A guilda é um elenco, não um inventário.** Cada aventureiro tem agenda própria, e o jogador aprende isso pelo comportamento, não por exposição forçada.
4. **A Party tem vida própria.** Um grupo entrosado é mais que a soma dos membros — com Ações de Vínculo que nenhum teria sozinho.
5. **Peso emocional com leveza de execução.** Jogabilidade simples na superfície, profundidade na escrita e nas ramificações.

**Hierarquia dos sistemas** (os de baixo nunca podem atrapalhar a leitura dos de cima):

| Nível | Sistemas |
|---|---|
| 1 — Essencial | Personagens → Relações → Party → Despacho → Consequência |
| 2 — Suporte | Moral, Fadiga, PV, Estresse |
| 3 — Progressão | XP, Nível, Talentos, Equipamento, Magias, Traços |
| 4 — Metagame | Guilda, Reputação, Melhorias, Economia |
| 5 — Narrativa | Capítulos, Flags, Missões pessoais, Finais |

---

## 3. Premissa Narrativa

A Guilda do Corvo Cinzento já foi referência na região — hoje é uma sombra do que foi, endividada e mal vista pelo Conselho de Guildas. O jogador assume o cargo de Mestre de Despacho, um cargo administrativo, não heroico.

O arco central: reconstruir a reputação da guilda enquanto descobre por que ela ruiu (uma traição interna e uma "lista de nomes" de alvos) e lida com um elenco de refugiados de outras guildas, fracassos redimidos e gente fugindo do próprio passado. Detalhes em [Narrativa](NARRATIVA.md).

---

## 4. Loop de Gameplay

```
1. Abertura do dia      → bastidores, ultimatos e pedidos de descanso aparecem no hub
2. Mural de Quests      → missões disponíveis, com risco, prazo, atributos e tags
3. Montagem de Party    → 1 a 4 aventureiros; preview de afinidade (nunca do resultado);
                          conjuradores preparam uma magia
4. Despacho             → Selo de Cera
5. Expedição            → Mapa Mágico: a cada bifurcação um herói chama e você escolhe o
                          caminho; eventos com teste d20, provisões, saque, estresse
6. Objetivo             → score da missão (atributos, afinidade, vínculos, poderes, mente,
                          rota, sorte) define o resultado
7. Resolução            → Sucesso Limpo / Sucesso com Custo / Falha com Revelação;
                          XP, saque, PV, moral, estresse, afinidade, eventos de vínculo
8. Guilda               → equipar, comprar, treinar duplas, mandar descansar, construir
9. Encerrar o dia       → recuperação, neglect, expiração, novos pedidos, salvamento automático
```

Cada capítulo dura de 5 a 6 dias e tem um objetivo; o resultado altera os capítulos seguintes.

---

## 5. Mecânicas Principais

### 5.1 Mural de Quests

- Cada missão tem: **tipo** (combate, diplomacia, exploração, furtividade), **risco** (baixo, médio, alto, lendário), **bioma**, **atributo primário e secundário**, **prazo** e, às vezes, **requisito oculto** (um herói específico muda o resultado, para melhor ou pior) e **tags de composição** (ex.: "exige um conjurador", "exige Senna").
- Missões chegam por dia dentro do capítulo; não resolvidas expiram e custam Reputação.
- Cada missão traz o **cartaz do inimigo** (chefe e, quando há, o guarda do alvo).

### 5.2 Montagem de Party

- **1 a 4 aventureiros** por missão. Mais gente não infla o score (a Base é média), mas aumenta Cobertura, número de pares (para o bem e para o mal) e esvazia o banco para as outras missões do dia.
- **Slots de despacho por dia:** 1 no início; 2 com Reputação 5; 3 com Reputação 12.
- **Fadiga:** Pronto (100%) → Cansado (60% do valor ponderado) → Exausto (não pode ir).
- O preview mostra a afinidade entre os selecionados (em palavras, sem o Quadro de Relações; em números, com ele), o estresse e as condições de cada um. **Nunca mostra o resultado.**
- Conjuradores com espaço de magia escolhem **uma magia preparada** para a missão.

### 5.3 Atributos

| Atributo | Uso |
|---|---|
| **Força** | Combate direto, obstáculos físicos |
| **Destreza** | Furtividade, fuga, precisão |
| **Conhecimento** | Investigação, rituais, runas, magia |
| **Carisma** | Diplomacia, negociação, liderança |
| **Resistência** | Recuperação de fadiga (≥ 7 recupera mais rápido) e chance de Virtude no ponto de ruptura |

Escala 1–10. Cada missão pesa o primário em 65% e o secundário em 35%. Nos testes do mapa, o modificador é **atributo − 5**.

### 5.4 Sistema de Afinidade

A Afinidade mede a relação entre dois aventureiros, de **−5 a +10**, e é **assimétrica**: Theo pode ter +4 com Lyssa enquanto Lyssa tem +1 com Theo.

**Regra do par:** para qualquer efeito mecânico vale o **menor** dos dois valores. O valor maior aparece só na narrativa e no tooltip do Quadro — um lado quer mais do que o outro.

| Faixa | Rótulo | Modificador |
|---|---|---|
| −5 a −3 | Conflito Aberto | −4 |
| −2 a −1 | Tensão Velada | −2 |
| 0 | Neutros | 0 |
| +1 a +2 | Camaradas | +2 |
| +3 a +5 | Companheiros | +4 |
| +6 a +8 | Laço Forte | +6 (habilita Ação de Vínculo) |
| +9 a +10 | Dupla Lendária | +8 |

**Visibilidade:** sem o upgrade **Quadro de Relações**, o jogador só vê impressões ("parecem mais próximos"). Com ele, vê números, faixas, os dois lados de cada par e (com o **Arquivo**) o histórico da dupla.

**Como evolui:**

| Gatilho | Variação |
|---|---|
| Missão juntos com Sucesso Limpo | +1 |
| Missão juntos com Falha | −1 |
| Sucesso com Custo: um protege o outro (chance) | +2 |
| Falha: um culpa o outro (chance) | −2 / −1 |
| Neglect: par a partir de +3 sem missão juntos por 3 dias | −1 (nunca abaixo do valor inicial) |
| Eventos de bastidor, acampamento na rota, Salão de Treinamento | +1 a +2 (ou −, conforme a escolha) |

**Eventos de limiar:** ao cruzar +3, +6, +9, −3 e −5, o jogador escolhe o rótulo do vínculo (Amizade, Mentoria, Atração, Rivalidade Saudável, Parceria Lendária, Romance, Irmandade, Rancor, Ruptura...).

### 5.5 Ações de Vínculo

Com o par em **Laço Forte (+6)** e o rótulo certo, a ação vale sempre que forem juntos:

| Rótulo | Ação | Efeito |
|---|---|---|
| Amizade Profunda | Cobertura Mútua | Na falha, um absorve o custo e o outro volta ileso |
| Mentoria | Impulso do Mentor | O mais fraco do par ganha +3 nos atributos da missão |
| Atração | Esforço Extra | +2 no score, mas os dois voltam Exaustos |
| Rivalidade Saudável | Competição | Os dois valem o melhor dos dois na Base |
| Parceria Lendária | Sincronia Perfeita | +3 no score; falha vira Sucesso com Custo |
| Irmandade | Até o Fim | Se um deixar a guilda, o outro parte junto |

### 5.6 Score da Missão

```
Score = Base + Cobertura + Afinidade + Vínculo + Poderes + Oculto + Mente + Povo + Rota + Sorte
```

| Termo | Origem |
|---|---|
| Base | Média dos membros de `0,65 × Primário + 0,35 × Secundário` (× 0,6 se Cansado) |
| Cobertura | +1 por membro com primário ≥ 7, até +2 |
| Afinidade | Média dos modificadores dos pares + efeitos de afinidade (itens, traços, condições) |
| Vínculo | Ações de Vínculo ativas |
| Poderes | Itens, talentos e magias preparadas, até +3 |
| Oculto | Requisito oculto da missão |
| Mente | Virtudes, aflições e traços do grupo, até ±3 |
| Povo | Fama do grupo no povo, só em diplomacia, −1 a +2 |
| Rota | Preparação − desgaste − fome do mapa de expedição, de −2 a +3 |
| Sorte | Inteiro de −2 a +2 |

O resultado sai da tabela de limiares por risco (ver [Balanceamento](BALANCEAMENTO.md)).

**Resultado contado em frases:** a tela não mostra a conta; mostra **por que** deu assim, em até três momentos escolhidos pelo que mais pesou (um par em sinergia ou em conflito, uma Ação de Vínculo, o herói que se destacou, alguém cansado ou aflito, a preparação ou a fome da rota, a sorte). Cada momento tem uma frase e uma cena ilustrada; pares importantes têm frase e cena próprias (*"Vera e Bram lutaram como uma só lâmina."*). A soma completa fica em "ver detalhes". Textos em `data/result_story.json`.

### 5.7 Moral, Descanso e Saída

- **Moral** 0–10: +1 no Sucesso Limpo, −1 na Falha (−1 extra para quem foi sozinho e não teve sucesso limpo), −1 se ficar 4 dias sem ser despachado, +1 no descanso; eventos de bastidor e missões pessoais também mexem.
- **Descanso ativo:** o jogador manda um herói descansar — ele fica o dia fora, mas recupera toda a fadiga, metade dos PV, as magias, +1 de moral, alivia 5 de estresse e cura aflições. Quem está esgotado, muito ferido ou aflito **pede descanso**; ignorar custa 1 de moral.
- **Ultimato:** com moral ≤ 1 o herói ameaça sair. Opções: pagar bônus (40 ouro), dar folga, prometer a próxima missão (2 dias) ou deixar partir. Ignorado por um dia, ele vai embora; promessa não cumprida também. O equipamento volta ao Baú.

### 5.8 Consequências

- Toda missão termina em **Sucesso Limpo**, **Sucesso com Custo** (alguém ferido, item gasto, NPC ofendido) ou **Falha com Revelação** (a missão fracassa, mas expõe algo do mundo ou de um personagem). Falha é gancho, não beco sem saída.
- Resultados mudam afinidade, moral, estresse, reputação, ouro e **flags** que alteram capítulos e finais.
- Missões podem ter **efeitos por resultado** (moral de um herói específico, flag, texto extra).

### 5.9 Mapa de Expedição

A missão vira um **grafo em camadas** (3 a 4 camadas de 2–3 nós, mais o objetivo), sorteado pelo bioma e pelo risco. O jogador:

1. vê só a próxima camada (o resto fica sob **névoa**; o objetivo e o guarda do alvo sempre aparecem);
2. clica no próximo nó; o grupo anda até lá;
3. o **herói mais apto chama pelo Mapa Mágico** e apresenta a situação e as opções;
4. cada opção pode ter **teste d20 + (atributo − 5)** contra uma CD por risco (20 sempre passa, 1 sempre falha) e pode exigir ouro ou provisões. O teste é encenado: um **d20 é arremessado sobre o mapa**, gira, quica e para na face do resultado, enquanto o painel mostra quem testa, a CD e, ao parar, a conta e o veredito.

Os heróis andam pelo mapa como **miniaturas de RPG de mesa** (base na cor de cada um); quem chama fica à frente com um balão "!".

| Nó | Função |
|---|---|
| Combate | Saque e preparação; risco de ferimento e estresse |
| Tesouro | Ouro e itens; às vezes armadilha |
| Mercador | Itens e provisões com o ouro da guilda |
| Acampamento | Cura, comida, conversa (afinidade), planejamento |
| Encontro | Evento narrativo; inclui eventos de perda (arma, comida, sanidade) |
| Atalho | Pula uma camada, com teste |
| Estranho (NPC) | Mercenária, eremita, guia traidor |
| Santuário | Oração (alivia estresse), bênção ou maldição, oferendas |
| Guarda do alvo | Miniboss obrigatório em missões de risco médio para cima |
| Objetivo | Resolve a missão |

**Estado da expedição:** provisões (cada passo gasta 1; sem comida é fome), bolsa da rota, itens achados, preparação contra o alvo e dias de atraso. No fim: o saque da rota chega inteiro no sucesso, pela metade no custo e se perde na falha; atrasos deixam o grupo fora da guilda por mais dias.

**Design intent:** o jogador continua **não controlando** combate nem heróis — ele decide *para onde* o grupo vai e *como* responder quando chamam. A tensão de decidir antes (party) se soma à de decidir durante (rota), sem virar RPG tático.

### 5.10 Estresse, Aflições, Virtudes e Traços

- **Estresse** 0–10. Sobe com falhas, missões de risco alto, fome e eventos assustadores; cai no santuário, acampamento, dias ociosos e descanso.
- **Ponto de ruptura:** no máximo, o herói testa a vontade (Resistência ajuda). **Virtude** (Corajoso, Focado, Estoico, Inspirador) dura 2 missões; **Aflição** (Paranoico, Egoísta, Desesperado, Irracional, Medroso) dura até um descanso. Com a aflição ativa e o estresse ainda no máximo, cada novo estresse vira colapso (−1 PV).
- **Traços** permanentes, positivos ou negativos, ganhos em missões e eventos (ex.: Pele Dura, Sangue-Frio, Medo do Escuro, Claustrofóbico). Até 4 por herói; alguns valem só em um bioma.
- Ideia central: *o personagem não volta apenas ferido; ele pode voltar diferente.*

### 5.11 Progressão (RPG leve)

- **XP e nível** (até 10): XP por risco × resultado. A cada nível, +1 em um atributo à escolha; nos níveis 3, 5, 7 e 9, uma magia ou talento.
- **Classes:** Paladino, Ladina, Maga, Guerreira, Bardo, Clérigo. Conjuradores têm espaços de magia (recuperados no descanso) e podem curar na guilda.
- **Equipamento:** arma, armadura (leve/média/pesada conforme a classe), acessório e dois consumíveis. Saque por risco e resultado; mercado na guilda e mercador na rota.

### 5.12 Guilda e Metagame

- **Reputação:** sobe com sucessos, cai com falhas e missões expiradas; libera slots e melhorias.
- **Ouro:** recompensa por risco; gasto em melhorias, mercado, ultimatos e opções da rota.
- **Melhorias:** Quadro de Relações, Enfermaria, Arquivo da Guilda, Salão de Treinamento — e as **ocultas**, que só aparecem quando um bastidor as revela e depois são construídas com ouro: Forja de Dorin (+1 em combate), Biblioteca do Arquivista (+15% XP), Capela da Guilda (−1 de estresse ganho), Estábulo (volta menos cansado), Taverna da Guilda (+1 de moral depois de cada missão). O efeito vale para todos os heróis.
- **A cidade e o povo:** cada herói tem **Fama no povo** (−5 a 10: malvisto, desconhecido, conhecido, querido, lenda do povo) e a guilda tem **Estima da cidade** (0 a 20), separada da Reputação com o Conselho. Sobem e descem com bastidores e com missões vistas pelo povo (na cidade e na estrada: limpo +1, falha −1); missão expirada custa estima. Cidade desconfiada encarece o mercado; grata dá desconto e paga 15% a mais nas missões; em missões de **diplomacia**, a fama do grupo entra no score (termo **Povo**, −1 a +2).
- **Bastidores:** até 2 cenas por dia na guilda e na cidade (taverna, treino, discussões, segredos, a praça, a viúva, o beco dos doentes, a festa da cidade), com escolhas que mexem em afinidade, moral, estresse, fama, estima e ouro; algumas revelam melhorias; outras dependem de capítulo, flag ou estima.
- **Salvar e carregar:** 3 espaços + automático ao fim de cada dia.

---

## 6. Elenco

Sete aventureiros (Corin entra no Capítulo 2). Fichas completas, relações iniciais e arcos em [Narrativa](NARRATIVA.md).

| Nome | Arquétipo | Classe | Destaque | Fraqueza |
|---|---|---|---|---|
| Theo | O Paladino Caído | Paladino | Força 8, Resistência 7 | Recusa ordens contra seu código |
| Lyssa | A Ladina Cética | Ladina | Destreza 9 | Desconfia de quase todos |
| Mira | A Erudita Frágil | Maga | Conhecimento 9 | Força 2, Resistência 3 |
| Senna | A Mercenária Pragmática | Guerreira | Força 7, Destreza 6 | Carisma 3, relações negativas |
| Bram | O Novato Idealista | Bardo | Carisma 7 | Resistência 3, quebra sob pressão |
| Vera | A Guerreira Veterana | Guerreira | Força 9, Resistência 8 | Carisma 3 |
| Corin | O Clérigo Errante | Clérigo | Conhecimento 7, cura | Chega no meio da história |

---

## 7. Estrutura de Conteúdo

- **Ato 1 — A Herança do Corvo:** Capítulo 1 "Herança de Cinzas" (Reputação 6+) e Capítulo 2 "Ecos do Corvo" (sobreviver à Noite do Corvo).
- **Ato 2 — A Lista de Nomes:** Capítulo 3 "Nomes na Lista" (convencer o Conselho) e Capítulo 4 "O Ninho do Corvo" (missão final lendária, exige 4 aventureiros).
- **Missões pessoais:** O Irmão de Senna, A Última Carta (Mira), O Julgamento da Ordem (Theo).
- **Epílogo:** quatro finais, um desfecho por herói e uma linha por vínculo formado.

Total atual: 24 missões, 14 eventos de bastidor, 4 capítulos, 4 finais.

---

## 8. Telas

1. **Título** — Continuar, Novo jogo, Carregar.
2. **Hub da Guilda** — mural de quests, elenco com status, bastidores, ultimatos, menu.
3. **Montagem de Party** — elenco, party selecionada, preview de afinidade, magias.
4. **Mapa Mágico** — pergaminho com o mapa de expedição clicável e as miniaturas dos heróis; painel com grupo (PV, estresse, condição), estado da rota, log, chamadas e o painel do teste com o d20 arremessado.
5. **Resolução** — cartaz do inimigo (riscado na vitória), texto, soma do score, mudanças de vínculo.
6. **Evento de Vínculo** e **Bastidor** — cena curta com escolhas.
7. **Quadro de Relações** — grade com retratos, faixas, os dois lados de cada par e histórico.
8. **Livro da Guilda** — livro de couro aberto sobre a mesa, com páginas de pergaminho e moldura ornamental; ficha estilo D&D em duas páginas (identidade, PV, moral, estresse, condição, traços, XP, equipamento, atributos, talentos, personalidade, afinidades).
9. **Guilda** (melhorias), **Mercado**, **Equipamento**, **Treinamento**, **Subida de nível**, **Ultimato**, **Abertura/fim de capítulo**, **Epílogo**.

---

## 9. Direção de Arte e Som

- **Arte:** pixel art detalhada — retratos dos heróis, cartazes dos inimigos, tela de título, ícones dos itens, miniaturas dos heróis, páginas e capa do Livro, ícone do jogo e as faces do d20. O Mapa Mágico é um pergaminho com peças a nanquim por bioma. Especificações (JSON) e índice de produção em `art/specs/`; o que ainda não chegou é desenhado por código.
- **Game juice:** sóbrio, a serviço da consequência — o Selo de Cera carimba o despacho, o d20 é arremessado nos testes, a barra do score enche até o veredito, rupturas e saídas ganham cena própria, o dia vira como uma vela apagando. Opção "Reduzir movimento" para acessibilidade.
- **UI:** paleta quente de madeira e pergaminho; a Montagem de Party tem peso visual por ser a decisão mais importante.
- **Som:** ainda não implementado (ver [Roadmap](ROADMAP.md)). Direção: folk acústico leve na guilda, percussão mínima na montagem, ambiente por bioma no mapa.

---

## 10. Filosofia para Novas Mecânicas

Antes de implementar algo novo, responder:

1. Isso melhora as **decisões** do jogador?
2. Isso melhora os **personagens**?
3. Isso cria **histórias diferentes**?
4. Isso adiciona **profundidade** ou só complexidade?

Se as três primeiras respostas forem "não", a mecânica provavelmente não é necessária. Conteúdo novo entra preferencialmente pelos arquivos de dados, não por código específico.

---

*Versão 0.9 — Rafael Jr / A Guilda. Atualizado em 2026-10-07 para refletir o estado real do projeto.*
