# GDD — A GUILDA
### "Quem você envia define quem eles se tornam"

**Versão:** 0.2 — Sistema de Party e Afinidade  
**Gênero:** Gerenciamento narrativo / Estratégia leve / Drama de fantasia  
**Inspiração mecânica:** Dispatch (AdHoc Studio) — loop de despacho + consequência narrativa  
**Inspiração temática:** Fantasia medieval, tom de campanha de RPG de mesa  
**Plataforma alvo do protótipo:** Browser (HTML/JS)  
**Changelog v0.3.1:** Fórmula de score normalizada (média em vez de soma), regra do par assimétrico (vale o menor valor), fadiga em três estados (Pronto/Cansado/Exausto), atributos completos do elenco, novos limiares calibrados.  
**Changelog v0.2:** Adição completa do Sistema de Party, Sistema de Afinidade com grades de compatibilidade, estados de vínculo evolutivos e mecânica de bônus de party consolidada.

---

## 1. Visão Geral

Você não é o herói. Você é quem **decide quem é o herói de cada história**.

Você assumiu a administração de uma guilda de aventureiros decadente, recém-herdada ou conquistada em uma aposta (a definir na narrativa). Pedidos de missão chegam todos os dias — resgatar uma vila, escoltar uma caravana, investigar ruínas, lidar com uma disputa entre nobres. Sua função é olhar o mural de quests e decidir **quem vai, com quem, e como**.

O jogo não é sobre combate tático. É sobre gestão de gente complicada com poder de matar dragões — egos, rivalidades, dívidas de honra, romances proibidos entre classes — e sobre como as escolhas erradas (ou certas demais) moldam quem cada aventureiro se torna.

A v0.2 aprofunda a pergunta central: **não é só *quem* vai, mas *quem vai junto*.**

---

## 2. Pilares de Design

1. **A escolha "ótima" raramente é a melhor escolha.** Mandar o mais forte nem sempre é certo se ele está em conflito com o grupo, exausto ou carregando um trauma relevante para aquela missão específica.
2. **Consequência é narrativa, não só numérica.** Falhar uma missão não é "game over" — é um aventureiro voltando mudado, ferido, ressentido ou mais próximo de outro.
3. **A guilda é um elenco, não um inventário.** Cada aventureiro tem agenda própria, e o jogador aprende isso através de como eles se comportam quando despachados — não por exposição forçada.
4. **A Party tem vida própria.** Um grupo bem entrosado não é a soma de seus membros — é algo novo, com dinâmica e bônus que nenhum dos três teria sozinho.
5. **Peso emocional com leveza de execução.** Jogabilidade simples na superfície, profundidade na escrita e nas ramificações.

---

## 3. Premissa Narrativa

A Guilda do Corvo Cinzento já foi referência na região — hoje é uma sombra do que foi, endividada e mal vista pelo Conselho de Guildas. O jogador assume como **Mestre(a) de Despacho**, um cargo administrativo, não um cargo heróico.

Arco central possível: reconstruir a reputação da guilda enquanto descobre por que ela ruiu — e lida com um elenco de aventureiros que são, em boa parte, refugiados de outras guildas, fracassos redimidos ou gente fugindo do próprio passado.

*(Esse gancho narrativo é só uma sugestão de ponto de partida — a estrutura mecânica abaixo funciona com qualquer premissa.)*

---

## 4. Loop de Gameplay

```
1. Mural de Quests     → aparecem 2-4 missões disponíveis no dia
2. Análise             → jogador revisa requisitos da missão + estado do elenco + afinidades
3. Montagem de Party   → seleciona de 1 a 4 aventureiros; sistema exibe preview de bônus/penalidades
4. Despacho            → confirma o envio com o Selo de Cera
5. Resolução           → resultado calculado (atributos + afinidade de party + fadiga + sorte)
6. Cena Narrativa      → texto/ilustração curta reagindo ao resultado; pode evoluir vínculos
7. Avanço de Tempo     → aventureiros voltam, descansam, eventos de bastidor disparam
```

Cada "dia" de jogo dura entre 3 e 6 minutos de decisão real.

---

## 5. Mecânicas Principais

### 5.1 Mural de Quests

