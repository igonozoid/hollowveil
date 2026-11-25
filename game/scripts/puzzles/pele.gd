extends "res://scripts/puzzles/puzzle.gd"
## A PELE — a pele tatuada do Capitão Hélio, costurada em 25 retalhos. Gire
## cada retalho (clique: horário; direito: anti-horário) até as linhas da
## tatuagem se ligarem num desenho só, sem pontas soltas. A semente gera uma
## árvore de linhas (busca em profundidade aleatória) e gira os retalhos.

const Blood := preload("res://scripts/gfx/blood.gd")
const N := 5
const TILE := 46.0
const ORIGIN := Vector2(205, 52)
## Bits de ligação: norte, leste, sul, oeste.
const DIRS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var base: Array = []    # ligações originais (bits)
var rot: Array = []     # rotação atual de cada retalho (0..3)
var shown: Array = []
var turns := 0
var blood := Blood.new()


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("pele")
	for i in N * N:
		base.append(0)
		rot.append(0)
		shown.append(0.0)
	# Árvore geradora por busca em profundidade a partir do centro.
	var seen := {}
	var stack := [Vector2i(2, 2)]
	seen[Vector2i(2, 2)] = true
	while not stack.is_empty():
		var cur: Vector2i = stack[-1]
		var opts: Array = []
		for d in 4:
			var nb: Vector2i = cur + DIRS[d]
			if nb.x >= 0 and nb.x < N and nb.y >= 0 and nb.y < N and not seen.has(nb):
				opts.append(d)
		if opts.is_empty():
			stack.pop_back()
			continue
		var dd: int = opts[rng.randi() % opts.size()]
		var nxt: Vector2i = cur + DIRS[dd]
		base[_i(cur)] |= 1 << dd
		base[_i(nxt)] |= 1 << ((dd + 2) % 4)
		seen[nxt] = true
		stack.append(nxt)
	for i in N * N:
		rot[i] = rng.randi() % 4
	if _solved():
		rot[0] = (rot[0] + 1) % 4
	if State.drafts.has("pele") and (State.drafts["pele"] as Array).size() == N * N:
		for i in N * N:
			rot[i] = int(State.drafts["pele"][i])
	for i in N * N:
		shown[i] = float(rot[i])
	add_child(blood)
	blood.floor_y = 340.0


func _i(v: Vector2i) -> int:
	return v.y * N + v.x


## Ligações atuais do retalho, já giradas.
func conn(i: int) -> int:
	var m: int = base[i]
	var r: int = rot[i]
	return ((m << r) | (m >> (4 - r))) & 15


func tile_ok(i: int) -> bool:
	var v := Vector2i(i % N, i / N)
	var m := conn(i)
	for d in 4:
		var has := (m >> d) & 1
		var nb: Vector2i = v + DIRS[d]
		var other := 0
		if nb.x >= 0 and nb.x < N and nb.y >= 0 and nb.y < N:
			other = (conn(_i(nb)) >> ((d + 2) % 4)) & 1
		if has != other:
			return false
	return true


func _solved() -> bool:
	for i in N * N:
		if not tile_ok(i):
			return false
	return true


static func hint(level: int) -> String:
	if level == 1:
		return "Comece pelos cantos e pelas pontas: um retalho com uma linha só tem que apontar para dentro, nunca para a borda."
	return "Os retalhos que ainda não se encaixam com os vizinhos agora sangram em azul."


func _tile_at(p: Vector2) -> int:
	var l := p - ORIGIN
	if l.x < 0 or l.y < 0 or l.x >= N * TILE or l.y >= N * TILE:
		return -1
	return int(l.y / TILE) * N + int(l.x / TILE)


func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseMotion:
		set_cursor("hand" if _tile_at(event.position) >= 0 else "flame")
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var i := _tile_at(event.position)
		if i < 0:
			return
		rot[i] = posmod(rot[i] + (1 if event.button_index == MOUSE_BUTTON_LEFT else -1), 4)
		turns += 1
		Audio.play("card", -6.0, randf_range(0.6, 0.8))
		State.drafts["pele"] = rot.duplicate()
		if randf() < 0.3:
			blood.drip(ORIGIN + Vector2(i % N, i / N) * TILE + Vector2(randf_range(4, TILE - 4), TILE), 20.0)
		if _solved():
			State.drafts.erase("pele")
			Audio.play("sting", -8.0, 0.75)
			say("DÁLIA", "Uma âncora, uma rosa e um nome. \"Mãe.\" Ele tatuou a mãe nas costas.")
			finish()


