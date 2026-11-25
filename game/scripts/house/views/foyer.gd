extends "res://scripts/house/view.gd"
## Saguão: escadaria, retrato de Morvant, a Prancheta e as portas do térreo.

var portrait_rect := Rect2()
var stairs_top := Vector2()
var figure_t := -1.0


func _init() -> void:
	id = "foyer"
	title = "Saguão"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.38
	p.fog = Color(0.015, 0.02, 0.02)
	# Luzes primeiro: o sombreamento de tudo depende delas.
	p.add_light(Vector3(0, 3.4, 4.6), Color(1.0, 0.7, 0.36), 6.5, 0.8, 0.15, 150.0)
	p.add_light(Vector3(2.35, 1.1, 3.6), Color(1.0, 0.6, 0.3), 2.2, 0.8, 0.3, 46.0)
	var wall := Color(0.2, 0.27, 0.22)
	var ink := Color(0.13, 0.19, 0.15)
	var wood := Color(0.3, 0.17, 0.1)
	var dark := Color(0.16, 0.08, 0.05)
	# Teto, paredes, piso
	p.floor_plane(-4, 4, 0.4, 9.5, 5.2, Color(0.12, 0.08, 0.06), Color(0.06, 0.04, 0.03), "", 12)
	p.back_wall(9.5, -4, 4, 0, 5.2, wall)
	p.wallpaper_back(9.5, -4, 4, 1.2, 5.2, ink)
	p.side_wall(-4, 0.4, 9.5, 1.2, 5.2, wall)
	p.wallpaper_side(-4, 0.4, 9.5, 1.2, 5.2, ink)
	p.side_wall(4, 0.4, 9.5, 1.2, 5.2, wall)
	p.wallpaper_side(4, 0.4, 9.5, 1.2, 5.2, ink)
	p.wainscot_side(-4, 0.4, 9.5, 1.2, wood, dark)
	p.wainscot_side(4, 0.4, 9.5, 1.2, wood, dark)
	p.wainscot_back(9.5, -4, 4, 1.2, wood, dark)
	p.floor_plane(-4, 4, 0.4, 9.5, 0.0, Color(0.26, 0.24, 0.21), Color(0.07, 0.06, 0.06), "tiles", 16)
	# Retrato de Morvant no patamar
	portrait_rect = p.portrait_back(0, 9.45, 1.5, 3.0, 1.8, "host")
	p.candle(Vector3(-1.3, 3.2, 9.4), 0.16, true, 2.2, 0.9)
	p.candle(Vector3(1.3, 3.2, 9.4), 0.16, true, 2.2, 0.9)
	# Arco escuro do andar de cima
	p.poly3([Vector3(-1.2, 2.4, 9.48), Vector3(-2.4, 2.4, 9.48), Vector3(-2.4, 4.2, 9.48), Vector3(-1.2, 4.2, 9.48)], Color(0.01, 0.01, 0.01), false)
	p.poly3([Vector3(1.2, 2.4, 9.48), Vector3(2.4, 2.4, 9.48), Vector3(2.4, 4.2, 9.48), Vector3(1.2, 4.2, 9.48)], Color(0.01, 0.01, 0.01), false)
	_stairs(wood)
	# Portas laterais
	var lib_open := State.has("chave_osso")
	var dining := p.door_side(-4, 4.2, 1.3, 2.4, wood, false)
	var library := p.door_side(4, 4.6, 1.3, 2.4, wood, false)
	# Lustre
	p.chandelier(Vector3(0, 3.7, 5.2), 5.2)
	# Mesinha com a Prancheta
	p.box(2.0, 2.7, 0.0, 0.7, 3.3, 3.9, Color(0.24, 0.13, 0.08))
	p.poly3([Vector3(2.1, 0.71, 3.35), Vector3(2.6, 0.71, 3.35), Vector3(2.6, 0.71, 3.85), Vector3(2.1, 0.71, 3.85)], Color(0.62, 0.5, 0.32))
	var board := p.rect_of([Vector3(2.0, 0.0, 3.3), Vector3(2.7, 0.75, 3.9)])
	_board_marks(board)
	p.candle(Vector3(2.6, 0.71, 3.45), 0.12, true, 1.5, 0.7)
	# Sangue que o retrato chora depois do primeiro jantar.
	if State.is_solved("ceia") and State.gore:
		for k in 2:
			var eye := portrait_rect.position + Vector2(portrait_rect.size.x * (0.42 + k * 0.16), portrait_rect.size.y * 0.42)
			draw_rect(Rect2(eye, Vector2(1, portrait_rect.size.y * 0.5 + k * 3)), Color(0.55, 0.0, 0.02))
	# Hotspots (ordem: os de trás primeiro)
	hot(Rect2(stairs_top.x - 60, stairs_top.y - 10, 120, 70), "locked", "locked:stairs", "Escadaria")
	hot(portrait_rect, "voice", "event:portrait", "Retrato")
	hot(dining, "walk", "go:dining", "Sala de jantar")
	if lib_open:
		hot(library, "walk", "go:library", "Biblioteca")
	else:
		hot(library, "locked", "locked:library", "Biblioteca")
	hot(board.grow(6), "voice", "event:planchette", "A Prancheta")
	hot_back("go:foyer_door", "Virar-se")