- Cada missão tem: **tipo** (combate, diplomacia, exploração, furtividade), **risco** (baixo/médio/alto), **prazo** (algumas são urgentes) e **requisito oculto** (algo que só fica claro ao tentar, ex: "essa escolta vai por território onde o Cavaleiro Renegado é procurado").
- Missões não resolvidas expiram e geram consequência própria (vila perdida, reputação cai, NPC recorrente guarda rancor).
- Algumas missões têm **tag de composição obrigatória**: ex, "Requer pelo menos um especialista em magia" ou "Proibido enviar alguém com passagem criminal na região" — introduzem restrições além dos atributos.

---

### 5.2 Montagem de Party

A montagem de party é a tela central do jogo — a principal decisão que o jogador toma a cada rodada.

**Regras básicas:**
- O jogador pode montar uma party de **1 a 4 aventureiros** para cada missão.
- Cada aventureiro tem um **estado de fadiga**: **Pronto** → **Cansado** → **Exausto**.
  - **Pronto:** contribui com 100% dos atributos.
  - **Cansado:** pode ser selecionado, mas contribui com **60%** (−40%) do seu valor ponderado. O preview mostra o aviso.
  - **Exausto:** **não pode ser selecionado** até descansar.
  - Após uma missão, o aventureiro fica Cansado; se a missão for de risco alto ou ele já estava Cansado, fica Exausto. Cada dia de descanso recupera um estado (Resistência ≥ 7 recupera dois).
- Ao selecionar cada membro, a interface atualiza em tempo real um **Preview de Party**: mostra o bônus ou penalidade de afinidade já acumulado com os membros já selecionados.
- O jogador nunca vê o resultado antes de confirmar — só vê os *indicadores*, não a pontuação final.

**Custo de mandar muita gente:**
- Mandar 4 aventureiros em uma missão de risco baixo é um desperdício — deixa o banco fraco para missões simultâneas.
- Missões diferentes podem ocorrer no mesmo dia; o jogador precisa dividir o elenco entre elas.

**Slots de missão por dia:**
- No início do jogo: 1 missão ativa por vez.
- Com upgrades de guilda: até 3 missões simultâneas — exigindo que o jogador divida um elenco limitado de 6–8 pessoas.

---

### 5.3 Atributos dos Aventureiros

| Atributo | Afeta principalmente |
|---|---|
| **Força** | Missões de combate direto, derrubar obstáculos físicos |
| **Destreza** | Furtividade, fuga, precisão em situações de risco |
| **Conhecimento** | Investigação, rituais, decifrar runas, magia |
| **Carisma** | Diplomacia, negociação, calmar populações, liderança de party |
| **Resistência** | *(novo v0.2)* Reduz a fadiga acumulada após missões longas; aventureiros com alta Resistência voltam prontos mais rápido |

Cada missão exige um **atributo primário** (peso 65%) e um **atributo secundário** (peso 35%). A party ideal cobre os dois — mas raramente alguém é excelente em ambos.

**Atributos do elenco base (escala 1–10):**

| Herói | For | Des | Con | Car | Res |
|---|---|---|---|---|---|
| Theo | 8 | 4 | 5 | 5 | 7 |
| Lyssa | 3 | 9 | 6 | 4 | 5 |
| Mira | 2 | 4 | 9 | 6 | 3 |
| Senna | 7 | 6 | 3 | 3 | 6 |
| Bram | 5 | 5 | 5 | 7 | 3 |
| Vera | 9 | 4 | 3 | 3 | 8 |

---

### 5.4 Sistema de Afinidade

A Afinidade é o eixo central da montagem de party. Ela mede a relação emocional e funcional entre dois aventureiros específicos — e evolui ao longo do jogo.

#### 5.4.1 Nível de Afinidade

Cada par de aventureiros tem um **valor de Afinidade** que vai de **-5 a +10**:

| Faixa | Rótulo | Efeito na party |
|---|---|---|
| -5 a -3 | **Conflito Aberto** | Penalidade grave (-4 no score total do par) |
| -2 a -1 | **Tensão Velada** | Penalidade leve (-2); não se sabotam, mas não colaboram |
| 0 | **Neutros** | Sem modificador |
| +1 a +2 | **Camaradas** | Bônus leve (+2); funcionam juntos |
| +3 a +5 | **Companheiros** | Bônus médio (+4); cobertura mútua em risco |
| +6 a +8 | **Laço Forte** | Bônus alto (+6) + desbloqueio de **Ação de Vínculo** |
| +9 a +10 | **Dupla Lendária** | Bônus máximo (+8) + **Ação de Vínculo Rara** desbloqueada |

