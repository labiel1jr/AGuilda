# Plano — "A Marca nas Paredes" (segunda missão grande)

**Status:** passos 1 a 4 implementados (jogável do pedido ao recibo); falta a arte (passo 5). O que mudou em relação ao plano está na §10.
**Base:** a aventura *Caçada aos Bandoleiros*, adaptação de fã de uma missão secundária de *Dragon Age II*, lida como referência de estrutura. É obra derivada de propriedade de terceiros: **nomes, falas e textos abaixo são próprios do A Guilda**. Da original aproveitamos só a forma: um contrato negociado, três caminhos de investigação para a mesma pista e um esconderijo que é uma emboscada.
**Documentos relacionados:** [Plano Alvorada](PLANO_ALVORADA.md) · [GDD](GDD.md) · [Narrativa](NARRATIVA.md) · [Referências de RPG](REFERENCIAS_RPG.md)

---

## 1. A ideia em uma frase

Um bando rouba os depósitos do bairro do porto e pinta nas paredes **a marca do Corvo Cinzento**. Os mercadores querem contratar a guilda para acabar com isso, mas a cidade já começa a desconfiar que **foi a própria guilda**. O grupo precisa negociar o contrato, descobrir quem usa a marca e sobreviver à emboscada no depósito.

Por que serve: é **curta** (cabe no Ato 1), usa os três sistemas da Alvorada numa escala menor (bom teste antes do arco grande) e **amarra o mistério do Capítulo 2**: "alguém está usando o passado do Corvo contra ele".

---

## 2. Elenco da missão (nomes próprios)

| Papel | Nome | Quem é |
|---|---|---|
| O bairro | **a Baixada do Cais** | Bairro pobre escavado na rocha junto ao porto; depósitos, becos em escada, uma taverna |
| Os contratantes | **Mestre Odo Carrapato** e **Dona Brisa Fenwick** | Dois mercadores da Liga do Cais; ele pechincha tudo, ela quer resultado |
| O informante | **Tibério Unha-Fina** | Anão sem barba, dono de metade dos boatos da Baixada; é quem traz o pedido à guilda |
| O bando | **os Mãos-Cinzas** | Ladrões que pintam o corvo para jogar a culpa na guilda; pagos por alguém de fora |
| O mandante | **o estrangeiro de capa verde** | Agente dos fundadores do Corvo; aparece só de longe (pista para o Capítulo 3) |
| O bairro élfico | **o Pátio da Figueira** | Pátio fechado à noite pela guarda, com a única árvore da Baixada |
| A testemunha | **Lisandre** | Elfa que perdeu o irmão: ele se recusou a guardar o roubo |
| O bando rival | **os Lanternas** | Mercenários baratos que os mercadores contratam se a guilda pedir demais |
| A taverna | **O Anzol Torto** | Onde Tibério mora e a festa do fim acontece |

**Ligação com a nossa história:** a marca nas paredes é o **corvo antigo** da guilda, usado antes da ruína. Quem paga os Mãos-Cinzas é um agente dos fundadores. A missão termina com uma pista (o recibo do estrangeiro) que leva à **lista de nomes** do Capítulo 3.

---

## 3. Onde entra

- **Ato 1, Capítulo 2 ("Ecos do Corvo")**, a partir do dia 1, como um **arco curto** (2 etapas) no lugar de **"Bandidos na Ponte Velha"**.
- No **Quadro de Avisos**: cartaz comum com o pedido da Liga do Cais e o desenho do corvo pichado.
- Risco: etapa 1 **baixo** (investigação), etapa 2 **médio** (combate, 2 a 3 heróis). Heróis por volta do nível 2–4.

---

## 4. Estrutura do arco

