extends "res://scripts/house/view.gd"
## Quarto de Ofélia: paredes riscadas de cima a baixo ("ELES FALAM"), uma
## prateleira de bonecas que olham, e um círculo de giz e velas no chão.

var circle_rect := Rect2()
var doll_eyes: Array = []


func _init() -> void:
	id = "ofelia_room"
	title = "Quarto de Ofélia"
	music = "quartos"
	grade = "quartos"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.36
	p.fog = Color(0.02, 0.015, 0.03)
	var wall := Color(0.36, 0.3, 0.4)
	var wood := Color(0.3, 0.2, 0.16)
	p.add_light(Vector3(0, 0.3, 4.2), Color(1.0, 0.6, 0.32), 3.2, 1.1, 0.35, 110.0)
	p.floor_plane(-2.8, 2.8, 0.4, 7, 3.0, Color(0.14, 0.11, 0.15), Color(0.07, 0.05, 0.07), "", 6)
	p.back_wall(7, -2.8, 2.8, 0, 3.0, wall)
	p.side_wall(-2.8, 0.4, 7, 0, 3.0, wall, 10)
	p.side_wall(2.8, 0.4, 7, 0, 3.0, wall, 10)
	# Rabiscos por toda parede
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var scrawl := p.shade(Color(0.12, 0.08, 0.12), Vector3(0, 1.5, 6.9))
	for i in 18:
		var pos := p.proj(Vector3(rng.randf_range(-2.6, 2.6), rng.randf_range(0.4, 2.8), 6.98))
		draw_string(ThemeDB.fallback_font, pos, ["ELES FALAM", "eles falam", "PAI NÃO", "ouço", "SHH"][rng.randi() % 5], HORIZONTAL_ALIGNMENT_LEFT, -1, rng.randi_range(6, 9), scrawl)
	for i in 30:
		var z := rng.randf_range(1.5, 7.0)
		var y := rng.randf_range(0.3, 2.8)
		for side in [-2.79, 2.79]:
			p.line3(Vector3(side, y, z), Vector3(side, y + rng.randf_range(-0.1, 0.1), z + rng.randf_range(0.2, 0.5)), Color(0.12, 0.08, 0.12), 1.0)
	p.floor_plane(-2.8, 2.8, 0.4, 7, 0.0, Color(0.28, 0.2, 0.16), Color(0.14, 0.1, 0.08), "boards", 12)
	glass.append(p.window_back(1.2, 6.98, 0.9, 1.2, 1.5, wood.darkened(0.3), SKY_TOP, SKY_BOT))
	# Cama de renda à esquerda
	var lace := Color(0.82, 0.8, 0.82)
	p.box(-2.8, -1.6, 0.0, 0.55, 4.4, 6.6, lace.darkened(0.25), lace)
	p.box(-2.8, -1.6, 0.55, 0.7, 6.0, 6.6, Color(0.9, 0.88, 0.9))
	p.box(-2.8, -2.7, 0.0, 1.3, 6.5, 6.7, wood)
	if State.is_solved("sussurros") and State.gore:
		var pil := p.proj(Vector3(-2.2, 0.7, 6.3))
		draw_set_transform(pil, 0, Vector2(1, 0.4))
		draw_circle(Vector2.ZERO, 9, Color(0.45, 0.0, 0.04))
		draw_set_transform(Vector2.ZERO)
	# Prateleira de bonecas à direita
	p.box(2.4, 2.8, 1.5, 1.56, 3.0, 6.0, wood)
	doll_eyes.clear()
	for k in 8:
		var z2 := 3.2 + k * 0.35
		p.box(2.55, 2.75, 1.56, 1.8, z2, z2 + 0.18, [Color(0.6, 0.3, 0.35), Color(0.4, 0.4, 0.6), Color(0.7, 0.65, 0.5)][k % 3])
		var head := Vector3(2.62, 1.9, z2 + 0.09)
		var hp := p.proj(head)
		var hr := p.scale_at(head.z) * 0.08
		draw_circle(hp, hr, p.shade(Color(0.85, 0.76, 0.7), head))
		draw_rect(Rect2(hp + Vector2(-hr, -hr * 1.1), Vector2(hr * 2, hr * 0.6)), p.shade([Color(0.5, 0.3, 0.1), Color(0.9, 0.8, 0.4), Color(0.1, 0.08, 0.06)][k % 3], head))
		doll_eyes.append([hp, hr])
	# Escrivaninha com o diário (fundo, esquerda)
	p.box(-1.2, 0.0, 0.0, 0.75, 6.4, 6.95, wood, wood.lightened(0.12))
	p.box(-0.9, -0.5, 0.75, 0.8, 6.5, 6.8, Color(0.3, 0.06, 0.08))
	var desk := p.box_rect(-1.2, 0.0, 0.0, 0.85, 6.4, 6.95)
	# Círculo de giz e velas no chão
	var cc := Vector3(0.2, 0.0, 4.2)
	var ring: Array = []
	for i in 24:
		var a := TAU * i / 24.0
		ring.append(cc + Vector3(cos(a) * 0.9, 0.005, sin(a) * 0.7))
	for i in 24:
		p.line3(ring[i], ring[(i + 1) % 24], Color(0.85, 0.84, 0.8), 1.0)
	for k in 5:
		var a2 := TAU * k / 5.0 - PI * 0.5
		p.line3(cc + Vector3(cos(a2) * 0.9, 0.005, sin(a2) * 0.7), cc + Vector3(cos(a2 + TAU * 2.0 / 5.0) * 0.9, 0.005, sin(a2 + TAU * 2.0 / 5.0) * 0.7), Color(0.75, 0.74, 0.7), 1.0)
		p.candle(cc + Vector3(cos(a2) * 0.9, 0.0, sin(a2) * 0.7), 0.16, not State.is_solved("sussurros"), 1.6, 0.6)
	circle_rect = p.rect_of(ring).grow(6)
	if State.is_solved("sussurros"):
		hot(circle_rect, "look", "look:circle_after", "O círculo de giz")
	else:
		hot(circle_rect, "puzzle", "puzzle:sussurros", "O círculo de giz")
	hot(desk, "look", "look:ofelia_desk", "Escrivaninha")
	hot_back("go:corridor", "Voltar ao corredor")


func paint_live(o: Node2D) -> void:
	# As bonecas viram os olhos para o cursor.
	var m := get_viewport().get_mouse_position()
	for d in doll_eyes:
		var hp: Vector2 = d[0]
		var hr: float = d[1]
		var look := ((m - hp) / 150.0).limit_length(1.0) * hr * 0.25
		for dx in [-0.35, 0.35]:
			var e := hp + Vector2(dx * hr, 0)
			o.draw_rect(Rect2(e - Vector2(1, 1), Vector2(2, 2)), Color(0.95, 0.95, 0.9))
			o.draw_rect(Rect2((e + look).round(), Vector2(1, 1)), Color(0.05, 0.05, 0.1))


func entered(house) -> void:
	if not State.flag("ofelia_room_seen"):
		State.set_flag("ofelia_room_seen")
		Audio.play("whisper", -4.0, 1.2)
		house.subs.say("OFÉLIA", "Benjamim. Você disse o nome dele. Então você ouve mesmo.")
		house.subs.say("OFÉLIA", "Os mortos sabem onde meu pai escondeu meu diário. Mas um deles mente. Sempre um mente.")