O valor de Afinidade entre dois aventureiros **não é visível diretamente** no início — o jogador aprende observando comportamentos, falas nos diálogos de bastidor e o resultado das missões em que foram juntos. Com upgrades de guilda (quadro de relações), ele se torna visível.

#### 5.4.2 Como a Afinidade Evolui

A Afinidade entre dois aventureiros muda com base em:

| Gatilho | Variação |
|---|---|
| Despachados juntos em missão com sucesso limpo | +1 |
| Despachados juntos em missão com falha | -1 |
| Um salva o outro (evento narrativo de sucesso com custo) | +2 |
| Um culpa o outro na cena pós-missão | -2 |
| Ficam muito tempo sem ser despachados juntos (neglect) | -1 (por 3 dias) |
| Jogador escolhe o lado de um no conflito pós-missão | +2 para quem foi apoiado / -1 para o outro |
| Evento de bastidor (cena na taverna, treino conjunto) | +1 a +2 |

A evolução é **bidirecional mas assimétrica** — Theo pode ter Afinidade +4 com Lyssa, mas Lyssa ter +1 com Theo.

**Regra do par:** para qualquer efeito mecânico (modificador de score, faixa, Ação de Vínculo, eventos de limiar), vale o **menor dos dois valores**. Um vínculo é tão forte quanto o lado mais frio. O valor maior aparece apenas na narrativa (falas, cenas de bastidor), sinalizando que um lado quer mais do que o outro. A tabela inicial (5.4.4) é simétrica; a assimetria surge com a evolução.

#### 5.4.3 Estados de Vínculo (Pontos de Evolução Narrativa)

Quando a Afinidade de um par atravessa certos limiares, um **evento de bastidor** é acionado — uma cena curta na tela da guilda que define o caráter do vínculo. O jogador pode ter escolha em como esse vínculo se rotula:

| Limiar | Evento disparado | Exemplos de rótulo disponíveis |
|---|---|---|
| Afinidade atinge +3 | "Algo mudou entre eles" | Amizade / Lealdade / Rivalidade Saudável |
| Afinidade atinge +6 | "Um vínculo se forma" | Amizade Profunda / Mentoria / Atração |
| Afinidade atinge +9 | "Não é mais só trabalho" | Parceria Lendária / Romance / Irmandade |
| Afinidade cai para -3 | "A tensão explodiu" | Rivalidade / Rancor / Ruptura |
| Afinidade cai para -5 | "Isso não tem conserto fácil" | Inimizade Declarada |

O **rótulo escolhido** define o tipo de Ação de Vínculo desbloqueada (ver seção 5.5).

#### 5.4.4 Tabela de Afinidade Inicial (Elenco Base)

| | Theo | Lyssa | Mira | Senna | Bram | Vera |
|---|---|---|---|---|---|---|
| **Theo** | — | -3 | +1 | -2 | +2 | +3 |
| **Lyssa** | -3 | — | +4 | -1 | +1 | 0 |
| **Mira** | +1 | +4 | — | -2 | +2 | +1 |
| **Senna** | -2 | -1 | -2 | — | -1 | +2 |
| **Bram** | +2 | +1 | +2 | -1 | — | +4 |
| **Vera** | +3 | 0 | +1 | +2 | +4 | — |

> **Nota de design:** Senna começa com relações negativas com quase todos — ela é o maior risco e a maior recompensa do elenco. Vera e Bram formam a "dupla segura" desde o início, mas isso cria dependência que o jogador precisa quebrar para crescer.

---

### 5.5 Ações de Vínculo

Quando um par atinge **Laço Forte (+6)** e o vínculo é rotulado, uma **Ação de Vínculo** fica disponível exclusivamente para aquele par quando despachados juntos. Ela é ativada automaticamente em momentos críticos da missão — o jogador não aciona, mas pode ver o resultado na cena narrativa.