```
   [Etapa 1 — O pedido da Liga]  (diplomacia + investigação, baixo)
            │  negociação na rota: aceitar / pedir mais / pedir demais
            │  três caminhos de pista (rota fixa com bifurcação)
            │
    DECISÃO NA GUILDA (curta)
     ├─ "Ir ao depósito"           → Etapa 2 (com ou sem contrato)
     └─ "Avisar a guarda e esperar" → o arco termina (Lanternas cuidam; a marca continua)
            │
   [Etapa 2 — O depósito vazio]  (combate, médio)
            │
   final "Prova na mão" / "Ninguém paga" / "A marca fica"
```

### Etapa 1 — "O Pedido da Liga" (risco baixo, 1 a 3 heróis)
- **Rota fixa curta:** sala reservada do Anzol Torto → (negociação) → três caminhos → beco das docas.
- **Negociação (primeiro nó, evento com escolhas):**
  - *Aceitar o preço* → contrato normal (`mc_contrato`).
  - *Pedir mais* → teste de **Carisma** CD 12. Sucesso: contrato com recompensa maior (`mc_contrato`, `mc_bom_preco`). Falha: aceitam o preço normal, de má vontade.
  - *Pedir demais* → os mercadores fecham com os Lanternas (`mc_sem_contrato`). A missão continua, mas sem pagamento garantido.
  - Na Estima "malvista", o preço inicial é menor; na "querida", maior.
- **Boatos de Tibério (texto do nó):** marcas pintadas nas paredes; um elfo do Pátio da Figueira conversando à noite com um estrangeiro.
- **Três caminhos (camada com 3 nós, o jogador escolhe um):**
  1. **Seguir as marcas** → teste de **Destreza** (rastrear) CD 13; as marcas mais velhas descem para as docas (`mc_marcas`). Lyssa e Vera reconhecem o corvo antigo sem teste.
  2. **O Pátio da Figueira** → Lisandre chora o irmão; teste de **Carisma** para ela falar (`mc_figueira`). Senna passa sem teste.
  3. **Só sem contrato: a escolta** → o grupo escolta um mercador que não fechou com ninguém, é emboscado por 4 Mãos-Cinzas (combate curto) e acha um bilhete com o endereço do depósito (`mc_bilhete`).
- **Resultado:** cada caminho dá a flag `mc_deposito` (o grupo sabe onde é). Com `mc_marcas` ou `mc_figueira`, o grupo também sabe que **a marca é falsa** (`mc_marca_falsa`).

### Decisão na guilda (tela de decisão)
Quem foi na Etapa 1 opina (ver §6). Escolhas:
- **"Ir ao depósito"** → abre a Etapa 2 no dia seguinte.
- **"Avisar a guarda e esperar"** → o arco termina; os Lanternas resolvem pela metade e **a marca continua nas paredes**: −1 de Estima e um bastidor depois ("A marca no muro da guilda").
- **"Limpar a marca primeiro"** (só com `mc_marca_falsa`) → gasta 1 dia de um herói, +1 de Estima, e a Etapa 2 abre com atraso de 1 dia.

### Etapa 2 — "O Depósito Vazio" (combate, risco médio, 2 a 3 heróis)
- **Rota fixa:** escada das docas → porta do depósito → interior → o baú.
- **A emboscada (nó-chave):** antes de entrar, teste de **Conhecimento** ou **Destreza** CD 14 (perceber vultos atrás das caixas).
  - Sucesso: o grupo entra preparado (sem penalidade; `+1` na rota).
  - Falha: **chuva de flechas**: −2 na rota, e um herói aleatório perde PV (o que mais estiver na frente; Bram sempre, se estiver).
  - Com a pista `mc_figueira`, Lisandre avisou da emboscada: sucesso automático.
- **Alvo:** os Mãos-Cinzas (arqueiros atrás das caixas + o chefe com espadas curtas). Combate, Força + Destreza.
- **Depois do alvo, o baú:** teste de **Destreza** CD 15 (Lyssa brilha). Dentro: ouro, a **Lâmina Rúnica** (item) e o **recibo do estrangeiro** (`mc_recibo`).

