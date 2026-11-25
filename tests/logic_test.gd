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

	# 6. Salvar e carregar.
	State.qa = false
	State.save_game()
	var before := State.solved.duplicate()
	State.solved = {}
	check(State.load_game() and State.solved == before and State.view == "dining", "Salvar e carregar preservam o progresso")
	State.qa = true

	print("RESULTADO: ", "tudo certo" if fails == 0 else "%d falha(s)" % fails)
	get_tree().quit(1 if fails > 0 else 0)
