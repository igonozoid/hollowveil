extends "res://scripts/house/view.gd"
## Saguão, virado para a porta de entrada: acorrentada por dentro.

var mirror := Rect2()


func _init() -> void:
	id = "foyer_door"
	title = "Porta de entrada"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.46
	p.add_light(Vector3(-2.4, 1.6, 4.4), Color(1.0, 0.6, 0.3), 2.6, 0.9, 0.3, 70.0)
	var wall := Color(0.2, 0.27, 0.22)
	var ink := Color(0.13, 0.19, 0.15)
	var wood := Color(0.3, 0.17, 0.1)
	var dark := Color(0.16, 0.08, 0.05)
	p.floor_plane(-4, 4, 0.4, 5.0, 5.2, Color(0.12, 0.08, 0.06), Color(0.06, 0.04, 0.03), "", 8)
	p.back_wall(5.0, -4, 4, 0, 5.2, wall)
	p.wallpaper_back(5.0, -4, 4, 1.2, 5.2, ink)
	p.side_wall(-4, 0.4, 5.0, 1.2, 5.2, wall, 8)
	p.side_wall(4, 0.4, 5.0, 1.2, 5.2, wall, 8)
	p.wainscot_side(-4, 0.4, 5.0, 1.2, wood, dark)
	p.wainscot_side(4, 0.4, 5.0, 1.2, wood, dark)
	p.wainscot_back(5.0, -4, 4, 1.2, wood, dark)
	p.floor_plane(-4, 4, 0.4, 5.0, 0.0, Color(0.26, 0.24, 0.21), Color(0.07, 0.06, 0.06), "tiles", 10)
	# Janelas ladeando a porta
	glass.append(p.window_back(-2.6, 4.98, 1.0, 1.3, 2.4, wood.darkened(0.3), SKY_TOP, SKY_BOT))
	glass.append(p.window_back(2.6, 4.98, 1.0, 1.3, 2.4, wood.darkened(0.3), SKY_TOP, SKY_BOT))
	# Porta dupla
	var door := p.door_back(0, 4.97, 2.0, 3.0, Color(0.26, 0.14, 0.08))
	p.line3(Vector3(0, 0, 4.96), Vector3(0, 3.0, 4.96), Color(0.08, 0.04, 0.02), 1.0)
	# Correntes em X por dentro.
	var chain := Color(0.42, 0.4, 0.38)
	for k in 2:
		var a := Vector3(-1.1, 2.6 if k == 0 else 0.6, 4.9)
		var b := Vector3(1.1, 0.6 if k == 0 else 2.6, 4.9)
		for i in 18:
			var q := a.lerp(b, i / 18.0)
			var r := a.lerp(b, (i + 0.7) / 18.0)
			p.line3(q, r, chain if i % 2 == 0 else chain.darkened(0.4), 2.0)
	p.box(-0.18, 0.18, 1.45, 1.8, 4.85, 4.9, Color(0.5, 0.42, 0.22))
	# Espelho à esquerda, cabideiro à direita.
	mirror = p.rect_of([Vector3(-3.95, 1.2, 2.2), Vector3(-3.95, 2.6, 3.2)])
	p.poly3([Vector3(-3.95, 1.1, 2.1), Vector3(-3.95, 1.1, 3.3), Vector3(-3.95, 2.7, 3.3), Vector3(-3.95, 2.7, 2.1)], Color(0.55, 0.42, 0.2))
	p.poly3([Vector3(-3.94, 1.2, 2.2), Vector3(-3.94, 1.2, 3.2), Vector3(-3.94, 2.6, 3.2), Vector3(-3.94, 2.6, 2.2)], Color(0.2, 0.24, 0.26))
	p.candle(Vector3(-3.6, 1.0, 3.6), 0.14, true, 2.0, 0.8)
	p.box(-3.8, -3.4, 0.0, 1.0, 3.4, 3.9, wood)
	p.line3(Vector3(3.2, 0, 3.8), Vector3(3.2, 2.2, 3.8), wood.lightened(0.1), 2.0)
	for dy in [1.9, 2.1]:
		p.line3(Vector3(3.2, dy, 3.8), Vector3(3.0, dy + 0.15, 3.8), wood, 1.0)
	p.poly3([Vector3(2.9, 1.0, 3.75), Vector3(3.3, 1.0, 3.75), Vector3(3.4, 2.0, 3.75), Vector3(2.85, 2.0, 3.75)], Color(0.08, 0.07, 0.08))
	hot(door, "look", "look:door", "Porta de entrada")
	hot(mirror, "look", "look:mirror", "Espelho")
	hot_back("go:foyer", "Virar-se")


func paint_live(o: Node2D) -> void:
	# No espelho, às vezes, há alguém atrás de Dália.
	if mirror.size.x <= 0.0:
		return
	var a := clampf(sin(t * 0.37) * 3.0 - 2.0, 0.0, 1.0) * (0.25 + State.madness())
	if a > 0.01:
		var c := mirror.get_center() + Vector2(2, 2)
		o.draw_rect(Rect2(c + Vector2(-2, -10), Vector2(4, 4)), Color(0.7, 0.9, 0.9, a * 0.6))
		o.draw_rect(Rect2(c + Vector2(-4, -6), Vector2(8, 14)), Color(0.7, 0.9, 0.9, a * 0.45))
