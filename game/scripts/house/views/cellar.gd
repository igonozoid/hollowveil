extends "res://scripts/house/view.gd"
## Galeria dos porões: túnel de pedra em abóbada, ao pé da escada do alçapão.
## A adega à esquerda, a câmara fria à direita e, no fundo, o portão de ferro
## da capela, com velas acesas e um padre ajoelhado do outro lado.

var priest_at := Vector2()
var priest_s := 1.0
var gate_rect := Rect2()


func _init() -> void:
	id = "cellar"
	title = "Galeria dos porões"
	music = "poroes"
	grade = "poroes"
	lantern = true


## Abóbada de berço entre z0 e z1 (meio cilindro deitado ao longo de z).
static func vault(p, x0: float, x1: float, spring: float, rise: float, z0: float, z1: float, col: Color, slices: int = 12) -> void:
	var r := (x1 - x0) * 0.5
	var xc := (x0 + x1) * 0.5
	var dz := (z1 - z0) / slices
	for s in slices:
		var za := z0 + s * dz
		var zb := za + dz
		for i in 8:
			var a0 := PI * i / 8.0
			var a1 := PI * (i + 1) / 8.0
			var pa := Vector3(xc + cos(a0) * r, spring + sin(a0) * rise, za)
			var pb := Vector3(xc + cos(a1) * r, spring + sin(a1) * rise, za)
			p.poly3([pa, pb, Vector3(pb.x, pb.y, zb), Vector3(pa.x, pa.y, zb)], col.darkened(0.08 * (i % 2)))


## Juntas de pedra numa parede lateral.
static func stones_side(p, x: float, z0: float, z1: float, h: float, col: Color) -> void:
	var y := 0.0
	var row := 0
	while y < h:
		p.line3(Vector3(x, y, z0), Vector3(x, y, z1), col, 1.0)
		var z := z0 + (0.35 if row % 2 == 0 else 0.0)
		while z < z1:
			p.line3(Vector3(x, y, z), Vector3(x, minf(y + 0.32, h), z), col, 1.0)
			z += 0.7
		y += 0.32
		row += 1


