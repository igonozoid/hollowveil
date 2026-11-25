extends "res://scripts/puzzles/puzzle.gd"
## OS GANCHOS — a câmara fria vista de cima. Os corpos correm em trolleys
## pelo chão gelado; Dália só consegue empurrá-los, nunca puxar. Os três
## precisam parar sobre os ralos. A semente monta a sala e uma busca de trás
## para a frente (puxando os corpos a partir dos ralos) acha a posição que
## pede mais empurrões, até um teto. Então sempre existe solução, e o número
## mínimo de empurrões é conhecido. A busca roda numa thread.

const W := 9
const H := 7
const CELL := 32
const ORIGIN := Vector2(176, 50)
const CAP := 24
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var walls: Array = []        # bool por célula
var targets: Array = []      # Vector2i
var boxes: Array = []        # Vector2i
var player := Vector2i()
var start_boxes: Array = []
var start_player := Vector2i()
var history: Array = []
var dead: Array = []         # células mortas (pista 2)
var show_dead := false
var bump_t := 0.0
var depth := 0
var room_ok := false
var _task := -1
var undo_btn := Button.new()
var reset_btn := Button.new()


func build() -> void:
	show_dead = State.flag("hint2_ganchos")
	if State.drafts.has("ganchos_room"):
		_load_room(State.drafts["ganchos_room"])
		_room_ready()
	else:
		var sd := State.puzzle_seed("ganchos")
		_task = WorkerThreadPool.add_task(_gen_task.bind(sd))
	undo_btn.text = "Desfazer"
	undo_btn.position = Vector2(230, 334)
	undo_btn.size = Vector2(84, 20)
	undo_btn.focus_mode = Control.FOCUS_NONE
	undo_btn.pressed.connect(undo)
	add_child(undo_btn)
	reset_btn.text = "Recomeçar"
	reset_btn.position = Vector2(326, 334)
	reset_btn.size = Vector2(84, 20)
	reset_btn.focus_mode = Control.FOCUS_NONE
	reset_btn.pressed.connect(restart)
	add_child(reset_btn)


