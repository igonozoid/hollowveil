extends Node2D
## Fim da fatia vertical: resumo da noite e chamada para o Ato II.

signal done

var t := 0.0
var label := Label.new()


func _ready() -> void:
	label.position = Vector2(80, 70)
	label.size = Vector2(480, 220)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	var hints := 0
	for k in State.hints:
		hints += int(State.hints[k])
	var host := 0
	for k in State.flags:
		if String(k).begins_with("host_solved_"):
			host += 1
	var mins := int(State.play_time / 60.0)
	label.text = "FIM DA PRIMEIRA NOITE\n\nTrês almas libertadas. Cinco ainda esperam lá em cima.\n\nTempo: %d min   ·   Sanidade: %d%%   ·   Pistas: %d   ·   Resolvidos por Morvant: %d\n\n\nATO II — OS QUARTOS\nem construção\n\n\nclique para voltar ao menu" % [mins, int(State.sanity), hints, host]
	add_child(label)
	Audio.music("menu")


func _unhandled_input(event: InputEvent) -> void:
	if t > 1.5 and event is InputEventMouseButton and event.pressed:
		done.emit()


func _process(delta: float) -> void:
	t += delta
	label.modulate.a = minf(1.0, t / 1.5)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.01))
	for i in 12:
		var x := fmod(i * 57.0, 640.0)
		draw_rect(Rect2(x, 0, 1, fmod(t * (10.0 + i * 3.0), 360.0)), Color(0.4, 0.0, 0.02, 0.6))