func paint() -> void:
	p.cy = 156.0
	p.ambient = 0.3
	p.fog = Color(0.01, 0.012, 0.025)
	p.fog_start = 3.0
	p.fog_len = 10.0
	var stone := Color(0.3, 0.3, 0.33)
	var joint := Color(0.16, 0.16, 0.2)
	var gate_open := State.has("chave_capela")
	p.add_light(Vector3(-1.75, 1.7, 3.0), Color(1.0, 0.6, 0.3), 2.8, 0.8, 0.35)
	# Velas da capela, do outro lado do portão.
	p.add_light(Vector3(0, 1.0, 12.5), Color(1.0, 0.66, 0.34), 3.2, 1.2, 0.3, 70.0)
	vault(p, -1.8, 1.8, 2.3, 1.0, 0.4, 11.0, stone.darkened(0.15))
	p.back_wall(11.0, -1.8, 1.8, 0.0, 3.3, stone)
	for side in [-1.8, 1.8]:
		p.side_wall(side, 0.4, 11.0, 0.0, 2.3, stone, 22)
		stones_side(p, side, 0.4, 11.0, 2.3, joint)
	p.floor_plane(-1.8, 1.8, 0.4, 11.0, 0.0, Color(0.22, 0.22, 0.24), Color(0.17, 0.17, 0.19), "tiles", 18)
	# Poças que refletem a vela.
	for pz in [2.4, 5.8, 8.3]:
		var c := p.proj(Vector3(0.4 - pz * 0.08, 0.0, pz))
		var w := p.scale_at(pz) * 0.35
		draw_set_transform(c, 0, Vector2(1, 0.22))
		draw_circle(Vector2.ZERO, w, p.shade(Color(0.12, 0.13, 0.2), Vector3(0, 0, pz)))
		draw_set_transform(Vector2.ZERO)
	# Arandela com vela, à esquerda.
	p.box(-1.8, -1.7, 1.45, 1.52, 2.94, 3.06, Color(0.4, 0.3, 0.16))
	p.candle(Vector3(-1.74, 1.52, 3.0), 0.12, true, 2.8, 0.7)
	# Ossário: nichos com crânios nas paredes, perto do fundo.
	for side in [-1.8, 1.8]:
		for k in 3:
			var z := 7.6 + k * 1.1
			for row in 2:
				var y := 0.5 + row * 0.75
				var dx := 0.01 if side < 0 else -0.01
				p.poly3([Vector3(side + dx, y, z), Vector3(side + dx, y, z + 0.8), Vector3(side + dx, y + 0.5, z + 0.8), Vector3(side + dx, y + 0.5, z)], Color(0.04, 0.035, 0.04))
				for sk in 3:
					var sp := Vector3(side + dx * 4.0, y + 0.14, z + 0.15 + sk * 0.25)
					var c2 := p.proj(sp)
					var r2 := p.scale_at(sp.z) * 0.08
					var bone := p.shade(Color(0.72, 0.66, 0.54), sp)
					draw_circle(c2, r2, bone)
					draw_rect(Rect2(c2 + Vector2(-r2 * 0.6, -r2 * 0.2), Vector2(maxf(1, r2 * 0.4), maxf(1, r2 * 0.35))), Color(0.03, 0.02, 0.02))
					draw_rect(Rect2(c2 + Vector2(r2 * 0.2, -r2 * 0.2), Vector2(maxf(1, r2 * 0.4), maxf(1, r2 * 0.35))), Color(0.03, 0.02, 0.02))
	var ossuary := p.rect_of([Vector3(-1.8, 0.4, 7.6), Vector3(-1.8, 1.8, 10.8)])
	# Portas: adega (madeira, esquerda) e câmara fria (zinco, direita).
	var adega := p.door_side(-1.8, 4.6, 1.0, 2.0, Color(0.3, 0.17, 0.1), false)
	var fria := p.door_side(1.8, 5.4, 1.0, 2.1, Color(0.42, 0.46, 0.5), false)
	# Geada escorrendo pela porta da câmara fria.
	for k in 7:
		var z := 4.95 + k * 0.13
		p.line3(Vector3(1.79, 2.1, z), Vector3(1.79, 2.1 - 0.2 - (k % 3) * 0.25, z), Color(0.8, 0.88, 0.95), 1.0)
	# Portão da capela, no fundo: arco aberto, velas e grades.
	var arch := p.door_back(0, 11.0, 1.3, 2.2, stone.darkened(0.3), true, true)
	gate_rect = arch
	for dx in [-0.35, 0.35]:
		p.candle(Vector3(dx, 0.9, 13.0), 0.2, true, 2.4, 0.5)
	p.box(-0.5, 0.5, 0.0, 0.9, 13.0, 13.6, Color(0.7, 0.68, 0.62))
	p.line3(Vector3(0, 1.3, 13.6), Vector3(0, 2.0, 13.6), Color(0.6, 0.46, 0.22), 2.0)
	p.line3(Vector3(-0.18, 1.8, 13.6), Vector3(0.18, 1.8, 13.6), Color(0.6, 0.46, 0.22), 2.0)
	priest_at = p.proj(Vector3(0.1, 0.0, 12.4))
	priest_s = p.scale_at(12.4) / 60.0
	if not gate_open:
		for i in 9:
			var x := -0.62 + i * 0.155
			p.line3(Vector3(x, 0.0, 10.98), Vector3(x, 2.2 + 0.6 * sqrt(maxf(0.0, 1.0 - pow(x / 0.65, 2.0))), 10.98), Color(0.1, 0.09, 0.09), 2.0, false)
		p.line3(Vector3(-0.65, 1.1, 10.97), Vector3(0.65, 1.1, 10.97), Color(0.1, 0.09, 0.09), 2.0, false)
		p.box(-0.08, 0.08, 1.0, 1.2, 10.9, 10.97, Color(0.3, 0.26, 0.2))
	# Rastro de sangue da câmara fria até a capela.
	if State.gore:
		for i in 14:
			var z := 5.4 + i * 0.4
			var fp := p.proj(Vector3(1.3 - i * 0.09 + sin(i * 1.7) * 0.08, 0.0, z))
			draw_rect(Rect2(fp, Vector2(maxf(1, p.scale_at(z) * 0.09), 1)), p.shade(Color(0.45, 0.0, 0.03), Vector3(0, 0, z)))
	hot(adega, "walk", "go:wine_cellar", "Adega")
	hot(fria, "walk", "go:cold_room", "Câmara fria")
	if gate_open:
		hot(gate_rect, "walk", "go:chapel", "Capela")
	else:
		hot(gate_rect, "locked", "locked:chapel_gate", "Portão da capela")
	hot(ossuary, "look", "look:ossuary", "Ossário")
	hot_back("go:kitchen", "Subir à cozinha")


func paint_live(o: Node2D) -> void:
	# O padre reza ajoelhado do outro lado do portão (até ser libertado).
	if State.is_solved("vitral"):
		return
	var s := priest_s
	var bob := sin(t * 1.3) * 0.6
	var c := Color(0.62, 0.95, 0.9, 0.35 + 0.1 * sin(t * 2.0))
	var base := priest_at
	o.draw_rect(Rect2(base + Vector2(-5, -14 + bob) * s, Vector2(10, 14) * s), c)
	o.draw_circle(base + Vector2(1, -18 + bob) * s, 3.2 * s, c)
	o.draw_rect(Rect2(base + Vector2(-1, -15 + bob) * s, Vector2(2, 1) * s), Color(0.95, 0.95, 0.95, 0.5))
	o.draw_line(base + Vector2(3, -12 + bob) * s, base + Vector2(6, -16 + bob) * s, c, maxf(1.0, s))


func entered(house) -> void:
	if not State.flag("cellar_seen"):
		State.set_flag("cellar_seen")
		Audio.play("bell", -6.0, 0.9)
		house.subs.say("DÁLIA", "Peguei a lamparina da cozinha. A luz não passa de um palmo à minha frente.")
		house.subs.say("DÁLIA", "No fundo, atrás de um portão, alguém reza ajoelhado. Não se vira.")
		house.subs.say("MORVANT", "As fundações da casa, médium. Aqui embaixo os mortos não sussurram. Eles rezam.")
		State.change_sanity(-3.0)
	elif randf() < 0.2 + State.madness() * 0.4:
		Audio.play("bell", -14.0, 0.7)
