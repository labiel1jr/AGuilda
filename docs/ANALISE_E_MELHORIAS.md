# A Guilda — Análise e Plano de Melhorias

> Documento de análise técnica e de design do projeto **A Guilda**, criado para registrar pontos fortes, problemas identificados, decisões de design e melhorias planejadas.

**Versão de referência:** v0.9
**Engine:** Godot 4.7
**Status:** Desenvolvimento / Vertical Slice
**Repositório:** `labiel1jr/AGuilda`

---

# 1. Visão Geral

A Guilda possui uma identidade própria baseada em:

* gerenciamento de personagens;
* despacho de aventureiros;
* relacionamento entre personagens;
* formação de parties;
* expedições;
* consequências persistentes;
* narrativa ramificada;
* RPG leve;
* estresse e transformação dos personagens;
* vínculos que alteram o gameplay.

A principal inspiração é o conceito de gerenciamento e despacho de personagens de **Dispatch**, adaptado para um universo de fantasia medieval.

A proposta não deve ser simplesmente criar um "Dispatch medieval".

O objetivo é desenvolver um jogo próprio, baseado na ideia:

> **Quem você envia define quem eles se tornam.**

---

# 2. Pilar Principal do Jogo

O verdadeiro foco do jogo não deve ser apenas completar missões.

O foco é:

> **Decidir quais pessoas devem enfrentar uma situação juntas e lidar com as consequências dessa decisão.**

O jogador deve pensar:

* Quem devo enviar?
* Quem combina com quem?
* Quem não deveria trabalhar junto?
* Quem precisa de experiência?
* Quem está cansado?
* Quem está estressado?
* Quem pode criar um vínculo?
* Quem pode sair da Guilda?
* Quem pode se tornar uma peça importante da história?

A missão é o mecanismo que coloca os personagens em situações capazes de gerar essas histórias.

---

# 3. Regra de Ouro do Projeto

## Não transformar o jogador em um administrador de números.

O jogador deve pensar:

> "Será que eu mando Theo e Lyssa juntos?"

e não:

> "Theo tem 8 de força, espada +2, talento +1, fadiga 0 e bônus de bioma +1."

Os sistemas numéricos devem existir para apoiar a decisão narrativa.

### Prioridade:

```text
PERSONAGEM
    ↓
RELAÇÃO
    ↓
PARTY
    ↓
DECISÃO
    ↓
MISSÃO
    ↓
CONSEQUÊNCIA
    ↓
HISTÓRIA
```

---

# 4. Principais Pontos Fortes

## 4.1 Conceito

O conceito de Mestre de Despacho é claro e possui potencial.

O jogador não controla diretamente os aventureiros.

Ele controla:

> **quem vai, quem fica e quem vai junto.**

Isso cria uma identidade diferente de um RPG tradicional.

---

## 4.2 Sistema de Party

A formação da Party deve continuar sendo uma das decisões mais importantes do jogo.

Uma Party maior não deve ser automaticamente melhor.

Mais personagens podem significar:

* mais poder;
* maior cobertura de atributos;
* mais relações;
* mais possibilidades narrativas;
* maior risco de conflitos;
* maior desgaste;
* menos personagens disponíveis para outras missões.

---

## 4.3 Afinidade Assimétrica

O sistema de afinidade assimétrica é um dos elementos mais interessantes.

Exemplo:

```text
Theo → Vera = +7
Vera → Theo = +3
```

A afinidade efetiva pode utilizar o menor valor:

```text
Afinidade efetiva = +3
```

Mas a diferença entre os valores deve continuar existindo narrativamente.

Isso permite relações como:

> Theo considera Vera sua melhor amiga.

enquanto:

> Vera considera Theo apenas um bom companheiro de equipe.

Esse comportamento deve ser preservado.

---

# 5. Sistema de Vínculos

Os vínculos devem continuar tendo efeitos mecânicos.

Exemplos:

### Mentoria

Um personagem experiente ajuda outro personagem.

```text
Mentor
   ↓
Impulso
   ↓
Personagem mais fraco
```

### Atração

Pode gerar bônus de desempenho, mas também consequências.

### Rivalidade

Pode aumentar desempenho e criar conflitos.

### Irmandade

Pode fazer com que a saída de um personagem provoque consequências para outro.

---

## Regra importante

