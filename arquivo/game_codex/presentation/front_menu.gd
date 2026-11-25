extends Control

signal resume_requested
signal new_requested
signal options_changed
signal quit_requested

const GOLD := Color("#dcb886")
var preferences: RefCounted
var splash := false
var running := false
var has_save := false
var page := "main"
var content := VBoxContainer.new()
var title := Label.new()
var confirmation := ConfirmationDialog.new()
var splash_timer: Tween

func _ready() -> void:
	size = Vector2(1280,720)
	title.position = Vector2(120,236)
	title.size = Vector2(1040,91)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",56)
	title.add_theme_color_override("font_color",GOLD)
	add_child(title)
	content.position = Vector2(430,342)
	content.size = Vector2(420,0)
	content.add_theme_constant_override("separation",10)
	add_child(content)
	confirmation.title = "Iniciar nova investigação"
	confirmation.dialog_text = "Uma nova investigação substituirá seu checkpoint atual."
	confirmation.get_ok_button().text = "Começar"
	confirmation.get_cancel_button().text = "Cancelar"
	confirmation.confirmed.connect(func(): new_requested.emit())
	add_child(confirmation)

func show_splash() -> void:
	splash = true
	title.text = "IGNF Lab"
	content.hide()
	show()
	queue_redraw()
	splash_timer = create_tween()
	splash_timer.tween_interval(1.5)
	splash_timer.tween_callback(finish_splash)

func finish_splash() -> void:
	if not splash:
		return
	splash = false
	if splash_timer and splash_timer.is_running():
		splash_timer.kill()
	open_main()

func open_main() -> void:
	page = "main"
	_reset("HOLLOWVEIL")
	if running or has_save:
		_button("Continuar",func(): resume_requested.emit())
	_button("Nova investigação",_new_game)
	_button("Configurações",_options)
	_button("Créditos",_credits)
	_button("Sair",func(): quit_requested.emit())

func _new_game() -> void:
	if has_save or running:
		confirmation.popup_centered(Vector2i(470,178))
	else:
		new_requested.emit()

func _options() -> void:
	page = "options"
	_reset("CONFIGURAÇÕES")
	_caption("Volume geral")
	var volume := HSlider.new()
	volume.max_value = 1
	volume.step = 0.05
	volume.value = preferences.volume
	volume.custom_minimum_size.y = 28
	volume.value_changed.connect(func(value: float):
		preferences.volume = value
		options_changed.emit()
	)
	content.add_child(volume)
	_toggle("Tela cheia",preferences.fullscreen,func(value: bool):
		preferences.fullscreen = value
		options_changed.emit()
	)
	_toggle("Efeitos visuais",preferences.effects,func(value: bool):
		preferences.effects = value
		options_changed.emit()
	)
	_button("Voltar",open_main)

func _credits() -> void:
	page = "credits"
	_reset("CRÉDITOS")
	_caption("HollowVeil · Uma produção IGNF Lab")
	_caption("Arte procedural · IGNF Vector Cinema")
	_caption("Godot Engine · Licença MIT")
	_button("Voltar",open_main)

func _reset(caption: String) -> void:
	title.text = caption
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	content.show()
	show()
	queue_redraw()

func _button(caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 43
	button.add_theme_font_size_override("font_size",20)
	button.pressed.connect(action)
	content.add_child(button)
	if not get_viewport().gui_get_focus_owner() or content.get_child_count() == 1:
		button.grab_focus()

func _caption(caption: String) -> void:
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",20)
	content.add_child(label)

func _toggle(caption: String, selected: bool, action: Callable) -> void:
	var button := CheckButton.new()
	button.text = caption
	button.button_pressed = selected
	button.custom_minimum_size.y = 39
	button.add_theme_font_size_override("font_size",18)
	button.toggled.connect(action)
	content.add_child(button)
	if get_viewport().gui_get_focus_owner() == null:
		button.grab_focus()

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#11191c"))
	for i in range(12,0,-1):
		draw_circle(Vector2(640,185),i*26,Color(0.56,0.35,0.21,0.022),true,-1,true)
	draw_rect(Rect2(55,42,1170,635),Color("#6d5645"),false,1)
	draw_rect(Rect2(67,54,1146,611),Color("#2c3432"),false,2)
	var crest := PackedVector2Array([
		Vector2(591,215),Vector2(591,145),Vector2(603,119),Vector2(640,84),
		Vector2(677,119),Vector2(689,145),Vector2(689,215),Vector2(591,215)])
	draw_polyline(crest,GOLD,2,true)
	draw_line(Vector2(616,135),Vector2(640,190),GOLD,4,true)
	draw_line(Vector2(640,190),Vector2(664,135),GOLD,4,true)
	draw_line(Vector2(640,100),Vector2(640,150),GOLD,1,true)
	draw_arc(Vector2(640,158),20,0,TAU,36,Color("#876b53"),1,true)
	draw_line(Vector2(286,324),Vector2(994,324),Color("#715849"),1,true)
