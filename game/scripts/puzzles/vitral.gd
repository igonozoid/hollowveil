extends "res://scripts/puzzles/puzzle.gd"
## O VITRAL — a rosácea da capela, 6×6 pedaços de vidro em seis painéis de
## 2×3. Cada cor aparece uma vez em cada linha, em cada coluna e em cada
## painel. A semente embaralha um vitral completo e tira vidros enquanto a
## resposta continua única.

const SIZE := 6
const CELL := 34
const ORIGIN := Vector2(218, 58)
const COLORS := [Color(0.78, 0.1, 0.14), Color(0.18, 0.32, 0.86), Color(0.95, 0.7, 0.18), Color(0.2, 0.62, 0.32), Color(0.56, 0.24, 0.72), Color(0.92, 0.9, 0.82)]
const NAMES := ["cruz", "peixe", "chave", "cálice", "estrela", "olho"]

var solution: Array = []     # 36 valores 0..5
var grid: Array = []         # 36 valores -1..5
var fixed: Array = []        # bool
var pick := 0
var wrong_t := 0.0
var palette_rects: Array = []


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("vitral")
	generate(rng)
	if State.flag("hint2_vitral"):
		# A prancheta acende mais quatro vidros.
		var empty: Array = []
		for i in 36:
			if not fixed[i]:
				empty.append(i)
		for k in mini(4, empty.size()):
			var j: int = empty[rng.randi() % empty.size()]
			empty.erase(j)
			fixed[j] = true
			grid[j] = solution[j]
	if State.drafts.has("vitral"):
		var d: Array = State.drafts["vitral"]
		if d.size() == 36:
			for i in 36:
				if not fixed[i]:
					grid[i] = int(d[i])
	for k in 6:
		palette_rects.append(Rect2(166 + k * 46, 290, 36, 26))


static func hint(level: int) -> String:
	if level == 1:
		return "Cada cor uma vez por linha, uma vez por coluna e uma vez em cada um dos seis painéis de seis vidros."
	return "A prancheta acendeu mais quatro vidros no lugar certo."


static func box_of(i: int) -> int:
	var r := i / SIZE
	var c := i % SIZE
	return (r / 2) * 2 + c / 3


func generate(rng: RandomNumberGenerator) -> void:
	# Vitral base válido, depois embaralhado: cores, linhas dentro das faixas,
	# faixas, colunas dentro das pilhas e pilhas.
	var base: Array = []
	for r in SIZE:
		for c in SIZE:
			base.append(((r % 2) * 3 + r / 2 + c) % SIZE)
	var sym := _perm(rng, 6)
	var bands := _perm(rng, 3)
	var stacks := _perm(rng, 2)
	var rows: Array = []
	for b in bands:
		var inner := _perm(rng, 2)
		for k in inner:
			rows.append(b * 2 + k)
	var cols: Array = []
	for s in stacks:
		var inner2 := _perm(rng, 3)
		for k in inner2:
			cols.append(s * 3 + k)
	solution = []
	for r in SIZE:
		for c in SIZE:
			solution.append(sym[base[rows[r] * SIZE + cols[c]]])
	# Tira vidros enquanto a solução continuar única (fica com pelo menos 12).
	grid = solution.duplicate()
	var order := _perm(rng, 36)
	var left := 36
	for i in order:
		if left <= 12:
			break
		var keep: int = grid[i]
		grid[i] = -1
		if count_solutions(grid, 2) != 1:
			grid[i] = keep
		else:
			left -= 1
	fixed = []
	for i in 36:
		fixed.append(grid[i] >= 0)


