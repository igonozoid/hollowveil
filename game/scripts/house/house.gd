extends Node2D
## A casa: troca de vistas com avanço de câmera, cursor contextual, falas,
## pistas da Prancheta e o encadeamento enigma → cena fantasma → recompensa.

signal slice_finished

const VIEWS := {
	"foyer": preload("res://scripts/house/views/foyer.gd"),
	"foyer_door": preload("res://scripts/house/views/foyer_door.gd"),
	"dining": preload("res://scripts/house/views/dining.gd"),
	"library": preload("res://scripts/house/views/library.gd"),
	"kitchen": preload("res://scripts/house/views/kitchen.gd"),
	"greenhouse": preload("res://scripts/house/views/greenhouse.gd"),
	"music": preload("res://scripts/house/views/music.gd"),
	"corridor": preload("res://scripts/house/views/corridor.gd"),
	"celeste_room": preload("res://scripts/house/views/celeste_room.gd"),
	"bathroom": preload("res://scripts/house/views/bathroom.gd"),
	"guest_room": preload("res://scripts/house/views/guest_room.gd"),
	"nursery": preload("res://scripts/house/views/nursery.gd"),
	"ofelia_room": preload("res://scripts/house/views/ofelia_room.gd"),
	"cellar": preload("res://scripts/house/views/cellar.gd"),
	"wine_cellar": preload("res://scripts/house/views/wine_cellar.gd"),
	"cold_room": preload("res://scripts/house/views/cold_room.gd"),
	"chapel": preload("res://scripts/house/views/chapel.gd"),
	"crypt": preload("res://scripts/house/views/crypt.gd"),
	"attic": preload("res://scripts/house/views/attic.gd"),
	"clock_tower": preload("res://scripts/house/views/clock_tower.gd"),
}
const PUZZLES := {
	"ceia": preload("res://scripts/puzzles/ceia.gd"),
	"atlas": preload("res://scripts/puzzles/atlas.gd"),
	"olhos": preload("res://scripts/puzzles/olhos.gd"),
	"veias": preload("res://scripts/puzzles/veias.gd"),
	"prancheta": preload("res://scripts/puzzles/prancheta.gd"),
	"partitura": preload("res://scripts/puzzles/partitura.gd"),
	"caixa": preload("res://scripts/puzzles/caixa.gd"),
	"banho": preload("res://scripts/puzzles/banho.gd"),
	"pele": preload("res://scripts/puzzles/pele.gd"),
	"movel": preload("res://scripts/puzzles/movel.gd"),
	"sussurros": preload("res://scripts/puzzles/sussurros.gd"),
	"balanca": preload("res://scripts/puzzles/balanca.gd"),
	"ganchos": preload("res://scripts/puzzles/ganchos.gd"),
	"vitral": preload("res://scripts/puzzles/vitral.gd"),
	"ossuario": preload("res://scripts/puzzles/ossuario.gd"),
	"labirinto": preload("res://scripts/puzzles/labirinto.gd"),
	"bau": preload("res://scripts/puzzles/bau.gd"),
	"luar": preload("res://scripts/puzzles/luar.gd"),
}
## Enigmas que libertam uma alma (e têm cena de morte). Os outros só abrem caminho.
const SOULS := ["ceia", "atlas", "olhos", "partitura", "pele", "sussurros", "vitral"]
## Enigmas que levam a uma cena (almas e memórias).
const SCENES := ["ceia", "atlas", "olhos", "partitura", "pele", "sussurros", "vitral", "movel", "balanca", "ossuario", "bau"]
const GhostStage := preload("res://scripts/ghosts/ghost_stage.gd")
const Subtitles := preload("res://scripts/ui/subtitles.gd")
const Hud := preload("res://scripts/ui/hud.gd")

