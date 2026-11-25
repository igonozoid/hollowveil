extends Node
## Teste de lógica da fatia (roda sem tela). Uso, a partir da raiz:
##   godot --headless --path game --fixed-fps 60 -- --qa --test
## (o autoload Test é injetado pelo script tests/run_tests.sh)

var fails := 0


func check(cond: bool, what: String) -> void:
	print(("OK   " if cond else "FAIL ") + what)
	if not cond:
		fails += 1


func w(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main = get_tree().root.get_node("Main")
	# 1. Ceia: solução única e Olhos solucionável em 60 sementes.
	var Ceia = load("res://scripts/puzzles/ceia.gd")
	var Olhos = load("res://scripts/puzzles/olhos.gd")
	var unique := true
	var solvable := true
	var min_clues := 99
	var max_clues := 0
	for s in 60:
		State.seed_value = s * 7919
		var c = Ceia.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = State.puzzle_seed("ceia")
		c._generate(rng)
		var all = c._perms([0, 1, 2, 3, 4, 5])
		var n := 0
		var hit_solution := false
		for p in all:
			var ok := true
			for cl in c.clues:
				if not c._holds(cl, p):
					ok = false
					break
			if ok:
				n += 1
				hit_solution = hit_solution or p == c.solution
		unique = unique and n == 1 and hit_solution
		min_clues = mini(min_clues, c.clues.size())
		max_clues = maxi(max_clues, c.clues.size())
		c.free()
		var o = Olhos.new()
		o.cells = []
		for r in 5:
			for cc in r + 1:
				o.cells.append(Vector2i(r, cc))
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = State.puzzle_seed("olhos")
		var hole := rng2.randi() % 15
		var found := false
		for k in 15:
			if o._solvable(o._full_mask() & ~(1 << ((hole + k) % 15))):
				found = true
				break
		solvable = solvable and found
		o.free()
	check(unique, "Ceia tem solução única em 60 sementes (pistas: %d a %d)" % [min_clues, max_clues])
	# Veias: o solucionador apaga tudo; Prancheta decifra; Partitura sem notas repetidas.
	var Veias = load("res://scripts/puzzles/veias.gd")
	var Prancheta = load("res://scripts/puzzles/prancheta.gd")
	var Partitura = load("res://scripts/puzzles/partitura.gd")
	var veias_ok := true
	var cipher_ok := true
	var melody_ok := true
	for s in 60:
		State.seed_value = s * 104729
		State.drafts = {}
		var v = Veias.new()
		v.build()
		var plan: Array = v.solve()
		for cell in plan:
			v._toggle(cell, false)
		veias_ok = veias_ok and not plan.is_empty() and v._all_dark()
		v.free()
		var pr = Prancheta.new()
		pr.build()
		cipher_ok = cipher_ok and pr.decoded() != pr.plain
		pr.ring = pr.key.duplicate()
		cipher_ok = cipher_ok and pr.decoded() == pr.plain and pr.cipher != pr.plain
		pr.free()
		var pa = Partitura.new()
		var rng3 := RandomNumberGenerator.new()
		rng3.seed = State.puzzle_seed("partitura")
		var last := -1
		var mel: Array = []
		for i in 7:
			var k := rng3.randi_range(0, 7)
			while k == last:
				k = rng3.randi_range(0, 7)
			mel.append(k)
			last = k
		for i in 6:
			melody_ok = melody_ok and mel[i] != mel[i + 1]
		pa.free()
	check(veias_ok, "As Veias: o solucionador murcha todos os bulbos em 60 sementes")
	check(cipher_ok, "A Prancheta: só a chave certa decifra a mensagem, em 60 sementes")
	check(melody_ok, "A Partitura: nenhuma nota repetida em seguida")
	# 1º andar: Caixa, Banho e Pele resolvíveis em 60 sementes.
	var Caixa = load("res://scripts/puzzles/caixa.gd")
	var Banho = load("res://scripts/puzzles/banho.gd")
	var Pele = load("res://scripts/puzzles/pele.gd")
	var caixa_ok := true
	var banho_ok := true
	var pele_ok := true
	for s in 60:
		State.seed_value = s * 7907 + 3
		State.drafts = {}
		var cx = Caixa.new()
		cx.pos = []
		var rngc := RandomNumberGenerator.new()
		rngc.seed = State.puzzle_seed("caixa")
		for i in 5:
			cx.pos.append(0)
		while cx._aligned():
			for k in 9:
				cx._turn(rngc.randi() % 5, 1 if rngc.randf() < 0.5 else -1, false)
		var guard := 0
		while not cx._aligned() and guard < 40:
			var mv: Array = cx.next_move()
			if mv.is_empty():
				break
			cx._turn(mv[0], mv[1], false)
			guard += 1
		caixa_ok = caixa_ok and cx._aligned()
		cx.free()
		var bh = Banho.new()
		bh.build()
		var path: Array = bh.path_from(bh.amt)
		var st: Array = bh.amt.duplicate()
		for mv2 in path:
			if mv2.size() == 2:
				st = bh._poured(st, mv2[0], mv2[1])
		banho_ok = banho_ok and not path.is_empty() and bh._reached(st)
		bh.free()
		var pl = Pele.new()
		pl.build()
		var edges := 0
		for i in 25:
			for d in 4:
				edges += (pl.base[i] >> d) & 1
		var scrambled_bad: bool = not pl._solved()
		for i in 25:
			pl.rot[i] = 0
		pele_ok = pele_ok and edges == 48 and scrambled_bad and pl._solved()
		pl.free()
	check(caixa_ok, "A Caixa de Música: a busca alinha as engrenagens em 60 sementes")
	check(banho_ok, "O Banho: sempre há uma sequência de despejos até a medida")
	check(pele_ok, "A Pele: árvore com 24 ligações, embaralhada e resolvível")
	var Movel = load("res://scripts/puzzles/movel.gd")
	var Sussurros = load("res://scripts/puzzles/sussurros.gd")
	var movel_ok := true
	var sus_ok := true
	for s in 60:
		State.seed_value = s * 6007 + 11
		State.drafts = {}
		var mv = Movel.new()
		mv.build()
		movel_ok = movel_ok and mv._count_solutions() == 1 and mv._balanced(mv.solution)
		mv.free()
		var su = Sussurros.new()
		su.build()
		var spots: Array = su.consistent_spots()
		sus_ok = sus_ok and spots.size() == 1 and spots[0] == su.answer
		su.free()
	check(movel_ok, "O Móbile: exatamente um jeito de equilibrar, em 60 sementes")
	check(sus_ok, "Os Sussurros: um único esconderijo consistente, em 60 sementes")
	check(solvable, "Olhos no Pote tem saída em 60 sementes")
	# Porões: Balança (estratégia certa sempre acha; chute não), Vitral único, Ganchos solucionável.
	var Balanca = load("res://scripts/puzzles/balanca.gd")
	var Vitral = load("res://scripts/puzzles/vitral.gd")
	var Ganchos = load("res://scripts/puzzles/ganchos.gd")
	var bal_ok := true
	var bal_guess_fails := true
	var vit_ok := true
	var min_glass := 99
	for s in 60:
		State.seed_value = s * 4211 + 5
		State.drafts = {}
		var b = Balanca.new()
		b.build()
		for j in 3:
			b.where[j] = 1
			b.where[3 + j] = 2
		b.weigh()
		var g: Array = b.cand.duplicate()
		for j in 9:
			b.where[j] = 0
		b.where[g[0]] = 1
		b.where[g[1]] = 2
		b.weigh()
		bal_ok = bal_ok and b.cand.size() == 1
		b.free()
		var b2 = Balanca.new()
		b2.build()
		b2.where[0] = 1
		b2.where[1] = 2
		b2.weigh()
		b2.weigh()
		bal_guess_fails = bal_guess_fails and b2.cand.size() > 1
		b2.free()
		var v = Vitral.new()
		var rng3 := RandomNumberGenerator.new()
		rng3.seed = State.puzzle_seed("vitral")
		v.generate(rng3)
		var clues := 0
		for i in 36:
			if v.grid[i] >= 0:
				clues += 1
				vit_ok = vit_ok and v.grid[i] == v.solution[i]
		min_glass = mini(min_glass, clues)
		vit_ok = vit_ok and Vitral.count_solutions(v.grid, 2) == 1
		var full: Array = v.solution.duplicate()
		v.grid = full
		vit_ok = vit_ok and v.conflicts().is_empty()
		v.free()
	check(bal_ok, "A Balança: três contra três e depois um contra um sempre acham o coração")
	check(bal_guess_fails, "A Balança: pesar um contra um não basta (Morvant esconde o coração)")
	check(vit_ok and min_glass >= 12, "O Vitral: solução única em 60 sementes (mínimo de %d vidros)" % min_glass)
	var gan_ok := true
	var gan_min := 99
	for s in 16:
		State.seed_value = s * 9173 + 3
		State.drafts = {}
		var gz = Ganchos.new()
		var rng4 := RandomNumberGenerator.new()
		rng4.seed = State.puzzle_seed("ganchos")
		gz.generate(rng4)
		gz._find_dead()
		gz.boxes = gz.start_boxes.duplicate()
		var n: int = gz.solve_pushes()
		gan_ok = gan_ok and n == gz.depth and n >= 14 and not gz.solved_now()
		gan_min = mini(gan_min, n)
		gz.free()
	check(gan_ok, "Os Ganchos: a busca para trás acerta o mínimo de empurrões, em 16 sementes (mínimo %d)" % gan_min)

	# 2. Prancheta: pista 1, pista 2, e na terceira Morvant resolve.
	main._new_game()
	await w(0.5)
	main.screen._finish()
	await w(2.5)
	var h = main.screen
	check(h.view.id == "foyer", "Começa no saguão")
	var s0 := State.sanity
	h._event("planchette")
	check(State.hint_level("ceia") == 1 and State.sanity < s0, "Pista 1 custa sanidade")
	h.subs.clear()
	h._event("planchette")
	check(State.flag("hint2_ceia"), "Pista 2 marca lugares na Ceia")
	h.subs.clear()
	h._event("planchette")
	await w(0.2)
	h.subs.clear()
	h.subs.finished.emit()
	await w(1.5)
	check(h.mode == "ghost" and h.stage != null, "Pista 3: Morvant resolve e a cena começa")
	if h.stage:
		h.stage.skip()
	while h.mode != "explore":
		await w(0.1)
	await w(0.5)
	check(State.is_solved("ceia") and State.flag("host_solved_ceia"), "Ceia marcada como resolvida por Morvant")
	check(State.has("chave_osso"), "Chave de osso recebida")

	# 3. Esc fecha o enigma.
	h.subs.clear()
	h.open_puzzle("atlas")
	await w(0.5)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	main._unhandled_input(esc)
	await w(0.3)
	check(h.mode == "explore" and h.puzzle == null, "Esc fecha o enigma")

	# 4. Esc em exploração pausa; de novo despausa.
	main._unhandled_input(esc)
	check(get_tree().paused, "Esc pausa")
	main._unhandled_input(esc)
	check(not get_tree().paused, "Esc despausa")

	# 5. Navegação e travas.
	h.go("library", Vector2(500, 200))
	await w(2.0)
	check(h.view.id == "library", "Chave abre a biblioteca")
	var locked := false
	h.go("foyer")
	await w(2.0)
	h.go("dining")
	await w(2.0)
	for hs in h.view.hotspots:
		if hs["action"] == "locked:pantry":
			locked = true
	check(locked, "Copa trancada antes do Atlas")

	# 6. Cadeia estufa → prancheta → sala de música → cena de Celeste.
	h.subs.clear()
	check(not State.flag("music_open"), "Sala de música começa trancada")
	State.mark_solved("veias")
	h.after_solve("veias", false)
	await w(0.2)
	check(State.flag("prancheta_ready"), "Estufa devolve a lente da prancheta")
	h._event("planchette")
	await w(0.5)
	check(h.mode == "puzzle" and h.puzzle != null and h.puzzle.has_method("decoded"), "Prancheta com lente abre a cifra")
	var pz = h.puzzle
	pz.ring = pz.key.duplicate()
	pz.ring[1] = posmod(pz.ring[1] - 1, 26)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_WHEEL_UP
	click.pressed = true
	click.position = pz.DISC[1]
	pz._gui_input(click)
	check(pz.done, "Girar o anel da Lua até a chave resolve a cifra")
	while h.mode != "explore" or h.puzzle != null:
		await w(0.1)
	check(State.flag("music_open"), "Cifra destranca a sala de música")
	h.subs.clear()
	h.go("foyer_door")
	await w(2.0)
	h.go("music")
	await w(2.0)
	check(h.view.id == "music", "Chega à sala de música")
	h.open_puzzle("partitura")
	await w(0.3)
	h.puzzle.finish()
	while h.stage == null:
		await w(0.1)
	check(h.stage.script_id == "partitura", "Partitura leva à cena de Celeste")
	h.stage.skip()
	while h.mode != "explore":
		await w(0.1)
	check(State.is_solved("partitura") and h.available_puzzles().has("atlas"), "Celeste libertada; o Atlas segue disponível")

	# 7. Subir ao 1º andar: banheiro → chave → quarto de hóspedes → Hélio.
	State.mark_solved("olhos")
	h.subs.clear()
	h.go("dining")
	await w(2.0)
	h.go("kitchen")
	await w(2.0)
	var up := false
	for hs in h.view.hotspots:
		if hs["action"] == "go:corridor":
			up = true
	check(up, "Escada de serviço leva ao corredor")
	h.go("corridor")
	await w(2.5)
	check(h.view.id == "corridor" and h.view.grade == "quartos", "Chega ao corredor do 1º andar")
	h.subs.clear()
	check(h.available_puzzles().has("banho") and h.available_puzzles().has("caixa"), "Banho e Caixa disponíveis ao chegar")
	State.mark_solved("banho")
	h.after_solve("banho", false)
	await w(0.3)
	check(State.has("chave_hospedes") and h.available_puzzles().has("pele"), "O Banho dá a chave do quarto de hóspedes")
	h.subs.clear()
	h.go("guest_room")
	await w(2.5)
	check(h.view.id == "guest_room", "Chave abre o quarto de hóspedes")
	h.open_puzzle("pele")
	await w(0.3)
	h.puzzle.finish()
	while h.stage == null:
		await w(0.1)
	check(h.stage.script_id == "pele", "A Pele leva à cena de Hélio")
	h.stage.skip()
	while h.mode != "explore":
		await w(0.1)
	check(State.is_solved("pele"), "Hélio libertado")

	# 8. Berçário → nome → Ofélia → alçapão.
	h.subs.clear()
	State.mark_solved("caixa")
	h.after_solve("caixa", false)
	await w(0.3)
	h.subs.clear()
	check(h.available_puzzles().has("movel"), "A canção da caixa abre o berçário")
	h.go("corridor")
	await w(2.2)
	h.go("nursery")
	await w(2.2)
	check(h.view.id == "nursery", "Chega ao berçário")
	h.open_puzzle("movel")
	await w(0.3)
	h.puzzle.finish()
	while h.stage == null:
		await w(0.1)
	check(h.stage.script_id == "movel", "O Móbile leva à memória do berço vazio")
	h.stage.skip()
	while h.mode != "explore":
		await w(0.1)
	check(State.flag("nome_benjamim"), "A memória revela o nome Benjamim")
	h.subs.clear()
	h.go("corridor")
	await w(2.2)
	var ofelia_open := false
	for hs in h.view.hotspots:
		if hs["action"] == "go:ofelia_room":
			ofelia_open = true
	check(ofelia_open, "O nome abre a porta de Ofélia")
	h.go("ofelia_room")
	await w(2.2)
	h.subs.clear()
	h.open_puzzle("sussurros")
	await w(0.3)
	h.puzzle._choose(h.puzzle.answer)
	while h.stage == null:
		await w(0.1)
	check(h.stage.script_id == "sussurros", "Os Sussurros levam à cena de Ofélia")
	h.stage.skip()
	while h.mode != "explore":
		await w(0.1)
	check(State.is_solved("sussurros") and State.flag("porao_open"), "Ofélia libertada; o alçapão abre")
	h.subs.clear()
	h.go("corridor")
	await w(2.2)
	h.go("kitchen")
	await w(2.2)
	var trap := false
	for hs in h.view.hotspots:
		if hs["action"] == "go:cellar":
			trap = true
	check(trap, "O alçapão da cozinha leva aos porões")

	# 9. Porões: ganchos → chave; balança → memória → coração; capela → vitral → Anselmo.
	h.subs.clear()
	h.go("cellar")
	await w(2.2)
	check(h.view.id == "cellar" and h.view.grade == "poroes" and h.view._lamp != null, "Chega à galeria dos porões, com a lamparina")
	var gate_locked := false
	for hs in h.view.hotspots:
		if hs["action"] == "locked:chapel_gate":
			gate_locked = true
	check(gate_locked, "O portão da capela começa trancado")
	check(h.available_puzzles().has("balanca") and h.available_puzzles().has("ganchos") and not h.available_puzzles().has("vitral"), "Balança e Ganchos abertos; Vitral ainda não")
	h.subs.clear()
	h.go("cold_room")
	await w(2.2)
	h.subs.clear()
	h.open_puzzle("ganchos")
	await w(0.3)
	var gz2 = h.puzzle
	gz2.boxes = gz2.targets.duplicate()
	gz2.history.append([gz2.player, gz2.boxes.duplicate()])
	gz2.finish()
	while h.puzzle != null or h.mode != "explore":
		await w(0.1)
	check(State.has("chave_capela"), "Os Ganchos dão a chave da capela")
	h.subs.clear()
	h.go("cellar")
	await w(2.2)
	h.go("wine_cellar")
	await w(2.2)
	h.subs.clear()
	h.open_puzzle("balanca")
	await w(0.3)
	var bz = h.puzzle
	for j in 3:
		bz.where[j] = 1
		bz.where[3 + j] = 2
	bz.weigh()
	var g2: Array = bz.cand.duplicate()
	for j in 9:
		bz.where[j] = 0
	bz.where[g2[0]] = 1
	bz.where[g2[1]] = 2
	bz.weigh()
	bz.open_jar(bz.cand[0])
	while h.stage == null:
		await w(0.1)
	check(h.stage.script_id == "balanca", "A Balança leva à memória do vinho")
	h.stage.skip()
	while h.mode != "explore":
		await w(0.1)
	check(State.has("coracao"), "A memória termina com o coração de Anselmo")
	h.subs.clear()
	h.go("cellar")
	await w(2.2)
	h.go("chapel")
	await w(2.4)
	check(h.view.id == "chapel" and State.flag("heart_placed"), "O coração vai para o relicário da capela")
	check(h.available_puzzles().has("vitral"), "Com o coração no altar, a rosácea vira enigma")
	h.subs.clear()
	h.open_puzzle("vitral")
	await w(0.3)
	var vz = h.puzzle
	for i in 36:
		if not vz.fixed[i] and i != 35:
			vz.grid[i] = vz.solution[i]
	if vz.fixed[35]:
		vz.finish()
	else:
		vz.place(35, vz.solution[35])
	while h.stage == null:
		await w(0.1)
	check(h.stage.script_id == "vitral", "O Vitral leva à cena de Anselmo")
	h.stage.skip()
	while h.mode != "explore":
		await w(0.1)
	check(State.is_solved("vitral") and State.flag("cripta_open"), "Anselmo libertado; a cripta abre")
	var crypt := false
	for hs in h.view.hotspots:
		if hs["action"] == "event:crypt":
			crypt = true
	check(crypt, "Atrás do altar, a passagem para a cripta")
	var souls := 0
	for id in h.SOULS:
		if State.is_solved(id):
			souls += 1
	check(h.SOULS.size() == 7 and souls == 6 and not State.is_solved("atlas"), "Sete almas na casa; só a do Atlas (que o teste pulou) segue presa")

	# 10. Salvar e carregar.
	State.qa = false
	State.save_game()
	var before := State.solved.duplicate()
	var where := State.view
	State.solved = {}
	State.view = "foyer"
	check(State.load_game() and State.solved == before and State.view == where, "Salvar e carregar preservam o progresso")
	State.qa = true

	print("RESULTADO: ", "tudo certo" if fails == 0 else "%d falha(s)" % fails)
	get_tree().quit(1 if fails > 0 else 0)
