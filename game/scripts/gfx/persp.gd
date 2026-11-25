extends RefCounted
## Perspectiva de um ponto para as vistas em primeira pessoa.
## O cômodo é descrito em metros (x à direita, y para cima, z para dentro);
## a câmera fica em (0, eye, 0) olhando +z. Cada plano é fatiado em faixas
## que escurecem com a distância e esquentam perto das velas: o sombreamento
## em degraus que dá o ar de "pré-renderizado" dos anos 90.

var ci: CanvasItem
var cx := 320.0
var cy := 160.0
var f := 330.0
var eye := 1.6
var near := 0.35
var ambient := 0.42
var fog := Color(0.02, 0.025, 0.03)
var fog_start := 3.0
var fog_len := 14.0
## [pos: Vector3, cor: Color, alcance: float, força: float]
var lights: Array = []
## Luzes 2D a criar depois do desenho: [pos2d, cor, raio, energia, tremulação]
var spots: Array = []
## Chamas animadas: [pos2d, tamanho]
var flames: Array = []
var rng := RandomNumberGenerator.new()


func _init(canvas: CanvasItem = null) -> void:
	ci = canvas


func proj(p: Vector3) -> Vector2:
	var z := maxf(p.z, 0.01)
	return Vector2(cx + p.x * f / z, cy - (p.y - eye) * f / z).round()


func scale_at(z: float) -> float:
	return f / maxf(z, 0.01)


func add_light(p: Vector3, col: Color, reach: float, strength: float, flicker: float = 0.25, radius2d: float = -1.0) -> void:
	lights.append([p, col, reach, strength])
	var r := radius2d if radius2d > 0.0 else reach * scale_at(p.z) * 0.55
	spots.append([proj(p), col, r, strength, flicker])


## Cor sombreada num ponto do espaço.
func shade(col: Color, p: Vector3) -> Color:
	var r := col.r * ambient
	var g := col.g * ambient
	var b := col.b * ambient
	for l in lights:
		var d: float = (l[0] as Vector3).distance_to(p)
		var k: float = clampf(1.0 - d / float(l[2]), 0.0, 1.0)
		k = k * k * float(l[3])
		var lc: Color = l[1]
		r += col.r * lc.r * k
		g += col.g * lc.g * k
		b += col.b * lc.b * k
	var fk := clampf((p.z - fog_start) / fog_len, 0.0, 0.92)
	return Color(lerpf(r, fog.r, fk), lerpf(g, fog.g, fk), lerpf(b, fog.b, fk), col.a)


## Recorta um polígono 3D contra o plano z = near (Sutherland–Hodgman).
func clip(pts: Array) -> Array:
	var out: Array = []
	var n := pts.size()
	for i in n:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % n]
		var ain := a.z >= near
		var bin := b.z >= near
		if ain:
			out.append(a)
		if ain != bin:
			var t := (near - a.z) / (b.z - a.z)
			out.append(a.lerp(b, t))
	return out


func poly3(pts: Array, col: Color, shaded: bool = true) -> void:
	var c := clip(pts)
	if c.size() < 3:
		return
	var center := Vector3.ZERO
	for p in c:
		center += p
	center /= c.size()
	var p2 := PackedVector2Array()
	for p in c:
		p2.append(proj(p))
	ci.draw_colored_polygon(p2, shade(col, center) if shaded else col)


func line3(a: Vector3, b: Vector3, col: Color, width: float = 1.0, shaded: bool = true) -> void:
	var c := clip([a, b])
	if c.size() < 2:
		return
	ci.draw_line(proj(c[0]), proj(c[1]), shade(col, (c[0] + c[1]) * 0.5) if shaded else col, width)


# ---------------------------------------------------------------- planos

