extends "res://scripts/puzzles/puzzle.gd"
## O ATLAS — quebra-cabeça deslizante 4×4. A prancha XIII do atlas anatômico
## de Morvant: o próprio rosto, meio pele, meio músculo. Embaralhado a partir
## da solução com a semente da volta (sempre solucionável).

const Blood := preload("res://scripts/gfx/blood.gd")
const N := 4
const TILE := 48
const ORIGIN := Vector2(224, 64)

var tiles: Array = []      # tiles[posição] = peça (N*N-1 = vazio)
var sub := SubViewport.new()
var art := Node2D.new()
var tex: Texture2D
var moves := 0
var anim: Dictionary = {}  # peça -> [de, t]
var blood := Blood.new()
var win_t := -1.0
var eyes_open := 0.0


func build() -> void:
	sub.size = Vector2i(N * TILE, N * TILE)
	sub.transparent_bg = false
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub.disable_3d = true
	add_child(sub)
	sub.add_child(art)
	art.draw.connect(_paint_art)
	tex = sub.get_texture()
	if State.drafts.has("atlas") and (State.drafts["atlas"] as Array).size() == N * N:
		tiles = []
		for v in State.drafts["atlas"]:
			tiles.append(int(v))
		moves = int(State.drafts.get("atlas_moves", 0))
	else:
		_shuffle()
	add_child(blood)
	blood.floor_y = INF


func _shuffle() -> void:
	tiles = []
	for i in N * N:
		tiles.append(i)
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("atlas")
	var blank := N * N - 1
	var last := -1
	var count := 0
	while count < 220:
		var opts := _neighbors(blank)
		opts.erase(last)
		var pick: int = opts[rng.randi() % opts.size()]
		tiles[blank] = tiles[pick]
		tiles[pick] = N * N - 1
		last = blank
		blank = pick
		count += 1
	if _is_solved():
		_shuffle()


func _neighbors(i: int) -> Array:
	var out: Array = []
	var r := i / N
	var c := i % N
	if r > 0:
		out.append(i - N)
	if r < N - 1:
		out.append(i + N)
	if c > 0:
		out.append(i - 1)
	if c < N - 1:
		out.append(i + 1)
	return out


func _is_solved() -> bool:
	for i in N * N:
		if tiles[i] != i:
			return false
	return true


static func hint(level: int) -> String:
	if level == 1:
		return "Monte primeiro a fileira de cima, depois a coluna da esquerda. O que sobra é um quebra-cabeça menor."
	return "Agora a prancha mostra o número de cada peça e, por baixo, o desenho completo."


# ---------------------------------------------------------------- entrada

func _cell_at(p: Vector2) -> int:
	var local := p - ORIGIN
	if local.x < 0 or local.y < 0 or local.x >= N * TILE or local.y >= N * TILE:
		return -1
	return int(local.y / TILE) * N + int(local.x / TILE)


func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseMotion:
		var c := _cell_at(event.position)
		set_cursor("hand" if c >= 0 and tiles.find(N * N - 1) in _neighbors(c) else "flame")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c2 := _cell_at(event.position)
		if c2 >= 0:
			_slide(c2)


func _unhandled_key_input(event: InputEvent) -> void:
	if done or not event.is_pressed():
		return
	var blank := tiles.find(N * N - 1)
	var r := blank / N
	var c := blank % N
	# A seta move a peça que está do lado oposto para dentro do vazio.
	if event.is_action_pressed("ui_left") and c < N - 1:
		_slide(blank + 1)
	elif event.is_action_pressed("ui_right") and c > 0:
		_slide(blank - 1)
	elif event.is_action_pressed("ui_up") and r < N - 1:
		_slide(blank + N)
	elif event.is_action_pressed("ui_down") and r > 0:
		_slide(blank - N)


func _slide(cell: int) -> void:
	var blank := tiles.find(N * N - 1)
	if not blank in _neighbors(cell):
		Audio.play("tile", -14.0, 0.6)
		return
	anim[tiles[cell]] = [_cell_pos(cell), 0.0]
	tiles[blank] = tiles[cell]
	tiles[cell] = N * N - 1
	moves += 1
	Audio.play("tile", -6.0, randf_range(0.85, 1.15))
	State.drafts["atlas"] = tiles.duplicate()
	State.drafts["atlas_moves"] = moves
	if moves == 120:
		say("MORVANT", "Cirurgia lenta mata o paciente. Felizmente, eu já estou morto.")
	if _is_solved():
		win_t = 0.0
		State.drafts.erase("atlas")
		Audio.play("sting", -8.0, 0.9)
		finish()


