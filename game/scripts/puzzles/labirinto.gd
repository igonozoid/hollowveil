extends "res://scripts/puzzles/puzzle.gd"
## O LABIRINTO DAS FUNDAÇÕES — corredores de pedra em primeira pessoa, uma
## casa por passo e viradas de 90 graus, como nos velhos jogos de masmorra.
## A lamparina só alcança quatro casas. Depois de alguns passos, uma coisa
## pálida começa a rastejar atrás de Dália; é mais lenta que ela, mas não
## se perde. A semente gera o labirinto (com alguns atalhos) e a saída fica
## na casa mais distante da entrada.

const MW := 9
const MH := 9
const N_ := 1
const E_ := 2
const S_ := 4
const W_ := 8
const DIRS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const BITS := [N_, E_, S_, W_]
const VIEW := 5
const WAKE := 12

var walls: Array = []       # bits de parede por casa
var start := Vector2i()
var exit := Vector2i()
var pos := Vector2i()
var facing := 1             # 0 N, 1 L, 2 S, 3 O
var visited := {}
var steps := 0
var creature := Vector2i(-1, -1)
var creature_on := false
var caught_t := 0.0
var bob := 0.0
var path_hint: Array = []
var buttons: Array = []


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("labirinto")
	generate(rng)
	_restart()
	if State.flag("hint2_labirinto"):
		path_hint = shortest(start, exit)
	var labels := ["Virar à esquerda", "Avançar", "Virar à direita", "Recuar"]
	var xs := [206, 270, 334, 398]
	var ys := [334, 334, 334, 334]
	var glyphs := ["Esquerda", "Frente", "Direita", "Trás"]
	for k in 4:
		var b := Button.new()
		b.text = glyphs[k]
		b.tooltip_text = labels[k]
		b.position = Vector2(xs[k], ys[k] - 6)
		b.size = Vector2(60, 18)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 9)
		b.pressed.connect(_act.bind(k))
		add_child(b)
		buttons.append(b)


func _restart() -> void:
	pos = start
	facing = 1 if walls[_i(start)] & E_ == 0 else 2
	steps = 0
	creature_on = false
	creature = Vector2i(-1, -1)
	visited[pos] = true


static func hint(level: int) -> String:
	if level == 1:
		return "Siga sempre a mesma parede com a mão. E olhe o mapa no canto: o giz marca onde você já pisou."
	return "A prancheta riscou setas de giz no chão, apontando o caminho mais curto até a saída."


func _i(c: Vector2i) -> int:
	return c.y * MW + c.x


func inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < MW and c.y < MH


func open_dir(c: Vector2i, d: int) -> bool:
	return inside(c) and inside(c + DIRS[d]) and walls[_i(c)] & BITS[d] == 0


func generate(rng: RandomNumberGenerator) -> void:
	walls = []
	for i in MW * MH:
		walls.append(15)
	# Labirinto perfeito por busca em profundidade.
	var stack: Array = [Vector2i(0, 0)]
	var seen := {Vector2i(0, 0): true}
	while not stack.is_empty():
		var c: Vector2i = stack[-1]
		var opts: Array = []
		for d in 4:
			var n: Vector2i = c + DIRS[d]
			if inside(n) and not seen.has(n):
				opts.append(d)
		if opts.is_empty():
			stack.pop_back()
			continue
		var d2: int = opts[rng.randi() % opts.size()]
		_carve(c, d2)
		seen[c + DIRS[d2]] = true
		stack.append(c + DIRS[d2])
	# Alguns atalhos, para a coisa não poder encurralar Dália num corredor só.
	var made := 0
	while made < 9:
		var c3 := Vector2i(rng.randi() % MW, rng.randi() % MH)
		var d3 := rng.randi() % 4
		if inside(c3 + DIRS[d3]) and walls[_i(c3)] & BITS[d3] != 0:
			_carve(c3, d3)
			made += 1
	start = Vector2i(0, rng.randi() % MH)
	var dist := _bfs(start)
	exit = start
	for k in dist:
		if dist[k] > dist[exit] or (dist[k] == dist[exit] and _i(k) > _i(exit)):
			exit = k


