extends CanvasLayer
## HUD mínimo: a vela da sanidade (canto superior esquerdo) e o aviso de
## item ou nota (canto superior direito, painel de latão como no IronVeil).

var node := Node2D.new()
var toast := PanelContainer.new()
var toast_label := Label.new()
var toast_t := 0.0
var t := 0.0
var shown_sanity := 100.0


func _ready() -> void:
	layer = 9
	add_child(node)
	node.draw.connect(_paint)
	toast.position = Vector2(430, 10)
	toast.custom_minimum_size = Vector2(200, 0)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.add_theme_font_size_override("font_size", 11)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.custom_minimum_size = Vector2(184, 0)
	toast.add_child(toast_label)
	add_child(toast)
	toast.hide()


func notify(msg: String, seconds: float = 3.5) -> void:
	toast_label.text = msg
	toast.reset_size()
	toast.position = Vector2(630 - toast.size.x, 10)
	toast.show()
	toast_t = seconds


func _process(delta: float) -> void:
	t += delta
	shown_sanity = move_toward(shown_sanity, State.sanity, delta * 20.0)
	if toast_t > 0.0:
		toast_t -= delta
		if toast_t <= 0.0:
			toast.hide()
	node.queue_redraw()


func _paint() -> void:
	# Pires de latão, vela que derrete conforme a sanidade, chama.
	var base := Vector2(18, 44)
	var h := 4.0 + 22.0 * shown_sanity / 100.0
	node.draw_rect(Rect2(base + Vector2(-8, 0), Vector2(16, 2)), Color(0.6, 0.44, 0.2))
	node.draw_rect(Rect2(base + Vector2(-6, 2), Vector2(12, 1)), Color(0.35, 0.25, 0.12))
	node.draw_rect(Rect2(base + Vector2(-3, -h), Vector2(6, h)), Color(0.86, 0.8, 0.68))
	node.draw_rect(Rect2(base + Vector2(2, -h), Vector2(1, h)), Color(0.7, 0.62, 0.5))
	# Cera escorrida (fica vermelha quando a mente cede).
	var wax := Color(0.86, 0.8, 0.68).lerp(Color(0.6, 0.05, 0.05), State.madness())
	node.draw_rect(Rect2(base + Vector2(-3, -h), Vector2(1, minf(h, 3.0 + 6.0 * State.madness()))), wax)
	var fl := 1.0 + 0.25 * sin(t * 12.0) * sin(t * 4.7)
	var tip := base + Vector2(0, -h - 1)
	node.draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -7 * fl), tip + Vector2(3, 0), tip + Vector2(0, 2), tip + Vector2(-3, 0)]), Color(1.0, 0.6, 0.2))
	node.draw_rect(Rect2(tip + Vector2(-1, -2), Vector2(2, 2)), Color(1, 0.95, 0.75))