const LOOK := {
	"door": "Acorrentada. Por dentro. As correntes estão mornas, como se alguém tivesse acabado de segurá-las.",
	"mirror": "O espelho está embaçado do lado de dentro.",
	"fireplace": "Brasas acesas. Treze anos sem ninguém, e alguém ainda alimenta este fogo.",
	"table_after": "Os dentes de ouro de Leocádia, enfileirados ao lado da colher. Alguém os arrumou.",
	"piano": "Um piano de estudo. Na estante, uma partitura assinada: Tobias Ruela.",
	"piano_after": "As mãos dele ficaram aqui. Ainda tentam tocar.",
	"atlas_after": "O rosto da prancha agora está completo. E me olha.",
	"stove": "No panelão ferve alguma coisa espessa. Não vou olhar dentro.",
	"pantry_after": "Os potes que sobraram me acompanham com o olhar.",
	"roots_after": "As raízes secaram em volta de uma mão. Ela segurava a lente da prancheta.",
	"piano_music_after": "A tampa do piano ainda reflete alguém no palco. Não me viro para conferir.",
	"musicbox_after": "A bailarina sem cabeça ainda gira, devagar, mesmo com a tampa fechada.",
	"vanity_mirror": "No espelho oval, a cama atrás de mim está desarrumada. Na cama de verdade, não.",
	"tub": "Cheia até a borda. Escura demais para ser água. Alguma coisa brilha no fundo.",
	"tub_after": "A banheira esvaziou e deixou uma crosta vermelha. A chave já está comigo.",
	"vials_after": "Os frascos ainda estão mornos.",
	"bath_mirror": "Alguém escreve no vapor com o dedo, do lado de dentro do espelho.",
	"skin_after": "A âncora, a rosa e a palavra \"Mãe\". A pele ainda tem cheiro de tabaco.",
	"cards": "Trinca de damas contra um par de setes. O capitão nunca soube a hora de parar.",
	"crib_after": "O móbile gira devagar sobre o berço vazio. O lençol tem a marca de um corpo muito pequeno.",
	"rocker": "A cadeira balança. Quando eu olho, ela para. Quando desvio o olhar, recomeça.",
	"circle_after": "As velas apagaram sozinhas. O giz está borrado, como se alguém tivesse se arrastado para fora do círculo.",
	"ofelia_desk": "Cadernos de escola cheios de nomes. Todos de pessoas mortas na casa. O meu está na última página.",
	"ossuary": "Crânios empilhados em nichos, todos virados para a capela. Um deles ainda tem os dentes de ouro arrancados.",
	"barrels": "Os barris têm datas a giz: 1909, 1910, 1911. O de 1911 está pela metade, e não cheira a vinho.",
	"scale_after": "A balança ficou parada no equilíbrio. Os oito potes que sobraram me olham pelo vidro.",
	"steel_table": "Uma mesa de inox, serras de osso e um avental pendurado. Ainda úmido.",
	"cold_after": "Os ganchos estão sobre os ralos. O gelo começou a derreter, e a água que corre é rosada.",
	"rose_dark": "Uma rosácea de vidro, apagada. Não há céu do outro lado: só velas, e alguém precisa acendê-las.",
	"reliquary_empty": "Um relicário de vidro no altar, vazio, do tamanho de um punho fechado.",
	"reliquary_full": "O coração bate dentro do relicário. Cada batida acende a rosácea um pouco mais.",
	"rose_after": "A rosácea brilha sozinha. A cruz, o peixe, a chave, o cálice, a estrela e o olho, cada um no seu lugar.",
	"altar_after": "A toalha do altar está encharcada. Atrás dele, a parede parece mais fina.",
	"small_coffin": "O forro de cetim tem a marca de um corpo do tamanho de um gato. Ainda morno. Na tampa: \"Benjamim, 1910\".",
	"trunk_after": "O caderno de costura de Morvant. Cada página tem um nome, uma parte do corpo e um desenho de onde a linha entra.",
	"rocking_horse": "O cavalinho tem o nome Benjamim pintado no pescoço. Nunca foi usado. A tinta da sela está riscada por unhas.",
	"pendulum": "A lâmina do pêndulo passa a um palmo do meu rosto. Tem uma crosta escura no fio.",
	"moonbeam_after": "O luar corre pelos espelhos, desce pelo poço da escada e vai acender o olho da porta do teatro.",
	"ossuary_after": "Os crânios do meio caíram para dentro. Do buraco vem um ar frio e um cheiro de terra molhada.",
}
const LOCKED := {
	"stairs": "Um peso no peito me empurra de volta. Ainda não.",
	"library": "Trancada. A fechadura tem a forma de um dente.",
	"pantry": "Travada por dentro. Do outro lado, alguém arrasta os pés.",
	"service": "Uma tranca de ferro, sem buraco de chave. Só abre do outro lado.",
	"music": "Trancada. Do outro lado, alguém afina a voz. Bato e o canto para.",
	"guest": "Trancada. A fechadura é de latão, com um 3 gravado.",
	"nursery": "Trancado. Do outro lado, um móbile gira sem vento.",
	"trapdoor": "Um alçapão no chão, pregado por dentro. Lá embaixo, alguém reza em latim.",
	"theater": "Trancada. Do outro lado, alguém nina um bebê, e o bebê responde numa voz de homem.",
	"chapel_gate": "Um portão de ferro com cadeado em forma de cruz. Do outro lado, o padre continua rezando.",
}

