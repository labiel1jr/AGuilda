# Balanceamento — A Guilda

**Versão:** 0.9
**Documentos relacionados:** [GDD](GDD.md) · [TDD](TDD.md)

Fórmulas, constantes e resultados de simulação. Os valores vêm do código e dos JSON: se um número mudar lá, atualize aqui. Onde cada valor vive está indicado entre parênteses.

---

## 1. Score da Missão (`score_calc.gd`)

```
Score = Base + Cobertura + Afinidade + Vínculo + Poderes + Oculto + Mente + Rota + Sorte
```

| Termo | Fórmula | Faixa |
|---|---|---|
| Base | média de `0,65 × Primário + 0,35 × Secundário` (atributos efetivos); Cansado × 0,6 | ~1 a 10 |
| Cobertura | +1 por membro com primário ≥ 7 | 0 a +2 |
| Afinidade | média dos modificadores de faixa dos pares (menor lado) + efeitos `affinity` (até +2) | −4 a +10 |
| Vínculo | Esforço Extra +2, Sincronia Perfeita +3 | 0 a +5 |
| Poderes | efeitos `score` e `mission_type` de itens, talentos e magias | 0 a +3 (`classes.json: power_cap`) |
| Oculto | `mission.hidden.mod` se o herói indicado for | conforme missão |
| Mente | efeitos `mind` e `biome` de traços e condições | −3 a +3 (`traits.json: mind_cap`) |
| Rota | `clamp(preparação, −1, 3) − desgaste − min(fome, 2)`, mínimo −2 | −2 a +3 |
| Sorte | inteiro aleatório | −2 a +2 |

Ações de Vínculo que mudam a conta: **Impulso do Mentor** (+3 nos dois atributos da missão para o mais fraco do par), **Competição** (os dois valem o melhor), **Sincronia Perfeita** (falha vira custo).

### 1.1 Limiares por risco

| Risco | Falha com Revelação | Sucesso com Custo | Sucesso Limpo |
|---|---|---|---|
| Baixo | < 6 | 6 a 8,9 | ≥ 9 |
| Médio | < 8 | 8 a 10,9 | ≥ 11 |
| Alto | < 10 | 10 a 12,9 | ≥ 13 |
| Lendário | < 13 | 13 a 15,9 | ≥ 16 |

### 1.2 Calibragem (testada em `sim_test.gd`)

Missão de Força + Carisma, risco médio, sem sorte, elenco inicial:

| Party | Score | Leitura |
|---|---|---|
| Vera sozinha | 7,9 | Resolve o baixo; no médio, quase sempre com custo |
| Theo + Bram (Camaradas) | 9,3 | Limpo no baixo, custo no médio |
| Vera + Bram (Companheiros) | 11,3 | A "dupla segura": limpo no médio |
| Vera + Bram + Theo | 11,8 | Ganho pequeno por um membro a mais |
| Theo + Lyssa (Conflito Aberto) | 2,2 | Desastre garantido |
| Theo + Lyssa + Mira + Senna | 6,2 | Um par em conflito contamina a party |

Intenção: Sucesso Limpo em risco alto **exige** afinidade evoluída, Ação de Vínculo, poderes ou boa rota; o lendário exige quase tudo junto.

---

## 2. Afinidade (`game_state.gd`)

| Constante | Valor |
|---|---|
| Faixa | −5 a +10 |
| Modificadores por faixa | −4, −2, 0, +2, +4, +6, +8 |
| Ação de Vínculo | par ≥ +6 com rótulo certo |
| Limiares de evento | +3, +6, +9, −3, −5 |
| Missão juntos | Limpo +1 · Custo 0 · Falha −1 |
| Proteção no custo | 40% de chance, +2 para um par |
| Culpa na falha | 40% de chance, −2 / −1 |
| Neglect | 3 dias sem missão juntos, só pares ≥ +3, −1 sem cair abaixo do inicial |
| Salão de Treinamento | +1 para a dupla, os dois ficam Cansados, 10 XP cada, 1 vez por dia |

---

## 3. Fadiga, PV, Moral e Descanso

| Regra | Valor |
|---|---|
| Fadiga após missão | Cansado; Exausto se risco alto/lendário ou se já estava Cansado; −1 com `fatigue_resist` |
| Esforço Extra | os dois ficam Exaustos |
| Recuperação diária (ocioso) | −1 estado de fadiga (−2 com Resistência ≥ 7), +¼ dos PV; Enfermaria soma mais 1 estado e dobra os PV |
| Descanso ativo | fadiga 0, +½ dos PV (×2 com Enfermaria), magias de volta, moral +1, estresse −5, cura aflição |
| Dano | Custo: 1 membro; Falha: todos (exceto protegido). Baixo 1 · Médio 2 · Alto 3 · Lendário 4, menos `damage_reduction` |
| Moral por resultado | Limpo +1 · Custo 0 · Falha −1; sozinho e sem limpo: −1 extra |
| Esquecido | −1 de moral após 4 dias sem ser despachado |
| Pedido de descanso | fadiga 2, PV ≤ ⅓ ou aflição; ignorado: −1 de moral |
| Ultimato | moral ≤ 1; ignorado 1 dia = saída; promessa = missão em até 2 dias |

