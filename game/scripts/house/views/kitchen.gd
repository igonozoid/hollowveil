extends "res://scripts/house/view.gd"
## Cozinha: fogão a lenha, ganchos com carne, a mesa do açougue e a
## despensa dos potes. A escada de serviço sobe para os quartos.

var stove_rect := Rect2()
var swing := 0.0
var hook_pts: Array = []


func _init() -> void:
	id = "kitchen"
	title = "Cozinha"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.44
	p.fog = Color(0.02, 0.012, 0.008)
	p.add_light(Vector3(0, 0.7, 7.2), Color(1.0, 0.42, 0.15), 5.5, 1.5, 0.35, 150.0)
	var stone := Color(0.3, 0.27, 0.24)
	var wood := Color(0.27, 0.16, 0.09)
	p.floor_plane(-3, 3, 0.4, 8, 3.6, Color(0.1, 0.07, 0.05), Color(0.04, 0.03, 0.02), "", 8)
	p.back_wall(8, -3, 3, 0, 3.6, stone)
	p.side_wall(-3, 0.4, 8, 0, 3.6, stone)
	p.side_wall(3, 0.4, 8, 0, 3.6, stone)
	# Juntas das pedras
	for i in 9:
		var y := 0.4 * i
		p.line3(Vector3(-3, y, 8), Vector3(3, y, 8), stone.darkened(0.4), 1.0)
		p.line3(Vector3(-3, y, 0.4), Vector3(-3, y, 8), stone.darkened(0.4), 1.0)
		p.line3(Vector3(3, y, 0.4), Vector3(3, y, 8), stone.darkened(0.4), 1.0)
	p.floor_plane(-3, 3, 0.4, 8, 0.0, Color(0.28, 0.24, 0.2), Color(0.2, 0.17, 0.14), "tiles", 12)
	# Vigas e ganchos
	p.box(-3, 3, 3.3, 3.45, 4.0, 4.2, wood.darkened(0.2))
	hook_pts.clear()
	for x in [-1.3, -0.4, 0.6, 1.5]:
		hook_pts.append(Vector3(x, 3.3, 4.1))
	# Fogão a lenha no fundo
	p.box(-1.5, 1.5, 0.0, 0.9, 6.8, 8.0, Color(0.1, 0.09, 0.09), Color(0.18, 0.16, 0.15))
	p.poly3([Vector3(-0.8, 0.15, 6.79), Vector3(0.8, 0.15, 6.79), Vector3(0.8, 0.6, 6.79), Vector3(-0.8, 0.6, 6.79)], Color(0.02, 0.0, 0.0), false)
	stove_rect = p.rect_of([Vector3(-0.8, 0.15, 6.79), Vector3(0.8, 0.6, 6.79)])
	p.box(-0.3, 0.3, 0.9, 3.6, 7.5, 8.0, Color(0.14, 0.12, 0.12))
	# Panelão sobre o fogão
	p.box(-0.9, -0.3, 0.9, 1.25, 7.0, 7.5, Color(0.2, 0.2, 0.22))
	# Despensa (parede direita): prateleiras de potes
	var pantry := p.box_rect(2.3, 3.0, 0.0, 2.4, 4.0, 6.4)
	for s in 4:
		var y := 0.3 + s * 0.55
		p.box(2.4, 3.0, y, y + 0.04, 4.1, 6.3, wood)
		for j in 6:
			var z := 4.25 + j * 0.34
			var jar := Color(0.55, 0.6, 0.4, 1.0)
			p.box(2.55, 2.8, y + 0.04, y + 0.34, z, z + 0.22, jar.darkened(0.35), jar.darkened(0.1))
			if not State.is_solved("olhos") or (s + j) % 3 == 0:
				var e := p.proj(Vector3(2.55, y + 0.18, z + 0.11))
				draw_rect(Rect2(e - Vector2(1, 1), Vector2(3, 3)), Color(0.85, 0.82, 0.72))
				draw_rect(Rect2(e, Vector2(1, 1)), Color(0.15, 0.25, 0.4))
	# Porta da escada de serviço (parede esquerda)
	var open := State.is_solved("olhos")
	var stair_door := p.door_side(-3, 4.6, 1.0, 2.2, wood, open)
	# Mesa do açougue com cutelo
	# Fica de lado, para não esconder o fogão (as chamas são desenhadas por cima).
	p.box(0.45, 1.85, 0.0, 0.85, 3.4, 4.0, wood, Color(0.42, 0.28, 0.18))
	p.poly3([Vector3(0.7, 0.86, 3.55), Vector3(1.2, 0.86, 3.55), Vector3(1.2, 0.86, 3.8), Vector3(0.7, 0.86, 3.8)], Color(0.6, 0.62, 0.66))
	p.line3(Vector3(1.2, 0.87, 3.67), Vector3(1.55, 0.87, 3.67), wood.darkened(0.3), 2.0)
	p.candle(Vector3(1.7, 0.86, 3.9), 0.12, true, 2.2, 0.8)
	if State.gore:
		for i in 8:
			var bp := p.proj(Vector3(0.55 + i * 0.15, 0.86, 3.45 + (i % 3) * 0.18))
			draw_rect(Rect2(bp, Vector2(3, 1)), Color(0.4, 0.0, 0.02))
		for i in 5:
			var fp := p.proj(Vector3(0.3 + i * 0.3, 0.0, 2.6 + (i % 2) * 0.4))
			draw_rect(Rect2(fp, Vector2(4, 1)), Color(0.35, 0.0, 0.02))
	if open:
		hot(stair_door, "walk", "event:stairs_up", "Escada de serviço")
		hot(pantry, "look", "look:pantry_after", "Despensa")
	else:
		hot(stair_door, "locked", "locked:service", "Escada de serviço")
		hot(pantry, "puzzle", "puzzle:olhos", "Despensa")
	hot(stove_rect, "look", "look:stove", "Fogão")
	hot_back("go:dining", "Voltar à sala de jantar")


