extends "res://scripts/house/view.gd"
## Capela subterrânea: bancos, um altar de pedra com relicário e, no alto do
## fundo, uma rosácea de vidro, apagada até o coração de Anselmo voltar ao altar.

const Cellar := preload("res://scripts/house/views/cellar.gd")
const GLASS := [Color(0.75, 0.1, 0.14), Color(0.16, 0.28, 0.8), Color(0.92, 0.66, 0.16), Color(0.18, 0.6, 0.3), Color(0.5, 0.22, 0.66), Color(0.9, 0.88, 0.8)]

var rose_c := Vector2()
var rose_r := 10.0
var priest_at := Vector2()
var priest_s := 1.0
var reliquary := Vector2()


func _init() -> void:
	id = "chapel"
	title = "Capela"
	music = "poroes"
	grade = "poroes"
	lantern = true


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.32
	p.fog = Color(0.012, 0.012, 0.025)
	p.fog_start = 3.5
	p.fog_len = 10.0
	var stone := Color(0.32, 0.3, 0.32)
	var wood := Color(0.26, 0.15, 0.09)
	var lit := State.flag("heart_placed")
	var freed := State.is_solved("vitral")
	p.add_light(Vector3(0, 1.4, 7.4), Color(1.0, 0.64, 0.34), 4.0, 1.1, 0.3, 120.0)
	if lit:
		p.add_light(Vector3(0, 3.0, 8.6), Color(0.9, 0.5, 0.6) if not freed else Color(0.8, 0.85, 1.0), 4.0, 0.8, 0.1, 110.0)
	Cellar.vault(p, -2.6, 2.6, 2.6, 1.3, 0.4, 9.0, stone.darkened(0.2), 10)
	p.back_wall(9.0, -2.6, 2.6, 0.0, 4.0, stone)
	for side in [-2.6, 2.6]:
		p.side_wall(side, 0.4, 9.0, 0.0, 2.6, stone, 14)
		Cellar.stones_side(p, side, 0.4, 9.0, 2.6, stone.darkened(0.45))
	p.floor_plane(-2.6, 2.6, 0.4, 9.0, 0.0, Color(0.22, 0.2, 0.2), Color(0.16, 0.15, 0.15), "tiles", 14)
	# Lápides no chão da nave.
	for k in 3:
		var z := 3.0 + k * 1.4
		p.poly3([Vector3(-0.35, 0.004, z), Vector3(0.35, 0.004, z), Vector3(0.35, 0.004, z + 0.9), Vector3(-0.35, 0.004, z + 0.9)], Color(0.34, 0.32, 0.3))
		p.line3(Vector3(-0.2, 0.005, z + 0.45), Vector3(0.2, 0.005, z + 0.45), Color(0.18, 0.16, 0.16), 1.0)
	# Rosácea no alto do fundo.
	rose_c = p.proj(Vector3(0, 3.0, 8.99))
	rose_r = p.scale_at(9.0) * 0.75
	draw_circle(rose_c, rose_r + 3, p.shade(stone.darkened(0.3), Vector3(0, 3.0, 8.9)))
	for ring in 2:
		var r0 := rose_r * (0.45 if ring == 0 else 1.0)
		var r1 := rose_r * (0.0 if ring == 0 else 0.45)
		for i in 12:
			var a0 := TAU * i / 12.0
			var a1 := TAU * (i + 1) / 12.0
			var col: Color = GLASS[(i + ring * 3) % 6]
			if not lit:
				col = Color(0.03, 0.028, 0.035).lerp(col, 0.04)
			elif not freed:
				col = col.darkened(0.55)
			var pts := PackedVector2Array([rose_c + Vector2(cos(a0), sin(a0)) * r1, rose_c + Vector2(cos(a0), sin(a0)) * r0, rose_c + Vector2(cos(a1), sin(a1)) * r0, rose_c + Vector2(cos(a1), sin(a1)) * r1])
			if r1 == 0.0:
				pts = PackedVector2Array([rose_c, rose_c + Vector2(cos(a0), sin(a0)) * r0, rose_c + Vector2(cos(a1), sin(a1)) * r0])
			draw_colored_polygon(pts, col)
			draw_line(rose_c + Vector2(cos(a0), sin(a0)) * r1, rose_c + Vector2(cos(a0), sin(a0)) * r0, Color(0.05, 0.04, 0.04), 1.0)
		draw_arc(rose_c, r0, 0, TAU, 32, Color(0.05, 0.04, 0.04), 1.0)
	# Crucifixo de ferro sobre o altar.
	p.line3(Vector3(0, 1.4, 8.95), Vector3(0, 2.2, 8.95), Color(0.2, 0.18, 0.16), 3.0)
	p.line3(Vector3(-0.25, 1.95, 8.95), Vector3(0.25, 1.95, 8.95), Color(0.2, 0.18, 0.16), 3.0)
	# Altar de pedra com toalha e velas.
	p.box(-1.1, 1.1, 0.0, 1.0, 7.6, 8.3, Color(0.5, 0.48, 0.44), Color(0.82, 0.8, 0.76))
	p.poly3([Vector3(-1.1, 1.0, 7.6), Vector3(1.1, 1.0, 7.6), Vector3(1.1, 0.7, 7.6), Vector3(-1.1, 0.7, 7.6)], Color(0.8, 0.78, 0.74))
	if freed and State.gore:
		p.poly3([Vector3(-0.5, 1.0, 7.6), Vector3(0.3, 1.0, 7.6), Vector3(0.2, 0.55, 7.6), Vector3(-0.4, 0.62, 7.6)], Color(0.45, 0.0, 0.04))
	for dx in [-0.9, -0.6, 0.6, 0.9]:
		p.candle(Vector3(dx, 1.0, 7.95), 0.24, true, 2.4, 0.5)
	# Relicário de vidro no centro do altar.
	p.box(-0.18, 0.18, 1.0, 1.32, 7.85, 8.1, Color(0.6, 0.5, 0.26), Color(0.7, 0.6, 0.3))
	reliquary = p.proj(Vector3(0, 1.16, 7.85))
	var altar := p.box_rect(-1.1, 1.1, 0.0, 1.4, 7.6, 8.3)
	# Bancos dos dois lados da nave.
	for k in 3:
		var z := 3.6 + k * 1.15
		for side in [-1, 1]:
			var x0 := 0.75 if side > 0 else -2.3
			var x1 := 2.3 if side > 0 else -0.75
			p.box(x0, x1, 0.4, 0.46, z, z + 0.38, wood, wood.lightened(0.12))
			p.box(x0, x1, 0.46, 0.9, z + 0.34, z + 0.42, wood.darkened(0.15))
			for lx in [x0 + 0.1, x1 - 0.1]:
				p.box(lx - 0.03, lx + 0.03, 0.0, 0.4, z + 0.05, z + 0.1, wood.darkened(0.3))
	priest_at = p.proj(Vector3(0.0, 0.0, 7.1))
	priest_s = p.scale_at(7.1) / 60.0
	var rose_rect := Rect2(rose_c - Vector2(rose_r, rose_r), Vector2(rose_r, rose_r) * 2.0)
	if freed:
		hot(rose_rect, "look", "look:rose_after", "A rosácea")
		if State.flag("cripta_open"):
			hot(altar, "walk", "go:crypt", "Descer à cripta")
		else:
			hot(altar, "look", "look:altar_after", "O altar")
	elif lit:
		hot(rose_rect, "puzzle", "puzzle:vitral", "A rosácea")
		hot(altar, "look", "look:reliquary_full", "O relicário")
	else:
		hot(rose_rect, "look", "look:rose_dark", "A rosácea")
		hot(altar, "look", "look:reliquary_empty", "O relicário")
	hot_back("go:cellar", "Voltar à galeria")


