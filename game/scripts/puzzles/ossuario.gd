extends "res://scripts/puzzles/puzzle.gd"
## O OSSUÁRIO — a parede de nichos da cripta, 10×10. Os números entalhados
## nas bordas dizem quantos crânios seguidos há em cada linha e coluna (um
## nonograma). Os crânios desenham uma figura. A semente escolhe a figura e
## se ela vem espelhada; todas se resolvem só por linha e coluna, então a
## resposta é única.

const N := 10
const CELL := 20
const ORIGIN := Vector2(262, 96)
const FIGURES := {
	"um crânio": ["..######..", ".########.", "##########", "##..##..##", "##..##..##", "##########", ".###..###.", "..######..", "..#.##.#..", "..######.."],
	"uma chave": [".####.....", "##..##....", "##..##....", ".####.....", "..##......", "..##......", "..####....", "..##......", "..###.....", "..##......"],
	"um caixão": ["...####...", "..######..", ".###..###.", ".###..###.", ".#......#.", ".###..###.", "..##..##..", "..##..##..", "...####...", "...####..."],
	"um olho": ["..........", "...####...", ".########.", "###....###", "##..##..##", "##..##..##", "###....###", ".########.", "...####...", ".........."],
	"uma mão": ["...#.#....", ".#.#.#.#..", ".#.#.#.#..", ".#.#.#.#..", ".#######..", ".#######.#", ".#######.#", "..######.#", "..#######.", "...#####.."],
	"um coração": [".###..###.", "##########", "##########", "##########", ".########.", "..######..", "...####...", "....##....", "..........", ".........."],
}

var figure := ""
var image: Array = []       # 0/1
var grid: Array = []        # 0 vazio, 1 crânio, 2 marcado com giz
var row_clues: Array = []
var col_clues: Array = []
var fixed_rows: Array = []
var paint := -1
var reveal := 0.0


func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = State.puzzle_seed("ossuario")
	pick_figure(rng)
	grid = []
	for i in N * N:
		grid.append(0)
	if State.flag("hint2_ossuario"):
		# A prancheta entalha duas linhas inteiras.
		var rows: Array = range(N)
		for k in 2:
			var r: int = rows[rng.randi() % rows.size()]
			rows.erase(r)
			fixed_rows.append(r)
			for c in N:
				grid[r * N + c] = 1 if image[r * N + c] == 1 else 2
	if State.drafts.has("ossuario"):
		var d: Array = State.drafts["ossuario"]
		if d.size() == N * N:
			for i in N * N:
				if not (i / N) in fixed_rows:
					grid[i] = int(d[i])


func pick_figure(rng: RandomNumberGenerator) -> void:
	var names: Array = FIGURES.keys()
	figure = names[rng.randi() % names.size()]
	var mirror := rng.randi() % 2 == 1
	var rows: Array = FIGURES[figure]
	image = []
	for r in N:
		for c in N:
			var ch: String = rows[r][N - 1 - c] if mirror else rows[r][c]
			image.append(1 if ch == "#" else 0)
	row_clues = []
	col_clues = []
	for r in N:
		var line: Array = []
		for c in N:
			line.append(image[r * N + c])
		row_clues.append(clue(line))
	for c in N:
		var line2: Array = []
		for r in N:
			line2.append(image[r * N + c])
		col_clues.append(clue(line2))


static func clue(line: Array) -> Array:
	var out: Array = []
	var n := 0
	for v in line:
		if v == 1:
			n += 1
		elif n > 0:
			out.append(n)
			n = 0
	if n > 0:
		out.append(n)
	return out


static func hint(level: int) -> String:
	if level == 1:
		return "Comece pelos números grandes: um 8 numa linha de 10 casas obriga as 6 do meio a terem crânio."
	return "A prancheta entalhou duas linhas inteiras do ossuário."


