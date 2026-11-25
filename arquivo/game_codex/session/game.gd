extends Node2D

const Atmosphere = preload("../presentation/atmosphere.gd")
const Film = preload("../presentation/film.gdshader")
const Room = preload("../rooms/corridor.gd")
const Landing = preload("../rooms/landing.gd")
const Actor = preload("../actors/investigator.gd")
const Clock = preload("../puzzles/clock.gd")
const Checkpoint = preload("checkpoint.gd")
const Sound = preload("../presentation/sound.gd")
const Menu = preload("../presentation/front_menu.gd")
const Device = preload("../puzzles/wing_device.gd")
const Preferences = preload("preferences.gd")
const Campaign = preload("campaign_data.gd")
const CampaignMap = preload("../presentation/campaign_map.gd")
const Tutorial = preload("../presentation/tutorial.gd")
const NAMES := ["Entrada", "Painel de rondas", "Sala lacrada", "Relógio", "Porta do patamar"]

var atmosphere := Atmosphere.new()
var room := Room.new()
var landing := Landing.new()
var actor := Actor.new()
var clock := Clock.new()
var state := Checkpoint.new()
var sound := Sound.new()
var preferences := Preferences.new()
var menu := Menu.new()
var device := Device.new()
var chapter_name := Label.new()
var film_layer := CanvasLayer.new()
var playing := false
var map_view := CampaignMap.new()
var objective := Label.new()
var qa_mode := false
var hint := Label.new()
var toast := Label.new()
var message := RichTextLabel.new()
var overlay := ColorRect.new()
var dismiss := Button.new()
var time := 0.0
var tick := 0.0
var camera_x := 0.0
var near := -1
var on_landing := false
var toast_left := 0.0

func _ready() -> void:
	_register_keys("walk_left", [KEY_A,KEY_LEFT])
	_register_keys("walk_right", [KEY_D,KEY_RIGHT])
	_register_keys("inspect", [KEY_E])
	_register_keys("campaign_map", [KEY_M])
	_register_keys("tutorial", [KEY_H])
	qa_mode = "--qa" in OS.get_cmdline_user_args()
	if qa_mode:
		_register_keys("qa_help", [KEY_F3])
		_register_keys("qa_solve", [KEY_F6])
		_register_keys("qa_advance", [KEY_F7])
		_register_keys("qa_reset", [KEY_F8])
	else:
		state.load_slot()
	preferences.restore()
	preferences.apply()
	add_child(room)
	room.add_child(actor)
	add_child(landing)
	landing.hide()
	add_child(atmosphere)
	_add_film()
	actor.position = Vector2(state.x,Room.FLOOR)
	camera_x = clampf(actor.position.x-595,0,840)
	room.position.x = -camera_x
	room.unlocked = state.solved if state.chapter == 0 else state.wing_solved
	add_child(sound)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var banner := ColorRect.new()
	banner.color = Color(0.04,0.05,0.067,0.90)
	banner.size = Vector2(1280,105)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(banner)
	_text(canvas, Label.new(), Vector2(43,20), Vector2(540,38), 27, "HOLLOWVEIL")
	_text(canvas, chapter_name, Vector2(44,62), Vector2(720,30), 17, "Corredor da Vigília    /    IGNF Lab")
	_text(canvas, Label.new(), Vector2(740,30), Vector2(512,40), 17, "A/D ou ←/→    ·    E Interagir    ·    M Mapa    ·    H Tutorial")
	_text(canvas, objective, Vector2(43,632), Vector2(1130,28), 17, "")
	if qa_mode:
		_text(canvas, Label.new(), Vector2(902,67), Vector2(340,24), 15, "MODO TESTE   ·   F3 Comandos")
	_text(canvas, hint, Vector2(43,660), Vector2(1130,42), 22, "")
	_text(canvas, toast, Vector2(43,112), Vector2(1130,40), 17, "")
	canvas.add_child(map_view)
	map_view.closed.connect(map_view.hide)
	canvas.add_child(clock)
	clock.turned.connect(_turn)
	clock.tested.connect(_test_clock)
	clock.closed.connect(_close_clock)
	clock.record_requested.connect(_record)
	canvas.add_child(device)
	device.changed.connect(_wing_changed)
	device.solved.connect(_wing_solved)
	device.closed.connect(_close_device)
	device.record_requested.connect(_wing_record)
	overlay.size = Vector2(1280,720)
	overlay.color = Color(0.025,0.033,0.040,0.95)
	canvas.add_child(overlay)
	message.position = Vector2(265,171)
	message.size = Vector2(750,345)
	message.bbcode_enabled = true
	message.add_theme_font_size_override("normal_font_size",22)
	message.add_theme_font_size_override("bold_font_size",28)
	overlay.add_child(message)
	dismiss.position = Vector2(503,540)
	dismiss.size = Vector2(274,54)
	dismiss.text = "Continuar"
	dismiss.pressed.connect(_dismiss)
	overlay.add_child(dismiss)
	overlay.hide()
	menu.preferences = preferences
	canvas.add_child(menu)
	menu.has_save = state.valid
	menu.new_requested.connect(_new_game)
	menu.resume_requested.connect(_resume_game)
	menu.options_changed.connect(_change_options)
	menu.quit_requested.connect(func(): get_tree().quit())
	_apply_chapter()
	_change_options(false)
	menu.show_splash()

