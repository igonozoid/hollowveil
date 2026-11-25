extends "res://scripts/puzzles/puzzle.gd"
## A PARTITURA — Celeste canta uma frase; Dália repete nas teclas desafinadas
## do piano. Quatro rodadas (4, 5, 6 e 7 notas), cada uma acrescenta uma nota
## ao fim da anterior. As teclas acendem quando ela canta, então dá para
## jogar sem som. As vozes são sintetizadas na hora (synth.gd).

const Synth := preload("res://scripts/audio/synth.gd")
const Blood := preload("res://scripts/gfx/blood.gd")
const KEYS := 8
const KEY_W := 40.0
const KEYS_POS := Vector2(160, 196)
const ROUNDS := [4, 5, 6, 7]

var melody: Array = []
var round_i := 0
var phase := "wait"     # wait | sing | play | wrong
var phase_t := 0.0
var sing_i := 0
var input_i := 0
var key_glow: Array = []
var key_blood: Array = []
var voice: Array = []    # AudioStreamWAV por tecla (Celeste)
var piano: Array = []    # AudioStreamWAV por tecla (piano)
var players: Array = []
var blood := Blood.new()
var mouth := 0.0


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("partitura")
	var last := -1
	for i in ROUNDS[-1]:
		var k := rng.randi_range(0, KEYS - 1)
		while k == last:
			k = rng.randi_range(0, KEYS - 1)
		melody.append(k)
		last = k
	var spec := {"root": 57, "scale": Synth.HARM}
	for i in KEYS:
		key_glow.append(0.0)
		key_blood.append(false)
		var midi := Synth.degree(spec, i)
		# Desafinadas: cada tecla erra um pouco, sempre do mesmo jeito.
		var detune := rng.randf_range(-0.35, 0.35)
		voice.append(_note(Synth.hz(midi + 12), "choir", 0.55, 0.16))
		piano.append(_note(Synth.hz(midi + detune), "harpsi", 0.7, 0.2))
	for i in 4:
		var pl := AudioStreamPlayer.new()
		pl.bus = "Sfx"
		add_child(pl)
		players.append(pl)
	round_i = int(State.drafts.get("partitura", 0))
	add_child(blood)
	blood.floor_y = 330.0
	_start_round(1.2)


func _note(f: float, kind: String, dur: float, amp: float) -> AudioStreamWAV:
	var buf := PackedFloat32Array()
	buf.resize(int((dur + 0.32) * Synth.RATE))
	Synth._tone(buf, 0.0, dur, f, amp, kind)
	return Synth.to_wav(buf)


func _play(stream: AudioStreamWAV, vol: float = 0.0) -> void:
	for pl: AudioStreamPlayer in players:
		if not pl.playing:
			pl.stream = stream
			pl.volume_db = vol
			pl.play()
			return


func _start_round(delay: float) -> void:
	phase = "wait"
	phase_t = -delay
	sing_i = 0
	input_i = 0


static func hint(level: int) -> String:
	if level == 1:
		return "Cada rodada repete a anterior e acrescenta uma nota no fim. Ela nunca canta a mesma nota duas vezes seguidas."
	return "Agora a tecla certa brilha em azul, bem fraquinho, quando é a sua vez."


func _process(delta: float) -> void:
	super(delta)
	phase_t += delta
	mouth = maxf(0.0, mouth - delta * 2.5)
	for i in KEYS:
		key_glow[i] = maxf(0.0, key_glow[i] - delta * 2.2)
	var length: int = ROUNDS[mini(round_i, ROUNDS.size() - 1)]
	match phase:
		"wait":
			if phase_t >= 0.0:
				phase = "sing"
				phase_t = 0.0
		"sing":
			if sing_i < length and phase_t >= sing_i * 0.62:
				var k: int = melody[sing_i]
				_play(voice[k], -2.0)
				key_glow[k] = 1.0
				mouth = 1.0
				sing_i += 1
			elif sing_i >= length and phase_t >= length * 0.62 + 0.4:
				phase = "play"
		"wrong":
			if phase_t > 1.4:
				_start_round(0.4)


func _key_at(p: Vector2) -> int:
	if p.y < KEYS_POS.y or p.y > KEYS_POS.y + 120 or p.x < KEYS_POS.x:
		return -1
	var k := int((p.x - KEYS_POS.x) / KEY_W)
	return k if k < KEYS else -1