## Resolve só por linha e coluna (para os testes). Devolve a grade ou [] se travar.
static func line_solve(rc: Array, cc: Array) -> Array:
	var g: Array = []
	for i in N * N:
		g.append(-1)
	var changed := true
	while changed:
		changed = false
		for pass_i in 2:
			for k in N:
				var cells: Array = []
				for j in N:
					cells.append(k * N + j if pass_i == 0 else j * N + k)
				var cl: Array = rc[k] if pass_i == 0 else cc[k]
				var known: Array = []
				for i in cells:
					known.append(g[i])
				var fits := _fits(cl, known)
				if fits.is_empty():
					return []
				for j in N:
					if known[j] >= 0:
						continue
					var v: int = fits[0][j]
					var same := true
					for f in fits:
						if f[j] != v:
							same = false
							break
					if same:
						g[cells[j]] = v
						changed = true
	for v in g:
		if v < 0:
			return []
	return g


static func _fits(cl: Array, known: Array) -> Array:
	var out: Array = []
	_place(cl, 0, 0, [], known, out)
	return out


static func _place(cl: Array, i: int, pos: int, cur: Array, known: Array, out: Array) -> void:
	if i == cl.size():
		var line := cur.duplicate()
		while line.size() < N:
			line.append(0)
		for j in N:
			if known[j] >= 0 and known[j] != line[j]:
				return
		out.append(line)
		return
	var rest := 0
	for k in range(i + 1, cl.size()):
		rest += cl[k] + 1
	for s in range(pos, N - rest - cl[i] + 1):
		var line := cur.duplicate()
		while line.size() < s:
			line.append(0)
		for k in cl[i]:
			line.append(1)
		if i < cl.size() - 1:
			line.append(0)
		var ok := true
		for j in line.size():
			if known[j] >= 0 and known[j] != line[j]:
				ok = false
				break
		if ok:
			_place(cl, i + 1, line.size(), line, known, out)


func matches() -> bool:
	for r in N:
		var line: Array = []
		for c in N:
			line.append(1 if grid[r * N + c] == 1 else 0)
		if clue(line) != row_clues[r]:
			return false
	for c in N:
		var line2: Array = []
		for r in N:
			line2.append(1 if grid[r * N + c] == 1 else 0)
		if clue(line2) != col_clues[c]:
			return false
	return true


func set_cell(i: int, v: int) -> void:
	if done or (i / N) in fixed_rows or grid[i] == v:
		return
	grid[i] = v
	if v == 1:
		Audio.play("tile", -10.0, randf_range(0.7, 0.9))
	elif v == 2:
		Audio.play("hover", -10.0, 0.7)
	State.drafts["ossuario"] = grid.duplicate()
	if matches():
		State.drafts.erase("ossuario")
		reveal = 0.001
		Audio.play("sting", -6.0, 0.9)
		Audio.play("cry", -6.0, 1.0)
		shake(0.4)
		say("DÁLIA", "Os crânios desenham %s. A parede inteira estremece, e os nichos do meio começam a ceder." % figure)
		finish()


func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseButton:
		if not event.pressed:
			paint = -1
			return
		var i := _cell_at(event.position)
		if i < 0:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			paint = 0 if grid[i] == 1 else 1
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			paint = 0 if grid[i] == 2 else 2
		else:
			return
		set_cell(i, paint)
	elif event is InputEventMouseMotion and paint >= 0:
		var j := _cell_at(event.position)
		if j >= 0:
			set_cell(j, paint)


func _cell_at(pos: Vector2) -> int:
	var c := Vector2i(((pos - ORIGIN) / CELL).floor())
	if c.x < 0 or c.y < 0 or c.x >= N or c.y >= N:
		return -1
	return c.y * N + c.x


func _process(delta: float) -> void:
	super(delta)
	if reveal > 0.0:
		reveal = minf(1.0, reveal + delta * 0.8)


