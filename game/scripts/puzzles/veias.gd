extends "res://scripts/puzzles/puzzle.gd"
## AS VEIAS — "apague as luzes" de 5×5 com raízes que pulsam. Tocar num bulbo
## inverte ele e os quatro vizinhos (cheio de sangue ↔ murcho). Murche todos.
## O estado inicial sai de toques aleatórios a partir do vazio (sempre tem
## solução); um solucionador em GF(2) acha um caminho para as pistas.

const Blood := preload("res://scripts/gfx/blood.gd")
const N := 5
const CELL := 44.0
const ORIGIN := Vector2(210, 74)

var lit: Array = []
var pulse: Array = []
var presses := 0
var blood := Blood.new()
var hint_cell := -1
var shown_hint := false


func build() -> void:
	for i in N * N:
		lit.append(false)
		pulse.append(0.0)
	if State.drafts.has("veias") and (State.drafts["veias"] as Array).size() == N * N:
		for i in N * N:
			lit[i] = bool(State.drafts["veias"][i])
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = State.puzzle_seed("veias")
		var count := 0
		while count < 7 or _all_dark():
			_toggle(rng.randi() % (N * N), false)
			count += 1
	add_child(blood)
	blood.floor_y = 330.0
	_update_hint()


func _all_dark() -> bool:
	for v in lit:
		if v:
			return false
	return true


func _neighbors(i: int) -> Array:
	var out := [i]
	var r := i / N
	var c := i % N
	if r > 0:
		out.append(i - N)
	if r < N - 1:
		out.append(i + N)
	if c > 0:
		out.append(i - 1)
	if c < N - 1:
		out.append(i + 1)
	return out


func _toggle(i: int, fx: bool) -> void:
	for j in _neighbors(i):
		lit[j] = not lit[j]
		pulse[j] = 1.0
	if fx:
		presses += 1
		var c := _center(i)
		if lit[i]:
			Audio.play("heart", -10.0, randf_range(1.0, 1.3))
		else:
			Audio.play("squelch", -6.0, randf_range(0.8, 1.2))
			blood.spray(c, Vector2(randf_range(-0.6, 0.6), -1), 14, 110.0, 0.8, 1.3)
		State.drafts["veias"] = lit.duplicate()


## Resolve Ax = b em GF(2). Devolve as casas a tocar (ou [] se não houver).
func solve() -> Array:
	var size := N * N
	var rows: Array = []
	for i in size:
		var row := PackedByteArray()
		row.resize(size + 1)
		for j in _neighbors(i):
			row[j] = 1
		row[size] = 1 if lit[i] else 0
		rows.append(row)
	var where: Array = []
	where.resize(size)
	where.fill(-1)
	var r := 0
	for col in size:
		var pivot := -1
		for k in range(r, size):
			if rows[k][col] == 1:
				pivot = k
				break
		if pivot < 0:
			continue
		var tmp = rows[r]
		rows[r] = rows[pivot]
		rows[pivot] = tmp
		where[col] = r
		for k in size:
			if k != r and rows[k][col] == 1:
				var a: PackedByteArray = rows[k]
				var b: PackedByteArray = rows[r]
				for c in range(col, size + 1):
					a[c] = a[c] ^ b[c]
				rows[k] = a
		r += 1
		if r == size:
			break
	for k in range(r, size):
		if rows[k][size] == 1:
			return []
	var out: Array = []
	for col in size:
		if where[col] >= 0 and rows[where[col]][size] == 1:
			out.append(col)
	return out


func _update_hint() -> void:
	hint_cell = -1
	if State.flag("hint2_veias"):
		var s := solve()
		if not s.is_empty():
			hint_cell = s[0]


static func hint(level: int) -> String:
	if level == 1:
		return "Trabalhe de cima para baixo: murche cada bulbo tocando no que fica logo abaixo dele. O que sobrar na última fileira diz por onde recomeçar."
	return "A prancheta agora faz pulsar, em azul, um bulbo que precisa ser tocado."


func _center(i: int) -> Vector2:
	return ORIGIN + Vector2(i % N, i / N) * CELL + Vector2(CELL, CELL) * 0.5


