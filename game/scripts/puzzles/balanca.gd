extends "res://scripts/puzzles/puzzle.gd"
## A BALANÇA — nove potes de órgãos, um deles mais pesado: o coração de
## Anselmo. Só duas pesagens. Morvant decide o pote pesado depois de cada
## pesagem, sempre o pior para você, dentro do que a balança já mostrou.
## Sorte não basta: só a estratégia dos três grupos de três acha o coração.

const N := 9
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]
const ORGANS := ["um fígado", "um rim", "um baço", "um pulmão", "uma língua", "um estômago", "um útero", "uma tireoide", "um pâncreas", "dois olhos", "uma bexiga"]
const SHELF_Y := 300.0

var rng := RandomNumberGenerator.new()
var where: Array = []        # 0 prateleira, 1 prato esquerdo, 2 prato direito
var cand: Array = []         # potes que ainda podem ser o coração
var weighings := 2
var left := 2
var tilt := 0.0
var tilt_to := 0.0
var open_mode := false
var result := ""
var opened := -1
var opened_t := 0.0
var opened_what := ""
var heart := -1
var log_lines: Array = []
var weigh_btn := Button.new()
var open_btn := Button.new()


func build() -> void:
	rng.seed = State.puzzle_seed("balanca")
	weighings = 3 if State.flag("hint2_balanca") else 2
	_reset()
	weigh_btn.text = "Pesar"
	weigh_btn.position = Vector2(236, 334)
	weigh_btn.size = Vector2(80, 20)
	weigh_btn.focus_mode = Control.FOCUS_NONE
	weigh_btn.pressed.connect(func(): weigh())
	add_child(weigh_btn)
	open_btn.text = "Abrir um pote"
	open_btn.toggle_mode = true
	open_btn.position = Vector2(326, 334)
	open_btn.size = Vector2(110, 20)
	open_btn.focus_mode = Control.FOCUS_NONE
	open_btn.toggled.connect(func(on: bool): open_mode = on)
	add_child(open_btn)


func _reset() -> void:
	where = []
	for i in N:
		where.append(0)
	cand = range(N)
	left = weighings
	tilt_to = 0.0
	result = ""
	open_mode = false
	if open_btn:
		open_btn.button_pressed = false


static func hint(level: int) -> String:
	if level == 1:
		return "Não pese um contra um. Divida os nove em três grupos de três, e compare dois grupos."
	return "A prancheta convenceu a balança: você ganha uma terceira pesagem."


## Pesa o que está nos pratos. Devolve -1 (esquerda desce), 0 ou 1 (direita desce).
func weigh() -> int:
	if done or left <= 0:
		return 0
	var l: Array = []
	var r: Array = []
	for i in N:
		if where[i] == 1:
			l.append(i)
		elif where[i] == 2:
			r.append(i)
	if l.is_empty() or l.size() != r.size():
		Audio.play("wrong", -8.0)
		say("MORVANT", "O mesmo número de potes em cada prato, médium. Senão a balança só conta potes.")
		return 0
	var groups := [[], [], []]   # esquerda desce, equilíbrio, direita desce
	for c in cand:
		if c in l:
			groups[0].append(c)
		elif c in r:
			groups[2].append(c)
		else:
			groups[1].append(c)
	# Morvant escolhe o resultado que deixa mais suspeitos (desempate pela semente).
	var best := 0
	for k in 3:
		if groups[k].size() > groups[best].size():
			best = k
	var ties: Array = []
	for k in 3:
		if groups[k].size() == groups[best].size():
			ties.append(k)
	best = ties[rng.randi() % ties.size()]
	cand = groups[best]
	left -= 1
	tilt_to = [-1.0, 0.0, 1.0][best]
	Audio.play("creak", -8.0, 1.4)
	Audio.play("tile", -6.0, 0.7)
	result = ["O prato esquerdo desce.", "Os pratos ficam parados, em equilíbrio.", "O prato direito desce."][best]
	if left == 0:
		open_mode = true
		open_btn.set_pressed_no_signal(true)
	return best - 1