func _carve(c: Vector2i, d: int) -> void:
	walls[_i(c)] &= ~BITS[d]
	walls[_i(c + DIRS[d])] &= ~BITS[(d + 2) % 4]


func _bfs(from: Vector2i) -> Dictionary:
	var dist := {from: 0}
	var q: Array = [from]
	var head := 0
	while head < q.size():
		var c: Vector2i = q[head]
		head += 1
		for d in 4:
			if open_dir(c, d) and not dist.has(c + DIRS[d]):
				dist[c + DIRS[d]] = dist[c] + 1
				q.append(c + DIRS[d])
	return dist


## Caminho mais curto (lista de casas, sem a de origem).
func shortest(a: Vector2i, b: Vector2i) -> Array:
	var prev := {a: a}
	var q: Array = [a]
	var head := 0
	while head < q.size():
		var c: Vector2i = q[head]
		head += 1
		if c == b:
			break
		for d in 4:
			var n: Vector2i = c + DIRS[d]
			if open_dir(c, d) and not prev.has(n):
				prev[n] = c
				q.append(n)
	var out: Array = []
	var c2 := b
	while c2 != a and prev.has(c2):
		out.push_front(c2)
		c2 = prev[c2]
	return out


## 0 vira à esquerda, 1 avança, 2 vira à direita, 3 recua.
func _act(k: int) -> void:
	if done or caught_t > 0.0:
		return
	match k:
		0:
			facing = (facing + 3) % 4
			Audio.play("step", -16.0, 1.2)
		2:
			facing = (facing + 1) % 4
			Audio.play("step", -16.0, 1.2)
		1, 3:
			var d := facing if k == 1 else (facing + 2) % 4
			if not open_dir(pos, d):
				Audio.play("slam", -18.0, 2.0)
				shake(0.15)
				return
			move(d)


## Um passo na direção d (absoluta). Devolve false se houver parede.
func move(d: int) -> bool:
	if done or not open_dir(pos, d):
		return false
	pos += DIRS[d]
	visited[pos] = true
	steps += 1
	bob = 1.0
	Audio.play("step", -10.0, randf_range(0.75, 0.9))
	if pos == exit:
		Audio.play("sting", -8.0, 1.3)
		say("DÁLIA", "Uma escada de ferro sobe por um poço de pedra. Lá no alto, um quadrado de luz de vela.")
		finish()
		return true
	_creature_turn()
	return true


func _creature_turn() -> void:
	if not creature_on:
		if steps >= WAKE:
			creature_on = true
			creature = start
			Audio.play("cry", -6.0, 0.7)
			say("DÁLIA", "Atrás de mim, na entrada, alguma coisa caiu no chão molhado. E começou a se arrastar.")
		return
	# Anda uma casa a cada dois passos de Dália, sempre pelo caminho mais curto.
	if steps % 2 == 0:
		var p := shortest(creature, pos)
		if not p.is_empty():
			creature = p[0]
	var gap := shortest(creature, pos).size()
	if creature == pos or gap == 0:
		_caught()
	elif gap <= 3:
		Audio.play("squelch", -10.0 - gap * 3.0, 0.5)
		Audio.play("whisper", -12.0 - gap * 2.0, 0.6)


func _caught() -> void:
	caught_t = 1.6
	Audio.play("scream", -2.0, 1.4)
	Audio.play("crunch", -2.0, 0.8)
	shake(1.0)
	State.change_sanity(-8.0)
	say("MORVANT", ["Ele gosta de você, médium. Começou pelos tornozelos.", "Meu filho ainda não sabe brincar direito. Comece de novo.", "Não corra. Ele fica nervoso quando corre."][randi() % 3])



func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_LEFT, KEY_A, KEY_Q:
			_act(0)
		KEY_UP, KEY_W:
			_act(1)
		KEY_RIGHT, KEY_D, KEY_E:
			_act(2)
		KEY_DOWN, KEY_S:
			_act(3)
		_:
			return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	super(delta)
	if caught_t > 0.0:
		caught_t -= delta
		if caught_t <= 0.0:
			caught_t = 0.0
			_restart()
	bob = maxf(0.0, bob - delta * 4.0)


