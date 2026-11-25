# HOLLOWVEIL — A Casa Morvant

**Gênero:** aventura de horror com enigmas, em primeira pessoa, com cenas fantasmas encenadas em vista lateral.
**Motor:** Godot 4.7, GDScript, renderizador Compatibility, sem nenhuma imagem ou som externo.
**Assinatura visual:** a do IronVeil, ou seja, 640×360 ampliado em pixel nítido, luz 2D dinâmica, pós-processamento por ato e tudo desenhado por código.
**Duração-alvo:** de 6 a 8 horas na primeira volta, com mais 3 a 4 horas na "Noite Mais Escura" (NG+).

---

## 1. Premissa

Outono de 1911. O **Vale Oco** passa o ano coberto por uma névoa que os moradores chamam de *véu*. No alto do vale fica a **Casa Morvant**, onde morava o **Dr. Ezequiel Morvant**, anatomista, hipnotizador e colecionador de "peças".

Na noite de 31 de outubro, Morvant ofereceu um último jantar à família e a seis convidados. Ninguém saiu da casa. A polícia encontrou a mesa posta, a sopa fria e nenhum corpo.

Treze anos depois, um advogado contrata **Dália Ferraz**, uma médium falsa que vive de sessões de mesa girante, para "acalmar a casa" antes de um leilão. Ela atravessa a porta e o véu se fecha às suas costas.

Morvant, que só aparece como voz, retrato, reflexo e silhueta, a recebe encantado: *"Uma médium. Enfim, alguém que escuta."*

## 2. O que está em jogo

Cada um dos oito mortos ficou preso a um **relicário**, um cômodo amarrado por um enigma. Cada enigma resolvido liberta uma alma, e a alma **encena a própria morte** diante de Dália.

Aos poucos, as cenas mostram o plano de Morvant. Ele tirou de cada pessoa uma parte (a voz da esposa, os olhos da filha, as mãos do pianista, a fé do padre, os dentes de ouro da credora) para costurar um corpo capaz de atravessar o véu. Falta a última peça: **alguém que de fato ouça os mortos**. Dália, a médium falsa, está deixando de ser falsa.

### Os oito mortos

| Alma | Quem era | O que Morvant tirou | Cômodo |
|---|---|---|---|
| Leocádia Brás | Viúva rica e credora de Morvant | Os dentes de ouro | Sala de jantar |
| Tobias Ruela | Pianista convidado | As mãos | Biblioteca |
| Benedita Assunção | Cozinheira da casa | Os olhos (ela viu demais) | Cozinha |
| Celeste Morvant | Esposa, soprano | A voz | Sala de música |
| Padre Anselmo Vidal | Confessor da família | O coração | Capela |
| Capitão Hélio Sarmento | Militar e jogador | A pele tatuada | Sala de jogos |
| Ofélia Morvant | Filha de 19 anos, médium de verdade | O "dom" | Quarto de Ofélia |
| Dr. Ezequiel Morvant | O anfitrião | — | O Teatro Anatômico |

## 3. Estrutura

| Ato | Zona | Cômodos | Enigmas | Cenas fantasmas |
|---|---|---|---|---|
| **I — O Térreo** | Térreo | Saguão, Sala de jantar, Biblioteca, Cozinha, Sala de música, Estufa | 6 | 4 |
| **II — Os Quartos** | 1º andar | Corredor, quartos de Celeste, Ofélia e dos hóspedes, Banheiro, Berçário vazio | 7 | 3 |
| **III — Os Porões** | Subsolo | Adega, Câmara fria, Capela, Cripta, Labirinto das fundações | 6 | 3 |
| **IV — O Véu** | Sótão e torre | Sótão, Teatro Anatômico, Torre do relógio | 5 | 2 + finais |

O **Saguão** é o centro de tudo: a escadaria, o retrato de Morvant (cujos olhos seguem o cursor) e a **Prancheta**, um tabuleiro de mesa girante que dá pistas.

## 4. Laços que prendem o jogador

