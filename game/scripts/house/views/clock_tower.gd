extends "res://scripts/house/view.gd"
## Torre do relógio: o mostrador de vidro visto por trás (números ao
## contrário, a lua atravessando), engrenagens enormes nas paredes e um
## pêndulo que corta o ar na frente de Dália.

var face_c := Vector2()
var face_r := 40.0
var pend_top := Vector2()
var pend_len := 100.0
var gears: Array = []
var hang_t := -1.0
var last_side := 0.0


func _init() -> void:
	id = "clock_tower"
	title = "Torre do relógio"
	music = "sotao"
	grade = "sotao"


func paint() -> void:
	p.cy = 170.0
	p.ambient = 0.3
	p.fog = Color(0.015, 0.016, 0.022)
	p.fog_start = 2.5
	p.fog_len = 8.0
	var stone := Color(0.3, 0.3, 0.33)
	var iron := Color(0.24, 0.22, 0.2)
	p.add_light(Vector3(0, 2.6, 5.2), Color(0.7, 0.8, 1.0), 4.5, 1.1, 0.0, 170.0)
	p.floor_plane(-2.2, 2.2, 0.4, 6.0, 4.6, Color(0.05, 0.05, 0.06), Color(0.03, 0.03, 0.04), "", 6)
	p.back_wall(6.0, -2.2, 2.2, 0.0, 4.6, stone)
	for side in [-2.2, 2.2]:
		p.side_wall(side, 0.4, 6.0, 0.0, 4.6, stone, 12)
	p.floor_plane(-2.2, 2.2, 0.4, 6.0, 0.0, Color(0.26, 0.2, 0.14), Color(0.14, 0.1, 0.07), "boards", 10)
	# O mostrador por trás: vidro leitoso com a lua atrás.
	face_c = p.proj(Vector3(0, 2.7, 5.99))
	face_r = p.scale_at(6.0) * 1.5
	draw_circle(face_c, face_r + 4, p.shade(iron, Vector3(0, 2.7, 5.9)))
	draw_circle(face_c, face_r, Color(0.55, 0.6, 0.7))
	draw_circle(face_c + Vector2(face_r * 0.3, -face_r * 0.25), face_r * 0.35, Color(0.85, 0.88, 0.92))
	for h in 12:
		var a := TAU * h / 12.0 - PI * 0.5
		var np := face_c + Vector2(-cos(a), sin(a)) * face_r * 0.82
		var num: String = ["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"][h]
		# Visto por trás: espelhado, então desenhamos de traz-para-frente.
		var rev := ""
		for ch in num:
			rev = ch + rev
		draw_string(ThemeDB.fallback_font, np + Vector2(-8, 3), rev, HORIZONTAL_ALIGNMENT_CENTER, 16, 7, Color(0.12, 0.12, 0.14))
	# Ponteiros parados em 23h47 (visto por trás).
	draw_line(face_c, face_c + Vector2(-sin(TAU * 47.0 / 60.0), -cos(TAU * 47.0 / 60.0)) * face_r * 0.75, Color(0.08, 0.08, 0.1), 3.0)
	draw_line(face_c, face_c + Vector2(-sin(TAU * 11.8 / 12.0), -cos(TAU * 11.8 / 12.0)) * face_r * 0.5, Color(0.08, 0.08, 0.1), 4.0)
	draw_circle(face_c, 4, Color(0.1, 0.1, 0.12))
	glass.append(PackedVector2Array([face_c + Vector2(-face_r, -face_r) * 0.7, face_c + Vector2(face_r, -face_r) * 0.7, face_c + Vector2(face_r, face_r) * 0.7, face_c + Vector2(-face_r, face_r) * 0.7]))
	# Eixo do mostrador até a caixa de engrenagens.
	p.box(-0.06, 0.06, 2.64, 2.76, 5.2, 5.95, iron)
	# Engrenagens das paredes (desenhadas vivas, girando).
	gears = [[p.proj(Vector3(-2.19, 2.6, 3.0)), p.scale_at(3.0) * 0.9, 1.0], [p.proj(Vector3(-2.19, 1.2, 4.6)), p.scale_at(4.6) * 0.6, -1.4], [p.proj(Vector3(2.19, 2.2, 3.4)), p.scale_at(3.4) * 0.8, -0.9], [p.proj(Vector3(2.19, 3.6, 4.8)), p.scale_at(4.8) * 0.5, 1.8]]
	pend_top = p.proj(Vector3(0, 1.8, 3.3))
	pend_len = p.scale_at(3.3) * 1.5
	# Espelhos nas engrenagens: o enigma.
	var gear_rect := Rect2(face_c - Vector2(face_r, face_r) * 1.1, Vector2(face_r, face_r) * 2.2)
	if State.flag("luar"):
		hot(gear_rect, "look", "look:moonbeam_after", "O luar")
	else:
		hot(gear_rect, "puzzle", "puzzle:luar", "Os espelhos do mecanismo")
	hot(Rect2(pend_top - Vector2(30, 0), Vector2(60, pend_len + 20)), "look", "look:pendulum", "O pêndulo")
	hot_back("go:attic", "Descer ao sótão")


