extends "res://scripts/puzzles/puzzle.gd"
## A CEIA — plano de mesa por lógica. Seis convidados, seis cadeiras laterais.
## O doutor ocupa a cabeceira; a outra cabeceira tem o nome de Dália.
## A semente gera a disposição e o menor conjunto de pistas com solução única.

const GUESTS := ["Celeste", "Ofélia", "Tobias", "Pe. Anselmo", "Leocádia", "Cap. Hélio"]
## Cadeiras: 0-2 lado das janelas (direita, do doutor para baixo), 3-5 lado da lareira.
const SEAT_POS := [Vector2(432, 110), Vector2(432, 176), Vector2(432, 242), Vector2(208, 110), Vector2(208, 176), Vector2(208, 242)]
const TABLE := Rect2(254, 56, 132, 252)
const POOL := Rect2(10, 40, 140, 200)
const LETTER := Rect2(468, 10, 164, 314)

var solution: Array = []
var clues: Array = []
var seats: Array = [-1, -1, -1, -1, -1, -1]
var locked: Array = [false, false, false, false, false, false]
var held := -1
var serve := Button.new()
var letter := Label.new()
var wrong_t := 0.0
var attempts := 0
var win_t := -1.0


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("ceia")
	_generate(rng)
	if State.drafts.has("ceia"):
		var d: Array = State.drafts["ceia"]
		if d.size() == 6:
			for i in 6:
				seats[i] = int(d[i])
	if State.flag("hint2_ceia"):
		# A prancheta fixou dois lugares.
		for k in 2:
			var s := (k * 4 + rng.randi_range(0, 1)) % 6
			var g: int = solution[s]
			for i in 6:
				if seats[i] == g:
					seats[i] = -1
			seats[s] = g
			locked[s] = true
	serve.text = "Servir o jantar"
	serve.position = Vector2(14, 250)
	serve.size = Vector2(132, 22)
	serve.focus_mode = Control.FOCUS_NONE
	serve.pressed.connect(_serve)
	add_child(serve)
	letter.position = LETTER.position + Vector2(8, 8)
	letter.size = LETTER.size - Vector2(16, 16)
	letter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	letter.add_theme_font_size_override("font_size", 8)
	letter.add_theme_color_override("font_color", Color(0.22, 0.12, 0.08))
	letter.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	var txt := "PLANO DE MESA — 31 de outubro\n(anotado por Benedita)\n\n"
	for c in clues:
		txt += "· " + _clue_text(c) + "\n"
	txt += "\nA cadeira do fim é da senhora que vem depois. O doutor insistiu."
	letter.text = txt
	add_child(letter)


# ---------------------------------------------------------------- geração