var view_root := Node2D.new()
var view: Node2D = null
var modulate_node := CanvasModulate.new()
var puzzle_layer := CanvasLayer.new()
var ghost_layer := CanvasLayer.new()
var fade_layer := CanvasLayer.new()
var fade := ColorRect.new()
var subs: CanvasLayer
var hud: CanvasLayer
var cursor: CanvasLayer
var post: CanvasLayer
var hover_label := Label.new()
var busy := false
var mode := "explore"
var puzzle: Control = null
var stage: Node2D = null
var _last_hot := {}


func _ready() -> void:
	add_child(modulate_node)
	modulate_node.color = Color(0.95, 0.92, 0.9)
	add_child(view_root)
	puzzle_layer.layer = 5
	add_child(puzzle_layer)
	ghost_layer.layer = 6
	add_child(ghost_layer)
	fade_layer.layer = 7
	add_child(fade_layer)
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)
	hud = Hud.new()
	add_child(hud)
	subs = Subtitles.new()
	add_child(subs)
	hover_label.add_theme_font_size_override("font_size", 10)
	hover_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.6))
	hover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hover_label)
	Audio.set_ambient(true)
	Audio.warm(["enigma", "fantasma"])
	_show_view(State.view)
	create_tween().tween_property(fade, "modulate:a", 0.0, 1.2).from(1.0)


func _show_view(id: String) -> void:
	if view:
		view.queue_free()
	view = VIEWS.get(id, VIEWS["foyer"]).new()
	view_root.add_child(view)
	State.view = view.id
	Audio.music(view.music)
	if post:
		post.grade(view.grade if view else "terreo")


# ---------------------------------------------------------------- entrada

func _process(_delta: float) -> void:
	if cursor == null:
		return
	if mode != "explore":
		hover_label.hide()
		return
	var m := get_viewport().get_mouse_position()
	var h: Dictionary = {} if busy or view == null else view.hotspot_at(m)
	cursor.mode = h.get("kind", "flame")
	if h.is_empty():
		hover_label.hide()
	else:
		if h != _last_hot:
			Audio.play("hover", -16.0)
		hover_label.text = h.get("label", "")
		hover_label.reset_size()
		hover_label.position = (m + Vector2(-hover_label.size.x * 0.5, -24)).clamp(Vector2(2, 2), Vector2(638 - hover_label.size.x, 340))
		hover_label.show()
	_last_hot = h


func _unhandled_input(event: InputEvent) -> void:
	if mode != "explore" or busy:
		if mode == "ghost" and event is InputEventMouseButton and event.pressed:
			subs.advance()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if subs.busy():
			subs.advance()
			get_viewport().set_input_as_handled()
			return
		var h: Dictionary = view.hotspot_at(event.position)
		if not h.is_empty():
			_act(h)
		get_viewport().set_input_as_handled()
	elif State.qa and event is InputEventKey and event.pressed:
		_qa_key(event.keycode)