Os relacionamentos não devem ser apenas:

```text
+10 amizade
-5 rivalidade
```

O relacionamento deve **alterar o funcionamento do jogo**.

---

# 6. Mapa de Expedição

O sistema de expedição é uma das principais evoluções do projeto.

Fluxo desejado:

```text
ESCOLHER PARTY
      ↓
DESPACHAR
      ↓
MAPA
      ↓
ESCOLHER ROTA
      ↓
EVENTOS
      ↓
RECURSOS
      ↓
FERIMENTOS
      ↓
ESTRESSE
      ↓
PREPARAÇÃO
      ↓
OBJETIVO
      ↓
RESULTADO
```

O mapa deve continuar funcionando como uma extensão do conceito de despacho.

O jogador acompanha a expedição, mas não deve transformar o jogo em um RPG de controle direto.

---

# 7. Mapa Mágico

O Mapa Mágico possui potencial para se tornar uma das principais identidades visuais de A Guilda.

Elementos importantes:

* mapa de pergaminho;
* biomas;
* rios;
* cidades;
* caminhos;
* nós;
* tesouros;
* eventos;
* miniboss;
* acampamentos;
* mercadores;
* objetivo;
* tokens dos aventureiros;
* neblina;
* animações.

A implementação atual permite escolher os nós alcançáveis.

Essa abordagem deve ser considerada a referência atual do design.

O GDD antigo deve ser atualizado para refletir esse comportamento.

---

# 8. Sistema de Estresse

O sistema de estresse deve ser mantido porque transforma consequências temporárias em mudanças de personalidade.

Modelo:

```text
Estresse
0 ─────────────── 10
                    ↓
             Ponto de ruptura
                    ↓
          Virtude ou Aflição
```

Exemplos de Virtudes:

* Corajoso;
* Focado;
* Estoico;
* Inspirador.

Exemplos de Aflições:

* Paranoico;
* Egoísta;
* Desesperado;
* Irracional;
* Medroso.

A ideia principal:

> O personagem não deve simplesmente voltar ferido. Ele pode voltar diferente.

---

# 9. Cuidado com o Excesso de Sistemas

Atualmente o projeto possui muitos sistemas:

* atributos;
* XP;
* níveis;
* talentos;
* magias;
* equipamentos;
* consumíveis;
* saque;
* mercado;
* PV;
* fadiga;
* moral;
* afinidade;
* vínculos;
* estresse;
* aflições;
* virtudes;
* traços;
* expedições;
* recursos;
* reputação;
* upgrades;
* capítulos;
* flags;
* finais;
* missões pessoais.

Isso é interessante, mas representa um risco de escopo.

## Decisão

Antes de adicionar novos grandes sistemas, consolidar e polir os sistemas existentes.

---

# 10. Hierarquia dos Sistemas

Os sistemas devem ser tratados em camadas.

## Nível 1 — Essencial

```text
Personagens
     ↓
Relações
     ↓
Party
     ↓
Despacho
     ↓
Consequência
```

## Nível 2 — Suporte

```text
Moral
Fadiga
PV
Estresse
```

## Nível 3 — Progressão

```text
XP
Nível
Talentos
Equipamentos
Magias
```

## Nível 4 — Metagame

```text
Guilda
Reputação
Upgrades
Economia
```

## Nível 5 — Narrativa

```text
Capítulos
Flags
Missões pessoais
Finais
```

Os níveis superiores nunca devem prejudicar a compreensão dos sistemas fundamentais.

---

# 11. Refatoração do GameState

O `GameState` cresceu bastante e concentra muitas responsabilidades.

A longo prazo, separar os sistemas.

Estrutura sugerida:

```text
scripts/
    core/
        game_state.gd

    systems/
        relationship_system.gd
        mission_system.gd
        chapter_system.gd
        economy_system.gd
        progression_system.gd
        departure_system.gd
        expedition_system.gd
        save_system.gd
        stress_system.gd
```

O `GameState` deve funcionar principalmente como um **orquestrador do estado global**.

Evitar transformar `GameState` em uma classe que conhece absolutamente todas as regras do jogo.

---

# 12. Refatoração do Main

O `main.gd` também cresceu bastante.

A interface deve ser gradualmente dividida.

Estrutura sugerida:

