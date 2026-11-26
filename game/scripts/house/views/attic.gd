extends "res://scripts/house/view.gd"
## Sótão: o telhado em duas águas, caibros, manequins sob lençóis, um
## cavalinho de balanço e o baú de Morvant. No fundo, a porta dupla do
## Teatro Anatômico, com um olho de vidro em cima. À direita, a portinha da
## escada da torre do relógio.

var eye_c := Vector2()
var eye_r := 4.0
var forms: Array = []
var horse := Vector2()
var horse_s := 1.0
var sheet_t := -1.0


func _init() -> void:
	id = "attic"
	title = "Sótão"
	music = "sotao"
	grade = "sotao"


## Água do telhado: de (x_eave, y_eave) até a cumeeira (0, ridge).
func roof(side: float, z0: float, z1: float, col: Color) -> void:
	var xe := side * 3.0
	for i in 6:
		var a := float(i) / 6.0
		var b := float(i + 1) / 6.0
		var pa := Vector3(lerpf(xe, 0.0, a), lerpf(1.0, 3.4, a), 0.0)
		var pb := Vector3(lerpf(xe, 0.0, b), lerpf(1.0, 3.4, b), 0.0)
		p.poly3([Vector3(pa.x, pa.y, z0), Vector3(pb.x, pb.y, z0), Vector3(pb.x, pb.y, z1), Vector3(pa.x, pa.y, z1)], col.darkened(0.05 * i))


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.32
	p.fog = Color(0.015, 0.015, 0.02)
	p.fog_start = 3.5
	p.fog_len = 10.0
	var wood := Color(0.3, 0.22, 0.16)
	var beam := Color(0.22, 0.15, 0.1)
	var moon := Color(0.65, 0.75, 1.0)
	p.add_light(Vector3(2.4, 1.6, 4.2), moon, 4.0, 0.9, 0.0, 130.0)
	p.add_light(Vector3(0, 2.3, 8.6), Color(0.9, 0.95, 1.0) if State.flag("luar") else Color(1.0, 0.6, 0.35), 2.4, 0.7, 0.2, 70.0)
	# Telhado em lâminas ao longo de z.
	for k in 9:
		var za := 0.4 + k * 0.95
		roof(-1.0, za, za + 0.95, wood)
		roof(1.0, za, za + 0.95, wood)
	# Paredinhas baixas dos lados (até o beiral).
	p.side_wall(-3.0, 0.4, 9.0, 0.0, 1.0, wood.darkened(0.2), 12)
	p.side_wall(3.0, 0.4, 9.0, 0.0, 1.0, wood.darkened(0.2), 12)
	# Empena do fundo.
	p.poly3([Vector3(-3, 0, 9), Vector3(3, 0, 9), Vector3(3, 1, 9), Vector3(0, 3.4, 9), Vector3(-3, 1, 9)], wood.darkened(0.1))
	p.floor_plane(-3, 3, 0.4, 9, 0.0, Color(0.3, 0.22, 0.15), Color(0.16, 0.11, 0.07), "boards", 16)
	# Caibros: em cada um, os dois braços do V invertido.
	for k in 10:
		var z := 0.9 + k * 0.85
		p.line3(Vector3(-3, 1.0, z), Vector3(0, 3.4, z), beam, 3.0)
		p.line3(Vector3(3, 1.0, z), Vector3(0, 3.4, z), beam, 3.0)
	p.box(-3, 3, 2.3, 2.42, 5.0, 5.12, beam)
	# Lucarna com a lua, na água da direita.
	glass.append(p.window_side(2.98, 4.2, 0.9, 0.2, 0.7, beam, SKY_TOP, SKY_BOT))
	# Porta dupla do teatro, no fundo, com o olho de vidro.
	var theater := p.door_back(0, 8.99, 1.4, 2.0, Color(0.36, 0.14, 0.12), false, false)
	for dx in [-1.0, 1.0]:
		p.box(dx - 0.08, dx + 0.08, 0.0, 0.9, 8.6, 8.76, Color(0.2, 0.14, 0.1))
		p.candle(Vector3(dx, 0.9, 8.68), 0.2, true, 2.2, 0.6)
	p.box(-0.35, 0.35, 2.05, 2.25, 8.95, 8.99, Color(0.6, 0.46, 0.2))
	draw_string(ThemeDB.fallback_font, p.proj(Vector3(-0.33, 2.1, 8.94)), "THEATRVM ANATOMICVM", HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(0.2, 0.12, 0.04))
	eye_c = p.proj(Vector3(0, 2.55, 8.98))
	eye_r = p.scale_at(9.0) * 0.16
	draw_circle(eye_c, eye_r + 2, p.shade(Color(0.5, 0.38, 0.2), Vector3(0, 2.55, 8.9)))
	# Porta da escada da torre, à direita.
	var tower := p.door_side(3.0, 6.6, 0.7, 0.98, Color(0.26, 0.17, 0.1), false)
	# Baú de Morvant, à esquerda, com ferragens.
	var leather := Color(0.32, 0.12, 0.08)
	p.box(-2.5, -1.4, 0.0, 0.6, 3.0, 3.7, leather, leather.lightened(0.1))
	for bx in [-2.3, -1.6]:
		p.line3(Vector3(bx, 0.0, 3.0), Vector3(bx, 0.6, 3.0), Color(0.5, 0.4, 0.2), 2.0)
	var lock_at := p.proj(Vector3(-1.95, 0.48, 3.0))
	draw_rect(Rect2(lock_at - Vector2(3, 3), Vector2(6, 6)), Color(0.75, 0.6, 0.3))
	var trunk := p.box_rect(-2.5, -1.4, 0.0, 0.62, 3.0, 3.7)
	# Manequins cobertos (desenhados vivos) e o cavalinho.
	forms = [Vector3(-1.9, 0.0, 6.0), Vector3(-1.3, 0.0, 7.2), Vector3(1.5, 0.0, 6.8)]
	horse = p.proj(Vector3(1.4, 0.0, 3.6))
	horse_s = p.scale_at(3.6) / 60.0
	# Teias nos cantos.
	for k in 6:
		var z2 := 1.5 + k * 1.3
		var c := p.proj(Vector3(-2.9, 1.05, z2))
		var c2 := p.proj(Vector3(-2.4, 1.4, z2))
		draw_line(c, c2, Color(0.6, 0.6, 0.62, 0.25), 1.0)
		draw_line(c, p.proj(Vector3(-2.9, 1.5, z2 + 0.3)), Color(0.6, 0.6, 0.62, 0.2), 1.0)
	if State.is_solved("bau"):
		hot(trunk, "look", "look:trunk_after", "O baú")
	else:
		hot(trunk, "puzzle", "puzzle:bau", "O baú de Morvant")
	hot(tower, "walk", "go:clock_tower", "Escada da torre")
	if State.has("chave_teatro") and State.flag("luar"):
		hot(theater, "walk", "event:theater", "Teatro Anatômico")
	else:
		hot(theater, "locked", "locked:theater", "Teatro Anatômico")
	hot(Rect2(horse - Vector2(20, 40) * horse_s, Vector2(40, 42) * horse_s), "look", "look:rocking_horse", "Cavalinho de balanço")
	hot_back("go:foyer", "Descer ao saguão")


