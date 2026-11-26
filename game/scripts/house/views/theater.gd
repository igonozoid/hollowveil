extends "res://scripts/house/view.gd"
## Teatro Anatômico: uma plateia circular em degraus de madeira escura que
## sobe até a claraboia. Nos degraus, os mortos libertados assistem. No
## centro, sob o luar, a mesa de dissecação e o corpo costurado de Benjamim,
## coberto por um lençol. Morvant espera de pé, do outro lado da mesa.

var seats: Array = []        # [posição 2D, escala, alma]
var table_c := Vector2()
var table_s := 1.0
var host_at := Vector2()
var host_s := 1.0
var twitch_t := -1.0

const SOUL_SEATS := ["ceia", "atlas", "olhos", "partitura", "pele", "sussurros", "vitral"]


func _init() -> void:
	id = "theater"
	title = "Teatro Anatômico"
	music = "sotao"
	grade = "sotao"


func paint() -> void:
	p.cy = 165.0
	p.ambient = 0.42
	p.fog = Color(0.012, 0.012, 0.018)
	p.fog_start = 4.0
	p.fog_len = 9.0
	var wood := Color(0.4, 0.25, 0.15)
	var rail := Color(0.6, 0.42, 0.22)
	p.add_light(Vector3(0, 3.0, 4.6), Color(0.78, 0.86, 1.0), 5.5, 1.3, 0.0, 170.0)
	# Velas no corrimão da primeira fileira.
	for k in 5:
		var a4 := PI * (0.1 + 0.8 * k / 4.0)
		p.candle(Vector3(cos(a4) * 2.75, 1.08, 4.6 + sin(a4) * 2.75), 0.14, true, 2.0, 0.5)
	# Paredes curvas da plateia: anéis de degraus, de trás para a frente.
	for ring in range(5, -1, -1):
		var r := 2.2 + ring * 0.55
		var y := 0.25 + ring * 0.42
		var pts_back: Array = []
		for i in 25:
			var a := PI * i / 24.0
			pts_back.append(Vector3(cos(a) * r, y, 4.6 + sin(a) * r))
		# Face do degrau (a parede de madeira vertical do anel).
		for i in 24:
			var a0: Vector3 = pts_back[i]
			var a1: Vector3 = pts_back[i + 1]
			p.poly3([a0 - Vector3(0, 0.42, 0), a1 - Vector3(0, 0.42, 0), a1, a0], wood.darkened(0.06 * ring))
		# Corrimão.
		for i in 24:
			p.line3(pts_back[i] + Vector3(0, 0.38, 0), pts_back[i + 1] + Vector3(0, 0.38, 0), rail, 1.0)
	# A parede do fundo, acima da última fileira, e a claraboia.
	p.back_wall(9.5, -6, 6, 2.5, 6.0, wood.darkened(0.5))
	var sky := p.proj(Vector3(0, 4.6, 6.5))
	draw_circle(sky, p.scale_at(6.5) * 0.9, Color(0.32, 0.38, 0.5))
	draw_circle(sky + Vector2(8, -4), p.scale_at(6.5) * 0.3, Color(0.82, 0.86, 0.9))
	for k in 8:
		var a2 := TAU * k / 8.0
		draw_line(sky, sky + Vector2(cos(a2), sin(a2)) * p.scale_at(6.5) * 0.9, Color(0.1, 0.1, 0.12), 2.0)
	# O piso da arena.
	p.floor_plane(-2.2, 2.2, 1.0, 6.8, 0.0, Color(0.32, 0.3, 0.28), Color(0.22, 0.2, 0.18), "tiles", 10)
	# Ralo central e o caminho do sangue.
	var drain := p.proj(Vector3(0, 0.0, 3.6))
	draw_circle(drain, 4, Color(0.05, 0.04, 0.04))
	if State.gore:
		for i in 10:
			var bp := p.proj(Vector3(sin(i * 1.3) * 0.2, 0.0, 4.6 - i * 0.1))
			draw_rect(Rect2(bp, Vector2(3, 1)), Color(0.45, 0.0, 0.04))
	# A mesa de dissecação de pedra sob o luar.
	p.box(-0.3, 0.3, 0.0, 0.8, 4.4, 4.8, Color(0.4, 0.4, 0.42))
	p.box(-1.1, 1.1, 0.8, 0.95, 4.2, 5.0, Color(0.55, 0.55, 0.56), Color(0.62, 0.62, 0.64))
	table_c = p.proj(Vector3(0, 0.96, 4.6))
	table_s = p.scale_at(4.6) / 60.0
	# Lugares na plateia (para os mortos libertados).
	seats.clear()
	for k in SOUL_SEATS.size():
		var ring2 := 1 + (k % 3)
		var a3 := PI * (0.18 + 0.64 * k / 6.0)
		var r2 := 2.2 + ring2 * 0.55
		var sp := Vector3(cos(a3) * (r2 - 0.25), 0.25 + ring2 * 0.42, 4.6 + sin(a3) * (r2 - 0.25))
		seats.append([p.proj(sp), p.scale_at(sp.z) / 60.0, SOUL_SEATS[k]])
	host_at = p.proj(Vector3(1.6, 0.0, 4.9))
	host_s = p.scale_at(4.9) / 60.0
	var table_rect := p.rect_of([Vector3(-1.1, 0.8, 4.2), Vector3(1.1, 1.3, 5.0)]).grow(4)
	if State.is_solved("montagem"):
		hot(table_rect, "look", "look:theater_table_after", "A mesa")
	else:
		hot(table_rect, "puzzle", "puzzle:montagem", "O corpo costurado")
	hot(Rect2(host_at - Vector2(16, 70) * host_s, Vector2(32, 70) * host_s), "voice", "event:host_theater", "Ezequiel Morvant")
	hot_back("go:attic", "Voltar ao sótão")


