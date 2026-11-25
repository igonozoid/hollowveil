extends Node2D
## Cena fantasma em vista lateral. Os mortos reaparecem como figuras pálidas
## e translúcidas; Morvant é uma silhueta negra de óculos que brilham. O sangue
## é a única coisa sólida e em cor plena.
## Os roteiros são corrotinas (scene_<id>) que usam _w() para esperar.

signal finished

const Blood := preload("res://scripts/gfx/blood.gd")
const FLOOR := 276.0
const S := 1.35
const GHOST := Color(0.62, 0.95, 0.9)

var script_id := "ceia"
var host_version := false
var house = null
var actors: Dictionary = {}
var gibs: Array = []
var surfaces: Array = []
var blood := Blood.new()
var t := 0.0
var skipping := false
var shake_amt := 0.0
var flash := 0.0
var fog_alpha := 1.0
var prop_draw: Callable
var _playing := false


class Actor:
	var x := 0.0
	var y := FLOOR
	var facing := 1.0
	var kind := "man"          # man | woman | host | priest
	var alpha := 0.75
	var lean := 0.0            # inclinação do tronco (rad, para a frente)
	var fall := 0.0            # 0 em pé, 1 deitado de bruços
	var sit := 0.0             # 0 em pé, 1 sentado
	var arm_f := 0.0           # braço da frente (0 = para baixo, PI/2 = esticado)
	var arm_b := 0.0
	var bend := 0.3            # cotovelo
	var hands := true
	var eyes := true
	var rise := 0.0            # alma subindo do corpo
	var walk := 0.0            # fase do passo
	var walking := false
	var tool := ""             # alicate | serra | colher
	var tremble := 0.0
	var head_turn := 0.0


func _ready() -> void:
	add_child(blood)
	blood.floor_y = FLOOR
	blood.amount_scale = 1.4
	if house and house.cursor:
		house.cursor.mode = "flame"
	call("scene_" + script_id)


# ---------------------------------------------------------------- utilidades de roteiro

func _w(seconds: float) -> void:
	if skipping:
		await get_tree().process_frame
	else:
		await get_tree().create_timer(seconds).timeout


func _say(who: String, line: String) -> void:
	if skipping or house == null:
		return
	house.subs.say(who, line)


func _sfx(name: String, vol: float = 0.0, pitch: float = 1.0) -> void:
	if not skipping:
		Audio.play(name, vol, pitch)


func _actor(id: String, props: Dictionary) -> Actor:
	var a := Actor.new()
	for k in props:
		a.set(k, props[k])
	if a.kind == "host":
		a.alpha = 1.0
	actors[id] = a
	return a


func _tw(a: Actor, prop: String, value: float, secs: float) -> void:
	if skipping:
		a.set(prop, value)
		return
	var tw := create_tween()
	tw.tween_method(func(v): a.set(prop, v), a.get(prop), value, secs).set_trans(Tween.TRANS_SINE)


func _walk_to(a: Actor, x: float, secs: float) -> void:
	a.facing = signf(x - a.x) if not is_equal_approx(x, a.x) else a.facing
	a.walking = true
	_tw(a, "x", x, secs)
	if not skipping:
		get_tree().create_timer(secs).timeout.connect(func(): a.walking = false)
		var steps := int(secs / 0.45)
		for i in steps:
			get_tree().create_timer(i * 0.45).timeout.connect(func(): _sfx("step", -10.0, 0.8))
	else:
		a.walking = false


func _shake(v: float) -> void:
	if skipping:
		return
	shake_amt = maxf(shake_amt, v)
	if house and house.post:
		house.post.kick(v * 0.5)


func _end() -> void:
	if house:
		house.subs.clear()
	finished.emit()


## Esc: pula a cena (roda o resto do roteiro instantaneamente, sem som).
func skip() -> void:
	skipping = true
	if house:
		house.subs.clear()


# ---------------------------------------------------------------- esqueleto

