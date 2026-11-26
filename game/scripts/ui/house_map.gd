extends Control
## Mapa da casa: um corte dos quatro andares. Cômodos já visitados aparecem
## com nome, alma libertada e relíquias achadas; os outros são só "?".
## Clicar num cômodo visitado leva Dália até lá (tecla M ou Esc fecha).

signal travel(view_id: String)
signal closed

const Relics := preload("res://scripts/core/relics.gd")
const FLOORS := [
	["SÓTÃO", ["attic", "clock_tower", "theater"]],
	["1º ANDAR", ["corridor", "celeste_room", "bathroom", "guest_room", "nursery", "ofelia_room"]],
	["TÉRREO", ["foyer", "foyer_door", "dining", "library", "kitchen", "greenhouse", "music"]],
	["PORÕES", ["cellar", "wine_cellar", "cold_room", "chapel", "crypt"]],
]
const NAMES := {
	"attic": "Sótão", "clock_tower": "Torre do relógio", "theater": "Teatro Anatômico",
	"corridor": "Corredor", "celeste_room": "Quarto de Celeste", "bathroom": "Banheiro",
	"guest_room": "Quarto de hóspedes", "nursery": "Berçário", "ofelia_room": "Quarto de Ofélia",
	"foyer": "Saguão", "foyer_door": "Porta de entrada", "dining": "Sala de jantar", "library": "Biblioteca",
	"kitchen": "Cozinha", "greenhouse": "Estufa", "music": "Sala de música",
	"cellar": "Galeria", "wine_cellar": "Adega", "cold_room": "Câmara fria", "chapel": "Capela", "crypt": "Cripta",
}
const SOUL_OF := {"dining": "ceia", "library": "atlas", "kitchen": "olhos", "music": "partitura", "guest_room": "pele", "ofelia_room": "sussurros", "chapel": "vitral"}
const X0 := 70.0
const W := 540.0
const Y0 := 44.0
const ROW := 68.0

var rects := {}
var hover := ""
var t := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for f in FLOORS.size():
		var rooms: Array = FLOORS[f][1]
		var bw := W / rooms.size()
		for k in rooms.size():
			rects[rooms[k]] = Rect2(X0 + k * bw + 2, Y0 + f * ROW + 14, bw - 4, ROW - 22)


static func visited(id: String) -> bool:
	return State.flag("visited_" + id)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = ""
		for id in rects:
			if (rects[id] as Rect2).has_point(event.position) and visited(id):
				hover = id
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hover != "" and hover != State.view:
			Audio.play("step", -6.0)
			travel.emit(hover)
		elif not Rect2(X0 - 10, Y0 - 10, W + 20, ROW * 4 + 10).has_point(event.position):
			closed.emit()
		accept_event()


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.012, 0.015, 0.93))
	# Silhueta do telhado e da torre por cima do corte.
	draw_colored_polygon(PackedVector2Array([Vector2(X0 - 8, Y0 + 4), Vector2(320, Y0 - 34), Vector2(X0 + W + 8, Y0 + 4)]), Color(0.12, 0.07, 0.07))
	draw_rect(Rect2(X0 + W * 0.83, Y0 - 40, 26, 44), Color(0.12, 0.07, 0.07))
	draw_string(font, Vector2(0, 22), "A CASA MORVANT", HORIZONTAL_ALIGNMENT_CENTER, 640, 13, Color(0.9, 0.8, 0.62))
	for f in FLOORS.size():
		var y := Y0 + f * ROW
		draw_rect(Rect2(X0 - 6, y + 8, W + 12, ROW - 10), Color(0.09, 0.05, 0.06))
		draw_rect(Rect2(X0 - 6, y + 8, W + 12, ROW - 10), Color(0.4, 0.22, 0.14), false, 1.0)
		draw_string(font, Vector2(4, y + 40), FLOORS[f][0], HORIZONTAL_ALIGNMENT_LEFT, 62, 8, Color(0.75, 0.3, 0.25))
	for id in rects:
		var r: Rect2 = rects[id]
		var seen := visited(id)
		var here: bool = id == State.view
		var bg := Color(0.2, 0.13, 0.11) if seen else Color(0.05, 0.03, 0.04)
		if id == hover:
			bg = bg.lightened(0.15)
		draw_rect(r, bg)
		draw_rect(r, Color(0.85, 0.66, 0.36) if here else Color(0.3, 0.18, 0.12), false, 2.0 if here else 1.0)
		if not seen:
			draw_string(font, r.get_center() + Vector2(-r.size.x * 0.5, 4), "?", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color(0.35, 0.2, 0.2))
			continue
		draw_string(font, r.position + Vector2(3, 12), NAMES.get(id, id), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 6, 7, Color(0.9, 0.84, 0.74))
		# Alma libertada: um vulto pálido; presa: uma chama vermelha.
		if SOUL_OF.has(id):
			var c := r.position + Vector2(10, r.size.y - 11)
			if State.is_solved(SOUL_OF[id]):
				draw_circle(c + Vector2(0, -4), 3, Color(0.62, 0.95, 0.9, 0.8 + 0.2 * sin(t * 3.0)))
				draw_rect(Rect2(c + Vector2(-3, -1), Vector2(6, 7)), Color(0.62, 0.95, 0.9, 0.6))
			else:
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(3, 0), c + Vector2(-3, 0)]), Color(0.8, 0.15, 0.1))
		# Relíquias: achadas / total.
		var total := Relics.for_view(id).size()
		if total > 0:
			var got := 0
			for rl in Relics.for_view(id):
				if State.has_relic(rl[0]):
					got += 1
			var rc := Color(0.95, 0.8, 0.45) if got == total else Color(0.6, 0.5, 0.4)
			var dp := r.position + Vector2(r.size.x - 30, r.size.y - 8)
			draw_colored_polygon(PackedVector2Array([dp + Vector2(0, -3), dp + Vector2(3, 0), dp + Vector2(0, 3), dp + Vector2(-3, 0)]), rc)
			draw_string(font, dp + Vector2(5, 3), "%d/%d" % [got, total], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, rc)
		if here:
			draw_string(font, r.position + Vector2(3, 22), "você", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.85, 0.66, 0.36))
	var tip := "Clique num cômodo visitado para ir até ele · M ou Esc fecha"
	if hover != "":
		tip = "Ir para: " + NAMES.get(hover, hover)
	draw_string(font, Vector2(0, 342), tip, HORIZONTAL_ALIGNMENT_CENTER, 640, 9, Color(0.7, 0.62, 0.52))
