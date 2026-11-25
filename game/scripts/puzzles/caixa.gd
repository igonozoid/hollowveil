extends "res://scripts/puzzles/puzzle.gd"
## A CAIXA DE MÚSICA — cinco engrenagens em corrente, seis posições cada.
## Girar uma engrenagem (clique esquerdo: horário; direito: anti-horário)
## gira as vizinhas um passo no sentido contrário. Alinhe todas as marcas
## no topo e a caixa toca. A semente embaralha a partir do alinhado; uma
## busca em largura dá as pistas.

const Synth := preload("res://scripts/audio/synth.gd")
const G := 5
const STEPS := 6
const CENTERS := [Vector2(176, 210), Vector2(248, 186), Vector2(320, 214), Vector2(392, 186), Vector2(464, 210)]
const RADII := [34.0, 30.0, 36.0, 30.0, 34.0]
const LULLABY := [7, 9, 7, 4, 7, 9, 7, 4, 11, 11, 9, 7, 8, 8, 7]

var pos: Array = []
var shown: Array = []
var moves := 0
var hint_move: Array = []
var notes: Array = []
var player := AudioStreamPlayer.new()
var song_i := -1
var song_t := 0.0


func build() -> void:
	for i in G:
		pos.append(0)
		shown.append(0.0)
	if State.drafts.has("caixa") and (State.drafts["caixa"] as Array).size() == G:
		for i in G:
			pos[i] = int(State.drafts["caixa"][i])
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = State.puzzle_seed("caixa")
		while _aligned():
			for k in 9:
				_turn(rng.randi() % G, 1 if rng.randf() < 0.5 else -1, false)
	for i in G:
		shown[i] = float(pos[i])
	player.bus = "Sfx"
	add_child(player)
	var spec := {"root": 69, "scale": Synth.HARM}
	for d in 12:
		var buf := PackedFloat32Array()
		buf.resize(int(0.9 * Synth.RATE))
		Synth._tone(buf, 0.0, 0.8, Synth.hz(Synth.degree(spec, d) + randf_range(-0.2, 0.2)), 0.25, "bell")
		notes.append(Synth.to_wav(buf))
	_update_hint()


func _aligned() -> bool:
	for v in pos:
		if v != 0:
			return false
	return true


func _turn(i: int, d: int, fx: bool) -> void:
	pos[i] = posmod(pos[i] + d, STEPS)
	for j in [i - 1, i + 1]:
		if j >= 0 and j < G:
			pos[j] = posmod(pos[j] - d, STEPS)
	if fx:
		moves += 1
		Audio.play("tile", -8.0, 0.6 + i * 0.12)
		State.drafts["caixa"] = pos.duplicate()


## Busca em largura do estado atual até o alinhado. Devolve [engrenagem, sentido].
func next_move() -> Array:
	var start := _key(pos)
	if start == 0:
		return []
	var prev := {start: null}
	var queue := [pos.duplicate()]
	while not queue.is_empty():
		var s: Array = queue.pop_front()
		for i in G:
			for d in [1, -1]:
				var n := s.duplicate()
				n[i] = posmod(n[i] + d, STEPS)
				for j in [i - 1, i + 1]:
					if j >= 0 and j < G:
						n[j] = posmod(n[j] - d, STEPS)
				var k := _key(n)
				if prev.has(k):
					continue
				prev[k] = [_key(s), i, d]
				if k == 0:
					# Volta pelo caminho até o primeiro passo.
					var cur := k
					var step: Array = prev[cur]
					while step[0] != start:
						cur = step[0]
						step = prev[cur]
					return [step[1], step[2]]
				queue.append(n)
	return []


func _key(s: Array) -> int:
	var k := 0
	for v in s:
		k = k * STEPS + int(v)
	return k


func _update_hint() -> void:
	hint_move = next_move() if State.flag("hint2_caixa") else []


static func hint(level: int) -> String:
	if level == 1:
		return "Comece pelas pontas: a primeira e a última engrenagem só mexem numa vizinha cada. Acerte as pontas e vá para o meio."
	return "A prancheta agora mostra qual engrenagem girar, e para que lado."


func _gear_at(p: Vector2) -> int:
	for i in G:
		if (CENTERS[i] as Vector2).distance_to(p) <= RADII[i] + 4.0:
			return i
	return -1


func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseMotion:
		set_cursor("hand" if _gear_at(event.position) >= 0 else "flame")
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var g := _gear_at(event.position)
		if g < 0:
			return
		_turn(g, 1 if event.button_index == MOUSE_BUTTON_LEFT else -1, true)
		_update_hint()
		if _aligned():
			State.drafts.erase("caixa")
			song_i = 0
			song_t = 0.0
			say("DÁLIA", "Uma canção de ninar. Do outro lado do corredor, uma fechadura estala.")
			finish()


