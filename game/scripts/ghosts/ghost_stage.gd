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
var spectators: Array = []
var show_body := true
var baby_glow := 0.0
var baby_at := Vector2(320, 220)
var ending := ""
var choosing := false
signal _picked(idx: int)


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
	house.subs.clear()
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
	if not State.gore and kind != "tooth" and kind != "glass":
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
			"skin":
				draw_rect(Rect2(p - Vector2(7, 3), Vector2(14, 6)), Color(0.8, 0.66, 0.58))
				draw_line(p + Vector2(-5, 0), p + Vector2(5, -1), Color(0.12, 0.16, 0.3), 1.0)
				draw_rect(Rect2(p + Vector2(-7, 2), Vector2(14, 1)), Color(0.55, 0.0, 0.03))
			"glass":
				draw_line(p, p + Vector2(3, -2).rotated(g["rot"]), Color(0.3, 0.55, 0.3, 0.8), 1.0)
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
	var alive := a.kind == "dalia"
	var body := Color(0.03, 0.025, 0.03) if host else Color(GHOST, a.alpha)
	var dark := Color(0.0, 0.0, 0.0) if host else Color(GHOST.darkened(0.35), a.alpha)
	if alive:
		# Dália, viva: a única figura com cor de gente. Casaco cor de vinho.
		body = Color(0.55, 0.22, 0.2, a.alpha)
		dark = Color(0.3, 0.12, 0.12, a.alpha)
	var w := S
	if not host and not alive:
		# Halo: o contorno pálido que tremula.
		var halo := Color(GHOST, a.alpha * 0.12 * (0.8 + 0.2 * sin(t * 5.0)))
		draw_circle(k["head"], 9.0 * w, halo)
		draw_line(k["hip"], k["neck"], halo, 14.0 * w)
	# Pernas (vestido para as mulheres)
	if a.kind == "woman" or alive:
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
	draw_circle(k["head"], 5.0 * w, body if not alive else Color(0.86, 0.72, 0.62, a.alpha))
	if a.kind == "woman" or alive:
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
		"bisturi":
			draw_line(hand, hand + dir * 6.0, Color(0.85, 0.87, 0.9), 1.0)
			draw_rect(Rect2(hand + dir * 6.0 - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 1))
		"trepano":
			# Arco de pua: manivela em "U" e a broca na ponta.
			var side := dir.orthogonal()
			draw_line(hand, hand + dir * 5.0, Color(0.5, 0.35, 0.2), 2.0)
			draw_line(hand + dir * 5.0, hand + dir * 5.0 + side * 6.0, Color(0.6, 0.6, 0.62), 1.0)
			draw_line(hand + dir * 5.0 + side * 6.0, hand + dir * 12.0 + side * 6.0, Color(0.6, 0.6, 0.62), 1.0)
			draw_line(hand + dir * 12.0 + side * 6.0, hand + dir * 12.0, Color(0.6, 0.6, 0.62), 1.0)
			draw_line(hand + dir * 12.0, hand + dir * 18.0, Color(0.8, 0.8, 0.82), 1.0)
		"colher":
			draw_line(hand, hand + dir * 7.0, Color(0.7, 0.7, 0.72), 1.0)
			draw_circle(hand + dir * 8.0, 1.5, Color(0.7, 0.7, 0.72))
		"garrafa":
			draw_line(hand, hand + dir * 5.0, Color(0.12, 0.25, 0.12), 2.0)
			draw_line(hand + dir * 5.0, hand + dir * 14.0, Color(0.1, 0.22, 0.1), 4.0)
		"embrulho":
			# Uma trouxinha de linho branco, pequena demais.
			draw_circle(hand + dir * 2.0, 4.0, Color(0.88, 0.86, 0.8))
			draw_rect(Rect2(hand + dir * 2.0 + Vector2(-5, -2), Vector2(9, 5)), Color(0.88, 0.86, 0.8))
		"agulha":
			draw_line(hand, hand + dir * 6.0, Color(0.85, 0.87, 0.9), 1.0)
			draw_line(hand + dir * 6.0, hand + dir * 6.0 + Vector2(0, 10), Color(0.05, 0.05, 0.05), 1.0)
		"lamparina":
			draw_line(hand, hand + Vector2(0, 6), Color(0.3, 0.28, 0.26), 1.0)
			draw_rect(Rect2(hand + Vector2(-2, 6), Vector2(4, 5)), Color(1.0, 0.75, 0.35))
			draw_circle(hand + Vector2(0, 8), 14.0, Color(1.0, 0.7, 0.3, 0.08))
		"coracao":
			# O coração ainda bate na mão dele.
			var beat := maxf(0.0, sin(t * 7.0)) ** 6.0
			draw_circle(hand + dir * 3.0, 3.5 + beat * 1.2, Color(0.6, 0.02, 0.06))
			draw_circle(hand + dir * 3.0 + Vector2(-1, -1), 1.2, Color(0.9, 0.35, 0.35))
			if State.gore and beat > 0.5:
				draw_rect(Rect2(hand + dir * 3.0 + Vector2(0, 4), Vector2(1, 3)), Color(0.6, 0.0, 0.04))


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


func _props_partitura() -> void:
	_wall(Color(0.14, 0.07, 0.14), Color(0.08, 0.04, 0.08), Color(0.11, 0.05, 0.11))
	# Palco e cortinas
	draw_rect(Rect2(150, 244, 360, 32), Color(0.2, 0.1, 0.06))
	draw_rect(Rect2(150, 240, 360, 5), Color(0.32, 0.17, 0.1))
	for side in [0, 1]:
		var x0 := 120.0 if side == 0 else 470.0
		for k in 6:
			draw_rect(Rect2(x0 + k * 8, 30, 8, 214), Color(0.45, 0.05, 0.08).darkened(0.15 * (k % 2)))
	draw_rect(Rect2(120, 24, 400, 22), Color(0.5, 0.06, 0.09))
	# Foco de luz sobre a cantora
	draw_colored_polygon(PackedVector2Array([Vector2(310, 30), Vector2(330, 30), Vector2(380, 244), Vector2(260, 244)]), Color(1.0, 0.9, 0.7, 0.06))
	# Piano de cauda à direita do palco
	draw_rect(Rect2(400, 196, 70, 14), Color(0.04, 0.03, 0.03))
	draw_colored_polygon(PackedVector2Array([Vector2(400, 196), Vector2(470, 196), Vector2(440, 160)]), Color(0.06, 0.05, 0.05))
	for x in [406, 462]:
		draw_rect(Rect2(x, 210, 3, 30), Color(0.04, 0.03, 0.03))
	_candles(450, 196)
	# Primeira fila da plateia
	for x in [60, 100, 560, 600]:
		draw_rect(Rect2(x, 236, 4, 40), Color(0.22, 0.09, 0.08))
		draw_rect(Rect2(x - 12, 254, 16, 4), Color(0.22, 0.09, 0.08))


func _props_pele() -> void:
	_wall(Color(0.13, 0.11, 0.16), Color(0.07, 0.06, 0.09), Color(0.1, 0.08, 0.12))
	_window(520, 120)
	# Mapa e cama de campanha
	draw_rect(Rect2(90, 90, 80, 56), Color(0.55, 0.48, 0.34))
	draw_line(Vector2(100, 120), Vector2(160, 104), Color(0.5, 0.1, 0.08), 1.0)
	draw_rect(Rect2(40, 246, 110, 14), Color(0.3, 0.32, 0.24))
	draw_rect(Rect2(40, 238, 30, 8), Color(0.7, 0.68, 0.62))
	# Mesa de cartas
	draw_rect(Rect2(270, 230, 110, 6), Color(0.16, 0.34, 0.2))
	draw_rect(Rect2(270, 236, 110, 4), Color(0.18, 0.1, 0.06))
	for x in [278, 370]:
		draw_rect(Rect2(x, 240, 4, 36), Color(0.18, 0.1, 0.06))
	for i in 5:
		draw_rect(Rect2(290 + i * 14, 227, 8, 3), Color(0.88, 0.86, 0.8))
	draw_rect(Rect2(316, 224, 4, 6), Color(0.3, 0.12, 0.08))
	_candles(360, 230)
	# Cadeiras
	for x in [240, 404]:
		draw_rect(Rect2(x, 220, 4, 56), Color(0.2, 0.1, 0.06))
		draw_rect(Rect2(x - 6 if x > 300 else x, 248, 22, 4), Color(0.2, 0.1, 0.06))


