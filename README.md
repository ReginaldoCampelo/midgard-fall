# O Último Drakkar: A Queda de Midgard

> Protótipo 2D em **Godot 4.6.1** com foco em movimentação de personagem, combate em combo, arremesso de espada e VFX.

![Godot](https://img.shields.io/badge/Godot-4.6.1-478cbf?logo=godot-engine&logoColor=white)
![Status](https://img.shields.io/badge/status-em%20desenvolvimento-ffb020)
![Plataforma](https://img.shields.io/badge/plataforma-PC%20%7C%20Mobile-2ea043)

## Sumário

- [Visão geral](#visão-geral)
- [Estado atual do projeto](#estado-atual-do-projeto)
- [Tecnologias](#tecnologias)
- [Como executar](#como-executar)
- [Controles](#controles)
- [Mecânicas implementadas](#mecânicas-implementadas)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Scripts principais](#scripts-principais)
- [Roadmap sugerido](#roadmap-sugerido)
- [Licença](#licença)

## Visão geral

**O Último Drakkar: A Queda de Midgard** é um projeto de jogo 2D com estética de aventura/plataforma.
Atualmente, o núcleo de gameplay já conta com:

- movimentação horizontal;
- pulo duplo;
- combos de ataque no chão e no ar;
- arremesso de espada;
- coleta de espada;
- efeitos visuais para ações (poeira, golpes, impacto etc.);
- background com parallax e nuvens em movimento.

## Estado atual do projeto

Snapshot com base na configuração atual do projeto:

- **Engine alvo:** `Godot 4.6.1` (`config/features = ["4.6", "Mobile"]`)
- **Cena principal configurada:** `res://background/background.tscn`
- **Fase jogável montada:** `res://levels/island_t1.tscn`
- **Autoload global:** `res://management/global.gd`
- **Resolução base do viewport:** `640x360` (janela com override `1280x720`)

## Tecnologias

- **Godot Engine 4.6.1**
- **GDScript**
- **TileMap/TileSet** para terreno
- **AnimatedSprite2D** para personagem, coletáveis, projéteis e efeitos

## Como executar

### Pela interface do Godot

1. Abra o **Godot 4.6.1**.
2. Importe este diretório como projeto.
3. Clique em **Run Project** para executar a cena principal configurada.

### Para testar a fase `island_t1`

1. Abra `res://levels/island_t1.tscn`.
2. Execute com **Run Current Scene** (`F6`).

## Controles

| Ação | Teclado | Mouse | Gamepad |
|---|---|---|---|
| Mover para esquerda | `A` / `←` | - | D-pad esquerda / eixo esquerdo (-X) |
| Mover para direita | `D` / `→` | - | D-pad direita / eixo esquerdo (+X) |
| Pular | `W` / `↑` / `Space` | - | Botão `A` |
| Atacar | `J` | Clique esquerdo | Botão `X` |
| Arremessar espada | `K` | Clique direito | - |

## Mecânicas implementadas

- **Movimento e física do personagem** (`CharacterBody2D`)
- **Pulo duplo** com controle por contador de saltos
- **Combo de ataque no chão** (3 etapas)
- **Combo aéreo** (2 etapas)
- **Arremesso de espada** com projétil (`CharacterSword`)
- **Pickup de espada** (`CollectableSword`) para habilitar ataques
- **Spawn centralizado de VFX** via autoload `global.spawn_effect(...)`
- **Parallax dinâmico** com múltiplas camadas e nuvens com velocidades diferentes

## Estrutura do projeto

```text
.
|-- background/         # Cenário, parallax, nuvens, reflexos d'água
|-- character/          # Cena, lógica e animações do personagem
|-- collectables/       # Itens coletáveis (ex.: espada)
|-- components/         # Componentes base reutilizáveis
|-- levels/             # Cenas de nível (ex.: island_t1)
|-- management/         # Autoloads e serviços globais
|-- terrain/            # TileSet/TileMap de terreno
|-- throwables/         # Objetos arremessáveis
|-- visual_effects/     # Efeitos visuais (ataque, poeira, explosão etc.)
`-- project.godot       # Configuração do projeto
```

## Scripts principais

- `character/character.gd`: movimentação, pulo, ataques, combo e arremesso
- `character/character_texture.gd`: máquina de animação e janela de hit dos ataques
- `throwables/character_sword/character_sword.gd`: lógica da espada arremessada e drop
- `collectables/sword/collectable_sword.gd`: consumo da espada pelo personagem
- `management/global.gd`: utilitário global de spawn de efeitos
- `background/background.gd`: movimentação contínua das nuvens

## Roadmap sugerido

- definir oficialmente a cena principal jogável (ex.: `levels/island_t1.tscn`);
- adicionar HUD (vida, estado da espada, feedback de combo);
- incluir inimigos e sistema de dano no `AttackArea`;
- criar loop de gameplay com objetivo, vitória e derrota;
- configurar testes de regressão de cenas e validação de input.

## Licença

Este repositório **ainda não possui licença declarada**.