## Piso (ou teto) horizontal, fatiado em faixas de profundidade.
## pattern: "boards" | "tiles" | "rug" | "" ; alt = segunda cor do padrão.
func floor_plane(x0: float, x1: float, z0: float, z1: float, y: float, col: Color, alt: Color, pattern: String = "boards", rows: int = 24) -> void:
	var dz := (z1 - z0) / rows
	for i in rows:
		var za := z0 + i * dz
		var zb := za + dz
		if pattern == "tiles":
			var cols := int(round((x1 - x0) / 0.6))
			var dx := (x1 - x0) / cols
			for j in cols:
				var xa := x0 + j * dx
				var c := col if (j + int(floor(za / 0.6))) % 2 == 0 else alt
				poly3([Vector3(xa, y, za), Vector3(xa + dx, y, za), Vector3(xa + dx, y, zb), Vector3(xa, y, zb)], c)
		else:
			poly3([Vector3(x0, y, za), Vector3(x1, y, za), Vector3(x1, y, zb), Vector3(x0, y, zb)], col)
	if pattern == "boards":
		var x := x0
		var k := 0
		while x <= x1:
			line3(Vector3(x, y, z0), Vector3(x, y, z1), alt, 1.0)
			# Juntas desencontradas das tábuas.
			var zz := z0 + fposmod(k * 1.37, 2.2)
			while zz < z1:
				line3(Vector3(x, y, zz), Vector3(x + 0.22, y, zz), alt, 1.0)
				zz += 2.2
			x += 0.22
			k += 1


## Parede do fundo (z constante).
func back_wall(z: float, x0: float, x1: float, y0: float, y1: float, col: Color) -> void:
	var cols := 10
	var dx := (x1 - x0) / cols
	for j in cols:
		var xa := x0 + j * dx
		poly3([Vector3(xa, y0, z), Vector3(xa + dx, y0, z), Vector3(xa + dx, y1, z), Vector3(xa, y1, z)], col)


## Parede lateral (x constante), fatiada por profundidade.
func side_wall(x: float, z0: float, z1: float, y0: float, y1: float, col: Color, slices: int = 18) -> void:
	var dz := (z1 - z0) / slices
	for i in slices:
		var za := z0 + i * dz
		poly3([Vector3(x, y0, za), Vector3(x, y0, za + dz), Vector3(x, y1, za + dz), Vector3(x, y1, za)], col)


## Papel de parede: listras verticais + medalhões (adamascado barato).
func wallpaper_side(x: float, z0: float, z1: float, y0: float, y1: float, ink: Color, step: float = 0.45) -> void:
	var z := z0
	var k := 0
	while z < z1:
		line3(Vector3(x, y0, z), Vector3(x, y1, z), ink, 1.0)
		if k % 2 == 0:
			var ym := lerpf(y0, y1, 0.55)
			var zm := z + step * 0.5
			poly3([Vector3(x, ym + 0.12, zm), Vector3(x, ym, zm + 0.08), Vector3(x, ym - 0.12, zm), Vector3(x, ym, zm - 0.08)], ink)
		z += step
		k += 1


func wallpaper_back(z: float, x0: float, x1: float, y0: float, y1: float, ink: Color, step: float = 0.45) -> void:
	var x := x0
	var k := 0
	while x < x1:
		line3(Vector3(x, y0, z), Vector3(x, y1, z), ink, 1.0)
		if k % 2 == 0:
			var ym := lerpf(y0, y1, 0.55)
			var xm := x + step * 0.5
			poly3([Vector3(xm, ym + 0.12, z), Vector3(xm + 0.08, ym, z), Vector3(xm, ym - 0.12, z), Vector3(xm - 0.08, ym, z)], ink)
		x += step
		k += 1


## Lambri (painéis de madeira na parte de baixo) numa parede lateral.
func wainscot_side(x: float, z0: float, z1: float, h: float, wood: Color, dark: Color) -> void:
	side_wall(x, z0, z1, 0.0, h, wood)
	line3(Vector3(x, h, z0), Vector3(x, h, z1), dark.lightened(0.25), 2.0)
	var z := z0 + 0.15
	while z + 0.7 < z1:
		var pts := [Vector3(x, 0.15, z), Vector3(x, 0.15, z + 0.6), Vector3(x, h - 0.12, z + 0.6), Vector3(x, h - 0.12, z)]
		poly3(pts, dark)
		z += 0.8


func wainscot_back(z: float, x0: float, x1: float, h: float, wood: Color, dark: Color) -> void:
	back_wall(z, x0, x1, 0.0, h, wood)
	line3(Vector3(x0, h, z), Vector3(x1, h, z), dark.lightened(0.25), 2.0)
	var x := x0 + 0.15
	while x + 0.7 < x1:
		poly3([Vector3(x, 0.15, z), Vector3(x + 0.6, 0.15, z), Vector3(x + 0.6, h - 0.12, z), Vector3(x, h - 0.12, z)], dark)
		x += 0.8


# ---------------------------------------------------------------- objetos