func _act(h: Dictionary) -> void:
	var parts: PackedStringArray = String(h["action"]).split(":", true, 1)
	var kind := parts[0]
	var arg := parts[1] if parts.size() > 1 else ""
	match kind:
		"go":
			go(arg, (h["rect"] as Rect2).get_center())
		"look":
			subs.say("DÁLIA", LOOK.get(arg, "..."))
		"locked":
			Audio.play("locked", -4.0)
			subs.say("DÁLIA", LOCKED.get(arg, "Trancado."))
		"puzzle":
			open_puzzle(arg)
		"event":
			_event(arg)


# ---------------------------------------------------------------- vistas

func go(target: String, focus: Vector2 = Vector2(320, 180)) -> void:
	if busy or mode != "explore":
		return
	busy = true
	subs.clear()
	Audio.play("step", -6.0, randf_range(0.9, 1.05))
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_method(_zoom.bind(focus), 1.0, 1.45, 0.55)
	tw.tween_property(fade, "modulate:a", 1.0, 0.5).set_delay(0.1)
	tw.chain().tween_callback(func():
		if target.begins_with("foyer") != State.view.begins_with("foyer") or target == "kitchen" or State.view == "kitchen":
			Audio.play("door", -10.0, randf_range(0.9, 1.1))
		_show_view(target)
		Audio.play("step2", -7.0, randf_range(0.9, 1.05))
		var tw2 := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw2.tween_method(_zoom.bind(Vector2(320, 180)), 1.12, 1.0, 0.6)
		tw2.tween_property(fade, "modulate:a", 0.0, 0.5)
		tw2.chain().tween_callback(func():
			busy = false
			State.save_game()
			view.entered(self)))


func _zoom(s: float, focus: Vector2) -> void:
	view_root.scale = Vector2(s, s)
	view_root.position = focus - focus * s


# ---------------------------------------------------------------- enigmas

func open_puzzle(id: String) -> void:
	if not PUZZLES.has(id):
		return
	mode = "puzzle"
	State.flags["last_puzzle"] = id
	Audio.play("heart", -6.0)
	puzzle = PUZZLES[id].new()
	puzzle.house = self
	puzzle.solved.connect(_on_solved.bind(id))
	puzzle.closed.connect(_close_puzzle)
	puzzle.modulate.a = 0.0
	puzzle_layer.add_child(puzzle)
	create_tween().tween_property(puzzle, "modulate:a", 1.0, 0.35)
	Audio.music("enigma")
	if post:
		post.grade("enigma")


func _close_puzzle() -> void:
	if puzzle:
		puzzle.queue_free()
		puzzle = null
	mode = "explore"
	Audio.music(view.music)
	if post:
		post.grade(view.grade if view else "terreo")
	State.save_game()


func _on_solved(id: String) -> void:
	State.mark_solved(id)
	State.change_sanity(12.0)
	Audio.play("solved", -4.0)
	await get_tree().create_timer(1.4).timeout
	if puzzle:
		puzzle.queue_free()
		puzzle = null
	after_solve(id, false)


## Depois de resolver: cena de morte para as almas; recompensa direta para o resto.
func after_solve(id: String, by_host: bool) -> void:
	if id in SCENES:
		play_ghost(id, by_host)
		return
	mode = "explore"
	Audio.music(view.music)
	if post:
		post.grade(view.grade if view else "terreo")
	view.queue_redraw()
	_reward(id, by_host)


# ---------------------------------------------------------------- cenas fantasmas