func _props_movel() -> void:
	_wall(Color(0.22, 0.2, 0.24), Color(0.12, 0.1, 0.13), Color(0.17, 0.15, 0.19))
	_window(500, 120)
	# Berço vazio, com o móbile parado
	draw_rect(Rect2(280, 224, 90, 6), Color(0.42, 0.34, 0.26))
	for i in 10:
		draw_rect(Rect2(282 + i * 9, 230, 2, 28), Color(0.42, 0.34, 0.26))
	draw_rect(Rect2(280, 256, 90, 6), Color(0.42, 0.34, 0.26))
	for x in [280, 366]:
		draw_rect(Rect2(x, 220, 4, 56), Color(0.36, 0.28, 0.2))
	draw_line(Vector2(366, 220), Vector2(366, 170), Color(0.42, 0.34, 0.26), 1.0)
	draw_line(Vector2(366, 170), Vector2(326, 170), Color(0.42, 0.34, 0.26), 1.0)
	for k in 4:
		var mx := 312.0 + k * 9.0 + sin(t * 0.5 + k) * 2.0
		draw_line(Vector2(mx, 172), Vector2(mx, 182 + k % 2 * 4), Color(0.7, 0.68, 0.6), 1.0)
		draw_circle(Vector2(mx, 184 + k % 2 * 4), 2.0, [Color(0.9, 0.85, 0.5), Color(0.7, 0.75, 0.9), Color(0.9, 0.6, 0.6), Color(0.75, 0.9, 0.7)][k])
	# Caixãozinho branco no chão, fechado.
	draw_rect(Rect2(160, 262, 46, 14), Color(0.62, 0.6, 0.58))
	draw_rect(Rect2(160, 262, 46, 3), Color(0.7, 0.68, 0.66))
	# Cadeira de balanço de Celeste
	var rock := sin(t * 1.4) * 2.0
	draw_line(Vector2(226, 276 + rock * 0.3), Vector2(266, 276 - rock * 0.3), Color(0.3, 0.22, 0.16), 2.0)
	draw_rect(Rect2(232, 247, 26, 4), Color(0.3, 0.22, 0.16))
	draw_line(Vector2(234, 251), Vector2(234, 275), Color(0.3, 0.22, 0.16), 2.0)
	draw_line(Vector2(256, 251), Vector2(256, 275), Color(0.3, 0.22, 0.16), 2.0)
	draw_line(Vector2(233, 249), Vector2(228 + rock, 206), Color(0.3, 0.22, 0.16), 2.0)
	_candles(184, 262)


func _props_sussurros() -> void:
	_wall(Color(0.2, 0.17, 0.24), Color(0.11, 0.09, 0.13), Color(0.15, 0.12, 0.18))
	for i in 14:
		draw_string(ThemeDB.fallback_font, Vector2(40 + fmod(i * 97.0, 560.0), 50 + fmod(i * 53.0, 170.0)), ["ELES FALAM", "PAI NÃO", "ouço"][i % 3], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.08, 0.05, 0.08))
	_window(500, 110)
	# Cama de renda
	draw_rect(Rect2(180, 236, 160, 12), Color(0.82, 0.8, 0.82))
	draw_rect(Rect2(180, 248, 160, 10), Color(0.62, 0.6, 0.62))
	draw_rect(Rect2(180, 210, 8, 66), Color(0.3, 0.2, 0.16))
	draw_rect(Rect2(332, 226, 8, 50), Color(0.3, 0.2, 0.16))
	draw_rect(Rect2(188, 228, 30, 8), Color(0.92, 0.9, 0.92))
	# Bonecas na prateleira
	draw_rect(Rect2(420, 170, 120, 4), Color(0.3, 0.2, 0.16))
	for k in 6:
		var dx := 428.0 + k * 19.0
		draw_rect(Rect2(dx - 4, 158, 8, 12), [Color(0.6, 0.3, 0.35), Color(0.4, 0.4, 0.6)][k % 2])
		draw_circle(Vector2(dx, 154), 4.0, Color(0.85, 0.76, 0.7))
		draw_rect(Rect2(dx - 2, 153, 1, 1), Color(0.05, 0.05, 0.1))
		draw_rect(Rect2(dx + 1, 153, 1, 1), Color(0.05, 0.05, 0.1))
	_candles(400, 276)


func _stone_wall() -> void:
	# Pedra dos porões, em fiadas desencontradas, sem lambri.
	for i in 20:
		draw_rect(Rect2(0, i * 14, 640, 15), Color(0.12, 0.13, 0.17).lerp(Color(0.06, 0.065, 0.09), i / 19.0))
	for row in 12:
		var y := row * 22.0
		draw_line(Vector2(0, y), Vector2(640, y), Color(0.05, 0.05, 0.07), 1.0)
		var off := 0.0 if row % 2 == 0 else 26.0
		for x in range(0, 680, 52):
			draw_line(Vector2(x + off, y), Vector2(x + off, y + 22), Color(0.05, 0.05, 0.07), 1.0)
	draw_rect(Rect2(0, FLOOR, 640, 100), Color(0.05, 0.05, 0.06))
	for i in 6:
		draw_line(Vector2(0, FLOOR + i * i * 3), Vector2(640, FLOOR + i * i * 3), Color(0.08, 0.08, 0.1), 1.0)


func _props_balanca() -> void:
	_stone_wall()
	# Barris deitados à direita, em duas fileiras.
	for row in 2:
		for k in 3:
			var c := Vector2(470 + k * 58 + row * 29, 250 - row * 52)
			draw_circle(c, 26, Color(0.3, 0.17, 0.1))
			draw_arc(c, 21, 0, TAU, 20, Color(0.16, 0.09, 0.05), 2.0)
			draw_line(c + Vector2(-12, -18), c + Vector2(-12, 18), Color(0.2, 0.11, 0.06), 1.0)
			draw_line(c + Vector2(12, -18), c + Vector2(12, 18), Color(0.2, 0.11, 0.06), 1.0)
	# Mesa com garrafas abertas e frascos de láudano.
	draw_rect(Rect2(250, 232, 130, 6), Color(0.3, 0.18, 0.1))
	for x in [258, 370]:
		draw_rect(Rect2(x, 238, 4, 38), Color(0.24, 0.14, 0.08))
	for i in 7:
		draw_rect(Rect2(262 + i * 15, 206, 6, 26), Color(0.08, 0.16, 0.08))
		draw_rect(Rect2(264 + i * 15, 198, 2, 8), Color(0.08, 0.16, 0.08))
	for i in 3:
		draw_rect(Rect2(366 + i * 5, 222, 3, 10), Color(0.5, 0.36, 0.2, 0.8))
	_candles(272, 232)
	# Escada de pedra descendo à esquerda.
	for i in 6:
		draw_rect(Rect2(20 + i * 14, 276 - (6 - i) * 12, 60, 12), Color(0.14, 0.14, 0.17))


