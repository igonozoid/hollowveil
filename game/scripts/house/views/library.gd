extends "res://scripts/house/view.gd"
## Biblioteca: estantes até o teto, o atlas anatômico no atril e o piano de
## estudo de Tobias junto à janela.

var piano_rect := Rect2()
var keys_rect := Rect2()


func _init() -> void:
	id = "library"
	title = "Biblioteca"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.44
	p.fog = Color(0.01, 0.015, 0.02)
	p.add_light(Vector3(0, 1.4, 4.2), Color(0.95, 0.75, 0.4), 3.6, 0.8, 0.2, 90.0)
	p.add_light(Vector3(2.9, 1.5, 4.8), Color(1.0, 0.62, 0.3), 3.0, 0.7, 0.3, 70.0)
	var wood := Color(0.24, 0.13, 0.08)
	var wall := Color(0.16, 0.2, 0.24)
	p.floor_plane(-3.5, 3.5, 0.4, 9, 4.6, Color(0.1, 0.07, 0.05), Color(0.04, 0.03, 0.02), "", 10)
	p.back_wall(9, -3.5, 3.5, 0, 4.6, wall)
	p.side_wall(-3.5, 0.4, 9, 0, 4.6, wall)
	p.side_wall(3.5, 0.4, 9, 0, 4.6, wall)
	p.floor_plane(-3.5, 3.5, 0.4, 9, 0.0, Color(0.26, 0.15, 0.09), Color(0.12, 0.06, 0.04), "boards", 16)
	p.floor_plane(-1.4, 1.4, 2.5, 6.5, 0.005, Color(0.14, 0.18, 0.22), Color(0.1, 0.12, 0.16), "tiles", 10)
	# Janela alta no fundo
	glass.append(p.window_back(0, 8.98, 1.6, 1.0, 3.0, wood.darkened(0.2), SKY_TOP, SKY_BOT))
	# Estantes nas duas paredes
	p.bookcase_side(-3.5, 0.5, 8.9, 4.2, wood, 11)
	p.bookcase_side(3.5, 0.5, 4.2, 4.2, wood, 23)
	p.bookcase_side(3.5, 6.8, 8.9, 4.2, wood, 37)
	# Piano de estudo na parede direita, entre as estantes.
	p.box(2.5, 3.45, 0.0, 1.3, 4.5, 6.4, Color(0.08, 0.05, 0.05), Color(0.14, 0.09, 0.08))
	p.box(2.2, 2.5, 0.75, 0.85, 4.6, 6.3, Color(0.1, 0.06, 0.05))
	keys_rect = p.rect_of([Vector3(2.2, 0.85, 4.6), Vector3(2.5, 0.85, 6.3)])
	_keys()
	p.candle(Vector3(2.9, 1.3, 4.8), 0.14, true, 2.0, 0.8)
	piano_rect = p.box_rect(2.2, 3.45, 0.0, 1.3, 4.5, 6.4)
	# Atril com o atlas aberto, abajur ao lado.
	p.box(-0.08, 0.08, 0.0, 1.0, 4.0, 4.16, wood)
	p.box(-0.5, 0.5, 0.0, 0.05, 3.8, 4.4, wood.darkened(0.2))
	p.poly3([Vector3(-0.42, 1.0, 3.9), Vector3(0.42, 1.0, 3.9), Vector3(0.42, 1.18, 4.25), Vector3(-0.42, 1.18, 4.25)], Color(0.5, 0.45, 0.36))
	p.line3(Vector3(0, 1.0, 3.9), Vector3(0, 1.18, 4.25), Color(0.5, 0.42, 0.3), 1.0)
	var atlas := p.rect_of([Vector3(-0.42, 1.0, 3.9), Vector3(0.42, 1.18, 4.25)])
	if not State.is_solved("atlas"):
		# Rabiscos vermelhos da prancha anatômica.
		for i in 6:
			draw_rect(Rect2(atlas.position + Vector2(6 + i * 4, 4 + (i % 2) * 3), Vector2(2, 1)), Color(0.5, 0.08, 0.06))
	p.box(-1.2, -0.8, 0.0, 0.8, 4.4, 4.8, wood)
	p.line3(Vector3(-1.0, 0.8, 4.6), Vector3(-1.0, 1.25, 4.6), Color(0.5, 0.4, 0.2), 1.0)
	p.poly3([Vector3(-1.18, 1.25, 4.5), Vector3(-0.82, 1.25, 4.5), Vector3(-0.9, 1.4, 4.6), Vector3(-1.1, 1.4, 4.6)], Color(0.15, 0.45, 0.25))
	p.add_light(Vector3(-1.0, 1.2, 4.6), Color(0.5, 1.0, 0.6), 1.6, 0.5, 0.05, 40.0)
	# As mãos de Tobias, sobre as teclas, depois da cena.
	if State.is_solved("atlas") and State.gore:
		var c := keys_rect.get_center()
		for k in 2:
			var h := c + Vector2(-6 + k * 10, -2)
			draw_rect(Rect2(h, Vector2(6, 4)), Color(0.62, 0.55, 0.5))
			for f in 4:
				draw_rect(Rect2(h + Vector2(f * 1.5, 4), Vector2(1, 3)), Color(0.62, 0.55, 0.5))
			draw_rect(Rect2(h + Vector2(-1, 1), Vector2(2, 3)), Color(0.55, 0.0, 0.03))
			draw_rect(Rect2(h.x - 1, h.y + 4, 1, 10 + k * 4), Color(0.5, 0.0, 0.02))
	if State.is_solved("atlas"):
		hot(atlas, "look", "look:atlas_after", "O atlas")
		hot(piano_rect, "look", "look:piano_after", "O piano")
	else:
		hot(atlas.grow(8), "puzzle", "puzzle:atlas", "O atlas anatômico")
		hot(piano_rect, "look", "look:piano", "Piano de estudo")
	hot_back("go:foyer", "Voltar ao saguão")


func _keys() -> void:
	var n := 26
	for i in n:
		var z0 := 4.62 + i * (1.66 / n)
		var z1 := z0 + 1.66 / n * 0.85
		p.poly3([Vector3(2.22, 0.86, z0), Vector3(2.22, 0.86, z1), Vector3(2.48, 0.86, z1), Vector3(2.48, 0.86, z0)], Color(0.82, 0.78, 0.68))
		if i % 7 != 2 and i % 7 != 6:
			p.poly3([Vector3(2.35, 0.87, z1 - 0.02), Vector3(2.35, 0.87, z1 + 0.03), Vector3(2.48, 0.87, z1 + 0.03), Vector3(2.48, 0.87, z1 - 0.02)], Color(0.05, 0.04, 0.04))
