# HOLLOWVEIL — A Casa Morvant

**Gênero:** aventura de horror com enigmas, em primeira pessoa, com cenas fantasmas encenadas em vista lateral.
**Motor:** Godot 4.7, GDScript, renderizador Compatibility, sem nenhuma imagem ou som externo.
**Assinatura visual:** a do IronVeil, ou seja, 640×360 ampliado em pixel nítido, luz 2D dinâmica, pós-processamento por andar e tudo desenhado por código.
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
| Capitão Hélio Sarmento | Militar e jogador | A pele tatuada | Quarto de hóspedes |
| Ofélia Morvant | Filha de 19 anos, médium de verdade | O "dom" | Quarto de Ofélia |
| Dr. Ezequiel Morvant | O anfitrião | — | O Teatro Anatômico |

## 3. Estrutura: uma casa contínua

Não há atos, capítulos nem telas de carregamento. O jogo é uma só casa, que se abre aos poucos e muda enquanto o jogador anda por ela. O que marca o avanço é a própria casa: portas que destrancam, cômodos que mudam depois de cada alma libertada e a voz de Morvant comentando.

- **Liberdade dentro do que está aberto.** Em cada andar liberado, os cômodos podem ser resolvidos em qualquer ordem, como no The 7th Guest. Uma porta só exige um enigma anterior quando a história pede (a chave de osso abre a biblioteca, por exemplo).
- **Andares abrem por almas libertadas**, não por fases concluídas:

| Andar | Cômodos | Enigmas | Cenas fantasmas | Abre quando |
|---|---|---|---|---|
| Térreo | Saguão, Sala de jantar, Biblioteca, Cozinha, Sala de música, Estufa | 6 | 4 | Desde o início |
| 1º andar | Corredor, quartos de Celeste, Ofélia e dos hóspedes, Banheiro, Berçário vazio | 7 | 3 | 3 almas (a escada de serviço) |
| Porões | Galeria, Adega, Câmara fria, Capela, Cripta, Labirinto das fundações | 5 | 3 | 6 almas (o alçapão da cozinha) |
| Sótão e torre | Sótão, Teatro Anatômico, Torre do relógio | 5 | 2 + finais | 7 almas e a saída do labirinto (a escadaria principal destrava) |

- **Voltar sempre vale a pena.** Andares já abertos continuam acessíveis e mudam com o progresso: sangue novo, objetos fora do lugar, sustos novos e relíquias que só aparecem depois.
- **Cada andar tem clima próprio** (paleta, trilha e gradação de cor), que muda com uma transição suave na escada, sem corte.

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

## 6. Enigmas do térreo (os da fatia vertical em negrito)

| Cômodo | Enigma | Mecânica | Semente gera |
|---|---|---|---|
| **Sala de jantar** | **A Ceia** | Plano de mesa por lógica: 7 convidados, 7 cadeiras e pistas escritas por Celeste | Disposição e conjunto mínimo de pistas com solução única |
| **Biblioteca** | **O Atlas** | Quebra-cabeça deslizante 4×4 com o rosto meio esfolado de Morvant | Embaralhamento sempre solucionável |
| **Cozinha** | **Olhos no Pote** | Resta-um triangular com 15 olhos em conserva: pular um olho o estoura | Buraco inicial, sempre com solução verificada por um solucionador |
| **Sala de música** | **A Partitura** | Repetir o canto de Celeste em teclas desafinadas, em 4 rodadas que crescem | Melodia (sem nota repetida em seguida) |
| **Estufa** | **As Veias** | "Apague as luzes" 5×5: tocar um bulbo inverte ele e os vizinhos | Estado inicial, sempre solucionável (solucionador em GF(2)) |
| **Saguão** | **A Prancheta** | Cifra com dois deslocamentos alternados, decifrada girando os anéis do Sol e da Lua | Mensagem e as duas chaves |

Sótão (rascunho): a montagem final do corpo no Teatro Anatômico.

Ligações do térreo:
- **Caminho 1:** a Ceia dá a chave de osso, que abre a biblioteca. O Atlas destranca a copa. Olhos no Pote libera a escada de serviço.
- **Caminho 2:** a estufa devolve a lente da Prancheta. A cifra da Prancheta destranca a sala de música, onde fica a Partitura.

Os dois caminhos podem ser jogados em paralelo, em qualquer ordem.

## 6b. O 1º andar

Chega-se pela escada de serviço da cozinha. O andar inteiro é um **corredor longo** com quatro portas laterais e, no fim, a porta de Ofélia, por baixo da qual escapa uma luz que tremula. Paleta roxa e lilás; a trilha é uma canção de ninar desafinada.

