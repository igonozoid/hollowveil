# HollowVeil — A Última Ronda

Uma aventura curta da IGNF Lab em três capítulos. Lia Varela investiga o fechamento da passagem de evacuação da mansão. A ronda começa no corredor e passa pela Galeria das Lanternas e pelo Arquivo Submerso.

## Jogar

Execute a edição Linux x86-64 ou abra este diretório como projeto no Godot 4.4.1 e pressione F5. Pelo terminal, use `godot --path game` a partir da raiz do projeto.

Ande com **A/D** ou **←/→** e use **E** para interagir. No close-up, use o mouse ou navegue com **Tab** e confirme com **Enter**. **Esc** fecha uma leitura, retorna do close-up ou abre o menu durante a exploração.

O jogo salva o capítulo, a posição ao interagir e o rascunho do enigma. **Continuar** retoma a investigação. **Nova investigação** pede confirmação antes de substituir um checkpoint existente. Volume, tela cheia e efeitos visuais são gravados separadamente.

## Validação

Em Linux, execute o teste em um perfil vazio. Ele percorre os três capítulos, incluindo tentativas inválidas, retomada, desfecho e confirmação antes de sobrescrever o save.

```sh
profile=$(mktemp -d)
XDG_DATA_HOME="$profile" godot --headless --path game --fixed-fps 60 --script ../tests/campaign_smoke.gd
```

A apresentação usa geometria 2D paramétrica, luz e materiais em Godot. Os auxiliares de geometria e luz são da biblioteca local IGNF Vector Cinema. O áudio ambiente e os efeitos são sintetizados.

## Mapa e tutorial

Durante a exploração, pressione **M** para abrir o mapa. Ele mostra a ala atual, a posição de Lia, os pontos de interesse e o estado da saída. Use **M** ou **Esc** para fechar. Pressione **H** para consultar o tutorial. A linha acima da interação indica o próximo passo e acompanha o progresso da investigação.

## Modo de teste

Inicie o executável com `./HollowVeil.x86_64 -- --qa`. Ainda no Godot, use `godot --path game -- --qa`.

| Tecla | Ação |
| --- | --- |
| **F3** | Mostrar os comandos de teste. |
| **F6** | Resolver o enigma da ala e liberar a saída. |
| **F7** | Avançar ao próximo capítulo ou ao desfecho. |
| **F8** | Reiniciar o capítulo e apagar seu rascunho na sessão de teste. |

Os comandos funcionam durante a exploração. O modo de teste começa em um perfil de campanha em memória e preserva o checkpoint normal.
