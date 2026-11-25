extends "res://scripts/house/view.gd"
## Cripta da família Morvant: sarcófagos nos dois lados e, no fundo, uma
## parede de nichos com crânios. Diante dela, sobre um pedestal, o caixão
## branco de Benjamim, aberto e vazio.

const Cellar := preload("res://scripts/house/views/cellar.gd")

var wall_rect := Rect2()
var coffin_rect := Rect2()
var hole_c := Vector2()
var hole_s := 1.0
var breath_t := -1.0


func _init() -> void:
	id = "crypt"
	title = "Cripta"
	music = "poroes"
	grade = "poroes"
	lantern = true


func paint() -> void:
	p.cy = 156.0
	p.ambient = 0.34
	p.fog = Color(0.01, 0.012, 0.022)
	p.fog_start = 3.0
	p.fog_len = 9.0
	var stone := Color(0.3, 0.3, 0.32)
	var marble := Color(0.62, 0.6, 0.58)
	var open := State.flag("fundacoes_open")
	p.add_light(Vector3(0, 1.3, 5.6), Color(1.0, 0.64, 0.36), 3.4, 1.0, 0.3, 110.0)
	Cellar.vault(p, -2.4, 2.4, 2.0, 0.9, 0.4, 7.0, stone.darkened(0.25), 10)
	p.back_wall(7.0, -2.4, 2.4, 0.0, 3.0, stone)
	for side in [-2.4, 2.4]:
		p.side_wall(side, 0.4, 7.0, 0.0, 2.0, stone, 12)
		Cellar.stones_side(p, side, 0.4, 7.0, 2.0, stone.darkened(0.45))
	p.floor_plane(-2.4, 2.4, 0.4, 7.0, 0.0, Color(0.2, 0.2, 0.22), Color(0.15, 0.15, 0.17), "tiles", 12)
	# Parede de nichos com crânios: o ossuário (o enigma).
	for row in 6:
		for col in 8:
			var x0 := -1.8 + col * 0.45
			var y0 := 0.9 + row * 0.33
			var hole := open and col >= 3 and col <= 4 and row <= 3
			p.poly3([Vector3(x0, y0, 6.99), Vector3(x0 + 0.38, y0, 6.99), Vector3(x0 + 0.38, y0 + 0.27, 6.99), Vector3(x0, y0 + 0.27, 6.99)], Color(0.03, 0.03, 0.035))
			if hole:
				continue
			if (row * 3 + col * 5) % 4 != 0:
				var sp := Vector3(x0 + 0.19, y0 + 0.12, 6.98)
				var c := p.proj(sp)
				var r := p.scale_at(7.0) * 0.1
				draw_circle(c, r, p.shade(Color(0.74, 0.68, 0.56), sp))
				draw_rect(Rect2(c + Vector2(-r * 0.6, -r * 0.2), Vector2(maxf(1, r * 0.45), maxf(1, r * 0.4))), Color(0.03, 0.02, 0.02))
				draw_rect(Rect2(c + Vector2(r * 0.15, -r * 0.2), Vector2(maxf(1, r * 0.45), maxf(1, r * 0.4))), Color(0.03, 0.02, 0.02))
	wall_rect = p.rect_of([Vector3(-1.8, 0.9, 7.0), Vector3(1.8, 2.9, 7.0)])
	# A passagem aberta: um buraco irregular atrás dos nichos.
	hole_c = p.proj(Vector3(0.0, 1.45, 6.98))
	hole_s = p.scale_at(7.0)
	if open:
		var pts := PackedVector2Array()
		for i in 12:
			var a := TAU * i / 12.0
			var rr := (0.5 + 0.08 * sin(i * 2.7)) * hole_s
			pts.append(hole_c + Vector2(cos(a) * rr * 0.75, sin(a) * rr))
		draw_colored_polygon(pts, Color(0.0, 0.0, 0.0))
	# Sarcófagos dos dois lados, com tampa de mármore.
	for side in [-1, 1]:
		for k in 2:
			var z := 2.9 + k * 1.9
			var x0: float = 1.2 if side > 0 else -2.3
			var x1: float = 2.3 if side > 0 else -1.2
			p.box(x0, x1, 0.0, 0.7, z, z + 1.6, marble.darkened(0.35), marble)
			p.box(x0 - 0.05, x1 + 0.05, 0.7, 0.8, z - 0.05, z + 1.65, marble.darkened(0.1), marble.lightened(0.1))
			var name_at := p.proj(Vector3(x0 if side > 0 else x1, 0.4, z + 0.3))
			draw_string(ThemeDB.fallback_font, name_at + Vector2(-10 if side > 0 else 2, 0), "MORVANT", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, p.shade(Color(0.2, 0.2, 0.2), Vector3(x0, 0.4, z)))
	# Pedestal e o caixãozinho branco, aberto.
	p.box(-0.6, 0.6, 0.0, 0.7, 5.2, 5.9, stone.lightened(0.1), stone.lightened(0.2))
	var white := Color(0.88, 0.86, 0.82)
	p.box(-0.4, 0.4, 0.7, 0.9, 5.3, 5.8, white.darkened(0.2), Color(0.12, 0.1, 0.1))
	p.poly3([Vector3(-0.32, 0.91, 5.36), Vector3(0.32, 0.91, 5.36), Vector3(0.28, 0.91, 5.5), Vector3(-0.28, 0.91, 5.5)], Color(0.75, 0.72, 0.7))
	# A tampa, encostada no pedestal.
	p.poly3([Vector3(0.62, 0.0, 5.25), Vector3(0.62, 0.0, 5.85), Vector3(0.75, 0.75, 5.8), Vector3(0.75, 0.75, 5.3)], white.darkened(0.1))
	p.line3(Vector3(0.69, 0.25, 5.55), Vector3(0.69, 0.55, 5.55), Color(0.5, 0.4, 0.2), 1.0)
	coffin_rect = p.box_rect(-0.6, 0.8, 0.0, 1.0, 5.2, 5.9)
	for dx in [-0.5, 0.5]:
		p.candle(Vector3(dx, 0.7, 5.25), 0.16, true, 2.2, 0.45)
	if State.gore:
		for i in 6:
			var fp := p.proj(Vector3(-0.2 + i * 0.08, 0.0, 4.4 - i * 0.35))
			draw_rect(Rect2(fp, Vector2(2, 1)), p.shade(Color(0.4, 0.0, 0.03), Vector3(0, 0, 4.4)))
	if open:
		hot(Rect2(hole_c - Vector2(0.4, 0.5) * hole_s, Vector2(0.8, 1.0) * hole_s), "walk", "puzzle:labirinto", "Descer às fundações")
		hot(wall_rect.grow(-1), "look", "look:ossuary_after", "O ossuário")
	elif State.is_solved("ossuario"):
		hot(wall_rect, "look", "look:ossuary_after", "O ossuário")
	else:
		hot(wall_rect, "puzzle", "puzzle:ossuario", "Os nichos dos crânios")
	hot(coffin_rect, "look", "look:small_coffin", "O caixão de Benjamim")
	hot_back("go:chapel", "Subir à capela")


