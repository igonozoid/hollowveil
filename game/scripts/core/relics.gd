extends RefCounted
## As 40 relíquias escondidas na casa: 14 páginas do diário de Morvant (em
## ordem, de I a XIV), 15 fotografias e 11 peças. Cada uma fica num ponto da
## tela de uma vista; algumas só aparecem depois de um enigma ("gate").
## [id, vista, tipo, posição na tela, enigma que a revela, título, texto]

const LIST := [
	# Saguão
	["foto_casamento", "foyer", "foto", Vector2(150, 300), "", "Fotografia: o casamento", "Ezequiel e Celeste, 1898. Ele não olha para a câmera. Olha para o pescoço dela."],
	["diario_1", "foyer", "diario", Vector2(235, 235), "ceia", "Diário de Morvant, página I", "Março de 1898. Celeste aceitou. Comprei esta casa no alto do vale porque a névoa não deixa ninguém ver o que se faz aqui dentro."],
	["peca_dente_leite", "foyer_door", "peca", Vector2(150, 270), "", "Peça: um dente de leite", "Num envelope com o nome de Ofélia. Dentro, também, um dente que não é de criança."],
	["diario_2", "foyer_door", "diario", Vector2(470, 185), "", "Diário de Morvant, página II", "1899. Ofélia nasceu de olhos abertos. A parteira disse que ela olhou para o canto vazio do quarto e sorriu."],
	# Sala de jantar
	["foto_jantar", "dining", "foto", Vector2(90, 142), "", "Fotografia: o último jantar", "A mesa posta para nove, na tarde de 31 de outubro. No reflexo da sopeira, alguém já está deitado."],
	["peca_dente_ouro", "dining", "peca", Vector2(430, 290), "ceia", "Peça: dente de ouro", "Um dos dentes de Leocádia, que rolou para baixo da mesa. Ainda tem um pedaço de gengiva."],
	# Biblioteca
	["diario_3", "library", "diario", Vector2(80, 290), "", "Diário de Morvant, página III", "1903. Ofélia conversa com a avó morta. Sabe coisas que ninguém lhe contou. Comecei a anotar. Um dom é um órgão como outro qualquer."],
	["foto_tobias", "library", "foto", Vector2(244, 208), "", "Fotografia: Tobias ao piano", "Tobias Ruela no Teatro São Pedro, 1908. As mãos saíram borradas, de tão rápidas."],
	# Cozinha
	["peca_olho_vidro", "kitchen", "peca", Vector2(220, 260), "", "Peça: olho de vidro", "Um olho de vidro azul entre os ladrilhos. Benedita tinha olhos castanhos. Morvant encomendou um par para o menino."],
	["diario_4", "kitchen", "diario", Vector2(400, 214), "olhos", "Diário de Morvant, página IV", "1906. Leocádia me emprestou onze contos. Disse que cobraria com juros. Cobrará com os dentes."],
	# Estufa
	["foto_ofelia_crianca", "greenhouse", "foto", Vector2(90, 205), "", "Fotografia: Ofélia criança", "Ofélia aos seis anos, entre as roseiras. Atrás dela, fora de foco, uma senhora que ninguém soube dizer quem era."],
	["peca_dedo", "greenhouse", "peca", Vector2(560, 210), "", "Peça: dedo enxertado", "Um dedo humano enxertado numa muda de roseira. Criou raízes."],
	# Sala de música
	["diario_5", "music", "diario", Vector2(420, 185), "", "Diário de Morvant, página V", "1909. Celeste está grávida outra vez. Ofélia diz que o menino \"não quer vir\". Proibi que ela repita isso."],
	["foto_celeste", "music", "foto", Vector2(100, 260), "", "Fotografia: Celeste no palco", "Celeste Morvant como Lucia, 1897. Dedicatória: \"Para Ezequiel, que só me ouve quando eu canto.\""],
	# Corredor
	["foto_empregados", "corridor", "foto", Vector2(330, 300), "", "Fotografia: os empregados", "Benedita e o jardineiro na escada de serviço. O rosto do jardineiro foi raspado com faca."],
	["diario_6", "corridor", "diario", Vector2(425, 150), "sussurros", "Diário de Morvant, página VI", "Julho de 1910. Benjamim. Nasceu às 23h47 e não respirou. Celeste ainda não soltou o lençol."],
	# Quarto de Celeste
	["peca_corda_vocal", "celeste_room", "peca", Vector2(470, 235), "", "Peça: corda vocal", "Num frasco de perfume vazio, uma membrana fina, cor-de-rosa. O rótulo diz \"Lá agudo\"."],
	["diario_7", "celeste_room", "diario", Vector2(180, 260), "", "Diário de Morvant, página VII", "Agosto de 1910. Ofélia diz que ouve Benjamim chorando atrás das paredes. Então ele está em algum lugar. Então há um caminho."],
	# Banheiro
	["foto_capitao", "bathroom", "foto", Vector2(220, 290), "", "Fotografia: o capitão", "Capitão Hélio Sarmento, sem camisa, mostrando a âncora tatuada. No verso: \"Paga-se com a pele.\""],
	["peca_unha", "bathroom", "peca", Vector2(450, 300), "", "Peça: unha", "Uma unha inteira presa no ralo da banheira, com esmalte vermelho."],
	# Quarto de hóspedes
	["foto_credora", "guest_room", "foto", Vector2(120, 240), "", "Fotografia: a credora", "Leocádia Brás sorri com todos os dentes de ouro. Alguém circulou os dentes a lápis."],
	["diario_8", "guest_room", "diario", Vector2(520, 235), "", "Diário de Morvant, página VIII", "Outubro de 1910. Para atravessar o véu, um corpo que sirva de porta. Peças: voz, olhos, mãos, pele, coração, dom. E alguém que escute."],
	# Berçário
	["foto_post_mortem", "nursery", "foto", Vector2(520, 250), "", "Fotografia post mortem", "Benjamim, 1910, vestido de batizado nos braços de Celeste. Os olhos foram pintados abertos sobre as pálpebras."],
	["peca_cordao", "nursery", "peca", Vector2(250, 300), "movel", "Peça: cordão umbilical", "Seco e enrolado numa fita azul, dentro de um saquinho de seda. \"B., 1910.\""],
	# Quarto de Ofélia
	["diario_9", "ofelia_room", "diario", Vector2(130, 215), "", "Diário de Morvant, página IX", "Março de 1911. Testei o láudano na cozinheira. Dormiu dezesseis horas e não lembrou de nada. Ótimo."],
	["foto_teste", "ofelia_room", "foto", Vector2(455, 125), "", "Fotografia: Ofélia e o pai", "Ofélia aos dezoito, de olhos vendados. Morvant segura a mão dela. Anotação: \"Teste VII. Acertou as sete cartas.\""],
	# Galeria dos porões
	["peca_rotula", "cellar", "peca", Vector2(95, 300), "", "Peça: rótula", "Um osso de joelho usado como calço de porta."],
	["diario_10", "cellar", "diario", Vector2(500, 300), "", "Diário de Morvant, página X", "Setembro de 1911. Os convites saíram. Todos aceitaram. Ninguém recusa um jantar em casa de médico."],
	# Adega
	["foto_padre", "wine_cellar", "foto", Vector2(520, 300), "", "Fotografia: o padre", "Padre Anselmo benzendo a adega nova, 1900. Morvant está atrás dele, com a mão erguida. Não para benzer."],
	["diario_11", "wine_cellar", "diario", Vector2(300, 130), "", "Diário de Morvant, página XI", "31 de outubro de 1911, à tarde. O padre desconfia. Vou mostrar a ele a adega."],
	# Câmara fria
	["peca_etiqueta", "cold_room", "peca", Vector2(40, 300), "", "Peça: etiqueta de gancho", "Uma plaquinha de metal: \"Nº 4. Ruela, T. Mãos à parte.\""],
	["foto_ganchos", "cold_room", "foto", Vector2(560, 195), "ganchos", "Fotografia: a câmara fria", "Os ganchos vazios, recém-instalados. Na legenda, a letra de Morvant: \"Capacidade: nove.\""],
	# Capela
	["diario_12", "chapel", "diario", Vector2(160, 245), "", "Diário de Morvant, página XII", "1º de novembro de 1911. Sete peças, todas frescas. O corpo mexeu a mão às quatro da manhã."],
	["foto_vitral", "chapel", "foto", Vector2(470, 245), "vitral", "Fotografia: o vitral", "A rosácea vista de dentro, ao entardecer. Seis cores e, no centro, um rosto pequeno que não está no vitral de verdade."],
	# Cripta
	["peca_cabelo", "crypt", "peca", Vector2(100, 250), "", "Peça: mecha de cabelo", "Uma mecha loira num medalhão. A tampa do sarcófago de Celeste está mal fechada."],
	["diario_13", "crypt", "diario", Vector2(530, 250), "", "Diário de Morvant, página XIII", "Inverno de 1911. Não é ele. O que olha pelos olhos dele não é ele. Falta quem escute de verdade. Ofélia não serve mais."],
	# Sótão
	["foto_familia", "attic", "foto", Vector2(330, 250), "", "Fotografia: a família", "Os Morvant em 1910: o pai, a mãe, a filha e um berço coberto. Ofélia olha para o berço."],
	["peca_coracao_cera", "attic", "peca", Vector2(560, 280), "", "Peça: coração de cera", "Um modelo anatômico de coração, de cera, com as câmaras abertas. Alguém escreveu nele, com a unha: \"Anselmo\"."],
	# Torre
	["diario_14", "clock_tower", "diario", Vector2(150, 290), "", "Diário de Morvant, página XIV", "1924. Uma médium vem amanhã. Falsa, dizem. Ótimo: as falsas escutam melhor, porque têm medo."],
	# Teatro
	["foto_estreia", "theater", "foto", Vector2(200, 250), "", "Fotografia: a estreia", "O Teatro Anatômico cheio de alunos, 1905. Na mesa, um corpo. Na primeira fila, Ofélia com seis anos, tapando os ouvidos."],
]