## Abre um pote. Acerta só se a balança já não deixa nenhuma dúvida.
func open_jar(j: int) -> void:
	if done or opened >= 0:
		return
	opened = j
	opened_t = 0.0
	if cand.size() == 1 and cand[0] == j:
		heart = j
		Audio.play("heart", 0.0, 0.8)
		Audio.play("sting", -8.0, 1.2)
		shake(0.5)
		say("DÁLIA", "Dentro do pote %s, um coração de homem. Bate uma vez quando o tiro do vinho." % ROMAN[j])
		finish()
		return
	opened_what = ORGANS[(j * 7 + rng.randi()) % ORGANS.size()]
	Audio.play("squelch", -2.0, 0.9)
	Audio.play("wrong", -6.0)
	shake(0.6)
	State.change_sanity(-6.0)
	say("MORVANT", ["Errado. Isso é %s. O coração continua batendo em outro pote." % opened_what,
		"%s. Que pena. Eu mudo os potes de lugar sempre que alguém chuta." % opened_what.capitalize(),
		"Não, médium. Isso é %s. A culpa pesa mais, eu disse." % opened_what][rng.randi() % 3])
	get_tree().create_timer(1.8).timeout.connect(func():
		opened = -1
		_reset())


func _jar_pos(i: int) -> Vector2:
	match int(where[i]):
		1, 2:
			var side := -1.0 if where[i] == 1 else 1.0
			var k := 0
			for j in i:
				if where[j] == where[i]:
					k += 1
			var pan := _pan(side)
			return pan + Vector2(-33 + k * 22, 0)
	return Vector2(84 + i * 59, SHELF_Y)


func _pan(side: float) -> Vector2:
	var a := tilt * 0.16
	var end := Vector2(320, 92) + Vector2(cos(a), sin(a)) * 150.0 * side
	return end + Vector2(0, 76)


func _jar_at(pos: Vector2) -> int:
	for i in N:
		if Rect2(_jar_pos(i) + Vector2(-10, -30), Vector2(20, 30)).has_point(pos):
			return i
	return -1


func _gui_input(event: InputEvent) -> void:
	if done or opened >= 0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var j := _jar_at(event.position)
		if j < 0:
			return
		if open_mode:
			open_jar(j)
			return
		# Prateleira → prato esquerdo → prato direito → prateleira.
		var nxt := (int(where[j]) + 1) % 3
		var count := 0
		for i in N:
			if where[i] == nxt:
				count += 1
		if nxt != 0 and count >= 4:
			nxt = (nxt + 1) % 3
		where[j] = nxt
		tilt_to = 0.0
		result = ""
		Audio.play("tile", -10.0, 1.3)


func _process(delta: float) -> void:
	super(delta)
	tilt = move_toward(tilt, tilt_to, delta * 1.5)
	opened_t += delta
	weigh_btn.disabled = done or left <= 0 or opened >= 0
	open_btn.disabled = done or opened >= 0


