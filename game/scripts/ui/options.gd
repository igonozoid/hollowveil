extends PanelContainer
## Opções: gore, efeitos, Modo VGA, tela cheia e volumes.

signal back

var gore_b := Button.new()
var fx_b := Button.new()
var vga_b := Button.new()
var full_b := Button.new()
var music_s := HSlider.new()
var sfx_s := HSlider.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(240, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var title := Label.new()
	title.text = "OPÇÕES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.85, 0.66, 0.36))
	box.add_child(title)
	for b in [gore_b, fx_b, vga_b, full_b]:
		b.focus_mode = Control.FOCUS_NONE
		box.add_child(b)
	gore_b.pressed.connect(func():
		State.gore = not State.gore
		_refresh())
	fx_b.pressed.connect(func():
		State.effects = not State.effects
		_refresh())
	vga_b.pressed.connect(func():
		State.vga = not State.vga
		_refresh())
	full_b.pressed.connect(func():
		State.fullscreen = not State.fullscreen
		State.apply_prefs()
		_refresh())
	for pair in [["Música", music_s, State.music_volume], ["Sons", sfx_s, State.sfx_volume]]:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = pair[0]
		l.custom_minimum_size = Vector2(60, 0)
		row.add_child(l)
		var s: HSlider = pair[1]
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = pair[2]
		s.custom_minimum_size = Vector2(160, 14)
		s.focus_mode = Control.FOCUS_NONE
		row.add_child(s)
		box.add_child(row)
	music_s.value_changed.connect(func(v):
		State.music_volume = v
		State.apply_prefs())
	sfx_s.value_changed.connect(func(v):
		State.sfx_volume = v
		State.apply_prefs()
		Audio.play("tile", -6.0))
	var close := Button.new()
	close.text = "Voltar"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func():
		State.save_prefs()
		back.emit())
	box.add_child(close)
	_refresh()


func _refresh() -> void:
	gore_b.text = "Gore: " + ("Ligado" if State.gore else "Desligado")
	fx_b.text = "Efeitos de tela: " + ("Ligados" if State.effects else "Desligados")
	vga_b.text = "Modo VGA (pontilhado): " + ("Ligado" if State.vga else "Desligado")
	full_b.text = "Tela cheia: " + ("Sim" if State.fullscreen else "Não")
	State.save_prefs()
	State.settings_changed.emit()