| Rótulo do Vínculo | Ação de Vínculo | Efeito mecânico |
|---|---|---|
| **Amizade Profunda** | "Cobertura Mútua" | Se a missão falhar, um dos dois absorve o custo — o outro volta ileso |
| **Mentoria** | "Impulso do Mentor" | O aventureiro mais fraco ganha bônus de +3 temporário nos atributos da missão |
| **Atração** | "Esforço Extra" | +2 no score final, mas ambos ficam Exaustos independente do resultado |
| **Rivalidade Saudável** | "Competição" | Na Base, o valor ponderado dos dois é substituído pelo do melhor dos dois (em vez de entrar na média) |
| **Parceria Lendária** | "Sincronia Perfeita" | +3 no score; a missão nunca resulta em "Falha com revelação" para esse par |
| **Irmandade** | "Até o Fim" | Se um sair da guilda por qualquer motivo, o outro parte junto — ou fica, mas com Afinidade -5 com o jogador |

As Ações de Vínculo Raras (Afinidade +9 a +10) adicionam efeitos narrativos além dos mecânicos — desbloqueiam linhas de diálogo, missões exclusivas para aquela dupla, ou revelações de lore sobre os personagens.

---

### 5.6 Cálculo de Score da Missão

O resultado de cada missão é calculado pela fórmula:

```
Score = Base + Cobertura + Afinidade + Vínculo + Sorte
```

| Termo | Cálculo | Faixa |
|---|---|---|
| **Base** | Para cada membro: `0,65 × Primário + 0,35 × Secundário` (× 0,6 se Cansado). Base = **média** dos membros. | 1 a 10 |
| **Cobertura** | +1 por membro com atributo primário ≥ 7, **máximo +2**. | 0 a +2 |
| **Afinidade** | **Média** dos modificadores de todos os pares da party (tabela 5.4.1, usando o menor valor do par). Party de 1 = 0. | −4 a +8 |
| **Vínculo** | Bônus da Ação de Vínculo ativada (5.5), se houver. | 0 a +3 |
| **Sorte** | Aleatório inteiro. | −2 a +2 |

**Por que média e não soma:** mandar mais gente não infla o score. Ter mais membros dilui um especialista, mas aumenta a Cobertura e o risco de um par ruim contaminar a party. O verdadeiro custo de mandar 4 é esvaziar o banco para as outras missões do dia (5.2).

**Limiares de resultado por risco:**

| Risco | Falha com Revelação | Sucesso com Custo | Sucesso Limpo |
|---|---|---|---|
| Baixo | < 6 | 6–8 | ≥ 9 |
| Médio | < 8 | 8–10 | ≥ 11 |
| Alto | < 10 | 10–12 | ≥ 13 |
| Lendário *(Ato 3)* | < 13 | 13–15 | ≥ 16 |

**Referências de calibragem** (missão de Força + Carisma, sem sorte):

| Party | Score | Leitura |
|---|---|---|
| Vera sozinha | 7,9 | Resolve risco baixo; no médio, quase sempre com custo |
| Theo + Bram (Camaradas) | 9,3 | Limpo no baixo, custo no médio |
| Vera + Bram (Companheiros) | 11,3 | A "dupla segura": limpo no médio |
| Vera + Bram + Theo | 11,8 | Ganho pequeno por um membro a mais |
| Theo + Lyssa (Conflito Aberto) | 2,2 | Desastre garantido |
| Theo + Lyssa + Mira + Senna | 6,2 | Um par em conflito puxa a party inteira para baixo |

O melhor score possível com o elenco inicial é **12,9**: Sucesso Limpo em risco alto **exige** afinidade evoluída ou Ação de Vínculo. Missões Lendárias exigem Laço Forte ou Dupla Lendária. O fator de Sorte garante que mesmo uma party perfeita pode ter custo — e uma party improvável pode surpreender.

---

### 5.7 Sistema de Moral Individual

- Cada aventureiro tem uma barra de **Moral** (0–10) independente da Afinidade.
- Moral afeta a disponibilidade: um aventureiro com Moral muito baixa pode **recusar uma missão**, exigir conversa antes de aceitar, ou sair da guilda se ignorado por muitos dias.
- Moral sobe com: missões bem-sucedidas, ser despachado junto de alguém de quem gosta, eventos de bastidor positivos.
- Moral cai com: falhas consecutivas, ser mandado sozinho sempre, conflito com o jogador em diálogos.

