# Plano — "Alvorada Rubra" (primeira missão grande)

**Status:** planejamento aprovado (nada implementado). Decisões na §9.
**Base:** a aventura *Alvorada de Sangue* (Coleção Aventuras, RPGBrasil), lida como referência de estrutura. A obra tem todos os direitos reservados: **nomes, falas e textos abaixo são próprios do A Guilda**; da original aproveitamos só a ideia (tirano escondido atrás de um "monstro" que leva a culpa, com uma escolha moral no meio).
**Documentos relacionados:** [GDD](GDD.md) · [Narrativa](NARRATIVA.md) · [Referências de RPG](REFERENCIAS_RPG.md) · [Roadmap](ROADMAP.md)

---

## 1. A ideia em uma frase

Uma cidade portuária vive sob toque de recolher e paga impostos para caçar uma **fera** que ronda as muralhas — mas a fera é o último leal ao lorde assassinado, e quem devora o povo é o **novo regente**. A guilda decide: **entregar a fera pela recompensa** ou **aliar-se a ela e derrubar o regente**.

Por que é a missão certa para ser a primeira grande: é sobre **em quem acreditar**, e cada herói reage de um jeito — exatamente o pilar "quem você envia define quem eles se tornam".

---

## 2. Elenco da missão (nomes próprios)

| Papel | Nome | Quem é |
|---|---|---|
| Cidade | **Vau-Salgado** | Porto murado de especiarias, ao sul da estrada costeira; rico, mas hoje com medo |
| O tirano | **Lorde Corvane Ashmere** | Irmão mais novo do antigo lorde; subiu ao poder há poucos meses; esconde que virou **vampiro** e se aliou aos inimigos do Corvo |
| O lorde morto | **Lorde Edwyn Ashmere** | Traído e morto; preso como **espectro** na própria cripta |
| A "fera" | **Halvard** | Ex-capitão da guarda de Edwyn, **lobisomem** desde a juventude; leal até depois da morte do senhor |
| A sobrinha | **Isolde Ashmere** | Filha de Edwyn, transformada em cria do tio; quer a vida de volta |
| A bruxa | **Mãe Grilha** | Feiticeira que vendeu a proteção de Edwyn a Corvane |
| O cão de guarda | **o Cavaleiro de Ônix** | Braço direito de Corvane, armadura negra com elmo de gárgula |
| O preso no quadro | **Irmão Teobaldo** | Antigo capelão da família, aprisionado num retrato |
| A taverna | **O Cálice Vermelho** (antes "O Cálice Dourado") | Taverna com o nome trocado por decreto; dono: **Pipo Talhadoce**, halfling |

**Ligação com a nossa história:** Corvane está na **lista de nomes** do Ato 2; o pacto dele é com **os fundadores do Ninho do Corvo**, que querem um porto aberto para trazer gente e armas. Isso amarra a missão ao Capítulo 4.

---

## 3. Onde entra

- **Ato 2, Capítulo 3 ("Nomes na Lista")**, a partir do dia 2, como um **arco de missões** (3 etapas) que corre em paralelo às outras.
- Aparece no **Quadro de Avisos** como um cartaz especial: *"Recompensa pela fera de Vau-Salgado"*, com selo **lendário** e o cartaz do lobisomem.
- Risco: etapa 1 **médio**, etapa 2 **alto**, etapa 3 **lendário** (os heróis estão por volta do nível 5–7 no Ato 2).

---

## 4. Estrutura do arco

```
          [Etapa 1 — Toque de recolher]  (investigação, médio)
                       │
             pistas: flags descobertas
                       │
          ┌──── DECISÃO NA GUILDA ────┐
          │                           │
   [2A — A caçada]              [2B — O túnel dos anões]
   (combate, alto)              (furtividade/exploração, alto)
          │                           │
   [3A — A noite das facas]     [3B — O castelo do regente]
   (defesa, alto)               (lendário, 3–4 heróis)
          │                           │
   final "Porto fechado"        finais "Alvorada" (3 variações)
```

### Etapa 1 — "Toque de Recolher" (investigação, risco médio, 1 a 3 heróis)
- **Mapa especial (rota fixa):** portão ao anoitecer → **O Cálice Vermelho** (NPC Pipo) → quadro de avisos da cidade → **cemitério à noite** → cripta de nome arrancado.
- **Eventos (com teste):** convencer o guarda do portão (Carisma); ler os decretos (Conhecimento); arrombar a cripta (Destreza, Lyssa brilha); resistir ao cheiro da cripta (Resistência); seguir os rastros (Destreza/Força).
- **O momento-chave:** no cemitério, o grupo ouve a fera conversando com um espectro. Escolha na hora: **atacar** ou **esperar e ouvir**.
- **Pistas (flags):** `vs_decretos`, `vs_cripta`, `vs_ouviu_halvard`, `vs_viu_onix`. Quanto mais pistas, mais clara fica a verdade na decisão.
- **Resultado contado** com frases próprias do arco (ex.: "Corin sentiu frio onde não havia vento: aquele túmulo não estava vazio.").

