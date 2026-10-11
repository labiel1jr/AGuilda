# Roadmap — A Guilda

**Versão atual:** 0.9
**Próxima meta:** v1.0 — Vertical Slice
**Documentos relacionados:** [Análise e Melhorias](ANALISE_E_MELHORIAS.md) · [Changelog](CHANGELOG.md) · [GDD](GDD.md) · [TDD](TDD.md)

As prioridades seguem a [Análise e Melhorias](ANALISE_E_MELHORIAS.md): **menos sistemas novos, mais profundidade, consequências e polimento**. Toda mecânica nova passa pelo teste "afeta decisão? afeta personagem? cria consequência?".

---

## Concluído

- [x] **v0.1** — loop de despacho
- [x] **v0.2** — party, afinidade assimétrica, Ações de Vínculo
- [x] **v0.3** — Mapa Mágico, Livro da Guilda, eventos de bastidor, neglect
- [x] **v0.4** — capítulos, Ato 1, melhorias da guilda
- [x] **v0.5** — níveis, equipamento, saque, mercado, magias, Corin, descanso ativo
- [x] **v0.6** — Ato 2, missões pessoais, bastidores ligados à história, ultimato e saída
- [x] **v0.7** — salvar/carregar, finais variáveis, retratos
- [x] **v0.8** — mapa de expedição com bifurcações, chamadas ao vivo, testes d20
- [x] **v0.9** — estresse, aflições e virtudes, traços, guarda do alvo, NPCs, santuário, eventos de perda

Detalhes de cada versão no [Changelog](CHANGELOG.md).

---

## v1.0 — Vertical Slice

Objetivo: uma experiência pequena, completa e jogável que mostre por que A Guilda é diferente. Critério: o jogador conhece personagens → cria relações → forma uma party → despacha → enfrenta consequências → vê personagens mudarem → toma novas decisões → quer saber o que acontece depois.

### P0 — Crítico

- [x] Atualizar o GDD para a v0.9
- [x] Corrigir a plataforma na documentação (Godot 4.7, não browser)
- [x] Criar TDD, Roadmap, Changelog, Balanceamento e Narrativa
- [x] Separar `GameState` em sistemas (relações, missões, capítulos, economia, saída, bastidores, save, finais), mantendo-o como orquestrador — comportamento idêntico provado por `tests/equivalencia.gd`
- [x] Separar `main.gd` em telas e componentes (8 telas, 3 componentes; lógica idêntica e telas comparadas por screenshot)
- [ ] Garantir o loop principal estável (testes verdes a cada passo, sem mudar comportamento)

### P1 — Alta

- [x] Resultado explicado em linguagem narrativa ("Vera e Bram lutaram como uma só lâmina"), com a soma do score como detalhe opcional
- [x] Primeiras cenas do resultado integradas (Vera e Bram, Lyssa e Mira, Theo e Lyssa)
- [ ] Restante das cenas do resultado (`art/specs/cenas/cenas_resultado.json`: genéricas por momento, derrota de Vera e Bram, outros pares)
- [x] Bastidores que evoluem relações, fama no povo e estima da cidade, e revelam melhorias da guilda (13 cenas novas)
- [x] Quadro de avisos no estilo de vila de RPG (por código; arte especificada em `quadro_avisos.json`)
- [ ] Feedback visual de relações (o que mudou entre quem, e por quê)
- [x] Game juice v1 (só código): selo, dado, placar, momentos de personagem, transições — ver Changelog
- [x] Dado d20 arremessado na cena nos testes (provisório por código; sprites especificados em `dado.json`)
- [ ] Game juice v2 (partículas com os sprites de `efeitos.json`) e v3 (som)
- [ ] Melhor apresentação dos personagens (retratos maiores na montagem, falas curtas)
- [ ] Mesma missão + party diferente = história diferente (textos por dupla/herói em `missions.json`)
- [ ] Arcos pessoais para Lyssa, Bram, Vera e Corin
- [ ] Eventos de rota que reagem a quem está no grupo e às condições
- [ ] Legibilidade do mapa (tamanho dos nós, contraste, legenda)

### P2 — Média

- [ ] Simulação de 1.000+ partidas com relatório (uso por personagem, duplas, vínculos, missões ignoradas, taxa de sucesso por herói, duração média, tamanho de party)
- [ ] Ferramenta de balanceamento a partir do relatório
- [ ] Política de simulação "pensante" (além da aleatória), para medir o teto

### P3 — Futuro

- [ ] Trilha e efeitos sonoros
- [ ] Tela de opções (volume, velocidade do mapa)
- [ ] Mais capítulos, personagens, missões e finais
- [x] Especificar os assets de cenário, objetos, interface, fundos e efeitos (`art/specs/cenario/`)
- [ ] Produção dos assets P0 pelos artistas e integração no jogo
- [x] Integrar as primeiras artes: ícones de itens, miniaturas (estado parado), páginas do Livro, ícone do jogo
- [ ] Integrar o restante quando chegar: estados das miniaturas, ornamentos do Livro, pergaminho do mapa (`mapa_pergaminho.json`), ícone do Windows redesenhado
- [ ] Arte final
- [ ] Localização

---

## Em espera (só depois da v1.0, e se passarem no teste de mecânica)

- Políticas e rituais da guilda (inspiração Cult of the Lamb)
- Habilidades de acampamento por classe
- Remoção de traços (sanatório)
- Minigame opcional por tipo de missão
- Salvar no meio da expedição

## Fora de escopo agora

Novos sistemas complexos de RPG, centenas de itens, dezenas de classes, árvores grandes de habilidades, sistemas paralelos que não afetam relações, conteúdo sem consequência, expansão exagerada do mapa.
