# Changelog — A Guilda

Histórico de versões, da mais recente para a mais antiga. Datas dos commits no repositório.

---

## Especificações de assets de cenário — 2026-10-08

- `art/specs/cenario/`: guia de estilo (`_estilo_cenario.json`), índice com 237 assets (`_indice.json`, prioridades P0–P3 e status de produção) e um JSON por categoria: ícones de nó do mapa, marcos/terreno/veículos do mapa, itens e ferramentas, objetos da guilda, fundos, interface e efeitos.
- Sem personagens vivos ou mortos-vivos; modelo e prefixos para novos assets.

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
