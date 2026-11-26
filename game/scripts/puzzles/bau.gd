extends "res://scripts/puzzles/puzzle.gd"
## O BAÚ — o cadeado de Morvant tem quatro discos com seis símbolos, sem
## repetir. A cada tentativa, os mortos respondem de dentro do baú: uma
## batida para cada símbolo no lugar certo, um arranhão para cada símbolo
## certo no lugar errado. Oito tentativas; depois disso Morvant troca a
## combinação. A semente sorteia as combinações.

const SYMS := 6
const LEN := 4
const TRIES := 8
const NAMES := ["cruz", "peixe", "chave", "cálice", "estrela", "olho"]
const SLOT_X := [236, 292, 348, 404]
const SLOT_Y := 250.0

var rng := RandomNumberGenerator.new()
var code: Array = []
var guess: Array = [0, 1, 2, 3]
var rows: Array = []        # [palpite, batidas, arranhões]
var fixed := -1
var tries_max := TRIES
var try_btn := Button.new()
var answer_t := 0.0
var reset_t := 0.0
var sounds: Array = []      # [instante, "batida" | "arranhão" | "nada"]


func build() -> void:
	rng.seed = State.puzzle_seed("bau")
	tries_max = 6 if State.dark_night else TRIES
	new_code()
	if State.flag("hint2_bau"):
		fixed = 0
		_lock_first()
	try_btn.text = "Girar a chave"
	try_btn.position = Vector2(282, 300)
	try_btn.size = Vector2(110, 22)
	try_btn.focus_mode = Control.FOCUS_NONE
	try_btn.pressed.connect(func(): try_guess(guess))
	add_child(try_btn)


## Pista 2: o primeiro disco fica no símbolo certo; os outros, sem repetir.
func _lock_first() -> void:
	guess = [code[0]]
	for v in SYMS:
		if guess.size() < LEN and v != code[0]:
			guess.append(v)


func new_code() -> void:
	var pool: Array = range(SYMS)
	code = []
	for k in LEN:
		var j := rng.randi() % pool.size()
		code.append(pool[j])
		pool.remove_at(j)
	rows = []


static func hint(level: int) -> String:
	if level == 1:
		return "Mude pouca coisa de uma tentativa para a outra. Se as batidas aumentam, o que você mexeu foi para o lugar certo."
	return "A prancheta travou o primeiro disco no símbolo certo."


static func score(g: Array, c: Array) -> Vector2i:
	var hits := 0
	var near := 0
	for i in LEN:
		if g[i] == c[i]:
			hits += 1
		elif c.has(g[i]):
			near += 1
	return Vector2i(hits, near)


func try_guess(g: Array) -> Vector2i:
	if done or reset_t > 0.0:
		return Vector2i(-1, -1)
	var seen := {}
	for v in g:
		if seen.has(v):
			Audio.play("wrong", -8.0)
			say("MORVANT", "Cada símbolo uma vez só, médium. Eu não repito, e o cadeado também não.")
			return Vector2i(-1, -1)
		seen[v] = true
	var sc := score(g, code)
	rows.append([g.duplicate(), sc.x, sc.y])
	answer_t = 0.0
	_play_answer(sc)
	if sc.x == LEN:
		Audio.play("door", -4.0, 0.7)
		say("DÁLIA", "O cadeado cede. Lá dentro: um caderno de costura, linha preta... e uma chave com um olho gravado.")
		finish()
	elif rows.size() >= tries_max:
		State.change_sanity(-8.0)
		Audio.play("laugh", -6.0, 0.9)
		say("MORVANT", "Tentativas demais, e nada. Vou trocar a combinação. Os mortos também cansam de bater.")
		reset_t = 2.0
	return sc


func _play_answer(sc: Vector2i) -> void:
	# Batidas secas e arranhões, uma a uma, de dentro do baú.
	sounds = []
	var i := 0
	for k in sc.x:
		sounds.append([0.35 + i * 0.32, "batida"])
		i += 1
	for k in sc.y:
		sounds.append([0.35 + i * 0.32, "arranhão"])
		i += 1
	if sc == Vector2i.ZERO:
		sounds.append([0.4, "nada"])


func _gui_input(event: InputEvent) -> void:
	if done or not (event is InputEventMouseButton and event.pressed):
		return
	for k in LEN:
		if Rect2(Vector2(SLOT_X[k] - 22, SLOT_Y - 26), Vector2(44, 52)).has_point(event.position):
			if k == fixed:
				Audio.play("locked", -12.0)
				return
			var dir := -1 if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 1
			guess[k] = posmod(guess[k] + dir, SYMS)
			Audio.play("tick", -8.0, 1.4)
			return


func _process(delta: float) -> void:
	super(delta)
	answer_t += delta
	while not sounds.is_empty() and answer_t >= sounds[0][0]:
		match String(sounds.pop_front()[1]):
			"batida":
				Audio.play("slam", -10.0, 2.2)
				shake(0.08)
			"arranhão":
				Audio.play("creak", -10.0, 2.4)
			_:
				Audio.play("whisper", -12.0, 0.7)
	if reset_t > 0.0:
		reset_t -= delta
		if reset_t <= 0.0:
			new_code()
			if fixed == 0:
				_lock_first()
	try_btn.disabled = done or reset_t > 0.0