## Pontos do corpo em coordenadas de tela.
func _skeleton(a: Actor) -> Dictionary:
	var step := sin(a.walk) if a.walking else 0.0
	var hip := Vector2(0, -28).lerp(Vector2(0, -21), a.sit)
	var k := {}
	k["foot_b"] = Vector2(-3 + step * 5.0, 0).lerp(Vector2(9, 0), a.sit)
	k["foot_f"] = Vector2(3 - step * 5.0, 0).lerp(Vector2(11, 0), a.sit)
	k["knee_b"] = Vector2(-1 + step * 3.0, -14).lerp(Vector2(9, -21), a.sit)
	k["knee_f"] = Vector2(2 - step * 3.0, -14).lerp(Vector2(11, -21), a.sit)
	k["hip"] = hip
	var up := Vector2(0, -1).rotated(a.lean + a.tremble * sin(t * 40.0) * 0.05)
	k["shoulder"] = hip + up * 20.0
	k["neck"] = hip + up * 23.0
	k["head"] = hip + up * 29.0
	var fwd := Vector2(1, 0).rotated(a.lean)
	for side in ["f", "b"]:
		var ang: float = (a.arm_f if side == "f" else a.arm_b) + (step * 0.4 * (1 if side == "f" else -1) if a.walking else 0.0)
		var dir := Vector2(0, 1).rotated(-ang + a.lean)
		var elbow: Vector2 = k["shoulder"] + dir * 11.0
		var hand: Vector2 = elbow + dir.rotated(-a.bend) * 10.0
		k["elbow_" + side] = elbow
		k["hand_" + side] = hand
	k["mouth"] = k["head"] + fwd * 4.0 + up * -1.5
	k["eyes"] = k["head"] + fwd * 3.5 + up * 1.5
	# Queda: gira tudo em volta dos pés.
	var out := {}
	for key in k:
		var p: Vector2 = (k[key] as Vector2).rotated(a.fall * PI * 0.5) * S
		p.x *= a.facing
		out[key] = Vector2(a.x, a.y - a.rise) + p
	out["fwd"] = Vector2(fwd.x * a.facing, fwd.y).rotated(a.fall * PI * 0.5 * a.facing)
	return out


func part(id: String, name: String) -> Vector2:
	return _skeleton(actors[id])[name]


# ---------------------------------------------------------------- simulação

func _process(delta: float) -> void:
	t += delta
	shake_amt = maxf(0.0, shake_amt - delta * 3.0)
	flash = maxf(0.0, flash - delta * 2.0)
	for a: Actor in actors.values():
		if a.walking:
			a.walk += delta * 9.0
	for g in gibs:
		if g["rest"]:
			continue
		g["vel"].y += 420.0 * delta
		g["pos"] += g["vel"] * delta
		g["rot"] += delta * 8.0
		for r: Rect2 in surfaces:
			if g["pos"].x > r.position.x and g["pos"].x < r.end.x and g["pos"].y >= r.position.y and g["pos"].y - g["vel"].y * delta < r.position.y + 2:
				g["pos"].y = r.position.y
				g["rest"] = true
		if g["pos"].y >= FLOOR:
			g["pos"].y = FLOOR
			g["rest"] = true
		if g["rest"]:
			_sfx("splat", -12.0, 1.6)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt * 4.0
	queue_redraw()


func gib(from: Vector2, kind: String, vel: Vector2) -> void:
	if not State.gore and kind != "tooth":
		return
	gibs.append({"pos": from, "vel": vel, "kind": kind, "rot": 0.0, "rest": false})


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	draw_rect(Rect2(-10, -10, 660, 380), Color(0.02, 0.03, 0.035))
	if prop_draw.is_valid():
		prop_draw.call()
	for a: Actor in actors.values():
		_draw_actor(a)
	for g in gibs:
		var p: Vector2 = g["pos"]
		match g["kind"]:
			"tooth":
				draw_rect(Rect2(p - Vector2(1, 2), Vector2(2, 2)), Color(0.95, 0.78, 0.3))
			"hand":
				draw_rect(Rect2(p - Vector2(3, 2), Vector2(6, 3)), Color(0.75, 0.66, 0.6))
				for f in 4:
					draw_rect(Rect2(p + Vector2(-3 + f * 1.6, 1), Vector2(1, 2)), Color(0.75, 0.66, 0.6))
				draw_rect(Rect2(p + Vector2(-4, -1), Vector2(2, 2)), Color(0.6, 0.0, 0.03))
			"eye":
				draw_circle(p, 2.0, Color(0.92, 0.9, 0.85))
				draw_rect(Rect2(p + Vector2(0, -1), Vector2(1, 1)), Color(0.15, 0.25, 0.4))
				draw_line(p, p + Vector2(-2, 3), Color(0.6, 0.1, 0.1), 1.0)
	# Névoa nas bordas e faixas que passam.
	for i in 6:
		var y := fmod(i * 61.0 + t * (8.0 + i * 3.0), 420.0) - 40.0
		draw_rect(Rect2(-10, y, 660, 18 + i * 4), Color(0.5, 0.7, 0.7, 0.025))
	for i in 10:
		var g2 := float(i)
		var c := Color(0.0, 0.01, 0.015, 0.09)
		draw_rect(Rect2(-10, -10, 26 + g2 * 9, 380), c)
		draw_rect(Rect2(624 - g2 * 9, -10, 26 + g2 * 9, 380), c)
		draw_rect(Rect2(-10, -10, 660, 14 + g2 * 5), c)
		draw_rect(Rect2(-10, 336 - g2 * 5, 660, 34 + g2 * 5), c)
	if flash > 0.0:
		draw_rect(Rect2(-10, -10, 660, 380), Color(0.8, 0.95, 1.0, flash * 0.5))