---

### 5.8 Consequências e Ramificações Narrativas

- Toda missão gera uma de três saídas: **Sucesso limpo**, **Sucesso com custo** (machucado, item perdido, NPC ofendido), ou **Falha com revelação** (a missão fracassa, mas expõe algo sobre um personagem ou o mundo).
- **"Falha" nunca é um beco sem saída** — é tratada como gancho de história.
- O resultado da missão pode **evoluir Afinidade** entre os membros despachados — tanto positivamente quanto negativamente, conforme a cena narrativa.
- Certas combinações de party + resultado desbloqueiam **cenas especiais** que não aparecem de outra forma (ex: Vera e Bram sobrevivendo juntos a uma falha gera uma cena de confiança que eleva a Afinidade para o estado de Mentoria).

---

### 5.9 Minigame Opcional

Como o hacking em Dispatch, pode existir um minigame leve ligado a tipos específicos de missão — ex: decifrar runas para missões de Conhecimento, QTE de timing de fuga para Destreza. Pode ser cortado do MVP sem perda estrutural.

---

## 6. Elenco de Aventureiros (Versão Completa v0.2)

| Nome | Arquétipo | Pontos fortes | Ponto fraco | Traço de Afinidade |
|---|---|---|---|---|
| **Theo** | O Paladino Caído | Força 8, Resistência 7 | Carisma 5 — recusa ordens que contradizem seu código | Forma laços lentos mas leais; vínculo com Vera cresce rápido |
| **Lyssa** | A Ladina Cética | Destreza 9, Carisma 4 | Tensão inicial com quase todos; melhora com convivência | Desconfia, mas lembra cada ato de honestidade |
| **Mira** | A Erudita Frágil | Conhecimento 9, Carisma 6 | Força 2 — insiste em ir a missões perigosas | Cria laços intelectuais; Afinidade cresce com Lyssa e Bram |
| **Senna** | A Mercenária Pragmática | Força 7, Destreza 6 | Carisma 3 — melhor sozinha, piora a dinâmica de grupos | Nunca inicia vínculo; responde a provas de lealdade |
| **Bram** | O Novato Idealista | Carisma 7, atributos medianos | Baixa Resistência — quebra rápido sob pressão | Afinidade cresce rápido no início, mas pode regredir se decepcionado |
| **Vera** | A Guerreira Veterana | Força 9, Resistência 8 | Carisma 3 — liderança intimidante, não inspiradora | Vínculo de Mentoria com Bram é o mais acessível do jogo |

---

## 7. Progressão da Guilda

- **Reputação da Guilda**: sobe com sucessos, abre missões de risco/recompensa maior.
- **Quadro de Relações** *(upgrade)*: revela visualmente a grade de Afinidade — antes disso, o jogador trabalha com observação e intuição.
- **Enfermaria** *(upgrade)*: reduz tempo de recuperação de Exaustão.
- **Salão de Treinamento** *(upgrade)*: permite eventos de bastidor entre aventureiros, acelerando ganho de Afinidade ativamente.
- **Arquivo da Guilda** *(upgrade)*: registra o histórico de cada par — quais missões fizeram juntos, qual foi o resultado, que cenas desbloquearam.
- **Slots de Missão Simultânea**: 1 → 2 → 3, conforme a Reputação cresce.

---

## 8. Telas Principais

1. **Tela da Guilda** — hub central: mural de quests, elenco disponível, upgrades, eventos de bastidor ativos.
2. **Mural de Quests** — lista de missões com ícones de tipo/risco/prazo/tag de composição.
3. **Tela de Montagem de Party** — grid de aventureiros disponíveis; ao selecionar cada um, a interface mostra o preview de Afinidade com os já selecionados. Confirma com o Selo de Cera.
4. **Tela de Resolução** — cena curta de texto/ilustração com o resultado e a variação de Afinidade.
5. **Quadro de Relações** *(desbloqueável)* — mapa visual da grade de Afinidade, histórico de vínculos e Ações de Vínculo ativas.

### Wireframe: Tela de Montagem de Party

