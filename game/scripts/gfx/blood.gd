extends Node2D
## Sangue em pixel: gotas com gravidade, manchas que ficam, poças que crescem
## e escorridos que descem devagar. Respeita a opção de gore.

const GRAVITY := 420.0
const MAX_STAINS := 2400

var floor_y := INF
## Superfícies onde a gota gruda no meio do voo: [Rect2]
var walls: Array = []
var drops: Array = []     # [pos, vel, size, col, age]
var stains: Array = []    # [pos, size, col, flat]
var pools: Array = []     # [pos, r, target, col]
var drips: Array = []     # [pos, len, speed, col, max]
var amount_scale := 1.0


static func color(rng_v: float = -1.0) -> Color:
	var v := randf() if rng_v < 0.0 else rng_v
	return Color(0.5, 0.0, 0.02).lerp(Color(0.78, 0.04, 0.05), v)


func enabled() -> bool:
	return State.gore


func spray(pos: Vector2, dir: Vector2, amount: int, speed: float, spread: float = 0.6, size: float = 1.6) -> void:
	if not enabled():
		return
	var base := dir.normalized() if dir.length() > 0.0 else Vector2.UP
	for i in int(amount * amount_scale):
		var a := randf_range(-spread, spread)
		var v := base.rotated(a) * speed * randf_range(0.35, 1.15)
		drops.append([pos + Vector2(randf_range(-1, 1), randf_range(-1, 1)), v, randf_range(0.7, 1.4) * size, color(), 0.0])


func burst(pos: Vector2, amount: int, speed: float = 180.0) -> void:
	spray(pos, Vector2.UP, amount, speed, PI, 1.8)


func pool(pos: Vector2, radius: float) -> void:
	if not enabled():
		return
	pools.append([pos, 1.0, radius, Color(0.42, 0.0, 0.03)])


func drip(pos: Vector2, max_len: float = 30.0) -> void:
	if not enabled():
		return
	drips.append([pos, 0.0, randf_range(4.0, 12.0), color(0.2), max_len])


func stain(pos: Vector2, size: float, flat: bool = false) -> void:
	if not enabled():
		return
	stains.append([pos, size, color(), flat])
	if stains.size() > MAX_STAINS:
		stains.remove_at(0)


func clear() -> void:
	drops.clear()
	stains.clear()
	pools.clear()
	drips.clear()
	queue_redraw()


func _process(delta: float) -> void:
	var i := drops.size() - 1
	while i >= 0:
		var d: Array = drops[i]
		d[4] += delta
		d[1].y += GRAVITY * delta
		d[1] *= 0.995
		d[0] += d[1] * delta
		var p: Vector2 = d[0]
		var landed := false
		if p.y >= floor_y:
			p.y = floor_y
			stains.append([p, d[2] * randf_range(1.2, 2.4), d[3], true])
			landed = true
		else:
			for w: Rect2 in walls:
				if w.has_point(p) and randf() < 0.08:
					stains.append([p, d[2] * 1.3, d[3], false])
					if randf() < 0.25:
						drips.append([p, 0.0, randf_range(3.0, 9.0), d[3], randf_range(6.0, 26.0)])
					landed = true
					break
		if landed or d[4] > 4.0 or p.y > 400.0:
			drops.remove_at(i)
		i -= 1
	for pl in pools:
		pl[1] = move_toward(pl[1], pl[2], delta * 3.0)
	for dr in drips:
		if dr[1] < dr[4]:
			dr[1] += dr[2] * delta
			dr[2] = maxf(1.0, dr[2] - delta * 1.5)
	if stains.size() > MAX_STAINS:
		stains = stains.slice(stains.size() - MAX_STAINS)
	queue_redraw()


func _draw() -> void:
	for pl in pools:
		var c: Vector2 = pl[0]
		var r: float = pl[1]
		draw_set_transform(c, 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, r, pl[3])
		draw_circle(Vector2(-r * 0.3, -r * 0.2), r * 0.35, Color(0.6, 0.05, 0.06, 0.6))
		draw_set_transform(Vector2.ZERO)
	for s in stains:
		var p: Vector2 = s[0]
		var sz: float = s[1]
		if s[3]:
			draw_rect(Rect2(p.x - sz, p.y - 0.5, sz * 2.0, 1.0 + sz * 0.3), s[2])
		else:
			draw_rect(Rect2(p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), s[2])
	for dr in drips:
		var p2: Vector2 = dr[0]
		draw_rect(Rect2(p2.x, p2.y, 1.0, dr[1]), dr[3])
		draw_rect(Rect2(p2.x - 0.5, p2.y + dr[1] - 1.0, 2.0, 2.0), dr[3])
	for d in drops:
		var sz2: float = d[2]
		var v: Vector2 = d[1]
		# Gotas rápidas viram riscos.
		if v.length() > 120.0:
			draw_line(d[0], d[0] - v * 0.012, d[3], maxf(1.0, sz2))
		else:
			draw_rect(Rect2(d[0] - Vector2(sz2, sz2) * 0.5, Vector2(sz2, sz2)), d[3])