```text
scripts/
    ui/
        screens/
            title_screen.gd
            guild_screen.gd
            mission_board.gd
            party_screen.gd
            expedition_screen.gd
            result_screen.gd
            relations_screen.gd
            market_screen.gd
            book_screen.gd

        components/
            hero_card.gd
            mission_card.gd
            affinity_bar.gd
            stress_bar.gd
            outcome_panel.gd
```

Benefícios:

* manutenção mais fácil;
* menos dependência entre telas;
* código mais legível;
* testes mais simples;
* menor risco de regressão.

---

# 13. Data-Driven Design

Uma das melhores decisões do projeto é separar dados e lógica.

Manter:

```text
data/
    heroes.json
    missions.json
    chapters.json
    route.json
    traits.json
    classes.json
    items.json
    endings.json
```

e:

```text
scripts/core/
```

para as regras.

## Regra

> Conteúdo novo deve ser preferencialmente criado nos arquivos de dados, e não através de código específico.

Isso facilita:

* criação de personagens;
* criação de missões;
* criação de capítulos;
* balanceamento;
* testes;
* expansão futura;
* criação de ferramentas internas.

---

# 14. Missões Devem Contar Histórias

As missões não devem existir apenas para testar atributos.

Evitar que uma missão seja apenas:

```text
Força + Destreza
```

Cada missão importante deveria responder pelo menos uma pergunta sobre os personagens.

Exemplo:

```text
O irmão de Senna desapareceu.
```

A mesma missão pode gerar resultados diferentes dependendo da Party.

### Senna + Vera

Uma relação.

### Senna + Lyssa

Outra relação.

### Senna + Theo

Outra consequência.

Assim:

```text
MESMA MISSÃO
      +
PARTY DIFERENTE
      =
HISTÓRIA DIFERENTE
```

Esse deve ser um dos principais objetivos narrativos do projeto.

---

# 15. Personagens Devem Ser Mais Importantes que Equipamentos

Ao balancear personagens, perguntar:

> "Eu me lembro desse personagem?"

e não apenas:

> "Qual é o DPS dele?"

Cada personagem deve possuir:

* personalidade;
* virtudes;
* defeitos;
* relações;
* conflitos;
* objetivos;
* comportamento;
* possibilidade de transformação.

O jogador deve ter motivos para querer manter um personagem na Guilda mesmo quando ele não é matematicamente o melhor.

---

# 16. Telemetria e Simulação

O projeto já possui testes e simulações.

Isso deve evoluir para uma ferramenta de análise de balanceamento.

Cada partida simulada pode registrar:

```text
Partida
Dias
Missões
Resultado
Party
Score
Afinidade
Moral
Estresse
Traços
Equipamentos
Ouro
Reputação
Personagens que saíram
Vínculos criados
```

Depois analisar:

```text
Qual personagem é mais utilizado?

Qual personagem é ignorado?

Qual dupla aparece mais?

Qual vínculo aparece mais?

Qual vínculo quase nunca acontece?

Qual missão é ignorada?

Qual personagem possui taxa de falha muito alta?

Qual personagem possui taxa de sucesso muito alta?

Qual é a duração média da partida?

Qual tamanho de Party é mais utilizado?
```

---

# 17. Objetivo de Simulação

Criar uma rotina capaz de executar:

```text
1.000+
partidas simuladas
```

e gerar estatísticas.

Exemplo:

```text
PERSONAGEM       USO
-----------------------
Theo             82%
Vera             91%
Senna            13%
Bram             76%
```

Isso pode revelar rapidamente problemas de balanceamento.

---

# 18. Documentação

Existe atualmente uma diferença de versão entre os documentos.

O projeto deve manter uma versão consistente.

### Atualizar:

```text
README
GDD
Roadmap
Changelog
Documentação técnica
```

A documentação deve refletir o estado real do projeto.

---

# 19. Estrutura de Documentação Recomendada

Criar:

```text
docs/
    GDD.md
    TDD.md
    ROADMAP.md
    CHANGELOG.md
    ANALISE_E_MELHORIAS.md
    BALANCEAMENTO.md
    NARRATIVA.md
```

### GDD.md

Documento de design do jogo.

### TDD.md

Documento técnico.

### ROADMAP.md

Próximas funcionalidades.

### CHANGELOG.md

Histórico de versões.

### ANALISE_E_MELHORIAS.md