func _draw_actor(a: Actor) -> void:
	var k := _skeleton(a)
	var host := a.kind == "host"
	var body := Color(0.03, 0.025, 0.03) if host else Color(GHOST, a.alpha)
	var dark := Color(0.0, 0.0, 0.0) if host else Color(GHOST.darkened(0.35), a.alpha)
	var w := S
	if not host:
		# Halo: o contorno pálido que tremula.
		var halo := Color(GHOST, a.alpha * 0.12 * (0.8 + 0.2 * sin(t * 5.0)))
		draw_circle(k["head"], 9.0 * w, halo)
		draw_line(k["hip"], k["neck"], halo, 14.0 * w)
	# Pernas (vestido para as mulheres)
	if a.kind == "woman":
		var hem_f: Vector2 = (k["knee_f"] as Vector2).lerp(k["foot_f"], 0.8)
		var hem_b: Vector2 = (k["knee_b"] as Vector2).lerp(k["foot_b"], 0.8)
		var side := Vector2(6 * w, 0)
		_quad(k["hip"] - side * 0.6, k["hip"] + side * 0.6, hem_f + side, hem_b - side, dark)
	else:
		draw_line(k["hip"], k["knee_b"], dark, 3.0 * w)
		draw_line(k["knee_b"], k["foot_b"], dark, 3.0 * w)
		draw_line(k["hip"], k["knee_f"], body, 3.0 * w)
		draw_line(k["knee_f"], k["foot_f"], body, 3.0 * w)
	draw_line(k["shoulder"], k["elbow_b"], dark, 2.5 * w)
	draw_line(k["elbow_b"], k["hand_b"], dark, 2.0 * w)
	# Tronco
	var perp: Vector2 = ((k["shoulder"] as Vector2) - (k["hip"] as Vector2)).normalized().orthogonal()
	if host:
		# Contorno avermelhado: a silhueta se descola do escuro.
		var rim := Color(0.45, 0.12, 0.1, 0.55)
		draw_circle(k["head"], 6.2 * w, rim)
		draw_line(k["hip"], k["shoulder"], rim, 11.0 * w)
		draw_line(k["hip"], k["foot_f"], rim, 5.0 * w)
		draw_line(k["hip"], k["foot_b"], rim, 5.0 * w)
	_quad(k["hip"] + perp * 3.5 * w, k["hip"] - perp * 3.5 * w, k["shoulder"] - perp * 4.5 * w, k["shoulder"] + perp * 4.5 * w, body)
	if host:
		# Avental de açougueiro, manchado.
		var low: Vector2 = (k["foot_f"] - k["hip"]) * 0.55
		var chest: Vector2 = (k["shoulder"] as Vector2).lerp(k["hip"], 0.3)
		_quad(k["hip"] + perp * 3.0 * w + low, k["hip"] - perp * 3.0 * w + low, chest - perp * 3.0 * w, chest + perp * 3.0 * w, Color(0.25, 0.22, 0.2))
		if State.gore:
			draw_rect(Rect2((k["hip"] as Vector2) - Vector2(2, 0), Vector2(3, 6)), Color(0.45, 0.0, 0.02))
	if a.kind == "priest":
		draw_rect(Rect2((k["neck"] as Vector2) - Vector2(1.5, 1), Vector2(3, 2)), Color(0.95, 0.95, 0.95, a.alpha))
	# Cabeça
	draw_circle(k["head"], 5.0 * w, body)
	if a.kind == "woman":
		var back := -(k["fwd"] as Vector2)
		draw_line(k["head"] + back * 3.0, k["head"] + back * 4.0 + Vector2(0, 11), dark, 3.0 * w)
	if host:
		# Óculos que brilham.
		var gl: Vector2 = k["eyes"]
		var glint := 0.6 + 0.4 * sin(t * 3.0)
		draw_rect(Rect2(gl - Vector2(1, 1), Vector2(3, 2)), Color(1.0, 0.25, 0.15, glint))
	elif a.eyes:
		draw_rect(Rect2(k["eyes"] - Vector2(0.5, 0.5), Vector2(2, 1)), Color(0.05, 0.1, 0.1, a.alpha))
	else:
		draw_rect(Rect2(k["eyes"] - Vector2(1, 1), Vector2(3, 2)), Color(0.5, 0.0, 0.02))
	# Braço da frente, mão e ferramenta
	draw_line(k["shoulder"], k["elbow_f"], body, 2.5 * w)
	draw_line(k["elbow_f"], k["hand_f"], body, 2.0 * w)
	if a.hands:
		draw_rect(Rect2((k["hand_f"] as Vector2) - Vector2(1.5, 1.5), Vector2(3, 3)), body.lightened(0.1))
		draw_rect(Rect2((k["hand_b"] as Vector2) - Vector2(1.5, 1.5), Vector2(3, 3)), dark)
	elif State.gore:
		draw_rect(Rect2((k["hand_f"] as Vector2) - Vector2(1, 1), Vector2(2, 2)), Color(0.6, 0.0, 0.03))
		draw_rect(Rect2((k["hand_b"] as Vector2) - Vector2(1, 1), Vector2(2, 2)), Color(0.6, 0.0, 0.03))
	var hand: Vector2 = k["hand_f"]
	var dir: Vector2 = (hand - (k["elbow_f"] as Vector2)).normalized()
	match a.tool:
		"alicate":
			draw_line(hand, hand + dir * 8.0, Color(0.6, 0.62, 0.66), 2.0)
		"serra":
			draw_line(hand, hand + dir * 18.0, Color(0.7, 0.72, 0.75), 3.0)
			for i in 6:
				var tp := hand + dir * (4.0 + i * 2.4)
				draw_rect(Rect2(tp + dir.orthogonal() * 2.0, Vector2(1, 1)), Color(0.8, 0.8, 0.85))
		"colher":
			draw_line(hand, hand + dir * 7.0, Color(0.7, 0.7, 0.72), 1.0)
			draw_circle(hand + dir * 8.0, 1.5, Color(0.7, 0.7, 0.72))


