extends RefCounted
## Tema da interface no estilo IronVeil: painéis marrom-escuros, borda de latão.

const BRASS := Color(0.78, 0.56, 0.3)
const INK := Color(0.9, 0.84, 0.74)
const BLOOD := Color(0.72, 0.08, 0.08)


static func _box(bg: Color, border: Color, w: int, margin: Vector2 = Vector2(8, 3)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(w)
	s.content_margin_left = margin.x
	s.content_margin_right = margin.x
	s.content_margin_top = margin.y
	s.content_margin_bottom = margin.y
	return s


static func make() -> Theme:
	var t := Theme.new()
	t.default_font_size = 11
	var normal := _box(Color(0.1, 0.08, 0.075, 0.92), Color(0.42, 0.28, 0.16), 1)
	var hover := _box(Color(0.24, 0.13, 0.08, 0.95), BRASS, 1)
	var focus := _box(Color(0.32, 0.14, 0.08, 0.96), Color(0.9, 0.62, 0.32), 2)
	var pressed := _box(Color(0.42, 0.1, 0.06, 0.96), Color(1.0, 0.7, 0.4), 2)
	var disabled := _box(Color(0.08, 0.07, 0.07, 0.8), Color(0.22, 0.19, 0.18), 1)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_color("font_color", "Button", Color(0.86, 0.8, 0.72))
	t.set_color("font_hover_color", "Button", Color(1, 0.92, 0.8))
	t.set_color("font_focus_color", "Button", Color(1, 0.92, 0.8))
	t.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.37, 0.35))
	t.set_font_size("font_size", "Button", 12)
	t.set_stylebox("panel", "Panel", _box(Color(0.07, 0.055, 0.05, 0.94), BRASS, 2, Vector2(8, 6)))
	t.set_stylebox("panel", "PanelContainer", _box(Color(0.07, 0.055, 0.05, 0.94), BRASS, 2, Vector2(8, 6)))
	t.set_color("font_color", "Label", INK)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.8))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font_size("normal_font_size", "RichTextLabel", 11)
	t.set_stylebox("slider", "HSlider", _box(Color(0.15, 0.1, 0.08), Color(0.42, 0.28, 0.16), 1, Vector2(0, 2)))
	t.set_stylebox("grabber_area", "HSlider", _box(Color(0.6, 0.15, 0.08), Color(0.6, 0.15, 0.08), 0, Vector2(0, 2)))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(Color(0.8, 0.2, 0.1), Color(0.8, 0.2, 0.1), 0, Vector2(0, 2)))
	return t