## Caixa sólida: desenha só as faces visíveis da câmera.
func box(x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, front: Color, top: Color = Color(0, 0, 0, 0), side: Color = Color(0, 0, 0, 0)) -> void:
	if top.a == 0.0:
		top = front.lightened(0.12)
	if side.a == 0.0:
		side = front.darkened(0.25)
	if y1 < eye:
		poly3([Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1)], top)
	elif y0 > eye:
		poly3([Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1)], side.darkened(0.2))
	if x0 > 0.0:
		poly3([Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0)], side)
	elif x1 < 0.0:
		poly3([Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0)], side)
	poly3([Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0)], front)


## Retângulo na tela de um conjunto de pontos 3D (para hotspots).
func rect_of(pts: Array) -> Rect2:
	var r := Rect2(proj(pts[0]), Vector2.ZERO)
	for p in pts:
		r = r.expand(proj(p))
	return r


func box_rect(x0: float, x1: float, y0: float, y1: float, z0: float, z1: float) -> Rect2:
	return rect_of([Vector3(x0, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z1), Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3(x1, y1, z1)])


## Porta numa parede do fundo. Devolve o retângulo de tela.
func door_back(xc: float, z: float, w: float, h: float, wood: Color, open: bool = false, arch: bool = true) -> Rect2:
	var x0 := xc - w * 0.5
	var x1 := xc + w * 0.5
	var frame := wood.lightened(0.18)
	poly3([Vector3(x0 - 0.12, 0, z), Vector3(x1 + 0.12, 0, z), Vector3(x1 + 0.12, h + 0.12, z), Vector3(x0 - 0.12, h + 0.12, z)], frame)
	if arch:
		_arch_back(xc, z, w * 0.5 + 0.12, h + 0.12, frame)
	var inner := Color(0.01, 0.01, 0.012) if open else wood
	poly3([Vector3(x0, 0, z), Vector3(x1, 0, z), Vector3(x1, h, z), Vector3(x0, h, z)], inner, not open)
	if arch:
		_arch_back(xc, z, w * 0.5, h, inner, not open)
	if not open:
		for i in 2:
			var px0 := x0 + 0.1 + i * (w * 0.5)
			var px1 := px0 + w * 0.5 - 0.2
			poly3([Vector3(px0, 0.2, z), Vector3(px1, 0.2, z), Vector3(px1, h * 0.45, z), Vector3(px0, h * 0.45, z)], wood.darkened(0.3))
			poly3([Vector3(px0, h * 0.52, z), Vector3(px1, h * 0.52, z), Vector3(px1, h - 0.15, z), Vector3(px0, h - 0.15, z)], wood.darkened(0.3))
		poly3([Vector3(x1 - 0.16, 0.95, z), Vector3(x1 - 0.08, 0.95, z), Vector3(x1 - 0.08, 1.03, z), Vector3(x1 - 0.16, 1.03, z)], Color(0.8, 0.62, 0.3))
	var top := h + (w * 0.5 if arch else 0.0)
	return rect_of([Vector3(x0, 0, z), Vector3(x1, top, z)])


func _arch_back(xc: float, z: float, r: float, base_y: float, col: Color, shaded: bool = true) -> void:
	var pts: Array = []
	for i in 13:
		var a := PI * i / 12.0
		pts.append(Vector3(xc + cos(a) * r, base_y + sin(a) * r * 0.75, z))
	poly3(pts, col, shaded)


## Porta numa parede lateral (x constante), centrada em zc.
func door_side(x: float, zc: float, w: float, h: float, wood: Color, open: bool = false) -> Rect2:
	var z0 := zc - w * 0.5
	var z1 := zc + w * 0.5
	var frame := wood.lightened(0.18)
	poly3([Vector3(x, 0, z0 - 0.12), Vector3(x, 0, z1 + 0.12), Vector3(x, h + 0.15, z1 + 0.12), Vector3(x, h + 0.15, z0 - 0.12)], frame)
	var inner := Color(0.01, 0.01, 0.012) if open else wood
	poly3([Vector3(x, 0, z0), Vector3(x, 0, z1), Vector3(x, h, z1), Vector3(x, h, z0)], inner, not open)
	if not open:
		poly3([Vector3(x, 0.2, z0 + 0.1), Vector3(x, 0.2, z1 - 0.1), Vector3(x, h * 0.45, z1 - 0.1), Vector3(x, h * 0.45, z0 + 0.1)], wood.darkened(0.3))
		poly3([Vector3(x, h * 0.52, z0 + 0.1), Vector3(x, h * 0.52, z1 - 0.1), Vector3(x, h - 0.15, z1 - 0.1), Vector3(x, h - 0.15, z0 + 0.1)], wood.darkened(0.3))
		var hz := z0 + 0.12 if x > 0 else z1 - 0.12
		poly3([Vector3(x, 0.95, hz), Vector3(x, 0.95, hz + 0.06), Vector3(x, 1.03, hz + 0.06), Vector3(x, 1.03, hz)], Color(0.8, 0.62, 0.3))
	return rect_of([Vector3(x, 0, z0), Vector3(x, h, z1)])