func _generate(rng: RandomNumberGenerator) -> void:
	var perm := [0, 1, 2, 3, 4, 5]
	for i in range(5, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = perm[i]
		perm[i] = perm[j]
		perm[j] = tmp
	solution = perm
	var all := _perms([0, 1, 2, 3, 4, 5])
	var rel: Array = []
	var direct: Array = []
	for a in 6:
		direct.append(["side", a, 0])
		direct.append(["pos", a, 0])
		for b in 6:
			if a == b:
				continue
			for kind in ["adj", "face", "notadj", "closer"]:
				if (kind in ["adj", "face", "notadj"]) and b < a:
					continue
				var c := [kind, a, b]
				if _holds(c, solution):
					rel.append(c)
	for c in direct:
		if c[0] == "side":
			c[2] = 0 if _seat_of(c[1], solution) < 3 else 1
		else:
			c[2] = _seat_of(c[1], solution) % 3
	_shuffle(rel, rng)
	_shuffle(direct, rng)
	var cands: Array = rel + direct
	var left := all
	clues = []
	for c in cands:
		var next: Array = []
		for p in left:
			if _holds(c, p):
				next.append(p)
		if next.size() < left.size():
			clues.append(c)
			left = next
			if left.size() == 1:
				break
	# Enxuga: tira pistas que sobram.
	for i in range(clues.size() - 1, -1, -1):
		var trial := clues.duplicate()
		trial.remove_at(i)
		if _count(all, trial) == 1:
			clues = trial
	_shuffle(clues, rng)


func _count(all: Array, cl: Array) -> int:
	var n := 0
	for p in all:
		var ok := true
		for c in cl:
			if not _holds(c, p):
				ok = false
				break
		if ok:
			n += 1
			if n > 1:
				return n
	return n


func _perms(items: Array) -> Array:
	if items.size() <= 1:
		return [items]
	var out: Array = []
	for i in items.size():
		var rest := items.duplicate()
		var head = rest.pop_at(i)
		for p in _perms(rest):
			out.append([head] + p)
	return out


func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func _seat_of(g: int, arr: Array) -> int:
	return arr.find(g)


func _holds(c: Array, arr: Array) -> bool:
	var sa := _seat_of(c[1], arr)
	match c[0]:
		"side":
			return (0 if sa < 3 else 1) == c[2]
		"pos":
			return sa % 3 == c[2]
	var sb := _seat_of(c[2], arr)
	var same_side := (sa < 3) == (sb < 3)
	match c[0]:
		"adj":
			return same_side and absi(sa % 3 - sb % 3) == 1
		"notadj":
			return not (same_side and absi(sa % 3 - sb % 3) == 1)
		"face":
			return not same_side and sa % 3 == sb % 3
		"closer":
			return sa % 3 < sb % 3
	return false


func _clue_text(c: Array) -> String:
	var a: String = GUESTS[c[1]]
	match c[0]:
		"side":
			return a + (" quis o lado das janelas." if c[2] == 0 else " ficou do lado da lareira.")
		"pos":
			return [a + " sentou junto ao doutor.", a + " ficou numa cadeira do meio.", a + " ficou ao lado da cadeira vazia."][c[2]]
	var b: String = GUESTS[c[2]]
	match c[0]:
		"adj":
			return a + " e " + b + " jantaram lado a lado."
		"notadj":
			return a + " se recusou a sentar ao lado de " + b + "."
		"face":
			return a + " passou o jantar encarando " + b + ", do outro lado da mesa."
		"closer":
			return a + " ficou mais perto do doutor do que " + b + "."
	return ""


static func hint(level: int) -> String:
	if level == 1:
		return "Comece por quem tem lugar fixo: junto ao doutor, no meio, junto à cadeira vazia. Depois, quem encara quem."
	return "Dois convidados agora têm lugar marcado na mesa. Eles não saem de lá."


# ---------------------------------------------------------------- entrada

func _seat_at(p: Vector2) -> int:
	for i in 6:
		if Rect2(SEAT_POS[i] - Vector2(30, 14), Vector2(60, 28)).has_point(p):
			return i
	return -1


func _pool_list() -> Array:
	var out: Array = []
	for g in 6:
		if not g in seats and g != held:
			out.append(g)
	return out


func _pool_at(p: Vector2) -> int:
	var list := _pool_list()
	for k in list.size():
		if Rect2(POOL.position + Vector2(10, 24 + k * 26), Vector2(120, 20)).has_point(p):
			return list[k]
	return -1


func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseMotion:
		var over := _seat_at(event.position) >= 0 or _pool_at(event.position) >= 0
		set_cursor("hand" if over or held >= 0 else "flame")
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		held = -1
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	var s := _seat_at(event.position)
	if s >= 0:
		if locked[s]:
			Audio.play("locked", -10.0)
			return
		Audio.play("card", -4.0, randf_range(0.9, 1.1))
		var prev: int = seats[s]
		seats[s] = held
		held = prev
		_save_draft()
		return
	var g := _pool_at(event.position)
	if g >= 0:
		Audio.play("card", -6.0)
		held = g
		return
	if held >= 0 and POOL.has_point(event.position):
		held = -1
		Audio.play("card", -8.0, 0.8)


func _save_draft() -> void:
	State.drafts["ceia"] = seats.duplicate()


func _serve() -> void:
	if done or -1 in seats:
		say("DÁLIA", "Ainda há cadeiras sem nome.")
		return
	attempts += 1
	if seats == solution:
		Audio.play("sting", -8.0, 1.2)
		win_t = 0.0
		finish()
		return
	wrong_t = 1.0
	Audio.play("wrong", -4.0)
	Audio.play("heart", -2.0)
	shake(0.6)
	State.change_sanity(-4.0)
	var lines := ["Errado. A sopa esfriou de novo.", "Leocádia nunca sentaria aí. Ela odiava correntes de ar.",
		"Tente outra vez. Temos a eternidade, e ela é longa.", "Você está me fazendo perder o apetite."]
	say("MORVANT", lines[(attempts - 1) % lines.size()])


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	# Fundo: o tapete visto de cima, escuro, com a borda em losangos.
	draw_rect(Rect2(0, 0, 640, 360), Color(0.07, 0.03, 0.03))
	for i in 24:
		draw_rect(Rect2(170 + i * 13, 26, 6, 6), Color(0.16, 0.05, 0.05))
		draw_rect(Rect2(170 + i * 13, 330, 6, 6), Color(0.16, 0.05, 0.05))
	# Mesa
	draw_rect(TABLE.grow(4), Color(0.2, 0.1, 0.06))
	draw_rect(TABLE, Color(0.74, 0.7, 0.62))
	for i in 12:
		draw_line(Vector2(TABLE.position.x, TABLE.position.y + i * 21), Vector2(TABLE.end.x, TABLE.position.y + i * 21), Color(0.68, 0.64, 0.56))
	# Cabeceiras: o doutor e a cadeira de Dália.
	_head(Vector2(320, 34), "DR. MORVANT", Color(0.55, 0.1, 0.08))
	_head(Vector2(320, 330), "D. FERRAZ", Color(0.3, 0.25, 0.2))
	# Castiçais
	for y in [120.0, 240.0]:
		var c := Vector2(320, y)
		draw_rect(Rect2(c - Vector2(8, 2), Vector2(16, 4)), Color(0.6, 0.44, 0.2))
		for dx in [-6, 0, 6]:
			var fl := 1.0 + 0.3 * sin(t * 11.0 + dx) * sin(t * 4.0)
			draw_rect(Rect2(c + Vector2(dx - 1, -9), Vector2(2, 7)), Color(0.86, 0.8, 0.66))
			draw_colored_polygon(PackedVector2Array([c + Vector2(dx, -15 * fl), c + Vector2(dx + 2, -10), c + Vector2(dx, -8), c + Vector2(dx - 2, -10)]), Color(1, 0.65, 0.25))
	# Lugares
	for i in 6:
		var sp: Vector2 = SEAT_POS[i]
		var right := i < 3
		var plate := Vector2(TABLE.end.x - 22 if right else TABLE.position.x + 22, sp.y)
		_plate(plate, i)
		var chair := Rect2(sp - Vector2(28, 12), Vector2(56, 24))
		draw_rect(chair, Color(0.22, 0.11, 0.06))
		draw_rect(chair, Color(0.4, 0.22, 0.12), false, 1.0)
		if seats[i] >= 0:
			_card(chair.get_center(), GUESTS[seats[i]], locked[i])
		else:
			draw_string(get_theme_default_font(), chair.position + Vector2(18, 16), "vazio", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.4, 0.3, 0.25))
	# Lado das janelas / lareira
	draw_string(get_theme_default_font(), Vector2(402, 300), "janelas »", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.5, 0.55, 0.7))
	draw_string(get_theme_default_font(), Vector2(180, 300), "« lareira", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.9, 0.45, 0.2))
	# Monte de cartões
	brass_frame(POOL)
	draw_string(get_theme_default_font(), POOL.position + Vector2(10, 16), "CARTÕES DE LUGAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.85, 0.66, 0.36))
	var list := _pool_list()
	for k in list.size():
		_card(POOL.position + Vector2(70, 34 + k * 26), GUESTS[list[k]], false)
	# Carta de Benedita
	draw_rect(LETTER, Color(0.78, 0.72, 0.58))
	draw_rect(LETTER, Color(0.45, 0.34, 0.2), false, 1.0)
	for i in 5:
		draw_circle(LETTER.position + Vector2(20 + i * 31, 280 + (i % 2) * 14), 3 + i % 3, Color(0.55, 0.42, 0.3, 0.4))
	draw_string(get_theme_default_font(), Vector2(244, 20), "A CEIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.66, 0.36))
	if held >= 0:
		_card(get_local_mouse_position() + Vector2(0, 10), GUESTS[held], false)


func _head(c: Vector2, name: String, col: Color) -> void:
	draw_rect(Rect2(c - Vector2(34, 10), Vector2(68, 20)), Color(0.18, 0.09, 0.05))
	draw_rect(Rect2(c - Vector2(30, 6), Vector2(60, 12)), col)
	draw_string(get_theme_default_font(), c + Vector2(-28, 4), name, HORIZONTAL_ALIGNMENT_CENTER, 56, 8, Color(0.95, 0.88, 0.75))


func _plate(c: Vector2, i: int) -> void:
	draw_circle(c, 12, Color(0.7, 0.68, 0.64))
	draw_circle(c, 8, Color(0.6, 0.58, 0.54))
	var soup := Color(0.32, 0.15, 0.06)
	if wrong_t > 0.0 and State.gore:
		soup = soup.lerp(Color(0.6, 0.0, 0.03), wrong_t)
	if win_t >= 0.0 and seats[i] == 4 and State.gore:
		soup = Color(0.62, 0.02, 0.04)
		var b := 2.0 + 2.0 * absf(sin(t * 6.0))
		draw_circle(c + Vector2(sin(t * 3.0) * 3, 0), b, Color(0.8, 0.1, 0.1))
	draw_circle(c, 6, soup)


func _card(c: Vector2, name: String, is_locked: bool) -> void:
	var r := Rect2(c - Vector2(30, 9), Vector2(60, 18))
	draw_rect(r, Color(0.9, 0.86, 0.76))
	draw_rect(r, Color(0.6, 0.42, 0.2) if not is_locked else Color(0.75, 0.1, 0.08), false, 1.0)
	draw_string(get_theme_default_font(), r.position + Vector2(2, 13), name, HORIZONTAL_ALIGNMENT_CENTER, 56, 9, Color(0.2, 0.1, 0.06))


func _process(delta: float) -> void:
	super(delta)
	wrong_t = maxf(0.0, wrong_t - delta * 0.6)
	if win_t >= 0.0:
		win_t += delta