static func _perm(rng: RandomNumberGenerator, n: int) -> Array:
	var a: Array = range(n)
	for i in range(n - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
	return a


static func _ok(g: Array, i: int, v: int) -> bool:
	var r := i / SIZE
	var c := i % SIZE
	var b := box_of(i)
	for j in 36:
		if j == i or g[j] != v:
			continue
		if j / SIZE == r or j % SIZE == c or box_of(j) == b:
			return false
	return true


## Conta soluções até `limit` (retrocesso pela célula com menos opções).
static func count_solutions(g0: Array, limit: int) -> int:
	var g := g0.duplicate()
	return _count(g, limit)


static func _count(g: Array, limit: int) -> int:
	var best := -1
	var best_opts: Array = []
	for i in 36:
		if g[i] >= 0:
			continue
		var opts: Array = []
		for v in 6:
			if _ok(g, i, v):
				opts.append(v)
		if opts.is_empty():
			return 0
		if best < 0 or opts.size() < best_opts.size():
			best = i
			best_opts = opts
			if opts.size() == 1:
				break
	if best < 0:
		return 1
	var n := 0
	for v in best_opts:
		g[best] = v
		n += _count(g, limit - n)
		g[best] = -1
		if n >= limit:
			break
	return n


func conflicts() -> Array:
	var out: Array = []
	for i in 36:
		if grid[i] >= 0 and not _ok(grid, i, grid[i]):
			out.append(i)
	return out


func full() -> bool:
	for v in grid:
		if v < 0:
			return false
	return true


func place(i: int, v: int) -> void:
	if done or fixed[i]:
		return
	grid[i] = v
	Audio.play("tile", -8.0, 1.6 if v >= 0 else 0.8)
	State.drafts["vitral"] = grid.duplicate()
	if full():
		if conflicts().is_empty():
			State.drafts.erase("vitral")
			Audio.play("bell", -2.0, 1.0)
			Audio.play("heart", -4.0, 0.8)
			shake(0.4)
			say("ANSELMO", "...lux perpetua luceat eis... A luz voltou, minha filha. Agora eu me lembro de tudo.")
			finish()
		else:
			wrong_t = 1.2
			Audio.play("ice", -2.0, 0.7)
			Audio.play("wrong", -6.0)
			State.change_sanity(-3.0)
			say("MORVANT", ["O vidro racha onde a cor se repete. Olhe as linhas vermelhas.", "Anselmo também não enxergava direito. Eu dei um jeito nos olhos dele... não, isso foi a cozinheira.", "Errou de novo. O padre reza mais alto quando você erra."][randi() % 3])


func _gui_input(event: InputEvent) -> void:
	if done or not (event is InputEventMouseButton and event.pressed):
		return
	var pos: Vector2 = event.position
	for k in 6:
		if (palette_rects[k] as Rect2).has_point(pos):
			pick = k
			Audio.play("hover", -6.0, 1.2)
			return
	var c := Vector2i(((pos - ORIGIN) / CELL).floor())
	if c.x < 0 or c.y < 0 or c.x >= SIZE or c.y >= SIZE:
		return
	var i := c.y * SIZE + c.x
	if event.button_index == MOUSE_BUTTON_RIGHT:
		place(i, -1)
	elif event.button_index == MOUSE_BUTTON_LEFT:
		place(i, -1 if grid[i] == pick else pick)
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		pick = (pick + 1) % 6
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		pick = (pick + 5) % 6


func _process(delta: float) -> void:
	super(delta)
	wrong_t = maxf(0.0, wrong_t - delta)


func _glyph(c: Vector2, v: int, s: float, col: Color) -> void:
	match v:
		0:  # cruz
			draw_line(c + Vector2(0, -6) * s, c + Vector2(0, 6) * s, col, 2.0)
			draw_line(c + Vector2(-4, -2) * s, c + Vector2(4, -2) * s, col, 2.0)
		1:  # peixe
			draw_arc(c + Vector2(-1, -3) * s, 6.0 * s, 0.6, 2.5, 8, col, 1.5)
			draw_arc(c + Vector2(-1, 3) * s, 6.0 * s, -2.5, -0.6, 8, col, 1.5)
			draw_line(c + Vector2(4, 0) * s, c + Vector2(7, -3) * s, col, 1.5)
			draw_line(c + Vector2(4, 0) * s, c + Vector2(7, 3) * s, col, 1.5)
		2:  # chave
			draw_arc(c + Vector2(-3, 0) * s, 3.0 * s, 0, TAU, 10, col, 1.5)
			draw_line(c + Vector2(0, 0) * s, c + Vector2(7, 0) * s, col, 1.5)
			draw_line(c + Vector2(5, 0) * s, c + Vector2(5, 3) * s, col, 1.5)
		3:  # cálice
			draw_arc(c + Vector2(0, -4) * s, 4.0 * s, 0, PI, 8, col, 1.5)
			draw_line(c + Vector2(0, 0) * s, c + Vector2(0, 5) * s, col, 1.5)
			draw_line(c + Vector2(-3, 5) * s, c + Vector2(3, 5) * s, col, 1.5)
		4:  # estrela
			for k in 5:
				var a := TAU * k / 5.0 - PI / 2.0
				var b := TAU * (k + 2) / 5.0 - PI / 2.0
				draw_line(c + Vector2(cos(a), sin(a)) * 6.0 * s, c + Vector2(cos(b), sin(b)) * 6.0 * s, col, 1.0)
		5:  # olho
			draw_arc(c + Vector2(0, 3) * s, 6.0 * s, -2.6, -0.54, 8, col, 1.5)
			draw_arc(c + Vector2(0, -3) * s, 6.0 * s, 0.54, 2.6, 8, col, 1.5)
			draw_circle(c, 1.6 * s, col)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.025, 0.022, 0.03))
	var font := get_theme_default_font()
	var bad := conflicts() if wrong_t > 0.0 else []
	# Arco gótico de pedra em volta do vitral.
	var frame := Rect2(ORIGIN - Vector2(14, 14), Vector2(SIZE * CELL + 28, SIZE * CELL + 28))
	draw_rect(frame, Color(0.2, 0.19, 0.2))
	draw_colored_polygon(PackedVector2Array([frame.position, frame.position + Vector2(frame.size.x * 0.5, -22), Vector2(frame.end.x, frame.position.y)]), Color(0.2, 0.19, 0.2))
	draw_rect(frame.grow(-6), Color(0.02, 0.02, 0.025))
	var heart := maxf(0.0, sin(t * 1.6)) ** 8.0
	for i in 36:
		var r := Rect2(ORIGIN + Vector2(i % SIZE, i / SIZE) * CELL, Vector2(CELL, CELL))
		var v: int = grid[i]
		if v >= 0:
			var col: Color = COLORS[v]
			# Luz de vela atrás do vidro: pulsa com o coração no relicário.
			var glow := 0.78 + 0.12 * heart + 0.06 * sin(t * 3.0 + i)
			draw_rect(r.grow(-1), Color(col.r * glow, col.g * glow, col.b * glow))
			draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(CELL * 0.35, 3)), Color(1, 1, 1, 0.18))
			_glyph(r.get_center(), v, 1.3, Color(0.06, 0.04, 0.04, 0.85))
		else:
			draw_rect(r.grow(-1), Color(0.05, 0.045, 0.05))
		if fixed[i]:
			draw_rect(r.grow(-2), Color(0.12, 0.1, 0.08), false, 2.0)
			draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(2, 2)), Color(0.7, 0.55, 0.3))
		if i in bad:
			draw_line(r.position + Vector2(4, 6), r.end - Vector2(6, 4), Color(0.9, 0.1, 0.1), 1.0)
			draw_line(Vector2(r.end.x - 5, r.position.y + 4), Vector2(r.position.x + 8, r.end.y - 6), Color(0.9, 0.1, 0.1), 1.0)
		draw_rect(r, Color(0.06, 0.05, 0.05), false, 1.0)
	# Chumbo grosso entre os painéis.
	for k in range(0, SIZE + 1, 3):
		draw_line(ORIGIN + Vector2(k * CELL, 0), ORIGIN + Vector2(k * CELL, SIZE * CELL), Color(0.1, 0.09, 0.08), 3.0)
	for k in range(0, SIZE + 1, 2):
		draw_line(ORIGIN + Vector2(0, k * CELL), ORIGIN + Vector2(SIZE * CELL, k * CELL), Color(0.1, 0.09, 0.08), 3.0)
	# Paleta de vidros soltos.
	for k in 6:
		var pr: Rect2 = palette_rects[k]
		draw_rect(pr, COLORS[k].darkened(0.1))
		_glyph(pr.get_center(), k, 1.1, Color(0.06, 0.04, 0.04, 0.85))
		if k == pick:
			draw_rect(pr.grow(3), Color(0.95, 0.8, 0.45), false, 2.0)
	draw_string(font, Vector2(282, 20), "O VITRAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(0, 284), "Vidro escolhido: " + NAMES[pick], HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.7, 0.62, 0.5))
	draw_string(font, Vector2(0, 328), "Cada cor uma vez por linha, por coluna e por painel. Botão direito tira o vidro.", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.6, 0.55, 0.48))