func _glyph(c: Vector2, v: int, s: float, col: Color) -> void:
	match v:
		0:
			draw_line(c + Vector2(0, -6) * s, c + Vector2(0, 6) * s, col, 2.0)
			draw_line(c + Vector2(-4, -2) * s, c + Vector2(4, -2) * s, col, 2.0)
		1:
			draw_arc(c + Vector2(-1, -3) * s, 6.0 * s, 0.6, 2.5, 8, col, 1.5)
			draw_arc(c + Vector2(-1, 3) * s, 6.0 * s, -2.5, -0.6, 8, col, 1.5)
			draw_line(c + Vector2(4, 0) * s, c + Vector2(7, -3) * s, col, 1.5)
			draw_line(c + Vector2(4, 0) * s, c + Vector2(7, 3) * s, col, 1.5)
		2:
			draw_arc(c + Vector2(-3, 0) * s, 3.0 * s, 0, TAU, 10, col, 1.5)
			draw_line(c, c + Vector2(7, 0) * s, col, 1.5)
			draw_line(c + Vector2(5, 0) * s, c + Vector2(5, 3) * s, col, 1.5)
		3:
			draw_arc(c + Vector2(0, -4) * s, 4.0 * s, 0, PI, 8, col, 1.5)
			draw_line(c, c + Vector2(0, 5) * s, col, 1.5)
			draw_line(c + Vector2(-3, 5) * s, c + Vector2(3, 5) * s, col, 1.5)
		4:
			for k in 5:
				var a := TAU * k / 5.0 - PI / 2.0
				var b := TAU * (k + 2) / 5.0 - PI / 2.0
				draw_line(c + Vector2(cos(a), sin(a)) * 6.0 * s, c + Vector2(cos(b), sin(b)) * 6.0 * s, col, 1.0)
		5:
			draw_arc(c + Vector2(0, 3) * s, 6.0 * s, -2.6, -0.54, 8, col, 1.5)
			draw_arc(c + Vector2(0, -3) * s, 6.0 * s, 0.54, 2.6, 8, col, 1.5)
			draw_circle(c, 1.6 * s, col)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.035, 0.025, 0.025))
	var font := get_theme_default_font()
	# A tampa do baú, de couro, com as tentativas riscadas a giz por dentro.
	var lid := Rect2(40, 40, 170, 270)
	draw_rect(lid, Color(0.2, 0.08, 0.05))
	draw_rect(lid, Color(0.5, 0.38, 0.2), false, 2.0)
	draw_string(font, Vector2(52, 58), "tentativas", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.75, 0.72, 0.65))
	for r in tries_max:
		var y := 70.0 + r * 29.0
		draw_line(Vector2(52, y + 24), Vector2(198, y + 24), Color(0.3, 0.14, 0.1), 1.0)
		if r >= rows.size():
			continue
		var row: Array = rows[r]
		var g: Array = row[0]
		for k in LEN:
			_glyph(Vector2(64 + k * 22, y + 12), g[k], 0.9, Color(0.85, 0.82, 0.75))
		var shown: float = 99.0 if r < rows.size() - 1 else answer_t
		var i := 0
		for k in row[1]:
			if shown > 0.35 + i * 0.32:
				# Batida: marca de nó de dedo ensanguentado.
				draw_circle(Vector2(160 + i * 9, y + 12), 3, Color(0.6, 0.05, 0.05) if State.gore else Color(0.9, 0.9, 0.85))
			i += 1
		for k in row[2]:
			if shown > 0.35 + i * 0.32:
				var sx := 160.0 + i * 9
				for l in 3:
					draw_line(Vector2(sx - 3 + l * 2, y + 7), Vector2(sx - 2 + l * 2, y + 17), Color(0.85, 0.85, 0.8), 1.0)
			i += 1
	# O cadeado: placa de latão com quatro discos.
	brass_frame(Rect2(208, 196, 228, 96), 2.0)
	draw_rect(Rect2(214, 202, 216, 84), Color(0.42, 0.3, 0.14))
	for k in LEN:
		var c := Vector2(SLOT_X[k], SLOT_Y)
		draw_rect(Rect2(c - Vector2(20, 24), Vector2(40, 48)), Color(0.12, 0.08, 0.05))
		var prev := posmod(guess[k] - 1, SYMS)
		var nxt := posmod(guess[k] + 1, SYMS)
		_glyph(c + Vector2(0, -16), prev, 0.7, Color(0.5, 0.42, 0.3))
		_glyph(c, guess[k], 1.3, Color(0.95, 0.85, 0.55) if k != fixed else Color(0.6, 0.9, 1.0))
		_glyph(c + Vector2(0, 16), nxt, 0.7, Color(0.5, 0.42, 0.3))
		draw_rect(Rect2(c - Vector2(20, 9), Vector2(40, 18)), Color(0.9, 0.7, 0.35, 0.12))
	# O baú, aberto um palmo: lá dentro, escuridão e às vezes dedos.
	draw_rect(Rect2(240, 70, 300, 110), Color(0.16, 0.06, 0.04))
	draw_rect(Rect2(250, 80, 280, 20), Color(0.0, 0.0, 0.0))
	if rows.size() > 0 and answer_t < 2.5:
		for f in 4:
			var fx := 330.0 + f * 9.0 + sin(t * 9.0 + f) * 2.0
			draw_rect(Rect2(fx, 80, 4, 10 + 4 * sin(t * 6.0 + f)), Color(0.62, 0.95, 0.9, 0.6))
	draw_string(font, Vector2(448, 212), "batida: símbolo no lugar", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.75, 0.68, 0.58))
	draw_string(font, Vector2(448, 224), "arranhão: símbolo fora do lugar", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.75, 0.68, 0.58))
	draw_string(font, Vector2(290, 20), "O BAÚ", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(0, 340), "Clique num disco para girá-lo (botão direito volta). Seis símbolos, nenhum repetido.", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.6, 0.55, 0.48))
