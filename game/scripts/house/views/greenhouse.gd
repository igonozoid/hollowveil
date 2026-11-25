extends "res://scripts/house/view.gd"
## Estufa: paredes e teto de vidro com estrutura de ferro, plantas mortas e,
## no canteiro do meio, uma massa de raízes que pulsa como carne.

var bed := Rect2()
var bulbs: Array = []  # posições 2D dos bulbos que pulsam


func _init() -> void:
	id = "greenhouse"
	title = "Estufa"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.4
	p.fog = Color(0.02, 0.03, 0.04)
	p.add_light(Vector3(0, 2.6, 5.0), Color(0.55, 0.65, 1.0), 6.0, 0.55, 0.0, 170.0)
	p.add_light(Vector3(0, 0.8, 5.4), Color(0.9, 0.2, 0.25), 2.4, 0.6 if not State.is_solved("veias") else 0.0, 0.15, 70.0)
	var iron := Color(0.12, 0.13, 0.13)
	var brick := Color(0.3, 0.16, 0.12)
	# Teto de vidro em duas águas
	for side in [-1.0, 1.0]:
		for i in 8:
			var za := 0.4 + i * 1.0
			var zb := za + 1.0
			_pane([Vector3(3.0 * side, 3.2, za), Vector3(0, 4.4, za), Vector3(0, 4.4, zb), Vector3(3.0 * side, 3.2, zb)])
		p.line3(Vector3(3.0 * side, 3.2, 0.4), Vector3(3.0 * side, 3.2, 8.0), iron, 2.0)
	p.line3(Vector3(0, 4.4, 0.4), Vector3(0, 4.4, 8.0), iron, 2.0)
	for i in 9:
		var z := 0.4 + i * 1.0
		p.line3(Vector3(-3, 3.2, z), Vector3(0, 4.4, z), iron, 1.0)
		p.line3(Vector3(3, 3.2, z), Vector3(0, 4.4, z), iron, 1.0)
	# Paredes de vidro sobre mureta de tijolo
	for side in [-1.0, 1.0]:
		var x: float = 3.0 * side
		p.side_wall(x, 0.4, 8.0, 0.0, 0.8, brick, 10)
		for i in 8:
			var za2 := 0.4 + i * 0.95
			_pane([Vector3(x, 0.8, za2), Vector3(x, 0.8, za2 + 0.95), Vector3(x, 3.2, za2 + 0.95), Vector3(x, 3.2, za2)])
			p.line3(Vector3(x, 0.8, za2), Vector3(x, 3.2, za2), iron, 2.0)
		p.line3(Vector3(x, 0.8, 0.4), Vector3(x, 0.8, 8.0), iron, 2.0)
		p.line3(Vector3(x, 2.0, 0.4), Vector3(x, 2.0, 8.0), iron, 1.0)
	# Fundo de vidro
	p.back_wall(8.0, -3, 3, 0, 0.8, brick)
	for i in 4:
		var xa := -3.0 + i * 1.5
		_pane([Vector3(xa, 0.8, 8.0), Vector3(xa + 1.5, 0.8, 8.0), Vector3(xa + 1.5, 3.2, 8.0), Vector3(xa, 3.2, 8.0)])
		p.line3(Vector3(xa, 0.8, 8.0), Vector3(xa, 3.2, 8.0), iron, 2.0)
	p.poly3([Vector3(-3, 3.2, 8.0), Vector3(3, 3.2, 8.0), Vector3(0, 4.4, 8.0)], Color(0.1, 0.12, 0.2), false)
	p.floor_plane(-3, 3, 0.4, 8, 0.0, Color(0.24, 0.24, 0.22), Color(0.16, 0.16, 0.15), "tiles", 12)
	# Bancadas com vasos mortos dos dois lados
	for side in [-1.0, 1.0]:
		var bx: float = 2.3 * side
		p.box(bx - 0.4, bx + 0.4, 0.0, 0.8, 2.0, 7.0, Color(0.22, 0.14, 0.09))
		for k in 6:
			var z2 := 2.4 + k * 0.8
			p.box(bx - 0.15, bx + 0.15, 0.8, 1.05, z2, z2 + 0.25, Color(0.45, 0.24, 0.16))
			var top := p.proj(Vector3(bx, 1.05, z2 + 0.12))
			var hgt := p.scale_at(z2) * (0.25 + 0.15 * ((k * 7) % 3))
			for st in 3:
				draw_line(top, top + Vector2((st - 1) * hgt * 0.4, -hgt), p.shade(Color(0.2, 0.18, 0.1), Vector3(bx, 1.3, z2)), 1.0)
	# Canteiro do meio e a massa de raízes
	p.box(-1.4, 1.4, 0.0, 0.5, 4.4, 6.4, Color(0.3, 0.28, 0.26), Color(0.12, 0.08, 0.06))
	bed = p.box_rect(-1.4, 1.4, 0.0, 1.8, 4.4, 6.4)
	var solved := State.is_solved("veias")
	var root_col := Color(0.35, 0.12, 0.14) if not solved else Color(0.25, 0.22, 0.2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	bulbs.clear()
	for k in 14:
		var base := Vector3(rng.randf_range(-1.2, 1.2), 0.5, rng.randf_range(4.6, 6.2))
		var prev := base
		var hgt2 := rng.randf_range(0.6, 1.6) * (0.5 if solved else 1.0)
		for seg in 5:
			var nxt := prev + Vector3(rng.randf_range(-0.25, 0.25), hgt2 / 5.0, rng.randf_range(-0.15, 0.15))
			p.line3(prev, nxt, root_col.darkened(seg * 0.05), maxf(1.0, 0.06 * p.scale_at(prev.z) * (1.0 - seg * 0.15)))
			prev = nxt
		if k % 2 == 0:
			bulbs.append([p.proj(prev), maxf(2.0, 0.09 * p.scale_at(prev.z))])
	if solved:
		# A mão enterrada que segurava a lente da prancheta.
		var h := p.proj(Vector3(0.2, 0.52, 5.0))
		draw_rect(Rect2(h + Vector2(-4, -3), Vector2(8, 4)), Color(0.55, 0.5, 0.46))
		for f in 4:
			draw_rect(Rect2(h + Vector2(-4 + f * 2, -6), Vector2(1, 3)), Color(0.55, 0.5, 0.46))
		hot(bed, "look", "look:roots_after", "Raízes secas")
	else:
		hot(bed, "puzzle", "puzzle:veias", "As raízes")
	hot_back("go:foyer_door", "Voltar ao saguão")


## Painel de vidro: céu noturno por trás, entra na lista do relâmpago.
func _pane(pts: Array) -> void:
	var c := p.clip(pts)
	if c.size() < 3:
		return
	var p2 := PackedVector2Array()
	var y_avg := 0.0
	for q in c:
		p2.append(p.proj(q))
		y_avg += (q as Vector3).y
	y_avg /= c.size()
	var sky := SKY_BOT.lerp(SKY_TOP, clampf((y_avg - 0.8) / 3.6, 0.0, 1.0)).darkened(0.25)
	draw_colored_polygon(p2, sky)
	glass.append(p2)


func paint_live(o: Node2D) -> void:
	if State.is_solved("veias"):
		return
	# Os bulbos incham no ritmo de um coração.
	var beat := maxf(0.0, sin(t * 7.0)) * maxf(0.0, sin(t * 3.5))
	for b in bulbs:
		var r: float = b[1] * (1.0 + 0.35 * beat)
		o.draw_circle(b[0], r + 2.0, Color(0.8, 0.1, 0.12, 0.15))
		o.draw_circle(b[0], r, Color(0.55, 0.06, 0.1))
		o.draw_circle((b[0] as Vector2) + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(0.9, 0.35, 0.35))