```
┌─────────────────────────────────────────────────────────┐
│  MISSÃO: Escolta da Caravana de Especiarias  [MÉDIO]    │
│  Atributo: Força + Carisma  |  Prazo: 3 dias            │
├──────────────────────┬──────────────────────────────────┤
│  AVENTUREIROS        │  PARTY SELECIONADA               │
│                      │                                  │
│ [Theo   ] [+] Pronto │  → Theo (For 8 / Car 5)          │
│ [Lyssa  ] [+] Pronto │  → Bram (For 5 / Car 7)          │
│ [Mira   ] [+] Pronto │                                  │
│ [Senna  ] [−] Exausta│  AFINIDADE DA PARTY:             │
│ [Bram   ] [+] Pronto │  Theo ↔ Bram  +2  [Camaradas]    │
│ [Vera   ] [+] Pronto │                                  │
│                      │  Score estimado: ████░░ Médio    │
│                      │  ⚠ Requisito oculto detectado?   │
├──────────────────────┴──────────────────────────────────┤
│           [  🪨 DESPACHAR PARTY  ]                      │
└─────────────────────────────────────────────────────────┘
```

---

## 9. Estrutura de Conteúdo

Formato episódico:

- **Ato 1 (Capítulos 1-2):** introdução do elenco, afinidades iniciais apresentadas por comportamento (não por número). Primeiras fricções.
- **Ato 2 (Capítulos 3-5):** primeiros Laços Fortes se formam ou se quebram. Decisões de party têm peso real — quem você sempre manda junto está evoluindo um vínculo que você pode não querer.
- **Ato 3 (Capítulos 6-8):** Ações de Vínculo determinam missões impossíveis. Final variável conforme vínculos consolidados, Reputação e quem ainda está na guilda.

---

## 10. Direção de Arte e Som

- Visual: ilustração 2D estilizada, paleta quente para a guilda (lar) vs. paleta fria/desaturada para o mapa de missões.
- UI do mural de quests como quadro físico de madeira com pergaminhos.
- A Tela de Montagem de Party deve ter peso visual — é a decisão mais importante, e a interface precisa comunicar isso sem ser barulhenta.
- Som: trilha acústica/folk leve na guilda, tensão mínima percussiva durante a montagem de party.

---

## 11. Escopo de Protótipo — MVP v0.2

Para a próxima versão jogável:

- [ ] 6 aventureiros com atributos e **grade de Afinidade** inicial definida.
- [ ] Sistema de montagem de party com preview de Afinidade em tempo real.
- [ ] Afinidade evolui ao longo de 3+ dias de play.
- [ ] Pelo menos 1 Ação de Vínculo ativa (Vera + Bram: "Impulso do Mentor").
- [ ] 10 missões, sendo 2 com tag de composição obrigatória.
- [ ] 1 evento de bastidor disparado por Laço Forte.
- [ ] Quadro de Relações básico visível (sem upgrade por ora).

---

## 12. Roadmap Sugerido

1. **v0.1** ✅ — loop de despacho funcional + 8 missões de teste + Sintonia de Grupo básica.
2. **v0.2** *(atual)* — sistema de Party e Afinidade completo, grade de compatibilidade, Ações de Vínculo.
3. **v0.3** — eventos de bastidor + evolução narrativa de vínculos + Quadro de Relações visual.
4. **v0.4** — estrutura de capítulos/episódios + Ato 1 completo + upgrade da guilda.
5. **v1.0** — polimento de UI, trilha sonora, minigame opcional, finais variáveis.

---

*Versão 0.2 — Rafael Jr / A Guilda. Próximos passos: prototipar a Tela de Montagem de Party com preview de Afinidade em tempo real, e escrever os eventos de bastidor do primeiro Laço Forte (Vera + Bram).*

---

## 13. Mapa Mágico *(adicionado v0.3)*

### 13.1 Conceito

O Mestre de Despacho não vai à missão — mas possui um **Mapa Mágico de Escrutínio** que permite observar a party em tempo real, como se fosse uma bola de cristal projetada sobre pergaminho iluminado. O mapa é a **tela de execução** da missão: o jogador assiste, não controla — reforçando o papel de quem decide *antes*, não *durante*.

### 13.2 Estrutura Visual