func _process(delta: float) -> void:
	super(delta)
	for i in G:
		# Anima o caminho mais curto até a posição nova.
		var target := float(pos[i])
		var diff := fposmod(target - shown[i] + STEPS * 0.5, STEPS) - STEPS * 0.5
		shown[i] = shown[i] + diff * minf(1.0, delta * 12.0)
	if song_i >= 0 and song_i < LULLABY.size():
		song_t -= delta
		if song_t <= 0.0:
			player.stream = notes[LULLABY[song_i]]
			player.play()
			song_i += 1
			song_t = 0.28 if song_i % 4 != 0 else 0.5


func _gear(i: int) -> void:
	var c: Vector2 = CENTERS[i]
	var r: float = RADII[i]
	var ang: float = shown[i] / STEPS * TAU
	var brass := Color(0.72, 0.52, 0.24) if i % 2 == 0 else Color(0.62, 0.46, 0.22)
	var teeth := int(r / 3.0)
	var pts := PackedVector2Array()
	for k in teeth * 2:
		var a: float = ang + TAU * k / (teeth * 2)
		var rr := r if k % 2 == 0 else r - 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, brass)
	draw_circle(c, r - 9.0, brass.darkened(0.25))
	for s in 4:
		var a2: float = ang + TAU * s / 4.0 + PI / 4.0
		draw_line(c, c + Vector2(cos(a2), sin(a2)) * (r - 9.0), brass, 4.0)
	draw_circle(c, 5, brass.lightened(0.2))
	# A marca (um ponto vermelho) e o ponteiro fixo no topo.
	var mark := c + Vector2(cos(ang - PI * 0.5), sin(ang - PI * 0.5)) * (r - 13.0)
	draw_circle(mark, 4, Color(0.75, 0.05, 0.06))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -r - 10), c + Vector2(4, -r - 10), c + Vector2(0, -r - 3)]), Color(0.9, 0.85, 0.7) if pos[i] != 0 else Color(0.4, 0.9, 0.5))
	if hint_move.size() == 2 and hint_move[0] == i:
		draw_arc(c, r + 6, 0, TAU, 24, Color(0.4, 0.9, 1.0, 0.4 + 0.3 * sin(t * 5.0)), 1.0)
		draw_string(get_theme_default_font(), c + Vector2(-8, r + 20), "↻" if hint_move[1] == 1 else "↺", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.9, 1.0))


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.04, 0.025, 0.04))
	# Caixa de madeira aberta, forrada de veludo roxo
	draw_rect(Rect2(120, 120, 400, 170), Color(0.32, 0.16, 0.08))
	draw_rect(Rect2(130, 130, 380, 150), Color(0.25, 0.08, 0.2))
	draw_rect(Rect2(120, 40, 400, 80), Color(0.36, 0.19, 0.1))
	draw_rect(Rect2(130, 48, 380, 64), Color(0.25, 0.08, 0.2))
	# Espelho na tampa, com a bailarina refletida
	draw_rect(Rect2(270, 54, 100, 52), Color(0.2, 0.24, 0.3))
	# Cilindro com pinos e pente
	draw_rect(Rect2(170, 136, 300, 18), Color(0.7, 0.66, 0.56))
	for k in 30:
		var px := 172.0 + fmod(k * 37.0 + shown[2] * 8.0, 296.0)
		draw_rect(Rect2(px, 138 + (k % 4) * 4, 2, 2), Color(0.3, 0.28, 0.24))
	for k in 18:
		draw_rect(Rect2(176 + k * 16, 156, 10, 3), Color(0.8, 0.78, 0.72))
	for i in G:
		_gear(i)
	# A bailarina: gira quando a caixa toca. Não tem cabeça.
	var bx := 320.0
	var by := 104.0
	var spin := t * 4.0 if song_i >= 0 else 0.0
	var w := cos(spin) * 6.0
	draw_line(Vector2(bx, by), Vector2(bx, by - 22), Color(0.9, 0.86, 0.84), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(bx - absf(w) - 3, by - 10), Vector2(bx + absf(w) + 3, by - 10), Vector2(bx, by - 16)]), Color(0.9, 0.7, 0.8))
	draw_line(Vector2(bx, by - 20), Vector2(bx + w, by - 28), Color(0.9, 0.86, 0.84), 1.0)
	draw_line(Vector2(bx, by - 20), Vector2(bx - w, by - 28), Color(0.9, 0.86, 0.84), 1.0)
	if State.gore:
		draw_rect(Rect2(bx - 1, by - 24, 2, 2), Color(0.6, 0.0, 0.03))
	draw_string(get_theme_default_font(), Vector2(232, 24), "A CAIXA DE MÚSICA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(get_theme_default_font(), Vector2(150, 316), "clique: gira no horário · botão direito: anti-horário · as vizinhas giram ao contrário", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.5, 0.4))
	draw_string(get_theme_default_font(), Vector2(540, 200), "giros: %d" % moves, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.5, 0.4))