func _props_vitral() -> void:
	_stone_wall()
	# Rosácea no alto: acesa, colorida.
	var rc := Vector2(440, 92)
	var cols := [Color(0.78, 0.1, 0.14), Color(0.18, 0.32, 0.86), Color(0.95, 0.7, 0.18), Color(0.2, 0.62, 0.32), Color(0.56, 0.24, 0.72), Color(0.92, 0.9, 0.82)]
	draw_circle(rc, 50, Color(0.1, 0.1, 0.12))
	for i in 12:
		var a0 := TAU * i / 12.0
		var a1 := TAU * (i + 1) / 12.0
		var c: Color = cols[i % 6]
		draw_colored_polygon(PackedVector2Array([rc, rc + Vector2(cos(a0), sin(a0)) * 44.0, rc + Vector2(cos(a1), sin(a1)) * 44.0]), Color(c, 0.55 + 0.1 * sin(t * 2.0 + i)))
		draw_line(rc, rc + Vector2(cos(a0), sin(a0)) * 44.0, Color(0.05, 0.04, 0.04), 1.0)
	# Crucifixo e altar de pedra com toalha.
	draw_rect(Rect2(438, 150, 4, 50), Color(0.18, 0.16, 0.14))
	draw_rect(Rect2(424, 164, 32, 4), Color(0.18, 0.16, 0.14))
	draw_rect(Rect2(380, 236, 130, 40), Color(0.32, 0.31, 0.3))
	draw_rect(Rect2(376, 230, 138, 7), Color(0.78, 0.76, 0.72))
	_candles(392, 230)
	_candles(498, 230)
	# Bancos à esquerda.
	for i in 3:
		var x := 60.0 + i * 70.0
		draw_rect(Rect2(x, 250, 46, 5), Color(0.24, 0.14, 0.08))
		draw_rect(Rect2(x + 40, 226, 5, 50), Color(0.24, 0.14, 0.08))
		draw_rect(Rect2(x + 2, 255, 4, 21), Color(0.2, 0.12, 0.07))


func _props_ossuario() -> void:
	_stone_wall()
	# Nichos com crânios no fundo.
	for row in 4:
		for col in 12:
			var r := Rect2(150 + col * 30, 40 + row * 26, 24, 20)
			draw_rect(r, Color(0.02, 0.02, 0.03))
			if (row * 7 + col * 3) % 5 != 0:
				draw_circle(r.get_center() + Vector2(0, 2), 7, Color(0.5, 0.46, 0.38))
				draw_rect(Rect2(r.get_center() + Vector2(-4, 0), Vector2(3, 3)), Color(0.02, 0.02, 0.02))
				draw_rect(Rect2(r.get_center() + Vector2(1, 0), Vector2(3, 3)), Color(0.02, 0.02, 0.02))
	# Pedestal e o caixãozinho branco.
	draw_rect(Rect2(290, 240, 70, 36), Color(0.22, 0.22, 0.25))
	draw_rect(Rect2(298, 228, 54, 12), Color(0.86, 0.84, 0.8))
	draw_rect(Rect2(298, 226, 54, 3), Color(0.94, 0.92, 0.88))
	_candles(280, 240)
	_candles(372, 240)
	# Sarcófagos dos lados.
	for x in [40, 520]:
		draw_rect(Rect2(x, 236, 90, 40), Color(0.4, 0.39, 0.37))
		draw_rect(Rect2(x - 4, 230, 98, 7), Color(0.55, 0.54, 0.5))


func _props_bau() -> void:
	# Oficina sob o telhado: caibros, prateleiras de vidros, a mesa de costura.
	for i in 20:
		draw_rect(Rect2(0, i * 14, 640, 15), Color(0.12, 0.1, 0.09).lerp(Color(0.05, 0.045, 0.045), i / 19.0))
	for k in 7:
		var x := 40.0 + k * 96.0
		draw_line(Vector2(x, 0), Vector2(x + 60, 236), Color(0.08, 0.05, 0.035), 4.0)
	draw_rect(Rect2(0, FLOOR, 640, 100), Color(0.07, 0.05, 0.035))
	for i in 6:
		draw_line(Vector2(0, FLOOR + i * i * 3), Vector2(640, FLOOR + i * i * 3), Color(0.1, 0.07, 0.05), 1.0)
	# Prateleira de vidros: olhos, mãos, um vidro com a voz (uma névoa que vibra).
	draw_rect(Rect2(60, 120, 200, 4), Color(0.3, 0.2, 0.12))
	for k in 6:
		var jx := 72.0 + k * 32.0
		draw_rect(Rect2(jx, 92, 20, 28), Color(0.45, 0.52, 0.4, 0.7))
		if k == 2:
			draw_circle(Vector2(jx + 10, 106), 6 + sin(t * 9.0), Color(0.75, 0.95, 0.9, 0.5))
		elif k % 2 == 0:
			draw_circle(Vector2(jx + 7, 108), 3, Color(0.9, 0.88, 0.82))
			draw_circle(Vector2(jx + 13, 104), 3, Color(0.9, 0.88, 0.82))
		else:
			draw_rect(Rect2(jx + 5, 100, 10, 14), Color(0.7, 0.6, 0.55))
	# A mesa e o corpinho costurado, coberto até o peito.
	draw_rect(Rect2(300, 230, 180, 7), Color(0.32, 0.22, 0.14))
	for x in [308, 468]:
		draw_rect(Rect2(x, 237, 5, 39), Color(0.26, 0.17, 0.1))
	draw_rect(Rect2(330, 222, 120, 8), Color(0.82, 0.8, 0.74))
	draw_circle(Vector2(330, 222), 7, Color(0.78, 0.7, 0.66))
	# Costuras pretas, e mãos grandes demais para um bebê.
	draw_line(Vector2(336, 219), Vector2(352, 219), Color(0.05, 0.05, 0.05), 1.0)
	for k in 6:
		draw_line(Vector2(338 + k * 3, 217), Vector2(338 + k * 3, 221), Color(0.05, 0.05, 0.05), 1.0)
	draw_rect(Rect2(446, 216, 16, 8), Color(0.75, 0.66, 0.6))
	if State.gore:
		draw_rect(Rect2(380, 230, 30, 2), Color(0.5, 0.0, 0.04))
		for k in 4:
			draw_rect(Rect2(386 + k * 7, 237, 1, 6 + k * 3), Color(0.5, 0.0, 0.04))
	# Lamparina de pé.
	draw_rect(Rect2(486, 214, 6, 16), Color(1.0, 0.75, 0.35))
	draw_circle(Vector2(489, 220), 14, Color(1.0, 0.75, 0.4, 0.12))


func _props_montagem() -> void:
	for i in 20:
		draw_rect(Rect2(0, i * 14, 640, 15), Color(0.07, 0.06, 0.06).lerp(Color(0.02, 0.02, 0.025), i / 19.0))
	# Claraboia e o feixe de luar.
	draw_circle(Vector2(330, -10), 70, Color(0.3, 0.36, 0.5))
	draw_colored_polygon(PackedVector2Array([Vector2(280, 0), Vector2(380, 0), Vector2(430, 240), Vector2(230, 240)]), Color(0.75, 0.85, 1.0, 0.06))
	# Plateia em degraus dos dois lados, com os mortos assistindo.
	for side in [-1.0, 1.0]:
		for row in 4:
			var x0: float = 320.0 + side * (170.0 + row * 40.0)
			var y := 236.0 - row * 34.0
			var w := 200.0
			var rx: float = x0 if side > 0 else x0 - w
			draw_rect(Rect2(rx, y, w, 34 + row * 34), Color(0.18, 0.1, 0.06).darkened(row * 0.1))
			draw_line(Vector2(rx, y), Vector2(rx + w, y), Color(0.4, 0.28, 0.16), 2.0)
	for st in spectators:
		var p0: Vector2 = st
		var c := Color(0.62, 0.95, 0.9, 0.3 + 0.08 * sin(t * 1.4 + p0.x))
		draw_rect(Rect2(p0 + Vector2(-5, -18), Vector2(10, 18)), c)
		draw_circle(p0 + Vector2(0, -23), 5, c)
	# A mesa de pedra no centro e o corpo desfeito.
	draw_rect(Rect2(270, 236, 120, 8), Color(0.55, 0.55, 0.56))
	draw_rect(Rect2(310, 244, 40, 32), Color(0.4, 0.4, 0.42))
	if show_body:
		draw_rect(Rect2(280, 228, 96, 8), Color(0.78, 0.7, 0.64))
		draw_circle(Vector2(282, 228), 8, Color(0.78, 0.7, 0.64))
		if State.gore:
			draw_rect(Rect2(300, 236, 50, 2), Color(0.5, 0.0, 0.04))
	# A bandeja com os instrumentos.
	draw_rect(Rect2(400, 240, 34, 4), Color(0.6, 0.62, 0.66))
	draw_line(Vector2(404, 238), Vector2(420, 236), Color(0.85, 0.87, 0.9), 1.0)
	draw_rect(Rect2(414, 244, 3, 32), Color(0.5, 0.5, 0.52))
	if baby_glow > 0.0:
		draw_circle(baby_at, 6.0 + sin(t * 4.0), Color(1.0, 0.95, 0.8, baby_glow))
		draw_circle(baby_at, 18.0, Color(1.0, 0.95, 0.8, baby_glow * 0.15))


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