### Finais
- **"Prova na mão"** (com contrato): pagamento da Liga + bônus da guarda; +1 de Estima; festa no Anzol Torto (bastidor).
- **"Ninguém paga"** (sem contrato): dá para cobrar levando a prova (teste de Carisma: paga metade). Sem teste ou com falha, só o que estava no baú.
- **"A marca fica"** (recusou na decisão ou perdeu a Etapa 2): −1 de Estima e o povo passa a desconfiar da guilda (Fama −1 para quem foi).
- Em todos com o baú aberto: `mc_recibo` dá uma linha extra na abertura do Capítulo 3 ("o recibo traz o mesmo selo da lista").

---

## 5. O que muda no jogo (sistemas)

Nada novo: usa só o que o passo 1 da Alvorada já criou.

| Peça | Uso aqui |
|---|---|
| **Arco de missões** (`Arcs`) | Etapa 2 com `requires_flag: mc_ir_deposito`; Etapa 2 com `forbids_flag: mc_marca_fica` (cancelada se a guilda avisar a guarda) |
| **Decisão de arco** | `mc_decisao` em `decisions.json`, com falas dos heróis |
| **Rota fixa** | Duas rotas curtas; a camada de três caminhos com o nó da escolta `requires_flag` (ver abaixo) |
| **Eventos da rota** | ~10 eventos novos em `route.json` (grupo `baixada`) |
| **Resultado contado** | Frases próprias em `result_story.json` |

Pequenas extensões necessárias:
- **Nó de rota condicional:** um nó da rota fixa só aparece com uma flag (`requires_flag` no nó). Serve para o caminho da escolta e vai servir à Alvorada.
- **Recompensa variável:** `reward` da missão ajustado pela flag de negociação (`mc_bom_preco` = +50%; `mc_sem_contrato` = 0, com o teste de cobrança no resultado).
- **Item:** Lâmina Rúnica (`items.json`), uma espada de duas mãos com +1 em combate.

---

## 6. Quem você envia muda a história

| Herói | Na Etapa 1 | Na decisão | No depósito |
|---|---|---|---|
| **Vera** | Reconhece o corvo antigo: sabe que é falso | Fica furiosa: quer ir já ("estão sujando o nome da casa") | +1 contra a emboscada (conhece depósitos do porto) |
| **Lyssa** | Segue as marcas sem teste; conhece o jeito dos Mãos-Cinzas | Desconfia da Liga: "quem paga ladrão para culpar a gente?" | Abre o baú sem teste |
| **Senna** | Lisandre fala com ela sem teste | Defende avisar o Pátio da Figueira primeiro | — |
| **Theo** | Desconfortável com a pechincha | Prefere avisar a guarda (lei primeiro): estresse se o grupo for sozinho | Protege os outros da chuva de flechas (ninguém perde PV) |
| **Bram** | Negocia: +2 no teste de pedir mais | Quer a festa no Anzol Torto | Sempre na frente: é o alvo da chuva de flechas |
| **Mira** | Lê o recibo e reconhece o selo | Quer entender quem paga | Identifica as flechas de pedra polida |
| **Corin** | Conforta Lisandre (bastidor depois) | Pede que o bando seja entregue vivo | +1 de Mente para o grupo depois da luta |

---

## 7. Arte necessária

Specs prontas para o artista (o jogo já aponta para os arquivos e mostra a arte assim que ela existir):

| Asset | Spec | Onde aparece |
|---|---|---|
| Cartaz do pedido: o corvo pintado num muro | `art/specs/inimigos/corvo_pichado.json` → `art/enemies/corvo_pichado.png` | Cartaz da Etapa 1 no Quadro de Avisos e alvo do mapa |
| Cartaz dos Mãos-Cinzas (arqueiro atrás da caixa) | `art/specs/inimigos/maos_cinzas.json` → `art/enemies/maos_cinzas.png` | Cartaz da Etapa 2, alvo do mapa e resultado |
| Cena da decisão: o reboco com o corvo na mesa da guilda | `art/specs/cenas/cenas_marca.json` → `art/scenes/mc_decisao.png` | Topo da tela de decisão |
| Ícone da Lâmina Rúnica | `art/specs/cenario/itens.json` → `art/items/lamina_runica.png` | Baú, Equipamento e resultado |