| Cômodo | Enigma | Mecânica | Semente gera | Abre / revela |
|---|---|---|---|---|
| **Quarto de Celeste** | **A Caixa de Música** | Cinco engrenagens em corrente: girar uma gira as vizinhas no sentido contrário; alinhar todas as marcas | Posição inicial (embaralhada a partir do alinhado) | A canção de ninar que destranca o berçário |
| **Banheiro** | **O Banho** | Transvasar sangue entre três frascos até medir a quantidade exata que o ralo aceita | Capacidades e alvo (sempre com solução, verificada por busca) | A banheira esvazia: chave do quarto de hóspedes |
| **Quarto de hóspedes** | **A Pele** | A pele tatuada de Hélio, costurada em 25 retalhos: girar cada retalho até a tatuagem virar um desenho contínuo | Árvore de linhas e rotações iniciais | Alma de Hélio (cena de morte) |
| **Berçário vazio** | **O Móbile** | Pendurar 4 de 5 brinquedos para equilibrar três barras (peso × marcas igual dos dois lados) | Pesos e braços, com uma única solução | Cena de memória (sem morte): o filho que nasceu morto e o motivo de Morvant |
| **Quarto de Ofélia** | **Os Sussurros** | Quatro mortos dizem onde está o diário; um mente. Só um esconderijo deixa uma única frase falsa | Falas e mentiroso, com resposta única | Alma de Ofélia; o alçapão da cozinha abre para os porões |

- **Ordem livre:** o quarto de Celeste e o banheiro estão abertos desde a chegada. O banheiro abre o quarto de hóspedes; a caixa de música abre o berçário; o berçário revela o que abre a porta de Ofélia.
- **Pronto:** o andar inteiro. A porta de Ofélia só abre quando Dália diz o nome do filho morto, Benjamim, revelado na memória do berçário.

## 6c. Os porões

Chega-se pelo alçapão da cozinha, aberto por Ofélia. Uma **galeria de pedra em abóbada** leva à adega (esquerda), à câmara fria (direita) e, no fundo, ao portão de ferro da capela, atrás do qual o padre Anselmo reza ajoelhado. Paleta azul-negra e a luz quente de uma **lamparina que segue o cursor**; a trilha é um cantochão solitário sobre um bordão grave, com gotas pingando no escuro.

| Cômodo | Enigma | Mecânica | Semente gera | Abre / revela |
|---|---|---|---|---|
| **Adega** | **A Balança** | Nove potes de órgãos, um mais pesado (o coração). Duas pesagens numa balança de pratos | Desempate de Morvant, que escolhe o pote pesado depois de cada pesagem, sempre o pior para o jogador | Cena de memória: o láudano no vinho do jantar. Dália leva o coração de Anselmo |
| **Câmara fria** | **Os Ganchos** | Empurrar três corpos pendurados em trolleys até os ralos; só empurrar, nunca puxar | Sala e posição inicial. Uma busca de trás para a frente, a partir dos ralos, escolhe a posição que pede mais empurrões (até 24) | A chave da capela, presa no gelo |
| **Capela** | **O Vitral** | Rosácea 6×6 em seis painéis de 2×3: cada cor uma vez por linha, coluna e painel | Vitral embaralhado e vidros retirados enquanto a solução continua única | Alma de Anselmo (cena de morte); a passagem para a cripta |
| **Cripta** | **O Ossuário** | Nonograma 10×10 na parede de nichos: os números entalhados contam os crânios seguidos em cada linha e coluna | Uma de seis figuras (crânio, chave, caixão, olho, mão, coração), talvez espelhada; todas se resolvem só por linha e coluna | Cena de memória: o enterro de Benjamim e a noite em que Morvant o tira do caixão. Os nichos cedem e abrem as fundações |
| **Fundações** | **O Labirinto** | Labirinto 9×9 em primeira pessoa, passo a passo e viradas de 90°, como nos jogos de masmorra antigos; mapa de giz do que já foi pisado | Labirinto com alguns atalhos; a saída fica na casa mais distante da entrada | Depois de 12 passos, uma coisa pálida rasteja atrás de Dália, uma casa a cada dois passos dela. Se alcança: sanidade e volta à entrada. A saída sobe por um poço até debaixo da escadaria do saguão, que leva ao sótão |