## Quadrilátero desenhado como primitiva (não falha quando degenera).
func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c, d]), PackedColorArray([col, col, col, col]), PackedVector2Array())


# ---------------------------------------------------------------- cenários

func _wall(top: Color, bottom: Color, ink: Color) -> void:
	for i in 20:
		draw_rect(Rect2(0, i * 14, 640, 15), top.lerp(bottom, i / 19.0))
	for x in range(0, 640, 24):
		draw_line(Vector2(x, 0), Vector2(x, FLOOR - 40), ink, 1.0)
	draw_rect(Rect2(0, FLOOR - 40, 640, 40), bottom.darkened(0.4))
	draw_line(Vector2(0, FLOOR - 40), Vector2(640, FLOOR - 40), bottom.lightened(0.15), 2.0)
	draw_rect(Rect2(0, FLOOR, 640, 100), Color(0.06, 0.04, 0.03))
	for i in 6:
		draw_line(Vector2(0, FLOOR + i * i * 3), Vector2(640, FLOOR + i * i * 3), Color(0.1, 0.07, 0.05), 1.0)


func _window(x: float, y: float) -> void:
	draw_rect(Rect2(x - 26, y - 46, 52, 92), Color(0.12, 0.08, 0.06))
	for i in 8:
		draw_rect(Rect2(x - 22, y - 42 + i * 10.5, 44, 11), Color(0.08, 0.1, 0.2).lerp(Color(0.25, 0.3, 0.45), i / 7.0))
	draw_circle(Vector2(x + 8, y - 20), 6, Color(0.85, 0.88, 0.8))
	draw_line(Vector2(x, y - 42), Vector2(x, y + 42), Color(0.12, 0.08, 0.06), 2.0)
	draw_line(Vector2(x - 22, y), Vector2(x + 22, y), Color(0.12, 0.08, 0.06), 2.0)


