# Narrativa — A Guilda

**Versão:** 0.9
**Documentos relacionados:** [GDD](GDD.md) · [Roadmap](ROADMAP.md)

Personagens, relações, capítulos, missões pessoais, bastidores e finais **como estão no jogo hoje**. O texto definitivo vive nos JSON (`data/heroes.json`, `chapters.json`, `missions.json`, `backstage.json`, `endings.json`); este documento é o mapa.

---

## 1. Premissa

A **Guilda do Corvo Cinzento** já foi referência na região. Hoje está endividada, mal vista pelo Conselho de Guildas e quase vazia. O jogador herda o cargo de **Mestre(a) de Despacho** junto com as chaves — e as dívidas.

O mistério central: a guilda não ruiu sozinha. Seus fundadores a abandonaram, existe uma **lista de nomes** de alvos (ex-membros, credores, um juiz da Ordem, gente que dorme sob o mesmo teto — e o nome do próprio jogador no topo), e alguém usa o passado do Corvo contra ele. O caminho termina no **Ninho do Corvo**, onde os fundadores se escondem.

---

## 2. Elenco

| Herói | Título | Classe / Raça | Traço | Ideal | Vínculo | Defeito |
|---|---|---|---|---|---|---|
| **Theo** | Sir Theo de Valmor, o Paladino Caído | Paladino humano | "Falo pouco e cumpro tudo. Palavra dada é dívida." | Justiça, mesmo quando a Ordem esqueceu | Deve a vida a quem o tirou da masmorra — e não sabe quem foi | Recusa ordens injustas, e recusa alto |
| **Lyssa** | Lyssa Mãos-Leves, a Ladina Cética | Ladina meio-elfa | Conta as saídas antes das pessoas | Liberdade | Mira é a única que nunca perguntou o que ela roubou | Gentileza demais parece golpe |
| **Mira** | Mira Vellacourt, a Erudita Frágil | Maga humana | Anota tudo, até numa emboscada | Conhecimento livre | O Arquivo guarda a última carta do seu mestre | Subestima o perigo diante de uma runa |
| **Senna** | Senna, a Lâmina Alugada | Guerreira meio-orc | "Pago minhas contas e espero que paguem as suas." | Pragmatismo | Um irmão ao sul lhe deve um adeus | Trabalha melhor sozinha — e faz questão que saibam |
| **Bram** | Bram Pé-de-Vento, o Novato Idealista | Bardo halfling | Acha que toda briga acaba com uma canção | Esperança na guilda | Entrou por causa das histórias da Vera | Desmorona quando um ídolo o decepciona |
| **Vera** | Vera Punho-de-Ferro, a Guerreira Veterana | Guerreira anã | Dá ordens como quem respira | Dever: a guilda é a última muralha | Enterrou metade da antiga guilda | Confunde proteger com controlar |
| **Corin** | Irmão Corin de Halvar, o Clérigo Errante | Clérigo humano | Oferece pão antes de conselho | Misericórdia | Expulso do templo por curar um inimigo do bispo | Confia rápido demais em quem diz que mudou |

Corin chega no **Capítulo 2**.

---

## 3. Relações Iniciais

Grade de afinidade inicial (`heroes.json → affinity`, linha → coluna):

| | Theo | Lyssa | Mira | Senna | Bram | Vera | Corin |
|---|---|---|---|---|---|---|---|
| **Theo** | — | −3 | +1 | −2 | +2 | +3 | +1 |
| **Lyssa** | −3 | — | +4 | −1 | +1 | 0 | 0 |
| **Mira** | +1 | +4 | — | −2 | +2 | +1 | +2 |
| **Senna** | −2 | −1 | −2 | — | −1 | +2 | −1 |
| **Bram** | +2 | +1 | +2 | −1 | — | +4 | +3 |
| **Vera** | +3 | 0 | +1 | +2 | +4 | — | +1 |
| **Corin** | +2 | +1 | +2 | 0 | +3 | +1 | — |

**Dinâmicas de partida:**

- **Vera + Bram** — a "dupla segura". O caminho mais acessível para Mentoria; cria dependência que o jogador precisa quebrar.
- **Lyssa + Mira** — confiança entre duas desconfiadas; caminho natural para Amizade Profunda.
- **Theo + Lyssa** — Conflito Aberto: o paladino e a ladra. O maior desafio de reconciliação.
- **Senna** — começa negativa com quase todos, exceto Vera. Maior risco e maior recompensa do elenco.
- **Corin** — chega gostando de todos (e Corin → Theo é +2 enquanto Theo → Corin é +1: a assimetria já começa).

---

## 4. Estrutura

### Ato 1 — A Herança do Corvo

| Capítulo | Dias | Objetivo | Missões | Flag de sucesso |
|---|---|---|---|---|
| 1. Herança de Cinzas | 5 | Reputação 6+ | Lobos na Estrada de Vaurel, Ratos Gigantes no Celeiro, Escolta da Caravana de Especiarias, Febre no Vilarejo de Marrow, Runas na Cripta de Hollen, Disputa entre os Barões | `conselho_confia` |
| 2. Ecos do Corvo | 5 | Sobreviver à Noite do Corvo | Os Credores da Guilda, Furto do Selo Perdido, **A Marca nas Paredes** → O Depósito Vazio (arco, ver [plano](PLANO_BANDOLEIROS.md)), A Torre do Mago Silencioso, O Ninho da Serpe, **A Noite do Corvo** | `noite_vencida` |

O Capítulo 2 abre diferente conforme `conselho_confia` (o Conselho apoia ou manda um observador).

### Ato 2 — A Lista de Nomes

