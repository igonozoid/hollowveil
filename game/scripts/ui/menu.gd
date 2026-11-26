extends Node2D
## Tela de título: a Casa Morvant no alto do vale, na chuva, com névoa,
## relâmpagos e uma janela que acende sozinha.

signal new_game
signal dark_game
signal continue_game
signal quit

const Options := preload("res://scripts/ui/options.gd")
const Logo := preload("res://scripts/ui/logo.gd")

var t := 0.0
var flash := 0.0
var ui := CanvasLayer.new()
var box := VBoxContainer.new()
var options: PanelContainer
var confirm := false
var new_b := Button.new()
var rain: Array = []


func _ready() -> void:
	ui.layer = 9
	add_child(ui)
	var logo := Logo.new()
	logo.position = Vector2(30, 22)
	ui.add_child(logo)
	box.position = Vector2(40, 130)
	box.custom_minimum_size = Vector2(190, 0)
	box.add_theme_constant_override("separation", 5)
	ui.add_child(box)
	if State.has_save():
		_button("Continuar a investigação", func(): continue_game.emit())
	new_b = _button("Nova investigação", _on_new)
	if State.dark_night_open():
		var d := _button("A Noite Mais Escura", func(): dark_game.emit())
		d.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2))
	if not State.relics_all.is_empty() or not State.endings.is_empty():
		var info := Label.new()
		info.text = "Relíquias: %d de 40 · Finais: %d de 4" % [State.relics_all.size(), State.endings.size()]
		info.add_theme_font_size_override("font_size", 8)
		info.add_theme_color_override("font_color", Color(0.6, 0.55, 0.48))
		info.position = Vector2(40, 326)
		ui.add_child(info)
	_button("Opções", _open_options)
	_button("Sair", func(): quit.emit())
	var foot := Label.new()
	foot.text = "IGNF Lab · tudo desenhado e sintetizado por código · Esc pausa · F11 tela cheia"
	foot.add_theme_font_size_override("font_size", 8)
	foot.add_theme_color_override("font_color", Color(0.5, 0.46, 0.42))
	foot.position = Vector2(40, 340)
	ui.add_child(foot)
	for i in 160:
		rain.append(Vector2(randf() * 700, randf() * 380))
	Audio.lightning.connect(func(s): flash = maxf(flash, s))
	Audio.music("menu")
	Audio.set_ambient(true)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	b.mouse_entered.connect(func(): Audio.play("hover", -14.0))
	box.add_child(b)
	return b


func _on_new() -> void:
	if State.has_save() and not confirm:
		confirm = true
		new_b.text = "Apagar o save anterior? Clique de novo"
		Audio.play("wrong", -10.0)
		return
	new_game.emit()


func _open_options() -> void:
	box.hide()
	options = Options.new()
	options.position = Vector2(40, 120)
	ui.add_child(options)
	options.back.connect(func():
		options.queue_free()
		box.show())


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 1.8)
	for i in rain.size():
		rain[i] += Vector2(-60, 420) * delta
		if rain[i].y > 370:
			rain[i] = Vector2(randf() * 720, -10)
	queue_redraw()