func scene_partitura() -> void:
	prop_draw = _props_partitura
	surfaces = [Rect2(150, 240, 360, 5)]
	blood.floor_y = 241.0
	blood.walls = [Rect2(120, 30, 400, 210)]
	var cel := _actor("cel", {"x": 320.0, "y": 241.0, "facing": -1.0, "kind": "woman", "arm_f": 0.5, "arm_b": 0.3, "alpha": 0.85})
	var host := _actor("host", {"x": 40.0, "facing": 1.0, "kind": "host"})
	await _w(1.2)
	_say("CELESTE", "A ária nova, Ezequiel. Escrevi pensando em Ofélia.")
	await _w(3.0)
	# Ela canta: braços se abrem devagar.
	_tw(cel, "arm_f", 1.6, 2.5)
	_tw(cel, "arm_b", 1.3, 2.5)
	for i in 6:
		_sfx("whisper", -10.0, 1.6 + i * 0.1)
		await _w(0.6)
	_walk_to(host, 250.0, 3.0)
	await _w(1.0)
	_say("MORVANT", "Bravo. Bravíssimo. Essa voz não pode morrer com você, minha querida.")
	await _w(2.6)
	_tw(host, "y", 241.0, 0.3)
	host.tool = "bisturi"
	_walk_to(host, 304.0, 0.8)
	await _w(0.9)
	_say("CELESTE", "Ezequiel? O que é isso na sua m...")
	await _w(1.0)
	_tw(host, "arm_f", 2.2, 0.12)
	await _w(0.12)
	_sfx("squelch", 0.0, 1.3)
	_sfx("scream", -6.0, 1.4)
	_shake(0.9)
	flash = 0.35
	var neck := part("cel", "neck")
	blood.spray(neck, Vector2(1, -0.2), 70, 230.0, 0.35, 2.2)
	blood.spray(neck, Vector2(-1, -0.4), 30, 160.0, 0.6, 1.6)
	cel.tremble = 1.0
	_tw(cel, "arm_f", 2.6, 0.3)
	await _w(0.5)
	# Ela tenta cantar e só sai sangue.
	for i in 5:
		_sfx("cough", -8.0, 1.4 + i * 0.05)
		blood.spray(part("cel", "neck"), Vector2(1, 0.1), 16, 130.0, 0.4)
		blood.drip(part("cel", "neck"), 60.0)
		await _w(0.45)
	cel.tremble = 0.0
	_tw(cel, "fall", 1.0, 0.9)
	await _w(1.0)
	_sfx("slam", -6.0, 1.1)
	blood.pool(Vector2(cel.x + 36, 241.0), 28.0)
	await _w(0.8)
	_say("MORVANT", "Shh. A melhor parte de uma ária é o silêncio depois dela.")
	await _w(3.6)
	var soul := _actor("soul", {"x": 340.0, "y": 241.0, "facing": -1.0, "kind": "woman", "alpha": 0.0})
	_tw(soul, "alpha", 0.75, 1.5)
	_tw(soul, "rise", 40.0, 2.5)
	_sfx("whisper", -4.0, 0.7)
	await _w(2.0)
	if host_version:
		_say("MORVANT", "Ela agradeceria, médium. Mas eu fiquei com a voz dela, lembra?")
	else:
		_say("CELESTE", "Ele guardou minha voz num vidro, lá em cima. Ofélia ouviu tudo. Ofélia ouve tudo.")
	await _w(4.6)
	_tw(soul, "alpha", 0.0, 1.0)
	await _w(1.2)
	_end()


func scene_pele() -> void:
	prop_draw = _props_pele
	surfaces = [Rect2(270, 230, 110, 6)]
	blood.walls = [Rect2(80, 60, 480, 170)]
	var hel := _actor("hel", {"x": 252.0, "facing": 1.0, "kind": "man", "sit": 1.0, "arm_f": 1.4, "alpha": 0.8})
	var host := _actor("host", {"x": 396.0, "facing": -1.0, "kind": "host", "sit": 1.0, "arm_f": 1.3})
	await _w(1.2)
	_say("HÉLIO", "Mais uma mão, doutor. Eu recupero tudo nesta.")
	await _w(3.0)
	_sfx("card", -4.0)
	_say("MORVANT", "Você já não tem o que apostar, capitão.")
	await _w(3.0)
	_say("HÉLIO", "Tenho a minha palavra. E esta tatuagem custou mais que a sua casa.")
	await _w(3.4)
	_sfx("card", -4.0)
	await _w(0.6)
	_say("MORVANT", "Trinca de damas. Aceito a tatuagem.")
	await _w(2.4)
	_tw(hel, "lean", -0.3, 0.3)
	_say("HÉLIO", "Foi uma piada, doutor... uma pia...")
	await _w(1.4)
	# O vinho estava batizado: o capitão tomba sobre a mesa.
	hel.tremble = 1.0
	_tw(hel, "lean", 1.3, 0.6)
	await _w(0.7)
	_sfx("slam", -8.0, 1.2)
	hel.tremble = 0.0
	_tw(host, "sit", 0.0, 0.4)
	host.tool = "bisturi"
	await _w(0.6)
	_walk_to(host, 236.0, 1.4)
	await _w(1.6)
	host.facing = 1.0
	for i in 8:
		_tw(host, "arm_f", 1.9 - (i % 2) * 0.6, 0.18)
		var back := part("hel", "shoulder").lerp(part("hel", "hip"), (i % 4) / 4.0)
		blood.spray(back, Vector2(randf_range(-0.6, 0.6), -1), 14, 120.0, 0.7, 1.6)
		_sfx("squelch", -4.0, randf_range(0.7, 1.0))
		if i == 3:
			_sfx("scream", -6.0, 0.8)
		_shake(0.3)
		await _w(0.34)
	# A pele sai inteira, como um mapa.
	_sfx("crunch", -2.0, 0.6)
	gib(part("hel", "shoulder"), "skin", Vector2(-40, -150))
	blood.spray(part("hel", "shoulder"), Vector2(0, -1), 60, 180.0, 0.8, 2.0)
	_shake(1.0)
	flash = 0.3
	await _w(1.2)
	_say("MORVANT", "Dívida de jogo se paga. Até a última pinta.")
	blood.pool(Vector2(300, FLOOR), 26.0)
	await _w(3.4)
	var soul := _actor("soul", {"x": 252.0, "facing": 1.0, "kind": "man", "alpha": 0.0})
	_tw(soul, "alpha", 0.7, 1.5)
	_tw(soul, "rise", 36.0, 2.5)
	_sfx("whisper", -6.0, 0.9)
	await _w(2.0)
	if host_version:
		_say("MORVANT", "O capitão perdeu de novo, médium. Desta vez, para mim e para você.")
	else:
		_say("HÉLIO", "A menina viu tudo pela fechadura. Ofélia. Ela não abre a porta para ninguém. Talvez abra para você.")
	await _w(4.6)
	_tw(soul, "alpha", 0.0, 1.0)
	await _w(1.2)
	_end()


