extends "res://scripts/house/view.gd"
## Câmara fria: azulejo branco encardido, geada, ralos no chão e, nos trilhos
## do teto, corpos embrulhados em lençol pendurados em ganchos.

var bodies: Array = []
var turn_t := -1.0


func _init() -> void:
	id = "cold_room"
	title = "Câmara fria"
	music = "poroes"
	grade = "poroes"
	lantern = true


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.36
	p.fog = Color(0.02, 0.03, 0.05)
	p.fog_start = 3.0
	p.fog_len = 9.0
	var tile := Color(0.56, 0.6, 0.62)
	var grout := Color(0.32, 0.36, 0.4)
	p.add_light(Vector3(0, 2.6, 5.0), Color(0.6, 0.78, 1.0), 4.5, 0.9, 0.05, 160.0)
	p.floor_plane(-2.6, 2.6, 0.4, 8.0, 3.0, Color(0.2, 0.22, 0.24), Color(0.1, 0.1, 0.12), "", 8)
	p.back_wall(8.0, -2.6, 2.6, 0.0, 3.0, tile)
	for side in [-2.6, 2.6]:
		p.side_wall(side, 0.4, 8.0, 0.0, 3.0, tile, 14)
		# Juntas dos azulejos.
		for i in 12:
			var y := i * 0.25
			p.line3(Vector3(side, y, 0.4), Vector3(side, y, 8.0), grout, 1.0)
		var z := 0.5
		while z < 8.0:
			p.line3(Vector3(side, 0.0, z), Vector3(side, 3.0, z), grout, 1.0)
			z += 0.5
	for i in 12:
		p.line3(Vector3(-2.6, i * 0.25, 7.99), Vector3(2.6, i * 0.25, 7.99), grout, 1.0)
	for i in 11:
		p.line3(Vector3(-2.5 + i * 0.5, 0.0, 7.99), Vector3(-2.5 + i * 0.5, 3.0, 7.99), grout, 1.0)
	p.floor_plane(-2.6, 2.6, 0.4, 8.0, 0.0, Color(0.42, 0.44, 0.46), Color(0.34, 0.36, 0.38), "tiles", 12)
	# Ralos no chão: as marcas onde os ganchos devem descer.
	for dz in [3.2, 5.0, 6.6]:
		var d := p.proj(Vector3(-0.6 + dz * 0.2, 0.0, dz))
		var r := p.scale_at(dz) * 0.14
		draw_set_transform(d, 0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, r, Color(0.06, 0.06, 0.07))
		draw_set_transform(Vector2.ZERO)
		if State.gore:
			draw_line(d + Vector2(r * 0.6, 0), d + Vector2(r * 2.2, r * 0.3), Color(0.4, 0.0, 0.03), 1.0)
	# Geada nos cantos e pingentes no teto.
	for i in 16:
		var x := -2.5 + i * 0.33
		p.line3(Vector3(x, 3.0, 7.98), Vector3(x, 2.75 - (i % 3) * 0.12, 7.98), Color(0.85, 0.92, 1.0), 1.0)
	# Trilhos no teto e os corpos pendurados.
	for rx in [-1.2, 1.2]:
		p.box(rx - 0.05, rx + 0.05, 2.85, 2.92, 1.2, 8.0, Color(0.4, 0.42, 0.45))
	bodies.clear()
	for k in 6:
		var rx: float = [-1.2, 1.2][k % 2]
		var z := 2.2 + int(k / 2) * 1.8 + (k % 2) * 0.5
		bodies.append(Vector3(rx, 2.85, z))
	# Mesa de inox à direita, com serras.
	p.box(1.6, 2.5, 0.0, 0.9, 2.0, 3.4, Color(0.5, 0.52, 0.55), Color(0.62, 0.64, 0.68))
	p.line3(Vector3(1.8, 0.91, 2.4), Vector3(2.3, 0.91, 2.6), Color(0.75, 0.76, 0.8), 2.0)
	if State.gore:
		for i in 6:
			var bp := p.proj(Vector3(1.7 + i * 0.12, 0.91, 2.2 + (i % 3) * 0.3))
			draw_rect(Rect2(bp, Vector2(3, 1)), Color(0.42, 0.0, 0.03))
	var floor_rect := p.rect_of([Vector3(-1.8, 0.0, 2.5), Vector3(1.8, 0.0, 7.5)]).grow(4)
	if State.is_solved("ganchos"):
		hot(floor_rect, "look", "look:cold_after", "Os ralos")
	else:
		hot(floor_rect, "puzzle", "puzzle:ganchos", "Os ganchos e os ralos")
	hot(p.box_rect(1.6, 2.5, 0.0, 0.9, 2.0, 3.4), "look", "look:steel_table", "Mesa de inox")
	hot_back("go:cellar", "Voltar à galeria")


