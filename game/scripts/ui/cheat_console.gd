extends CanvasLayer
## Console de cheats (tecla =). Uma linha de comando por cima do jogo, que
## pausa enquanto está aberta. "ajuda" lista os comandos.

const Relics := preload("res://scripts/core/relics.gd")
const HELP := [
	"ajuda — esta lista",
	"deus — sanidade travada em 100 (liga/desliga)",
	"sanidade N — muda a sanidade para N (0 a 100)",
	"resolver — resolve o enigma aberto ou o próximo disponível",
	"resolver ID — resolve um enigma pelo nome (ceia, atlas, vitral...)",
	"pista — mostra as duas pistas do enigma atual, sem custo",
	"ir CÔMODO — vai direto a um cômodo (saguão, capela, teatro...)",
	"abrir — destranca a casa inteira (todas as portas e andares)",
	"almas — liberta as sete almas, sem cenas",
	"reliquias — dá as 40 relíquias",
	"final medium|cancao|peca|anfitriao — vai direto a um final",
	"noite — liga/desliga a Noite Mais Escura nesta volta",
	"limpar — limpa o console",
	"fechar — fecha (ou = / Esc)",
]
const ROOM_ALIASES := {
	"saguao": "foyer", "saguão": "foyer", "porta": "foyer_door", "jantar": "dining", "biblioteca": "library",
	"cozinha": "kitchen", "estufa": "greenhouse", "musica": "music", "música": "music", "corredor": "corridor",
	"celeste": "celeste_room", "banheiro": "bathroom", "hospedes": "guest_room", "hóspedes": "guest_room",
	"bercario": "nursery", "berçário": "nursery", "ofelia": "ofelia_room", "ofélia": "ofelia_room",
	"galeria": "cellar", "poroes": "cellar", "porões": "cellar", "adega": "wine_cellar", "fria": "cold_room",
	"capela": "chapel", "cripta": "crypt", "sotao": "attic", "sótão": "attic", "torre": "clock_tower", "teatro": "theater",
}

var main: Node
var root: Control
var log_label: Label
var input: LineEdit
var lines: Array = []
var history: Array = []
var hist_i := 0


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.size = Vector2(640, 170)
	root.visible = false
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.015, 0.94)
	bg.size = Vector2(640, 170)
	root.add_child(bg)
	var edge := ColorRect.new()
	edge.color = Color(0.55, 0.08, 0.08)
	edge.position = Vector2(0, 169)
	edge.size = Vector2(640, 1)
	root.add_child(edge)
	log_label = Label.new()
	log_label.position = Vector2(8, 4)
	log_label.size = Vector2(624, 140)
	log_label.add_theme_font_size_override("font_size", 9)
	log_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72))
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	log_label.clip_text = true
	root.add_child(log_label)
	input = LineEdit.new()
	input.position = Vector2(8, 146)
	input.size = Vector2(624, 20)
	input.placeholder_text = "comando (ajuda)"
	input.add_theme_font_size_override("font_size", 10)
	input.text_submitted.connect(_run)
	input.gui_input.connect(_history_keys)
	root.add_child(input)
	_print("Console de cheats. Digite \"ajuda\".")


func is_open() -> bool:
	return root.visible


func toggle() -> void:
	root.visible = not root.visible
	get_tree().paused = root.visible
	if root.visible:
		input.text = ""
		input.grab_focus()
	else:
		input.release_focus()


