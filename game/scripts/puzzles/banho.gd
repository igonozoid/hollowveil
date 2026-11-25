extends "res://scripts/puzzles/puzzle.gd"
## O BANHO — três frascos. O maior começa cheio de sangue; os outros, vazios.
## Despeje de um para outro (sempre até encher o destino ou esvaziar a
## origem) até algum frasco ter exatamente a medida que o ralo aceita.
## A semente escolhe capacidades e alvo; uma busca confirma a solução.

const SETS := [[8, 5, 3, 4], [10, 7, 3, 5], [12, 7, 5, 6], [9, 7, 4, 6], [11, 6, 4, 9], [12, 8, 5, 2], [10, 6, 4, 2], [13, 8, 5, 11]]
const XS := [220.0, 320.0, 420.0]
const BASE_Y := 290.0
const UNIT := 16.0

var cap: Array = []
var amt: Array = []
var target := 0
var selected := -1
var pours := 0
var pour_fx: Array = []   # [de, para, t]
var hint_move: Array = []
var reset_b := Button.new()


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("banho")
	var order := range(SETS.size())
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = order[i]
		order[i] = order[j]
		order[j] = tmp
	for idx in order:
		var s: Array = SETS[idx]
		cap = [s[0], s[1], s[2]]
		target = s[3]
		amt = [s[0], 0, 0]
		if not path_from(amt).is_empty():
			break
	if State.drafts.has("banho") and (State.drafts["banho"] as Array).size() == 3:
		amt = []
		for v in State.drafts["banho"]:
			amt.append(int(v))
	reset_b.text = "Recomeçar"
	reset_b.position = Vector2(96, 334)
	reset_b.size = Vector2(84, 20)
	reset_b.focus_mode = Control.FOCUS_NONE
	reset_b.pressed.connect(func():
		amt = [cap[0], 0, 0]
		State.drafts.erase("banho")
		selected = -1
		Audio.play("squelch", -10.0, 0.6)
		_update_hint())
	add_child(reset_b)
	_update_hint()


func _poured(state: Array, a: int, b: int) -> Array:
	var n := state.duplicate()
	var q := mini(n[a], cap[b] - n[b])
	n[a] -= q
	n[b] += q
	return n


func _reached(state: Array) -> bool:
	return target in state


## Busca em largura: lista de despejos [de, para] até o alvo ([] se impossível).
func path_from(start: Array) -> Array:
	if _reached(start):
		return [[]]
	var prev := {str(start): null}
	var queue := [start]
	while not queue.is_empty():
		var s: Array = queue.pop_front()
		for a in 3:
			for b in 3:
				if a == b or s[a] == 0 or s[b] == cap[b]:
					continue
				var n := _poured(s, a, b)
				var k := str(n)
				if prev.has(k):
					continue
				prev[k] = [str(s), a, b, s]
				if _reached(n):
					var path: Array = []
					var cur := k
					while prev[cur] != null:
						var st: Array = prev[cur]
						path.push_front([st[1], st[2]])
						cur = st[0]
					return path
				queue.append(n)
	return []


func _update_hint() -> void:
	hint_move = []
	if State.flag("hint2_banho"):
		var path := path_from(amt)
		if not path.is_empty() and path[0].size() == 2:
			hint_move = path[0]


static func hint(level: int) -> String:
	if level == 1:
		return "Use o frasco do meio como passagem e o menor para medir. Às vezes é preciso devolver sangue ao frasco grande."
	return "A prancheta acende, em azul, de qual frasco para qual despejar."


func _vial_rect(i: int) -> Rect2:
	var h: float = cap[i] * UNIT
	return Rect2(Vector2(XS[i] - 24, BASE_Y - h), Vector2(48, h))


func _vial_at(p: Vector2) -> int:
	for i in 3:
		if _vial_rect(i).grow(8).has_point(p):
			return i
	return -1


func _gui_input(event: InputEvent) -> void:
	if done or not pour_fx.is_empty():
		return
	if event is InputEventMouseMotion:
		set_cursor("hand" if _vial_at(event.position) >= 0 else "flame")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var v := _vial_at(event.position)
		if v < 0:
			selected = -1
			return
		if selected < 0 or selected == v:
			selected = v if amt[v] > 0 and selected != v else -1
			if selected >= 0:
				Audio.play("tile", -12.0, 1.4)
			return
		if amt[selected] == 0 or amt[v] == cap[v]:
			Audio.play("tile", -12.0, 0.5)
			selected = -1
			return
		pour_fx = [selected, v, 0.0]
		selected = -1