func _candles(x: float, y: float) -> void:
	draw_rect(Rect2(x - 1, y - 14, 2, 14), Color(0.6, 0.45, 0.2))
	draw_rect(Rect2(x - 8, y - 15, 16, 2), Color(0.6, 0.45, 0.2))
	for dx in [-7, 0, 7]:
		draw_rect(Rect2(x + dx - 1, y - 22, 2, 7), Color(0.86, 0.8, 0.66))
		var fl := 1.0 + 0.3 * sin(t * 12.0 + dx) * sin(t * 5.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x + dx, y - 22 - 6 * fl), Vector2(x + dx + 2, y - 24), Vector2(x + dx, y - 22), Vector2(x + dx - 2, y - 24)]), Color(1, 0.65, 0.25))
		draw_circle(Vector2(x + dx, y - 25), 10, Color(1, 0.6, 0.25, 0.04))


func _props_ceia() -> void:
	_wall(Color(0.18, 0.06, 0.07), Color(0.1, 0.04, 0.04), Color(0.14, 0.05, 0.05))
	_window(130, 130)
	_window(520, 130)
	# Mesa
	draw_rect(Rect2(160, 236, 320, 6), Color(0.75, 0.72, 0.64))
	draw_rect(Rect2(160, 242, 320, 14), Color(0.62, 0.58, 0.52))
	for x in [176, 464]:
		draw_rect(Rect2(x, 256, 6, 20), Color(0.18, 0.09, 0.05))
	for x in [230, 300, 380, 440]:
		draw_rect(Rect2(x - 9, 233, 18, 3), Color(0.86, 0.84, 0.8))
		draw_rect(Rect2(x - 5, 232, 10, 2), Color(0.32, 0.14, 0.06))
	_candles(260, 234)
	_candles(410, 234)
	# Cadeiras
	for x in [208, 352]:
		draw_rect(Rect2(x, 220, 4, 56), Color(0.2, 0.1, 0.06))
		draw_rect(Rect2(x, 248, 22, 4), Color(0.2, 0.1, 0.06))


func _props_atlas() -> void:
	_wall(Color(0.08, 0.1, 0.13), Color(0.05, 0.06, 0.08), Color(0.06, 0.08, 0.1))
	# Estantes ao fundo
	for bx in [20, 470]:
		draw_rect(Rect2(bx, 60, 150, 176), Color(0.14, 0.08, 0.05))
		for s in 6:
			for b in 18:
				var hgt := 14 + (b * 7 + s * 3) % 10
				draw_rect(Rect2(bx + 6 + b * 8, 62 + s * 29 + (26 - hgt), 6, hgt), [Color(0.3, 0.1, 0.08), Color(0.14, 0.18, 0.1), Color(0.25, 0.2, 0.12)][(b + s) % 3])
	_window(330, 120)
	# Piano de estudo
	draw_rect(Rect2(300, 190, 110, 86), Color(0.06, 0.04, 0.04))
	draw_rect(Rect2(300, 186, 110, 6), Color(0.12, 0.08, 0.07))
	draw_rect(Rect2(288, 230, 122, 6), Color(0.82, 0.78, 0.68))
	for i in 20:
		if i % 7 != 2 and i % 7 != 6:
			draw_rect(Rect2(290 + i * 6, 230, 3, 3), Color(0.05, 0.04, 0.04))
	draw_rect(Rect2(330, 196, 40, 22), Color(0.82, 0.78, 0.66))
	for i in 5:
		draw_line(Vector2(334, 200 + i * 4), Vector2(366, 200 + i * 4), Color(0.3, 0.25, 0.2), 1.0)
	# Banco
	draw_rect(Rect2(250, 246, 40, 5), Color(0.2, 0.1, 0.06))
	draw_rect(Rect2(254, 251, 3, 25), Color(0.2, 0.1, 0.06))
	draw_rect(Rect2(283, 251, 3, 25), Color(0.2, 0.1, 0.06))
	_candles(392, 186)


