extends "res://scripts/house/view.gd"
## Berçário: papel de parede de carneirinhos desbotados, um berço vazio com
## um móbile parado no ar e uma cadeira de balanço que às vezes balança.

var mobile_at := Vector2()
var mobile_s := 1.0
var rocker := Vector2()


func _init() -> void:
	id = "nursery"
	title = "Berçário"
	music = "quartos"
	grade = "quartos"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.4
	p.fog = Color(0.02, 0.015, 0.025)
	p.add_light(Vector3(0.4, 1.6, 5.4), Color(0.75, 0.82, 1.0), 4.0, 0.6, 0.0, 120.0)
	p.add_light(Vector3(-1.8, 1.0, 4.0), Color(1.0, 0.66, 0.4), 2.4, 0.7, 0.3, 60.0)
	var wall := Color(0.42, 0.38, 0.42)
	var ink := Color(0.32, 0.28, 0.32)
	var wood := Color(0.42, 0.34, 0.26)
	p.floor_plane(-2.6, 2.6, 0.4, 6.8, 3.0, Color(0.16, 0.14, 0.16), Color(0.08, 0.07, 0.08), "", 6)
	p.back_wall(6.8, -2.6, 2.6, 0, 3.0, wall)
	p.side_wall(-2.6, 0.4, 6.8, 0, 3.0, wall, 10)
	p.side_wall(2.6, 0.4, 6.8, 0, 3.0, wall, 10)
	# Carneirinhos desbotados no papel de parede (nuvens de três bolas)
	for row in 3:
		for k in 6:
			var x := -2.2 + k * 0.9 + (row % 2) * 0.45
			var y := 0.9 + row * 0.7
			var c := p.proj(Vector3(x, y, 6.79))
			var r := p.scale_at(6.79) * 0.07
			for b in 3:
				draw_circle(c + Vector2((b - 1) * r * 0.9, 0), r * 0.7, p.shade(ink.lightened(0.3), Vector3(x, y, 6.79)))
	p.wallpaper_side(-2.6, 0.4, 6.8, 0.0, 3.0, ink, 0.6)
	p.wallpaper_side(2.6, 0.4, 6.8, 0.0, 3.0, ink, 0.6)
	p.floor_plane(-2.6, 2.6, 0.4, 6.8, 0.0, Color(0.3, 0.22, 0.16), Color(0.16, 0.11, 0.08), "boards", 12)
	glass.append(p.window_side(2.58, 5.4, 1.0, 1.0, 1.6, wood.darkened(0.4), SKY_TOP, SKY_BOT))
	# Berço no fundo, centro
	var cz := 5.6
	p.box(-0.7, 0.7, 0.0, 0.45, cz, cz + 0.8, wood.darkened(0.2), Color(0.85, 0.82, 0.78))
	for i in 11:
		var x2 := -0.7 + i * 0.14
		p.line3(Vector3(x2, 0.45, cz), Vector3(x2, 1.0, cz), wood, 1.0)
	p.line3(Vector3(-0.7, 1.0, cz), Vector3(0.7, 1.0, cz), wood, 2.0)
	for post in [-0.72, 0.72]:
		p.box(post - 0.03, post + 0.03, 0.0, 1.1, cz, cz + 0.06, wood)
	# Haste do móbile
	p.line3(Vector3(0.6, 1.1, cz + 0.4), Vector3(0.6, 1.9, cz + 0.4), wood, 1.0)
	p.line3(Vector3(0.6, 1.9, cz + 0.4), Vector3(0.1, 1.9, cz + 0.4), wood, 1.0)
	mobile_at = p.proj(Vector3(0.1, 1.85, cz + 0.4))
	mobile_s = p.scale_at(cz + 0.4) / 60.0
	var crib := p.box_rect(-0.8, 0.8, 0.0, 2.0, cz, cz + 0.8)
	# Cadeira de balanço à esquerda
	rocker = p.proj(Vector3(-1.8, 0.0, 4.0))
	p.candle(Vector3(-2.3, 0.8, 4.8), 0.14, true, 2.2, 0.7)
	p.box(-2.55, -2.1, 0.0, 0.8, 4.6, 5.0, wood.darkened(0.3))
	# Caixinha de brinquedos à direita
	p.box(1.6, 2.4, 0.0, 0.5, 3.2, 3.8, Color(0.5, 0.36, 0.3), Color(0.6, 0.44, 0.36))
	if State.is_solved("movel"):
		hot(crib, "look", "look:crib_after", "O berço")
	else:
		hot(crib, "puzzle", "puzzle:movel", "O móbile do berço")
	hot(Rect2(rocker - Vector2(24, 60), Vector2(48, 62)), "look", "look:rocker", "Cadeira de balanço")
	hot_back("go:corridor", "Voltar ao corredor")


func paint_live(o: Node2D) -> void:
	# Cadeira de balanço: balança sozinha, devagar.
	var rock := sin(t * 1.4) * 0.12
	var s := p.scale_at(4.0) / 60.0 if p else 1.0
	var seat := rocker + Vector2(0, -28 * s)
	var col := Color(0.2, 0.15, 0.12)
	o.draw_line(rocker + Vector2(-18 * s, 0).rotated(rock), rocker + Vector2(18 * s, 0).rotated(rock), col, 2.0)
	o.draw_line(rocker + Vector2(-12 * s, -2 * s).rotated(rock), seat + Vector2(-12 * s, 0).rotated(rock), col, 2.0)
	o.draw_line(rocker + Vector2(12 * s, -2 * s).rotated(rock), seat + Vector2(12 * s, 0).rotated(rock), col, 2.0)
	o.draw_line(seat + Vector2(-12 * s, 0).rotated(rock), seat + Vector2(12 * s, 0).rotated(rock), col, 3.0)
	o.draw_line(seat + Vector2(10 * s, 0).rotated(rock), seat + Vector2(16 * s, -40 * s).rotated(rock), col, 2.0)
	# O móbile gira mesmo sem vento.
	var spin := t * (0.6 if State.is_solved("movel") else 0.15)
	for k in 4:
		var a := spin + TAU * k / 4.0
		var off := Vector2(cos(a) * 14.0, 0) * mobile_s
		var hang := mobile_at + off + Vector2(0, (10 + 4 * sin(a)) * mobile_s)
		o.draw_line(mobile_at + off, hang, Color(0.7, 0.68, 0.6), 1.0)
		o.draw_circle(hang, 2.5 * mobile_s, [Color(0.9, 0.85, 0.5), Color(0.7, 0.75, 0.9), Color(0.9, 0.6, 0.6), Color(0.75, 0.9, 0.7)][k])
	o.draw_line(mobile_at + Vector2(-14, 0) * mobile_s, mobile_at + Vector2(14, 0) * mobile_s, Color(0.6, 0.5, 0.35), 1.0)
