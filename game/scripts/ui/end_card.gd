extends Node2D
## Tela do final: qual final, o epílogo, os números da volta e os finais vistos.

signal done

const ENDINGS := {
	"medium": ["FINAL: A MÉDIUM", "Sete almas libertadas, nenhuma lembrança perdida. A casa Morvant foi a leilão na primavera e ninguém quis comprá-la. Dália Ferraz nunca mais cobrou por uma sessão."],
	"cancao": ["FINAL SECRETO: A CANÇÃO", "Celeste levou o filho. Ezequiel ficou com a casa, e a casa ficou com ele. Dizem que, em certas noites, o vale ouve uma canção de ninar afinada, e um homem chorando no sótão."],
	"peca": ["FINAL: A PEÇA FINAL", "Faltou uma alma, uma lembrança, ou a própria Dália já não aguentava. O corpo no teatro se levantou e chamou Morvant de pai, com a voz de Dália. A névoa do vale nunca mais se abriu."],
	"anfitriao": ["FINAL: O ANFITRIÃO", "Morvant morreu na própria mesa. A casa ganhou uma anfitriã nova, que escuta os mortos e gosta da companhia. O jantar continua servido."],
}

var t := 0.0
var label := Label.new()


func _ready() -> void:
	label.position = Vector2(60, 36)
	label.size = Vector2(520, 290)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	var hints := 0
	for k in State.hints:
		hints += int(State.hints[k])
	var host := 0
	for k in State.flags:
		if String(k).begins_with("host_solved_"):
			host += 1
	var mins := int(State.play_time / 60.0)
	var souls := 0
	for id in ["ceia", "atlas", "olhos", "partitura", "pele", "sussurros", "vitral"]:
		if State.is_solved(id):
			souls += 1
	var stats := "Tempo: %d min   ·   Sanidade: %d%%   ·   Pistas: %d   ·   Resolvidos por Morvant: %d   ·   Almas: %d de 7" % [mins, int(State.sanity), hints, host, souls]
	var end_id := State.last_ending
	if ENDINGS.has(end_id):
		var e: Array = ENDINGS[end_id]
		label.text = "%s\n\n%s\n\n%s\n\nFinais encontrados: %d de 4\n\n\nclique para voltar ao menu" % [e[0], e[1], stats, State.endings.size()]
	else:
		label.text = "O TEATRO ANATÔMICO\n\n" + ("%d de 7 almas libertadas até aqui. " % souls) + "\n\n" + stats + "\n\n\nclique para voltar ao menu"
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