## Memória, não morte: o berço vazio e o motivo de Morvant.
func scene_movel() -> void:
	prop_draw = _props_movel
	var cel := _actor("cel", {"x": 250.0, "facing": 1.0, "kind": "woman", "sit": 1.0, "arm_f": 1.2, "alpha": 0.8})
	var host := _actor("host", {"x": 700.0, "facing": -1.0, "kind": "host"})
	await _w(1.0)
	_say("CELESTE", "Dorme, Benjamim, que a noite é comprida... dorme, que a mãe fica.")
	for i in 6:
		_tw(cel, "lean", 0.18 if i % 2 == 0 else -0.06, 0.5)
		await _w(0.55)
	_walk_to(host, 420.0, 2.4)
	await _w(2.6)
	_say("MORVANT", "Você canta para um berço vazio há três meses, Celeste.")
	await _w(3.4)
	_say("CELESTE", "Ele nasceu sem respirar, Ezequiel. Deixe-o ir. Por favor.")
	await _w(3.6)
	_say("MORVANT", "A morte é uma porta. Eu só preciso montar a chave.")
	await _w(3.2)
	_say("MORVANT", "Uma voz para chamá-lo. Olhos para encontrá-lo. Mãos para trazê-lo de volta.")
	await _w(4.0)
	_tw(cel, "sit", 0.0, 0.6)
	await _w(0.6)
	_say("CELESTE", "Você está falando dos nossos convidados. Ezequiel... dos nossos convidados?")
	await _w(3.6)
	_sfx("laugh", -8.0, 0.8)
	_say("MORVANT", "Benjamim vai voltar. E você vai cantar para ele de novo. Não do jeito que imagina.")
	await _w(4.4)
	_tw(cel, "alpha", 0.0, 2.0)
	_tw(host, "alpha", 0.0, 2.0)
	await _w(2.2)
	_say("DÁLIA", "Benjamim. O filho deles. Foi por ele que Morvant abriu o véu.")
	await _w(3.6)
	_end()


func scene_sussurros() -> void:
	prop_draw = _props_sussurros
	surfaces = [Rect2(180, 236, 160, 12)]
	blood.floor_y = FLOOR
	blood.walls = [Rect2(60, 40, 520, 200)]
	var ofe := _actor("ofe", {"x": 260.0, "y": 238.0, "facing": 1.0, "kind": "woman", "sit": 1.0, "arm_f": 1.3, "arm_b": 1.2, "alpha": 0.85})
	var host := _actor("host", {"x": 700.0, "facing": -1.0, "kind": "host"})
	await _w(1.2)
	_say("OFÉLIA", "Eles estão com medo, pai. Todos. Até o capitão está chorando lá no seu quarto.")
	await _w(3.6)
	_walk_to(host, 340.0, 2.4)
	await _w(2.6)
	_say("MORVANT", "Eles têm razão de ter medo. Você não, filha. É só o seu dom que eu quero.")
	await _w(3.6)
	host.tool = "trepano"
	_say("OFÉLIA", "Pai? Pai, os mortos estão gritando. O que é isso na sua mão?")
	await _w(2.6)
	_walk_to(host, 288.0, 0.6)
	await _w(0.6)
	host.facing = -1.0
	_tw(host, "arm_f", 1.9, 0.2)
	ofe.tremble = 1.0
	_sfx("scream", -4.0, 1.5)
	await _w(0.4)
	# A broca entra pela têmpora.
	for i in 10:
		_sfx("saw", -10.0, 2.2)
		var head := part("ofe", "head")
		blood.spray(head, Vector2(-1, -0.6), 10, 120.0, 0.6, 1.4)
		blood.drip(head + Vector2(randf_range(-3, 3), 4), 40.0)
		_shake(0.25)
		await _w(0.24)
	_sfx("crunch", -2.0, 1.4)
	blood.spray(part("ofe", "head"), Vector2(-1, -0.2), 60, 200.0, 0.6, 2.0)
	_shake(1.0)
	flash = 0.35
	ofe.tremble = 0.0
	_tw(ofe, "lean", -1.2, 0.8)
	await _w(1.0)
	_sfx("slam", -10.0, 1.3)
	blood.pool(Vector2(250, 238.0), 18.0)
	await _w(0.8)
	_say("MORVANT", "Pronto. Agora eu também ouço. Que barulho eles fazem, Ofélia.")
	await _w(3.8)
	var soul := _actor("soul", {"x": 260.0, "y": 238.0, "facing": 1.0, "kind": "woman", "alpha": 0.0})
	_tw(soul, "alpha", 0.8, 1.5)
	_tw(soul, "rise", 44.0, 2.5)
	_sfx("whisper", -4.0, 1.3)
	await _w(2.0)
	if host_version:
		_say("MORVANT", "Minha filha não tem nada a dizer, médium. Eu fiquei com o dom dela, lembra?")
	else:
		_say("OFÉLIA", "Ele vai fazer o mesmo com você, Dália. O padre ainda reza lá embaixo, na capela. Desça pelo alçapão da cozinha.")
	await _w(5.0)
	_tw(soul, "alpha", 0.0, 1.0)
	await _w(1.2)
	_end()


## Memória, não morte: o láudano no vinho do jantar, e o padre que viu.
func scene_balanca() -> void:
	prop_draw = _props_balanca
	surfaces = [Rect2(250, 232, 130, 6)]
	blood.walls = [Rect2(40, 60, 560, 200)]
	var host := _actor("host", {"x": 330.0, "facing": 1.0, "kind": "host", "arm_f": 1.1})
	var ans := _actor("ans", {"x": -30.0, "facing": 1.0, "kind": "priest", "alpha": 0.8})
	await _w(0.8)
	# Morvant pinga o láudano garrafa por garrafa.
	for i in 4:
		_tw(host, "arm_f", 1.5, 0.3)
		await _w(0.4)
		_sfx("drip", -6.0, 1.0 + i * 0.1)
		_sfx("tile", -14.0, 1.8)
		_tw(host, "arm_f", 1.0, 0.3)
		await _w(0.5)
	_walk_to(ans, 170.0, 2.6)
	_say("ANSELMO", "Ezequiel? Celeste disse que você estava aqui embaixo. O que está pondo no vinho?")
	await _w(3.2)
	host.facing = -1.0
	_say("MORVANT", "Láudano, padre. Uma gota por convidado. Para que ninguém se levante da mesa cedo demais.")
	await _w(4.0)
	_say("ANSELMO", "Isso é veneno. Há uma moça de dezenove anos lá em cima. A sua filha.")
	await _w(3.6)
	_say("MORVANT", "Ofélia bebe água. Ela precisa estar acordada. Ela vai ouvir tudo.")
	await _w(3.6)
	_tw(ans, "arm_f", 0.8, 0.3)
	_say("ANSELMO", "Vou subir e contar a eles. Agora mesmo, antes do primeiro brinde...")
	await _w(2.6)
	ans.facing = -1.0
	_walk_to(ans, 120.0, 1.4)
	host.tool = "garrafa"
	_walk_to(host, 150.0, 1.1)
	await _w(1.1)
	host.facing = -1.0
	_tw(host, "arm_f", 2.6, 0.12)
	await _w(0.14)
	_sfx("crunch", 0.0, 1.3)
	_sfx("pop", -4.0, 0.7)
	_shake(0.9)
	flash = 0.3
	var head := part("ans", "head")
	for k in 6:
		gib(head, "glass", Vector2(randf_range(-90, 40), randf_range(-140, -40)))
	blood.spray(head, Vector2(-1, -0.5), 40, 160.0, 0.7, 1.8)
	host.tool = ""
	ans.walking = false
	ans.tremble = 1.0
	_tw(ans, "sit", 1.0, 0.4)
	_tw(ans, "y", FLOOR + 10.0, 0.4)
	_tw(ans, "lean", 0.6, 0.4)
	await _w(0.6)
	for i in 5:
		blood.drip(part("ans", "head") + Vector2(randf_range(-2, 2), 2), 30.0)
	_tw(host, "arm_f", 0.4, 0.3)
	await _w(0.8)
	ans.tremble = 0.0
	_say("MORVANT", "O senhor vai rezar, padre. Lá na capela, de joelhos, até eu precisar do seu coração.")
	await _w(4.0)
	_sfx("laugh", -8.0, 0.85)
	_say("ANSELMO", "...Pater noster, qui es in caelis...")
	await _w(3.4)
	_tw(ans, "alpha", 0.0, 2.0)
	_tw(host, "alpha", 0.0, 2.0)
	await _w(2.2)
	_say("DÁLIA", "O vinho do jantar. Por isso ninguém conseguiu fugir. E o padre sabia, e ficou trancado aqui embaixo.")
	await _w(4.4)
	_end()