- **Área do mapa:** SVG estilizado com vegetação, montanhas, rios e estradas conforme o bioma da missão (floresta, pântano, montanha, cidade, estrada).
- **Rota:** traçado que se revela progressivamente (animação de `stroke-dashoffset`) ao longo da missão, pintado em dourado.
- **Tokens dos heróis:** marcadores glowing que se movem ao longo da rota — um por herói despachado, com leve offset vertical para ficarem legíveis como grupo.
- **Waypoints:** 3 pontos de interesse na rota; ao serem alcançados pelo token, pulsam com um anel de luz e disparam uma linha de narração no painel lateral.

### 13.3 Biomas do Mapa

| Bioma | Missões típicas | Visual |
|---|---|---|
| Floresta | Combate, fauna | Verde escuro, copas de árvore |
| Pântano | Exploração, ruínas | Azul-verde, névoa, poças |
| Montanha | Dragões, mistérios | Marrom pedra, picos poligonais |
| Estrada | Diplomacia, escolta | Terra batida, construções |
| Cidade | Furtividade, política | Silhuetas de prédios, trapiches |

### 13.4 Painel Lateral da Missão

Ao lado do mapa, painel exibe:
- Nome da missão e risk badge.
- Party chips (avatar + nome de cada herói, coloridos).
- Barra de progresso da missão.
- **Narração em tempo real:** linhas de texto com animação de entrada, uma por waypoint alcançado — escrita no ponto de vista de quem observa de longe.
- Botão **"Ver Resultado"** que aparece apenas ao fim da animação.

### 13.5 Design Intent

O jogador nunca clica durante o mapa — apenas lê, observa e torce. Isso reforça o pilar de design: "a tensão está em decidir *antes*, não em executar *durante*." A impossibilidade de intervir torna o resultado mais pesado — você fez o que pôde na montagem da party; agora o mapa revela as consequências.

---

## 14. Livro da Guilda *(adicionado v0.3)*

### 14.1 Conceito

O Mestre de Despacho carrega um **Livro da Guilda** — um tomo de páginas envelhecidas onde cada aventureiro tem sua ficha. A UI imita um livro aberto em duas páginas (spread), com estética de pergaminho, iniciais iluminadas e tinta de pena. Funciona como uma **ficha de personagem ao estilo D&D 5ª edição**, adaptada para as mecânicas do jogo.

### 14.2 Página Esquerda (Identidade)

- **Retrato** (placeholder estilizado com emoji/avatar + cor do herói).
- **Nome, título, classe, raça, nível.**
- **PV (Pontos de Vida):** pips visuais cheios/dano — afetados por missões com custo.
- **Moral:** 10 pips dourados — sobe com sucesso e descansa, cai com falha e negligência.
- **Status:** badge (Pronto / Exausto / Ferido).
- **Habilidades proficientes:** tags compactas (Atletismo, Furtividade, Arcana etc.).
- **Histórico de missões:** log rolável com ícone de resultado (✓ / ~ / ✗).
- **Campo trancado:** Inventário Detalhado — marcado como "disponível na v0.3".

### 14.3 Página Direita (Stats e Relações)

- **Grid de Atributos (D&D 5e):** 5 atributos em caixas com pontuação (1–10) e modificador derivado (−2 a +2).
- **Seção de Personalidade (D&D 5e):** Traço, Vínculo, Defeito, Ideal — escritos na voz do personagem.
- **Tabela de Afinidades:** lista todos os outros aventureiros com barra visual (−5 a +10), valor numérico e rótulo de estado do vínculo. Atualiza em tempo real conforme missões são resolvidas.
- **Campos trancados expandíveis:**
  - Árvore de Habilidades — v0.4
  - Conquistas — v1.0

### 14.4 Navegação

- Setas prev/next para folhear o livro entre os aventureiros.
- Dots indicadores de herói (clicáveis).
- Label textual com nome atual e posição (ex: "Theo (1/6)").

### 14.5 Princípio de Expansão

O livro foi projetado para crescer. Cada campo trancado é um slot — o sistema de dados subjacente já está pronto para receber inventário, habilidades especiais e conquistas sem quebrar o layout. A metáfora do livro físico justifica naturalmente o conceito de "páginas adicionadas com o tempo".

---

*Versão 0.3 — adicionadas seções Mapa Mágico e Livro da Guilda. Próximos passos: implementar eventos de bastidor no hub, sistema de upgrades da guilda com slots de missão simultânea.*
