extends "res://scripts/house/view.gd"
## Sala de jantar: a mesa longa ainda posta, a lareira, as janelas e a porta
## da copa (que leva à cozinha).

var table_rect := Rect2()
var fire_rect := Rect2()
var leocadia_spot := Vector2()


func _init() -> void:
	id = "dining"
	title = "Sala de jantar"


func paint() -> void:
	p.cy = 145.0
	p.ambient = 0.46
	p.fog = Color(0.02, 0.012, 0.01)
	p.add_light(Vector3(-3.0, 0.8, 5.5), Color(1.0, 0.45, 0.18), 5.0, 1.3, 0.35, 120.0)
	var wall := Color(0.32, 0.12, 0.12)
	var ink := Color(0.22, 0.07, 0.08)
	var wood := Color(0.28, 0.15, 0.09)
	var dark := Color(0.15, 0.07, 0.05)
	p.floor_plane(-3.5, 3.5, 0.4, 11, 4.2, Color(0.12, 0.07, 0.05), Color(0.05, 0.03, 0.02), "", 12)
	p.back_wall(11, -3.5, 3.5, 0, 4.2, wall)
	p.wallpaper_back(11, -3.5, 3.5, 1.1, 4.2, ink, 0.5)
	p.side_wall(-3.5, 0.4, 11, 1.1, 4.2, wall)
	p.wallpaper_side(-3.5, 0.4, 11, 1.1, 4.2, ink, 0.5)
	p.side_wall(3.5, 0.4, 11, 1.1, 4.2, wall)
	p.wallpaper_side(3.5, 0.4, 11, 1.1, 4.2, ink, 0.5)
	p.wainscot_side(-3.5, 0.4, 11, 1.1, wood, dark)
	p.wainscot_side(3.5, 0.4, 11, 1.1, wood, dark)
	p.wainscot_back(11, -3.5, 3.5, 1.1, wood, dark)
	p.floor_plane(-3.5, 3.5, 0.4, 11, 0.0, Color(0.3, 0.17, 0.1), Color(0.14, 0.07, 0.04), "boards", 18)
	# Tapete sob a mesa
	p.floor_plane(-1.8, 1.8, 2.4, 10.0, 0.005, Color(0.3, 0.06, 0.07), Color(0.2, 0.04, 0.05), "", 14)
	# Janelas na parede direita
	glass.append(p.window_side(3.48, 4.0, 1.0, 1.2, 2.2, wood.darkened(0.3), SKY_TOP, SKY_BOT))
	glass.append(p.window_side(3.48, 7.5, 1.0, 1.2, 2.2, wood.darkened(0.3), SKY_TOP, SKY_BOT))
	# Lareira na parede esquerda
	p.box(-3.5, -3.1, 0.0, 1.5, 4.6, 6.4, Color(0.3, 0.27, 0.25))
	p.poly3([Vector3(-3.1, 0.0, 5.0), Vector3(-3.1, 0.0, 6.0), Vector3(-3.1, 1.0, 6.0), Vector3(-3.1, 1.0, 5.0)], Color(0.02, 0.01, 0.0), false)
	fire_rect = p.rect_of([Vector3(-3.1, 0.0, 5.0), Vector3(-3.1, 0.7, 6.0)])
	p.box(-3.6, -2.95, 1.5, 1.62, 4.5, 6.5, Color(0.36, 0.32, 0.3))
	# Retrato de Celeste e porta da copa no fundo
	p.portrait_back(-1.6, 10.98, 1.0, 1.8, 1.3, "woman")
	var kitchen_open := State.flag("kitchen_open")
	var door := p.door_back(2.1, 10.97, 1.0, 2.2, wood, kitchen_open, false)
	# Mesa longa, cadeiras e louça
	var cloth := Color(0.66, 0.62, 0.55)
	p.chair(Vector3(0, 0, 10.4), true, wood)
	for k in 3:
		var zc := 8.8 - k * 1.6
		p.chair(Vector3(-1.25, 0, zc), false, wood)
		p.chair(Vector3(1.25, 0, zc), false, wood)
	p.box(-0.9, 0.9, 0.0, 0.76, 4.2, 9.8, cloth.darkened(0.25), cloth)
	p.box(-0.9, 0.9, 0.5, 0.76, 4.2, 4.25, cloth.darkened(0.15))
	for k in 3:
		var zc2 := 8.8 - k * 1.6
		for side in [-0.55, 0.55]:
			_plate(Vector3(side, 0.765, zc2))
	_plate(Vector3(0, 0.765, 9.4))
	p.add_light(Vector3(0, 1.1, 7.0), Color(1.0, 0.66, 0.32), 4.0, 0.9, 0.2, 90.0)
	p.candelabra(Vector3(0, 0.76, 6.4), true)
	p.candelabra(Vector3(0, 0.76, 8.0), true)
	table_rect = p.rect_of([Vector3(-0.9, 0.0, 4.2), Vector3(0.9, 1.1, 9.8), Vector3(-0.9, 1.1, 4.2), Vector3(0.9, 0.0, 4.2)])
	leocadia_spot = p.proj(Vector3(0.55, 0.77, 7.2))
	# O que ficou depois do jantar de Leocádia.
	if State.is_solved("ceia") and State.gore:
		var c := leocadia_spot
		draw_set_transform(c, 0, Vector2(1, 0.35))
		draw_circle(Vector2.ZERO, 14, Color(0.4, 0.0, 0.02))
		draw_circle(Vector2(-4, 1), 7, Color(0.55, 0.02, 0.04))
		draw_set_transform(Vector2.ZERO)
		for i in 5:
			draw_rect(Rect2(c + Vector2(-6 + i * 3, -2), Vector2(2, 2)), Color(0.9, 0.75, 0.3))
		for i in 6:
			draw_rect(Rect2(c.x + 10 + i, c.y + 2, 1, 6 + (i * 7) % 9), Color(0.45, 0.0, 0.02))
	# Hotspots
	if kitchen_open:
		hot(door, "walk", "go:kitchen", "Copa e cozinha")
	else:
		hot(door, "locked", "locked:pantry", "Porta da copa")
	hot(fire_rect, "look", "look:fireplace", "Lareira")
	if State.is_solved("ceia"):
		hot(table_rect, "look", "look:table_after", "A mesa")
	else:
		hot(table_rect, "puzzle", "puzzle:ceia", "A mesa posta")
	hot_back("go:foyer", "Voltar ao saguão")