- **Ordem livre:** a adega e a câmara fria abrem desde a chegada. A capela precisa da chave (Ganchos); a rosácea só acende quando o coração (Balança) volta ao relicário do altar.
- **A Balança não aceita chute:** Morvant decide qual pote é o pesado só depois de cada pesagem, dentro do que a balança já mostrou. Só a estratégia dos três grupos de três garante o coração. A pista 2 dá uma terceira pesagem.
- **A coisa do labirinto** nunca encurrala Dália: começa na entrada, atrás dela, e é mais lenta. Os atalhos deixam rotas de fuga. A pista 2 risca setas de giz no caminho mais curto e marca a saída no mapa.
- **Pronto:** os porões inteiros. A demonstração termina ao subir a escadaria principal para o sótão.

## 6d. O sótão e a torre

Chega-se pela escadaria principal do saguão, que destrava quando Dália sai do labirinto. O **sótão** é o vão do telhado em duas águas: caibros, manequins sob lençóis (um deles vira a cabeça), um cavalinho de balanço com o nome de Benjamim e o baú de Morvant. No fundo, a porta dupla do **Teatro Anatômico**, com um olho de vidro em cima e um choro de bebê atrás. À direita, a escada da **torre do relógio**: mostrador de vidro visto por trás, parado em 23h47, engrenagens enormes e um pêndulo de lâmina. Paleta quase preta e branco frio de luar; a trilha é a canção de ninar de Celeste numa caixa de música que está parando, sobre um bordão e o tique do relógio.

| Cômodo | Enigma | Mecânica | Semente gera | Abre / revela |
|---|---|---|---|---|
| **Sótão** | **O Baú** | Cadeado de 4 discos com 6 símbolos, sem repetir. A cada tentativa os mortos respondem de dentro do baú: uma batida por símbolo no lugar certo, um arranhão por símbolo fora do lugar. 8 tentativas, depois Morvant troca a combinação | As combinações | Cena de memória: a costura do corpo de Benjamim com as peças dos mortos. A chave do teatro |
| **Torre do relógio** | **O Luar** | Levar o raio da lua pelo mecanismo até o olho de vidro, pondo um número contado de espelhos nos vãos entre engrenagens; alguns espelhos presos atrapalham | Um caminho que funciona, engrenagens em volta, espelhos presos de distração | O olho da porta do teatro acende |
| Teatro Anatômico | — | (próxima leva) | — | Morvant, a montagem final e os finais |

- **Ordem livre:** baú e torre abrem desde a chegada. A porta do teatro precisa da chave e do luar.
- **Pronto:** sótão e torre, com O Baú, O Luar e a memória da costura. A demonstração termina ao abrir a porta do teatro.
- **Próxima leva:** o Teatro Anatômico (a plateia de mortos, a montagem final do corpo, o confronto com Morvant) e os três finais mais o secreto.

## 7. Arte

- **Resolução:** 640×360 ampliado sem suavização. As cores são chapadas, com sombreamento em faixas, porque os planos são divididos em fatias que escurecem com a distância.
- **Perspectiva:** os cômodos são caixas 3D projetadas por código. Piso de tábuas ou ladrilho, papel de parede adamascado, lambri, vigas, portas, janelas com luar, estantes, retratos e lustres.
- **Luz:** `CanvasModulate` escuro mais `PointLight2D` em cada vela, janela e lareira, com tremulação. Os relâmpagos da trilha de ambiente acendem as janelas.
- **Pós-processamento:** brilho, gradação de sombras e realces por andar, contraste, vinheta e grão. Há também um **Modo VGA** opcional, com pontilhado ordenado e paleta reduzida, e a **distorção da sanidade** (ondulação e aberração cromática).
- **Paleta por andar:**

| Andar | Sombras | Luz | Acento |
|---|---|---|---|
| Térreo | Verde-musgo | Vela âmbar | Vinho |
| 1º andar | Roxo | Lilás | Rosa podre |
| Porões | Azul-negro | Lanterna | Vermelho |
| Sótão e torre | Quase preto | Branco frio | Sangue |

- **Interface:** painéis marrom-escuros com borda de latão, como no IronVeil, e a vela da sanidade. As legendas usam o nome de quem fala em latão.

## 8. Som e música (todos sintetizados)

- **Trilhas:** cada faixa é gerada em thread na primeira vez.
  - **Menu:** caixa de música desafinada e órgão.
  - **Térreo:** cravo lento em menor harmônica, violoncelo e tique de relógio.
  - **Enigma:** pulsação esparsa, vidro e grave.
  - **Cena fantasma:** cluster dissonante de cordas e coração.
  - **Porões:** cantochão de uma voz só sobre um bordão grave, com gotas d'água.
  - **Sótão:** a canção de ninar de Celeste, lenta e desafinada, numa caixa de música que está parando, com o tique do relógio.
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
