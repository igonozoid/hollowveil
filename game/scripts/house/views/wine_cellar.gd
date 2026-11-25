extends "res://scripts/house/view.gd"
## Adega: barris deitados dos dois lados, garrafeira no fundo e, no meio, a
## balança de latão de Morvant com nove potes de órgãos em fila.

const Cellar := preload("res://scripts/house/views/cellar.gd")

var spigot := Vector2()
var beam_at := Vector2()
var beam_s := 1.0


func _init() -> void:
	id = "wine_cellar"
	title = "Adega"
	music = "poroes"
	grade = "poroes"
	lantern = true


## Tampo redondo de barril numa parede lateral (plano x constante).
func barrel_end(x: float, yc: float, zc: float, r: float, wood: Color) -> void:
	var pts: Array = []
	for i in 14:
		var a := TAU * i / 14.0
		pts.append(Vector3(x, yc + sin(a) * r, zc + cos(a) * r))
	p.poly3(pts, wood)
	var inner: Array = []
	for i in 14:
		var a := TAU * i / 14.0
		inner.append(Vector3(x, yc + sin(a) * r * 0.8, zc + cos(a) * r * 0.8))
	for i in 14:
		p.line3(inner[i], inner[(i + 1) % 14], wood.darkened(0.45), 1.0)
	for k in 3:
		var dz := (k - 1) * r * 0.45
		p.line3(Vector3(x, yc - r * 0.75, zc + dz), Vector3(x, yc + r * 0.75, zc + dz), wood.darkened(0.3), 1.0)


func paint() -> void:
	p.cy = 156.0
	p.ambient = 0.38
	p.fog = Color(0.012, 0.01, 0.02)
	p.fog_start = 3.0
	p.fog_len = 9.0
	var stone := Color(0.3, 0.27, 0.28)
	var wood := Color(0.36, 0.2, 0.12)
	p.add_light(Vector3(0.3, 1.4, 4.6), Color(1.0, 0.62, 0.32), 3.0, 1.0, 0.3)
	Cellar.vault(p, -2.8, 2.8, 2.2, 1.0, 0.4, 8.0, stone.darkened(0.2), 10)
	p.back_wall(8.0, -2.8, 2.8, 0.0, 3.2, stone)
	for side in [-2.8, 2.8]:
		p.side_wall(side, 0.4, 8.0, 0.0, 2.2, stone, 14)
		Cellar.stones_side(p, side, 0.4, 8.0, 2.2, stone.darkened(0.45))
	p.floor_plane(-2.8, 2.8, 0.4, 8.0, 0.0, Color(0.2, 0.17, 0.16), Color(0.14, 0.12, 0.11), "tiles", 12)
	# Garrafeira no fundo: favos com gargalos.
	p.box(-2.0, 2.0, 0.0, 2.1, 7.6, 8.0, wood.darkened(0.4))
	for row in 7:
		for col in 14:
			var bp := Vector3(-1.85 + col * 0.28, 0.2 + row * 0.28, 7.59)
			var c := p.proj(bp)
			var r := p.scale_at(7.6) * 0.09
			draw_circle(c, r, p.shade(Color(0.06, 0.1, 0.06), bp))
			if (row * 5 + col * 3) % 7 == 0:
				draw_rect(Rect2(c + Vector2(-1, -1), Vector2(1, 1)), p.shade(Color(0.9, 0.85, 0.7), bp))
	# Barris deitados, dois andares de cada lado.
	for side in [-1, 1]:
		var x: float = side * 2.1
		p.box(minf(x, side * 2.8), maxf(x, side * 2.8), 0.0, 0.12, 2.4, 7.4, wood.darkened(0.5))
		for k in 5:
			var zc := 2.9 + k * 0.92
			for row in 2:
				var r := 0.4
				barrel_end(x, 0.12 + r + row * (r * 2.0 + 0.04), zc, r, wood if (k + row) % 2 == 0 else wood.darkened(0.12))
	# Torneira que pinga (barril de baixo, esquerda, o mais perto).
	p.line3(Vector3(-2.1, 0.5, 2.9), Vector3(-1.95, 0.5, 2.9), Color(0.55, 0.42, 0.2), 2.0)
	spigot = p.proj(Vector3(-1.95, 0.48, 2.9))
	var puddle := p.proj(Vector3(-1.8, 0.0, 3.0))
	draw_set_transform(puddle, 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, p.scale_at(2.1) * 0.35, p.shade(Color(0.32, 0.02, 0.06), Vector3(-1.6, 0.0, 2.1)))
	draw_set_transform(Vector2.ZERO)
	# Mesa com a balança e os potes.
	p.box(-1.1, 1.1, 0.0, 0.85, 4.2, 5.0, wood, wood.lightened(0.15))
	for jx in 9:
		var x0 := -0.98 + jx * 0.22
		var jar := Color(0.5, 0.56, 0.42)
		if State.is_solved("balanca") and jx == 4:
			continue
		p.box(x0, x0 + 0.15, 0.85, 1.07, 4.25, 4.4, jar.darkened(0.3), jar)
		var o := p.proj(Vector3(x0 + 0.075, 0.95, 4.25))
		draw_circle(o, maxf(1.0, p.scale_at(4.3) * 0.04), p.shade(Color(0.55, 0.12, 0.14), Vector3(x0, 0.95, 4.25)))
	# Balança: coluna, travessão e pratos (o travessão é desenhado vivo).
	p.line3(Vector3(0, 0.85, 4.75), Vector3(0, 1.55, 4.75), Color(0.65, 0.5, 0.24), 2.0)
	p.box(-0.12, 0.12, 0.85, 0.9, 4.65, 4.85, Color(0.55, 0.42, 0.2))
	beam_at = p.proj(Vector3(0, 1.55, 4.75))
	beam_s = p.scale_at(4.75) / 60.0
	var scale_rect := p.rect_of([Vector3(-1.1, 0.85, 4.2), Vector3(1.1, 1.7, 4.8)])
	if State.is_solved("balanca"):
		hot(scale_rect, "look", "look:scale_after", "A balança")
	else:
		hot(scale_rect, "puzzle", "puzzle:balanca", "A balança dos potes")
	hot(p.rect_of([Vector3(-2.8, 0.1, 2.5), Vector3(-2.1, 1.8, 7.4)]), "look", "look:barrels", "Barris")
	hot_back("go:cellar", "Voltar à galeria")


