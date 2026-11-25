extends "res://scripts/puzzles/puzzle.gd"
## OLHOS NO POTE — resta-um triangular de 15 potes. Um olho só pula sobre o
## vizinho para cair num pote vazio, e o olho pulado estoura. Sobra um? Benedita
## descansa. A semente escolhe o pote vazio inicial; um solucionador garante
## que existe saída e dá as pistas.

const Blood := preload("res://scripts/gfx/blood.gd")
const ROWS := 5
const DIRS := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(1, 1), Vector2i(-1, -1)]
const IRIS := [Color(0.25, 0.4, 0.65), Color(0.35, 0.22, 0.1), Color(0.3, 0.5, 0.3), Color(0.45, 0.45, 0.5)]

var cells: Array = []        # [Vector2i(r, c)]
var eyes: Array = []         # bool por pote
var popped: Array = []       # float: vermelho no líquido
var iris: Array = []
var selected := -1
var history: Array = []
var flying: Array = []       # [de, para, t]
var blood := Blood.new()
var memo: Dictionary = {}
var undo_b := Button.new()
var reset_b := Button.new()
var start_hole := 0
var stuck_warned := false
var hint_move: Array = []


func build() -> void:
	for r in ROWS:
		for c in r + 1:
			cells.append(Vector2i(r, c))
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("olhos")
	var options := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
	start_hole = options[rng.randi() % options.size()]
	while not _solvable(_full_mask() & ~(1 << start_hole)):
		start_hole = (start_hole + 1) % 15
	for i in 15:
		iris.append(IRIS[rng.randi() % IRIS.size()])
	_reset()
	if State.drafts.has("olhos"):
		var d: Array = State.drafts["olhos"]
		if d.size() == 15:
			for i in 15:
				eyes[i] = bool(d[i])
				popped[i] = 0.0 if eyes[i] else (1.0 if i != start_hole else 0.0)
	add_child(blood)
	for i in 15:
		blood.walls.append(_jar_rect(i))
	undo_b.text = "Desfazer"
	undo_b.position = Vector2(96, 334)
	undo_b.size = Vector2(80, 20)
	undo_b.focus_mode = Control.FOCUS_NONE
	undo_b.pressed.connect(_undo)
	add_child(undo_b)
	reset_b.text = "Recomeçar"
	reset_b.position = Vector2(184, 334)
	reset_b.size = Vector2(84, 20)
	reset_b.focus_mode = Control.FOCUS_NONE
	reset_b.pressed.connect(func():
		_reset()
		blood.clear()
		for i in 15:
			blood.walls.append(_jar_rect(i))
		Audio.play("whisper", -10.0, 1.4))
	add_child(reset_b)
	_update_hint()


func _reset() -> void:
	eyes = []
	popped = []
	for i in 15:
		eyes.append(i != start_hole)
		popped.append(0.0)
	history.clear()
	selected = -1
	stuck_warned = false
	State.drafts.erase("olhos")
	_update_hint()


func _full_mask() -> int:
	return (1 << 15) - 1


func _index(rc: Vector2i) -> int:
	if rc.x < 0 or rc.x >= ROWS or rc.y < 0 or rc.y > rc.x:
		return -1
	return rc.x * (rc.x + 1) / 2 + rc.y


func _moves_for(mask: int) -> Array:
	var out: Array = []
	for i in 15:
		if mask & (1 << i) == 0:
			continue
		for d: Vector2i in DIRS:
			var over := _index(cells[i] + d)
			var to := _index(cells[i] + d * 2)
			if over >= 0 and to >= 0 and mask & (1 << over) and mask & (1 << to) == 0:
				out.append([i, over, to])
	return out


func _solvable(mask: int) -> bool:
	if memo.has(mask):
		return memo[mask]
	var count := 0
	for i in 15:
		if mask & (1 << i):
			count += 1
	if count == 1:
		memo[mask] = true
		return true
	for m in _moves_for(mask):
		var next: int = mask & ~(1 << m[0]) & ~(1 << m[1]) | (1 << m[2])
		if _solvable(next):
			memo[mask] = true
			return true
	memo[mask] = false
	return false