func paint_live(o: Node2D) -> void:
	if p == null:
		return
	if turn_t >= 0.0:
		turn_t += get_process_delta_time()
		if turn_t > 3.0:
			turn_t = -1.0
	for i in bodies.size():
		var top: Vector3 = bodies[i]
		var sway := sin(t * 0.6 + i * 1.9) * 0.04
		var a := p.proj(top)
		var hook := p.proj(top + Vector3(sway, -0.35, 0))
		var s := p.scale_at(top.z) / 60.0
		o.draw_line(a, hook, Color(0.3, 0.32, 0.34), 1.0)
		var sheet := Color(0.7, 0.7, 0.66) if i % 3 else Color(0.62, 0.6, 0.55)
		var b := PackedVector2Array([hook + Vector2(-4, 2) * s, hook + Vector2(4, 2) * s, hook + Vector2(8, 22) * s, hook + Vector2(7, 52) * s, hook + Vector2(2, 62) * s, hook + Vector2(-3, 62) * s, hook + Vector2(-8, 50) * s, hook + Vector2(-8, 20) * s])
		o.draw_colored_polygon(b, sheet.darkened(0.25 + 0.06 * (top.z - 2.0)))
		# A corda que amarra o lençol.
		for yy in [16.0, 34.0, 50.0]:
			o.draw_line(hook + Vector2(-8, yy) * s, hook + Vector2(8, yy - 1) * s, Color(0.35, 0.3, 0.22), 1.0)
		if State.gore:
			o.draw_rect(Rect2(hook + Vector2(-2, 20) * s, Vector2(4, 12) * s), Color(0.45, 0.02, 0.04, 0.7))
			o.draw_rect(Rect2(hook + Vector2(0, 62) * s, Vector2(1, 2 + fmod(t * 4.0 + i * 3.0, 6.0))), Color(0.45, 0.0, 0.03))
		# Um deles vira a cabeça embrulhada para a lamparina.
		if i == 2 and turn_t >= 0.0:
			var k := clampf(turn_t / 0.6, 0.0, 1.0)
			o.draw_rect(Rect2(hook + Vector2(-2 + 3 * k, 6) * s, Vector2(2, 1) * s), Color(0.02, 0.0, 0.0))
	# A respiração de Dália condensa no frio.
	var breath := fmod(t * 0.35, 1.0)
	if breath < 0.5:
		for i in 6:
			var k2 := breath * 2.0
			var bp := Vector2(320 + sin(i * 2.1 + t) * 10.0 * k2, 340 - k2 * 50.0 - i * 4.0)
			o.draw_circle(bp, 4.0 + k2 * 10.0, Color(0.85, 0.9, 1.0, 0.05 * (1.0 - k2)))


func entered(house) -> void:
	if not State.flag("cold_seen"):
		State.set_flag("cold_seen")
		turn_t = 0.0
		Audio.play("ice", -6.0)
		Audio.play("sting", -10.0, 0.9)
		house.subs.say("DÁLIA", "Corpos embrulhados em lençóis, pendurados em ganchos. Um deles virou para a luz. Eu vi.")
		house.subs.say("MORVANT", "A despensa de inverno. Desça os ganchos sobre os ralos. Eles pingam menos assim.")
		State.change_sanity(-4.0)
	elif randf() < 0.3 + State.madness() * 0.5:
		turn_t = 0.0
		Audio.play("ice", -12.0, 0.8)