func play_ghost(id: String, host_version: bool) -> void:
	mode = "ghost"
	cursor.mode = "flame"
	subs.clear()
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.8)
	await tw.finished
	stage = GhostStage.new()
	stage.script_id = id
	stage.host_version = host_version
	stage.house = self
	ghost_layer.add_child(stage)
	Audio.music("fantasma")
	Audio.set_ambient(false)
	if post:
		post.grade("fantasma")
	create_tween().tween_property(fade, "modulate:a", 0.0, 1.0)
	await stage.finished
	var tw2 := create_tween()
	tw2.tween_property(fade, "modulate:a", 1.0, 1.0)
	await tw2.finished
	stage.queue_free()
	stage = null
	Audio.set_ambient(true)
	view.queue_redraw()
	mode = "explore"
	Audio.music(view.music)
	if post:
		post.grade(view.grade if view else "terreo")
	create_tween().tween_property(fade, "modulate:a", 0.0, 1.0)
	_reward(id, host_version)


func _reward(id: String, by_host: bool) -> void:
	match id:
		"ceia":
			State.give("chave_osso")
			hud.notify("CHAVE DE OSSO\nTirada da sopa de Leocádia. Abre a biblioteca.")
			subs.say("MORVANT", "Ela sempre falou demais à mesa. Agora fala pelos cotovelos... dos outros.")
		"atlas":
			State.set_flag("kitchen_open")
			hud.notify("A PORTA DA COPA\nAlguma coisa a destrancou por dentro.")
			subs.say("MORVANT", "Mãos tão bonitas. Seria um desperdício enterrá-las.")
		"olhos":
			hud.notify("ESCADA DE SERVIÇO\nA tranca caiu sozinha.")
			if State.is_solved("partitura"):
				subs.say("MORVANT", "Quatro já se foram. Suba, médium. Minha filha não dorme há treze anos.")
			else:
				subs.say("MORVANT", "Três já se foram. Suba, médium. Ou fique, e ouça minha esposa ensaiar.")
		"veias":
			State.set_flag("prancheta_ready")
			hud.notify("LENTE DE VIDRO\nA prancheta do saguão tem olho de novo.")
			subs.say("MORVANT", "Ofélia plantou isso. Ela regava com o que tinha à mão.")
		"prancheta":
			State.set_flag("music_open")
			hud.notify("SALA DE MÚSICA\nA porta destrancou com o seu nome.")
			subs.say("MORVANT", "Celeste odeia plateia atrasada. Corra.")
		"partitura":
			hud.notify("A VOZ DE CELESTE\nLevada num vidro para o andar de cima.")
			subs.say("MORVANT", "Agora ela canta só para mim. Lá em cima, onde a acústica é melhor.")
		"banho":
			State.give("chave_hospedes")
			hud.notify("CHAVE DE LATÃO Nº 3\nEstava no fundo da banheira. Abre o quarto de hóspedes.")
			subs.say("MORVANT", "O capitão tomava banhos de duas horas. Hoje ele não se importa com a demora.")
		"caixa":
			hud.notify("A CANÇÃO DE NINAR\nUma fechadura estalou do outro lado do corredor.")
			subs.say("MORVANT", "Era a canção do berçário. Celeste cantava para um berço vazio.")
		"movel":
			State.set_flag("nome_benjamim")
			hud.notify("BENJAMIM\nO nome do filho que nasceu morto. Ofélia vai querer ouvir.")
		"sussurros":
			State.set_flag("porao_open")
			hud.notify("O ALÇAPÃO DA COZINHA\nOfélia abriu o caminho para os porões.")
			subs.say("MORVANT", "Desça, médium. O padre Anselmo adora uma confissão.")
		"balanca":
			State.give("coracao")
			hud.notify("O CORAÇÃO DE ANSELMO\nAinda bate dentro do pote. O relicário da capela tem o tamanho dele.")
			subs.say("MORVANT", "Guardei no vinho para não secar. Leve para ele, médium. O padre sente falta.")
		"ganchos":
			State.give("chave_capela")
			hud.notify("CHAVE DA CAPELA\nPresa no gelo, debaixo do último ralo. Tem uma cruz no lugar do dente.")
			subs.say("MORVANT", "Anselmo escondia a chave de mim. Como se eu precisasse de chave para entrar numa igreja.")
		"vitral":
			State.set_flag("cripta_open")
			hud.notify("A CRIPTA\nAtrás do altar, uma laje de pedra se moveu sozinha.")
			subs.say("MORVANT", "Sete almas, médium. Só falta a sua. E o meu filho espera lá embaixo, na cripta.")
		"ossuario":
			State.set_flag("fundacoes_open")
			hud.notify("AS FUNDAÇÕES\nOs nichos do meio cederam. Atrás deles, um túnel desce sob a casa.")
			subs.say("MORVANT", "Lá embaixo é escuro e ele está com fome, médium. Ande depressa e não volte por onde veio.")
		"labirinto":
			State.set_flag("sotao_open")
			hud.notify("A ESCADARIA PRINCIPAL\nO poço sai debaixo da escada do saguão. O peso no peito sumiu.")
			subs.say("MORVANT", "Você saiu. Ninguém sai. Suba, então. Meu filho e eu esperamos no teatro.")
			_emerge_in_foyer.call_deferred()
		"bau":
			State.give("chave_teatro")
			hud.notify("A CHAVE DO TEATRO\nEstava no fundo do baú, dentro do caderno de costura.")
			subs.say("MORVANT", "Agora você sabe para que serve uma médium. Não se preocupe: eu costuro com carinho.")
		"luar":
			State.set_flag("luar")
			hud.notify("O LUAR\nA lua atravessa o mostrador e acende o olho de vidro da porta do teatro.")
			subs.say("MORVANT", "Luz na plateia. O espetáculo vai começar.")
		"pele":
			hud.notify("A PELE DE HÉLIO\nUma âncora, uma rosa e a palavra \"Mãe\".")
			subs.say("MORVANT", "Pele boa, bem curtida pelo sol. Serviu de capa para o meu diário.")
	if by_host:
		subs.say("DÁLIA", "Ele resolveu por mim. E levou alguma coisa junto... não lembro o rosto dela.")
	State.save_game()


