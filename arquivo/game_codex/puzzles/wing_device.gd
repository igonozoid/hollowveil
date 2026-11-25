extends ColorRect

signal changed(values: Array[int])
signal solved
signal closed
signal record_requested

const TARGET := [1,0,1,0,1]
const PROTOCOL := [0,1,1,2]
var chapter := 1
var values: Array[int] = []
var done := false
var header := Label.new()
var display := Label.new()
var feedback := Label.new()
var keys: Array[Button] = []
var submit := Button.new()
var reset := Button.new()
var back := Button.new()

func _ready() -> void:
	size = Vector2(1280,720)
	color = Color("#101619")
	_label(header,120,33)
	_label(display,239,39)
	_label(feedback,432,19)
	for index in 5:
		var button := Button.new()
		button.position = Vector2(286+index*144,335)
		button.size = Vector2(130,52)
		button.add_theme_font_size_override("font_size",20)
		button.pressed.connect(_activate.bind(index))
		add_child(button)
		keys.append(button)
	_button(submit,"Testar",Vector2(390,508),_verify)
	_button(reset,"Limpar",Vector2(650,508),_clear)
	_button(back,"Voltar",Vector2(520,574),func(): closed.emit())
	hide()

func open_device(wing: int, draft: Array[int], unlocked: bool) -> void:
	chapter = wing
	done = unlocked
	values.assign(draft)
	if values.is_empty() and chapter == 1:
		values.assign([0,0,0,0,0])
	header.text = "PAINEL DE LANTERNAS" if chapter == 1 else "IMPRESSORA DE SELOS"
	feedback.text = "O comprovante está disponível." if done else ""
	for index in keys.size():
		keys[index].visible = not done and (chapter == 1 or index < 3)
		keys[index].text = str(index+1) if chapter == 1 else ["Água","Voz","Nome","",""][index]
	reset.visible = not done
	show()
	_refresh()
	if done:
		submit.grab_focus()
	else:
		keys[0].grab_focus()

func _activate(index: int) -> void:
	if not visible or done:
		return
	if chapter == 1:
		for light in range(maxi(0,index-1),mini(5,index+2)):
			values[light] = 1-values[light]
	elif values.size() < 4:
		values.append(index)
	else:
		feedback.text = "Quatro selos preenchidos. Teste ou limpe a ordem."
		return
	feedback.text = ""
	changed.emit(values)
	_refresh()

func _clear() -> void:
	values.clear()
	if chapter == 1:
		values.assign([0,0,0,0,0])
	feedback.text = ""
	changed.emit(values)
	_refresh()

func _verify() -> void:
	if done:
		record_requested.emit()
	elif values == (TARGET if chapter == 1 else PROTOCOL):
		done = true
		feedback.text = "Aceito. A saída foi liberada."
		for button in keys:
			button.hide()
		reset.hide()
		_refresh()
		submit.grab_focus()
		solved.emit()
	else:
		feedback.text = "A ordem ainda não confere."

func _refresh() -> void:
	var marks := PackedStringArray()
	for value in values:
		marks.append(["○","●"][value] if chapter == 1 else ["Água","Voz","Nome"][value])
	display.text = "    ".join(marks) if not values.is_empty() else "Aguardando selos"
	submit.text = "Ler comprovante" if done else "Testar"
	queue_redraw()

func _label(label: Label,y: float,font_size: int) -> void:
	label.position = Vector2(120,y)
	label.size = Vector2(1040,63)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color",Color("#dfbb86"))
	label.add_theme_font_size_override("font_size",font_size)
	add_child(label)

func _button(button: Button,caption: String,at: Vector2,action: Callable) -> void:
	button.position = at
	button.size = Vector2(240,48)
	button.text = caption
	button.pressed.connect(action)
	add_child(button)

func _draw() -> void:
	draw_rect(Rect2(254,91,772,550),Color("#795d49"),false,2)
	draw_rect(Rect2(275,208,730,198),Color("#2a2825"),false,3)