| Capítulo | Dias | Objetivo | Missões | Flag de sucesso |
|---|---|---|---|---|
| 3. Nomes na Lista | 6 | Convencer o Conselho | Contrabando no Porto, **O Irmão de Senna**, **A Última Carta**, **O Julgamento da Ordem**, Os Mortos da Mina, Emboscada na Estrada Real, **Audiência no Conselho** | `conselho_aliado` |
| 4. O Ninho do Corvo | 6 | Tomar o Ninho do Corvo | O Espião na Guilda, A Torre de Sinais, Aldeia Sitiada, Rituais no Pântano, **O Ninho do Corvo** (lendária, 4 aventureiros) | `corvo_derrotado` |

O Capítulo 3 muda conforme `noite_vencida`; o Capítulo 4 conforme `conselho_aliado` (guardas seguram a cidade) e `irmao_salvo` (o irmão de Senna guia a party).

---

## 5. Missões Pessoais e Requisitos Ocultos

| Missão | Herói | Efeito narrativo |
|---|---|---|
| O Irmão de Senna | Senna precisa ir | Sucesso: flag `irmao_salvo` (Dario, o irmão, guia no Capítulo 4). Na falha, Dario escolhe ficar com os traidores |
| A Última Carta | Mira precisa ir | Sucesso: flag `carta_lida` (a carta revela quem traiu o mestre de Mira, um nome da lista) |
| O Julgamento da Ordem | Theo precisa ir | Sucesso: flag `theo_redimido` (o juiz confessa a armação; Theo devolve o escudo da Ordem) |
| Escolta da Caravana | (oculto) Theo | Theo é procurado na rota: −2 no score se for |

Nas três missões pessoais, a moral do herói muda +3 (limpo), +1 (custo) ou −3 (falha).

Outras tags: Cripta (exige um especialista em magia), Selo (proibido quem tem passagem criminal), Noite do Corvo (3+ aventureiros), Audiência (2+ testemunhas), Ninho (4 aventureiros).

---

## 6. Bastidores

27 cenas curtas (`backstage.json`), até 2 por dia, com escolhas que mexem em afinidade, moral, estresse, fama no povo, estima da cidade e ouro:

- **Entre heróis (por afinidade):** taverna, treino, discussão, conversa ao luar, lealdade, lição, código, mapa; o pão dos órfãos (Theo descobre o lado de Lyssa que ela esconde).
- **Ligadas à história:** primeira noite na guilda, chegada de Corin, Senna encontra o nome do irmão na lista, o peso do código (Theo), Dario como guia, véspera do Ninho.
- **Na cidade:** canções na praça (Bram), o telhado da viúva de um antigo membro, o boato sobre Senna, o menino que queria ser paladino (Theo), a bolsa do nobre (Lyssa), o beco dos doentes (Corin), a festa da cidade (só com a cidade grata).
- **Que revelam melhorias:** o ferreiro sem forja (Vera e Dorin → Forja), os livros do arquivista (Mira → Biblioteca), a sala esquecida (Corin → Capela), os cavalos velhos (→ Estábulo), o porão da guilda (Bram → Taverna).

### A cidade

A guilda não existe no vácuo: a cidade observa. Cada herói tem uma **fama no povo** — Bram vira o bardo da praça, Lyssa a ladra que devolve aos pobres (ou a ladra, só), Senna a mercenária que ninguém entende — e a guilda tem a **estima da cidade**, que é outra coisa que a reputação com o Conselho: o Conselho pode confiar na guilda enquanto o povo a teme, e vice-versa.

## 7. Mapa de Expedição

Os eventos de rota (`route.json`) são vinhetas curtas em que um herói chama o Mestre de Despacho pelo Mapa Mágico: batedores inimigos, saqueadores, feras, baús, ruínas, viajantes feridos, pontes caídas, névoa, vozes na escuridão, ladrões na noite, mercenária, eremita, guia traidor, santuários e o guarda do alvo. O texto usa `{heroi}` — quem chama é o membro mais apto ao teste.

---

## 8. Estresse como Narrativa

Ao quebrar, o herói ganha uma frase própria da condição (ex.: Paranoico — *"Quem de vocês contou a eles?"*; Inspirador — canta alto e desafinado e o grupo ri pela primeira vez em dias). Traços permanentes (Medo do Escuro, Pele Dura...) funcionam como cicatrizes visíveis no Livro.

---

## 9. Finais

Ao fim do Ato 2, o epílogo escolhe um final por condição (o primeiro que se cumprir):

| Final | Condição |
|---|---|
| **A Lenda do Corvo Cinzento** | `corvo_derrotado` e `conselho_aliado`, ninguém saiu da guilda, Reputação 20+ |
| **A Guilda Reconstruída** | `corvo_derrotado` |
| **Os Que Ficaram** | `noite_vencida` ou `conselho_aliado` |
| **Cinzas e Recomeço** | nenhum dos anteriores |

Além do final, há um **desfecho por herói** (inclusive para quem saiu) e uma linha por **vínculo formado**: Romance, Parceria Lendária, Irmandade, Mentoria, Amizade Profunda, Inimizade Declarada.

---

## 10. Lacunas Narrativas (para o Roadmap)

- Variar o texto do resultado conforme **a dupla enviada** (seção 14 da Análise: mesma missão + party diferente = história diferente). Hoje só o requisito oculto e as missões pessoais fazem isso.
- Arco pessoal para **Lyssa, Bram, Vera e Corin** (hoje só Senna, Mira e Theo têm missão pessoal).
- Cenas especiais por combinação de party + resultado (ex.: Vera e Bram sobrevivendo juntos a uma falha).
- Eventos de rota que reajam a **quem está no grupo** e às condições (ex.: um herói paranoico desconfiando do guia).
