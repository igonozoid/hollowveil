extends "res://scripts/house/view.gd"
## Quarto de hóspedes do Capitão Hélio: cama de campanha, mesa de cartas com
## a última mão ainda aberta e, na parede, uma pele esticada num bastidor.

var frame := Rect2()


func _init() -> void:
	id = "guest_room"
	title = "Quarto de hóspedes"
	music = "quartos"
	grade = "quartos"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.42
	p.fog = Color(0.02, 0.015, 0.02)
	p.add_light(Vector3(0.2, 1.4, 4.4), Color(1.0, 0.66, 0.38), 3.6, 1.1, 0.25, 100.0)
	var wall := Color(0.26, 0.22, 0.3)
	var wood := Color(0.24, 0.13, 0.08)
	var dark := Color(0.12, 0.06, 0.05)
	p.floor_plane(-3, 3, 0.4, 7.5, 3.2, Color(0.1, 0.07, 0.1), Color(0.05, 0.03, 0.05), "", 8)
	p.back_wall(7.5, -3, 3, 0, 3.2, wall)
	for side in [-3.0, 3.0]:
		p.side_wall(side, 0.4, 7.5, 0, 3.2, wall, 12)
		p.wainscot_side(side, 0.4, 7.5, 1.0, wood, dark)
	p.wainscot_back(7.5, -3, 3, 1.0, wood, dark)
	p.floor_plane(-3, 3, 0.4, 7.5, 0.0, Color(0.24, 0.14, 0.09), Color(0.12, 0.06, 0.04), "boards", 14)
	glass.append(p.window_back(2.0, 7.48, 0.9, 1.2, 1.6, wood.darkened(0.2), SKY_TOP, SKY_BOT))
	# A pele no bastidor, no centro da parede do fundo.
	var fx0 := -1.2
	var fx1 := 0.6
	p.poly3([Vector3(fx0 - 0.1, 1.2, 7.47), Vector3(fx1 + 0.1, 1.2, 7.47), Vector3(fx1 + 0.1, 2.8, 7.47), Vector3(fx0 - 0.1, 2.8, 7.47)], Color(0.35, 0.2, 0.1))
	p.poly3([Vector3(fx0, 1.3, 7.46), Vector3(fx1, 1.3, 7.46), Vector3(fx1, 2.7, 7.46), Vector3(fx0, 2.7, 7.46)], Color(0.58, 0.48, 0.42))
	frame = p.rect_of([Vector3(fx0, 1.3, 7.46), Vector3(fx1, 2.7, 7.46)])
	# Costuras e linhas da tatuagem (embaralhadas até o enigma).
	var solved := State.is_solved("pele")
	for i in 5:
		var gx := frame.position.x + frame.size.x * i / 5.0
		var gy := frame.position.y + frame.size.y * i / 5.0
		draw_line(Vector2(gx, frame.position.y), Vector2(gx, frame.end.y), Color(0.3, 0.06, 0.06), 1.0)
		draw_line(Vector2(frame.position.x, gy), Vector2(frame.end.x, gy), Color(0.3, 0.06, 0.06), 1.0)
	var ink := p.shade(Color(0.14, 0.18, 0.3), Vector3(-0.3, 2.0, 7.46))
	if solved:
		var c := frame.get_center()
		draw_line(c + Vector2(0, -frame.size.y * 0.35), c + Vector2(0, frame.size.y * 0.3), ink, 2.0)
		draw_arc(c + Vector2(0, frame.size.y * 0.15), frame.size.x * 0.25, 0.2, PI - 0.2, 10, ink, 2.0)
		draw_line(c + Vector2(-frame.size.x * 0.15, -frame.size.y * 0.2), c + Vector2(frame.size.x * 0.15, -frame.size.y * 0.2), ink, 2.0)
	else:
		for i in 9:
			var a := frame.position + Vector2(fmod(i * 7.3, frame.size.x), fmod(i * 11.7, frame.size.y))
			draw_line(a, a + Vector2(4, (i % 3) * 2 - 2), ink, 2.0)
	if State.gore:
		for i in 4:
			draw_rect(Rect2(frame.position.x + 3 + i * frame.size.x / 4.0, frame.end.y, 1, 4 + i * 3), Color(0.45, 0.0, 0.03))
	# Cama de campanha (esquerda)
	p.box(-3.0, -2.0, 0.0, 0.5, 3.2, 6.0, Color(0.3, 0.32, 0.24), Color(0.4, 0.42, 0.32))
	p.box(-3.0, -2.0, 0.5, 0.62, 5.4, 6.0, Color(0.7, 0.68, 0.62))
	# Baú (direita)
	p.box(2.2, 3.0, 0.0, 0.6, 3.4, 4.6, Color(0.3, 0.18, 0.1), Color(0.38, 0.24, 0.14))
	p.line3(Vector3(2.2, 0.45, 3.4), Vector3(2.2, 0.45, 4.6), Color(0.6, 0.45, 0.2), 1.0)
	# Mapa na parede direita
	p.poly3([Vector3(2.99, 1.4, 5.0), Vector3(2.99, 1.4, 6.6), Vector3(2.99, 2.5, 6.6), Vector3(2.99, 2.5, 5.0)], Color(0.7, 0.62, 0.44))
	p.line3(Vector3(2.98, 1.7, 5.3), Vector3(2.98, 2.2, 6.2), Color(0.5, 0.1, 0.08), 1.0)
	# Mesa de cartas com duas cadeiras
	p.chair(Vector3(-0.9, 0, 4.6), false, wood)
	p.chair(Vector3(1.0, 0, 4.0), true, wood)
	p.box(-0.5, 0.7, 0.0, 0.75, 3.8, 4.8, Color(0.14, 0.26, 0.16), Color(0.16, 0.34, 0.2))
	for i in 5:
		var cp := p.proj(Vector3(-0.3 + i * 0.18, 0.76, 4.0 + (i % 2) * 0.3))
		draw_rect(Rect2(cp - Vector2(2, 1), Vector2(4, 3)), Color(0.88, 0.86, 0.8))
		draw_rect(Rect2(cp - Vector2(0, 0), Vector2(1, 1)), Color(0.7, 0.05, 0.05))
	p.candle(Vector3(0.5, 0.76, 4.6), 0.12, true, 2.2, 0.8)
	var table := p.box_rect(-0.5, 0.7, 0.0, 0.8, 3.8, 4.8)
	if solved:
		hot(frame, "look", "look:skin_after", "O bastidor")
	else:
		hot(frame, "puzzle", "puzzle:pele", "Uma pele esticada")
	hot(table, "look", "look:cards", "Mesa de cartas")
	hot_back("go:corridor", "Voltar ao corredor")