func _stairs(wood: Color) -> void:
	var steps := 12
	var carpet := Color(0.42, 0.06, 0.08)
	for k in steps:
		var i := steps - 1 - k
		var z0 := 5.6 + i * 0.3
		var y1 := (i + 1) * 0.2
		p.box(-1.7, 1.7, 0.0, y1, z0, 9.5, wood.darkened(0.1), wood.lightened(0.08))
		p.box(-0.8, 0.8, y1 - 0.2, y1 + 0.01, z0 - 0.01, z0 + 0.3, carpet, carpet.lightened(0.15))
	# Corrimãos
	for side in [-1.0, 1.0]:
		var x: float = 1.75 * side
		p.line3(Vector3(x, 1.0, 5.4), Vector3(x, 3.4, 9.0), wood.lightened(0.25), 2.0)
		for k in 9:
			var zz := 5.6 + k * 0.4
			var yy := 1.0 + (zz - 5.4) / 3.6 * 2.4
			p.line3(Vector3(x, (zz - 5.6) / 0.3 * 0.2, zz), Vector3(x, yy, zz), wood, 1.0)
		p.box(x - 0.1, x + 0.1, 0.0, 1.2, 5.3, 5.5, wood.lightened(0.15))
	stairs_top = p.proj(Vector3(0, 2.4, 9.3))


func _board_marks(r: Rect2) -> void:
	# Letras da mesa girante: só pontinhos de latão vistos de longe.
	var c := r.get_center() + Vector2(0, -r.size.y * 0.32)
	for i in 9:
		draw_rect(Rect2(c + Vector2(-10 + i * 2.5, -1), Vector2(1, 1)), Color(0.15, 0.1, 0.05))


func paint_live(o: Node2D) -> void:
	# Os olhos do retrato seguem o cursor.
	if portrait_rect.size.x <= 0.0:
		return
	var c := portrait_rect.get_center() + Vector2(0, -portrait_rect.size.y * 0.06)
	var s := portrait_rect.size.x / 40.0
	var m := get_viewport().get_mouse_position()
	var look := ((m - c) / 200.0).limit_length(1.0) * s * 0.8
	for dx in [-3.0, 3.0]:
		var e: Vector2 = c + Vector2(dx, -2) * s
		o.draw_rect(Rect2(e - Vector2(s, s * 0.6), Vector2(s * 2, s * 1.2)), Color(0.78, 0.72, 0.6))
		o.draw_rect(Rect2((e + look).round() - Vector2(0.5, 0.5) * s, Vector2(s, s)), Color(0.05, 0.02, 0.02) if not State.is_solved("ceia") else Color(0.6, 0.0, 0.0))
	# O vulto no alto da escada (susto agendado).
	if figure_t >= 0.0:
		figure_t += get_process_delta_time()
		var a := clampf(1.0 - absf(figure_t - 0.9) / 0.9, 0.0, 1.0)
		var b := stairs_top + Vector2(28, -6)
		var col := Color(0.6, 0.95, 0.9, a * 0.55)
		o.draw_rect(Rect2(b + Vector2(-3, -26), Vector2(6, 6)), col)
		o.draw_colored_polygon(PackedVector2Array([b + Vector2(-5, -20), b + Vector2(5, -20), b + Vector2(7, 4), b + Vector2(-7, 4)]), col)
		if figure_t > 1.8:
			figure_t = -1.0


func entered(house) -> void:
	if not State.flag("intro_foyer"):
		State.set_flag("intro_foyer")
		house.subs.say("MORVANT", "Uma médium... Enfim, alguém que escuta.")
		house.subs.say("MORVANT", "Bem-vinda à minha casa, Dália. O jantar está servido há treze anos.")
		house.subs.say("DÁLIA", "Truques de eco. Casas velhas falam pelos canos.")
		house.subs.say("MORVANT", "Então vá até a mesa. Os canos estão com fome.")
		Audio.play("laugh", -8.0, 0.9)
	elif State.is_solved("ceia") and not State.flag("scare_stairs"):
		State.set_flag("scare_stairs")
		figure_t = 0.0
		Audio.play("sting", -6.0)
		State.change_sanity(-6.0)
		house.subs.say("DÁLIA", "...Tinha alguém no alto da escada.")