func scene_vitral() -> void:
	prop_draw = _props_vitral
	surfaces = [Rect2(376, 230, 138, 7)]
	blood.walls = [Rect2(40, 40, 560, 230)]
	var ans := _actor("ans", {"x": 360.0, "y": FLOOR + 10.0, "facing": 1.0, "kind": "priest", "sit": 1.0, "lean": 0.25, "arm_f": 1.6, "arm_b": 1.5, "bend": 1.2, "alpha": 0.85})
	var host := _actor("host", {"x": -40.0, "facing": 1.0, "kind": "host"})
	await _w(1.0)
	_sfx("bell", -8.0, 1.0)
	_say("ANSELMO", "...requiem aeternam dona eis, Domine... Eu sabia que você viria, Ezequiel.")
	await _w(3.8)
	_walk_to(host, 300.0, 3.2)
	await _w(1.2)
	_say("ANSELMO", "Treze anos rezando por você. Alguém precisava confessar no seu lugar.")
	await _w(2.4)
	_say("MORVANT", "Guarde a absolvição, padre. Eu vim buscar o coração que a sente.")
	await _w(3.8)
	# Ele ergue o padre e o deita sobre o altar.
	_tw(host, "arm_f", 1.5, 0.3)
	_tw(ans, "sit", 0.0, 0.5)
	_tw(ans, "y", FLOOR, 0.5)
	_tw(ans, "lean", 0.0, 0.5)
	await _w(0.7)
	_sfx("slam", -6.0, 1.1)
	_tw(ans, "x", 488.0, 0.5)
	_tw(ans, "y", 230.0, 0.5)
	_tw(ans, "fall", -1.0, 0.5)
	ans.arm_f = 0.0
	ans.arm_b = 0.0
	await _w(0.6)
	_walk_to(host, 418.0, 0.8)
	await _w(0.9)
	host.facing = 1.0
	host.tool = "bisturi"
	_say("ANSELMO", "...Pater... noster...")
	ans.tremble = 1.0
	# Bisturi: o peito aberto de cima a baixo.
	for i in 4:
		_tw(host, "arm_f", 1.9 - (i % 2) * 0.5, 0.16)
		_sfx("squelch", -2.0, randf_range(0.8, 1.0))
		var chest := part("ans", "shoulder").lerp(part("ans", "hip"), 0.3 + i * 0.1)
		blood.spray(chest, Vector2(randf_range(-0.4, 0.4), -1), 20, 140.0, 0.6, 1.6)
		_shake(0.3)
		await _w(0.32)
	_sfx("scream", -4.0, 0.9)
	# Serra: as costelas.
	host.tool = "serra"
	_sfx("saw", 0.0, 0.9)
	for i in 6:
		_tw(host, "arm_f", 1.4 + (i % 2) * 0.5, 0.12)
		blood.spray(part("ans", "shoulder").lerp(part("ans", "hip"), 0.35), Vector2(randf_range(-1, 1), -1), 12, 160.0, 0.7)
		if i % 2 == 1:
			_sfx("crunch", -2.0, 1.0 + i * 0.05)
		_shake(0.35)
		await _w(0.2)
	# A mão entra e sai com o coração.
	host.tool = ""
	_tw(host, "arm_f", 2.0, 0.3)
	await _w(0.5)
	_sfx("squelch", 0.0, 0.6)
	_sfx("heart", 0.0, 1.0)
	_tw(host, "arm_f", 2.9, 0.25)
	host.tool = "coracao"
	var c2 := part("ans", "shoulder").lerp(part("ans", "hip"), 0.35)
	blood.spray(c2, Vector2(0, -1), 70, 220.0, 0.5, 2.2)
	blood.pool(Vector2(450, FLOOR), 30.0)
	_shake(1.0)
	flash = 0.4
	ans.tremble = 0.0
	for i in 6:
		blood.drip(Vector2(randf_range(380, 510), 237.0), 40.0)
	await _w(1.2)
	for i in 3:
		_sfx("heart", -4.0, 0.9)
		await _w(0.8)
	_say("MORVANT", "Ainda bate. Coração de padre bate por mais tempo. É a culpa: ela dá corda.")
	await _w(4.0)
	var soul := _actor("soul", {"x": 460.0, "y": 230.0, "facing": -1.0, "kind": "priest", "alpha": 0.0})
	_tw(soul, "alpha", 0.75, 1.5)
	_tw(soul, "rise", 40.0, 2.5)
	_sfx("whisper", -4.0, 0.7)
	_sfx("bell", -10.0, 1.3)
	await _w(2.0)
	if host_version:
		_say("MORVANT", "O padre manda dizer que perdoa você, médium. Eu perguntei por ele.")
	else:
		_say("ANSELMO", "Ele costurou um corpo com as nossas partes. Benjamim não voltou nele, filha. Outra coisa voltou.")
		await _w(4.6)
		_say("ANSELMO", "Atrás do altar há uma passagem para a cripta. Não deixe que ele termine.")
	await _w(4.6)
	_tw(soul, "alpha", 0.0, 1.0)
	await _w(1.2)
	_end()


## Memória, não morte: o enterro de Benjamim e a noite em que o caixão abriu.
func scene_ossuario() -> void:
	prop_draw = _props_ossuario
	var cel := _actor("cel", {"x": 270.0, "y": FLOOR + 10.0, "facing": 1.0, "kind": "woman", "sit": 1.0, "lean": 0.4, "arm_f": 1.1, "alpha": 0.8})
	var ans := _actor("ans", {"x": 400.0, "facing": -1.0, "kind": "priest", "arm_f": 1.4, "alpha": 0.8})
	var host := _actor("host", {"x": 200.0, "facing": 1.0, "kind": "host"})
	await _w(1.0)
	_sfx("bell", -8.0, 0.8)
	_say("ANSELMO", "Benjamim Morvant. Nasceu e morreu no mesmo dia. Requiescat in pace.")
	await _w(3.8)
	_say("CELESTE", "Ele é tão pequeno, Ezequiel. Cabia inteiro nas minhas duas mãos.")
	await _w(3.8)
	_say("MORVANT", "Ele não vai ficar aqui embaixo, Celeste.")
	await _w(3.0)
	_say("ANSELMO", "Doutor, a morte de uma criança não é uma pergunta. Deixe que ela descanse.")
	await _w(3.8)
	_tw(cel, "alpha", 0.0, 2.0)
	_tw(ans, "alpha", 0.0, 2.0)
	_tw(host, "alpha", 0.0, 2.0)
	await _w(2.4)
	_say("", "Na mesma noite.")
	await _w(2.4)
	host.x = -30.0
	host.tool = "lamparina"
	_tw(host, "alpha", 1.0, 0.5)
	_walk_to(host, 290.0, 3.0)
	await _w(3.2)
	host.tool = ""
	_tw(host, "arm_f", 1.4, 0.4)
	await _w(0.5)
	_sfx("door", -6.0, 1.6)
	_shake(0.3)
	await _w(1.0)
	_tw(host, "arm_f", 0.9, 0.6)
	host.tool = "embrulho"
	await _w(0.8)
	_say("MORVANT", "Vamos, filho. O papai preparou um quarto lá no alto. Um teatro inteiro, só para você.")
	await _w(4.4)
	_walk_to(host, 700.0, 4.0)
	await _w(1.6)
	_sfx("cry", -8.0, 1.0)
	await _w(2.6)
	_say("DÁLIA", "Ele tirou o próprio filho do caixão. Benjamim está lá em cima, no teatro do sótão.")
	await _w(4.2)
	_say("DÁLIA", "E os números desta parede... alguém continuou contando os crânios depois disso.")
	await _w(3.8)
	_end()