Este documento.

### BALANCEAMENTO.md

Regras, fórmulas e resultados das simulações.

### NARRATIVA.md

Personagens, relações, capítulos, eventos e finais.

---

# 20. Correções Documentais Prioritárias

## Corrigir versão

Verificar documentos que ainda apresentam versões antigas.

Objetivo:

```text
README      → v0.9
GDD         → v0.9
TDD         → v0.9
Roadmap     → v0.9
```

---

## Corrigir plataforma

O projeto atual utiliza:

```text
Godot 4.7
```

Portanto, documentos antigos que indiquem:

```text
Browser (HTML/JS)
```

devem ser revisados.

A plataforma oficial deve refletir o objetivo real do projeto.

---

# 21. Vertical Slice

Antes de tentar criar o jogo completo, criar uma versão pequena, mas completa.

Um Vertical Slice ideal poderia conter:

```text
6 personagens
20–30 missões
1–2 atos
sistema de afinidade
sistema de vínculos
expedição
estresse
progressão
save
alguns finais
```

O objetivo é provar que o loop inteiro funciona.

```text
Conhecer personagem
      ↓
Formar Party
      ↓
Despachar
      ↓
Explorar
      ↓
Resolver missão
      ↓
Voltar
      ↓
Alterar relações
      ↓
Evoluir
      ↓
Tomar nova decisão
```

---

# 22. O que NÃO fazer agora

Evitar adicionar grandes sistemas antes de consolidar o núcleo.

Não priorizar neste momento:

* novos sistemas complexos de RPG;
* centenas de itens;
* dezenas de classes;
* árvores gigantes de habilidades;
* sistemas paralelos que não afetem relações;
* conteúdo sem consequência;
* expansão exagerada do mapa.

Primeiro:

> **fazer o núcleo funcionar perfeitamente.**

---

# 23. Prioridade de Desenvolvimento

## Prioridade P0 — Crítico

* [ ] Atualizar GDD para v0.9
* [ ] Corrigir documentação de plataforma
* [ ] Criar TDD
* [ ] Consolidar arquitetura
* [ ] Revisar `GameState`
* [ ] Revisar `main.gd`
* [ ] Garantir que o loop principal esteja estável

---

## Prioridade P1 — Alta

* [ ] Melhorar UI
* [ ] Melhorar feedback visual
* [ ] Melhorar mapa mágico
* [ ] Melhorar feedback de relações
* [ ] Melhorar apresentação dos personagens
* [ ] Criar eventos narrativos exclusivos
* [ ] Criar mais consequências entre personagens

---

## Prioridade P2 — Média

* [ ] Telemetria
* [ ] Simulação de 1.000 partidas
* [ ] Ferramentas de balanceamento
* [ ] Estatísticas de uso dos personagens
* [ ] Estatísticas de vínculos
* [ ] Estatísticas de missões

---

## Prioridade P3 — Futuro

* [ ] Mais capítulos
* [ ] Mais personagens
* [ ] Mais missões
* [ ] Mais finais
* [ ] Conteúdo adicional
* [ ] Áudio completo
* [ ] Arte final
* [ ] Localização

---

# 24. Filosofia de Design

Sempre que uma nova mecânica for proposta, fazer estas perguntas:

### 1. Isso melhora as decisões do jogador?

Se não:

> reconsiderar.

### 2. Isso melhora os personagens?

Se não:

> reconsiderar.

### 3. Isso cria histórias diferentes?

Se não:

> reconsiderar.

### 4. Isso adiciona profundidade ou apenas complexidade?

Preferir:

> profundidade.

Evitar:

> complexidade desnecessária.

---

# 25. Teste de Qualidade de uma Mecânica

Antes de implementar uma nova mecânica:

```text
Nova mecânica
      ↓
Afeta decisão?
      ↓
SIM
      ↓
Afeta personagem?
      ↓
SIM
      ↓
Cria consequência?
      ↓
SIM
      ↓
Implementar
```

Se todas as respostas forem "não":

> provavelmente a mecânica não é necessária.

---

# 26. Identidade de A Guilda

O projeto deve preservar estes elementos:

```text
DESPACHO
   +
PERSONAGENS
   +
RELAÇÕES
   +
DECISÕES
   +
CONSEQUÊNCIAS
   +
HISTÓRIA
```