## Janela na parede do fundo, com céu de luar e caixilhos. Devolve os pontos 2D
## do vidro (para o clarão do relâmpago).
func window_back(xc: float, z: float, w: float, y0: float, h: float, frame: Color, sky_top: Color, sky_bot: Color) -> PackedVector2Array:
	var x0 := xc - w * 0.5
	var x1 := xc + w * 0.5
	poly3([Vector3(x0 - 0.1, y0 - 0.12, z), Vector3(x1 + 0.1, y0 - 0.12, z), Vector3(x1 + 0.1, y0 + h + 0.1, z), Vector3(x0 - 0.1, y0 + h + 0.1, z)], frame)
	var steps := 8
	for i in steps:
		var ya := y0 + h * i / steps
		var yb := y0 + h * (i + 1) / steps
		poly3([Vector3(x0, ya, z), Vector3(x1, ya, z), Vector3(x1, yb, z), Vector3(x0, yb, z)], sky_bot.lerp(sky_top, float(i) / steps), false)
	# Silhueta de árvores mortas lá fora.
	rng.seed = int(xc * 100.0 + z * 10.0)
	for k in 4:
		var tx := lerpf(x0, x1, rng.randf())
		var th := rng.randf_range(0.3, 0.8) * h
		line3(Vector3(tx, y0, z), Vector3(tx + rng.randf_range(-0.1, 0.1), y0 + th, z), Color(0.02, 0.02, 0.03), 1.0, false)
		line3(Vector3(tx, y0 + th * 0.6, z), Vector3(tx + rng.randf_range(-0.25, 0.25), y0 + th * 0.85, z), Color(0.02, 0.02, 0.03), 1.0, false)
	line3(Vector3(xc, y0, z), Vector3(xc, y0 + h, z), frame, 2.0)
	for i in 3:
		var yy := y0 + h * (i + 1) / 4.0
		line3(Vector3(x0, yy, z), Vector3(x1, yy, z), frame, 1.0)
	var glass := PackedVector2Array([proj(Vector3(x0, y0, z)), proj(Vector3(x1, y0, z)), proj(Vector3(x1, y0 + h, z)), proj(Vector3(x0, y0 + h, z))])
	spots.append([proj(Vector3(xc, y0 + h * 0.5, z)), Color(0.45, 0.55, 0.85), w * scale_at(z) * 0.9, 0.35, 0.0])
	return glass


func window_side(x: float, zc: float, w: float, y0: float, h: float, frame: Color, sky_top: Color, sky_bot: Color) -> PackedVector2Array:
	var z0 := zc - w * 0.5
	var z1 := zc + w * 0.5
	poly3([Vector3(x, y0 - 0.12, z0 - 0.1), Vector3(x, y0 - 0.12, z1 + 0.1), Vector3(x, y0 + h + 0.1, z1 + 0.1), Vector3(x, y0 + h + 0.1, z0 - 0.1)], frame)
	var steps := 8
	for i in steps:
		var ya := y0 + h * i / steps
		var yb := y0 + h * (i + 1) / steps
		poly3([Vector3(x, ya, z0), Vector3(x, ya, z1), Vector3(x, yb, z1), Vector3(x, yb, z0)], sky_bot.lerp(sky_top, float(i) / steps), false)
	line3(Vector3(x, y0, zc), Vector3(x, y0 + h, zc), frame, 2.0)
	for i in 3:
		var yy := y0 + h * (i + 1) / 4.0
		line3(Vector3(x, yy, z0), Vector3(x, yy, z1), frame, 1.0)
	var glass := PackedVector2Array([proj(Vector3(x, y0, z0)), proj(Vector3(x, y0, z1)), proj(Vector3(x, y0 + h, z1)), proj(Vector3(x, y0 + h, z0))])
	spots.append([proj(Vector3(x, y0 + h * 0.5, zc)), Color(0.45, 0.55, 0.85), w * scale_at(zc) * 0.8, 0.3, 0.0])
	return glass


