# HOLLOWVEIL — A Casa Morvant

Horror em primeira pessoa com enigmas e cenas fantasmas em vista lateral. Godot 4.7, só GDScript, sem nenhuma imagem ou som externo: os cômodos, os personagens, o sangue, a trilha e os efeitos são gerados por código. O design completo está em [../docs/design/GDD.md](../docs/design/GDD.md).

Esta versão é a **fatia vertical do térreo**: saguão, sala de jantar, biblioteca e cozinha, com três enigmas (A Ceia, O Atlas e Olhos no Pote), três cenas de morte, a Prancheta de pistas, sanidade e salvamento automático.

## Jogar

```bash
flatpak run org.godotengine.Godot --path game
```

Com o Godot instalado normalmente, use `godot --path game`.

## Controles

| Ação | Entrada |
|---|---|
| Andar, examinar, abrir enigma | clique (o cursor muda conforme a ação) |
| Adiantar fala | clique |
| Sair do enigma / pular cena / pausar | Esc |
| Tela cheia | F11 |

Os formatos do cursor:

| Cursor | O que o clique faz |
|---|---|
| Chama | nada |
| Seta | anda |
| Olho | examina |
| Coração | abre um enigma |
| Boca | voz ou evento |
| Cadeado | está fechado |
| Mão | pega ou move uma peça |

## Opções

Gore, efeitos de tela, **Modo VGA** (pontilhado com paleta curta), tela cheia e volumes. As preferências ficam em `user://preferencias.json` e o progresso em `user://investigacao.json`.

## Testes

Teste de lógica sem tela, num perfil temporário:

```bash
tests/run_tests.sh
```

Ele confere:
- a Ceia tem solução única e os Olhos no Pote têm saída em 60 sementes;
- a Prancheta dá as pistas 1 e 2 e, na terceira, Morvant resolve o enigma;
- Esc fecha o enigma e pausa o jogo;
- as portas e as travas respeitam o progresso;
- salvar e carregar preservam o progresso.

Com `-- --qa`, o jogo não grava o save e aceita atalhos de teste:

| Tecla | Ação |
|---|---|
| F6 | Resolve o enigma atual |
| F7 | Diminui a sanidade |
| F8 | Aumenta a sanidade |

## Ferramentas

| Script | Para que serve |
|---|---|
| `tools/bake_music.gd` | Gera `music/*.wav` com a mesma síntese de `scripts/audio/synth.gd`. Sem esses arquivos, cada faixa é gerada na primeira vez que toca, o que deixa alguns segundos de silêncio. |
| `tools/make_theme.gd` | Gera `resources/ui_theme.tres` a partir de `scripts/ui/theme.gd`. |

```bash
flatpak run org.godotengine.Godot --headless --path game --script res://tools/bake_music.gd
```

## Estrutura

```text
scripts/
  core/      estado, salvamento e fluxo (menu → introdução → casa → fim)
  audio/     síntese de música e efeitos, ambiente com relâmpagos
  gfx/       perspectiva dos cômodos, luzes, pós-processamento, sangue
  ui/        tema, cursor, legendas, HUD da sanidade, menu, opções
  house/     motor de vistas e os cômodos (views/)
  puzzles/   A Ceia, O Atlas, Olhos no Pote
  ghosts/    palco das cenas fantasmas e os roteiros de morte
```

O protótipo anterior, feito com o Codex, está preservado em `../arquivo/game_codex`.