func paint_live(o: Node2D) -> void:
	# Brasas do fogão
	if stove_rect.size.x > 0.0:
		for i in 9:
			var x := stove_rect.position.x + stove_rect.size.x * (0.08 + i * 0.105)
			var h := stove_rect.size.y * (0.3 + 0.3 * absf(sin(t * (4.0 + i * 0.7) + i)))
			var b := stove_rect.end.y
			o.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, b), Vector2(x, b - h), Vector2(x + 3, b)]), Color(1.0, 0.4 + 0.15 * sin(t * 8.0 + i), 0.1))
	# Carnes balançando nos ganchos.
	if p == null:
		return
	for i in hook_pts.size():
		var hp: Vector3 = hook_pts[i]
		var top := p.proj(hp)
		var sw := sin(t * 1.1 + i * 1.7) * 0.06
		var hook := p.proj(hp + Vector3(sw, -0.45, 0))
		o.draw_line(top, hook, Color(0.25, 0.24, 0.24), 1.0)
		var s := p.scale_at(hp.z) / 80.0
		var col := Color(0.42, 0.12, 0.1) if i % 2 == 0 else Color(0.5, 0.3, 0.26)
		var body := PackedVector2Array([hook + Vector2(-5, 2) * s, hook + Vector2(5, 2) * s, hook + Vector2(7, 22) * s, hook + Vector2(2, 36) * s, hook + Vector2(-3, 36) * s, hook + Vector2(-7, 20) * s])
		o.draw_colored_polygon(body, col)
		o.draw_line(hook + Vector2(0, 6) * s, hook + Vector2(0, 32) * s, Color(0.82, 0.74, 0.62), maxf(1.0, s))
		if State.gore:
			o.draw_rect(Rect2(hook + Vector2(0, 36) * s, Vector2(1, 3 + fmod(t * 6.0 + i * 3.0, 8.0))), Color(0.5, 0.0, 0.02))