## Memória, não morte: a costura. O corpo de Benjamim, montado com as peças.
func scene_bau() -> void:
	prop_draw = _props_bau
	blood.walls = [Rect2(280, 120, 220, 110)]
	surfaces = [Rect2(300, 230, 180, 7)]
	var host := _actor("host", {"x": 300.0, "facing": 1.0, "kind": "host", "arm_f": 1.3, "tool": "agulha"})
	await _w(1.0)
	# Ele costura, ponto por ponto, cantarolando com a voz de Celeste.
	for i in 5:
		_tw(host, "arm_f", 1.8, 0.25)
		await _w(0.3)
		_sfx("squelch", -14.0, 1.8)
		if State.gore and i % 2 == 0:
			blood.drip(Vector2(352 + i * 5, 222), 20.0)
		_tw(host, "arm_f", 1.2, 0.3)
		await _w(0.4)
	_sfx("whisper", -6.0, 1.7)
	_say("MORVANT", "As mãos do pianista, para ele tocar. Os olhos da cozinheira, para ele achar o caminho de casa.")
	await _w(4.6)
	_say("MORVANT", "A pele do capitão, que aguenta qualquer frio. A voz da mãe, para chamar por ela.")
	await _w(4.4)
	_say("MORVANT", "O coração do padre, que bate mais do que devia. E o dom de Ofélia, para ouvir o caminho de volta.")
	await _w(4.6)
	host.tool = ""
	_tw(host, "arm_f", 0.4, 0.4)
	await _w(1.0)
	_say("MORVANT", "Acorde, Benjamim. O papai está aqui.")
	await _w(3.0)
	# Nada. Depois, a mão grande demais se mexe.
	_sfx("heart", -4.0, 1.2)
	await _w(1.2)
	_sfx("heart", -2.0, 1.2)
	_shake(0.3)
	await _w(0.8)
	_sfx("cry", -2.0, 0.8)
	_shake(0.6)
	flash = 0.25
	_say("MORVANT", "Ele mexeu. Ele MEXEU! Benjamim? Olhe para o papai...")
	await _w(3.4)
	_sfx("scream", -6.0, 0.7)
	_say("MORVANT", "Não. Não é ele. Os olhos... o que está olhando por esses olhos não é o meu filho.")
	await _w(4.0)
	_say("MORVANT", "Falta uma peça. Alguém que escute de verdade, para chamar o menino certo pelo nome.")
	await _w(4.4)
	_sfx("laugh", -8.0, 0.8)
	_tw(host, "alpha", 0.0, 2.0)
	await _w(2.2)
	_say("DÁLIA", "A última peça. Uma médium de verdade. Ele não me trouxe aqui para acalmar a casa.")
	await _w(4.4)
	_end()


## Mostra os botões da escolha final e espera um clique. O Esc não pula isto.
func _choose(options: Array) -> int:
	skipping = false
	var box := VBoxContainer.new()
	box.position = Vector2(170, 120)
	box.custom_minimum_size = Vector2(300, 0)
	box.add_theme_constant_override("separation", 8)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size = Vector2(640, 360)
	add_child(root)
	root.add_child(box)
	for i in options.size():
		var b := Button.new()
		b.text = options[i]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(300, 26)
		b.pressed.connect(func(): _picked.emit(i))
		box.add_child(b)
	if house and house.cursor:
		house.cursor.mode = "hand"
	choosing = true
	var idx: int = await _picked
	choosing = false
	root.queue_free()
	if house and house.cursor:
		house.cursor.mode = "flame"
	return idx


## Os mortos libertados descem da plateia. Devolve os atores.
func _souls_descend(xs: Array) -> Array:
	var out: Array = []
	var kinds := ["woman", "man", "woman", "woman", "man", "woman", "priest"]
	for i in xs.size():
		var a := _actor("s%d" % i, {"x": float(xs[i]), "facing": 1.0 if xs[i] < 320 else -1.0, "kind": kinds[i % kinds.size()], "alpha": 0.0})
		_tw(a, "alpha", 0.75, 1.2)
		out.append(a)
	spectators = []
	return out


## O confronto no teatro e os quatro finais.
func scene_montagem() -> void:
	prop_draw = _props_montagem
	surfaces = [Rect2(270, 236, 120, 8)]
	blood.walls = [Rect2(60, 40, 520, 200)]
	for k in 7:
		var side := -1.0 if k % 2 == 0 else 1.0
		var row := k % 3
		spectators.append(Vector2(320.0 + side * (210.0 + row * 40.0 + (k / 2) * 18.0), 236.0 - row * 34.0))
	var dal := _actor("dal", {"x": 120.0, "facing": 1.0, "kind": "dalia", "alpha": 1.0})
	var host := _actor("host", {"x": 450.0, "facing": -1.0, "kind": "host"})
	await _w(1.0)
	_walk_to(dal, 230.0, 2.2)
	await _w(2.4)
	_say("MORVANT", "Você desfez o meu filho. Ponto por ponto, como quem desfaz uma bainha.")
	await _w(4.0)
	_say("MORVANT", "Não importa. As peças voltam para a gaveta. Mas a última peça veio sozinha até a minha mesa.")
	await _w(4.4)
	_say("MORVANT", "Deite-se, Dália. Você escuta os mortos. Com você, ele escuta o caminho de volta.")
	await _w(4.4)
	_say("DÁLIA", "Na bandeja ao lado da mesa, um bisturi. Na plateia, sete mortos esperam que eu diga alguma coisa.")
	await _w(4.0)
	var choice := "nome"
	if State.sanity < 15.0:
		_say("DÁLIA", "...não consigo... as vozes são muitas... a mesa está tão fria...")
		await _w(3.0)
		ending = "peca"
	else:
		var idx := await _choose(["Dizer o nome dele: \"Benjamim\"", "Pegar o bisturi da bandeja"])
		choice = "nome" if idx == 0 else "bisturi"
		ending = State.ending_for(choice)
	match ending:
		"medium":
			await _end_medium(dal, host, false)
		"cancao":
			await _end_medium(dal, host, true)
		"anfitriao":
			await _end_host(dal, host)
		_:
			await _end_piece(dal, host, choice == "nome")
	State.record_ending(ending)
	_end()