func _history_keys(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		if e.keycode == KEY_UP and not history.is_empty():
			hist_i = maxi(0, hist_i - 1)
			input.text = history[hist_i]
			input.caret_column = input.text.length()
			input.accept_event()
		elif e.keycode == KEY_DOWN and not history.is_empty():
			hist_i = mini(history.size(), hist_i + 1)
			input.text = history[hist_i] if hist_i < history.size() else ""
			input.caret_column = input.text.length()
			input.accept_event()
		elif e.keycode == KEY_ESCAPE or e.keycode == KEY_EQUAL:
			toggle()
			input.accept_event()


func _print(s: String) -> void:
	lines.append(s)
	if lines.size() > 60:
		lines = lines.slice(lines.size() - 60)
	# Só cabem as últimas linhas acima da linha de comando.
	var shown: Array = lines.slice(maxi(0, lines.size() - 9))
	log_label.text = "\n".join(PackedStringArray(shown))


func _house():
	if main and main.screen and main.screen.has_method("open_puzzle"):
		return main.screen
	return null


func _run(text: String) -> void:
	text = text.strip_edges()
	input.text = ""
	if text == "":
		return
	history.append(text)
	hist_i = history.size()
	_print("> " + text)
	var parts := text.to_lower().split(" ", false)
	var cmd: String = parts[0]
	var arg: String = parts[1] if parts.size() > 1 else ""
	var h = _house()
	match cmd:
		"ajuda", "help":
			for l in HELP:
				_print("  " + l)
		"limpar":
			lines.clear()
			log_label.text = ""
		"fechar":
			toggle()
		"deus":
			State.god = not State.god
			if State.god:
				State.sanity = 100.0
				State.sanity_changed.emit(State.sanity)
			_print("Deus: " + ("ligado" if State.god else "desligado"))
		"sanidade":
			State.sanity = clampf(float(arg) if arg != "" else 100.0, 0.0, 100.0)
			State.sanity_changed.emit(State.sanity)
			_print("Sanidade: %d" % int(State.sanity))
		"noite":
			State.dark_night = not State.dark_night
			_print("Noite Mais Escura: " + ("ligada" if State.dark_night else "desligada"))
		"reliquias", "relíquias":
			for r in Relics.LIST:
				State.collect_relic(r[0])
			if h:
				h.view.queue_redraw()
			_print("As 40 relíquias estão com você.")
		_:
			if h == null:
				_print("Esse comando só funciona dentro da casa.")
				return
			match cmd:
				"resolver":
					_solve(h, arg)
				"pista":
					var target: String = arg if arg != "" else h._current_puzzle()
					if target == "" or not h.PUZZLES.has(target):
						_print("Nenhum enigma pendente.")
					else:
						_print("1: " + h.PUZZLES[target].hint(1))
						_print("2: " + h.PUZZLES[target].hint(2))
				"ir":
					var v: String = ROOM_ALIASES.get(arg, arg)
					if not h.VIEWS.has(v):
						_print("Cômodo desconhecido. Exemplos: saguão, capela, cripta, torre, teatro.")
					else:
						toggle()
						h.close_map()
						if h.puzzle:
							h._close_puzzle()
						h._travel(v)
				"abrir":
					unlock_all()
					h.view.queue_redraw()
					_print("A casa inteira está aberta.")
				"almas":
					for id in h.SOULS:
						State.mark_solved(id)
					_print("As sete almas estão livres.")
					h.view.queue_redraw()
				"final":
					if not ["medium", "cancao", "peca", "anfitriao"].has(arg):
						_print("Use: final medium|cancao|peca|anfitriao")
					else:
						toggle()
						State.record_ending(arg)
						h.slice_finished.emit()
				_:
					_print("Comando desconhecido. Digite \"ajuda\".")


func _solve(h, arg: String) -> void:
	var target: String = arg
	if target == "":
		target = String(State.flags.get("last_puzzle", "")) if h.puzzle else h._current_puzzle()
	if target == "" or not h.PUZZLES.has(target):
		_print("Nenhum enigma para resolver.")
		return
	if State.is_solved(target):
		_print("Esse já está resolvido.")
		return
	toggle()
	State.mark_solved(target)
	if h.puzzle:
		h.puzzle.queue_free()
		h.puzzle = null
	h.after_solve(target, false)


## Destranca tudo o que o progresso destrancaria, sem resolver os enigmas.
static func unlock_all() -> void:
	for f in ["prancheta_ready", "music_open", "kitchen_open", "nome_benjamim", "porao_open", "heart_placed", "cripta_open", "fundacoes_open", "sotao_open", "luar", "theater_seen", "voz_celeste"]:
		State.set_flag(f)
	for item in ["chave_osso", "chave_hospedes", "coracao", "chave_capela", "chave_teatro"]:
		State.give(item)
	for id in ["olhos", "caixa", "movel"]:
		if not State.is_solved(id):
			State.solved[id] = true