func _cell_pos(cell: int) -> Vector2:
	return ORIGIN + Vector2(cell % N, cell / N) * TILE


# ---------------------------------------------------------------- desenho

func _process(delta: float) -> void:
	super(delta)
	for k in anim.keys():
		anim[k][1] += delta / 0.09
		if anim[k][1] >= 1.0:
			anim.erase(k)
	if win_t >= 0.0:
		win_t += delta
		eyes_open = minf(1.0, win_t / 0.8)
		if win_t > 0.9 and win_t < 2.0 and randf() < 0.3:
			for e in [Vector2(54, 87), Vector2(117, 87)]:
				blood.drip(ORIGIN + e + Vector2(randf_range(-2, 2), 4), 70.0)
		if win_t > 0.9 and win_t - delta <= 0.9:
			Audio.play("squelch", -4.0, 0.8)
			blood.spray(ORIGIN + Vector2(117, 87), Vector2(1, -0.4), 30, 120.0, 0.5)
	art.queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.05, 0.04, 0.035))
	# Couro e capa do atlas aberto
	draw_rect(Rect2(150, 30, 340, 270), Color(0.22, 0.09, 0.06))
	draw_rect(Rect2(158, 38, 324, 254), Color(0.7, 0.62, 0.46))
	draw_line(Vector2(320, 38), Vector2(320, 292), Color(0.5, 0.42, 0.3), 1.0)
	brass_frame(Rect2(ORIGIN - Vector2(6, 6), Vector2(N * TILE + 12, N * TILE + 12)), 2.0)
	var hint2 := State.flag("hint2_atlas")
	if hint2 and win_t < 0.0:
		draw_texture_rect(tex, Rect2(ORIGIN, Vector2(N * TILE, N * TILE)), false, Color(1, 1, 1, 0.18))
	for cell in N * N:
		var piece: int = tiles[cell]
		if piece == N * N - 1 and win_t < 0.0:
			draw_rect(Rect2(_cell_pos(cell), Vector2(TILE, TILE)), Color(0.04, 0.02, 0.02, 0.85 if not hint2 else 0.3))
			continue
		var dst := _cell_pos(cell)
		if anim.has(piece):
			dst = (anim[piece][0] as Vector2).lerp(dst, ease(anim[piece][1], 0.4))
		var src := Rect2(Vector2(piece % N, piece / N) * TILE, Vector2(TILE, TILE))
		draw_texture_rect_region(tex, Rect2(dst, Vector2(TILE, TILE)), src)
		if win_t < 0.0:
			draw_rect(Rect2(dst, Vector2(TILE, TILE)), Color(0.2, 0.12, 0.08), false, 1.0)
			var num_col := Color(0.25, 0.12, 0.08, 0.85) if hint2 else Color(0.3, 0.2, 0.15, 0.35)
			draw_string(get_theme_default_font(), dst + Vector2(3, 10), str(piece + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9 if hint2 else 7, num_col)
	draw_string(get_theme_default_font(), Vector2(166, 54), "TAB. XIII", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.35, 0.2, 0.12))
	draw_string(get_theme_default_font(), Vector2(424, 54), "CAPVT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.35, 0.2, 0.12))
	draw_string(get_theme_default_font(), Vector2(166, 286), "movimentos: %d" % moves, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.35, 0.2, 0.12))
	draw_string(get_theme_default_font(), Vector2(250, 22), "O ATLAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.66, 0.36))
	draw_string(get_theme_default_font(), Vector2(196, 322), "clique numa peça ao lado do vazio · setas também deslizam", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.5, 0.4))


