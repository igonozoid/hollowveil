extends "res://scripts/puzzles/puzzle.gd"
## A PRANCHETA — a mesa girante soletra uma mensagem cifrada. As letras de
## posição ímpar usam um deslocamento (anel do Sol) e as de posição par,
## outro (anel da Lua). Gire os dois anéis até a mensagem fazer sentido.
## Pista embutida: os mortos sempre começam chamando Dália pelo nome.

const MESSAGES := [
	"DALIA ELA CANTA NA SALA DE MUSICA",
	"DALIA A VOZ DELA AINDA ESTA NA SALA DE MUSICA",
	"DALIA SIGA O CANTO ATE A SALA DE MUSICA",
]
const ALPHA := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const DISC := [Vector2(200, 284), Vector2(440, 284)]
const DISC_R := 44.0

var plain := ""
var cipher := ""
var key := [0, 0]
var ring := [0, 0]
var locked := [false, false]
var spell_t := 0.0
var win_t := -1.0


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("prancheta")
	plain = MESSAGES[rng.randi() % MESSAGES.size()]
	key[0] = rng.randi_range(3, 23)
	key[1] = rng.randi_range(3, 23)
	while key[1] == key[0]:
		key[1] = rng.randi_range(3, 23)
	cipher = _shift(plain, [-key[0], -key[1]])
	if State.drafts.has("prancheta"):
		var d: Array = State.drafts["prancheta"]
		ring = [int(d[0]), int(d[1])]
	if State.flag("hint2_prancheta"):
		ring[0] = key[0]
		locked[0] = true
	var ask := Button.new()
	ask.text = "Perguntar aos mortos"
	ask.position = Vector2(484, 334)
	ask.size = Vector2(148, 20)
	ask.focus_mode = Control.FOCUS_NONE
	ask.pressed.connect(_ask)
	add_child(ask)


## O tabuleiro é a própria fonte de pistas: pedir ajuda daqui mesmo.
func _ask() -> void:
	if house == null or done:
		return
	house.hint_for("prancheta")
	if State.flag("hint2_prancheta") and not locked[0]:
		ring[0] = key[0]
		locked[0] = true


## Aplica os deslocamentos alternados só às letras (espaços não contam).
func _shift(text: String, k: Array) -> String:
	var out := ""
	var n := 0
	for ch in text:
		var i := ALPHA.find(ch)
		if i < 0:
			out += ch
			continue
		out += ALPHA[posmod(i + int(k[n % 2]), 26)]
		n += 1
	return out


func decoded() -> String:
	return _shift(cipher, ring)


static func hint(level: int) -> String:
	if level == 1:
		return "Os mortos sempre começam pelo seu nome. Se a primeira letra deve ser D, quanto o anel do Sol precisa girar?"
	return "A prancheta fixou o anel do Sol no lugar certo. Falta só o da Lua."


func _gui_input(event: InputEvent) -> void:
	if done:
		return
	var d := _disc_at(event.position) if event is InputEventMouse else -1
	if event is InputEventMouseMotion:
		set_cursor("hand" if d >= 0 and not locked[d] else "flame")
	elif event is InputEventMouseButton and event.pressed and d >= 0 and not locked[d]:
		var step := 0
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				step = -1 if event.position.x < DISC[d].x else 1
			MOUSE_BUTTON_WHEEL_UP:
				step = 1
			MOUSE_BUTTON_WHEEL_DOWN:
				step = -1
		if step != 0:
			ring[d] = posmod(ring[d] + step, 26)
			Audio.play("tile", -10.0, 0.7 + d * 0.3)
			State.drafts["prancheta"] = ring.duplicate()
			if decoded() == plain:
				win_t = 0.0
				State.drafts.erase("prancheta")
				Audio.play("planchette", 0.0)
				Audio.play("sting", -8.0, 1.3)
				say("DÁLIA", "\"" + plain.substr(0, 1) + plain.substr(1).to_lower() + ".\" A porta da sala de música... ouvi ela destrancar.")
				finish()


func _disc_at(p: Vector2) -> int:
	for i in 2:
		if (DISC[i] as Vector2).distance_to(p) <= DISC_R + 4.0:
			return i
	return -1


func _process(delta: float) -> void:
	super(delta)
	spell_t += delta
	if win_t >= 0.0:
		win_t += delta