# ---------------------------------------------------------------- eventos

func _event(id: String) -> void:
	match id:
		"portrait":
			var lines := [
				"Pintado por um aluno. Errou o nariz. Corrigi o nariz dele depois.",
				"Os olhos? São os meus. Os originais.",
				"Você também finge ouvir os mortos, Dália. Somos colegas.",
			]
			if State.is_solved("ceia"):
				lines = ["Chorar sangue é só uma figura de linguagem. Na maioria das casas.",
					"Uma alma a menos para me fazer companhia. Que egoísmo o seu."]
			subs.say("MORVANT", lines[int(State.play_time) % lines.size()])
			State.change_sanity(-1.0)
		"planchette":
			if State.flag("prancheta_ready") and not State.is_solved("prancheta"):
				open_puzzle("prancheta")
			else:
				_planchette()
		"voice_jar":
			Audio.play("whisper", -6.0, 1.8)
			if State.is_solved("partitura"):
				subs.say("CELESTE", "...me tire daqui... devolva para a minha garganta...")
				subs.say("DÁLIA", "A voz de Celeste. Ainda não sei como devolver. Ainda.")
			else:
				subs.say("DÁLIA", "Uma coisa pálida vibra dentro do vidro, como uma corda que alguém dedilha.")
		"ofelia_door":
			Audio.play("whisper", -4.0, 1.2)
			subs.say("OFÉLIA", ["Você ouve a gente. Eu sei que ouve. Mas só abro se disser o nome dele.", "O nome. O nome do menino do berço. Diga, e eu abro."][int(State.play_time) % 2])
		"attic":
			go("attic", Vector2(320, 110))
		"theater":
			busy = true
			Audio.play("door", -4.0, 0.5)
			Audio.play("cry", -6.0, 0.8)
			subs.say("DÁLIA", "A chave entra. O olho de vidro me encara, branco de luar. A porta do teatro se abre para uma plateia em degraus, e todos os lugares estão ocupados.")
			await subs.finished
			var tw4 := create_tween()
			tw4.tween_property(fade, "modulate:a", 1.0, 1.5)
			await tw4.finished
			slice_finished.emit()
		"gramophone":
			Audio.play("sting", -14.0, 1.6)
			subs.say("", "O disco gira sozinho. Uma soprano canta, longe, e para no meio da frase.")
			if State.is_solved("partitura"):
				subs.say("CELESTE", "...lá em cima... no vidro...")
		"stairs_up":
			busy = true
			Audio.play("door", -6.0, 0.8)
			subs.say("DÁLIA", "A escada sobe no escuro. Lá em cima, alguém canta.")
			await subs.finished
			var tw := create_tween()
			tw.tween_property(fade, "modulate:a", 1.0, 1.5)
			await tw.finished
			slice_finished.emit()