# ---------------------------------------------------------------- desenho

const CX := 320.0
const CY := 150.0


func _hw(z: float) -> float:
	return 190.0 / z


func _hh(z: float) -> float:
	return 120.0 / z


func _shade(col: Color, z: float) -> Color:
	var k := clampf(1.05 - z * 0.27, 0.03, 1.0)
	k *= 0.9 + 0.1 * sin(t * 9.0) * sin(t * 5.3)
	return Color(col.r * k, col.g * k, col.b * k)


func _face(x0: float, x1: float, z: float, col: Color) -> void:
	# Parede de frente (plano z constante), com fiadas de pedra.
	var hw := _hw(z)
	var hh := _hh(z)
	var r := Rect2(CX + x0 * hw * 2.0, CY - hh, (x1 - x0) * hw * 2.0, hh * 2.0)
	draw_rect(r, _shade(col, z))
	for k in 5:
		var y := r.position.y + r.size.y * (k + 1) / 6.0
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), _shade(col.darkened(0.45), z), 1.0)
		# Juntas verticais desencontradas.
		var off := 0.25 if k % 2 == 0 else 0.0
		var xx := r.position.x + r.size.x * off
		while xx < r.end.x:
			draw_line(Vector2(xx, y), Vector2(xx, y - r.size.y / 6.0), _shade(col.darkened(0.45), z), 1.0)
			xx += r.size.x * 0.5
	# Umidade escorrendo.
	if State.gore and int(absf(x0 * 7.0 + z * 3.0)) % 3 == 0:
		draw_rect(Rect2(r.position.x + r.size.x * 0.7, r.position.y + r.size.y * 0.1, maxf(1.0, 3.0 / z), r.size.y * 0.5), _shade(Color(0.35, 0.02, 0.03), z))


func _side(side: float, za: float, zb: float, col: Color) -> void:
	# Parede lateral entre as profundidades za e zb (side -1 esquerda, 1 direita).
	var xa := CX + side * _hw(za)
	var xb := CX + side * _hw(zb)
	var c := _shade(col, (za + zb) * 0.5)
	draw_colored_polygon(PackedVector2Array([Vector2(xa, CY - _hh(za)), Vector2(xb, CY - _hh(zb)), Vector2(xb, CY + _hh(zb)), Vector2(xa, CY + _hh(za))]), c)
	for k in 5:
		var f := (k + 1) / 6.0
		draw_line(Vector2(xa, CY - _hh(za) + 2.0 * _hh(za) * f), Vector2(xb, CY - _hh(zb) + 2.0 * _hh(zb) * f), _shade(col.darkened(0.45), (za + zb) * 0.5), 1.0)


func _floor_mark(cell: Vector2i, z: float) -> void:
	var y := CY + _hh(z)
	var w := _hw(z) * 0.3
	if path_hint.has(cell):
		var nxt_i := path_hint.find(cell) + 1
		if nxt_i < path_hint.size():
			var nd: Vector2i = path_hint[nxt_i] - cell
			var rel := (DIRS.find(nd) - facing + 4) % 4
			var a: Vector2 = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)][rel]
			var c := Vector2(CX, y - _hh(z) * 0.08)
			draw_line(c - a * w, c + a * w, _shade(Color(0.95, 0.95, 0.9), z), 2.0)
			draw_line(c + a * w, c + a * w * 0.4 + a.orthogonal() * w * 0.4, _shade(Color(0.95, 0.95, 0.9), z), 2.0)
			draw_line(c + a * w, c + a * w * 0.4 - a.orthogonal() * w * 0.4, _shade(Color(0.95, 0.95, 0.9), z), 2.0)
	elif visited.has(cell):
		var c2 := Vector2(CX, y - _hh(z) * 0.08)
		draw_line(c2 + Vector2(-w, -w * 0.2), c2 + Vector2(w, w * 0.2), _shade(Color(0.8, 0.8, 0.75), z), 1.0)
		draw_line(c2 + Vector2(w, -w * 0.2), c2 + Vector2(-w, w * 0.2), _shade(Color(0.8, 0.8, 0.75), z), 1.0)