### Decisão na guilda (tela de decisão, sem missão)
Uma cena como as de bastidor, com **quem foi na Etapa 1** opinando — e as opiniões dependem do herói (ver §6). Escolhas:
- **"A fera pela recompensa"** → ramo A (ouro alto, Estima de Vau-Salgado com o regente).
- **"Ouvir Halvard"** → ramo B (só aparece se o grupo tiver a pista `vs_ouviu_halvard` ou `vs_cripta`).
- **"Não é problema nosso"** → o arco se encerra; consequência no Capítulo 4 (o Ninho ganha o porto: chefe final mais forte).

### Ramo A — "A Caçada" e "A Noite das Facas"
- **2A (combate, alto):** caçar Halvard no cemitério. Vencer paga muito ouro.
- **3A (defesa, alto):** dois dias depois, o Cavaleiro de Ônix ataca o grupo na taverna para apagar testemunhas. Sobreviver = **final "Porto fechado"**: a guilda ganhou ouro, Vau-Salgado continua sob o regente e **o Ninho ganha o porto** (Cap. 4 mais difícil). Bastidor posterior: Senna e Corin questionam a escolha (afinidade e estresse).

### Ramo B — "O Túnel dos Anões" e "O Castelo do Regente"
- **2B (exploração/furtividade, alto):** Halvard mostra uma passagem antiga sob a muralha, **obra anã** (Vera reconhece). Preparar a invasão: estacas, flechas de madeira, poções do laboratório de Halvard (rota com nós de preparo e um nó de mercador clandestino). Preparação aqui vira **bônus no castelo**.
- **3B (lendário, 3–4 heróis):** mapa especial do castelo — alçapão no beco → corredor de prata → sala de troféus (ursos empalhados animados = **golens**) → salão com **Isolde** (pede ajuda em segredo) → quarto da bruxa (poções) → retrato de **Irmão Teobaldo** → torre com **Corvane** cercado de crianças enfeitiçadas.
  - **Halvard segura o portão** do lado de fora (aliado que entra no score como bônus fixo).
  - **Escolhas no caminho:** salvar as crianças antes (custa provisões/tempo) ou subir direto; poupar os guardas que servem por medo (Theo e Corin pedem; afeta o final); confiar em Isolde.
- **Finais "Alvorada"** (pela soma das escolhas):
  1. **"Alvorada"** — Corvane morre, Isolde volta a ser humana e assume Vau-Salgado; a cidade vira **aliada da guilda** (melhoria/recompensa permanente).
  2. **"Meia-noite"** — Corvane foge em névoa; Isolde continua cria e parte; Halvard vira regente; aliado, mas o Ninho sabe que a guilda vem.
  3. **"O preço do espectro"** — a bruxa revela que Edwyn só descansa se Halvard morrer: **dilema final** (matar o aliado para libertar o senhor dele, ou deixar o espectro preso). Escolha marcada no Livro de quem estava lá.

---

## 5. O que muda no jogo (sistemas)

| Peça | O que é | Esforço |
|---|---|---|
| **Arco de missões** | Missões com `arc`, `requires_flag` / `forbids_flag` e etapa; o quadro mostra a próxima etapa só quando a anterior termina | médio |
| **Tela de decisão de arco** | Cena de escolha (como bastidor) disparada por flag ao fim de uma etapa, com falas dos heróis que participaram | médio |
| **Rota fixa** | `route.fixed` em `missions.json`: camadas e eventos definidos à mão (cemitério, túnel, castelo) em vez de sorteados | médio |
| **Eventos de rota do arco** | ~20 eventos novos em `route.json` (grupo `vau_salgado`) | texto |
| **Aliado temporário** | Halvard como bônus no score da etapa 3B (e Isolde como evento) | pequeno |
| **Efeito no Capítulo 4** | Flags do arco mudam o Ninho do Corvo (chefe mais forte, ou ajuda de Vau-Salgado) | pequeno |
| **Recompensas** | Ouro; item **Lâmina da Alvorada** (espada lendária contra mortos-vivos); título no Livro ("Libertador de Vau-Salgado" ou "Caçador da Fera") | pequeno |
| **Resultado contado** | Frases e cenas próprias do arco em `result_story.json` | texto |

