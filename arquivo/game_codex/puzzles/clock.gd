extends Control

signal turned(index: int, value: int)
signal tested(correct: bool)
signal closed
signal record_requested

const MARKS := ["◆", "●", "▲", "✦"]
const RINGS := [[1, 2, 0, 3], [3, 1, 0, 2], [2, 1, 0, 3]]
const TARGET := [0, 2, 3]
const GOLD := Color("#d9b17b")
var values: Array[int] = [0, 0, 0]
var solved := false
var compartment := 0.0
var ring_buttons: Array[Button] = []
var test_button: Button
var close_button: Button
var feedback := Label.new()
var title := Label.new()

func _ready() -> void:
	size = Vector2(1280,720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label(title, "O RELÓGIO DA VIGÍLIA", Rect2(305,125,670,55), 34)
	_label(feedback, "", Rect2(265,448,750,40), 20)
	for index in 3:
		var button := _button("", Vector2(398+index*166,352), Vector2(152,45))
		button.pressed.connect(_turn.bind(index))
		button.text = "Girar anel %d" % (index+1)
		ring_buttons.append(button)
	test_button = _button("Testar combinação", Vector2(459,507), Vector2(362,49))
	test_button.pressed.connect(_test)
	close_button = _button("Voltar ao corredor", Vector2(459,571), Vector2(362,43))
	close_button.pressed.connect(func(): closed.emit())
	hide()

func show_clock(positions: Array[int], unlocked: bool) -> void:
	values.assign(positions)
	solved = unlocked
	compartment = 1.0 if solved else 0.0
	feedback.text = "O compartimento está aberto." if solved else "Alinhe as três marcas na ordem do painel de rondas."
	show()
	_refresh()
	if solved:
		test_button.grab_focus()
	else:
		ring_buttons[0].grab_focus()

func unlock() -> void:
	solved = true
	create_tween().tween_method(_open_compartment, 0.0, 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	feedback.text = "O trinco cede. Há um registro dentro do relógio."
	_refresh()
	test_button.grab_focus()

func _open_compartment(amount: float) -> void:
	compartment = amount
	queue_redraw()

func _turn(index: int) -> void:
	values[index] = (values[index]+1)%4
	feedback.text = ""
	turned.emit(index,values[index])
	_refresh()

func _test() -> void:
	if solved:
		record_requested.emit()
		return
	for index in 3:
		if RINGS[index][values[index]] != TARGET[index]:
			feedback.text = "O trinco permanece fechado."
			tested.emit(false)
			return
	tested.emit(true)

func _refresh() -> void:
	for button in ring_buttons:
		button.disabled = solved
	test_button.text = "Ler registro" if solved else "Testar combinação"
	queue_redraw()

func _button(caption: String, at: Vector2, dimensions: Vector2) -> Button:
	var result := Button.new()
	result.text = caption
	result.position = at
	result.size = dimensions
	result.add_theme_font_size_override("font_size", 18)
	add_child(result)
	return result

func _label(label: Label, caption: String, box: Rect2, font_size: int) -> void:
	label.text = caption
	label.position = box.position
	label.size = box.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", GOLD)
	add_child(label)

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(0.02,0.025,0.032,0.89))
	for index in 48:
		var y := 96.0+index*11.45
		var shade := 0.56 + 0.35*cos(index*0.078)
		draw_rect(Rect2(292,y,696,12),Color("#453135").darkened(1.0-shade))
	draw_rect(Rect2(292,96,696,549),Color("#835f4b"),false,4)
	draw_rect(Rect2(310,114,660,511),Color("#3c2429"),false,2)
	for x in [330,950]:
		for y in [130,610]:
			var screw := Vector2(x,y)
			draw_circle(screw,5,Color("#977553"),true,-1,true)
			draw_line(screw+Vector2(-3,3),screw+Vector2(3,-3),Color("#3a2926"),1,true)
	draw_rect(Rect2(302,106,676,529),Color("#624735"),false,2)
	draw_rect(Rect2(317,196,646,239),Color("#131a1c"))
	for index in 3:
		var center := Vector2(474+index*166,272)
		draw_circle(center+Vector2(1,4),76,Color("#0b1011"),true,-1,true)
		draw_circle(center,73,Color("#5b4434"),true,-1,true)
		draw_circle(center,48,Color("#302624"),true,-1,true)
		draw_arc(center,71,PI*0.88,TAU*0.87,44,Color("#f2c68b"),3,true)
		draw_arc(center,65,0.1,PI*0.86,22,Color("#7b563c"),4,true)
		draw_arc(center,69,0,TAU,72,GOLD,2,true)
		draw_arc(center,53,0,TAU,64,Color("#b28d61"),1,true)
		for tick in 16:
			var ray := Vector2.from_angle(tick*TAU/16.0)
			draw_line(center+ray*59,center+ray*64,GOLD,1,true)
		var mark: String = MARKS[RINGS[index][values[index]]]
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(mark,HORIZONTAL_ALIGNMENT_LEFT,-1,36).x
		draw_string(font,center+Vector2(-width/2,13),mark,HORIZONTAL_ALIGNMENT_LEFT,-1,36,GOLD)

	if solved:
		draw_rect(Rect2(326,404,628,22),Color("#0b1012"))
		draw_rect(Rect2(330,408,620*compartment,14),Color("#ae875d"))
