extends "res://scripts/puzzles/puzzle.gd"
## O MÓBILE — o móbile do berço tem uma barra de cima e duas barras menores,
## com quatro ganchos. Há cinco brinquedos de pesos diferentes (os pontinhos
## gravados dizem o peso); pendure quatro para equilibrar tudo. Os braços
## têm marcas de medida: peso × distância tem que ser igual dos dois lados.
## A semente gera pesos e braços com uma única solução.

const TOP := Vector2(320, 62)
const TOYS := ["cavalinho", "sino", "lua", "estrela", "peixe"]

var weights: Array = []   # peso de cada brinquedo (5)
var solution: Array = []  # brinquedo certo em cada gancho (4)
var arms: Array = []      # [a, b, c, d, e, f] em unidades
var hooks: Array = [-1, -1, -1, -1]
var locked: Array = [false, false, false, false]
var held := -1
var tilt: Array = [0.0, 0.0, 0.0]
var win_t := -1.0


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("movel")
	for attempt in 200:
		var pool := [1, 2, 3, 4, 5, 6, 7]
		for i in range(pool.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = pool[i]
			pool[i] = pool[j]
			pool[j] = tmp
		weights = pool.slice(0, 5)
		var pick := [0, 1, 2, 3, 4]
		for i in range(4, 0, -1):
			var j2 := rng.randi_range(0, i)
			var tmp2 = pick[i]
			pick[i] = pick[j2]
			pick[j2] = tmp2
		solution = pick.slice(0, 4)
		var w: Array = []
		for s in solution:
			w.append(weights[s])
		var g1 := _gcd(w[0], w[1])
		var g2 := _gcd(w[2], w[3])
		var c: int = w[1] / g1
		var d: int = w[0] / g1
		var e: int = w[3] / g2
		var f: int = w[2] / g2
		var g3 := _gcd(w[0] + w[1], w[2] + w[3])
		var a: int = (w[2] + w[3]) / g3
		var b: int = (w[0] + w[1]) / g3
		if maxi(maxi(a, b), maxi(maxi(c, d), maxi(e, f))) > 9:
			continue
		arms = [a, b, c, d, e, f]
		if _count_solutions() == 1:
			break
	if State.drafts.has("movel") and (State.drafts["movel"] as Array).size() == 4:
		for i in 4:
			hooks[i] = int(State.drafts["movel"][i])
	if State.flag("hint2_movel"):
		var k := rng.randi() % 4
		for i in 4:
			if hooks[i] == solution[k]:
				hooks[i] = -1
		hooks[k] = solution[k]
		locked[k] = true


func _gcd(x: int, y: int) -> int:
	while y != 0:
		var r := x % y
		x = y
		y = r
	return x


func _balanced(h: Array) -> bool:
	if -1 in h:
		return false
	var w: Array = []
	for t2 in h:
		w.append(weights[t2])
	return w[0] * arms[2] == w[1] * arms[3] and w[2] * arms[4] == w[3] * arms[5] and (w[0] + w[1]) * arms[0] == (w[2] + w[3]) * arms[1]


func _count_solutions() -> int:
	var n := 0
	for a in 5:
		for b in 5:
			for c in 5:
				for d in 5:
					if a == b or a == c or a == d or b == c or b == d or c == d:
						continue
					if _balanced([a, b, c, d]):
						n += 1
	return n


static func hint(level: int) -> String:
	if level == 1:
		return "Conte as marcas de cada braço. Peso vezes marcas tem que dar igual dos dois lados. Uma barra menor pesa a soma do que carrega."
	return "A prancheta pendurou um brinquedo no lugar certo. Ele não sai mais de lá."


# ---------------------------------------------------------------- geometria

func _unit(bar: int) -> float:
	var m: int = maxi(arms[0], arms[1]) if bar == 0 else (maxi(arms[2], arms[3]) if bar == 1 else maxi(arms[4], arms[5]))
	return (130.0 if bar == 0 else 52.0) / maxf(1.0, m)


func _ends() -> Dictionary:
	var u0 := _unit(0)
	var l0: Vector2 = TOP + Vector2(-arms[0] * u0, 0).rotated(tilt[0])
	var r0: Vector2 = TOP + Vector2(arms[1] * u0, 0).rotated(tilt[0])
	var p1 := l0 + Vector2(0, 60)
	var p2 := r0 + Vector2(0, 60)
	var u1 := _unit(1)
	var u2 := _unit(2)
	var hk := [p1 + Vector2(-arms[2] * u1, 0).rotated(tilt[1]), p1 + Vector2(arms[3] * u1, 0).rotated(tilt[1]),
		p2 + Vector2(-arms[4] * u2, 0).rotated(tilt[2]), p2 + Vector2(arms[5] * u2, 0).rotated(tilt[2])]
	return {"l0": l0, "r0": r0, "p1": p1, "p2": p2, "hooks": hk}


func _hook_toy_pos(i: int, e: Dictionary) -> Vector2:
	return (e["hooks"][i] as Vector2) + Vector2(0, 44)


func _tray_pos(t2: int) -> Vector2:
	return Vector2(176 + t2 * 72, 322)


# ---------------------------------------------------------------- entrada

func _gui_input(event: InputEvent) -> void:
	if done:
		return
	var e := _ends()
	if event is InputEventMouseMotion:
		var over := false
		for i in 4:
			if _hook_toy_pos(i, e).distance_to(event.position) < 22:
				over = true
		for t2 in 5:
			if _tray_pos(t2).distance_to(event.position) < 26:
				over = true
		set_cursor("hand" if over or held >= 0 else "flame")
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		held = -1
		return
	for i in 4:
		if _hook_toy_pos(i, e).distance_to(event.position) < 22:
			if locked[i]:
				Audio.play("locked", -10.0)
				return
			var prev: int = hooks[i]
			hooks[i] = held
			held = prev
			Audio.play("tile", -6.0, 1.6)
			State.drafts["movel"] = hooks.duplicate()
			_check()
			return
	for t2 in 5:
		if _tray_pos(t2).distance_to(event.position) < 26 and not t2 in hooks:
			held = t2 if held != t2 else -1
			Audio.play("card", -8.0, 1.4)
			return
	held = -1


func _check() -> void:
	if _balanced(hooks):
		win_t = 0.0
		State.drafts.erase("movel")
		Audio.play("solved", -8.0, 1.2)
		say("DÁLIA", "Equilibrado. O móbile gira sozinho... e uma voz de mulher começa a cantar para o berço.")
		finish()
	elif not -1 in hooks:
		Audio.play("wrong", -10.0, 1.4)
		State.change_sanity(-2.0)


# ---------------------------------------------------------------- desenho

func _process(delta: float) -> void:
	super(delta)
	var w := []
	for h in hooks:
		w.append(0 if h < 0 else weights[h])
	var target := [
		clampf(((w[2] + w[3]) * arms[1] - (w[0] + w[1]) * arms[0]) * 0.012, -0.32, 0.32),
		clampf((w[1] * arms[3] - w[0] * arms[2]) * 0.03, -0.4, 0.4),
		clampf((w[3] * arms[5] - w[2] * arms[4]) * 0.03, -0.4, 0.4),
	]
	for i in 3:
		tilt[i] = lerpf(tilt[i], target[i] + sin(t * 1.3 + i) * 0.015, minf(1.0, delta * 3.0))
	if win_t >= 0.0:
		win_t += delta


func _bar(a: Vector2, b: Vector2, pivot: Vector2, units_l: int, units_r: int) -> void:
	draw_line(a, b, Color(0.62, 0.48, 0.3), 3.0)
	# Marcas de medida em cada braço
	for k in range(1, units_l + 1):
		var q := pivot.lerp(a, float(k) / units_l)
		draw_line(q + Vector2(0, -3), q + Vector2(0, 3), Color(0.25, 0.15, 0.08), 1.0)
	for k in range(1, units_r + 1):
		var q2 := pivot.lerp(b, float(k) / units_r)
		draw_line(q2 + Vector2(0, -3), q2 + Vector2(0, 3), Color(0.25, 0.15, 0.08), 1.0)
	draw_circle(pivot, 3.0, Color(0.75, 0.6, 0.3))


func _toy(c: Vector2, t2: int, glow: bool) -> void:
	var col: Color = [Color(0.75, 0.55, 0.35), Color(0.85, 0.75, 0.3), Color(0.8, 0.82, 0.9), Color(0.9, 0.8, 0.45), Color(0.5, 0.7, 0.8)][t2]
	match TOYS[t2]:
		"cavalinho":
			draw_rect(Rect2(c + Vector2(-10, -4), Vector2(18, 8)), col)
			draw_rect(Rect2(c + Vector2(6, -12), Vector2(6, 10)), col)
			for lx in [-8, -2, 2, 6]:
				draw_rect(Rect2(c + Vector2(lx, 4), Vector2(2, 6)), col.darkened(0.3))
		"sino":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -10), c + Vector2(4, -10), c + Vector2(10, 8), c + Vector2(-10, 8)]), col)
			draw_circle(c + Vector2(0, 9), 2.5, col.darkened(0.4))
		"lua":
			draw_circle(c, 11, col)
			draw_circle(c + Vector2(5, -3), 9, Color(0.08, 0.05, 0.08))
		"estrela":
			var pts := PackedVector2Array()
			for k in 10:
				var r := 12.0 if k % 2 == 0 else 5.0
				var a := -PI * 0.5 + TAU * k / 10.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, col)
		"peixe":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-12, 0), c + Vector2(0, -7), c + Vector2(10, 0), c + Vector2(0, 7)]), col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(8, 0), c + Vector2(14, -6), c + Vector2(14, 6)]), col)
	# Pontinhos gravados: o peso.
	var wgt: int = weights[t2]
	for k in wgt:
		draw_rect(Rect2(c + Vector2(-wgt * 2.0 + k * 4.0, 14), Vector2(2, 2)), Color(0.95, 0.9, 0.8))
	if glow:
		draw_arc(c, 18, 0, TAU, 16, Color(0.9, 0.2, 0.15), 1.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.05, 0.045, 0.06))
	# Céu de berço: estrelinhas pintadas no teto
	for i in 40:
		draw_rect(Rect2(fmod(i * 83.1, 640.0), fmod(i * 41.7, 140.0), 1, 1), Color(0.8, 0.8, 0.6, 0.4))
	var e := _ends()
	draw_line(Vector2(TOP.x, 0), TOP, Color(0.7, 0.68, 0.6), 1.0)
	draw_line(e["l0"], e["p1"], Color(0.7, 0.68, 0.6), 1.0)
	draw_line(e["r0"], e["p2"], Color(0.7, 0.68, 0.6), 1.0)
	_bar(e["l0"], e["r0"], TOP, arms[0], arms[1])
	_bar(e["hooks"][0], e["hooks"][1], e["p1"], arms[2], arms[3])
	_bar(e["hooks"][2], e["hooks"][3], e["p2"], arms[4], arms[5])
	for i in 4:
		var hk: Vector2 = e["hooks"][i]
		var tp := _hook_toy_pos(i, e)
		draw_line(hk, tp + Vector2(0, -12), Color(0.7, 0.68, 0.6), 1.0)
		if hooks[i] >= 0:
			_toy(tp, hooks[i], false)
			if locked[i]:
				draw_arc(tp, 20, 0, TAU, 16, Color(0.4, 0.9, 1.0, 0.6), 1.0)
		else:
			draw_arc(tp + Vector2(0, -12), 3, 0, PI, 6, Color(0.7, 0.6, 0.4), 1.0)
	# Bandeja dos brinquedos
	draw_rect(Rect2(140, 296, 360, 50), Color(0.18, 0.12, 0.1))
	draw_rect(Rect2(140, 296, 360, 50), Color(0.45, 0.32, 0.2), false, 1.0)
	for t2 in 5:
		if t2 in hooks or t2 == held:
			continue
		_toy(_tray_pos(t2), t2, false)
	if held >= 0:
		_toy(get_local_mouse_position() + Vector2(0, 14), held, true)
	var font := get_theme_default_font()
	draw_string(font, Vector2(276, 20), "O MÓBILE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(196, 36), "peso × marcas tem que dar igual dos dois lados de cada barra", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.5, 0.4))