func _add_film() -> void:
	film_layer.layer = 0
	var grade := ColorRect.new()
	grade.size = Vector2(1280,720)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = Film
	grade.material = material
	add_child(film_layer)
	film_layer.add_child(grade)

func _register_keys(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key: int in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action,event)

func _text(parent: Node, label: Label, at: Vector2, dimensions: Vector2, font_size: int, content: String) -> void:
	label.position = at
	label.size = dimensions
	label.text = content
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("#f0d8ac"))
	parent.add_child(label)

func _physics_process(delta: float) -> void:
	time += delta
	var free := playing and not menu.visible and not clock.visible and not overlay.visible and not device.visible and not map_view.visible
	var axis := Input.get_axis("walk_left","walk_right") if free else 0.0
	actor.walking = not is_zero_approx(axis)
	if actor.walking:
		actor.facing = signf(axis)
		actor.position.x = clampf(actor.position.x + axis*246*delta, 760 if on_landing else 48, 1180 if on_landing else 2032)
		if not on_landing:
			state.x = actor.position.x
	camera_x = lerpf(camera_x,clampf(actor.position.x-595,0,840),1.0-exp(-8*delta))
	room.position.x = -camera_x
	_update_near()
	objective.text = Tutorial.objective(state.chapter,state.tutorial_step,
		state.solved if state.chapter == 0 else state.wing_solved,state.read_record,on_landing)
	objective.visible = free
	room.update_light(time,camera_x)
	atmosphere.elapsed = time
	atmosphere.camera_offset = camera_x
	atmosphere.visible = preferences.effects and not on_landing
	atmosphere.queue_redraw()
	actor.set_light(time, on_landing)
	tick -= delta
	if free and near == 3 and not state.solved and tick <= 0:
		sound.cue("tick")
		tick = 1.0
	if toast_left > 0.0:
		toast_left -= delta
		if toast_left <= 0.0:
			toast.text = ""

func _update_near() -> void:
	near = -1
	if state.chapter == 3:
		hint.text = ""
		return
	if on_landing:
		if actor.position.x >= 1040:
			hint.text = "E   Voltar ao corredor"
		elif actor.position.x <= 895:
			hint.text = "E   Descer à Galeria das Lanternas"
		else:
			hint.text = "Patamar   ·   Galeria à esquerda, corredor à direita"
		return
	for index in Room.LOCATIONS.size():
		if absf(actor.position.x-Room.LOCATIONS[index]) <= 93:
			near = index
			break
	room.active = near
	if state.chapter in [1,2]:
		var wing: Dictionary = Campaign.WINGS[state.chapter-1]
		var names := ["Entrada", "Instruções", "Examinar a ala", wing.device, "Saída"]
		hint.text = "E   " + names[near] if near >= 0 else "Procure as instruções e examine o mecanismo."
		return
	hint.text = "E   " + NAMES[near] if near >= 0 else "Explore o corredor e procure o painel de rondas."
	if near == 4 and state.solved:
		hint.text = "E   Entrar no patamar"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if menu.visible:
		if menu.splash and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
			menu.finish_splash()
		elif event.is_action_pressed("ui_cancel") and menu.page != "main":
			menu.open_main()
		elif event.is_action_pressed("ui_cancel") and playing:
			_resume_game()
		return
	if map_view.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("campaign_map"):
			map_view.hide()
		return
	if event.is_action_pressed("ui_cancel"):
		if overlay.visible:
			_dismiss()
		elif clock.visible:
			_close_clock()
		elif device.visible:
			_close_device()
		else:
			_open_menu()
	elif playing and not overlay.visible and not clock.visible and not device.visible:
		if event.is_action_pressed("inspect"):
			_interact()
		elif event.is_action_pressed("campaign_map"):
			map_view.inspect(state.chapter,actor.position.x,on_landing,
				state.solved if state.chapter == 0 else state.wing_solved)
		elif event.is_action_pressed("tutorial"):
			_note("TUTORIAL",Tutorial.GUIDE)
		elif qa_mode:
			_qa_input(event)

