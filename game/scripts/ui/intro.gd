extends Node2D
## Introdução em cartões: a carta do advogado e a porta que bate.

signal done

const CARDS := [
	["", "Vale Oco, 30 de outubro de 1924."],
	["CARTA", "Sra. Ferraz,\n\nA Casa Morvant vai a leilão no dia 2. Os compradores não passam do portão. Dizem que a casa ainda janta.\n\nFaça sua sessão. Acenda suas velas. Diga a todos que os mortos foram embora. Pago o dobro.\n\n— Dr. Bento Albuquerque, advogado"],
	["", "Treze anos antes, oito pessoas sentaram para jantar na Casa Morvant.\nNenhuma se levantou."],
	["", "Dália Ferraz cobra por hora.\nEm vinte anos de sessões, os mortos nunca responderam."],
	["", "Até esta noite."],
]

var i := -1
var label := Label.new()
var paper := ColorRect.new()
var t := 0.0
var shown := 0.0
var rain: Array = []
var ending := false


func _ready() -> void:
	paper.color = Color(0.78, 0.72, 0.58)
	paper.position = Vector2(170, 50)
	paper.size = Vector2(300, 250)
	paper.hide()
	add_child(paper)
	label.position = Vector2(120, 140)
	label.size = Vector2(400, 100)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	add_child(label)
	for k in 120:
		rain.append(Vector2(randf() * 700, randf() * 380))
	Audio.music("menu")
	_next()


func _next() -> void:
	i += 1
	if i >= CARDS.size():
		_finish()
		return
	shown = 0.0
	var card: Array = CARDS[i]
	var letter: bool = card[0] == "CARTA"
	paper.visible = letter
	if letter:
		label.position = Vector2(186, 64)
		label.size = Vector2(268, 220)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.2, 0.1, 0.06))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		Audio.play("card", -4.0)
	else:
		label.position = Vector2(100, 140)
		label.size = Vector2(440, 100)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))


func _finish() -> void:
	if ending:
		return
	ending = true
	label.text = ""
	paper.hide()
	Audio.play("slam", 0.0)
	Audio.play("laugh", -10.0, 0.8)
	get_tree().create_timer(1.6).timeout.connect(func(): done.emit())


func _unhandled_input(event: InputEvent) -> void:
	if ending:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo):
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			_finish()
			return
		var full: String = CARDS[i][1]
		if shown < full.length():
			shown = full.length()
		else:
			_next()


func _process(delta: float) -> void:
	t += delta
	if i >= 0 and i < CARDS.size() and not ending:
		var full: String = CARDS[i][1]
		shown = minf(full.length(), shown + delta * 40.0)
		label.text = full.substr(0, int(shown))
	for k in rain.size():
		rain[k] += Vector2(-50, 400) * delta
		if rain[k].y > 370:
			rain[k] = Vector2(randf() * 720, -10)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.01, 0.01, 0.015))
	for d in rain:
		draw_line(d, d + Vector2(-2, 8), Color(0.5, 0.55, 0.7, 0.18), 1.0)
	if not ending:
		draw_string(ThemeDB.fallback_font, Vector2(520, 346), "clique para continuar", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.4, 0.37, 0.34))