## A prancha: o rosto de Morvant, metade pele, metade dissecado.
func _paint_art() -> void:
	var a := art
	var paper := Color(0.78, 0.7, 0.54)
	a.draw_rect(Rect2(0, 0, 192, 192), paper)
	# Hachura de gravura e manchas de umidade: nenhuma peça fica lisa.
	for i in range(-192, 192, 5):
		a.draw_line(Vector2(i, 0), Vector2(i + 192, 192), Color(0.64, 0.55, 0.38, 0.22), 1.0)
	for i in 30:
		var p := Vector2(fmod(i * 61.7, 192.0), fmod(i * 37.3, 192.0))
		a.draw_circle(p, 2 + i % 4, Color(0.62, 0.5, 0.32, 0.35))
	for i in 3:
		a.draw_circle(Vector2(30 + i * 70, 170 - i * 60), 14 + i * 4, Color(0.55, 0.42, 0.25, 0.12))
	# Moldura gravada, régua na margem e numeração.
	a.draw_rect(Rect2(3, 3, 186, 186), Color(0.3, 0.18, 0.1), false, 1.0)
	a.draw_rect(Rect2(6, 6, 180, 180), Color(0.3, 0.18, 0.1, 0.5), false, 1.0)
	for i in 36:
		a.draw_line(Vector2(6, 8 + i * 5), Vector2(9 if i % 5 else 12, 8 + i * 5), Color(0.3, 0.18, 0.1), 1.0)
	_label(a, Vector2(150, 16), "XIII")
	_legend(a)
	# O rosto ocupa a prancha toda (escala em volta do centro).
	var zoom := 1.48
	var c0 := Vector2(84, 108)
	a.draw_set_transform(c0 - Vector2(96, 100) * zoom, 0.0, Vector2(zoom, zoom))
	var c := Vector2(96, 100)
	var skin := Color(0.86, 0.72, 0.6)
	var skin_d := Color(0.68, 0.52, 0.42)
	var muscle := Color(0.62, 0.12, 0.1)
	var muscle_l := Color(0.8, 0.3, 0.24)
	var bone := Color(0.9, 0.86, 0.74)
	var ink := Color(0.2, 0.12, 0.08)
	# Pescoço
	a.draw_rect(Rect2(78, 140, 18, 52), skin_d)
	a.draw_rect(Rect2(96, 140, 18, 52), muscle)
	for i in 5:
		a.draw_line(Vector2(98 + i * 3, 142), Vector2(100 + i * 3, 190), muscle_l, 1.0)
	a.draw_line(Vector2(104, 150), Vector2(110, 188), bone, 2.0)
	# Cabeça: metade esquerda pele, metade direita músculo.
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	left.append(Vector2(96, 44))
	right.append(Vector2(96, 44))
	for i in 17:
		var ang := PI * 0.5 + PI * i / 16.0
		left.append(c + Vector2(cos(ang) * 42, -sin(ang) * 56 - 4) * Vector2(1, -1) * Vector2(1, -1))
	for i in 17:
		var ang2 := PI * 0.5 - PI * i / 16.0
		right.append(c + Vector2(cos(ang2) * 42, -sin(ang2) * 56 - 4))
	a.draw_colored_polygon(left, skin)
	a.draw_colored_polygon(right, muscle)
	# Fibras do lado dissecado
	for i in 14:
		var s := Vector2(100 + i * 2.6, 60 + i * 3)
		a.draw_line(s, s + Vector2(8 + (i % 3) * 4, 30 + (i % 4) * 6), muscle_l, 1.0)
	for i in 8:
		a.draw_line(Vector2(128, 70), Vector2(102 + i * 4, 48 + absi(4 - i) * 2), muscle_l, 1.0)
	# Crânio exposto no topo direito, com sutura
	a.draw_colored_polygon(PackedVector2Array([Vector2(96, 44), Vector2(112, 45), Vector2(128, 52), Vector2(136, 64), Vector2(120, 60), Vector2(96, 56)]), bone)
	for i in 6:
		a.draw_line(Vector2(100 + i * 5, 50 + (i % 2) * 2), Vector2(104 + i * 5, 50 - (i % 2) * 2 + 2), ink, 1.0)
	# Cabelo engomado do lado esquerdo
	a.draw_colored_polygon(PackedVector2Array([Vector2(96, 44), Vector2(96, 56), Vector2(80, 58), Vector2(62, 68), Vector2(56, 82), Vector2(56, 64), Vector2(70, 48)]), Color(0.12, 0.08, 0.07))
	# Olhos
	var lid := 1.0 - eyes_open
	a.draw_colored_polygon(PackedVector2Array([Vector2(66, 86), Vector2(76, 80), Vector2(86, 86), Vector2(76, 91)]), Color(0.95, 0.92, 0.86))
	a.draw_circle(Vector2(77, 86), 3.2, Color(0.25, 0.35, 0.3))
	a.draw_circle(Vector2(77, 86), 1.4, ink)
	if lid > 0.01:
		a.draw_rect(Rect2(66, 79, 20, 7 * lid), skin_d)
	# Óculos só do lado com pele
	a.draw_arc(Vector2(76, 86), 9, 0, TAU, 16, Color(0.45, 0.36, 0.2), 1.0)
	a.draw_line(Vector2(85, 86), Vector2(96, 84), Color(0.45, 0.36, 0.2), 1.0)
	# Olho sem pálpebra, veias
	a.draw_circle(Vector2(118, 86), 9, Color(0.96, 0.93, 0.88))
	for i in 6:
		var ang3 := TAU * i / 6.0 + 0.4
		a.draw_line(Vector2(118, 86) + Vector2(cos(ang3), sin(ang3)) * 9, Vector2(118, 86) + Vector2(cos(ang3), sin(ang3)) * 5, Color(0.8, 0.2, 0.2), 1.0)
	var look := Vector2(sin(t * 0.8) * 1.5, 0) if eyes_open > 0.5 else Vector2.ZERO
	a.draw_circle(Vector2(118, 86) + look, 4, Color(0.25, 0.35, 0.3))
	a.draw_circle(Vector2(118, 86) + look, 1.8, ink)
	# Nariz: metade pele, metade cavidade
	a.draw_colored_polygon(PackedVector2Array([Vector2(96, 88), Vector2(88, 112), Vector2(96, 116)]), skin_d)
	a.draw_colored_polygon(PackedVector2Array([Vector2(96, 92), Vector2(104, 112), Vector2(96, 116)]), Color(0.15, 0.03, 0.03))
	# Boca: bigode e lábio de um lado, dentes e gengiva do outro.
	a.draw_colored_polygon(PackedVector2Array([Vector2(74, 120), Vector2(96, 116), Vector2(96, 122), Vector2(78, 124)]), Color(0.16, 0.1, 0.08))
	a.draw_rect(Rect2(80, 126, 16, 4), Color(0.6, 0.32, 0.3))
	a.draw_rect(Rect2(96, 122, 22, 12), Color(0.55, 0.1, 0.12))
	for i in 6:
		a.draw_rect(Rect2(97 + i * 3.5, 124, 3, 4), bone)
		a.draw_rect(Rect2(97 + i * 3.5, 129, 3, 4), bone)
	# Orelha esquerda
	a.draw_colored_polygon(PackedVector2Array([Vector2(55, 84), Vector2(48, 90), Vector2(50, 106), Vector2(56, 104)]), skin_d)
	a.draw_set_transform(Vector2.ZERO)
	# Linhas de anotação ligando o rosto às letras da margem.
	var pts := [Vector2(120, 62), Vector2(126, 86), Vector2(110, 128), Vector2(108, 160), Vector2(64, 80), Vector2(70, 124)]
	for k in pts.size():
		var from: Vector2 = c0 + ((pts[k] as Vector2) - c) * zoom
		var to := Vector2(176, 30 + k * 26) if k < 4 else Vector2(176, 30 + k * 26)
		a.draw_line(from, to, Color(0.2, 0.12, 0.08, 0.8), 1.0)
		a.draw_circle(from, 1.5, ink)
		_label(a, to + Vector2(2, 3), "abcdef"[k])
	_label(a, Vector2(12, 184), "E. M. fecit 1909")


func _label(a: Node2D, at: Vector2, text: String) -> void:
	a.draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.2, 0.12, 0.08))


## Legenda em latim no canto: dá textura às peças de baixo.
func _legend(a: Node2D) -> void:
	var lines := ["a. os parietale", "b. bulbus oculi", "c. dentes", "d. m. sternocl.", "e. palpebra", "f. labium"]
	for i in lines.size():
		_label(a, Vector2(140, 128 + i * 9), lines[i])
	a.draw_line(Vector2(138, 122), Vector2(186, 122), Color(0.3, 0.18, 0.1), 1.0)