func _plate(c: Vector3) -> void:
	var pts: Array = []
	for i in 10:
		var a := TAU * i / 10.0
		pts.append(c + Vector3(cos(a) * 0.16, 0, sin(a) * 0.16))
	p.poly3(pts, Color(0.62, 0.6, 0.56))
	var soup: Array = []
	for i in 10:
		var a := TAU * i / 10.0
		soup.append(c + Vector3(cos(a) * 0.09, 0.002, sin(a) * 0.09))
	# A sopa de treze anos: escura, com nata.
	p.poly3(soup, Color(0.3, 0.14, 0.06))


func paint_live(o: Node2D) -> void:
	# Fogo da lareira
	if fire_rect.size.x > 0.0:
		var base := fire_rect.position + Vector2(0, fire_rect.size.y)
		for i in 7:
			var x := base.x + fire_rect.size.x * (0.15 + i * 0.11)
			var h := fire_rect.size.y * (0.35 + 0.3 * absf(sin(t * (5.0 + i) + i)))
			o.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, base.y), Vector2(x, base.y - h), Vector2(x + 3, base.y)]), Color(1.0, 0.45 + 0.1 * sin(t * 9.0 + i), 0.12))
		o.draw_rect(Rect2(base + Vector2(fire_rect.size.x * 0.1, -3), Vector2(fire_rect.size.x * 0.8, 3)), Color(1.0, 0.85, 0.4))