func paint_live(o: Node2D) -> void:
	# A torneira pinga. Vinho, diz a etiqueta.
	var k := fmod(t * 0.9, 1.0)
	o.draw_rect(Rect2(spigot + Vector2(0, k * 26.0), Vector2(1, 2)), Color(0.5, 0.0, 0.05))
	# O travessão oscila, como se alguém tocasse um prato.
	var tilt := sin(t * 0.7) * 0.05 + (0.0 if State.is_solved("balanca") else sin(t * 2.3) * 0.02)
	var s := beam_s
	var half := Vector2(cos(tilt), sin(tilt)) * 34.0 * s
	var brass := Color(0.75, 0.58, 0.28)
	o.draw_line(beam_at - half, beam_at + half, brass, maxf(1.0, 2.0 * s))
	for e in [beam_at - half, beam_at + half]:
		o.draw_line(e, e + Vector2(-7, 14) * s, brass.darkened(0.3), 1.0)
		o.draw_line(e, e + Vector2(7, 14) * s, brass.darkened(0.3), 1.0)
		o.draw_line(e + Vector2(-9, 14) * s, e + Vector2(9, 14) * s, brass, maxf(1.0, 2.0 * s))


func entered(house) -> void:
	if not State.flag("adega_seen"):
		State.set_flag("adega_seen")
		house.subs.say("DÁLIA", "Uma balança de farmacêutico no meio da adega. Nove potes enfileirados, e uma coisa dentro de cada um.")
		house.subs.say("MORVANT", "Um deles ainda bate, médium. Ache o mais pesado. A culpa pesa, sabia?")