1. **Enigmas com semente.** Cada volta gera enigmas novos: plano de mesa, embaralhamento, posições iniciais e cifras. A semente fica no save. Assim a NG+ não vira um teste de memória.
2. **Sanidade.** Uma vela no canto da tela mostra a sanidade de Dália.
   - **O que baixa:** pistas, sustos, erros nos enigmas e ficar tempo demais no escuro.
   - **O que recupera:** libertar almas e acender velas.
   - **Sanidade baixa traz:** alucinações (o cômodo distorce, vultos aparecem no canto do olho, sangue escorre das paredes e o retrato muda) e falas extras de Morvant.
   - **Efeito no final:** altera qual final o jogador recebe.
3. **Pistas com preço.** A primeira pista sai barata. A segunda custa mais e mostra a resposta parcial. Na terceira, Morvant resolve o enigma por você: a alma é libertada, mas a cena mostra **a versão dele** e você perde aquela lembrança, que conta para o final.
4. **Relíquias e diário.** São 40 itens escondidos em pontos de vista secundários: páginas do diário de Morvant, fotografias e peças anatômicas. Colecionar todos abre a "Noite Mais Escura".
5. **Revisitas que mudam.** Os cômodos mudam a cada alma libertada: sangue novo, objetos fora do lugar, uma porta que antes não existia. Sustos são agendados por progresso e sanidade, nunca por tempo fixo.
6. **Três finais e um secreto.**
   - *A Médium:* liberta todos, sem usar a terceira pista.
   - *A Peça Final:* Dália é costurada ao corpo.
   - *O Anfitrião:* Dália assume a casa.
   - *Secreto:* exige todas as relíquias.

## 5. Navegação (o modelo híbrido)

- **Primeira pessoa por pontos de vista.** Cada cômodo tem de 1 a 4 vistas fixas, desenhadas em perspectiva de um ponto por código. Passar de uma vista para outra é um **avanço de câmera**: a imagem cresce em direção ao ponto clicado, escurece e a próxima vista assenta. Os passos tocam no ritmo do movimento.
- **Cursor que conta o que vai acontecer.** Tudo é desenhado por código:
  - **Chama:** neutro, nada ali.
  - **Seta de passos:** ir para outra vista.
  - **Olho:** examinar.
  - **Coração batendo:** enigma.
  - **Boca:** voz ou evento.
  - **Cadeado:** passagem fechada.
- **Cenas fantasmas em vista lateral.**
  - A vista escurece, a névoa fecha as bordas e os mortos aparecem como figuras pálidas, ciano-esverdeadas e translúcidas.
  - O sangue é a única coisa sólida e em cor plena: vermelho vivo que espirra, escorre e fica no chão da cena.
  - Gore pode ser desligado no menu.

## 6. Enigmas do Ato I (fatia vertical em negrito)

| Cômodo | Enigma | Mecânica | Semente gera |
|---|---|---|---|
| **Sala de jantar** | **A Ceia** | Plano de mesa por lógica: 7 convidados, 7 cadeiras e pistas escritas por Celeste | Disposição e conjunto mínimo de pistas com solução única |
| **Biblioteca** | **O Atlas** | Quebra-cabeça deslizante 4×4 com o rosto meio esfolado de Morvant | Embaralhamento sempre solucionável |
| **Cozinha** | **Olhos no Pote** | Resta-um triangular com 15 olhos em conserva: pular um olho o estoura | Buraco inicial, sempre com solução verificada por um solucionador |
| Sala de música | A Partitura | Repetir uma frase do canto de Celeste em teclas desafinadas | Melodia |
| Estufa | As Veias | Variação de "apague as luzes" com raízes que pulsam | Estado inicial |
| Saguão | A Prancheta | Cifra de letras com o alfabeto da mesa girante | Mensagem e chave |

Atos seguintes (rascunho): pesos e órgãos em balança, labirinto em primeira pessoa nas fundações, peças de xadrez com bisturis, caixas de música com engrenagens, transvaso de sangue entre frascos, ganchos de carne num quebra-cabeça de empurrar caixas na câmara fria e a montagem final do corpo no Teatro Anatômico.

## 7. Arte

