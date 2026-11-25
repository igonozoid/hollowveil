# HOLLOWVEIL — A Casa Morvant

Horror em primeira pessoa com enigmas e cenas fantasmas em vista lateral. Godot 4.7, só GDScript, sem nenhuma imagem ou som externo: os cômodos, os personagens, o sangue, a trilha e os efeitos são gerados por código. O design completo está em [../docs/design/GDD.md](../docs/design/GDD.md).

Esta versão traz o **térreo** e o **1º andar** completos e a **primeira parte dos porões**:
- **Cômodos do térreo:** saguão, porta de entrada, sala de jantar, biblioteca, cozinha, estufa e sala de música.
- **Cômodos do 1º andar:** corredor, quartos de Celeste, de hóspedes e de Ofélia, banheiro e berçário.
- **Cômodos dos porões:** galeria, adega, câmara fria e capela. Lá embaixo, Dália carrega uma lamparina que segue o cursor.
- **Catorze enigmas:** A Ceia, O Atlas, Olhos no Pote, As Veias, A Prancheta, A Partitura, A Caixa de Música, O Banho, A Pele, O Móbile, Os Sussurros, A Balança, Os Ganchos e O Vitral.
- **Sete cenas de morte** (Leocádia, Tobias, Benedita, Celeste, Hélio, Ofélia e o padre Anselmo) e **duas de memória**: o berço vazio e o vinho do jantar.
- **Sistemas:** pistas da Prancheta, sanidade e salvamento automático.

A demonstração termina atrás do altar da capela, na passagem para a cripta.

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
| Andar n'Os Ganchos | setas ou WASD (Z desfaz) |
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
- cada enigma gerado por semente tem solução (e, quando deve, solução única) em 16 a 60 sementes;
- a Balança só se resolve com a estratégia certa, e os Ganchos pedem exatamente o mínimo de empurrões calculado;
- a Prancheta dá as pistas 1 e 2 e, na terceira, Morvant resolve o enigma;
- Esc fecha o enigma e pausa o jogo;
- as portas e as travas respeitam o progresso, do saguão até a cripta;
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
| `tools/bake_music.gd` | Gera `music/*.wav` com a mesma síntese de `scripts/audio/synth.gd`. Sem esses arquivos, cada faixa é gerada na primeira vez que toca, o que deixa alguns segundos de silêncio. Só gera as faixas que faltam; `-- --all` refaz todas. |
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
  puzzles/   um script por enigma
  ghosts/    palco das cenas fantasmas e os roteiros de morte
```

O protótipo anterior, feito com o Codex, está preservado em `../arquivo/game_codex`.