func _draw_creature(z: float) -> void:
	var s := 1.0 / z
	var base := Vector2(CX + sin(t * 3.0) * 10.0 * s, CY + _hh(z))
	var pale := _shade(Color(0.85, 0.82, 0.78), z * 0.8)
	# Corpo deitado, braços compridos demais, cabeça grande.
	draw_colored_polygon(PackedVector2Array([base + Vector2(-50, -10) * s, base + Vector2(40, -16) * s, base + Vector2(50, 0) * s, base + Vector2(-50, 0) * s]), pale.darkened(0.2))
	for side in [-1.0, 1.0]:
		var reach := sin(t * 4.0 + side) * 12.0
		var elbow := base + Vector2(side * 70.0, -40.0 + reach) * s
		draw_line(base + Vector2(side * 20.0, -12) * s, elbow, pale, maxf(1.0, 6.0 * s))
		draw_line(elbow, base + Vector2(side * 110.0, -2) * s, pale, maxf(1.0, 5.0 * s))
		for f in 3:
			draw_line(base + Vector2(side * 110.0, -2) * s, base + Vector2(side * (118.0 + f * 4.0), 2.0 + f * 2.0) * s, pale.darkened(0.3), 1.0)
	var head := base + Vector2(0, -44) * s
	draw_circle(head, 34.0 * s, pale)
	draw_circle(head + Vector2(-12, -6) * s, 8.0 * s, Color(0.0, 0.0, 0.0))
	draw_circle(head + Vector2(12, -6) * s, 8.0 * s, Color(0.0, 0.0, 0.0))
	draw_rect(Rect2(head + Vector2(-10, 12) * s, Vector2(20, 6 + 4 * absf(sin(t * 6.0))) * s), Color(0.05, 0.0, 0.0))
	if State.gore:
		draw_rect(Rect2(head + Vector2(-6, 18) * s, Vector2(3, 18) * s), Color(0.55, 0.0, 0.04))
		draw_rect(Rect2(head + Vector2(4, 18) * s, Vector2(2, 24) * s), Color(0.55, 0.0, 0.04))
		draw_line(base + Vector2(-50, -2) * s, base + Vector2(-90, 0) * s, Color(0.45, 0.0, 0.03), maxf(1.0, 4.0 * s))