func _end_medium(dal: Actor, host: Actor, song: bool) -> void:
	_say("DÁLIA", "Benjamim.")
	_sfx("bell", -2.0, 0.9)
	await _w(2.2)
	show_body = false
	baby_glow = 0.0
	baby_at = Vector2(320, 224)
	var tw := create_tween()
	tw.tween_property(self, "baby_glow", 0.9, 1.5)
	_sfx("cry", -6.0, 1.2)
	_say("MORVANT", "Ali... em cima da mesa... é ele? Benjamim? Filho, o papai está...")
	await _w(4.0)
	var souls := _souls_descend([150, 180, 210, 260, 380, 420, 470])
	await _w(1.6)
	if song:
		var cel: Actor = souls[2]
		_walk_to(cel, 300.0, 1.6)
		await _w(1.8)
		_say("DÁLIA", "Abro o vidro que trouxe do quarto dela. A voz volta para a garganta de Celeste.")
		await _w(3.6)
		for i in 6:
			_sfx("whisper", -6.0, 1.5 + i * 0.05)
		_sfx("cry", -14.0, 1.4)
		_say("CELESTE", "Dorme, Benjamim, que a noite é comprida... dorme, que a mãe fica.")
		_tw(cel, "arm_f", 1.3, 0.6)
		var tw2 := create_tween()
		tw2.tween_property(self, "baby_at", Vector2(312, 196), 1.5)
		await _w(4.2)
		_say("MORVANT", "Celeste... me leve junto. Eu fiz tudo isso por ele. Por nós.")
		await _w(3.8)
		_say("CELESTE", "Não, Ezequiel. Você fica. A casa é sua. Foi você que a encheu.")
		await _w(3.8)
		_tw(cel, "rise", 140.0, 4.0)
		var tw3 := create_tween()
		tw3.tween_property(self, "baby_at", Vector2(312, 50), 4.0)
		await _w(4.2)
		baby_glow = 0.0
	else:
		var tw4 := create_tween()
		tw4.tween_property(self, "baby_at", Vector2(320, 30), 4.0)
		_say("DÁLIA", "Uma luz pequena sobe pela claraboia, e some no luar. Não era a coisa costurada. Era ele.")
		await _w(4.4)
		baby_glow = 0.0
	# Os mortos cobram de volta o que é deles.
	_say("MORVANT", "Não. NÃO. Fiquem nos seus lugares! Eu sou o anfitrião!")
	for a in souls:
		_walk_to(a, host.x + randf_range(-30, 30), 1.4)
	await _w(1.6)
	host.tremble = 1.0
	_sfx("scream", 0.0, 0.7)
	for i in 8:
		var part_name: String = ["hand_f", "hand_b", "eyes", "mouth", "shoulder", "neck", "hip", "head"][i]
		var at := part("host", part_name)
		blood.spray(at, Vector2(randf_range(-1, 1), -1), 26, 190.0, 0.7, 1.8)
		gib(at, ["hand", "hand", "eye", "tooth", "skin", "tooth", "skin", "eye"][i], Vector2(randf_range(-90, 90), randf_range(-160, -60)))
		_sfx(["crunch", "squelch"][i % 2], -2.0, randf_range(0.7, 1.1))
		_shake(0.6)
		if i == 1:
			host.hands = false
		await _w(0.35)
	host.tremble = 0.0
	_tw(host, "fall", 1.0, 0.6)
	await _w(0.7)
	_sfx("slam", -2.0, 0.8)
	blood.pool(Vector2(host.x + 30, FLOOR), 40.0)
	flash = 0.5
	await _w(1.4)
	for a in souls:
		_tw(a, "alpha", 0.0, 2.5)
		_tw(a, "rise", 60.0, 2.5)
	_tw(host, "alpha", 0.0, 3.0)
	await _w(3.0)
	_say("DÁLIA", "Lá embaixo, uma corrente cai no chão do saguão. A porta da frente range e abre para a manhã.")
	await _w(4.6)
	if song:
		_say("DÁLIA", "No caminho de volta, a casa canta baixinho. Uma canção de ninar, afinada pela primeira vez.")
	else:
		_say("DÁLIA", "Eu era uma médium falsa. Agora escuto os mortos o tempo todo. Pelo menos estes foram embora.")
	await _w(4.8)


func _end_piece(dal: Actor, host: Actor, said_name: bool) -> void:
	if said_name:
		_say("DÁLIA", "Benjamim.")
		await _w(2.0)
		_say("MORVANT", "Bonito. Mas você não lembra de todos os rostos, médium. Ou não libertou todos. O nome não chega a ele.")
		await _w(4.6)
	host.tool = "garrafa"
	_walk_to(host, 260.0, 1.2)
	await _w(1.2)
	host.facing = -1.0
	_tw(host, "arm_f", 2.6, 0.12)
	await _w(0.15)
	_sfx("crunch", 0.0, 1.2)
	_shake(0.8)
	flash = 0.3
	blood.spray(part("dal", "head"), Vector2(-1, -0.4), 30, 150.0, 0.6, 1.6)
	dal.tremble = 1.0
	_tw(dal, "fall", -1.0, 0.6)
	await _w(1.0)
	dal.tremble = 0.0
	host.tool = ""
	_say("MORVANT", "Shh. Láudano no vinho, láudano no lenço. Não dói. Quer dizer: dói, mas você não vai lembrar.")
	await _w(4.0)
	# Ele a leva até a mesa e costura.
	_tw(dal, "x", 330.0, 0.8)
	_tw(dal, "y", 228.0, 0.8)
	_walk_to(host, 300.0, 0.8)
	await _w(1.0)
	host.facing = 1.0
	host.tool = "agulha"
	for i in 8:
		_tw(host, "arm_f", 1.9 - (i % 2) * 0.6, 0.18)
		blood.spray(part("dal", "head").lerp(part("dal", "hip"), (i % 4) / 4.0), Vector2(randf_range(-0.4, 0.4), -1), 12, 120.0, 0.7, 1.4)
		_sfx("squelch", -4.0, randf_range(1.4, 1.8))
		if i == 3:
			_sfx("scream", -6.0, 1.3)
		_shake(0.3)
		await _w(0.4)
	await _w(1.0)
	_sfx("heart", -2.0, 1.1)
	await _w(1.2)
	_tw(dal, "fall", -0.3, 1.0)
	await _w(1.2)
	_sfx("cry", -4.0, 0.8)
	_say("DÁLIA", "...Papai?")
	await _w(3.0)
	_sfx("laugh", -2.0, 0.8)
	_say("MORVANT", "Bem-vindo de volta, filho. Bem-vinda, médium. Agora vocês dois escutam. E eu nunca mais fico sozinho.")
	await _w(5.0)
	_tw(dal, "alpha", 0.3, 2.0)
	await _w(2.4)


func _end_host(dal: Actor, host: Actor) -> void:
	dal.tool = "bisturi"
	_say("MORVANT", "Isso. Pegue. Eu sabia que você entendia de anatomia.")
	_walk_to(dal, 400.0, 1.6)
	await _w(1.7)
	_tw(dal, "arm_f", 2.2, 0.12)
	await _w(0.12)
	_sfx("squelch", 0.0, 1.0)
	_sfx("scream", -2.0, 0.6)
	_shake(1.0)
	flash = 0.4
	var neck := part("host", "neck")
	blood.spray(neck, Vector2(-1, -0.3), 90, 240.0, 0.4, 2.4)
	blood.spray(neck, Vector2(1, -0.5), 40, 160.0, 0.7, 1.8)
	host.tremble = 1.0
	await _w(0.6)
	for i in 5:
		blood.spray(part("host", "neck"), Vector2(randf_range(-1, 1), 0.2), 14, 110.0, 0.5)
		blood.drip(part("host", "neck"), 50.0)
		await _w(0.35)
	host.tremble = 0.0
	_tw(host, "fall", 1.0, 0.8)
	await _w(0.9)
	_sfx("slam", -4.0, 0.9)
	blood.pool(Vector2(host.x + 34, FLOOR), 44.0)
	await _w(1.2)
	_say("MORVANT", "...a casa... é sua... cuide bem... dos convidados...")
	await _w(3.6)
	_tw(host, "alpha", 0.0, 2.0)
	dal.tool = ""
	await _w(2.0)
	# Dália se senta onde ele ficava. A plateia se curva.
	_walk_to(dal, 420.0, 1.0)
	await _w(1.0)
	dal.facing = -1.0
	_tw(dal, "sit", 1.0, 0.8)
	for i in spectators.size():
		spectators[i] = (spectators[i] as Vector2) + Vector2(0, 4)
	_sfx("bell", -4.0, 0.6)
	await _w(1.4)
	_say("DÁLIA", "A casa ficou quieta. Os mortos esperam que eu diga o que fazer. E eu gosto disso.")
	await _w(4.4)
	_tw(dal, "alpha", 0.0, 2.0)
	await _w(2.2)
	_say("", "Treze anos depois.")
	await _w(2.6)
	_sfx("laugh", -6.0, 1.2)
	_say("DÁLIA", "Uma médium... Enfim, alguém que escuta.")
	await _w(4.0)
