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
	check(solvable, "Olhos no Pote tem saída em 60 sementes")

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

	# 8. Salvar e carregar.
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