Tudo data-driven: o arco cabe em `missions.json`, `route.json`, `backstage.json` (decisões) e `result_story.json`, com código só para arco, decisão e rota fixa — que servirão para as próximas missões grandes.

---

## 6. Quem você envia muda a história

| Herói | Na Etapa 1 | Na decisão | No castelo |
|---|---|---|---|
| **Corin** | Sente a presença do espectro (pista grátis) | Pede para ouvir Halvard | Bônus contra mortos-vivos; pode **libertar Irmão Teobaldo** |
| **Senna** | Reconhece em Halvard alguém que o povo culpa por ser diferente | Defende a aliança (afinidade com quem concordar) | Ameaça os guardas para que larguem as armas |
| **Theo** | O código o faz desconfiar da "fera" | Dividido: a lei diz caçar, a justiça diz ouvir (estresse) | Quer poupar os guardas; conflito se o grupo não poupar |
| **Lyssa** | Abre a cripta sem teste | Desconfia de todo mundo, inclusive de Halvard | Acha a passagem do espelho na sala de troféus |
| **Mira** | Lê os decretos e as runas da bruxa | Quer entender antes de escolher | Identifica as poções da bruxa |
| **Vera** | — | Pragmatismo: quem paga? | Reconhece o **túnel anão** (atalho sem teste); lembra a antiga guilda |
| **Bram** | Arranca de Pipo o que ele sabe com uma canção | Romântico: quer salvar Isolde | Acalma as crianças enfeitiçadas (evita a luta) |

---

## 7. Arte necessária (specs a criar)

- **Cartazes de inimigo:** Corvane (vampiro), o Cavaleiro de Ônix, golens empalhados, Mãe Grilha; **Halvard** em dois cartazes (como "procurado" e como aliado).
- **Cenas do resultado/decisão:** a fera e o espectro no cemitério; o túnel anão; Isolde ao piano; o retrato de Teobaldo; a torre ao amanhecer (para os três finais).
- **Mapa:** marcos de Vau-Salgado (muralha, cripta, castelo) no padrão nanquim.

---

## 8. Ordem de implementação sugerida

1. Sistemas reutilizáveis: **arco de missões**, **tela de decisão**, **rota fixa** (com testes).
2. Etapa 1 + decisão (já jogável: dá para encerrar o arco recusando).
3. Ramo A (mais curto).
4. Ramo B e os finais.
5. Efeito no Capítulo 4, recompensas, frases do resultado.
6. Specs de arte e integração quando chegarem.

Cada passo com teste no `sim_test.gd` (o arco tem que ser completável pelos dois ramos) e conferência por screenshot.

---

## 9. Decisões tomadas (2026-10-11)

| Tema | Decisão |
|---|---|
| Momento | **Ato 2, Capítulo 3**, a partir do dia 2, em paralelo às outras missões; o desfecho muda o Capítulo 4 |
| Tamanho | **Os dois ramos completos**: Etapa 1, decisão, ramo A (caçada + noite das facas) e ramo B (túnel + castelo) com os três finais |
| Halvard | **Vira recruta da guilda** se a aliança der certo: entra no elenco no Capítulo 4 como 8º herói — um aliado que o povo teme (Fama inicial baixa, ligação com o arco de reconhecimento de raças/monstros). No final "O preço do espectro", se o jogador escolher libertar Edwyn, Halvard morre e não entra |
| Tom | **Sombrio, sem gore**: suspense e horror gótico (toque de recolher, cripta, crianças enfeitiçadas, vampiro) sem descrever violência explícita; o pior fica sugerido |

### 9.1 Halvard como herói (rascunho)

- **Classe:** Guerreiro (lobisomem) — Força e Resistência altas, Carisma baixo; magia nenhuma.
- **Atributos de partida (escala 1–10):** For 9 · Des 6 · Con 3 · Car 3 · Res 9 · nível 6.
- **Traço próprio:** *Fera contida* — em missões de risco alto ou lendário ganha +1 de Mente, mas cada falha dá +1 de estresse extra (a fera quer sair).
- **Relações iniciais:** Senna +3 (reconhece nele o mesmo olhar da cidade), Corin +2, Theo −2 (o código), Bram +1, Lyssa −1 (desconfiança), Vera 0, Mira +1.
- **Fama no povo inicial:** −3 ("malvisto"), que pode subir com bastidores próprios.
- **Precisa de:** retrato, miniatura e cartaz ("procurado" e aliado) — specs a criar junto com os da missão.