func _line_done(cells: Array, cl: Array) -> bool:
	var line: Array = []
	for i in cells:
		line.append(1 if grid[i] == 1 else 0)
	return clue(line) == cl


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.04))
	var font := get_theme_default_font()
	brass_frame(Rect2(ORIGIN - Vector2(8, 8), Vector2(N * CELL + 16, N * CELL + 16)), 2.0)
	for r in N:
		var cells: Array = []
		for c in N:
			cells.append(r * N + c)
		var ok := _line_done(cells, row_clues[r])
		var txt := " ".join(PackedStringArray(row_clues[r].map(func(v): return str(v)))) if not row_clues[r].is_empty() else "0"
		draw_string(font, Vector2(ORIGIN.x - 116, ORIGIN.y + r * CELL + 14), txt, HORIZONTAL_ALIGNMENT_RIGHT, 100, 10, Color(0.55, 0.5, 0.42) if ok else Color(0.88, 0.8, 0.62))
	for c in N:
		var cells2: Array = []
		for r in N:
			cells2.append(r * N + c)
		var ok2 := _line_done(cells2, col_clues[c])
		var cl: Array = col_clues[c] if not col_clues[c].is_empty() else [0]
		for k in cl.size():
			var y := ORIGIN.y - 12 - (cl.size() - 1 - k) * 11
			draw_string(font, Vector2(ORIGIN.x + c * CELL, y), str(cl[k]), HORIZONTAL_ALIGNMENT_CENTER, CELL, 10, Color(0.55, 0.5, 0.42) if ok2 else Color(0.88, 0.8, 0.62))
	for i in N * N:
		var r := Rect2(ORIGIN + Vector2(i % N, i / N) * CELL, Vector2(CELL, CELL))
		draw_rect(r.grow(-1), Color(0.02, 0.02, 0.025))
		draw_rect(r, Color(0.2, 0.19, 0.2), false, 1.0)
		var v: int = grid[i]
		if v == 1:
			var c := r.get_center()
			var bone := Color(0.78, 0.72, 0.58)
			if reveal > 0.0:
				bone = bone.lerp(Color(1.0, 0.92, 0.7), 0.5 + 0.5 * sin(t * 4.0 + i * 0.1))
			draw_circle(c + Vector2(0, -1), 7, bone)
			draw_rect(Rect2(c + Vector2(-4, 4), Vector2(8, 3)), bone.darkened(0.15))
			draw_rect(Rect2(c + Vector2(-4, -2), Vector2(3, 3)), Color(0.04, 0.03, 0.03))
			draw_rect(Rect2(c + Vector2(1, -2), Vector2(3, 3)), Color(0.04, 0.03, 0.03))
			draw_rect(Rect2(c + Vector2(-1, 2), Vector2(2, 1)), Color(0.04, 0.03, 0.03))
		elif v == 2:
			var c2 := r.get_center()
			draw_line(c2 + Vector2(-4, -4), c2 + Vector2(4, 4), Color(0.8, 0.8, 0.76, 0.6), 1.0)
			draw_line(c2 + Vector2(4, -4), c2 + Vector2(-4, 4), Color(0.8, 0.8, 0.76, 0.6), 1.0)
		if (i / N) in fixed_rows:
			draw_rect(r.grow(-2), Color(0.4, 0.8, 1.0, 0.15))
	for k in range(0, N + 1, 5):
		draw_line(ORIGIN + Vector2(k * CELL, 0), ORIGIN + Vector2(k * CELL, N * CELL), Color(0.45, 0.4, 0.3), 1.0)
		draw_line(ORIGIN + Vector2(0, k * CELL), ORIGIN + Vector2(N * CELL, k * CELL), Color(0.45, 0.4, 0.3), 1.0)
	draw_string(font, Vector2(270, 20), "O OSSUÁRIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(0, 318), "Os números contam os crânios seguidos em cada linha e coluna.", HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color(0.75, 0.68, 0.58))
	draw_string(font, Vector2(0, 330), "Clique (ou arraste) para pôr um crânio · botão direito marca o nicho vazio com giz", HORIZONTAL_ALIGNMENT_CENTER, 640, 8, Color(0.55, 0.52, 0.46))
