extends "res://scripts/puzzles/puzzle.gd"
## A MONTAGEM — Morvant quer que Dália termine o corpo; ela o descostura.
## Cada peça roubada está presa por linhas pretas que se cruzam umas por
## cima das outras. Só dá para cortar uma linha que não tem nenhuma outra
## por cima (como no pega-varetas). Cortar a errada repuxa o corpo. Três
## erros e o corpo se senta: as linhas se refazem noutra ordem. Quando a
## última linha de uma peça sai, ela volta para o dono, na plateia.

const PARTS := [
	["dentes", "os dentes de ouro", "Leocádia", Vector2(320, 86)],
	["olhos", "os olhos", "Benedita", Vector2(320, 66)],
	["dom", "o dom", "Ofélia", Vector2(296, 58)],
	["voz", "a voz", "Celeste", Vector2(320, 110)],
	["coracao", "o coração", "Anselmo", Vector2(334, 146)],
	["pele", "a pele", "Hélio", Vector2(304, 182)],
	["maos", "as mãos", "Tobias", Vector2(238, 196)],
]
const MAX_ERRORS := 3

var rng := RandomNumberGenerator.new()
var threads: Array = []     # [a, b, parte, z, cortada]
var errors := 0
var shake_t := 0.0
var freed: Array = []
var show_free := false
var sit_t := 0.0
var flash_part := -1
var flash_t := 0.0


func build() -> void:
	rng.seed = State.puzzle_seed("montagem")
	show_free = State.flag("hint2_montagem")
	generate()


static func hint(level: int) -> String:
	if level == 1:
		return "Olhe onde as linhas se cruzam: a de cima esconde um pedaço da de baixo. Corte sempre a que não tem nada por cima."
	return "A prancheta faz brilhar as linhas que já podem ser cortadas."