func _letter_pos(ch: String) -> Vector2:
	# As letras do tabuleiro ficam em dois arcos.
	var i := ALPHA.find(ch)
	if i < 0:
		return Vector2(320, 132)
	var row := 0 if i < 13 else 1
	var k := (i % 13) / 12.0
	var ang := lerpf(PI * 1.18, PI * 1.82, k)
	var r := 150.0 if row == 0 else 112.0
	return Vector2(320, 205) + Vector2(cos(ang), sin(ang)) * Vector2(r * 1.25, r * 0.95)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.04, 0.03, 0.03))
	# O tabuleiro
	var board := Rect2(96, 24, 448, 168)
	draw_rect(board, Color(0.45, 0.3, 0.16))
	draw_rect(board.grow(-4), Color(0.58, 0.42, 0.24))
	draw_rect(board, Color(0.25, 0.14, 0.07), false, 2.0)
	var font := get_theme_default_font()
	var ink := Color(0.15, 0.07, 0.03)
	for i in 26:
		var ch := ALPHA[i]
		draw_string(font, _letter_pos(ch) - Vector2(4, -4), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)
	draw_string(font, Vector2(112, 44), "SIM", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)
	draw_string(font, Vector2(500, 44), "NÃO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)
	draw_string(font, Vector2(296, 182), "ADEUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ink)
	draw_circle(Vector2(140, 66), 10, Color(0.85, 0.7, 0.3))
	draw_arc(Vector2(500, 66), 10, PI * 0.3, PI * 1.7, 12, Color(0.85, 0.75, 0.5), 3.0)
	# A prancheta soletrando a mensagem cifrada, letra por letra.
	var letters := cipher.replace(" ", "")
	var idx := int(spell_t / 0.7) % (letters.length() + 3)
	var target := Vector2(150, 62) if win_t >= 0.0 else (_letter_pos(letters[idx]) if idx < letters.length() else Vector2(320, 132))
	var prev := _letter_pos(letters[maxi(idx - 1, 0)]) if idx > 0 and idx <= letters.length() else target
	var k := clampf(fmod(spell_t, 0.7) / 0.35, 0.0, 1.0)
	var pp := prev.lerp(target, ease(k, -2.0))
	draw_colored_polygon(PackedVector2Array([pp + Vector2(0, -22), pp + Vector2(16, 6), pp + Vector2(-16, 6)]), Color(0.75, 0.6, 0.38))
	draw_circle(pp + Vector2(0, -6), 6, Color(0.2, 0.25, 0.3))
	draw_circle(pp + Vector2(-2, -8), 2, Color(0.8, 0.85, 0.9, 0.6))
	# Faixas: o que foi soletrado e o que os anéis traduzem.
	draw_string(font, Vector2(60, 210), "SOLETRADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.5, 0.4))
	draw_string(font, Vector2(60, 230), "TRADUZIDO", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.5, 0.4))
	var dec := decoded()
	var x := 128.0
	var n := 0
	for i in cipher.length():
		var c := cipher[i]
		draw_string(font, Vector2(x, 211), c, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.62, 0.5))
		var col := Color(0.95, 0.78, 0.35) if n % 2 == 0 else Color(0.75, 0.8, 0.9)
		if c == " ":
			col = Color(0, 0, 0, 0)
		elif win_t >= 0.0:
			col = Color(1.0, 0.3, 0.25)
		draw_string(font, Vector2(x, 231), dec[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)
		if c != " ":
			n += 1
		x += 10.0
	# Os dois anéis decodificadores
	for d in 2:
		_disc(d, font)
	draw_string(font, Vector2(268, 16), "A PRANCHETA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(260, 280), "clique na metade", HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color(0.6, 0.5, 0.4))
	draw_string(font, Vector2(260, 291), "esquerda ou direita", HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color(0.6, 0.5, 0.4))
	draw_string(font, Vector2(260, 302), "de um anel, ou role", HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color(0.6, 0.5, 0.4))


func _disc(d: int, font: Font) -> void:
	var c: Vector2 = DISC[d]
	var sun := d == 0
	var metal := Color(0.75, 0.56, 0.24) if sun else Color(0.62, 0.66, 0.72)
	draw_circle(c, DISC_R + 3, Color(0.1, 0.07, 0.05))
	draw_circle(c, DISC_R, metal.darkened(0.4))
	draw_circle(c, DISC_R - 14, metal.darkened(0.2))
	draw_circle(c, 12, metal)
	# Letras de fora (fixas) e de dentro (giram com o anel).
	for i in 26:
		var ang := -PI * 0.5 + TAU * i / 26.0
		var o := c + Vector2(cos(ang), sin(ang)) * (DISC_R - 6) - Vector2(3, -3)
		draw_string(font, o, ALPHA[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.95, 0.9, 0.8))
		var inner := c + Vector2(cos(ang), sin(ang)) * (DISC_R - 20) - Vector2(3, -3)
		draw_string(font, inner, ALPHA[posmod(i + ring[d], 26)], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.15, 0.08, 0.04))
	draw_line(c + Vector2(0, -DISC_R - 6), c + Vector2(0, -DISC_R + 16), Color(0.9, 0.2, 0.15), 1.0)
	if sun:
		for r in 8:
			var a := TAU * r / 8.0 + t * 0.2
			draw_line(c + Vector2(cos(a), sin(a)) * 5, c + Vector2(cos(a), sin(a)) * 10, Color(0.95, 0.75, 0.3), 1.0)
	else:
		draw_circle(c, 7, Color(0.85, 0.88, 0.92))
		draw_circle(c + Vector2(3, -2), 6, metal)
	draw_string(font, c + Vector2(-20, DISC_R + 14), "SOL" if sun else "LUA", HORIZONTAL_ALIGNMENT_CENTER, 40, 8, metal)
	if locked[d]:
		draw_arc(c, DISC_R + 5, 0, TAU, 24, Color(0.4, 0.9, 1.0, 0.6), 1.0)
	draw_string(font, c + Vector2(-DISC_R - 14, 4), "‹", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.6, 0.45))
	draw_string(font, c + Vector2(DISC_R + 6, 4), "›", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.6, 0.45))