func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseMotion:
		set_cursor("hand" if _key_at(event.position) >= 0 and phase == "play" else "flame")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and phase == "play":
		var k := _key_at(event.position)
		if k < 0:
			return
		key_glow[k] = 0.8
		_play(piano[k])
		if k == melody[input_i]:
			input_i += 1
			var length: int = ROUNDS[round_i]
			if input_i >= length:
				round_i += 1
				State.drafts["partitura"] = round_i
				if round_i >= ROUNDS.size():
					State.drafts.erase("partitura")
					Audio.play("solved", -8.0, 0.8)
					say("DÁLIA", "Ela parou de cantar. Agora só respira, perto do meu ouvido.")
					finish()
				else:
					Audio.play("candle", -8.0)
					_start_round(1.2)
		else:
			phase = "wrong"
			phase_t = 0.0
			key_blood[k] = true
			Audio.play("wrong", -4.0)
			Audio.play("scream", -14.0, 1.6)
			shake(0.5)
			State.change_sanity(-3.0)
			var kc := KEYS_POS + Vector2(k * KEY_W + KEY_W * 0.5, 90)
			blood.spray(kc, Vector2(0, -1), 18, 90.0, 0.9)
			say("MORVANT", ["Desafinou. Ela odiava quando eu desafinava.", "De novo. Do começo. Como nos ensaios.", "Você está machucando os ouvidos dela."][randi() % 3])


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.02, 0.03))
	var font := get_theme_default_font()
	# Tampa do piano, polida: o reflexo de Celeste aparece nela.
	draw_rect(Rect2(140, 20, 360, 160), Color(0.03, 0.025, 0.03))
	draw_rect(Rect2(140, 20, 360, 160), Color(0.2, 0.16, 0.18), false, 1.0)
	for i in 6:
		draw_line(Vector2(150 + i * 60, 24), Vector2(190 + i * 60, 176), Color(1, 1, 1, 0.025), 6.0)
	# Partitura na estante, que se enche de notas a cada rodada.
	var sheet := Rect2(196, 34, 248, 112)
	draw_rect(sheet, Color(0.82, 0.78, 0.66))
	for l in 5:
		draw_line(Vector2(sheet.position.x + 8, 60 + l * 8), Vector2(sheet.end.x - 8, 60 + l * 8), Color(0.3, 0.25, 0.2), 1.0)
		draw_line(Vector2(sheet.position.x + 8, 104 + l * 8), Vector2(sheet.end.x - 8, 104 + l * 8), Color(0.3, 0.25, 0.2), 1.0)
	var written: int = ROUNDS[mini(round_i, ROUNDS.size() - 1)] if round_i > 0 else 0
	if round_i >= ROUNDS.size():
		written = ROUNDS[-1]
	for i in written:
		var nx := sheet.position.x + 20 + i * 30
		var ny: float = 92.0 - float(melody[i]) * 4.0
		draw_circle(Vector2(nx, ny), 3.0, Color(0.45, 0.02, 0.04))
		draw_line(Vector2(nx + 3, ny), Vector2(nx + 3, ny - 16), Color(0.45, 0.02, 0.04), 1.0)
	draw_string(font, sheet.position + Vector2(8, 16), "Ária para o Véu — C. M.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.3, 0.2, 0.15))
	# O rosto de Celeste no reflexo, ao lado da partitura.
	var face := Vector2(470, 90)
	var a := 0.25 + 0.5 * (1.0 if phase == "sing" else 0.0) + 0.2 * sin(t * 1.3)
	draw_circle(face, 16, Color(0.6, 0.95, 0.9, a * 0.35))
	draw_circle(face, 11, Color(0.6, 0.95, 0.9, a * 0.6))
	draw_rect(Rect2(face + Vector2(-5, -4), Vector2(3, 2)), Color(0.02, 0.05, 0.05, a))
	draw_rect(Rect2(face + Vector2(2, -4), Vector2(3, 2)), Color(0.02, 0.05, 0.05, a))
	draw_rect(Rect2(face + Vector2(-2, 3), Vector2(4, 1 + mouth * 5)), Color(0.02, 0.05, 0.05, a))
	draw_line(face + Vector2(-11, -2), face + Vector2(-13, 26), Color(0.6, 0.95, 0.9, a * 0.4), 3.0)
	# Teclado
	draw_rect(Rect2(KEYS_POS - Vector2(10, 14), Vector2(KEYS * KEY_W + 20, 148)), Color(0.05, 0.035, 0.035))
	draw_rect(Rect2(KEYS_POS - Vector2(10, 14), Vector2(KEYS * KEY_W + 20, 10)), Color(0.45, 0.05, 0.08))
	var next := -1
	if phase == "play" and State.flag("hint2_partitura") and input_i < melody.size():
		next = melody[input_i]
	for i in KEYS:
		var r := Rect2(KEYS_POS + Vector2(i * KEY_W, 0), Vector2(KEY_W - 2, 120))
		var g: float = key_glow[i]
		var col := Color(0.66, 0.61, 0.5).lerp(Color(0.6, 0.95, 0.9), g)
		draw_rect(r, col)
		draw_rect(Rect2(r.position + Vector2(0, 112), Vector2(r.size.x, 8)), col.darkened(0.25))
		if i == next:
			draw_rect(r.grow(-3), Color(0.4, 0.8, 1.0, 0.18 + 0.1 * sin(t * 5.0)))
		if key_blood[i] and State.gore:
			draw_rect(Rect2(r.position + Vector2(r.size.x * 0.4, 0), Vector2(3, 50 + i * 7)), Color(0.5, 0.0, 0.03))
			draw_rect(Rect2(r.position + Vector2(r.size.x * 0.4 - 1, 46 + i * 7), Vector2(5, 5)), Color(0.5, 0.0, 0.03))
	for i in KEYS - 1:
		if i % 7 == 2 or i % 7 == 6:
			continue
		draw_rect(Rect2(KEYS_POS + Vector2((i + 1) * KEY_W - 10, 0), Vector2(18, 72)), Color(0.05, 0.04, 0.04))
	draw_string(font, Vector2(262, 14), "A PARTITURA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	var status := "escute..." if phase in ["wait", "sing"] else ("sua vez" if phase == "play" else "de novo")
	draw_string(font, Vector2(520, 220), "rodada %d de %d" % [mini(round_i + 1, ROUNDS.size()), ROUNDS.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.65, 0.5))
	draw_string(font, Vector2(520, 236), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.95, 0.9) if phase != "wrong" else Color(0.9, 0.2, 0.2))
	if phase == "play":
		for i in input_i:
			draw_rect(Rect2(520 + i * 8, 246, 6, 6), Color(0.85, 0.66, 0.36))