## Vela de pé (com luz). Devolve a posição 2D da chama.
func candle(p: Vector3, h: float = 0.18, lit: bool = true, reach: float = 2.6, strength: float = 1.1) -> Vector2:
	var w := 0.025
	poly3([Vector3(p.x - w, p.y, p.z), Vector3(p.x + w, p.y, p.z), Vector3(p.x + w, p.y + h, p.z), Vector3(p.x - w, p.y + h, p.z)], Color(0.86, 0.8, 0.66), false)
	var tip := Vector3(p.x, p.y + h + 0.03, p.z)
	if lit:
		add_light(tip, Color(1.0, 0.62, 0.28), reach, strength, 0.3)
		flames.append([proj(tip), maxf(1.0, 0.06 * scale_at(p.z))])
	return proj(tip)


## Castiçal de três braços.
func candelabra(p: Vector3, lit: bool = true) -> void:
	var brass := Color(0.62, 0.46, 0.22)
	line3(p, p + Vector3(0, 0.3, 0), brass, maxf(1.0, 0.03 * scale_at(p.z)))
	line3(p + Vector3(-0.14, 0.3, 0), p + Vector3(0.14, 0.3, 0), brass, maxf(1.0, 0.02 * scale_at(p.z)))
	for dx in [-0.14, 0.0, 0.14]:
		candle(p + Vector3(dx, 0.3, 0), 0.14, lit, 2.4, 0.55)


## Quadro na parede do fundo. kind: "host" (Morvant), "woman", "land".
func portrait_back(xc: float, z: float, w: float, y0: float, h: float, kind: String) -> Rect2:
	var gold := Color(0.6, 0.44, 0.2)
	var x0 := xc - w * 0.5
	var x1 := xc + w * 0.5
	poly3([Vector3(x0 - 0.08, y0 - 0.08, z), Vector3(x1 + 0.08, y0 - 0.08, z), Vector3(x1 + 0.08, y0 + h + 0.08, z), Vector3(x0 - 0.08, y0 + h + 0.08, z)], gold)
	poly3([Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y0 + h, z), Vector3(x0, y0 + h, z)], Color(0.1, 0.07, 0.06))
	var r := rect_of([Vector3(x0, y0, z), Vector3(x1, y0 + h, z)])
	if kind != "land":
		draw_figure_2d(r, kind, Vector3(xc, y0 + h * 0.5, z))
	else:
		ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.6), Vector2(r.size.x, r.size.y * 0.4)), shade(Color(0.12, 0.14, 0.08), Vector3(xc, y0, z)))
	return r


## Busto pintado dentro de um retângulo de tela (usado também pelos efeitos).
func draw_figure_2d(r: Rect2, kind: String, at: Vector3 = Vector3(0, 2, 4)) -> void:
	var c := r.get_center()
	var s := r.size.x / 40.0
	var dark := shade(Color(0.08, 0.06, 0.07), at)
	var skin := shade(Color(0.62, 0.5, 0.42), at)
	var coat := shade(Color(0.12, 0.1, 0.12) if kind == "host" else Color(0.32, 0.1, 0.16), at)
	# Ombros
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-17, 22) * s, c + Vector2(-12, 8) * s, c + Vector2(12, 8) * s, c + Vector2(17, 22) * s]), coat)
	# Rosto
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -8) * s, c + Vector2(6, -8) * s, c + Vector2(7, 2) * s, c + Vector2(3, 8) * s, c + Vector2(-3, 8) * s, c + Vector2(-7, 2) * s]), skin)
	if kind == "host":
		# Cabelo engomado, entradas, bigode e óculos redondos.
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -6) * s, c + Vector2(-6, -12) * s, c + Vector2(6, -12) * s, c + Vector2(7, -6) * s, c + Vector2(3, -9) * s, c + Vector2(-3, -9) * s]), dark)
		ci.draw_rect(Rect2(c + Vector2(-4, 3) * s, Vector2(8, 1.5) * s), dark)
		ci.draw_arc(c + Vector2(-3, -2) * s, 2.2 * s, 0, TAU, 10, shade(Color(0.7, 0.6, 0.4), at), maxf(1.0, s * 0.6))
		ci.draw_arc(c + Vector2(3, -2) * s, 2.2 * s, 0, TAU, 10, shade(Color(0.7, 0.6, 0.4), at), maxf(1.0, s * 0.6))
		ci.draw_rect(Rect2(c + Vector2(-1, 8) * s, Vector2(2, 6) * s), shade(Color(0.7, 0.68, 0.64), at))
	else:
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, 4) * s, c + Vector2(-8, -10) * s, c + Vector2(0, -14) * s, c + Vector2(8, -10) * s, c + Vector2(8, 4) * s, c + Vector2(6, -6) * s, c + Vector2(-6, -6) * s]), dark)