func _process(delta: float) -> void:
	super(delta)
	for i in N * N:
		var diff := fposmod(float(rot[i]) - shown[i] + 2.0, 4.0) - 2.0
		shown[i] += diff * minf(1.0, delta * 14.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.05, 0.035, 0.04))
	# Bastidor de madeira com as cordas que esticam a pele
	var board := Rect2(ORIGIN - Vector2(16, 16), Vector2(N * TILE + 32, N * TILE + 32))
	draw_rect(board, Color(0.32, 0.18, 0.09))
	for k in 12:
		var x := board.position.x + 6 + k * (board.size.x - 12) / 11.0
		draw_line(Vector2(x, board.position.y + 2), Vector2(x, ORIGIN.y + 2), Color(0.75, 0.7, 0.55), 1.0)
		draw_line(Vector2(x, board.end.y - 2), Vector2(x, ORIGIN.y + N * TILE - 2), Color(0.75, 0.7, 0.55), 1.0)
	var hint2 := State.flag("hint2_pele")
	var win := done
	for i in N * N:
		var o := ORIGIN + Vector2(i % N, i / N) * TILE
		var c := o + Vector2(TILE, TILE) * 0.5
		var tone := Color(0.7, 0.57, 0.48).lerp(Color(0.6, 0.46, 0.39), fmod(i * 0.37, 1.0))
		draw_rect(Rect2(o, Vector2(TILE, TILE)), tone)
		# Pelos e poros
		for k in 4:
			draw_rect(Rect2(o + Vector2(fmod(i * 13.0 + k * 11.0, TILE - 4), fmod(i * 7.0 + k * 17.0, TILE - 4)), Vector2(1, 1)), tone.darkened(0.25))
		var ink := Color(0.12, 0.16, 0.3) if not win else Color(0.08, 0.12, 0.3).lerp(Color(0.6, 0.05, 0.08), 0.3 + 0.3 * sin(t * 3.0))
		var ang: float = shown[i] * PI * 0.5
		var m: int = base[i]
		var arms := 0
		for d in 4:
			if (m >> d) & 1:
				arms += 1
				var dir := Vector2(DIRS[d]).rotated(ang)
				draw_line(c, c + dir * TILE * 0.5, ink, 5.0)
		draw_circle(c, 3.0, ink)
		# Pontas da árvore viram pequenos ornamentos (estrela, rosa).
		if arms == 1:
			draw_circle(c, 6.0, ink)
			draw_circle(c, 3.0, Color(0.6, 0.08, 0.12))
		if i == 12:
			draw_circle(c, 9.0, ink)
			draw_rect(Rect2(c - Vector2(4, 3), Vector2(3, 3)), tone)
			draw_rect(Rect2(c + Vector2(1, -3), Vector2(3, 3)), tone)
		if hint2 and not tile_ok(i):
			draw_rect(Rect2(o + Vector2(2, 2), Vector2(TILE - 4, TILE - 4)), Color(0.3, 0.7, 1.0, 0.18), false, 2.0)
	# Costuras grossas entre os retalhos
	for k in N + 1:
		for s in 10:
			var a := ORIGIN + Vector2(k * TILE, s * TILE * N / 10.0)
			draw_line(a + Vector2(-2, 2), a + Vector2(2, 8), Color(0.35, 0.05, 0.05), 1.0)
			var b := ORIGIN + Vector2(s * TILE * N / 10.0, k * TILE)
			draw_line(b + Vector2(2, -2), b + Vector2(8, 2), Color(0.35, 0.05, 0.05), 1.0)
	var font := get_theme_default_font()
	draw_string(font, Vector2(282, 22), "A PELE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(150, 320), "clique gira o retalho · botão direito gira ao contrário · ligue todas as linhas", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.5, 0.4))
	draw_string(font, Vector2(470, 160), "giros: %d" % turns, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.5, 0.4))
