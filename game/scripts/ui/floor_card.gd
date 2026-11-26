extends CanvasLayer
## Cartão de andar (nome grande no meio da tela, ao trocar de andar) e o nome
## do cômodo (discreto, no canto de baixo, a cada entrada).

const FLOORS := {
	"terreo": ["O TÉRREO", "onde o jantar foi servido"],
	"quartos": ["O PRIMEIRO ANDAR", "onde a família dormia"],
	"poroes": ["OS PORÕES", "as fundações da casa"],
	"sotao": ["O SÓTÃO", "onde o espetáculo espera"],
}

var big := Label.new()
var small := Label.new()
var room := Label.new()
var line := ColorRect.new()
var _tw: Tween
var _room_tw: Tween


func _ready() -> void:
	layer = 9
	for l in [big, small, room]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		add_child(l)
	var spaced := FontVariation.new()
	spaced.base_font = ThemeDB.fallback_font
	spaced.spacing_glyph = 4
	spaced.variation_embolden = 0.5
	big.add_theme_font_override("font", spaced)
	big.add_theme_font_size_override("font_size", 26)
	big.add_theme_color_override("font_color", Color(0.93, 0.88, 0.78))
	big.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	big.add_theme_constant_override("shadow_offset_y", 2)
	big.position = Vector2(0, 140)
	big.size = Vector2(640, 36)
	small.add_theme_font_size_override("font_size", 11)
	small.add_theme_color_override("font_color", Color(0.8, 0.2, 0.18))
	small.position = Vector2(0, 186)
	small.size = Vector2(640, 18)
	line.color = Color(0.55, 0.06, 0.06)
	line.position = Vector2(220, 180)
	line.size = Vector2(200, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.modulate.a = 0.0
	add_child(line)
	room.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	room.add_theme_font_size_override("font_size", 10)
	room.add_theme_color_override("font_color", Color(0.85, 0.78, 0.66))
	room.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	room.position = Vector2(14, 336)
	room.size = Vector2(300, 16)


func show_floor(grade: String) -> void:
	if not FLOORS.has(grade):
		return
	big.text = FLOORS[grade][0]
	small.text = FLOORS[grade][1]
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_interval(0.6)
	# Entra junto (os três ao mesmo tempo), espera e sai junto.
	_tw.tween_property(big, "modulate:a", 1.0, 0.8)
	_tw.parallel().tween_property(small, "modulate:a", 1.0, 0.8)
	_tw.parallel().tween_property(line, "modulate:a", 1.0, 0.8)
	_tw.tween_interval(1.8)
	_tw.tween_property(big, "modulate:a", 0.0, 1.0)
	_tw.parallel().tween_property(small, "modulate:a", 0.0, 1.0)
	_tw.parallel().tween_property(line, "modulate:a", 0.0, 1.0)


func show_room(title: String) -> void:
	room.text = title.to_upper()
	if _room_tw:
		_room_tw.kill()
	_room_tw = create_tween()
	_room_tw.tween_property(room, "modulate:a", 0.85, 0.5)
	_room_tw.tween_interval(2.2)
	_room_tw.tween_property(room, "modulate:a", 0.0, 1.0)
