extends "res://scripts/puzzles/puzzle.gd"
## O LUAR — o mecanismo do relógio visto de frente, em grade. A lua entra
## pelo mostrador, à esquerda; o olho de vidro que acende a porta do teatro
## fica numa das bordas. Dália tem um punhado de espelhos para pôr nos vãos
## entre as engrenagens. Alguns espelhos já estão presos ao mecanismo e não
## giram. A semente traça um caminho que funciona e enche o resto de
## engrenagens; qualquer caminho que chegue ao olho vale.

const GW := 9
const GH := 6
const CELL := 34
const ORIGIN := Vector2(167, 64)
const E := Vector2i(1, 0)
const N := Vector2i(0, -1)
const W := Vector2i(-1, 0)
const S := Vector2i(0, 1)

var gears := {}             # célula → true
var fixed := {}             # célula → "/" ou "\\"
var placed := {}            # célula → "/" ou "\\"
var solution := {}          # espelhos do caminho gerado (para os testes e a pista)
var src_row := 0
var eye := Vector2i()       # célula fora da grade
var stock := 0
var beam: Array = []        # pontos do feixe na tela
var hit := false
var hint_cells: Array = []


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("luar")
	generate(rng)
	if State.flag("hint2_luar"):
		var keys: Array = solution.keys()
		for k in mini(2, keys.size()):
			hint_cells.append(keys[k])
	if State.drafts.has("luar"):
		for item in State.drafts["luar"]:
			var c := Vector2i(int(item[0]), int(item[1]))
			if not gears.has(c) and not fixed.has(c) and placed.size() < stock:
				placed[c] = String(item[2])
	trace()


static func hint(level: int) -> String:
	if level == 1:
		return "Um espelho \"/\" vira o raio que vem da esquerda para cima; um \"\\\" vira para baixo. Comece pelo olho e volte até a lua."
	return "A prancheta marcou de azul duas casas onde o caminho precisa de um espelho."


static func turn(d: Vector2i, m: String) -> Vector2i:
	if m == "/":
		return Vector2i(-d.y, -d.x)
	return Vector2i(d.y, d.x)


func generate(rng: RandomNumberGenerator) -> void:
	for attempt in 3000:
		src_row = rng.randi_range(1, GH - 2)
		var pos := Vector2i(0, src_row)
		var d := E
		var path: Array = [pos]
		var seen := {pos: true}
		var turns := {}
		var since := 0
		var ok := false
		for step in 60:
			if since >= 1 and rng.randf() < 0.32:
				var nd := Vector2i(-d.y, d.x) if rng.randf() < 0.5 else Vector2i(d.y, -d.x)
				# O espelho que faz essa virada.
				var m := "/" if turn(d, "/") == nd else "\\"
				turns[pos] = m
				d = nd
				since = 0
			var nxt := pos + d
			since += 1
			if nxt.x < 0 or nxt.y < 0 or nxt.x >= GW or nxt.y >= GH:
				if nxt.x < 0:
					break
				if path.size() >= 13 and turns.size() >= 5:
					eye = nxt
					ok = true
				break
			if seen.has(nxt):
				break
			seen[nxt] = true
			path.append(nxt)
			pos = nxt
		if not ok:
			continue
		# Uma das viradas fica presa ao mecanismo; as outras são de Dália.
		fixed = {}
		solution = {}
		var tk: Array = turns.keys()
		var fixed_i := rng.randi() % tk.size()
		for i in tk.size():
			if i == fixed_i:
				fixed[tk[i]] = turns[tk[i]]
			else:
				solution[tk[i]] = turns[tk[i]]
		stock = solution.size()
		# Engrenagens nas casas fora do caminho, e dois espelhos presos que atrapalham.
		gears = {}
		var free_cells: Array = []
		for y in GH:
			for x in GW:
				var c := Vector2i(x, y)
				if not seen.has(c):
					free_cells.append(c)
		for c in free_cells:
			if rng.randf() < 0.42:
				gears[c] = true
		var decoys := 0
		for c in free_cells:
			if decoys < 2 and not gears.has(c) and rng.randf() < 0.15:
				fixed[c] = "/" if rng.randf() < 0.5 else "\\"
				decoys += 1
		placed = {}
		trace()
		if hit:
			continue
		placed = solution.duplicate()
		trace()
		var good := hit
		placed = {}
		trace()
		if good:
			return


func mirror_at(c: Vector2i) -> String:
	if fixed.has(c):
		return fixed[c]
	return placed.get(c, "")


## Segue o raio da lua; marca `hit` se ele sair da grade pelo olho.
func trace() -> void:
	beam = []
	hit = false
	var pos := Vector2i(0, src_row)
	var d := E
	beam.append(ORIGIN + Vector2(-30, (src_row + 0.5) * CELL))
	for step in 200:
		if pos.x < 0 or pos.y < 0 or pos.x >= GW or pos.y >= GH:
			hit = pos == eye
			beam.append(_center(pos) - Vector2(d) * CELL * 0.4)
			return
		if gears.has(pos):
			beam.append(_center(pos) - Vector2(d) * CELL * 0.5)
			return
		var m := mirror_at(pos)
		if m != "":
			beam.append(_center(pos))
			d = turn(d, m)
		pos += d
	beam.append(_center(pos))


func _center(c: Vector2i) -> Vector2:
	return ORIGIN + (Vector2(c) + Vector2(0.5, 0.5)) * CELL


