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
const Relics := preload("res://scripts/core/relics.gd")

var id := ""
var title := ""
var music := "terreo"
## Gradação de cor do pós-processamento (post_fx.GRADES).
var grade := "terreo"
## Porões: Dália carrega uma lamparina que segue o cursor.
var lantern := false
var _lamp: PointLight2D = null
var p: Persp
var hotspots: Array = []
var glass: Array = []
var overlay := Node2D.new()
var lights_node := Node2D.new()
var t := 0.0
var flash := 0.0
var _flames: Array = []
var _spots: Array = []


func _ready() -> void:
	add_child(lights_node)
	add_child(overlay)
	overlay.draw.connect(_draw_overlay)
	Audio.lightning.connect(_on_lightning)
	State.flag_changed.connect(func(_n): queue_redraw())
	if lantern:
		_lamp = Light.make(self, get_viewport().get_mouse_position(), Color(1.0, 0.76, 0.46), 120.0, 0.85, 0.1)


func _on_lightning(s: float) -> void:
	flash = maxf(flash, s)


func _draw() -> void:
	p = Persp.new(self)
	hotspots.clear()
	glass.clear()
	paint()
	_paint_relics()
	_flames = p.flames.duplicate()
	_spots = p.spots.duplicate()
	_spawn_lights.call_deferred(p.spots.duplicate())


func _spawn_lights(spots: Array) -> void:
	for c in lights_node.get_children():
		c.queue_free()
	for s in spots:
		Light.make(lights_node, s[0], s[1], s[2], s[3], s[4])


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 2.2)
	if _lamp:
		_lamp.position = _lamp.position.lerp(get_viewport().get_mouse_position() + Vector2(0, 10), minf(1.0, delta * 7.0))
		# Gotas que caem em algum lugar no escuro.
		if randf() < delta * 0.3:
			Audio.play("drip", -16.0, randf_range(0.8, 1.35))
	overlay.queue_redraw()


func _draw_overlay() -> void:
	for f in _flames:
		var pos: Vector2 = f[0]
		var s: float = f[1]
		var k := 1.0 + 0.25 * sin(t * 13.0 + pos.x) * sin(t * 7.1 + pos.y)
		overlay.draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -3.0 * s * k), pos + Vector2(s, 0), pos + Vector2(0, s * 0.8), pos + Vector2(-s, 0)]), Color(1.0, 0.62, 0.22))
		overlay.draw_rect(Rect2(pos - Vector2(0.5, 1), Vector2(1, maxf(1.0, s))), Color(1, 0.95, 0.75))
		# Fumaça fina que sobe e se desfaz.
		if State.effects:
			for w in 4:
				var ph := fmod(t * 0.45 + w * 0.25 + pos.x * 0.013, 1.0)
				var sp := pos + Vector2(sin(t * 1.3 + w * 2.0 + pos.y) * 3.0 * ph * s, -(3.0 * s + ph * 26.0 * s))
				overlay.draw_circle(sp, 0.6 * s + ph * 2.2 * s, Color(0.7, 0.68, 0.66, 0.09 * (1.0 - ph)))
	if flash > 0.02:
		for g in glass:
			overlay.draw_colored_polygon(g, Color(0.85, 0.9, 1.0, flash * 0.9))
	_rain_on_glass()
	paint_live(overlay)
	_relic_glints()
	_dust()


## Gotas escorrendo pelo vidro das janelas.
func _rain_on_glass() -> void:
	for g: PackedVector2Array in glass:
		var r := Rect2(g[0], Vector2.ZERO)
		for v in g:
			r = r.expand(v)
		r = r.grow(-2.0)
		if r.size.x <= 2.0 or r.size.y <= 2.0:
			continue
		var n := int(clampf(r.size.x * r.size.y / 300.0, 3.0, 18.0))
		for k in n:
			var x := r.position.x + fmod(k * 37.13 + r.position.x, r.size.x)
			var y := r.position.y + fmod(t * (18.0 + (k % 5) * 9.0) + k * 53.7, r.size.y)
			overlay.draw_rect(Rect2(x, y, 1, 2 + k % 3), Color(0.75, 0.85, 1.0, 0.28))


## Poeira suspensa: só aparece onde há luz por perto.
func _dust() -> void:
	if not State.effects:
		return
	for i in 70:
		var x := fmod(i * 97.31 + sin(t * 0.31 + i) * 14.0 + t * (1.5 + i % 3), 640.0)
		var y := fmod(i * 53.77 + t * (2.0 + (i % 4) * 0.8), 360.0)
		var pos := Vector2(x, y)
		var b := 0.0
		for s in _spots:
			var r: float = s[2] * 1.3
			var d: float = pos.distance_to(s[0])
			if d < r:
				b = maxf(b, (1.0 - d / r) * float(s[3]))
		if b > 0.06:
			overlay.draw_rect(Rect2(pos.round(), Vector2(1, 1)), Color(1.0, 0.86, 0.62, minf(b, 1.0) * 0.7))


var _relic_spots: Array = []


## Relíquias desta vista ainda não achadas: um objeto pequeno e um hotspot.
func _paint_relics() -> void:
	_relic_spots = []
	for r in Relics.for_view(id):
		if State.has_relic(r[0]):
			continue
		if r[4] != "" and not State.is_solved(r[4]):
			continue
		Relics.draw_icon(self, r[3], r[2], 0.8, 0.75)
		hot(Rect2(r[3] - Vector2(8, 8), Vector2(16, 16)), "look", "relic:" + String(r[0]), "Alguma coisa no chão")
		_relic_spots.append(r[3])


## Um brilho rápido, de tempos em tempos, onde há relíquia.
func _relic_glints() -> void:
	for i in _relic_spots.size():
		var ph := fmod(t * 0.35 + i * 0.37, 1.0)
		if ph < 0.08:
			var c: Vector2 = _relic_spots[i]
			var k := 1.0 - absf(ph - 0.04) / 0.04
			overlay.draw_line(c + Vector2(-5, 0) * k, c + Vector2(5, 0) * k, Color(1, 0.95, 0.8, 0.8 * k), 1.0)
			overlay.draw_line(c + Vector2(0, -5) * k, c + Vector2(0, 5) * k, Color(1, 0.95, 0.8, 0.8 * k), 1.0)


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