---

## 4. Economia e Progressão

| Item | Valor |
|---|---|
| Ouro inicial | 30 (`upgrades.json`) |
| Recompensa por risco | Baixo 20 · Médio 35 · Alto 60 · Lendário 90; Custo paga metade, Falha nada |
| Reputação | Limpo +2 · Custo +1 · Falha −1 · Missão expirada −1 |
| Slots por dia | 1; 2 com Reputação 5; 3 com Reputação 12 |
| Melhorias | Quadro 40 (rep 0) · Enfermaria 60 (rep 3) · Arquivo 50 (rep 4) · Salão 80 (rep 5) |
| XP por missão | Baixo 20 · Médio 35 · Alto 55 · Lendário 80, × 1,0 / 0,75 / 0,5 por resultado |
| XP para o próximo nível | 50 + 25 × (nível − 1), nível máximo 10, atributo máximo 10 |
| Marcos (magia/talento) | níveis 3, 5, 7, 9 |
| Saque | chance por resultado: Limpo 100% · Custo 50% · Falha 30%; tabela por risco (`items.json`) |
| Venda | metade do preço |
| Ultimato: bônus | 40 ouro |

---

## 5. Mapa de Expedição (`route.json`)

| Constante | Valor |
|---|---|
| Camadas intermediárias | Baixo 3 · Médio 3 · Alto 4 · Lendário 4 (+ objetivo) |
| Nós por camada | 2 ou 3, tipos diferentes na mesma camada |
| Guarda do alvo | sempre na última camada em risco médio para cima |
| Provisões iniciais | Baixo 4 · Médio 3 · Alto 4 · Lendário 4 (cada passo gasta 1) |
| Fome | passo sem provisão: +1 fome (−1 na Rota, até −2) e +1 de estresse em todos |
| CD base | Baixo 9 · Médio 11 · Alto 13 · Lendário 15 (+ `dc` da opção) |
| Teste | d20 + (atributo efetivo − 5) do membro mais apto; 20 passa, 1 falha |
| Preparação | até +3 no score (`bonus_cap`) |
| Desgaste | −1 por membro com PV ≤ ⅓, até −2 |
| Dano na rota | nunca deixa abaixo de 1 PV |
| Atraso | até +2 dias fora da guilda |
| Saque da rota | Limpo: tudo · Custo: metade do ouro + itens · Falha: perde tudo |
| Provisões no mercador | +2 por 10 ouro |

Pesos de nó por bioma estão em `route.json → weights`; uma missão pode sobrescrever com `route.weights`.

---

## 6. Estresse e Traços (`traits.json`)

| Constante | Valor |
|---|---|
| Estresse máximo | 10 |
| Por resultado | Limpo 0 · Custo +1 · Falha +2; risco Alto +1, Lendário +2 |
| Alívio | descanso −5; dia ocioso −1; santuário/acampamento conforme o evento |
| Ponto de ruptura | Virtude com 25% + 5% × (Resistência − 5); senão Aflição |
| Virtude | dura 2 missões; estresse volta a 4 |
| Aflição | dura até um descanso na guilda |
| No limite com aflição | cada novo estresse: −1 PV (colapso) |
| Traço ao fim da missão | Limpo 12% (positivo) · Falha 20% (negativo) |
| Máximo de traços | 4 |

---

## 7. Simulação

`sim_test.gd` roda **150 partidas aleatórias** completas: parties, magias, caminhos e opções da rota escolhidos ao acaso; descansa quem pede; compra todas as melhorias possíveis. É uma política **ruim de propósito** — mede o piso do jogo, não a experiência de um jogador que pensa.

| Versão | Limpo | Custo | Falha | Saídas de heróis (150 partidas) |
|---|---|---|---|---|
| v0.7 (sem rota) | 269 | 654 | 1908 | 145 |
| v0.8 (rota, sem estresse) | 250 | 529 | 2000 | 148 |
| v0.9 (rota + estresse) | 322 | 561 | 1915 | 141 |

Distribuição do termo Rota na v0.9 (escolhas aleatórias): −2: 328 · −1: 750 · 0: 858 · +1: 549 · +2: 256 · +3: 57.

**Leituras e decisões:**

- Escolhas aleatórias na rota ficam levemente abaixo de não ter rota — escolher bem precisa fazer diferença.
- Na v0.8, o herói "na estrada" perdia moral por pedido de descanso não atendido; as saídas quase dobraram. Corrigido: quem está fora não pede descanso.
- Na v0.9, aflição tirando moral, colapso tirando moral e falha dando +3 de estresse levaram as saídas a 220. Ajuste: aflição e colapso não mexem em moral, falha dá +2, herói aflito pede descanso.

### 7.1 Próximos passos (P2)

Evoluir a simulação para 1.000+ partidas com relatório de: uso por personagem, duplas mais frequentes, vínculos formados, missões ignoradas, taxa de sucesso por herói, duração média, tamanho de party mais usado. Ver [Roadmap](ROADMAP.md).