## O poço das fundações sobe até debaixo da escadaria do saguão.
func _emerge_in_foyer() -> void:
	await get_tree().create_timer(2.5).timeout
	if mode == "explore" and not busy:
		go("foyer")


## Enigmas já alcançáveis e ainda abertos, na ordem em que costumam aparecer.
func available_puzzles() -> Array:
	var out: Array = []
	var gates := {
		"ceia": true, "veias": true,
		"atlas": State.has("chave_osso"),
		"olhos": State.flag("kitchen_open"),
		"prancheta": State.flag("prancheta_ready"),
		"partitura": State.flag("music_open"),
		"banho": State.is_solved("olhos"),
		"caixa": State.is_solved("olhos"),
		"pele": State.has("chave_hospedes"),
		"movel": State.is_solved("caixa"),
		"sussurros": State.flag("nome_benjamim"),
		"balanca": State.flag("porao_open"),
		"ganchos": State.flag("porao_open"),
		"vitral": State.flag("heart_placed") and State.has("chave_capela"),
		"ossuario": State.flag("cripta_open"),
		"labirinto": State.flag("fundacoes_open"),
		"bau": State.flag("sotao_open"),
		"luar": State.flag("sotao_open"),
	}
	for id in ["ceia", "veias", "atlas", "prancheta", "olhos", "partitura", "banho", "caixa", "pele", "movel", "sussurros", "balanca", "ganchos", "vitral", "ossuario", "labirinto", "bau", "luar"]:
		if gates[id] and not State.is_solved(id):
			out.append(id)
	return out


func _current_puzzle() -> String:
	var last := String(State.flags.get("last_puzzle", ""))
	if last != "" and not State.is_solved(last):
		return last
	var open := available_puzzles()
	return open[0] if not open.is_empty() else ""


func _planchette() -> void:
	hint_for(_current_puzzle())


## Pista para um enigma: nível 1 e 2 custam sanidade; no 3, Morvant resolve.
func hint_for(target: String) -> void:
	Audio.play("planchette", -2.0)
	if target == "":
		subs.say("", "A prancheta não se move. Os mortos daqui já disseram tudo.")
		return
	var level := State.use_hint(target)
	var script = PUZZLES[target]
	if level <= 2:
		State.change_sanity(-5.0 if level == 1 else -10.0)
		subs.say("", "A prancheta desliza sob os seus dedos, letra por letra...")
		subs.say("DÁLIA", script.hint(level))
		if level == 2:
			State.set_flag("hint2_" + target)
			subs.say("MORVANT", "Mais uma vez e eu mesmo faço. Mas nada nesta casa é de graça.")
	else:
		State.change_sanity(-20.0)
		subs.say("MORVANT", "Deixe comigo, querida. Eu conheço esta peça de cor.")
		Audio.play("laugh", -6.0, 0.85)
		await subs.finished
		State.mark_solved(target, true)
		if puzzle:
			puzzle.queue_free()
			puzzle = null
		after_solve(target, true)


# ---------------------------------------------------------------- modo de teste

func _qa_key(code: int) -> void:
	match code:
		KEY_F6:
			var target := _current_puzzle()
			if target != "":
				State.mark_solved(target)
				if puzzle:
					puzzle.queue_free()
					puzzle = null
				after_solve(target, false)
		KEY_F7:
			State.change_sanity(-15.0)
		KEY_F8:
			State.change_sanity(15.0)
