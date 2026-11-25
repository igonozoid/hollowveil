extends CanvasLayer
## Cursor desenhado por código. O formato diz o que o clique vai fazer:
## chama (nada), passos (andar), olho (examinar), coração (enigma),
## boca (voz/evento), cadeado (fechado), mão (pegar/mover peça).

var mode := "flame"
var t := 0.0
var node := Node2D.new()


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(node)
	node.draw.connect(_paint)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _process(delta: float) -> void:
	t += delta
	node.position = node.get_viewport().get_mouse_position().round()
	node.queue_redraw()


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	node.draw_rect(Rect2(x, y, w, h), c)


func _paint() -> void:
	var dark := Color(0.05, 0.03, 0.03)
	match mode:
		"walk":
			# Seta grossa com pegadas: avançar.
			var pts := PackedVector2Array([Vector2(0, -9), Vector2(7, -1), Vector2(3, -1), Vector2(3, 7), Vector2(-3, 7), Vector2(-3, -1), Vector2(-7, -1)])
			var bob := Vector2(0, round(sin(t * 8.0)))
			var outline := PackedVector2Array()
			for p in pts:
				outline.append(p * 1.25 + bob)
			node.draw_colored_polygon(outline, dark)
			var inner := PackedVector2Array()
			for p in pts:
				inner.append(p + bob)
			node.draw_colored_polygon(inner, Color(0.92, 0.82, 0.62))
		"look":
			node.draw_colored_polygon(_eye(9.0, 5.0), dark)
			node.draw_colored_polygon(_eye(8.0, 4.0), Color(0.92, 0.88, 0.8))
			var look := Vector2(sin(t * 1.3) * 2.0, 0).round()
			node.draw_circle(look, 2.6, Color(0.5, 0.12, 0.1))
			node.draw_circle(look, 1.2, dark)
		"puzzle":
			var beat := 1.0 + 0.25 * maxf(0.0, sin(t * 7.0)) * maxf(0.0, sin(t * 3.5))
			node.draw_colored_polygon(_heart(7.5 * beat), dark)
			node.draw_colored_polygon(_heart(6.0 * beat), Color(0.75, 0.06, 0.08))
			_px(-2, -3, 2, 2, Color(1, 0.5, 0.5))
		"voice":
			var open := 1.0 + 2.0 * absf(sin(t * 6.0))
			node.draw_colored_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(0, -4 - open), Vector2(8, 0), Vector2(0, 4 + open)]), dark)
			node.draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(0, -2 - open), Vector2(6, 0), Vector2(0, 2 + open)]), Color(0.55, 0.08, 0.1))
			_px(-3, -1, 6, 1, Color(0.95, 0.9, 0.8))
		"locked":
			node.draw_arc(Vector2(0, -3), 4.0, PI, TAU, 8, dark, 3.0)
			node.draw_arc(Vector2(0, -3), 4.0, PI, TAU, 8, Color(0.7, 0.55, 0.3), 1.0)
			_px(-6, -3, 12, 10, dark)
			_px(-5, -2, 10, 8, Color(0.7, 0.55, 0.3))
			_px(-1, 0, 2, 4, dark)
		"hand":
			_px(-4, -2, 9, 9, dark)
			_px(-3, -1, 7, 7, Color(0.86, 0.72, 0.6))
			for i in 4:
				_px(-4 + i * 2, -7, 2, 6, dark)
				_px(-3 + i * 2, -6, 1, 5, Color(0.86, 0.72, 0.6))
		_:
			var fl := 1.0 + 0.2 * sin(t * 11.0) * sin(t * 5.3)
			node.draw_colored_polygon(PackedVector2Array([Vector2(0, -9 * fl), Vector2(4, -1), Vector2(0, 3), Vector2(-4, -1)]), dark)
			node.draw_colored_polygon(PackedVector2Array([Vector2(0, -7 * fl), Vector2(3, -1), Vector2(0, 2), Vector2(-3, -1)]), Color(1.0, 0.66, 0.25))
			_px(-1, -2, 2, 3, Color(1, 0.95, 0.7))


func _eye(w: float, h: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		var y := sin(a) * h * (1.0 if sin(a) < 0 else 1.0)
		p.append(Vector2(cos(a) * w, y * absf(cos(a * 0.5)) + y * 0.4))
	return p


func _heart(s: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		var x := 16.0 * pow(sin(a), 3)
		var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
		p.append(Vector2(x, y) * s / 16.0)
	return p