func _cell_at(p: Vector2) -> int:
	for i in N * N:
		if _center(i).distance_to(p) < CELL * 0.42:
			return i
	return -1


func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseMotion:
		set_cursor("hand" if _cell_at(event.position) >= 0 else "flame")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _cell_at(event.position)
		if i < 0:
			return
		_toggle(i, true)
		_update_hint()
		if _all_dark():
			State.drafts.erase("veias")
			Audio.play("sting", -8.0, 0.7)
			say("DÁLIA", "As raízes secaram. Tem alguma coisa enterrada ali no meio.")
			finish()
		elif presses == 40:
			say("MORVANT", "Elas crescem melhor com sangue. O meu, de preferência.")


func _process(delta: float) -> void:
	super(delta)
	for i in pulse.size():
		pulse[i] = maxf(0.0, pulse[i] - delta * 3.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.035, 0.04))
	# Terra do canteiro dentro da moldura
	brass_frame(Rect2(ORIGIN - Vector2(22, 22), Vector2(N * CELL + 44, N * CELL + 44)), 2.0)
	draw_rect(Rect2(ORIGIN - Vector2(18, 18), Vector2(N * CELL + 36, N * CELL + 36)), Color(0.12, 0.08, 0.06))
	for i in 60:
		var q := ORIGIN + Vector2(fmod(i * 47.3, N * CELL), fmod(i * 29.1, N * CELL))
		draw_rect(Rect2(q, Vector2(2, 1)), Color(0.18, 0.12, 0.08))
	var beat := maxf(0.0, sin(t * 7.0)) * maxf(0.0, sin(t * 3.5))
	# Raízes ligando os vizinhos (engrossam quando os dois lados estão cheios).
	for i in N * N:
		for j in [i + 1, i + N]:
			if j >= N * N or (j == i + 1 and i % N == N - 1):
				continue
			var both: bool = lit[i] and lit[j]
			var col := Color(0.45, 0.08, 0.1) if both else Color(0.24, 0.18, 0.14)
			var a := _center(i)
			var b := _center(j)
			var mid := (a + b) * 0.5 + Vector2(sin(i * 1.7) * 4.0, cos(j * 1.3) * 4.0)
			draw_line(a, mid, col, 3.0 if both else 2.0)
			draw_line(mid, b, col, 3.0 if both else 2.0)
	for i in N * N:
		var c := _center(i)
		var k: float = pulse[i]
		if lit[i]:
			var r := 13.0 + 2.5 * beat + 4.0 * k
			draw_circle(c, r + 4.0, Color(0.9, 0.1, 0.15, 0.12))
			draw_circle(c, r, Color(0.5, 0.04, 0.08))
			draw_circle(c, r * 0.75, Color(0.66, 0.08, 0.12))
			for v in 4:
				var ang := v * 1.6 + i
				draw_line(c, c + Vector2(cos(ang), sin(ang)) * r * 0.8, Color(0.35, 0.02, 0.06), 1.0)
			draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.25, Color(0.95, 0.45, 0.45))
		else:
			var r2 := 8.0 + 3.0 * k
			draw_circle(c, r2, Color(0.22, 0.2, 0.17))
			draw_circle(c + Vector2(1, 1), r2 * 0.6, Color(0.16, 0.14, 0.12))
			draw_line(c + Vector2(-r2 * 0.5, 0), c + Vector2(r2 * 0.4, -r2 * 0.3), Color(0.12, 0.1, 0.08), 1.0)
		if i == hint_cell:
			draw_arc(c, 18.0, 0, TAU, 20, Color(0.4, 0.9, 1.0, 0.4 + 0.4 * sin(t * 5.0)), 1.0)
	draw_string(get_theme_default_font(), Vector2(262, 20), "AS VEIAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.66, 0.36))
	draw_string(get_theme_default_font(), Vector2(160, 34), "tocar num bulbo inverte ele e os vizinhos. Murche todos.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.5, 0.4))
	var count := 0
	for v in lit:
		if v:
			count += 1
	draw_string(get_theme_default_font(), Vector2(470, 120), "cheios: %d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.8, 0.3, 0.3))
	draw_string(get_theme_default_font(), Vector2(470, 134), "toques: %d" % presses, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.5, 0.4))