func paint_live(o: Node2D) -> void:
	# O coração no relicário bate uma vez a cada tanto.
	if State.flag("heart_placed") and not State.is_solved("vitral"):
		var beat := maxf(0.0, sin(t * 1.6)) ** 8.0
		o.draw_circle(reliquary, 3.0 + beat * 1.5, Color(0.55, 0.04, 0.08))
		o.draw_circle(reliquary + Vector2(-1, -1), 1.0, Color(0.85, 0.3, 0.3))
	# Anselmo, de joelhos diante do altar, enquanto não for libertado.
	if not State.is_solved("vitral"):
		var s := priest_s
		var bob := sin(t * 1.2) * 0.8
		var c := Color(0.62, 0.95, 0.9, 0.45 + 0.1 * sin(t * 2.0))
		var b := priest_at
		o.draw_rect(Rect2(b + Vector2(-6, -16 + bob) * s, Vector2(12, 16) * s), c)
		o.draw_rect(Rect2(b + Vector2(-7, -3) * s, Vector2(16, 3) * s), c.darkened(0.2))
		o.draw_circle(b + Vector2(0, -21 + bob) * s, 4.0 * s, c)
		o.draw_rect(Rect2(b + Vector2(-1.5, -17 + bob) * s, Vector2(3, 1.5) * s), Color(1, 1, 1, 0.6))
		# Mãos postas, e um buraco escuro no peito.
		o.draw_line(b + Vector2(5, -12 + bob) * s, b + Vector2(8, -17 + bob) * s, c, maxf(1.0, 1.5 * s))
		if State.gore:
			o.draw_circle(b + Vector2(1, -10 + bob) * s, 2.2 * s, Color(0.35, 0.0, 0.03, 0.9))


func entered(house) -> void:
	if not State.flag("chapel_seen"):
		State.set_flag("chapel_seen")
		Audio.play("bell", -4.0, 1.0)
		house.subs.say("ANSELMO", "...requiem aeternam dona eis, Domine... et lux perpetua...")
		house.subs.say("DÁLIA", "Padre? Padre Anselmo? Ele não me ouve. Reza para um altar onde falta alguma coisa.")
	if State.has("coracao") and not State.flag("heart_placed"):
		State.set_flag("heart_placed")
		Audio.play("heart", -2.0, 0.9)
		Audio.play("bell", -8.0, 1.2)
		house.subs.say("DÁLIA", "Coloco o pote no relicário. O coração bate uma vez, forte. A rosácea acende por dentro, vermelha.")
		house.subs.say("ANSELMO", "...miserere... a janela, minha filha... cada cor no seu lugar...")
		queue_redraw()