func _props_olhos() -> void:
	_wall(Color(0.14, 0.12, 0.1), Color(0.08, 0.06, 0.05), Color(0.1, 0.08, 0.07))
	# Prateleiras com potes à esquerda
	for s in 4:
		var y := 120 + s * 40
		draw_rect(Rect2(80, y, 170, 4), Color(0.3, 0.18, 0.1))
		for j in 7:
			var jx := 88 + j * 23
			draw_rect(Rect2(jx, y - 24, 16, 24), Color(0.45, 0.5, 0.28, 0.7))
			draw_rect(Rect2(jx + 1, y - 26, 14, 3), Color(0.45, 0.36, 0.22))
			draw_circle(Vector2(jx + 8, y - 11), 3.0, Color(0.9, 0.86, 0.8))
			draw_rect(Rect2(jx + 8, y - 12, 1, 1), Color(0.15, 0.25, 0.4))
	# Fogão à direita
	draw_rect(Rect2(440, 200, 120, 76), Color(0.08, 0.07, 0.07))
	draw_rect(Rect2(460, 232, 60, 26), Color(0.02, 0.0, 0.0))
	for i in 8:
		var hh := 8 + 10 * absf(sin(t * (4.0 + i) + i))
		draw_colored_polygon(PackedVector2Array([Vector2(464 + i * 7, 258), Vector2(467 + i * 7, 258 - hh), Vector2(470 + i * 7, 258)]), Color(1, 0.45, 0.12))
	draw_circle(Vector2(490, 245), 60, Color(1, 0.45, 0.15, 0.05))
	draw_rect(Rect2(490, 80, 20, 120), Color(0.1, 0.09, 0.09))
	# Ganchos
	for x in [300, 340, 380]:
		draw_line(Vector2(x, 40), Vector2(x, 90 + sin(t + x) * 2), Color(0.3, 0.3, 0.3), 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 92), Vector2(x + 6, 92), Vector2(x + 8, 120), Vector2(x, 140), Vector2(x - 8, 120)]), Color(0.42, 0.12, 0.1))


# ---------------------------------------------------------------- roteiros

func scene_ceia() -> void:
	prop_draw = _props_ceia
	surfaces = [Rect2(160, 236, 320, 6)]
	blood.walls = [Rect2(160, 236, 320, 20)]
	var leo := _actor("leo", {"x": 300.0, "facing": 1.0, "kind": "woman", "sit": 1.0, "arm_f": 1.2, "alpha": 0.8})
	var cel := _actor("cel", {"x": 224.0, "facing": 1.0, "kind": "woman", "sit": 1.0, "arm_f": 0.9, "alpha": 0.35})
	var hel := _actor("hel", {"x": 372.0, "facing": -1.0, "kind": "man", "sit": 1.0, "arm_f": 0.9, "alpha": 0.35})
	var host := _actor("host", {"x": 520.0, "facing": -1.0, "kind": "host", "arm_f": 0.2})
	await _w(1.4)
	_say("LEOCÁDIA", "Ezequiel, esta sopa tem gosto de ferrugem.")
	await _w(3.0)
	_say("MORVANT", "É o ferro, minha cara. Faz bem ao sangue.")
	await _w(3.0)
	_say("LEOCÁDIA", "Você me deve onze contos de réis. E eu vou cobrar até o último...")
	await _w(3.2)
	_sfx("cough", -2.0)
	_tw(leo, "lean", 0.45, 0.2)
	leo.tremble = 1.0
	await _w(0.35)
	blood.spray(part("leo", "mouth"), Vector2(1, -0.2), 16, 120.0, 0.5)
	await _w(0.5)
	_sfx("cough", 0.0, 0.9)
	blood.spray(part("leo", "mouth"), Vector2(1, 0.1), 40, 170.0, 0.5, 2.0)
	_shake(0.4)
	await _w(0.7)
	_tw(cel, "sit", 0.0, 0.4)
	_tw(hel, "sit", 0.0, 0.4)
	_tw(leo, "lean", 1.45, 0.18)
	await _w(0.18)
	_sfx("slam", -4.0, 1.4)
	_sfx("splat", 0.0)
	_shake(1.0)
	flash = 0.4
	blood.burst(part("leo", "mouth"), 40, 140.0)
	blood.pool(Vector2(part("leo", "mouth").x + 6, 236.0), 18.0)
	leo.tremble = 0.0
	await _w(1.2)
	_say("MORVANT", "Não se levantem. A sobremesa ainda não foi servida.")
	host.tool = "alicate"
	_walk_to(host, 336.0, 2.2)
	await _w(2.4)
	host.facing = -1.0
	for i in 3:
		_tw(host, "arm_f", 1.4, 0.15)
		await _w(0.25)
		_sfx("crunch", -2.0, randf_range(0.9, 1.2))
		_shake(0.5)
		var m := part("leo", "mouth")
		blood.spray(m, Vector2(randf_range(-0.5, 0.5), -1), 22, 150.0, 0.7)
		for k in 2:
			gib(m, "tooth", Vector2(randf_range(-40, 40), randf_range(-120, -60)))
		_tw(host, "arm_f", 0.7, 0.2)
		await _w(0.6)
	_say("MORVANT", "Ouro não se enterra. É falta de educação com os vivos.")
	await _w(3.4)
	# A alma sobe do corpo.
	var soul := _actor("soul", {"x": 300.0, "facing": 1.0, "kind": "woman", "alpha": 0.0})
	_tw(soul, "alpha", 0.7, 1.5)
	_tw(soul, "rise", 40.0, 2.5)
	_sfx("whisper", -6.0, 0.8)
	await _w(2.0)
	if host_version:
		_say("MORVANT", "Ela não tem nada a lhe dizer, médium. Eu falo por ela.")
	else:
		_say("LEOCÁDIA", "Obrigada, menina. Procure no meu prato. A chave estava na sopa. Sempre esteve.")
	await _w(4.2)
	_tw(soul, "alpha", 0.0, 1.0)
	await _w(1.2)
	_end()


