extends PanelContainer
## Opções, em duas colunas: imagem e efeitos à esquerda, jogo e legendas à
## direita, volumes embaixo. Passe o mouse num botão para ler o que ele faz.

signal back

const OPTS := [
	# [rótulo, chave, valores, descrição]
	["Gore", "gore", ["Desligado", "Ligado"], "Sangue e mutilação nas cenas. Desligado, as mortes ficam implícitas."],
	["Efeitos de tela", "effects", ["Desligados", "Ligados"], "Brilho, vinheta, grão, distorção da sanidade, fumaça e sangue na lente."],
	["Filme antigo", "film", ["Desligado", "Ligado"], "Riscos, poeira e oscilação de brilho de película velha."],
	["Clarões", "flashes", ["Desligados", "Ligados"], "O clarão branco dos relâmpagos. Desligue se luz piscando incomoda."],
	["Modo VGA", "vga", ["Desligado", "Ligado"], "Pontilhado ordenado e paleta curta, como uma placa VGA de 1993."],
	["Resolução", "sharp", ["Leve", "Nítida"], "Leve: desenhado em 640x360 e ampliado (mais rápido). Nítida: na resolução da tela, com texto e linhas finos (mais pesado)."],
	["Tela cheia (F11)", "fullscreen", ["Não", "Sim"], "Alterna entre janela e tela cheia."],
	["Dificuldade", "difficulty", ["Branda", "Normal", "Cruel"], "Quanto a sanidade cai com sustos, erros e pistas."],
	["Legendas", "sub_size", ["Normais", "Grandes"], "Tamanho do texto das falas."],
	["Velocidade das falas", "sub_speed", ["Lenta", "Normal", "Rápida"], "Quão rápido o texto aparece e quanto tempo fica na tela."],
	["Transições", "fast_moves", ["Normais", "Rápidas"], "Velocidade do avanço de câmera entre os cômodos."],
]

var buttons: Array = []
var desc := Label.new()
var music_s := HSlider.new()
var sfx_s := HSlider.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(430, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var title := Label.new()
	title.text = "OPÇÕES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.85, 0.66, 0.36))
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 3)
	box.add_child(grid)
	for i in OPTS.size():
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(208, 0)
		b.add_theme_font_size_override("font_size", 10)
		b.pressed.connect(_cycle.bind(i))
		b.mouse_entered.connect(func(): desc.text = OPTS[i][3])
		grid.add_child(b)
		buttons.append(b)
	for pair in [["Música", music_s, State.music_volume], ["Sons", sfx_s, State.sfx_volume]]:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = pair[0]
		l.custom_minimum_size = Vector2(60, 0)
		row.add_child(l)
		var s: HSlider = pair[1]
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = pair[2]
		s.custom_minimum_size = Vector2(340, 14)
		s.focus_mode = Control.FOCUS_NONE
		row.add_child(s)
		box.add_child(row)
	music_s.value_changed.connect(func(v):
		State.music_volume = v
		State.apply_prefs())
	sfx_s.value_changed.connect(func(v):
		State.sfx_volume = v
		State.apply_prefs()
		Audio.play("tile", -6.0))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(420, 30)
	desc.add_theme_font_size_override("font_size", 9)
	desc.add_theme_color_override("font_color", Color(0.7, 0.64, 0.55))
	desc.text = "Passe o mouse numa opção para ver o que ela faz."
	box.add_child(desc)
	var close := Button.new()
	close.text = "Voltar"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func():
		State.save_prefs()
		back.emit())
	box.add_child(close)
	_refresh()


func _value(key: String) -> int:
	var v = State.get(key)
	return int(v) if typeof(v) != TYPE_BOOL else (1 if v else 0)


func _cycle(i: int) -> void:
	var key: String = OPTS[i][1]
	var n: int = (OPTS[i][2] as Array).size()
	var nv := (_value(key) + 1) % n
	if typeof(State.get(key)) == TYPE_BOOL:
		State.set(key, nv == 1)
	else:
		State.set(key, nv)
	State.apply_prefs()
	Audio.play("tile", -10.0, 1.3)
	_refresh()


func _refresh() -> void:
	for i in OPTS.size():
		var o: Array = OPTS[i]
		buttons[i].text = "%s: %s" % [o[0], o[2][_value(o[1])]]
	State.save_prefs()
	State.settings_changed.emit()
