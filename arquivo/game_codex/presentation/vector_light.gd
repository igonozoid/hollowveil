extends Resource
## Luz radial avaliada uma vez por forma, em coordenadas locais.

@export var position: Vector2 = Vector2(-70, -120):
	set(value):
		position = value
		emit_changed()

@export_range(1.0, 1024.0, 1.0, "or_greater") var radius: float = 240.0:
	set(value):
		radius = value
		emit_changed()

@export_range(0.0, 1.0) var ambient: float = 0.45:
	set(value):
		ambient = value
		emit_changed()


func shade(base_color: Color, response: float, sample_position: Vector2) -> Color:
	var influence := clampf(1.0 - position.distance_to(sample_position) / maxf(radius, 1.0), 0.0, 1.0)
	var brightness := lerpf(1.0, lerpf(ambient, 1.0, influence), response)
	return Color(base_color.r * brightness, base_color.g * brightness, base_color.b * brightness, base_color.a)