- **Resolução:** 640×360 ampliado sem suavização. As cores são chapadas, com sombreamento em faixas, porque os planos são divididos em fatias que escurecem com a distância.
- **Perspectiva:** os cômodos são caixas 3D projetadas por código. Piso de tábuas ou ladrilho, papel de parede adamascado, lambri, vigas, portas, janelas com luar, estantes, retratos e lustres.
- **Luz:** `CanvasModulate` escuro mais `PointLight2D` em cada vela, janela e lareira, com tremulação. Os relâmpagos da trilha de ambiente acendem as janelas.
- **Pós-processamento:** brilho, gradação de sombras e realces por ato, contraste, vinheta e grão. Há também um **Modo VGA** opcional, com pontilhado ordenado e paleta reduzida, e a **distorção da sanidade** (ondulação e aberração cromática).
- **Paleta por ato:**

| Ato | Sombras | Luz | Acento |
|---|---|---|---|
| I — Térreo | Verde-musgo | Vela âmbar | Vinho |
| II — Quartos | Roxo | Lilás | Rosa podre |
| III — Porões | Azul-negro | Lanterna | Vermelho |
| IV — O Véu | Quase preto | Branco frio | Sangue |

- **Interface:** painéis marrom-escuros com borda de latão, como no IronVeil, e a vela da sanidade. As legendas usam o nome de quem fala em latão.

## 8. Som e música (todos sintetizados)

- **Trilhas:** cada faixa é gerada em thread na primeira vez.
  - **Menu:** caixa de música desafinada e órgão.
  - **Térreo:** cravo lento em menor harmônica, violoncelo e tique de relógio.
  - **Enigma:** pulsação esparsa, vidro e grave.
  - **Cena fantasma:** cluster dissonante de cordas e coração.
- **Ambiente:** vento, rangidos aleatórios da casa, trovão distante sincronizado com o relâmpago nas janelas e relógio.
- **Efeitos:** passos em madeira, porta rangendo, porta trancada, batida, esmagamento molhado, respingo, coração, sussurros com formantes, susto, serra de osso, tosse e grito.
- **A risada de Morvant:** pulsos de formante "ha" que descem de tom.

## 9. Fatia vertical (primeira entrega)

1. **Abertura:** menu com a mansão na névoa, chuva e relâmpago. Novo jogo abre uma introdução em cartas: a carta do advogado e a porta que bate atrás de Dália.
2. **Saguão:**
   - A voz de Morvant dá as boas-vindas. A porta de entrada está acorrentada.
   - A sala de jantar está aberta, a biblioteca trancada e o corredor da cozinha bloqueado.
   - A Prancheta dá pistas.
3. **Sala de jantar:** o enigma A Ceia, e depois a cena da morte de Leocádia. Ela tosse sangue na sopa, cai sobre a mesa e Morvant arranca os dentes de ouro. Dália ganha a **chave de osso** e a biblioteca abre.
4. **Biblioteca:** o enigma O Atlas, e depois a cena de Tobias, cujas mãos são serradas sobre o piano de estudo. A cena revela a passagem da cozinha.
5. **Cozinha:** o enigma Olhos no Pote, e depois a cena de Benedita na despensa. A escada de serviço para o 1º andar se abre e a fatia termina.
6. **Sistemas:**
   - sanidade;
   - pistas da Prancheta;
   - salvamento automático;
   - opções de gore, efeitos, Modo VGA e volumes;
   - revisitas com sustos, como o retrato que sangra e o vulto na escada.

## 10. Organização do projeto

```text
game/
  project.godot           640×360, Compatibility, autoloads State e Audio
  main.tscn               raiz: troca entre menu, introdução e casa
  scripts/
    core/                 estado, salvamento, fluxo principal
    audio/                síntese de música e efeitos, ambiente
    gfx/                  perspectiva, luzes, pós-processamento, sangue
    ui/                   tema, cursor, legendas, menu, HUD
    house/                motor de vistas e as vistas de cada cômodo
    puzzles/              um script por enigma
    ghosts/               motor de cenas fantasmas e roteiros
arquivo/game_codex/       o protótipo anterior, preservado
```
