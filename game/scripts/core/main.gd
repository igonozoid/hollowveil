extends Node
## Raiz do jogo: troca entre menu, introdução, casa e tela final; cuida da
## pausa, do Esc e das camadas globais (pós-processamento e cursor).

const PostFx := preload("res://scripts/gfx/post_fx.gd")
const CursorLayer := preload("res://scripts/ui/cursor.gd")
const Menu := preload("res://scripts/ui/menu.gd")
const Intro := preload("res://scripts/ui/intro.gd")
const House := preload("res://scripts/house/house.gd")
const EndCard := preload("res://scripts/ui/end_card.gd")
const Options := preload("res://scripts/ui/options.gd")
const Relicario := preload("res://scripts/ui/relicario.gd")

var post: CanvasLayer
var cursor: CanvasLayer
var screen: Node = null
var pause_layer := CanvasLayer.new()
var pause_box := VBoxContainer.new()
var pause_options: PanelContainer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	post = PostFx.new()
	add_child(post)
	cursor = CursorLayer.new()
	add_child(cursor)
	_build_pause()
	show_menu()


func _swap(node: Node) -> void:
	if screen:
		screen.queue_free()
	screen = node
	add_child(node)
	move_child(node, 0)


func show_menu() -> void:
	get_tree().paused = false
	pause_layer.hide()
	var m := Menu.new()
	m.new_game.connect(_new_game)
	m.dark_game.connect(func(): _new_game(true))
	m.continue_game.connect(_continue)
	m.quit.connect(func(): get_tree().quit())
	_swap(m)
	post.grade("menu")
	cursor.mode = "flame"


func _new_game(dark: bool = false) -> void:
	State.new_game(dark)
	var intro := Intro.new()
	intro.done.connect(_enter_house)
	_swap(intro)


func _continue() -> void:
	if State.load_game():
		_enter_house()
	else:
		_new_game()


func _enter_house() -> void:
	var h := House.new()
	h.cursor = cursor
	h.post = post
	h.slice_finished.connect(_end)
	_swap(h)
	post.grade("terreo")


func _end() -> void:
	var e := EndCard.new()
	if State.last_ending != "":
		# A volta acabou: o save some, os finais vistos ficam nas preferências.
		e.done.connect(func():
			State.clear_save()
			show_menu())
	else:
		State.save_game()
		e.done.connect(show_menu)
	_swap(e)
	post.grade("menu")


# ---------------------------------------------------------------- pausa

func _build_pause() -> void:
	pause_layer.layer = 15
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(220, 100)
	panel.custom_minimum_size = Vector2(200, 0)
	pause_layer.add_child(panel)
	pause_box.add_theme_constant_override("separation", 5)
	panel.add_child(pause_box)
	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.85, 0.66, 0.36))
	pause_box.add_child(title)
	for pair in [["Continuar", _resume], ["Relicário", _pause_relics], ["Opções", _pause_options], ["Salvar e voltar ao menu", func():
			State.save_game()
			show_menu()]]:
		var b := Button.new()
		b.text = pair[0]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(pair[1])
		pause_box.add_child(b)
	pause_layer.hide()


func _pause() -> void:
	get_tree().paused = true
	pause_layer.show()
	pause_box.get_parent().show()
	cursor.mode = "flame"


func _resume() -> void:
	if pause_options:
		pause_options.queue_free()
		pause_options = null
	get_tree().paused = false
	pause_layer.hide()


func _pause_relics() -> void:
	pause_box.get_parent().hide()
	var r := Relicario.new()
	pause_layer.add_child(r)
	r.back.connect(func():
		r.queue_free()
		pause_box.get_parent().show())


func _pause_options() -> void:
	pause_box.get_parent().hide()
	pause_options = Options.new()
	pause_options.position = Vector2(200, 90)
	pause_layer.add_child(pause_options)
	pause_options.back.connect(func():
		pause_options.queue_free()
		pause_options = null
		pause_box.get_parent().show())


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F11:
		State.fullscreen = not State.fullscreen
		State.apply_prefs()
		State.save_prefs()
		return
	if event.keycode != KEY_ESCAPE:
		return
	if pause_layer.visible:
		_resume()
		return
	if screen is House:
		var h = screen
		if h.mode == "puzzle" and h.puzzle and not h.puzzle.done:
			h.puzzle.closed.emit()
		elif h.mode == "ghost" and h.stage:
			h.stage.skip()
		elif h.mode == "explore":
			_pause()
		get_viewport().set_input_as_handled()
