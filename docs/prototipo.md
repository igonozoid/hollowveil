# HollowVeil — primeira fatia jogável

Proposta de pré-produção da IGNF Lab em Godot 4 e GDScript. A primeira fatia valida o percurso completo entre exploração lateral, investigação em close-up e mudança persistente no ambiente. Corredor, três portas e relógio seguem a proposta do documento de contexto.

## Cena e puzzle

A protagonista entra no corredor para investigar a interrupção do serviço de vigília da mansão. Um painel de rondas traz três marcas em ordem. No close-up do relógio, ela gira três anéis de latão independentes, cada um com quatro posições, até alinhar essas marcas com as respectivas janelas. Um botão de teste confirma a combinação. A posição das marcas em cada anel varia, de modo que repetir a mesma posição nos três não resolve o puzzle. Ao acertar, o relógio abre um compartimento com um registro adulterado e libera a terceira porta.

- A porta de entrada funciona como marco da chegada. A segunda protege uma sala lacrada e oferece uma inspeção contextual. A terceira passa de bloqueada a atravessável e leva a um pequeno patamar que encerra a demo.
- Setas ou A/D movem a protagonista. E interage com o hotspot em alcance. No close-up, mouse e teclado oferecem rotação, teste e saída. Esc retorna à exploração na mesma posição.
- Uma tentativa incorreta dá retorno visual e sonoro e mantém a combinação. Fechar e reabrir recupera o rascunho. A solução abre o compartimento uma vez e permanece visível nas revisitas.
- A pista deve ser legível por forma e ordem. O fechamento mantém o foco de teclado no hotspot anterior. Trinco, clique e abertura têm também sinais visuais.

## Arte, personagem e som

IGNF Vector Cinema em semirrealismo vetorial 2D, com geometria, curvas, materiais e iluminação procedurais. Usar desenho por código como o `_draw()` de IronVeil, com arcos em ogiva, madeira escurecida, latão envelhecido, verde profundo e focos de luz de vela. Construir profundidade com primeiro plano, plano de jogo e fundo em paralaxe discreta. O close-up reaproveita os parâmetros do relógio visível no corredor.

A protagonista é feminina e tem silhueta própria. Usar a descrição de Luana como referência anatômica provisória, com corpo chubby, quadris largos, coxas volumosas, cintura natural e seios pequenos. Para a primeira passagem, propor uma investigadora de cabelo curto e casaco de viagem vinho, com rosto e figurino próprios. Validar repouso, caminhada e gesto de inspeção com pivôs estáveis e transferência de peso. Nome, história definitiva e prancha visual permanecem em aberto.

Ambiência de madeira e vento, com tique-taque em alcance do relógio. Um módulo de áudio recebe eventos de foco, clique e solução. O módulo de animação responde à abertura do close-up, aos anéis e ao compartimento. Usar sons provisórios sintetizados para validar a leitura.

## Arquitetura e persistência

| Módulo | Responsabilidade |
| --- | --- |
| Corredor e patamar | Cenas Node2D com limites, portas e hotspots Area2D. A protagonista usa CharacterBody2D e a câmera segue o eixo horizontal. IDs estáveis ligam interações ao estado. |
| Relógio | Cena Control em CanvasLayer. Recebe posições iniciais, valida a combinação e emite sinais de alteração, conclusão e fechamento. Suspende a entrada da protagonista durante o close-up. |
| Sessão | Mantém modo de interação, checkpoint, posições dos anéis e conclusão. A conclusão determina o compartimento e a terceira porta. A leitura do registro é um estado narrativo próprio. |
| Salvamento | Checkpoint local em user://, com versão de schema. Validar antes de carregar e substituir o arquivo por gravação temporária após salvar. Preservar o último válido em caso de falha. Retomar na exploração, com rascunho e conclusão restaurados. |
| Apresentação | Cenas e parâmetros visuais reutilizáveis. AnimationPlayer e áudio recebem eventos da sessão para sincronizar abertura, trinco e luz. |

Estrutura proposta após validação deste plano

```text
docs/                 plano e decisões da fatia
pesquisa/             notas documentais de referência
game/                 raiz Godot e preset de exportação
  rooms/              corredor e patamar
  actors/             protagonista e animações
  puzzles/            relógio em close-up
  session/            progressão, revelações e checkpoint
  presentation/       desenho procedural e áudio
```

## Entregas e critérios

1. **Percurso.** Cenas com formas simples, três portas, câmera e interação. Validar colisão nos extremos, indicação de foco e retorno do close-up sem deslocamento da protagonista.
2. **Puzzle e retomada.** Testar solução incorreta, saída com rascunho, solução correta, leitura, porta aberta e retorno após reiniciar o jogo. Validar também carregamento com slot ausente ou inválido e ausência de nova abertura ao revisitar um relógio resolvido.
3. **Apresentação e exportação.** Aplicar uma passagem de arte e som, rodar em Godot e validar o export na plataforma escolhida. Depois de confirmar o repositório GitHub de `igonozoid` e a página itch.io de `igonoz`, usar o fluxo de IronVeil como referência para GitHub Actions com Butler, publicação por tag `v*` e credenciais em secrets. Restringir o pacote ao export de `game/`.

O diretório local foi confirmado em 22/11/2026. O Git ainda não reconhece um repositório no workspace. O IronVeil foi consultado em leitura. Este plano propõe a fatia, sem assumir que nomes, visual definitivo ou serviços de publicação estejam aprovados.

## Referências de implementação

- Consultar os tópicos de movimento 2D, física, sinais e foco de controles ao implementar o corredor e o relógio. Conferir os exemplos na documentação da versão de Godot adotada. Para uma lacuna concreta, usar o catálogo de Godot para localizar ferramentas e consultar a fonte de cada candidata. [Awesome Gamedev Agent Skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) · [Awesome Godot](https://github.com/Calinou/awesome-godot)
- Consultar o guia de game design para materiais de documentação e prototipagem. No playtest da fatia, observar se a pessoa encontra a pista, relaciona as marcas aos anéis e percebe a mudança na terceira porta. [Guia do Game Designer](https://github.com/baptixta/guia-do-game-designer)
- Consultar Diorama para organização de parâmetros, pivôs e poses. Diorama exporta spritesheets 2.5D, e SpriteKiln produz sprites pixel art a partir de modelos 3D. A arte da fatia é desenhada e animada em Godot. [Diorama](https://github.com/leduardo99/diorama) · [SpriteKiln](https://github.com/LucasJRamos/spritekiln)
- VibeDev serve como referência de revisão por etapa. OhMyGame reúne produção assistida e publicação em outro ambiente, enquanto o fluxo previsto para esta fatia usa Codex, Godot, GitHub e itch.io. Ambos ficam como referências opcionais. [VibeDev](https://github.com/4pixeltechBR/VibeDev) · [OhMyGame](https://github.com/WhiteTowerAI/ohmygame)
