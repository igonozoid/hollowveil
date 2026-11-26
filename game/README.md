# HOLLOWVEIL — A Casa Morvant

Horror em primeira pessoa com enigmas e cenas fantasmas em vista lateral. Godot 4.7, só GDScript, sem nenhuma imagem ou som externo: os cômodos, os personagens, o sangue, a trilha e os efeitos são gerados por código. O design completo está em [../docs/design/GDD.md](../docs/design/GDD.md).

Esta versão traz o **jogo inteiro**, do saguão aos quatro finais:
- **Cômodos do térreo:** saguão, porta de entrada, sala de jantar, biblioteca, cozinha, estufa e sala de música.
- **Cômodos do 1º andar:** corredor, quartos de Celeste, de hóspedes e de Ofélia, banheiro e berçário.
- **Cômodos dos porões:** galeria, adega, câmara fria, capela, cripta e o labirinto das fundações, em primeira pessoa. Lá embaixo, Dália carrega uma lamparina que segue o cursor.
- **Cômodos do sótão:** o sótão, a torre do relógio e o Teatro Anatômico.
- **Dezenove enigmas:** A Ceia, O Atlas, Olhos no Pote, As Veias, A Prancheta, A Partitura, A Caixa de Música, O Banho, A Pele, O Móbile, Os Sussurros, A Balança, Os Ganchos, O Vitral, O Ossuário, O Labirinto, O Baú, O Luar e A Montagem.
- **Sete cenas de morte** (Leocádia, Tobias, Benedita, Celeste, Hélio, Ofélia e o padre Anselmo) e **quatro de memória**: o berço vazio, o vinho do jantar, o enterro de Benjamim e a costura.
- **Quarenta relíquias** escondidas (páginas do diário de Morvant, fotografias e peças), relidas no **Relicário** do menu de pausa.
- **A Noite Mais Escura:** uma segunda volta mais dura, que abre com as 40 relíquias e um final visto.
- **Sistemas:** pistas da Prancheta, sanidade e salvamento automático.

- **O confronto com Morvant e quatro finais:** A Médium, A Peça Final, O Anfitrião e o secreto, A Canção. O final depende da escolha no teatro, das almas libertadas, das pistas de nível 3 e da sanidade. Ao terminar, o save da volta é apagado; os finais vistos ficam guardados.

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
| Andar n'O Labirinto | W/↑ avança, S/↓ recua, A/← e D/→ viram |
| O Ossuário | clique ou arraste põe crânios; botão direito marca com giz |
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
- toda figura do Ossuário se resolve só por linha e coluna, e no Labirinto o caminho mais curto escapa da coisa;
- o Baú sempre abre em até 8 tentativas com palpites coerentes, e no Luar os espelhos da semente levam a lua ao olho;
- A Montagem sempre se desfaz cortando linhas livres, e os finais seguem a regra;
- as 40 relíquias aparecem, somem ao serem pegas e entram no Relicário; a Noite Mais Escura abre e pesa como deve;
- a Prancheta dá as pistas 1 e 2 e, na terceira, Morvant resolve o enigma;
- Esc fecha o enigma e pausa o jogo;
- as portas e as travas respeitam o progresso, do saguão até o final;
- salvar e carregar preservam o progresso.

Com `-- --qa`, o jogo não grava o save e aceita atalhos de teste:

| Tecla | Ação |
|---|---|
| F6 | Resolve o enigma atual |
| F7 | Diminui a sanidade |
| F8 | Aumenta a sanidade |

## Walkthrough e itch.io

- O guia completo, com spoilers, está em [../docs/WALKTHROUGH.md](../docs/WALKTHROUGH.md).
- O texto da página do itch.io está em [../docs/itch/PAGINA.md](../docs/itch/PAGINA.md).
- Para gerar as versões e enviá-las (precisa dos modelos de exportação do Godot 4.7.2 e do `butler`):

```bash
tools/itch/build.sh
```

```bash
tools/itch/push.sh usuario/hollowveil 1.0.0
```

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