func generate() -> void:
	threads = []
	freed = []
	errors = 0
	var order: Array = []
	for pi in PARTS.size():
		for k in 2:
			order.append(pi)
	# Ordem de cima para baixo sorteada.
	var zs: Array = range(order.size())
	for i in range(zs.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = zs[i]
		zs[i] = zs[j]
		zs[j] = tmp
	for i in order.size():
		var part: int = order[i]
		var c: Vector2 = PARTS[part][3]
		if part == 6 and i % 2 == 1:
			c = Vector2(402, 196)    # a outra mão
		var ang := rng.randf_range(0.0, PI)
		var length := rng.randf_range(80.0, 140.0)
		var off := Vector2(rng.randf_range(-14, 14), rng.randf_range(-10, 10))
		var d := Vector2(cos(ang), sin(ang)) * length * 0.5
		threads.append([c + off - d, c + off + d, part, zs[i], false])


static func _cross(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	return Geometry2D.segment_intersects_segment(a, b, c, d) != null


## Uma linha está livre se nenhuma linha ainda inteira passa por cima dela.
func is_free(i: int) -> bool:
	var ti: Array = threads[i]
	for j in threads.size():
		var tj: Array = threads[j]
		if j == i or tj[4] or int(tj[3]) < int(ti[3]):
			continue
		if _cross(ti[0], ti[1], tj[0], tj[1]):
			return false
	return true


func cut(i: int) -> bool:
	if done or threads[i][4]:
		return false
	if not is_free(i):
		errors += 1
		shake_t = 0.6
		shake(0.4)
		State.change_sanity(-4.0)
		Audio.play("squelch", -4.0, 0.7)
		Audio.play("cry", -10.0, 0.7)
		if errors >= MAX_ERRORS:
			sit_t = 1.5
			Audio.play("scream", -4.0, 0.8)
			Audio.play("laugh", -6.0, 0.9)
			say("MORVANT", "Ele se sentou, médium. Não gosta de ser desfeito. Eu refiz os pontos, do meu jeito.")
			generate()
		else:
			say("MORVANT", ["Essa linha está presa por baixo. Você está machucando o menino.", "Cuidado. Cada ponto errado repuxa a carne dele.", "Por cima, médium. Sempre por cima. Até eu sei disso."][errors % 3])
		return false
	threads[i][4] = true
	Audio.play("crunch", -12.0, 2.0)
	Audio.play("squelch", -14.0, 1.6)
	var part: int = threads[i][2]
	var all_cut := true
	for t2 in threads:
		if t2[2] == part and not t2[4]:
			all_cut = false
	if all_cut:
		freed.append(part)
		flash_part = part
		flash_t = 0.0
		Audio.play("whisper", -6.0, 1.2)
		say("DÁLIA", "%s de %s. Soltei. Na plateia, %s se levanta." % [String(PARTS[part][1]).capitalize(), PARTS[part][2], PARTS[part][2]])
	var left := 0
	for t3 in threads:
		if not t3[4]:
			left += 1
	if left == 0:
		Audio.play("bell", -2.0, 0.8)
		say("DÁLIA", "A última linha. O corpo amolece sobre a mesa, e não é mais ninguém.")
		finish()
	return true


func _thread_at(pos: Vector2) -> int:
	# A de cima ganha quando duas estão perto do clique.
	var best := -1
	var best_z := -1
	for i in threads.size():
		var t1: Array = threads[i]
		if t1[4]:
			continue
		var q := Geometry2D.get_closest_point_to_segment(pos, t1[0], t1[1])
		if q.distance_to(pos) <= 5.0 and int(t1[3]) > best_z:
			best = i
			best_z = int(t1[3])
	return best


func _gui_input(event: InputEvent) -> void:
	if done or sit_t > 0.0 or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var i := _thread_at(event.position)
	if i >= 0:
		cut(i)


func _process(delta: float) -> void:
	super(delta)
	shake_t = maxf(0.0, shake_t - delta)
	sit_t = maxf(0.0, sit_t - delta)
	flash_t += delta


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.02, 0.025))
	var font := get_theme_default_font()
	# A mesa de pedra e o luar.
	draw_rect(Rect2(170, 30, 300, 290), Color(0.38, 0.38, 0.4))
	draw_rect(Rect2(176, 36, 288, 278), Color(0.46, 0.46, 0.48))
	draw_circle(Vector2(320, 170), 170, Color(0.7, 0.8, 1.0, 0.05))
	var jx := sin(t * 50.0) * 2.0 * shake_t + (sin(t * 30.0) * 4.0 if sit_t > 0.0 else 0.0)
	var o := Vector2(jx, -sit_t * 8.0)
	# O corpo: pequeno demais no tronco, grande demais nas mãos.
	var skin := Color(0.78, 0.7, 0.64)
	var dark := skin.darkened(0.25)
	draw_line(Vector2(298, 210) + o, Vector2(292, 296) + o, dark, 18.0)
	draw_line(Vector2(342, 210) + o, Vector2(348, 296) + o, dark, 18.0)
	draw_line(Vector2(288, 112) + o, Vector2(238, 192) + o, skin, 14.0)
	draw_line(Vector2(352, 112) + o, Vector2(402, 192) + o, skin, 14.0)
	draw_colored_polygon(PackedVector2Array([Vector2(282, 104) + o, Vector2(358, 104) + o, Vector2(346, 220) + o, Vector2(294, 220) + o]), skin)
	draw_circle(Vector2(320, 70) + o, 30, skin)
	# A pele tatuada de Hélio, num remendo; as mãos de Tobias, enormes.
	draw_rect(Rect2(Vector2(290, 166) + o, Vector2(30, 34)), Color(0.72, 0.62, 0.56))
	draw_line(Vector2(296, 174) + o, Vector2(312, 192) + o, Color(0.15, 0.2, 0.35), 1.0)
	for hc in [Vector2(238, 196), Vector2(402, 196)]:
		draw_circle(hc + o, 13, skin.darkened(0.1))
		for f in 4:
			draw_line(hc + o, hc + o + Vector2(-9 + f * 6, 16), skin.darkened(0.1), 4.0)
	# Rosto: olhos de vidro, boca com dentes de ouro.
	draw_circle(Vector2(310, 66) + o, 5, Color(0.9, 0.88, 0.82))
	draw_circle(Vector2(330, 66) + o, 5, Color(0.9, 0.88, 0.82))
	draw_circle(Vector2(310 + sin(t) * 1.5, 66) + o, 2, Color(0.15, 0.25, 0.4))
	draw_circle(Vector2(330 + sin(t) * 1.5, 66) + o, 2, Color(0.15, 0.25, 0.4))
	draw_rect(Rect2(Vector2(308, 84) + o, Vector2(24, 5)), Color(0.15, 0.02, 0.02))
	for k in 4:
		draw_rect(Rect2(Vector2(310 + k * 6, 84) + o, Vector2(3, 3)), Color(0.95, 0.78, 0.3))
	# Coração por baixo de uma janela de pele aberta.
	var beat := maxf(0.0, sin(t * 5.0)) ** 6.0
	if not freed.has(4):
		draw_circle(Vector2(334, 146) + o, 7 + beat * 2.0, Color(0.6, 0.04, 0.08))
	if State.gore:
		draw_rect(Rect2(Vector2(300, 222) + o, Vector2(40, 3)), Color(0.5, 0.0, 0.04))
		for k in 5:
			draw_rect(Rect2(Vector2(302 + k * 8, 225) + o, Vector2(1, 4 + (k * 7) % 9)), Color(0.5, 0.0, 0.04))
	# As linhas, de baixo para cima; cada uma com uma borda clara por baixo,
	# para que os cruzamentos mostrem quem passa por cima.
	var idx: Array = range(threads.size())
	idx.sort_custom(func(a, b): return int(threads[a][3]) < int(threads[b][3]))
	for i in idx:
		var th: Array = threads[i]
		if th[4]:
			continue
		var a: Vector2 = th[0] + o
		var b: Vector2 = th[1] + o
		var glow := show_free and is_free(i)
		draw_line(a, b, Color(0.8, 0.74, 0.66) if not glow else Color(0.5, 0.9, 1.0, 0.6 + 0.4 * sin(t * 6.0)), 6.0)
		draw_line(a, b, Color(0.04, 0.03, 0.03), 2.0)
		var dir := (b - a).normalized()
		var n := dir.orthogonal()
		var steps := int(a.distance_to(b) / 9.0)
		for k in steps:
			var pp := a + dir * (k * 9.0 + 4.5)
			draw_line(pp - n * 3.0, pp + n * 3.0, Color(0.04, 0.03, 0.03), 1.0)
	# Peças soltas brilham e somem.
	if flash_part >= 0 and flash_t < 1.5:
		var fp: Vector2 = PARTS[flash_part][3]
		draw_circle(fp + o, 20 + flash_t * 30.0, Color(0.62, 0.95, 0.9, 0.4 * (1.0 - flash_t / 1.5)))
	# Lista das peças e de quem são.
	for pi in PARTS.size():
		var y := 60.0 + pi * 18.0
		var got := freed.has(pi)
		draw_string(font, Vector2(484, y), "%s — %s" % [PARTS[pi][1], PARTS[pi][2]], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.55, 0.95, 0.88) if got else Color(0.7, 0.62, 0.52))
		if got:
			draw_line(Vector2(484, y - 3), Vector2(484 + 120, y - 3), Color(0.55, 0.95, 0.88, 0.5), 1.0)
	for k in MAX_ERRORS:
		draw_rect(Rect2(40 + k * 16, 60, 10, 10), Color(0.6, 0.0, 0.04) if k < errors else Color(0.2, 0.18, 0.18))
	draw_string(font, Vector2(40, 54), "repuxões", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.55, 0.48))
	draw_string(font, Vector2(260, 20), "A MONTAGEM", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(0, 336), "Descosture o corpo. Só corte uma linha que não tenha nenhuma outra por cima.", HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color(0.75, 0.68, 0.58))
