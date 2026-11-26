extends Control
## O Relicário: as 40 relíquias numa caixa de veludo. As achadas em qualquer
## volta aparecem; as desta volta têm um ponto de latão. Passe o mouse para
## ler.

signal back

const Relics := preload("res://scripts/core/relics.gd")
const COLS := 8
const SLOT := Vector2(52, 34)
const ORIGIN := Vector2(112, 60)

var hover := -1
var t := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var b := Button.new()
	b.text = "Voltar"
	b.position = Vector2(280, 330)
	b.size = Vector2(80, 20)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): back.emit())
	add_child(b)


func _slot_rect(i: int) -> Rect2:
	return Rect2(ORIGIN + Vector2(i % COLS, i / COLS) * (SLOT + Vector2(1, 1)), SLOT)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = -1
		for i in Relics.LIST.size():
			if _slot_rect(i).has_point(event.position):
				hover = i


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.012, 0.96))
	var font := get_theme_default_font()
	draw_rect(Rect2(ORIGIN - Vector2(10, 10), Vector2(COLS * (SLOT.x + 1) + 20, 5 * (SLOT.y + 1) + 20)), Color(0.22, 0.04, 0.06))
	draw_rect(Rect2(ORIGIN - Vector2(10, 10), Vector2(COLS * (SLOT.x + 1) + 20, 5 * (SLOT.y + 1) + 20)), Color(0.72, 0.5, 0.26), false, 2.0)
	var found := 0
	for i in Relics.LIST.size():
		var r: Array = Relics.LIST[i]
		var rect := _slot_rect(i)
		draw_rect(rect, Color(0.12, 0.02, 0.03) if i != hover else Color(0.2, 0.05, 0.06))
		var known: bool = r[0] in State.relics_all
		if known:
			found += 1
			Relics.draw_icon(self, rect.get_center(), r[2], 2.0)
			if State.has_relic(r[0]):
				draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(3, 3)), Color(0.85, 0.66, 0.36))
		else:
			draw_string(font, rect.position + Vector2(0, 22), "?", HORIZONTAL_ALIGNMENT_CENTER, SLOT.x, 12, Color(0.35, 0.18, 0.18))
	draw_string(font, Vector2(0, 26), "O RELICÁRIO", HORIZONTAL_ALIGNMENT_CENTER, 640, 13, Color(0.85, 0.66, 0.36))
	draw_string(font, Vector2(0, 42), "%d de 40 encontradas · nesta volta: %d" % [found, State.relics.size()], HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color(0.7, 0.62, 0.52))
	var text := "Páginas do diário, fotografias e peças, escondidas pela casa. Algumas só aparecem depois de um enigma."
	var title := ""
	if hover >= 0:
		var h: Array = Relics.LIST[hover]
		if h[0] in State.relics_all:
			title = h[5]
			text = h[6]
		else:
			title = "?"
			text = "Ainda escondida em algum lugar da casa."
	if State.dark_night_open() and hover < 0:
		text += "  A Noite Mais Escura está aberta no menu."
	draw_string(font, Vector2(60, 266), title, HORIZONTAL_ALIGNMENT_LEFT, 520, 10, Color(0.95, 0.8, 0.55))
	draw_multiline_string(font, Vector2(60, 282), text, HORIZONTAL_ALIGNMENT_LEFT, 520, 9, 4, Color(0.82, 0.78, 0.7))