func _interact() -> void:
	if state.chapter in [1,2]:
		_interact_wing()
		return
	if on_landing:
		if actor.position.x <= 895:
			_advance()
		elif actor.position.x >= 1040:
			_leave_landing()
		return
	match near:
		0: _note("ENTRADA", "Você veio investigar por que a última ronda da mansão nunca terminou.")
		1:
			state.tutorial_step = maxi(1,state.tutorial_step)
			_note("PAINEL DE RONDAS", "Ordem da vigília\n\n◆   →   ▲   →   ✦\n\nRepita as três marcas no relógio.")
		2: _note("SALA LACRADA", "O selo está intacto. A folha de ronda, porém, dá a sala como inspecionada.")
		3:
			state.tutorial_step = 2
			clock.show_clock(state.rings,state.solved)
		4:
			if state.solved:
				_enter_landing()
				_note("PATAMAR", "A última ronda continuava abaixo da mansão. Siga para a escada à esquerda para chegar à Galeria das Lanternas.")
			else:
				_note("PORTA DO PATAMAR", "O trinco está preso. Um cabo de bronze liga a fechadura ao relógio.")
	if near >= 0 or on_landing:
		_save()

func _enter_landing() -> void:
	on_landing = true
	actor.reparent(landing, false)
	actor.position = Vector2(1020,595)
	actor.facing = -1
	room.hide()
	landing.show()
	_update_near()

func _leave_landing() -> void:
	on_landing = false
	actor.reparent(room, false)
	actor.position = Vector2(state.x,Room.FLOOR)
	actor.facing = 1
	landing.hide()
	room.show()
	_update_near()

func _note(heading: String, body: String) -> void:
	message.text = "[b]%s[/b]\n\n%s" % [heading,body]
	overlay.show()
	dismiss.grab_focus()

func _dismiss() -> void:
	overlay.hide()
	if state.chapter == 3:
		playing = false
		_open_menu()
		return
	if device.visible:
		device.submit.grab_focus()
	if clock.visible:
		clock.test_button.grab_focus()

func _close_clock() -> void:
	clock.hide()
	_save()
	_update_near()

func _record() -> void:
	state.read_record = true
	_save()
	_note("REGISTRO DE VIGÍLIA", "A assinatura da última ronda aparece duas vezes. Na segunda, a hora foi raspada. Sob a tinta resta um traço de carvão apontando para o patamar.")

func _turn(index: int, value: int) -> void:
	state.rings[index] = value
	sound.cue("turn")
	_save()

func _test_clock(correct: bool) -> void:
	if not correct:
		sound.cue("wrong")
		return
	state.solved = true
	room.unlocked = true
	if clock.visible:
		clock.unlock()
	sound.cue("open")
	_save()

func _save() -> void:
	if qa_mode:
		state.valid = true
		return
	if state.save() != OK:
		toast.text = "Não foi possível gravar a investigação."
		toast_left = 4.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready() and (playing or state.valid):
		_save()


func _open_menu() -> void:
	if playing:
		_save()
	menu.running = playing
	menu.has_save = state.valid
	menu.open_main()

func _resume_game() -> void:
	menu.hide()
	playing = true
	if state.chapter == 3:
		_ending()

func _new_game() -> void:
	var replacement := Checkpoint.new()
	if not qa_mode and replacement.save() != OK:
		menu.confirmation.dialog_text = "Não foi possível iniciar uma nova investigação. O checkpoint anterior foi preservado."
		return
	state = replacement
	overlay.hide()
	clock.hide()
	device.hide()
	if on_landing:
		_leave_landing()
	_apply_chapter()
	_resume_game()
	_note("A ÚLTIMA RONDA", "A investigadora Lia Varela chega à mansão para verificar por que a passagem de evacuação foi lacrada. A chave sumiu. O livro de rondas é o único vestígio de quem ficou para trás.")