func _draw() -> void:
	# Céu
	for i in 24:
		draw_rect(Rect2(0, i * 15, 640, 16), Color(0.03, 0.04, 0.08).lerp(Color(0.14, 0.13, 0.2), i / 23.0))
	var moon := Vector2(470, 70)
	for r in range(70, 10, -10):
		draw_circle(moon, r, Color(0.6, 0.65, 0.8, 0.025))
	draw_circle(moon, 18, Color(0.86, 0.86, 0.78))
	draw_circle(moon + Vector2(-5, -3), 4, Color(0.75, 0.75, 0.68))
	# Nuvens passando na frente da lua
	for i in 5:
		var x := fmod(i * 170.0 + t * (6.0 + i * 2.0), 900.0) - 150.0
		draw_rect(Rect2(x, 40 + i * 16, 140 + i * 20, 8), Color(0.08, 0.08, 0.12, 0.7))
		draw_rect(Rect2(x + 20, 36 + i * 16, 90, 6), Color(0.08, 0.08, 0.12, 0.6))
	if flash > 0.0:
		draw_rect(Rect2(0, 0, 640, 360), Color(0.7, 0.75, 0.9, flash * 0.35))
		var bx := 560.0
		var by := 0.0
		for i in 8:
			var nx := bx + randf_range(-14, 10)
			var ny := by + 18
			draw_line(Vector2(bx, by), Vector2(nx, ny), Color(0.9, 0.92, 1.0, flash), 1.0)
			bx = nx
			by = ny
	# Morro
	var hill := PackedVector2Array([Vector2(160, 360), Vector2(220, 250), Vector2(320, 228), Vector2(500, 224), Vector2(600, 246), Vector2(640, 270), Vector2(640, 360)])
	draw_colored_polygon(hill, Color(0.03, 0.035, 0.04))
	_mansion(Vector2(400, 226))
	# Árvores mortas
	for tx in [250.0, 590.0, 615.0]:
		_tree(Vector2(tx, 250 + (tx - 250) * 0.04))
	# Névoa
	for i in 26:
		var y := 236.0 + i * 4.6 + sin(t * 0.4 + i) * 3.0
		var x2 := fmod(t * (5.0 + (i % 5) * 2.0) + i * 53.0, 320.0) - 320.0
		for k in 4:
			var wdt := 180.0 + (i * 37 % 90)
			draw_rect(Rect2(x2 + k * 320, y, wdt, 3), Color(0.55, 0.6, 0.66, 0.035 + i * 0.002))
	# Chuva
	for d in rain:
		draw_line(d, d + Vector2(-2, 9), Color(0.6, 0.65, 0.8, 0.25), 1.0)


func _mansion(base: Vector2) -> void:
	var c := Color(0.015, 0.015, 0.02).lerp(Color(0.3, 0.3, 0.4), flash * 0.5)
	# Corpo principal, alas e torre
	draw_rect(Rect2(base + Vector2(-80, -70), Vector2(160, 70)), c)
	draw_rect(Rect2(base + Vector2(-130, -46), Vector2(52, 46)), c)
	draw_rect(Rect2(base + Vector2(78, -50), Vector2(58, 50)), c)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-86, -70), base + Vector2(0, -112), base + Vector2(86, -70)]), c)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-134, -46), base + Vector2(-104, -72), base + Vector2(-74, -46)]), c)
	draw_colored_polygon(PackedVector2Array([base + Vector2(74, -50), base + Vector2(107, -78), base + Vector2(140, -50)]), c)
	draw_rect(Rect2(base + Vector2(40, -140), Vector2(26, 70)), c)
	draw_colored_polygon(PackedVector2Array([base + Vector2(36, -140), base + Vector2(53, -176), base + Vector2(70, -140)]), c)
	for cx in [-50.0, 20.0, 110.0]:
		draw_rect(Rect2(base + Vector2(cx, -104 if cx != 110.0 else -86), Vector2(8, 22)), c)
	# Janelas: quase todas escuras; algumas acesas por dentro.
	var lit := [Vector2(-60, -56), Vector2(-20, -30), Vector2(30, -56), Vector2(96, -36), Vector2(48, -120)]
	for i in 12:
		var wx := -72 + (i % 6) * 26
		var wy := -58 + (i / 6) * 26
		draw_rect(Rect2(base + Vector2(wx, wy), Vector2(8, 12)), Color(0.05, 0.05, 0.07))
	for i in lit.size():
		var on := 0.6 + 0.4 * sin(t * (1.3 + i) + i * 2.0)
		if i == 4:
			on = 1.0 if fmod(t, 9.0) > 6.5 else 0.0
		var w: Vector2 = base + lit[i]
		draw_rect(Rect2(w, Vector2(8, 12)), Color(1.0, 0.6, 0.25, on))
		draw_circle(w + Vector2(4, 6), 14, Color(1.0, 0.55, 0.2, 0.06 * on))
		if i == 2 and fmod(t, 7.0) > 5.0:
			draw_rect(Rect2(w + Vector2(2, 2), Vector2(4, 10)), Color(0.05, 0.02, 0.02))
	# Porta
	draw_rect(Rect2(base + Vector2(-8, -18), Vector2(16, 18)), Color(0.08, 0.03, 0.02))


func _tree(b: Vector2) -> void:
	var c := Color(0.02, 0.02, 0.025)
	draw_line(b, b + Vector2(2, -60), c, 3.0)
	for i in 5:
		var y := -24 - i * 8
		var dir := -1 if i % 2 == 0 else 1
		draw_line(b + Vector2(1, y), b + Vector2(dir * (14 + i * 2), y - 14), c, 1.0)