func scene_atlas() -> void:
	prop_draw = _props_atlas
	surfaces = [Rect2(288, 230, 122, 6), Rect2(300, 186, 110, 6)]
	blood.walls = [Rect2(300, 186, 110, 90)]
	var tob := _actor("tob", {"x": 272.0, "y": FLOOR, "facing": 1.0, "kind": "man", "sit": 1.0, "arm_f": 1.5, "arm_b": 1.4, "bend": 0.4, "alpha": 0.8})
	var host := _actor("host", {"x": 40.0, "facing": 1.0, "kind": "host"})
	_playing = true
	var play := func():
		while _playing and not skipping and is_instance_valid(self):
			_sfx("tick", -14.0, randf_range(1.5, 3.0))
			tob.arm_f = 1.5 + randf_range(-0.12, 0.12)
			tob.arm_b = 1.4 + randf_range(-0.12, 0.12)
			await get_tree().create_timer(0.22).timeout
	play.call()
	await _w(1.6)
	_say("TOBIAS", "Ouça esta passagem, doutor. Ainda não está pronta, mas...")
	_walk_to(host, 236.0, 3.0)
	await _w(3.4)
	_say("MORVANT", "As mãos estão prontas. É o que importa.")
	host.tool = "serra"
	await _w(2.6)
	_playing = false
	_tw(tob, "lean", 0.5, 0.2)
	_tw(tob, "arm_f", 1.7, 0.2)
	_tw(tob, "arm_b", 1.7, 0.2)
	_sfx("slam", -8.0, 1.6)
	_say("TOBIAS", "Doutor? Solte! SOLTE!")
	_tw(host, "arm_f", 1.6, 0.3)
	await _w(0.6)
	_sfx("saw", 0.0)
	_sfx("scream", -2.0, 1.1)
	tob.tremble = 1.0
	for i in 10:
		var wr := part("tob", "hand_f")
		blood.spray(wr, Vector2(randf_range(-1, 1), -0.6), 10, 150.0, 0.8)
		_shake(0.3)
		_tw(host, "arm_f", 1.3 + (i % 2) * 0.5, 0.12)
		await _w(0.22)
	tob.hands = false
	var w1 := part("tob", "hand_f")
	var w2 := part("tob", "hand_b")
	gib(w1, "hand", Vector2(30, -60))
	gib(w2, "hand", Vector2(50, -40))
	_sfx("splat", 0.0)
	blood.spray(w1, Vector2(1, -0.4), 50, 200.0, 0.6, 2.0)
	blood.spray(w2, Vector2(1, -0.2), 40, 180.0, 0.6, 2.0)
	_shake(1.0)
	flash = 0.3
	await _w(1.0)
	tob.tremble = 0.0
	_tw(tob, "sit", 0.0, 0.5)
	_tw(tob, "fall", -1.0, 0.9)
	await _w(1.0)
	_sfx("slam", -6.0, 0.9)
	blood.pool(Vector2(tob.x - 30, FLOOR), 26.0)
	await _w(1.0)
	_say("MORVANT", "Benedita! Traga os potes. Os grandes.")
	await _w(3.0)
	var soul := _actor("soul", {"x": 260.0, "facing": 1.0, "kind": "man", "alpha": 0.0, "hands": false})
	_tw(soul, "alpha", 0.7, 1.5)
	_tw(soul, "rise", 36.0, 2.5)
	_sfx("whisper", -6.0, 1.1)
	await _w(2.0)
	if host_version:
		_say("MORVANT", "O pianista agradece. Ele diria, se ainda tivesse com que gesticular.")
	else:
		_say("TOBIAS", "As minhas mãos foram para a cozinha. A porta da copa... deixe que eu abro.")
	await _w(4.4)
	_tw(soul, "alpha", 0.0, 1.0)
	await _w(1.2)
	_end()


