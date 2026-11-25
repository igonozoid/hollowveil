extends RefCounted
## Gera vértices no espaço local, sem texturas.

static func ellipse(center: Vector2, radii: Vector2, segments: int = 24) -> PackedVector2Array:
	var count := clampi(segments, 3, 128)
	var points := PackedVector2Array()
	points.resize(count)
	for index in count:
		var angle := TAU * float(index) / float(count)
		points[index] = center + Vector2(cos(angle), sin(angle)) * radii.abs()
	return points