func _gen_task(sd: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	generate(rng)


func _room_ready() -> void:
	_find_dead()
	boxes = start_boxes.duplicate()
	player = start_player
	var wl: Array = []
	for w in walls:
		wl.append(1 if w else 0)
	State.drafts["ganchos_room"] = {"walls": wl, "targets": _pack(targets), "boxes": _pack(start_boxes), "player": [start_player.x, start_player.y], "depth": depth}
	if State.drafts.has("ganchos"):
		var d: Dictionary = State.drafts["ganchos"]
		var bs := _unpack(d.get("boxes", []))
		if bs.size() == boxes.size():
			boxes = bs
			var pl: Array = d.get("player", [player.x, player.y])
			player = Vector2i(int(pl[0]), int(pl[1]))
	room_ok = true


func _load_room(d: Dictionary) -> void:
	walls = []
	for w in d["walls"]:
		walls.append(int(w) == 1)
	targets = _unpack(d["targets"])
	start_boxes = _unpack(d["boxes"])
	start_player = Vector2i(int(d["player"][0]), int(d["player"][1]))
	depth = int(d.get("depth", 0))


static func _pack(a: Array) -> Array:
	var out: Array = []
	for c in a:
		out.append([c.x, c.y])
	return out


static func _unpack(a: Array) -> Array:
	var out: Array = []
	for c in a:
		out.append(Vector2i(int(c[0]), int(c[1])))
	return out


static func hint(level: int) -> String:
	if level == 1:
		return "Um corpo encostado num canto nunca mais sai de lá. Pense de trás para a frente: de onde ele precisa ser empurrado?"
	return "A prancheta riscou de vermelho os ladrilhos onde um corpo fica preso para sempre."


func idx(c: Vector2i) -> int:
	return c.y * W + c.x


func is_wall(c: Vector2i) -> bool:
	return c.x < 0 or c.y < 0 or c.x >= W or c.y >= H or walls[idx(c)]


func is_free(c: Vector2i, bs: Array) -> bool:
	return not is_wall(c) and not bs.has(c)


## Células alcançáveis a pé, sem empurrar nada.
func reach(from: Vector2i, bs: Array) -> Dictionary:
	var seen := {from: true}
	var q: Array = [from]
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for d in DIRS:
			var n: Vector2i = c + d
			if not seen.has(n) and is_free(n, bs):
				seen[n] = true
				q.append(n)
	return seen


func generate(rng: RandomNumberGenerator) -> void:
	for attempt in 200:
		walls = []
		for y in H:
			for x in W:
				walls.append(x == 0 or y == 0 or x == W - 1 or y == H - 1)
		# Pilares e prateleiras de aço no meio da sala.
		for k in rng.randi_range(4, 7):
			walls[idx(Vector2i(rng.randi_range(1, W - 2), rng.randi_range(1, H - 2)))] = true
		var floor_cells: Array = []
		for y in H:
			for x in W:
				if not walls[idx(Vector2i(x, y))]:
					floor_cells.append(Vector2i(x, y))
		if floor_cells.size() < 20:
			continue
		if reach(floor_cells[0], []).size() != floor_cells.size():
			continue
		# Embaralhar com a semente (Array.shuffle usaria o sorteio global).
		for i in range(floor_cells.size() - 1, 0, -1):
			var j := rng.randi() % (i + 1)
			var tmp = floor_cells[i]
			floor_cells[i] = floor_cells[j]
			floor_cells[j] = tmp
		targets = floor_cells.slice(0, 3)
		if _deepest(rng) >= 14:
			return


## Busca para trás a partir dos ralos: cada passo é um puxão (o inverso de um
## empurrão). O estado mais fundo, com os três corpos fora dos ralos, vira a
## sala inicial; a profundidade é o mínimo de empurrões para resolver.
func _deepest(rng: RandomNumberGenerator) -> int:
	var tset := {}
	for tg in targets:
		tset[tg] = true
	var goal: Array = targets.duplicate()
	var q: Array = []
	var taken := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if taken.has(c) or not is_free(c, goal):
				continue
			for rc in reach(c, goal):
				taken[rc] = true
			q.append([c, goal, 0])
	var seen := {}
	var queued := {}
	var best_d := -1
	var best: Array = []
	var head := 0
	while head < q.size():
		var st: Array = q[head]
		head += 1
		var bs: Array = st[1]
		var r := reach(st[0], bs)
		var m: Vector2i = st[0]
		for c in r:
			if c.y < m.y or (c.y == m.y and c.x < m.x):
				m = c
		var code := _code(m, bs)
		if seen.has(code):
			continue
		seen[code] = true
		var d: int = st[2]
		var off := true
		for b in bs:
			if tset.has(b):
				off = false
				break
		if off:
			if d > best_d:
				best_d = d
				best = [[r, bs]]
			elif d == best_d:
				best.append([r, bs])
		if d >= CAP:
			continue
		for bi in bs.size():
			var b: Vector2i = bs[bi]
			for dd in DIRS:
				var stand: Vector2i = b + dd
				var back: Vector2i = b + dd * 2
				if not r.has(stand) or not is_free(back, bs):
					continue
				var nb: Array = bs.duplicate()
				nb[bi] = stand
				var qc := _code(back, nb)
				if not queued.has(qc):
					queued[qc] = true
					q.append([back, nb, d + 1])
	if best.is_empty():
		return -1
	var pick: Array = best[rng.randi() % best.size()]
	start_boxes = (pick[1] as Array).duplicate()
	var cells: Array = (pick[0] as Dictionary).keys()
	start_player = cells[rng.randi() % cells.size()]
	boxes = start_boxes.duplicate()
	player = start_player
	depth = best_d
	return best_d


## Cantos sem ralo: um corpo empurrado ali fica preso.
func _find_dead() -> void:
	dead = []
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if is_wall(c) or targets.has(c):
				continue
			var hz := is_wall(c + Vector2i(1, 0)) or is_wall(c + Vector2i(-1, 0))
			var vt := is_wall(c + Vector2i(0, 1)) or is_wall(c + Vector2i(0, -1))
			if hz and vt:
				dead.append(c)


func solved_now() -> bool:
	for b in boxes:
		if not targets.has(b):
			return false
	return true


## Um passo de Dália. Empurra o corpo à frente, se houver espaço.
func step(d: Vector2i) -> bool:
	if done or not room_ok:
		return false
	var n := player + d
	if is_wall(n):
		bump_t = 0.2
		return false
	var bi := boxes.find(n)
	if bi >= 0:
		var to := n + d
		if not is_free(to, boxes):
			bump_t = 0.2
			Audio.play("locked", -16.0, 1.4)
			return false
		history.append([player, boxes.duplicate()])
		boxes[bi] = to
		player = n
		Audio.play("creak", -12.0, randf_range(1.6, 2.0))
		if targets.has(to):
			Audio.play("squelch", -10.0, 0.7)
	else:
		history.append([player, boxes.duplicate()])
		player = n
		Audio.play("step", -16.0, randf_range(1.1, 1.3))
	_save_draft()
	if solved_now():
		Audio.play("sting", -8.0, 0.8)
		shake(0.4)
		say("DÁLIA", "O último gancho desce sobre o ralo. Embaixo dele, presa no gelo, uma chave de ferro com uma cruz.")
		State.drafts.erase("ganchos")
		State.drafts.erase("ganchos_room")
		finish()
	return true


func undo() -> void:
	if done or not room_ok or history.is_empty():
		return
	var h: Array = history.pop_back()
	player = h[0]
	boxes = h[1]
	Audio.play("tile", -12.0, 0.8)
	_save_draft()


func restart() -> void:
	if done or not room_ok:
		return
	history.clear()
	boxes = start_boxes.duplicate()
	player = start_player
	Audio.play("ice", -10.0)
	_save_draft()


func _save_draft() -> void:
	var bs: Array = []
	for b in boxes:
		bs.append([b.x, b.y])
	State.drafts["ganchos"] = {"boxes": bs, "player": [player.x, player.y]}


## Busca em largura pelos empurrões (para os testes): mínimo de empurrões
## até todos os corpos nos ralos, ou -1 se passar do limite de estados.
func solve_pushes(limit: int = 80000) -> int:
	var tset := {}
	for tg in targets:
		tset[tg] = true
	var deadset := {}
	for dc in dead:
		deadset[dc] = true
	var q: Array = [[start_player, start_boxes.duplicate(), 0]]
	var seen := {}
	var queued := {}
	var head := 0
	while head < q.size():
		if seen.size() > limit:
			return -1
		var st: Array = q[head]
		head += 1
		var bs: Array = st[1]
		var r := reach(st[0], bs)
		var m: Vector2i = st[0]
		for c in r:
			if c.y < m.y or (c.y == m.y and c.x < m.x):
				m = c
		var code := _code(m, bs)
		if seen.has(code):
			continue
		seen[code] = true
		var ok := true
		for b in bs:
			if not tset.has(b):
				ok = false
				break
		if ok:
			return st[2]
		for bi in bs.size():
			var b: Vector2i = bs[bi]
			for d in DIRS:
				var to: Vector2i = b + d
				if not r.has(b - d) or deadset.has(to) or not is_free(to, bs):
					continue
				var nb: Array = bs.duplicate()
				nb[bi] = to
				var qc := _code(b, nb)
				if not queued.has(qc):
					queued[qc] = true
					q.append([b, nb, int(st[2]) + 1])
	return -1


func _code(pl: Vector2i, bs: Array) -> int:
	var ids: Array = []
	for b in bs:
		ids.append(idx(b))
	ids.sort()
	var k := idx(pl)
	for v in ids:
		k = k * 64 + int(v)
	return k


func _unhandled_key_input(event: InputEvent) -> void:
	if not room_ok or not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_LEFT, KEY_A:
			step(Vector2i(-1, 0))
		KEY_RIGHT, KEY_D:
			step(Vector2i(1, 0))
		KEY_UP, KEY_W:
			step(Vector2i(0, -1))
		KEY_DOWN, KEY_S:
			step(Vector2i(0, 1))
		KEY_Z, KEY_BACKSPACE:
			undo()
		_:
			return
	get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if done or not room_ok or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var c := Vector2i(((event.position - ORIGIN) / CELL).floor())
	var d := c - player
	if absi(d.x) + absi(d.y) == 1:
		step(d)
		return
	# Clique longe: anda até lá pelo caminho livre, sem empurrar nada.
	if is_free(c, boxes) and reach(player, boxes).has(c):
		var path := _path(player, c)
		for dd in path:
			step(dd)


func _path(a: Vector2i, b: Vector2i) -> Array:
	var prev := {a: a}
	var q: Array = [a]
	var head := 0
	while head < q.size():
		var c: Vector2i = q[head]
		head += 1
		if c == b:
			break
		for d in DIRS:
			var n: Vector2i = c + d
			if not prev.has(n) and is_free(n, boxes):
				prev[n] = c
				q.append(n)
	var out: Array = []
	var c2 := b
	while c2 != a and prev.has(c2):
		var pc: Vector2i = prev[c2]
		out.push_front(c2 - pc)
		c2 = pc
	return out


func _process(delta: float) -> void:
	super(delta)
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_room_ready()
	bump_t = maxf(0.0, bump_t - delta)
	undo_btn.disabled = done or history.is_empty()
	reset_btn.disabled = done


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.035, 0.045))
	var font := get_theme_default_font()
	if not room_ok:
		draw_string(font, Vector2(0, 180), "O gelo range. Os ganchos ainda balançam...", HORIZONTAL_ALIGNMENT_CENTER, 640, 10, Color(0.7, 0.75, 0.85, 0.5 + 0.4 * sin(t * 4.0)))
		return
	var lamp := ORIGIN + (Vector2(player) + Vector2(0.5, 0.5)) * CELL
	brass_frame(Rect2(ORIGIN - Vector2(6, 6), Vector2(W * CELL + 12, H * CELL + 12)), 2.0)
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var r := Rect2(ORIGIN + Vector2(x, y) * CELL, Vector2(CELL, CELL))
			# A lamparina de Dália ilumina em volta dela; o resto fica no azul do gelo.
			var light := clampf(1.0 - lamp.distance_to(r.get_center()) / 230.0, 0.5, 1.0)
			if walls[idx(c)]:
				draw_rect(r, Color(Color(0.07, 0.075, 0.09) * light, 1.0))
				# Prateleiras de aço: três tábuas de metal.
				for k in 3:
					draw_rect(Rect2(r.position + Vector2(3, 6 + k * 9), Vector2(CELL - 6, 3)), Color(Color(0.22, 0.23, 0.27) * light, 1.0))
				draw_rect(r, Color(0.02, 0.02, 0.03), false, 1.0)
			else:
				var tile := Color(0.58, 0.62, 0.66) if (x + y) % 2 == 0 else Color(0.52, 0.56, 0.6)
				draw_rect(r, Color(tile * light, 1.0))
				draw_rect(r, Color(0.3, 0.34, 0.38), false, 1.0)
				if show_dead and dead.has(c):
					draw_rect(r.grow(-4), Color(0.6, 0.05, 0.05, 0.35))
	# Trilhos do teto, projetados como sombras finas.
	for y in range(1, H - 1):
		draw_line(ORIGIN + Vector2(CELL * 0.5, (y + 0.5) * CELL), ORIGIN + Vector2((W - 0.5) * CELL, (y + 0.5) * CELL), Color(0, 0, 0, 0.08), 1.0)
	for tg: Vector2i in targets:
		var cc := ORIGIN + (Vector2(tg) + Vector2(0.5, 0.5)) * CELL
		draw_circle(cc, 10, Color(0.08, 0.08, 0.09))
		for k in 4:
			draw_line(cc + Vector2(-8, -6 + k * 4), cc + Vector2(8, -6 + k * 4), Color(0.3, 0.3, 0.32), 1.0)
		if State.gore:
			draw_circle(cc + Vector2(6, 6), 3, Color(0.4, 0.0, 0.03))
	for b: Vector2i in boxes:
		var cc := ORIGIN + (Vector2(b) + Vector2(0.5, 0.5)) * CELL
		var on := targets.has(b)
		var sheet := Color(0.78, 0.76, 0.7) if not on else Color(0.66, 0.56, 0.52)
		draw_set_transform(cc, 0.0, Vector2(0.62, 1.0))
		draw_circle(Vector2.ZERO, 13, sheet.darkened(0.3))
		draw_circle(Vector2(0, -1), 12, sheet)
		draw_set_transform(Vector2.ZERO)
		for k in 3:
			draw_line(cc + Vector2(-7, -7 + k * 7), cc + Vector2(7, -8 + k * 7), Color(0.38, 0.3, 0.2), 1.0)
		draw_circle(cc + Vector2(0, -9), 3, Color(0.4, 0.42, 0.45))
		if State.gore:
			draw_rect(Rect2(cc + Vector2(-2, 0), Vector2(4, 5)), Color(0.5, 0.02, 0.05, 0.8))
	# Dália, com a lamparina.
	var shake_x := sin(t * 60.0) * 2.0 * bump_t * 5.0
	var pc := lamp + Vector2(shake_x, 0)
	draw_circle(pc, 26, Color(1.0, 0.7, 0.35, 0.07))
	draw_circle(pc, 8, Color(0.16, 0.1, 0.12))
	draw_circle(pc + Vector2(0, -2), 4, Color(0.75, 0.62, 0.52))
	draw_circle(pc + Vector2(6, 4), 2.5, Color(1.0, 0.75, 0.35))
	# Textos.
	draw_string(font, Vector2(276, 20), "OS GANCHOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(0, 306), "Empurre os três corpos até os ralos. Só dá para empurrar, nunca puxar.", HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color(0.75, 0.68, 0.58))
	draw_string(font, Vector2(0, 320), "Setas ou WASD para andar · clique num ladrilho para ir até ele · Z desfaz", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.55, 0.52, 0.46))