func paint_live(o: Node2D) -> void:
	# Do buraco aberto sai um ar frio que mexe a poeira.
	if State.flag("fundacoes_open"):
		for i in 8:
			var k := fmod(t * 0.4 + i * 0.125, 1.0)
			var pos := hole_c + Vector2(sin(t + i * 1.3) * 8.0, -k * 30.0)
			o.draw_rect(Rect2(pos.round(), Vector2(1, 1)), Color(0.7, 0.75, 0.85, 0.4 * (1.0 - k)))
	# Algo respira dentro do caixão vazio.
	if breath_t >= 0.0:
		breath_t += get_process_delta_time()
		var c := p.proj(Vector3(0.0, 0.95, 5.45)) if p else Vector2()
		o.draw_circle(c, 2.0 + breath_t * 6.0, Color(0.85, 0.9, 1.0, maxf(0.0, 0.25 - breath_t * 0.1)))
		if breath_t > 2.5:
			breath_t = -1.0


func entered(house) -> void:
	if not State.flag("crypt_seen"):
		State.set_flag("crypt_seen")
		Audio.play("cry", -6.0)
		breath_t = 0.0
		house.subs.say("DÁLIA", "Um caixão branco do tamanho de uma caixa de sapatos. Aberto. O forro ainda tem a marca de um corpo muito pequeno.")
		house.subs.say("DÁLIA", "E alguém chora. Um bebê. Não daqui: de cima, muito longe, através da pedra.")
		house.subs.say("MORVANT", "Os nichos guardam a família inteira, médium. Conte os crânios. Eles contam uma história.")
		State.change_sanity(-5.0)
	elif randf() < 0.3 + State.madness() * 0.5:
		breath_t = 0.0
		Audio.play("cry", -16.0, 0.9)