func _mask() -> int:
	var m := 0
	for i in 15:
		if eyes[i]:
			m |= 1 << i
	return m


func _update_hint() -> void:
	hint_move = []
	if not State.flag("hint2_olhos"):
		return
	var mask := _mask()
	for m in _moves_for(mask):
		var next: int = mask & ~(1 << m[0]) & ~(1 << m[1]) | (1 << m[2])
		if _solvable(next):
			hint_move = m
			return


static func hint(level: int) -> String:
	if level == 1:
		return "Não deixe olhos isolados nas pontas. Esvazie os cantos cedo e trabalhe em direção ao centro."
	return "A prancheta agora acende o próximo pulo certo. Se ela se apagar, você errou antes: desfaça."


# ---------------------------------------------------------------- geometria

func _jar_center(i: int) -> Vector2:
	var rc: Vector2i = cells[i]
	return Vector2(320 + (rc.y - rc.x * 0.5) * 56, 74 + rc.x * 52)


func _jar_rect(i: int) -> Rect2:
	return Rect2(_jar_center(i) - Vector2(16, 20), Vector2(32, 40))


func _jar_at(p: Vector2) -> int:
	for i in 15:
		if _jar_rect(i).has_point(p):
			return i
	return -1


# ---------------------------------------------------------------- entrada

func _gui_input(event: InputEvent) -> void:
	if done or not flying.is_empty():
		return
	if event is InputEventMouseMotion:
		var j := _jar_at(event.position)
		set_cursor("hand" if j >= 0 and (eyes[j] or selected >= 0) else "flame")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _jar_at(event.position)
		if i < 0:
			selected = -1
			return
		if eyes[i]:
			selected = i
			Audio.play("squelch", -18.0, 2.0)
			return
		if selected >= 0:
			for m in _moves_for(_mask()):
				if m[0] == selected and m[2] == i:
					_jump(m)
					return
			Audio.play("tile", -12.0, 0.5)


func _jump(m: Array) -> void:
	history.append([eyes.duplicate(), popped.duplicate()])
	eyes[m[0]] = false
	flying.append([m[0], m[2], 0.0, m[1]])
	selected = -1


func _land(f: Array) -> void:
	eyes[f[1]] = true
	var over: int = f[3]
	eyes[over] = false
	popped[over] = 1.0
	Audio.play("pop", -2.0, randf_range(0.8, 1.2))
	Audio.play("squelch", -6.0, randf_range(0.9, 1.3))
	shake(0.35)
	var c := _jar_center(over)
	blood.spray(c, Vector2(randf_range(-0.5, 0.5), -1), 26, 110.0, 1.2, 1.4)
	State.drafts["olhos"] = eyes.duplicate()
	_update_hint()
	var left := 0
	for e in eyes:
		if e:
			left += 1
	if left == 1:
		say("BENEDITA", "...Agora eu não vejo mais nada. Que alívio.")
		State.drafts.erase("olhos")
		finish()
	elif _moves_for(_mask()).is_empty() and not stuck_warned:
		stuck_warned = true
		State.change_sanity(-3.0)
		Audio.play("wrong", -6.0)
		say("MORVANT", ["Sobrou olho demais. Recomece, ou desfaça.", "Eles ainda estão olhando para você. Todos."][left % 2])


func _undo() -> void:
	if history.is_empty() or not flying.is_empty() or done:
		return
	var h: Array = history.pop_back()
	eyes = h[0]
	popped = h[1]
	stuck_warned = false
	Audio.play("whisper", -12.0, 1.6)
	_update_hint()
	State.drafts["olhos"] = eyes.duplicate()


# ---------------------------------------------------------------- desenho