func paint_live(o: Node2D) -> void:
	if p == null:
		return
	# O olho de vidro da porta: apagado, ou aceso pelo luar.
	var lit := State.flag("luar")
	o.draw_circle(eye_c, eye_r, Color(0.85, 0.92, 1.0, 0.85) if lit else Color(0.08, 0.06, 0.06))
	o.draw_circle(eye_c + Vector2(sin(t * 0.7), 0) * eye_r * 0.3, eye_r * 0.45, Color(0.1, 0.15, 0.3) if lit else Color(0.2, 0.05, 0.05))
	if lit:
		o.draw_circle(eye_c, eye_r * 3.0, Color(0.8, 0.9, 1.0, 0.08))
	# Manequins sob lençóis; um deles às vezes vira.
	for i in forms.size():
		var f: Vector3 = forms[i]
		var b := p.proj(f)
		var s := p.scale_at(f.z) / 60.0
		var sway := sin(t * 0.5 + i) * 1.0
		var turn := 0.0
		if i == 1 and sheet_t >= 0.0:
			turn = clampf(sheet_t / 0.5, 0.0, 1.0)
		var col := p.shade(Color(0.72, 0.72, 0.7), f + Vector3(0, 1, 0))
		o.draw_colored_polygon(PackedVector2Array([b + Vector2(-9 + sway, -70) * s, b + Vector2(9 + sway, -70) * s, b + Vector2(16, -8) * s, b + Vector2(-16, -8) * s]), col)
		o.draw_circle(b + Vector2(sway, -76) * s, 8.0 * s, col)
		o.draw_line(b + Vector2(0, -8) * s, b, Color(0.15, 0.1, 0.08), maxf(1.0, 2.0 * s))
		if turn > 0.0:
			o.draw_rect(Rect2(b + Vector2(-4 + sway, -79) * s, Vector2(3, 2) * s), Color(0, 0, 0, turn))
			o.draw_rect(Rect2(b + Vector2(2 + sway, -79) * s, Vector2(3, 2) * s), Color(0, 0, 0, turn))
			if State.gore:
				o.draw_rect(Rect2(b + Vector2(-2 + sway, -72) * s, Vector2(4, 30 * turn) * s), Color(0.5, 0.0, 0.04, turn))
	if sheet_t >= 0.0:
		sheet_t += get_process_delta_time()
		if sheet_t > 4.0:
			sheet_t = -1.0
	# Cavalinho de balanço: balança sozinho, devagar.
	var rock := sin(t * 1.1) * 0.15
	var s2 := horse_s
	var col2 := Color(0.45, 0.3, 0.2)
	o.draw_arc(horse + Vector2(0, -40 * s2).rotated(rock), 40 * s2, PI * 0.3, PI * 0.7, 10, col2.darkened(0.3), maxf(1.0, 2.0 * s2))
	var body := horse + Vector2(0, -18 * s2).rotated(rock)
	o.draw_rect(Rect2(body - Vector2(14, 5) * s2, Vector2(28, 10) * s2), col2)
	o.draw_line(body + Vector2(12, -4) * s2, body + Vector2(18, -16) * s2, col2, maxf(1.0, 5.0 * s2))
	o.draw_circle(body + Vector2(20, -17) * s2, 4.0 * s2, col2)
	o.draw_rect(Rect2(body + Vector2(20, -19) * s2, Vector2(1, 1)), Color(0.9, 0.85, 0.7))
	for lx in [-10.0, 10.0]:
		o.draw_line(body + Vector2(lx, 5) * s2, body + Vector2(lx, 16) * s2, col2, maxf(1.0, 2.0 * s2))


func entered(house) -> void:
	if not State.flag("attic_seen"):
		State.set_flag("attic_seen")
		sheet_t = 0.0
		Audio.play("cry", -4.0, 1.0)
		Audio.play("sting", -10.0, 0.8)
		house.subs.say("DÁLIA", "O choro vem de trás daquela porta dupla. Teatro Anatômico. Em cima dela, um olho de vidro, apagado.")
		house.subs.say("DÁLIA", "Um dos manequins virou a cabeça para mim. Eles não têm cabeça. Têm?")
		house.subs.say("MORVANT", "Bem-vinda ao meu sótão, médium. O espetáculo começa quando a lua olhar pela porta. E quando você achar a chave.")
		State.change_sanity(-5.0)
	elif randf() < 0.25 + State.madness() * 0.5:
		sheet_t = 0.0
		Audio.play("cry", -14.0, 1.1)