func scene_olhos() -> void:
	prop_draw = _props_olhos
	surfaces = []
	blood.walls = [Rect2(80, 90, 170, 130)]
	var ben := _actor("ben", {"x": 270.0, "facing": -1.0, "kind": "woman", "arm_f": 1.1, "alpha": 0.8})
	var host := _actor("host", {"x": 700.0, "facing": -1.0, "kind": "host"})
	await _w(1.6)
	_say("BENEDITA", "Olhos... são olhos. Virgem Santa, são de gente.")
	await _w(3.2)
	_walk_to(host, 360.0, 2.4)
	await _w(2.6)
	_sfx("sting", -4.0)
	ben.facing = 1.0
	_tw(ben, "arm_f", 0.4, 0.2)
	_say("BENEDITA", "Doutor! Eu não vi nada! Juro pela minha mãe que não vi nada!")
	await _w(3.4)
	_say("MORVANT", "Eu sei, Benedita. E vai continuar não vendo.")
	host.tool = "colher"
	await _w(2.6)
	_walk_to(host, 292.0, 0.4)
	await _w(0.4)
	_sfx("scream", 0.0, 1.25)
	_tw(host, "arm_f", 1.9, 0.15)
	_tw(ben, "lean", -0.4, 0.2)
	ben.tremble = 1.0
	_shake(0.8)
	for i in 2:
		await _w(0.5)
		_sfx("squelch", 0.0, 0.8 + i * 0.2)
		_sfx("pop", -2.0)
		var e := part("ben", "eyes")
		blood.spray(e, Vector2(1, -0.3), 40, 150.0, 0.8, 1.8)
		gib(e, "eye", Vector2(60 + i * 20, -110))
		_shake(0.9)
	ben.eyes = false
	await _w(0.6)
	_tw(host, "arm_f", 0.3, 0.3)
	for i in 6:
		blood.drip(part("ben", "eyes") + Vector2(randf_range(-2, 2), 0), 40.0)
	await _w(0.6)
	_walk_to(ben, 230.0, 1.2)
	await _w(1.2)
	ben.tremble = 0.0
	_tw(ben, "fall", -1.0, 0.7)
	await _w(0.8)
	_sfx("slam", -6.0, 1.0)
	blood.pool(Vector2(230 - 38, FLOOR), 22.0)
	await _w(1.0)
	_say("MORVANT", "Pote doze. Etiqueta: ‘Assunção, B. — viu demais’.")
	await _w(3.6)
	var soul := _actor("soul", {"x": 210.0, "facing": 1.0, "kind": "woman", "alpha": 0.0, "eyes": false})
	_tw(soul, "alpha", 0.7, 1.5)
	_tw(soul, "rise", 36.0, 2.5)
	_sfx("whisper", -6.0, 0.9)
	await _w(2.0)
	if host_version:
		_say("MORVANT", "Benedita sempre foi discreta. Hoje mais do que nunca.")
	else:
		_say("BENEDITA", "A tranca da escada de serviço é minha. Pode subir, moça. Mas não olhe para trás.")
	await _w(4.4)
	_tw(soul, "alpha", 0.0, 1.0)
	await _w(1.2)
	_end()
