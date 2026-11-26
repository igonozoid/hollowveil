extends Control
## O logo do jogo: o emblema (olho na fechadura), o nome em osso rachado que
## se encharca de sangue na base e gotas que escorrem devagar e caem. Usado no
## menu e na tela do final.

const EMBLEM := preload("res://icons/emblem_128.png")

const BONE_SHADER := """
shader_type canvas_item;
uniform float top_y = 6.0;
uniform float glyph_h = 44.0;
uniform float time = 0.0;
varying float ly;
void vertex() { ly = VERTEX.y; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float k = clamp((ly - top_y) / glyph_h, 0.0, 1.0);
	vec3 top = vec3(0.97, 0.93, 0.84);
	vec3 mid = vec3(0.78, 0.72, 0.62);
	vec3 bot = vec3(0.38, 0.32, 0.27);
	vec3 g = k < 0.5 ? mix(top, mid, k * 2.0) : mix(mid, bot, (k - 0.5) * 2.0);
	// Rachaduras finas no osso.
	vec2 cell = floor(FRAGCOORD.xy / 2.0);
	float crack = step(0.965, hash(vec2(cell.x, floor(cell.y / 3.0))));
	g *= 1.0 - crack * 0.55;
	// A base encharcada de sangue, que sobe e desce como se respirasse.
	float level = 0.8 - 0.03 * sin(time * 0.7);
	float blood = smoothstep(level, level + 0.07, k);
	g = mix(g, vec3(0.56, 0.02, 0.05), blood);
	COLOR = vec4(g, COLOR.a);
}
"""

var title := "HOLLOWVEIL"
var font_size := 44
var subtitle := "A  C A S A   M O R V A N T"
var t := 0.0
var labels: Array = []
var mat: ShaderMaterial
var drips: Array = []        # [x, comprimento, velocidade, largura]
var drops: Array = []        # [posição, velocidade]
var title_pos := Vector2(64, 0)
var title_w := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var emblem := TextureRect.new()
	emblem.texture = EMBLEM
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	emblem.position = Vector2(0, 2)
	emblem.size = Vector2(56, 56)
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(emblem)
	var spacing := FontVariation.new()
	spacing.base_font = ThemeDB.fallback_font
	spacing.spacing_glyph = 3
	spacing.variation_embolden = 0.8
	var sh := Shader.new()
	sh.code = BONE_SHADER
	mat = ShaderMaterial.new()
	mat.shader = sh
	for layer in 2:
		var l := Label.new()
		l.text = title
		l.position = title_pos
		l.add_theme_font_override("font", spacing)
		l.add_theme_font_size_override("font_size", font_size)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if layer == 0:
			l.add_theme_color_override("font_color", Color(0.06, 0.01, 0.02))
			l.add_theme_color_override("font_outline_color", Color(0.04, 0.0, 0.01))
			l.add_theme_constant_override("outline_size", 9)
			l.add_theme_color_override("font_shadow_color", Color(0.25, 0.0, 0.02, 0.8))
			l.add_theme_constant_override("shadow_offset_y", 3)
		else:
			l.material = mat
		add_child(l)
		labels.append(l)
	var sub := Label.new()
	sub.text = subtitle
	sub.position = title_pos + Vector2(4, font_size + 34)
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.78, 0.16, 0.14))
	sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)
	_setup_drips.call_deferred()


func _setup_drips() -> void:
	var l: Label = labels[1]
	title_w = l.size.x
	mat.set_shader_parameter("top_y", l.size.y * 0.18)
	mat.set_shader_parameter("glyph_h", l.size.y * 0.62)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1911
	for i in 9:
		drips.append([rng.randf_range(0.04, 0.96) * title_w, rng.randf_range(2.0, 10.0), rng.randf_range(0.6, 2.2), rng.randf_range(1.0, 2.2)])


func _process(delta: float) -> void:
	t += delta
	mat.set_shader_parameter("time", t)
	var base_y := title_pos.y + (labels[1] as Label).size.y * 0.76 if not labels.is_empty() else 0.0
	for d in drips:
		d[1] += d[2] * delta
		# Quando fica pesada demais, a gota se solta e cai.
		if d[1] > 18.0:
			drops.append([Vector2(title_pos.x + d[0], base_y + d[1]), 0.0])
			d[1] = 2.0
	for dr in drops:
		dr[1] += 260.0 * delta
		dr[0].y += dr[1] * delta
	drops = drops.filter(func(dr): return dr[0].y < 380.0)
	queue_redraw()


func _draw() -> void:
	if labels.is_empty():
		return
	var base_y := title_pos.y + (labels[1] as Label).size.y * 0.76
	var blood := Color(0.56, 0.02, 0.05)
	for d in drips:
		var x: float = title_pos.x + d[0]
		var ln: float = d[1]
		var w: float = d[3]
		draw_rect(Rect2(x - w * 0.5, base_y - 2.0, w, ln), blood)
		draw_circle(Vector2(x, base_y + ln), w * 0.9, blood)
		draw_rect(Rect2(x - w * 0.5, base_y, 1, ln * 0.7), Color(0.8, 0.12, 0.12, 0.7))
	for dr in drops:
		draw_rect(Rect2(dr[0] - Vector2(0.5, 2), Vector2(1.5, 3)), blood)