func paint_live(o: Node2D) -> void:
	# Os mortos libertados, sentados na plateia, olhando a mesa.
	for st in seats:
		if not State.is_solved(st[2]):
			continue
		var b: Vector2 = st[0]
		var s: float = st[1]
		var c := Color(0.62, 0.95, 0.9, 0.35 + 0.1 * sin(t * 1.5 + b.x))
		o.draw_rect(Rect2(b + Vector2(-5, -16) * s, Vector2(10, 14) * s), c)
		o.draw_circle(b + Vector2(0, -20) * s, 4.0 * s, c)
		o.draw_rect(Rect2(b + Vector2(-2, -21) * s, Vector2(4, 1) * s), Color(0.02, 0.05, 0.05, 0.8))
	# O corpo sob o lençol: respira, às vezes se contrai.
	var s2 := table_s
	var breath := sin(t * 1.1) * 1.5
	var k := 0.0
	if twitch_t >= 0.0:
		twitch_t += get_process_delta_time()
		k = sin(twitch_t * 40.0) * maxf(0.0, 1.0 - twitch_t)
		if twitch_t > 1.2:
			twitch_t = -1.0
	if not State.is_solved("montagem"):
		var sheet := Color(0.85, 0.84, 0.8)
		o.draw_colored_polygon(PackedVector2Array([table_c + Vector2(-46, -2) * s2, table_c + Vector2(40, -2) * s2, table_c + Vector2(34, -10 - breath) * s2, table_c + Vector2(-10, -14 - breath + k * 3.0) * s2, table_c + Vector2(-40, -10) * s2]), sheet)
		o.draw_rect(Rect2(table_c + Vector2(38, -6 + k * 2.0) * s2, Vector2(14, 5) * s2), Color(0.74, 0.66, 0.6))
		if State.gore:
			o.draw_rect(Rect2(table_c + Vector2(-12, -8) * s2, Vector2(18, 4) * s2), Color(0.5, 0.0, 0.04, 0.8))
	# Morvant, de pé atrás da mesa: silhueta e óculos que brilham.
	if not State.is_solved("montagem"):
		var h := host_at
		var hs := host_s
		o.draw_rect(Rect2(h + Vector2(-7, -54) * hs, Vector2(14, 54) * hs), Color(0.02, 0.02, 0.025))
		o.draw_circle(h + Vector2(0, -60) * hs, 6.0 * hs, Color(0.02, 0.02, 0.025))
		var glint := 0.6 + 0.4 * sin(t * 3.0)
		o.draw_rect(Rect2(h + Vector2(-4, -62) * hs, Vector2(3, 2) * hs), Color(1.0, 0.25, 0.15, glint))
		o.draw_rect(Rect2(h + Vector2(1, -62) * hs, Vector2(3, 2) * hs), Color(1.0, 0.25, 0.15, glint))


func entered(house) -> void:
	if not State.flag("theater_seen"):
		State.set_flag("theater_seen")
		twitch_t = 0.0
		Audio.play("bell", -4.0, 0.7)
		Audio.play("cry", -8.0, 0.75)
		house.subs.say("MORVANT", "Enfim. Uma plateia inteira, médium, e todos vieram por você.")
		house.subs.say("MORVANT", "Benjamim está quase pronto. Falta só alguém que escute. Deite-se na mesa e eu termino a costura.")
		house.subs.say("DÁLIA", "Os mortos na plateia não olham para ele. Olham para as linhas pretas no corpo. Cada uma prende uma coisa que é deles.")
		State.change_sanity(-6.0)
	elif randf() < 0.3:
		twitch_t = 0.0
