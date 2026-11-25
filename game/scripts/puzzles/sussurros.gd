extends "res://scripts/puzzles/puzzle.gd"
## OS SUSSURROS — quatro mortos dizem onde Morvant escondeu o diário de
## Ofélia. Exatamente um mente. Só um esconderijo deixa uma única frase
## falsa. A semente gera falas e mentiroso, e o gerador só aceita conjuntos
## com resposta única.

const SPOTS := ["debaixo da cama", "no armário", "dentro da boneca", "atrás do espelho"]
const GHOSTS := ["Leocádia", "Tobias", "Benedita", "Hélio"]
const FACES := [Vector2(128, 96), Vector2(256, 96), Vector2(384, 96), Vector2(512, 96)]

var answer := 0
var liar := 0
var claims: Array = []      # [tipo, a, b]
var buttons: Array = []
var truthful_hint := -1
var wrong_t := 0.0
var cracked := -1


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("sussurros")
	for attempt in 500:
		answer = rng.randi() % 4
		liar = rng.randi() % 4
		claims = []
		for i in 4:
			var want := i != liar
			var c: Array = []
			for tries in 50:
				c = _random_claim(rng)
				if _true(c, answer) == want:
					break
			claims.append(c)
		var ok := true
		for i in 4:
			if _true(claims[i], answer) != (i != liar):
				ok = false
		if ok and consistent_spots().size() == 1:
			break
	if State.flag("hint2_sussurros"):
		for i in 4:
			if i != liar:
				truthful_hint = i
				break
	# As falas: rótulos com quebra de linha, um sob cada rosto.
	for i in 4:
		var l := Label.new()
		l.text = _text(claims[i])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 9)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.custom_minimum_size = Vector2(116, 0)
		add_child(l)
		l.position = FACES[i] + Vector2(-58, 26)
		l.size = Vector2(116, 50)
	for k in 4:
		var b := Button.new()
		b.text = SPOTS[k].substr(0, 1).to_upper() + SPOTS[k].substr(1)
		b.add_theme_font_size_override("font_size", 10)
		b.clip_text = true
		b.custom_minimum_size = Vector2(112, 22)
		b.position = Vector2(80 + k * 122, 296)
		b.size = Vector2(112, 22)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_choose.bind(k))
		add_child(b)
		buttons.append(b)


func _random_claim(rng: RandomNumberGenerator) -> Array:
	var a := rng.randi() % 4
	var b := (a + 1 + rng.randi() % 3) % 4
	return [["em", "nao", "ou", "nem"][rng.randi() % 4], a, b]


func _true(c: Array, spot: int) -> bool:
	match c[0]:
		"em":
			return spot == c[1]
		"nao":
			return spot != c[1]
		"ou":
			return spot == c[1] or spot == c[2]
		"nem":
			return spot != c[1] and spot != c[2]
	return false


## Esconderijos em que exatamente uma frase sai falsa.
func consistent_spots() -> Array:
	var out: Array = []
	for s in 4:
		var false_count := 0
		for c in claims:
			if not _true(c, s):
				false_count += 1
		if false_count == 1:
			out.append(s)
	return out


func _text(c: Array) -> String:
	match c[0]:
		"em":
			return "Está %s." % SPOTS[c[1]]
		"nao":
			return "Não está %s." % SPOTS[c[1]]
		"ou":
			return "Está %s ou %s." % [SPOTS[c[1]], SPOTS[c[2]]]
		"nem":
			return "Não está %s, nem %s." % [SPOTS[c[1]], SPOTS[c[2]]]
	return ""


static func hint(level: int) -> String:
	if level == 1:
		return "Teste um esconderijo de cada vez. No certo, exatamente uma das quatro frases fica falsa."
	return "A prancheta marcou, em azul, um morto que fala a verdade."