func _draw_jar(c: Vector2, i: int) -> void:
	var glass := Color(0.5, 0.58, 0.46, 0.85)
	draw_rect(Rect2(c + Vector2(-9, -26), Vector2(18, 26)), glass.darkened(0.45))
	draw_rect(Rect2(c + Vector2(-8, -24), Vector2(16, 23)), Color(0.42, 0.36, 0.2, 0.9))
	var beat := 0.0
	if i == heart:
		beat = maxf(0.0, sin(t * 6.0)) ** 6.0 * 2.0
	draw_circle(c + Vector2(0, -11), 5.0 + beat, Color(0.5, 0.08, 0.1))
	draw_circle(c + Vector2(-2, -13), 1.5, Color(0.75, 0.3, 0.3))
	draw_rect(Rect2(c + Vector2(-10, -30), Vector2(20, 5)), Color(0.3, 0.22, 0.14))
	draw_rect(Rect2(c + Vector2(-6, -8), Vector2(12, 6)), Color(0.82, 0.76, 0.6))
	draw_string(get_theme_default_font(), c + Vector2(-6, -3), ROMAN[i], HORIZONTAL_ALIGNMENT_CENTER, 12, 6, Color(0.15, 0.08, 0.05))
	if i == opened and heart < 0:
		# O pote estoura e o que tinha dentro escorre.
		var k := minf(1.0, opened_t * 3.0)
		if State.gore:
			for s in 8:
				var a := TAU * s / 8.0
				draw_rect(Rect2(c + Vector2(cos(a), sin(a) * 0.5) * 18.0 * k + Vector2(0, -10), Vector2(2, 2)), Color(0.55, 0.0, 0.04))
			draw_rect(Rect2(c + Vector2(-14, 0), Vector2(28 * k, 2)), Color(0.45, 0.0, 0.03))
		draw_rect(Rect2(c + Vector2(-9, -26), Vector2(18, 26)), Color(0.9, 0.95, 1.0, 0.4 * (1.0 - k)))


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.025, 0.035))
	var font := get_theme_default_font()
	# Barris ao fundo, em silhueta.
	for k in 6:
		var x := 40.0 + k * 112.0
		draw_circle(Vector2(x, 150), 46, Color(0.07, 0.045, 0.04))
		draw_arc(Vector2(x, 150), 38, 0, TAU, 24, Color(0.04, 0.025, 0.02), 2.0)
	# Prateleira dos potes.
	draw_rect(Rect2(40, SHELF_Y, 560, 6), Color(0.3, 0.18, 0.1))
	draw_rect(Rect2(40, SHELF_Y + 6, 560, 3), Color(0.15, 0.09, 0.05))
	# A balança: coluna, travessão e pratos.
	var brass := Color(0.78, 0.6, 0.3)
	draw_rect(Rect2(314, 92, 12, 168), brass.darkened(0.35))
	draw_rect(Rect2(280, 256, 80, 10), brass.darkened(0.2))
	var a := tilt * 0.16
	var e := Vector2(cos(a), sin(a)) * 150.0
	draw_line(Vector2(320, 92) - e, Vector2(320, 92) + e, brass, 4.0)
	draw_circle(Vector2(320, 92), 6, brass.lightened(0.2))
	# Ponteiro.
	draw_line(Vector2(320, 92), Vector2(320, 92) + Vector2(0, -40).rotated(a), brass.lightened(0.1), 2.0)
	for side in [-1.0, 1.0]:
		var top: Vector2 = Vector2(320, 92) + e * side
		var pan := _pan(side)
		draw_line(top, pan + Vector2(-46, 0), brass.darkened(0.3), 1.0)
		draw_line(top, pan + Vector2(46, 0), brass.darkened(0.3), 1.0)
		draw_rect(Rect2(pan + Vector2(-50, 0), Vector2(100, 5)), brass)
		draw_rect(Rect2(pan + Vector2(-40, 5), Vector2(80, 3)), brass.darkened(0.3))
	for i in N:
		_draw_jar(_jar_pos(i), i)
	# Velas: uma por pesagem que resta.
	for k in weighings:
		var cp := Vector2(560 + k * 18, 52)
		draw_rect(Rect2(cp - Vector2(2, 0), Vector2(4, 16)), Color(0.86, 0.8, 0.66) if k < left else Color(0.3, 0.28, 0.24))
		if k < left:
			var fl := 1.0 + 0.3 * sin(t * 11.0 + k) * sin(t * 4.0)
			draw_colored_polygon(PackedVector2Array([cp + Vector2(0, -8 * fl), cp + Vector2(2, -2), cp + Vector2(0, 0), cp + Vector2(-2, -2)]), Color(1, 0.65, 0.25))
	draw_string(font, Vector2(540, 84), "pesagens", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.55, 0.45))
	draw_string(font, Vector2(274, 20), "A BALANÇA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(130, 36), "Um dos nove potes guarda um coração, mais pesado que os outros.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.68, 0.58))
	if result != "":
		draw_string(font, Vector2(0, 228), result, HORIZONTAL_ALIGNMENT_CENTER, 640, 10, Color(0.95, 0.85, 0.6))
	var tip := "Clique num pote para abri-lo." if open_mode else "Clique num pote para pô-lo num prato. Mesmo número de cada lado."
	draw_string(font, Vector2(0, 326), tip, HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.6, 0.55, 0.48))