Não transformar o jogo em:

```text
RPG tradicional
```

nem em:

```text
simulador administrativo
```

nem em:

```text
visual novel pura
```

A Guilda deve permanecer no meio desses gêneros.

---

# 27. Objetivo Final

O objetivo não é criar um jogo onde o jogador encontra a combinação matematicamente perfeita.

O objetivo é criar situações em que o jogador diga:

> "Eu sei que essa não é a melhor Party..."

mas envie mesmo assim porque:

> "Eu quero ver o que vai acontecer entre eles."

Esse é o momento em que o sistema está funcionando.

---

# 28. Frase de Direção do Projeto

> ## **Não faça o jogador administrar números. Faça-o administrar pessoas.**

E, como segunda regra:

> ## **A melhor Party não é necessariamente a mais forte. É a que cria a melhor história.**

---

# 29. Próxima Grande Meta

## A Guilda v1.0 — Vertical Slice

Objetivo:

> Criar uma experiência pequena, completa e jogável que demonstre claramente por que A Guilda é diferente.

Critério de sucesso:

```text
O jogador conhece personagens
        ↓
cria relações
        ↓
forma uma Party
        ↓
faz um despacho
        ↓
enfrenta consequências
        ↓
vê personagens mudarem
        ↓
toma novas decisões
        ↓
quer saber o que acontecerá depois
```

Se esse ciclo for divertido mesmo com poucos personagens e poucas missões, o projeto possui uma base sólida para crescer.

---

# 30. Checklist de Revisão Antes da v1.0

### Design

* [ ] O jogador entende seu papel como Mestre de Despacho?
* [ ] A formação da Party é interessante?
* [ ] Relações realmente importam?
* [ ] Vínculos alteram gameplay?
* [ ] Personagens possuem identidade?
* [ ] Consequências são perceptíveis?
* [ ] Missões geram histórias?
* [ ] Parties diferentes produzem resultados diferentes?

### Técnico

* [ ] `GameState` está modularizado?
* [ ] `main.gd` está modularizado?
* [ ] Dados estão separados da lógica?
* [ ] Saves estão funcionando?
* [ ] Testes estão funcionando?
* [ ] Simulações estão funcionando?
* [ ] Não existem dependências circulares desnecessárias?

### UX

* [ ] O jogador entende o que está acontecendo?
* [ ] O jogador entende por que ganhou/perdeu?
* [ ] O jogador entende as relações?
* [ ] O jogador entende o estresse?
* [ ] O jogador entende as consequências?
* [ ] O mapa é legível?
* [ ] O feedback visual é suficiente?

### Narrativa

* [ ] Personagens possuem personalidade?
* [ ] Existem relações diferentes?
* [ ] Existem conflitos?
* [ ] Existem eventos exclusivos?
* [ ] Existem consequências permanentes?
* [ ] Existem finais diferentes?

---

# 31. Status Atual

**Projeto:** A Guilda
**Versão analisada:** v0.9
**Estado:** Vertical Slice / Desenvolvimento

### Avaliação atual

| Área            | Avaliação |
| --------------- | --------: |
| Conceito        |      9/10 |
| Gameplay        |      9/10 |
| Sistemas        |      9/10 |
| Narrativa       |    8,5/10 |
| Arquitetura     |      8/10 |
| Data-driven     |    9,5/10 |
| Testabilidade   |      9/10 |
| UI/UX           |    7,5/10 |
| Documentação    |      6/10 |
| Risco de escopo |      Alto |
| Potencial       |  **9/10** |

---

# 32. Conclusão

A Guilda possui uma base muito forte.

O maior diferencial do projeto não está no combate, nos atributos ou nos equipamentos.

Está nas relações entre os personagens e nas consequências das decisões do jogador.

A direção recomendada é:

```text
MENOS SISTEMAS NOVOS
        +
MAIS PROFUNDIDADE
        +
MAIS PERSONAGENS
        +
MAIS CONSEQUÊNCIAS
        +
MAIS POLIMENTO
```

O objetivo da próxima fase não deve ser simplesmente adicionar conteúdo.

Deve ser fazer o jogador **se importar com quem está enviando para a missão**.

---

**Documento criado para acompanhamento do desenvolvimento de A Guilda.**

**Última revisão:** 2026-10-07