func _draw_exit(z: float) -> void:
	var hw := _hw(z)
	var hh := _hh(z)
	var top := Vector2(CX, CY - hh)
	draw_colored_polygon(PackedVector2Array([top + Vector2(-hw * 0.35, 0), top + Vector2(hw * 0.35, 0), Vector2(CX + hw * 0.5, CY + hh), Vector2(CX - hw * 0.5, CY + hh)]), Color(1.0, 0.78, 0.45, 0.22))
	for k in 7:
		var y := CY - hh + 2.0 * hh * (k + 0.5) / 7.0
		draw_line(Vector2(CX - hw * 0.18, y), Vector2(CX + hw * 0.18, y), _shade(Color(0.5, 0.42, 0.3), z), maxf(1.0, 3.0 / z))
	draw_line(Vector2(CX - hw * 0.18, CY - hh), Vector2(CX - hw * 0.18, CY + hh), _shade(Color(0.45, 0.38, 0.28), z), maxf(1.0, 3.0 / z))
	draw_line(Vector2(CX + hw * 0.18, CY - hh), Vector2(CX + hw * 0.18, CY + hh), _shade(Color(0.45, 0.38, 0.28), z), maxf(1.0, 3.0 / z))


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0))
	var font := get_theme_default_font()
	var by := sin(bob * PI) * 3.0
	draw_set_transform(Vector2(0, by))
	# Teto e chão em degradê, escurecendo com a distância.
	for k in 20:
		var f := k / 20.0
		var y0 := f * CY
		draw_rect(Rect2(0, y0, 640, CY / 20.0 + 1), Color(0.06, 0.06, 0.08).lerp(Color(0.0, 0.0, 0.0), f))
		draw_rect(Rect2(0, 2 * CY - y0 - CY / 20.0, 640, CY / 20.0 + 1), Color(0.12, 0.1, 0.09).lerp(Color(0.0, 0.0, 0.0), f))
	var stone := Color(0.34, 0.33, 0.36)
	var fwd: Vector2i = DIRS[facing]
	var left: int = (facing + 3) % 4
	var right: int = (facing + 1) % 4
	# Monta do fundo para a frente.
	var depth := 0
	var cells: Array = [pos]
	while depth < VIEW and open_dir(cells[-1], facing):
		cells.append(cells[-1] + fwd)
		depth += 1
	for k in range(cells.size() - 1, -1, -1):
		var c: Vector2i = cells[k]
		var za := maxf(k - 0.5, 0.32)
		var zb := k + 0.5
		if k == cells.size() - 1:
			if k == VIEW and open_dir(c, facing):
				pass
			else:
				_face(-0.5, 0.5, zb, stone)
		for side in [-1, 1]:
			var d: int = left if side < 0 else right
			if not open_dir(c, d):
				_side(side, za, zb, stone.darkened(0.1))
			else:
				# Abertura lateral: a parede da frente da casa vizinha.
				var nb: Vector2i = c + DIRS[d]
				if not open_dir(nb, facing):
					if side < 0:
						_face(-1.5, -0.5, zb, stone.darkened(0.2))
					else:
						_face(0.5, 1.5, zb, stone.darkened(0.2))
		if k > 0:
			_floor_mark(c, float(k))
		if c == exit and k > 0:
			_draw_exit(float(k))
		if creature_on and c == creature and k > 0:
			_draw_creature(float(k))
	draw_set_transform(Vector2.ZERO)
	# A coisa colada em Dália.
	if caught_t > 0.0:
		var a := minf(1.0, caught_t)
		_draw_creature(0.9)
		if State.gore:
			draw_rect(Rect2(0, 0, 640, 360), Color(0.5, 0.0, 0.03, a * 0.5))
			for i in 20:
				draw_rect(Rect2(fmod(i * 97.0, 640.0), 0, 3, 360.0 * (1.0 - caught_t / 1.6) * (0.4 + fmod(i * 0.37, 0.6))), Color(0.6, 0.0, 0.04, a))
	# Mapa de giz no canto: só o que já foi pisado.
	var mo := Vector2(548, 26)
	var ms := 9.0
	draw_rect(Rect2(mo - Vector2(4, 4), Vector2(MW * ms + 8, MH * ms + 8)), Color(0.05, 0.04, 0.035, 0.85))
	for cell in visited:
		var r := Rect2(mo + Vector2(cell) * ms, Vector2(ms, ms))
		draw_rect(r.grow(-1), Color(0.3, 0.28, 0.24))
		var w: int = walls[_i(cell)]
		var lc := Color(0.85, 0.82, 0.74)
		if w & N_:
			draw_line(r.position, Vector2(r.end.x, r.position.y), lc, 1.0)
		if w & S_:
			draw_line(Vector2(r.position.x, r.end.y), r.end, lc, 1.0)
		if w & W_:
			draw_line(r.position, Vector2(r.position.x, r.end.y), lc, 1.0)
		if w & E_:
			draw_line(Vector2(r.end.x, r.position.y), r.end, lc, 1.0)
	if not path_hint.is_empty():
		draw_rect(Rect2(mo + Vector2(exit) * ms + Vector2(2, 2), Vector2(ms - 4, ms - 4)), Color(1.0, 0.8, 0.4))
	var me := mo + (Vector2(pos) + Vector2(0.5, 0.5)) * ms
	var fv := Vector2(DIRS[facing])
	draw_colored_polygon(PackedVector2Array([me + fv * 4.0, me + fv.orthogonal() * 3.0 - fv * 2.0, me - fv.orthogonal() * 3.0 - fv * 2.0]), Color(1.0, 0.7, 0.3))
	if creature_on and visited.has(creature):
		draw_circle(mo + (Vector2(creature) + Vector2(0.5, 0.5)) * ms, 2.5, Color(0.8, 0.1, 0.1, 0.5 + 0.5 * sin(t * 8.0)))
	draw_string(font, Vector2(44, 20), "AS FUNDAÇÕES", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(44, 34), "Setas ou WASD · ache a saída", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.55, 0.48))
