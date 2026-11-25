extends "res://scripts/house/view.gd"
## Quarto de Celeste: cama de dossel lilás, penteadeira com a caixa de música
## e, ao lado, um vidro onde alguma coisa ainda vibra.

var jar := Vector2()
var jar_r := 0.0


func _init() -> void:
	id = "celeste_room"
	title = "Quarto de Celeste"
	music = "quartos"
	grade = "quartos"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.42
	p.fog = Color(0.02, 0.012, 0.03)
	p.add_light(Vector3(-1.0, 1.3, 6.6), Color(1.0, 0.66, 0.4), 3.4, 1.0, 0.3, 90.0)
	var wall := Color(0.34, 0.24, 0.38)
	var ink := Color(0.24, 0.15, 0.28)
	var wood := Color(0.26, 0.13, 0.1)
	var lilac := Color(0.58, 0.44, 0.66)
	p.floor_plane(-3, 3, 0.4, 7.5, 3.4, Color(0.12, 0.08, 0.12), Color(0.06, 0.04, 0.06), "", 8)
	p.back_wall(7.5, -3, 3, 0, 3.4, wall)
	p.wallpaper_back(7.5, -3, 3, 0, 3.4, ink, 0.35)
	for side in [-3.0, 3.0]:
		p.side_wall(side, 0.4, 7.5, 0, 3.4, wall, 12)
		p.wallpaper_side(side, 0.4, 7.5, 0, 3.4, ink, 0.35)
	p.floor_plane(-3, 3, 0.4, 7.5, 0.0, Color(0.26, 0.14, 0.1), Color(0.13, 0.07, 0.05), "boards", 14)
	p.floor_plane(-1.6, 1.4, 3.0, 6.6, 0.006, Color(0.3, 0.18, 0.32), Color(0.2, 0.1, 0.2), "tiles", 8)
	glass.append(p.window_back(1.4, 7.48, 1.0, 1.1, 1.8, wood.darkened(0.2), SKY_TOP, SKY_BOT))
	# Guarda-roupa na parede esquerda
	p.box(-3.0, -2.4, 0.0, 2.6, 2.4, 3.8, wood, wood.lightened(0.1), wood.darkened(0.15))
	p.line3(Vector3(-2.4, 0.2, 3.1), Vector3(-2.4, 2.4, 3.1), wood.darkened(0.5), 1.0)
	# Penteadeira com espelho oval no fundo, à esquerda
	p.box(-1.9, -0.3, 0.0, 0.8, 6.9, 7.45, wood, Color(0.36, 0.2, 0.14))
	var mc := Vector3(-1.1, 1.7, 7.44)
	var oval: Array = []
	for i in 16:
		var a := TAU * i / 16.0
		oval.append(mc + Vector3(cos(a) * 0.5, sin(a) * 0.7, 0))
	p.poly3(oval, Color(0.55, 0.42, 0.2))
	var inner: Array = []
	for q in oval:
		inner.append(mc + ((q as Vector3) - mc) * 0.85 + Vector3(0, 0, -0.005))
	p.poly3(inner, Color(0.22, 0.24, 0.3))
	p.candle(Vector3(-1.7, 0.8, 7.0), 0.14, true, 2.4, 0.8)
	# A caixa de música
	var box_r := p.box_rect(-1.25, -0.85, 0.8, 1.0, 6.95, 7.2)
	p.box(-1.25, -0.85, 0.8, 0.98, 6.95, 7.2, Color(0.4, 0.22, 0.12), Color(0.55, 0.36, 0.18))
	if State.is_solved("caixa"):
		p.poly3([Vector3(-1.25, 0.98, 7.2), Vector3(-0.85, 0.98, 7.2), Vector3(-0.85, 1.25, 7.25), Vector3(-1.25, 1.25, 7.25)], Color(0.5, 0.3, 0.16))
	# O vidro com a voz
	jar = p.proj(Vector3(-0.55, 0.98, 7.05))
	jar_r = p.scale_at(7.05) * 0.09
	p.box(-0.65, -0.45, 0.8, 1.15, 6.95, 7.15, Color(0.5, 0.6, 0.6), Color(0.6, 0.7, 0.7))
	# Cama de dossel na parede direita
	var bed_c := Color(0.62, 0.56, 0.6)
	p.box(1.1, 3.0, 0.0, 0.55, 4.2, 6.8, bed_c.darkened(0.2), bed_c)
	p.box(1.1, 3.0, 0.55, 0.75, 6.3, 6.8, Color(0.85, 0.82, 0.8))
	for post in [Vector2(1.1, 4.2), Vector2(1.1, 6.8)]:
		p.box(post.x, post.x + 0.08, 0.0, 2.8, post.y, post.y + 0.08, wood)
	p.box(1.1, 3.0, 2.7, 2.85, 4.2, 6.85, lilac.darkened(0.2))
	p.poly3([Vector3(1.12, 2.7, 4.25), Vector3(1.12, 2.7, 5.0), Vector3(1.12, 0.6, 4.9), Vector3(1.12, 0.6, 4.25)], lilac)
	p.poly3([Vector3(1.12, 2.7, 6.05), Vector3(1.12, 2.7, 6.8), Vector3(1.12, 0.6, 6.8), Vector3(1.12, 0.6, 6.2)], lilac)
	# A marca do corpo dela, no lençol.
	if State.gore:
		var b := p.proj(Vector3(1.9, 0.56, 5.3))
		draw_set_transform(b, 0, Vector2(1, 0.4))
		draw_circle(Vector2.ZERO, 10, Color(0.38, 0.02, 0.05))
		draw_set_transform(Vector2.ZERO)
	if State.is_solved("caixa"):
		hot(box_r.grow(4), "look", "look:musicbox_after", "Caixa de música")
	else:
		hot(box_r.grow(4), "puzzle", "puzzle:caixa", "Caixa de música")
	hot(Rect2(jar - Vector2(jar_r * 1.4, jar_r * 3.0), Vector2(jar_r * 2.8, jar_r * 3.2)), "voice", "event:voice_jar", "Um vidro")
	hot(p.rect_of(inner), "look", "look:vanity_mirror", "Espelho oval")
	hot_back("go:corridor", "Voltar ao corredor")


func paint_live(o: Node2D) -> void:
	# Dentro do vidro, uma coisa pálida vibra como corda de violino.
	if jar_r > 0.0:
		var v := sin(t * 40.0) * 0.6
		var c := jar + Vector2(0, -jar_r * 1.2)
		o.draw_circle(c + Vector2(v, 0), jar_r * 0.6, Color(0.8, 0.45, 0.45, 0.9))
		o.draw_line(c + Vector2(v, -jar_r * 0.6), c + Vector2(-v, jar_r * 0.6), Color(0.6, 0.15, 0.15), 1.0)
		o.draw_circle(c, jar_r * 1.8, Color(0.6, 0.95, 0.9, 0.06 + 0.04 * sin(t * 3.0)))