func _change_options(persist := true) -> void:
	preferences.apply()
	film_layer.visible = preferences.effects
	if persist and not qa_mode and preferences.save() != OK:
		push_warning("Não foi possível gravar as configurações de HollowVeil.")

func _apply_chapter() -> void:
	room.chapter = state.chapter
	room.unlocked = state.solved if state.chapter == 0 else state.wing_solved
	actor.position = Vector2(state.x,Room.FLOOR)
	camera_x = clampf(state.x-595,0,840)
	room.position.x = -camera_x
	room.visible = state.chapter < 3
	actor.visible = state.chapter < 3
	var name_value: String = "Corredor da Vigília"
	if state.chapter in [1,2]:
		name_value = Campaign.WINGS[state.chapter-1].name
	elif state.chapter == 3:
		name_value = "A passagem exterior"
	chapter_name.text = name_value + "    /    IGNF Lab"
	_update_near()

func _interact_wing() -> void:
	var wing: Dictionary = Campaign.WINGS[state.chapter-1]
	match near:
		0: _note(wing.name, "A saída fica na outra extremidade desta ala.")
		1: _note("INSTRUÇÕES",wing.clue)
		2: _note("VESTÍGIO",wing.detail)
		3: device.open_device(state.chapter,state.wing_draft,state.wing_solved)
		4:
			if state.wing_solved:
				_advance()
			else:
				_note("SAÍDA BLOQUEADA",wing.locked)
	if near >= 0:
		_save()

func _close_device() -> void:
	device.hide()
	_save()

func _wing_changed(values: Array[int]) -> void:
	state.wing_draft.assign(values)
	sound.cue("turn")
	_save()

func _wing_solved() -> void:
	state.wing_solved = true
	room.unlocked = true
	sound.cue("open")
	_save()

func _wing_record() -> void:
	_note("COMPROVANTE",Campaign.WINGS[state.chapter-1].reveal)

func _advance() -> void:
	if on_landing:
		_leave_landing()
	state.chapter += 1
	state.wing_draft.clear()
	state.wing_solved = false
	state.x = 260.0
	_apply_chapter()
	_save()
	if state.chapter == 3:
		_ending()
	else:
		var story := "Você segue os vestígios de carvão até a galeria. Há instruções num painel próximo à entrada." if state.chapter == 1 else "Atrás da porta, o arquivo conserva a ordem original. Autentique o documento para abrir a passagem exterior."
		_note(Campaign.WINGS[state.chapter-1].name,story)

func _ending() -> void:
	playing = false
	_note("A PASSAGEM REABERTA", "Lia leva a ordem assinada até o portão. A passagem abre, e o sino finalmente se cala. Antes de sair, ela devolve ao livro os nomes que tinham sido raspados.\n\nFim da investigação · IGNF Lab")


func _qa_input(event: InputEvent) -> void:
	if event.is_action_pressed("qa_help"):
		_note("COMANDOS DE TESTE", "F6 · Resolver o enigma desta ala\nF7 · Avançar para a próxima ala\nF8 · Reiniciar esta ala\n\nO progresso desta sessão fica em memória.")
	elif event.is_action_pressed("qa_solve") and not on_landing:
		if state.chapter == 0:
			state.rings.assign([2,3,3])
			_test_clock(true)
		else:
			state.wing_draft.assign(Device.TARGET if state.chapter == 1 else Device.PROTOCOL)
			_wing_solved()
		_qa_feedback("Enigma marcado como resolvido.")
	elif event.is_action_pressed("qa_advance"):
		state.solved = true
		_advance()
	elif event.is_action_pressed("qa_reset"):
		if on_landing:
			_leave_landing()
		state.x = 260.0
		if state.chapter == 0:
			state.tutorial_step = 0
			state.rings.assign([0,0,0])
			state.solved = false
			state.read_record = false
		state.wing_draft.clear()
		state.wing_solved = false
		_apply_chapter()
		_qa_feedback("Ala reiniciada.")

func _qa_feedback(value: String) -> void:
	toast.text = value
	toast_left = 3.0
