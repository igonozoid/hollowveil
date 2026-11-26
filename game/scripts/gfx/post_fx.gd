extends CanvasLayer
## Camada de pós-processamento acima do mundo e dos enigmas (abaixo do HUD).

const SHADER := preload("res://scripts/gfx/post.gdshader")

## [sombras, realces, quantidade, saturação]
const GRADES := {
	"terreo": [Color(0.34, 0.46, 0.38), Color(1.0, 0.84, 0.62), 0.42, 1.0],
	"fantasma": [Color(0.3, 0.45, 0.55), Color(0.85, 1.0, 0.95), 0.5, 0.8],
	"menu": [Color(0.3, 0.36, 0.5), Color(1.0, 0.86, 0.7), 0.4, 0.95],
	"enigma": [Color(0.4, 0.36, 0.34), Color(1.0, 0.88, 0.7), 0.3, 1.0],
	"quartos": [Color(0.42, 0.32, 0.56), Color(1.0, 0.82, 0.82), 0.45, 0.95],
	"poroes": [Color(0.26, 0.34, 0.52), Color(1.0, 0.8, 0.56), 0.5, 0.88],
	"sotao": [Color(0.3, 0.3, 0.34), Color(0.9, 0.95, 1.0), 0.5, 0.7],
}

var mat: ShaderMaterial
var shock := 0.0
var flash := 0.0
var rect: ColorRect
var _grade_amount := 0.4


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	rect.material = mat
	add_child(rect)
	grade("menu")
	Audio.lightning.connect(func(s: float): flash = maxf(flash, s * 0.25))


func grade(id: String) -> void:
	var g: Array = GRADES.get(id, GRADES["terreo"])
	var tw := create_tween().set_parallel()
	tw.tween_method(func(c): mat.set_shader_parameter("shadow_tint", c), mat.get_shader_parameter("shadow_tint") if mat.get_shader_parameter("shadow_tint") != null else g[0], g[0], 1.2)
	tw.tween_method(func(c): mat.set_shader_parameter("highlight_tint", c), mat.get_shader_parameter("highlight_tint") if mat.get_shader_parameter("highlight_tint") != null else g[1], g[1], 1.2)
	_grade_amount = g[2]
	mat.set_shader_parameter("saturation", g[3])


func kick(amount: float) -> void:
	shock = maxf(shock, amount)


func _process(delta: float) -> void:
	rect.visible = State.effects or State.vga
	shock = maxf(0.0, shock - delta * 2.5)
	flash = maxf(0.0, flash - delta * 1.5)
	mat.set_shader_parameter("madness", State.madness() if State.effects else 0.0)
	mat.set_shader_parameter("shock", shock)
	mat.set_shader_parameter("flash", flash)
	mat.set_shader_parameter("vga", 1.0 if State.vga else 0.0)
	var on := 1.0 if State.effects else 0.0
	mat.set_shader_parameter("bloom_strength", 0.75 * on)
	mat.set_shader_parameter("vignette", 0.55 * on)
	mat.set_shader_parameter("grain", 0.03 * on)
	mat.set_shader_parameter("grade_amount", _grade_amount * on)
