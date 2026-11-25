extends "res://scripts/house/view.gd"
## Sala de música: plateia de cadeiras vazias voltadas para um palco com
## cortinas, o piano de cauda de Celeste e uma harpa sem metade das cordas.

var piano_rect := Rect2()
var stage_spot := Vector2()


func _init() -> void:
	id = "music"
	title = "Sala de música"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.4
	p.fog = Color(0.02, 0.01, 0.02)
	p.add_light(Vector3(0, 2.2, 8.4), Color(1.0, 0.72, 0.42), 4.5, 1.0, 0.1, 140.0)
	var wall := Color(0.24, 0.14, 0.24)
	var ink := Color(0.16, 0.08, 0.16)
	var wood := Color(0.24, 0.12, 0.08)
	var dark := Color(0.12, 0.06, 0.06)
	var velvet := Color(0.45, 0.05, 0.08)
	p.floor_plane(-4, 4, 0.4, 10, 4.5, Color(0.1, 0.06, 0.08), Color(0.05, 0.03, 0.04), "", 10)
	p.back_wall(10, -4, 4, 0, 4.5, wall)
	p.wallpaper_back(10, -4, 4, 1.2, 4.5, ink, 0.4)
	p.side_wall(-4, 0.4, 10, 1.2, 4.5, wall)
	p.wallpaper_side(-4, 0.4, 10, 1.2, 4.5, ink, 0.4)
	p.side_wall(4, 0.4, 10, 1.2, 4.5, wall)
	p.wainscot_side(-4, 0.4, 10, 1.2, wood, dark)
	p.wainscot_side(4, 0.4, 10, 1.2, wood, dark)
	p.wainscot_back(10, -4, 4, 1.2, wood, dark)
	glass.append(p.window_side(3.98, 3.4, 1.0, 1.3, 2.4, wood.darkened(0.3), SKY_TOP, SKY_BOT))
	glass.append(p.window_side(3.98, 6.2, 1.0, 1.3, 2.4, wood.darkened(0.3), SKY_TOP, SKY_BOT))
	p.floor_plane(-4, 4, 0.4, 10, 0.0, Color(0.26, 0.14, 0.09), Color(0.13, 0.06, 0.04), "boards", 18)
	# Retrato de Celeste sobre o palco
	p.portrait_back(0, 9.98, 1.2, 2.6, 1.5, "woman")
	# Palco e cortinas
	p.box(-3.2, 3.2, 0.0, 0.5, 7.4, 10.0, Color(0.22, 0.11, 0.07), Color(0.3, 0.16, 0.1))
	for side in [-1.0, 1.0]:
		for k in 5:
			var x: float = side * (3.2 - k * 0.18)
			p.poly3([Vector3(x, 0.5, 7.5 + k * 0.05), Vector3(x - side * 0.2, 0.5, 7.5 + k * 0.05), Vector3(x - side * 0.2, 4.4, 7.5 + k * 0.05), Vector3(x, 4.4, 7.5 + k * 0.05)], velvet.darkened(0.1 * (k % 2)))
	p.poly3([Vector3(-3.2, 3.9, 7.45), Vector3(3.2, 3.9, 7.45), Vector3(3.2, 4.4, 7.45), Vector3(-3.2, 4.4, 7.45)], velvet)
	# Harpa
	var hb := Vector3(1.6, 0.5, 8.8)
	p.line3(hb, hb + Vector3(0, 1.7, 0), Color(0.6, 0.45, 0.2), 2.0)
	p.line3(hb + Vector3(0, 1.7, 0), hb + Vector3(0.7, 1.2, 0), Color(0.6, 0.45, 0.2), 2.0)
	p.line3(hb, hb + Vector3(0.7, 0.2, 0), Color(0.6, 0.45, 0.2), 2.0)
	for i in 5:
		var k2 := (i + 1) / 6.0
		p.line3(hb + Vector3(0.7 * k2, 0.2 * k2, 0), hb + Vector3(0.7 * k2, 1.7 - 0.5 * k2, 0), Color(0.8, 0.75, 0.6), 1.0)
	# Piano de cauda
	var pc := Vector3(-1.3, 0.5, 8.6)
	p.box(pc.x - 0.05, pc.x + 0.05, 0.5, 1.2, pc.z, pc.z + 0.1, Color(0.04, 0.03, 0.03))
	p.box(pc.x - 0.75, pc.x + 0.75, 1.2, 1.45, pc.z - 0.7, pc.z + 0.8, Color(0.09, 0.07, 0.07), Color(0.14, 0.11, 0.11))
	p.poly3([Vector3(pc.x - 0.7, 1.45, pc.z - 0.6), Vector3(pc.x + 0.7, 1.45, pc.z - 0.6), Vector3(pc.x + 0.4, 2.3, pc.z + 0.5), Vector3(pc.x - 0.7, 2.3, pc.z + 0.5)], Color(0.07, 0.05, 0.05))
	p.box(pc.x - 0.7, pc.x + 0.7, 1.15, 1.22, pc.z - 0.95, pc.z - 0.7, Color(0.85, 0.82, 0.74))
	p.candelabra(Vector3(pc.x + 0.55, 1.45, pc.z - 0.3), true)
	piano_rect = p.box_rect(pc.x - 0.8, pc.x + 0.8, 0.5, 2.3, pc.z - 1.0, pc.z + 0.8)
	stage_spot = p.proj(Vector3(0.2, 0.5, 8.0))
	# Plateia: cadeiras de costas para nós
	for row in 2:
		for cx in [-2.7, -1.8, 1.8, 2.7]:
			p.chair(Vector3(cx, 0, 6.0 - row * 1.2), false, Color(0.28, 0.12, 0.1))
	# Gramofone na mesinha à esquerda
	p.box(-3.6, -3.0, 0.0, 0.8, 2.6, 3.2, wood)
	p.box(-3.45, -3.15, 0.8, 0.95, 2.75, 3.05, Color(0.14, 0.08, 0.05))
	var horn := p.proj(Vector3(-3.3, 1.2, 2.9))
	var hs := p.scale_at(2.9) * 0.22
	draw_colored_polygon(PackedVector2Array([horn, horn + Vector2(hs, -hs * 1.4), horn + Vector2(hs * 1.6, -hs * 0.4)]), p.shade(Color(0.6, 0.45, 0.2), Vector3(-3.3, 1.2, 2.9)))
	var gramophone := p.box_rect(-3.6, -3.0, 0.0, 1.5, 2.6, 3.2)
	if State.is_solved("partitura") and State.gore:
		draw_set_transform(stage_spot, 0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, 16, Color(0.4, 0.0, 0.02))
		draw_circle(Vector2(5, -2), 8, Color(0.55, 0.02, 0.04))
		draw_set_transform(Vector2.ZERO)
	if State.is_solved("partitura"):
		hot(piano_rect, "look", "look:piano_music_after", "Piano de cauda")
	else:
		hot(piano_rect, "puzzle", "puzzle:partitura", "Piano de cauda")
	hot(gramophone, "voice", "event:gramophone", "Gramofone")
	hot_back("go:foyer_door", "Voltar ao saguão")
