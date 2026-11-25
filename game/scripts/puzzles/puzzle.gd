extends Control
## Base dos enigmas em close-up: tela cheia, botão de voltar, cursor e sons.

signal solved
signal closed

var house = null
var t := 0.0
var done := false
var back := Button.new()


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	back.text = "Voltar"
	back.position = Vector2(8, 334)
	back.size = Vector2(80, 20)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(_on_back)
	build()
	add_child(back)


func _on_back() -> void:
	if not done:
		closed.emit()


## Sobrescrever: monta o enigma.
func build() -> void:
	pass


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func set_cursor(m: String) -> void:
	if house and house.cursor:
		house.cursor.mode = m


func say(who: String, line: String) -> void:
	if house:
		house.subs.say(who, line)


func shake(amount: float) -> void:
	if house and house.post:
		house.post.kick(amount)


func finish() -> void:
	if done:
		return
	done = true
	back.disabled = true
	if is_inside_tree():
		get_tree().create_timer(2.2).timeout.connect(func(): solved.emit())


## Texto de pista (nível 1 ou 2). Sobrescrever com static func hint().
static func hint(_level: int) -> String:
	return "..."


## Moldura de latão com rebites (o mesmo vocabulário do IronVeil).
func brass_frame(r: Rect2, w: float = 2.0) -> void:
	draw_rect(r, Color(0.07, 0.05, 0.045, 0.95))
	draw_rect(r, Color(0.72, 0.5, 0.26), false, w)
	draw_rect(r.grow(-3), Color(0.35, 0.22, 0.12), false, 1.0)
	for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		draw_rect(Rect2(c + (r.get_center() - c).sign() * 5.0 - Vector2(1, 1), Vector2(2, 2)), Color(0.85, 0.66, 0.36))