static func by_id(id: String) -> Array:
	for r in LIST:
		if r[0] == id:
			return r
	return []


static func for_view(view_id: String) -> Array:
	var out: Array = []
	for r in LIST:
		if r[1] == view_id:
			out.append(r)
	return out


## Desenha o ícone de uma relíquia (usado nas vistas e no relicário).
static func draw_icon(ci: CanvasItem, c: Vector2, kind: String, s: float, a: float = 1.0) -> void:
	match kind:
		"diario":
			ci.draw_rect(Rect2(c - Vector2(3, 4) * s, Vector2(6, 8) * s), Color(0.78, 0.72, 0.6, a))
			for k in 3:
				ci.draw_line(c + Vector2(-2, -2 + k * 2) * s, c + Vector2(2, -2 + k * 2) * s, Color(0.3, 0.22, 0.15, a), 1.0)
		"foto":
			ci.draw_rect(Rect2(c - Vector2(4, 3) * s, Vector2(8, 6) * s), Color(0.9, 0.88, 0.82, a))
			ci.draw_rect(Rect2(c - Vector2(3, 2) * s, Vector2(6, 4) * s), Color(0.45, 0.35, 0.25, a))
		_:
			ci.draw_rect(Rect2(c - Vector2(2.5, 4) * s, Vector2(5, 7) * s), Color(0.5, 0.58, 0.46, a * 0.9))
			ci.draw_circle(c + Vector2(0, 0.5) * s, 1.6 * s, Color(0.6, 0.1, 0.12, a))
			ci.draw_rect(Rect2(c - Vector2(3, 5) * s, Vector2(6, 1.5) * s), Color(0.3, 0.22, 0.14, a))