## Lustre pendurado (com velas e luz).
func chandelier(p: Vector3, ceiling: float) -> void:
	var brass := Color(0.55, 0.42, 0.2)
	line3(Vector3(p.x, ceiling, p.z), p, brass, 1.0)
	var r := 0.45
	var prev := Vector3.ZERO
	for i in 13:
		var a := TAU * i / 12.0
		var q := p + Vector3(cos(a) * r, -0.05, sin(a) * r * 0.6)
		if i > 0:
			line3(prev, q, brass, maxf(1.0, 0.03 * scale_at(p.z)))
		prev = q
	for i in 6:
		var a2 := TAU * i / 6.0 + 0.3
		candle(p + Vector3(cos(a2) * r, -0.05, sin(a2) * r * 0.6), 0.1, true, 4.5, 0.55)


## Estante com fileiras de livros (frente voltada para o eixo x).
func bookcase_side(x: float, z0: float, z1: float, h: float, wood: Color, seed_i: int) -> void:
	rng.seed = seed_i
	var depth := 0.35 * (1.0 if x < 0 else -1.0)
	var xf := x + depth
	side_wall(x + depth * 0.02, z0, z1, 0.0, h, wood.darkened(0.45), 10)
	var shelves := 6
	for s in shelves:
		var y := 0.15 + s * (h - 0.2) / shelves
		var top_y := y + (h - 0.2) / shelves - 0.06
		var z := z0 + 0.04
		while z < z1 - 0.06:
			var bw := rng.randf_range(0.04, 0.09)
			var bh := rng.randf_range(0.6, 0.95) * (top_y - y)
			var palette := [Color(0.42, 0.12, 0.1), Color(0.18, 0.22, 0.12), Color(0.36, 0.28, 0.16), Color(0.14, 0.16, 0.24), Color(0.3, 0.24, 0.2)]
			var bc: Color = palette[rng.randi() % palette.size()]
			bc = bc.lerp(Color(0.5, 0.45, 0.35), rng.randf() * 0.2)
			poly3([Vector3(xf, y, z), Vector3(xf, y, z + bw), Vector3(xf, y + bh, z + bw), Vector3(xf, y + bh, z)], bc)
			z += bw + 0.008
		poly3([Vector3(x, y - 0.04, z0), Vector3(x, y - 0.04, z1), Vector3(xf, y - 0.04, z1), Vector3(xf, y - 0.04, z0)], wood.lightened(0.1))
		poly3([Vector3(xf, y - 0.06, z0), Vector3(xf, y - 0.06, z1), Vector3(xf, y, z1), Vector3(xf, y, z0)], wood)
	# Laterais da estante
	poly3([Vector3(x, 0, z0), Vector3(xf, 0, z0), Vector3(xf, h, z0), Vector3(x, h, z0)], wood)
	poly3([Vector3(xf, h - 0.08, z0), Vector3(xf, h - 0.08, z1), Vector3(xf, h, z1), Vector3(xf, h, z0)], wood.lightened(0.15))


## Cadeira de espaldar alto vista de frente/de lado.
func chair(p: Vector3, facing_z: bool, wood: Color) -> void:
	var w := 0.22
	box(p.x - w, p.x + w, 0.45, 0.5, p.z - w, p.z + w, wood)
	var back_z := p.z + (w if facing_z else -w)
	if facing_z:
		box(p.x - w, p.x + w, 0.5, 1.25, back_z - 0.04, back_z, wood.darkened(0.1))
	for dx in [-w + 0.03, w - 0.03]:
		box(p.x + dx - 0.02, p.x + dx + 0.02, 0.0, 0.45, p.z - w + 0.02, p.z - w + 0.05, wood.darkened(0.3))
	if not facing_z:
		box(p.x - w, p.x + w, 0.5, 1.25, back_z, back_z + 0.04, wood.darkened(0.1))