func toggle(c: Vector2i) -> void:
	if done or gears.has(c) or fixed.has(c):
		return
	var cur: String = placed.get(c, "")
	if cur == "":
		if placed.size() >= stock:
			Audio.play("locked", -10.0)
			say("DÁLIA", "Não tenho mais espelhos. Preciso tirar um de outro lugar.")
			return
		placed[c] = "/"
	elif cur == "/":
		placed[c] = "\\"
	else:
		placed.erase(c)
	Audio.play("tile", -8.0, 1.5)
	var d: Array = []
	for k in placed:
		d.append([k.x, k.y, placed[k]])
	State.drafts["luar"] = d
	trace()
	if hit:
		State.drafts.erase("luar")
		Audio.play("bell", -2.0, 1.1)
		Audio.play("sting", -10.0, 1.4)
		shake(0.3)
		say("DÁLIA", "A lua atravessa o mecanismo e acerta o olho de vidro. Lá embaixo, no sótão, uma luz fria se acende sobre a porta do teatro.")
		finish()


func _gui_input(event: InputEvent) -> void:
	if done or not (event is InputEventMouseButton and event.pressed):
		return
	var c := Vector2i(((event.position - ORIGIN) / CELL).floor())
	if c.x < 0 or c.y < 0 or c.x >= GW or c.y >= GH:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if placed.has(c):
			placed.erase(c)
			Audio.play("tile", -10.0, 0.8)
			trace()
	elif event.button_index == MOUSE_BUTTON_LEFT:
		toggle(c)


func _draw_gear(c: Vector2, r: float, spin: float) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := spin + TAU * i / 20.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.82))
	draw_colored_polygon(pts, Color(0.24, 0.2, 0.15))
	draw_circle(c, r * 0.5, Color(0.17, 0.14, 0.1))
	draw_circle(c, r * 0.15, Color(0.4, 0.34, 0.24))


func _draw_mirror(c: Vector2, m: String, col: Color) -> void:
	var h := CELL * 0.38
	var a := c + (Vector2(-h, h) if m == "/" else Vector2(-h, -h))
	var b := c + (Vector2(h, -h) if m == "/" else Vector2(h, h))
	draw_line(a, b, col, 3.0)
	draw_line(a + Vector2(1, 1), b + Vector2(1, 1), Color(0.1, 0.1, 0.12), 1.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.022, 0.03))
	var font := get_theme_default_font()
	brass_frame(Rect2(ORIGIN - Vector2(6, 6), Vector2(GW * CELL + 12, GH * CELL + 12)), 2.0)
	for y in GH:
		for x in GW:
			var c := Vector2i(x, y)
			var r := Rect2(ORIGIN + Vector2(x, y) * CELL, Vector2(CELL, CELL))
			draw_rect(r, Color(0.06, 0.06, 0.075))
			draw_rect(r, Color(0.1, 0.1, 0.12), false, 1.0)
			if gears.has(c):
				_draw_gear(r.get_center(), CELL * 0.48, t * 0.4 * (1.0 if (x + y) % 2 == 0 else -1.0))
			elif fixed.has(c):
				draw_rect(r.grow(-3), Color(0.15, 0.13, 0.1))
				_draw_mirror(r.get_center(), fixed[c], Color(0.55, 0.55, 0.6))
				draw_circle(r.get_center(), 2, Color(0.6, 0.45, 0.2))
			elif placed.has(c):
				_draw_mirror(r.get_center(), placed[c], Color(0.85, 0.9, 1.0))
			if c in hint_cells:
				draw_rect(r.grow(-2), Color(0.4, 0.8, 1.0, 0.5), false, 1.0)
	# A lua no mostrador, à esquerda, e o olho na borda.
	var moon := ORIGIN + Vector2(-34, (src_row + 0.5) * CELL)
	draw_circle(moon, 14, Color(0.85, 0.9, 0.95))
	draw_circle(moon + Vector2(4, -3), 3, Color(0.7, 0.75, 0.8))
	var eye_p := _center(eye)
	draw_circle(eye_p, 11, Color(0.5, 0.4, 0.2))
	draw_circle(eye_p, 8, Color(0.9, 0.95, 1.0) if hit else Color(0.15, 0.08, 0.08))
	draw_circle(eye_p, 3.5, Color(0.1, 0.12, 0.3) if hit else Color(0.45, 0.05, 0.05))
	# O feixe, com poeira brilhando.
	var flick := 0.85 + 0.15 * sin(t * 13.0)
	for i in beam.size() - 1:
		draw_line(beam[i], beam[i + 1], Color(0.7, 0.8, 1.0, 0.25), 6.0)
		draw_line(beam[i], beam[i + 1], Color(0.92, 0.96, 1.0, flick), 2.0)
		var seg: Vector2 = beam[i + 1] - beam[i]
		for k in 3:
			var f := fmod(t * 0.3 + k * 0.33 + i * 0.17, 1.0)
			draw_rect(Rect2((beam[i] + seg * f + Vector2(sin(t * 3.0 + k) * 3.0, 0)).round(), Vector2(1, 1)), Color(1, 1, 1, 0.8))
	draw_string(font, Vector2(288, 20), "O LUAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(0, 300), "Espelhos na mão: %d de %d" % [stock - placed.size(), stock], HORIZONTAL_ALIGNMENT_CENTER, 640, 10, Color(0.9, 0.92, 1.0))
	draw_string(font, Vector2(0, 318), "Leve a lua até o olho. Clique num vão: \"/\", depois \"\\\", depois tira. Botão direito tira.", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.6, 0.55, 0.48))
	draw_string(font, Vector2(0, 330), "Espelhos cinzentos estão presos ao mecanismo.", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.5, 0.48, 0.44))