func _choose(k: int) -> void:
	if done:
		return
	if k == answer:
		cracked = liar
		Audio.play("scream", -8.0, 1.3)
		Audio.play("sting", -8.0, 1.1)
		shake(0.6)
		say("OFÉLIA", "%s mentiu. O diário estava %s. Obrigada, Dália. Agora deixe ele vir." % [GHOSTS[liar], SPOTS[answer]])
		for b in buttons:
			b.disabled = true
		finish()
	else:
		wrong_t = 1.0
		Audio.play("wrong", -4.0)
		Audio.play("scream", -14.0, 1.9)
		shake(0.5)
		State.change_sanity(-5.0)
		say("MORVANT", ["Errado. As bonecas estão rindo de você.", "Ofélia também errava. Eu a corrigia com carinho.", "Tente de novo. O diário não vai a lugar nenhum. Você também não."][randi() % 3])


func _process(delta: float) -> void:
	super(delta)
	wrong_t = maxf(0.0, wrong_t - delta)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.025, 0.04))
	var font := get_theme_default_font()
	# Círculo de giz e velas, ao fundo, no assoalho
	var c := Vector2(320, 214)
	draw_set_transform(c, 0, Vector2(1, 0.35))
	draw_arc(Vector2.ZERO, 170, 0, TAU, 64, Color(0.75, 0.74, 0.7, 0.5), 1.0)
	draw_set_transform(Vector2.ZERO)
	for k in 5:
		var a := TAU * k / 5.0 - PI * 0.5
		var cp := c + Vector2(cos(a) * 170, sin(a) * 60)
		draw_rect(Rect2(cp - Vector2(1, 8), Vector2(3, 8)), Color(0.86, 0.8, 0.66))
		var fl := 1.0 + 0.3 * sin(t * 11.0 + k) * sin(t * 4.0)
		draw_colored_polygon(PackedVector2Array([cp + Vector2(0, -8 - 6 * fl), cp + Vector2(2, -9), cp + Vector2(0, -7), cp + Vector2(-2, -9)]), Color(1, 0.65, 0.25))
	# Os quatro mortos
	for i in 4:
		var f: Vector2 = FACES[i]
		var shake_x := sin(t * 40.0) * 2.0 * wrong_t
		var alpha := 0.55 + 0.15 * sin(t * 2.0 + i)
		draw_rect(Rect2(f + Vector2(-62, 22), Vector2(124, 56)), Color(0.07, 0.06, 0.09, 0.9))
		draw_rect(Rect2(f + Vector2(-62, 22), Vector2(124, 56)), Color(0.45, 0.6, 0.6, 0.5), false, 1.0)
		draw_circle(f + Vector2(shake_x, 0), 16, Color(0.6, 0.95, 0.9, alpha * 0.25))
		draw_circle(f + Vector2(shake_x, 0), 11, Color(0.6, 0.95, 0.9, alpha))
		draw_rect(Rect2(f + Vector2(-5 + shake_x, -3), Vector2(3, 2)), Color(0.02, 0.05, 0.05))
		draw_rect(Rect2(f + Vector2(2 + shake_x, -3), Vector2(3, 2)), Color(0.02, 0.05, 0.05))
		draw_rect(Rect2(f + Vector2(-2 + shake_x, 3), Vector2(4, 2 + absf(sin(t * 5.0 + i)) * 2)), Color(0.02, 0.05, 0.05))
		draw_string(font, f + Vector2(-60, -22), GHOSTS[i].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color(0.55, 0.95, 0.88))
		if cracked == i and State.gore:
			draw_line(f + Vector2(-6, -10), f + Vector2(4, 10), Color(0.5, 0.0, 0.03), 2.0)
			draw_rect(Rect2(f + Vector2(-1, 6), Vector2(2, 14)), Color(0.5, 0.0, 0.03))
		if truthful_hint == i:
			draw_arc(f, 20, 0, TAU, 20, Color(0.4, 0.9, 1.0, 0.6), 1.0)
	draw_string(font, Vector2(264, 20), "OS SUSSURROS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(166, 286), "Onde está o diário de Ofélia? Um dos quatro mente.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.68, 0.58))