func _process(delta: float) -> void:
	super(delta)
	if pour_fx.is_empty():
		return
	pour_fx[2] += delta / 0.6
	if pour_fx[2] >= 1.0:
		amt = _poured(amt, pour_fx[0], pour_fx[1])
		pour_fx = []
		pours += 1
		Audio.play("squelch", -6.0, randf_range(0.6, 0.9))
		State.drafts["banho"] = amt.duplicate()
		_update_hint()
		if _reached(amt):
			State.drafts.erase("banho")
			Audio.play("sting", -8.0, 0.8)
			say("DÁLIA", "Exatamente %d dedos. Despejo no ralo, e a banheira começa a esvaziar sozinha." % target)
			finish()
		elif pours == 25:
			say("MORVANT", "O sangue não é infinito, médium. Bem, nesta casa quase.")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.05, 0.055, 0.06))
	# Azulejos ao fundo
	for i in 16:
		for j in 10:
			draw_rect(Rect2(i * 40 + 1, j * 36 + 1, 38, 34), Color(0.12, 0.13, 0.13))
	var font := get_theme_default_font()
	# Prateleira
	draw_rect(Rect2(150, BASE_Y, 340, 8), Color(0.3, 0.18, 0.1))
	for i in 3:
		var r := _vial_rect(i)
		var level: float = float(amt[i])
		if not pour_fx.is_empty():
			var q := mini(amt[pour_fx[0]], cap[pour_fx[1]] - amt[pour_fx[1]])
			if i == pour_fx[0]:
				level -= q * pour_fx[2]
			elif i == pour_fx[1]:
				level += q * pour_fx[2]
		var lh := level * UNIT
		draw_rect(Rect2(r.position.x + 3, BASE_Y - lh, r.size.x - 6, lh), Color(0.5, 0.0, 0.04))
		draw_rect(Rect2(r.position.x + 3, BASE_Y - lh, r.size.x - 6, 2), Color(0.7, 0.08, 0.1))
		draw_rect(r, Color(0.75, 0.85, 0.85, 0.08))
		draw_rect(r, Color(0.7, 0.8, 0.8, 0.7), false, 1.0)
		draw_rect(Rect2(r.position + Vector2(6, 4), Vector2(3, r.size.y - 8)), Color(1, 1, 1, 0.15))
		for m in cap[i]:
			var y: float = BASE_Y - (m + 1) * UNIT
			draw_line(Vector2(r.end.x - 10, y), Vector2(r.end.x - 3, y), Color(0.8, 0.85, 0.85, 0.6), 1.0)
		draw_rect(Rect2(r.position.x + 8, r.position.y - 8, r.size.x - 16, 8), Color(0.45, 0.36, 0.22))
		draw_string(font, Vector2(r.position.x, BASE_Y + 22), "%d / %d" % [amt[i], cap[i]], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10, Color(0.85, 0.8, 0.7))
		if i == selected:
			draw_rect(r.grow(3), Color(0.9, 0.15, 0.1), false, 1.0)
		if hint_move.size() == 2 and (i == hint_move[0] or i == hint_move[1]):
			draw_rect(r.grow(5), Color(0.4, 0.9, 1.0, 0.35 + 0.3 * sin(t * 5.0)), false, 1.0)
	if not pour_fx.is_empty():
		var a := _vial_rect(pour_fx[0])
		var b := _vial_rect(pour_fx[1])
		var from := Vector2(a.get_center().x, a.position.y - 6)
		var to := Vector2(b.get_center().x, b.position.y + 4)
		var mid := (from + to) * 0.5 + Vector2(0, -40)
		var prev := from
		for k in 10:
			var s := (k + 1) / 10.0
			var q2 := from.lerp(mid, s).lerp(mid.lerp(to, s), s)
			draw_line(prev, q2, Color(0.55, 0.0, 0.04), 3.0)
			prev = q2
	draw_string(font, Vector2(270, 26), "O BANHO", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(150, 44), "O ralo só aceita exatamente %d dedos. Despeje de um frasco para outro." % target, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.68, 0.58))
	draw_string(font, Vector2(520, 200), "despejos: %d" % pours, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.5, 0.4))