func _gear(o: Node2D, c: Vector2, r: float, spin: float) -> void:
	var col := Color(0.26, 0.22, 0.16)
	var pts := PackedVector2Array()
	var teeth := 16
	for i in teeth * 2:
		var a := spin + TAU * i / (teeth * 2.0)
		var rr := r if i % 2 == 0 else r * 0.86
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	o.draw_colored_polygon(pts, col)
	o.draw_circle(c, r * 0.7, col.darkened(0.25))
	for k in 5:
		var a2 := spin + TAU * k / 5.0
		o.draw_line(c, c + Vector2(cos(a2), sin(a2)) * r * 0.7, col.lightened(0.1), maxf(1.0, r * 0.08))
	o.draw_circle(c, r * 0.15, col.lightened(0.2))


func paint_live(o: Node2D) -> void:
	for g in gears:
		_gear(o, g[0], g[1], t * 0.25 * float(g[2]))
	# Feixe de luar pelo mostrador.
	if State.flag("luar"):
		o.draw_colored_polygon(PackedVector2Array([face_c + Vector2(-face_r * 0.2, 0), face_c + Vector2(face_r * 0.2, 0), Vector2(320 + face_r, 360), Vector2(320 - face_r, 360)]), Color(0.8, 0.88, 1.0, 0.07))
	# O pêndulo: lâmina larga, corta o ar com um assobio a cada passagem.
	var a := sin(t * 1.6) * 0.5
	var end := pend_top + Vector2(sin(a), cos(a)) * pend_len
	o.draw_line(pend_top, end, Color(0.3, 0.28, 0.26), 2.0)
	var blade := PackedVector2Array([end + Vector2(-26, 0).rotated(-a), end + Vector2(26, 0).rotated(-a), end + Vector2(0, 12).rotated(-a)])
	o.draw_colored_polygon(blade, Color(0.6, 0.62, 0.66))
	if State.gore:
		o.draw_line(end + Vector2(-20, 3).rotated(-a), end + Vector2(-6, 8).rotated(-a), Color(0.45, 0.0, 0.03), 2.0)
	var side := signf(sin(t * 1.6))
	if side != last_side:
		last_side = side
		Audio.play("tick", -12.0, 0.6)
	# Uma sombra enforcada na corda do sino, só por um instante.
	if hang_t >= 0.0:
		hang_t += get_process_delta_time()
		var al := clampf(1.0 - absf(hang_t - 0.8) / 0.8, 0.0, 1.0) * 0.8
		var top := face_c + Vector2(face_r * 1.6, -face_r * 0.9)
		o.draw_line(top, top + Vector2(0, 40), Color(0, 0, 0, al), 1.0)
		o.draw_circle(top + Vector2(0, 44), 5, Color(0, 0, 0, al))
		o.draw_rect(Rect2(top + Vector2(-4, 48), Vector2(8, 24)), Color(0, 0, 0, al))
		o.draw_line(top + Vector2(-2, 72), top + Vector2(-2, 92), Color(0, 0, 0, al), 2.0)
		o.draw_line(top + Vector2(2, 72), top + Vector2(3, 92), Color(0, 0, 0, al), 2.0)
		if hang_t > 1.6:
			hang_t = -1.0


func entered(house) -> void:
	if not State.flag("tower_seen"):
		State.set_flag("tower_seen")
		hang_t = 0.0
		Audio.play("bell", -2.0, 0.85)
		house.subs.say("DÁLIA", "O relógio parou em 23h47. A hora em que a sopa foi servida.")
		house.subs.say("DÁLIA", "A lua bate no mostrador e se perde entre as engrenagens. Há espelhos presos nelas.")
		house.subs.say("MORVANT", "Leve a lua até o olho da porta, médium. O teatro precisa de luz para a estreia.")
		State.change_sanity(-3.0)
	elif randf() < 0.2 + State.madness() * 0.5:
		hang_t = 0.0
		Audio.play("creak", -10.0, 0.6)
