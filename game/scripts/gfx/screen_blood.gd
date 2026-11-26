extends CanvasLayer
## Sangue na lente: a cada susto forte, gotas grossas batem nas bordas da tela
## e escorrem devagar até sumir. Só com gore ligado.

var node := Node2D.new()
var blobs: Array = []        # [posição, raio, velocidade, vida, rastro]
var t := 0.0


func _ready() -> void:
	layer = 8
	add_child(node)
	node.draw.connect(_paint)


## amount de 0 a 1: quantas gotas e quão grandes.
func splash(amount: float) -> void:
	if not State.gore or not State.effects:
		return
	var n := int(3 + amount * 10)
	for i in n:
		var side := randi() % 3
		var pos := Vector2(randf_range(0, 640), randf_range(0, 90))
		if side == 1:
			pos = Vector2(randf_range(0, 70), randf_range(0, 300))
		elif side == 2:
			pos = Vector2(randf_range(570, 640), randf_range(0, 300))
		var r := randf_range(2.0, 4.0 + amount * 5.0)
		# Respingo irregular: uma gota principal e algumas menores coladas nela.
		var bits: Array = []
		for k in randi_range(2, 5):
			bits.append([Vector2(randf_range(-1.6, 1.6), randf_range(-1.2, 1.0)) * r, r * randf_range(0.3, 0.7)])
		blobs.append([pos, r, randf_range(6.0, 18.0), randf_range(3.0, 6.0), 0.0, bits])


func _process(delta: float) -> void:
	t += delta
	for b in blobs:
		b[0].y += b[2] * delta
		b[4] += b[2] * delta
		b[2] = maxf(2.0, b[2] - delta * 2.0)
		b[3] -= delta
	blobs = blobs.filter(func(b): return b[3] > 0.0)
	node.queue_redraw()


func _paint() -> void:
	for b in blobs:
		var a := clampf(b[3] / 2.0, 0.0, 1.0)
		var p: Vector2 = b[0]
		var r: float = b[1]
		var col := Color(0.4, 0.0, 0.03, 0.6 * a)
		# O rastro que a gota deixa ao escorrer, mais fino que ela.
		node.draw_rect(Rect2(p.x - r * 0.25, p.y - b[4], r * 0.5, b[4]), Color(0.3, 0.0, 0.02, 0.35 * a))
		node.draw_circle(p, r, col)
		for bit in b[5]:
			node.draw_circle(p + bit[0], bit[1], col)
		node.draw_circle(p + Vector2(-r * 0.3, -r * 0.35), r * 0.18, Color(0.85, 0.35, 0.35, 0.35 * a))
