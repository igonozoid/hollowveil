extends Node2D
## Uma vista fixa em primeira pessoa. O desenho estático é feito uma vez em
## _draw (paint); as chamas, o relâmpago nas janelas e os detalhes vivos vão
## na camada "overlay", redesenhada a cada quadro.
##
## Hotspots: {rect, kind, action, label}
##   kind: walk | look | puzzle | voice | locked
##   action: "go:<vista>" | "look:<texto>" | "puzzle:<id>" | "event:<id>" | "locked:<texto>"

const Persp := preload("res://scripts/gfx/persp.gd")
const Light := preload("res://scripts/gfx/light.gd")

var id := ""
var title := ""
var music := "terreo"
var p: Persp
var hotspots: Array = []
var glass: Array = []
var overlay := Node2D.new()
var lights_node := Node2D.new()
var t := 0.0
var flash := 0.0
var _flames: Array = []


func _ready() -> void:
	add_child(lights_node)
	add_child(overlay)
	overlay.draw.connect(_draw_overlay)
	Audio.lightning.connect(_on_lightning)
	State.flag_changed.connect(func(_n): queue_redraw())


func _on_lightning(s: float) -> void:
	flash = maxf(flash, s)


func _draw() -> void:
	p = Persp.new(self)
	hotspots.clear()
	glass.clear()
	paint()
	_flames = p.flames.duplicate()
	_spawn_lights.call_deferred(p.spots.duplicate())


func _spawn_lights(spots: Array) -> void:
	for c in lights_node.get_children():
		c.queue_free()
	for s in spots:
		Light.make(lights_node, s[0], s[1], s[2], s[3], s[4])


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 2.2)
	overlay.queue_redraw()


func _draw_overlay() -> void:
	for f in _flames:
		var pos: Vector2 = f[0]
		var s: float = f[1]
		var k := 1.0 + 0.25 * sin(t * 13.0 + pos.x) * sin(t * 7.1 + pos.y)
		overlay.draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -3.0 * s * k), pos + Vector2(s, 0), pos + Vector2(0, s * 0.8), pos + Vector2(-s, 0)]), Color(1.0, 0.62, 0.22))
		overlay.draw_rect(Rect2(pos - Vector2(0.5, 1), Vector2(1, maxf(1.0, s))), Color(1, 0.95, 0.75))
	if flash > 0.02:
		for g in glass:
			overlay.draw_colored_polygon(g, Color(0.85, 0.9, 1.0, flash * 0.9))
	paint_live(overlay)


## Sobrescrever: desenho estático do cômodo.
func paint() -> void:
	pass


## Sobrescrever: detalhes animados (desenhar em `o`).
func paint_live(_o: Node2D) -> void:
	pass


## Chamado pela casa quando o jogador chega a esta vista.
func entered(_house) -> void:
	pass


func hot(rect: Rect2, kind: String, action: String, label: String = "") -> void:
	hotspots.append({"rect": rect.grow(2.0), "kind": kind, "action": action, "label": label})


## Faixa de baixo da tela: "voltar"/"virar-se".
func hot_back(action: String, label: String = "Voltar") -> void:
	hotspots.append({"rect": Rect2(120, 330, 400, 30), "kind": "walk", "action": action, "label": label})


func hotspot_at(pos: Vector2) -> Dictionary:
	# Os últimos registrados ficam por cima (objetos na frente das paredes).
	for i in range(hotspots.size() - 1, -1, -1):
		if (hotspots[i]["rect"] as Rect2).has_point(pos):
			return hotspots[i]
	return {}


## Céu noturno padrão para janelas.
const SKY_TOP := Color(0.06, 0.08, 0.16)
const SKY_BOT := Color(0.22, 0.26, 0.38)