func _process(delta: float) -> void:
	super(delta)
	for f in flying.duplicate():
		f[2] += delta / 0.38
		if f[2] >= 1.0:
			flying.erase(f)
			_land(f)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.06, 0.045, 0.035))
	# Prateleiras da despensa
	for r in ROWS:
		var y := 74 + r * 52 + 21
		var w := 70 + r * 56
		draw_rect(Rect2(320 - w * 0.5 - 10, y, w + 20, 5), Color(0.3, 0.18, 0.1))
		draw_rect(Rect2(320 - w * 0.5 - 10, y + 5, w + 20, 2), Color(0.12, 0.07, 0.04))
	var mouse := get_local_mouse_position()
	var targets: Array = []
	if selected >= 0:
		for m in _moves_for(_mask()):
			if m[0] == selected:
				targets.append(m[2])
	for i in 15:
		_jar(i, mouse, i in targets)
	for f in flying:
		var a := _jar_center(f[0])
		var b := _jar_center(f[1])
		var k: float = f[2]
		var p := a.lerp(b, k) + Vector2(0, -sin(k * PI) * 26)
		_eye(p, f[0], mouse, 1.0)
	draw_string(get_theme_default_font(), Vector2(226, 22), "OLHOS NO POTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.66, 0.36))
	draw_string(get_theme_default_font(), Vector2(200, 34), "pule um olho sobre o vizinho até um pote vazio. Deixe só um.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.5, 0.4))


func _jar(i: int, mouse: Vector2, target: bool) -> void:
	var r := _jar_rect(i)
	var liquid := Color(0.42, 0.48, 0.24, 0.85).lerp(Color(0.5, 0.02, 0.04, 0.95), popped[i] if State.gore else 0.0)
	draw_rect(Rect2(r.position + Vector2(2, 8), r.size - Vector2(4, 10)), liquid)
	# Restos do olho estourado
	if popped[i] > 0.0 and not eyes[i] and State.gore:
		draw_rect(Rect2(r.get_center() + Vector2(-4, 8), Vector2(6, 3)), Color(0.85, 0.75, 0.68))
		draw_rect(Rect2(r.get_center() + Vector2(1, 10), Vector2(3, 2)), Color(0.3, 0.05, 0.05))
	# Vidro, tampa e reflexo
	draw_rect(r, Color(0.7, 0.8, 0.75, 0.08))
	draw_rect(r, Color(0.6, 0.7, 0.65, 0.5), false, 1.0)
	draw_rect(Rect2(r.position + Vector2(3, 0), Vector2(r.size.x - 6, 6)), Color(0.45, 0.36, 0.22))
	draw_rect(Rect2(r.position + Vector2(5, 10), Vector2(2, r.size.y - 16)), Color(1, 1, 1, 0.18))
	if eyes[i]:
		_eye(r.get_center() + Vector2(0, 4 + sin(t * 1.3 + i) * 1.5), i, mouse, 1.0)
	if i == selected:
		draw_rect(r.grow(2), Color(0.9, 0.15, 0.1), false, 1.0)
	if target:
		draw_rect(r.grow(1), Color(0.9, 0.75, 0.4, 0.4 + 0.3 * sin(t * 6.0)), false, 1.0)
	if hint_move.size() == 3 and (i == hint_move[0] or i == hint_move[2]):
		draw_rect(r.grow(3), Color(0.4, 0.9, 1.0, 0.3 + 0.3 * sin(t * 4.0)), false, 1.0)


func _eye(c: Vector2, i: int, mouse: Vector2, s: float) -> void:
	draw_circle(c, 8 * s, Color(0.92, 0.88, 0.82))
	# Nervo óptico pendurado
	draw_line(c + Vector2(0, 7), c + Vector2(sin(t * 2.0 + i) * 3, 14), Color(0.7, 0.35, 0.3), 2.0)
	for k in 3:
		var ang := 0.6 + k * 1.9
		draw_line(c + Vector2(cos(ang), sin(ang)) * 8, c + Vector2(cos(ang), sin(ang)) * 4, Color(0.8, 0.25, 0.25), 1.0)
	# Todos os olhos seguem o cursor.
	var look := ((mouse - c) / 120.0).limit_length(1.0) * 3.0
	draw_circle(c + look, 3.6 * s, iris[i])
	draw_circle(c + look, 1.6 * s, Color(0.03, 0.02, 0.02))
	draw_rect(Rect2(c + look + Vector2(-2, -2), Vector2(1, 1)), Color(1, 1, 1, 0.9))
