extends CanvasLayer
## Legendas com efeito de máquina de escrever. Fila de falas; clique adianta.

signal finished

const COLORS := {
	"MORVANT": Color(0.9, 0.3, 0.22),
	"DÁLIA": Color(0.86, 0.82, 0.74),
	"LEOCÁDIA": Color(0.55, 0.95, 0.88),
	"TOBIAS": Color(0.55, 0.95, 0.88),
	"BENEDITA": Color(0.55, 0.95, 0.88),
	"CELESTE": Color(0.55, 0.95, 0.88),
	"HÉLIO": Color(0.55, 0.95, 0.88),
	"OFÉLIA": Color(0.75, 0.85, 1.0),
	"ANSELMO": Color(0.95, 0.9, 0.72),
	"": Color(0.75, 0.7, 0.62),
}

var queue: Array = []
var panel := PanelContainer.new()
var who := Label.new()
var text := Label.new()
var shown := 0.0
var hold := 0.0
var current: Array = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.position = Vector2(70, 296)
	panel.size = Vector2(500, 54)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	who.add_theme_font_size_override("font_size", 10)
	box.add_child(who)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(484, 30)
	text.add_theme_font_size_override("font_size", 11)
	box.add_child(text)
	panel.hide()
	State.settings_changed.connect(_apply_size)
	_apply_size()


## Legendas grandes: fonte maior e painel mais alto.
func _apply_size() -> void:
	var big := State.sub_size == 1
	who.add_theme_font_size_override("font_size", 12 if big else 10)
	text.add_theme_font_size_override("font_size", 14 if big else 11)
	panel.position = Vector2(50 if big else 70, 280 if big else 296)
	panel.size = Vector2(540 if big else 500, 70 if big else 54)
	text.custom_minimum_size = Vector2(524 if big else 484, 46 if big else 30)


func say(speaker: String, line: String, seconds: float = -1.0) -> void:
	var slow: float = [1.45, 1.0, 0.7][clampi(State.sub_speed, 0, 2)]
	queue.append([speaker, line, seconds if seconds > 0.0 else (1.6 + line.length() * 0.055) * slow])
	if current.is_empty():
		_next()


func busy() -> bool:
	return not current.is_empty()


func clear() -> void:
	queue.clear()
	current = []
	panel.hide()


## Clique: completa a frase; segundo clique pula para a próxima.
func advance() -> void:
	if current.is_empty():
		return
	if shown < String(current[1]).length():
		shown = String(current[1]).length()
	else:
		hold = 0.0


func _next() -> void:
	if queue.is_empty():
		current = []
		panel.hide()
		finished.emit()
		return
	current = queue.pop_front()
	who.text = current[0]
	who.add_theme_color_override("font_color", COLORS.get(current[0], COLORS[""]))
	text.text = ""
	shown = 0.0
	hold = current[2]
	panel.show()
	if current[0] == "MORVANT":
		Audio.play("whisper", -14.0, 0.6)


func _process(delta: float) -> void:
	if current.is_empty():
		return
	var full: String = current[1]
	if shown < full.length():
		shown = minf(full.length(), shown + delta * [30.0, 48.0, 90.0][clampi(State.sub_speed, 0, 2)])
		text.text = full.substr(0, int(shown))
	else:
		text.text = full
		hold -= delta
		if hold <= 0.0:
			_next()