Reservadas para quando a tela tiver lugar (eventos da rota e resultado específico de missão ainda não mostram imagem): negociação no Anzol Torto, Lisandre sob a figueira, o interior do depósito e a festa (ver `cenas_marca.json → reservado_para_futuro`).

---

## 8. Ordem de implementação sugerida

1. Nó de rota condicional e recompensa variável (com testes).
2. Etapa 1 com negociação e os três caminhos + decisão.
3. Etapa 2 e os três finais, Lâmina Rúnica, frases do resultado.
4. Ligação com o Capítulo 3 (linha extra da abertura com `mc_recibo`).
5. Specs de arte e integração quando chegarem.

Cada passo com teste no `sim_test.gd` (o arco tem que ser completável com e sem contrato) e conferência por screenshot.

---

## 9. Decisões tomadas (2026-10-11)

| Tema | Decisão |
|---|---|
| Momento | **Ato 1, Capítulo 2**, a partir do dia 1 |
| Ponte Velha | **Substituída** pelo arco (o quadro mostra 6 pedidos; o Depósito entra como 7º quando a decisão o abre) |
| Tamanho | 2 etapas + decisão curta; os três finais |
| Tom | Leve-sombrio: crime de bairro e um luto, sem gore; espaço para humor (Bram, a pechincha, a festa) |
| Ordem | Implementar **antes** da Alvorada: é menor e testa os sistemas do passo 1 em conteúdo real |

---

## 10. Como ficou no jogo

**Dados:** missões `marca` e `deposito` em `missions.json` (no lugar de `ponte` no Capítulo 2), eventos do grupo `baixada` em `route.json` (`mc_negociacao`, `mc_marcas`, `mc_figueira`, `mc_escolta`, `mc_escada`, `mc_emboscada`), decisão `mc_decisao` em `decisions.json`, item `lamina_runica` em `items.json` e a linha `mc_recibo` na abertura do Capítulo 3.

**Flags:** `mc_contrato` · `mc_bom_preco` · `mc_sem_contrato` (negociação) → `mc_deposito` · `mc_marca_falsa` · `mc_figueira` (caminhos) → `mc_ir_deposito` ou `mc_marca_fica` (decisão) → `mc_recibo` (vitória no depósito).

**Extensões de código que a missão trouxe (servem à Alvorada):**
- Nó de rota fixa com `requires_flag`/`forbids_flag`: fora do caminho e escondido no mapa enquanto a pista não permite.
- Teste dispensado (`test.auto_heroes`, `test.auto_flags`) e ajuda de herói no teste (`test.help`), com a dica do botão mostrando "sem teste" ou o bônus somado.
- `flags` (lista) nos efeitos de evento; `item` nos efeitos de missão; `reward_flags` multiplicando a recompensa.

**Simplificações em relação ao plano (podem voltar depois):**
- "Limpar a marca primeiro" dá +1 de Estima e abre o depósito no mesmo prazo de "Ir" (não ocupa um herói nem atrasa um dia a mais).
- "Ninguém paga": sem contrato, o depósito paga metade da recompensa (a cobrança com a prova), sem teste de Carisma.
- A chuva de flechas fere quem fez o teste (não sempre o Bram); Theo não protege, Vera não dá +1, Lyssa não precisa abrir o baú (o baú vem com a vitória), Corin não dá Mente.
- "A marca fica" na derrota: só a flag e a frase; sem Fama −1 e sem o bastidor "A marca no muro da guilda". A festa no Anzol Torto é só uma frase do resultado, não um bastidor.

**Testes:** `sim_test.gd` (`_check_marca`) percorre o arco com contrato, sem contrato e recusando na decisão; `tests/marca_shots.gd` gera as telas do arco (hub, negociação, caminhos, Figueira, resultado e decisão).
