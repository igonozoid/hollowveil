shader_type canvas_item;
render_mode unshaded;

uniform sampler2D scene : hint_screen_texture, repeat_disable, filter_nearest;
uniform float vignette : hint_range(0.0, 1.0) = 0.44;
uniform float grain : hint_range(0.0, 0.06) = 0.019;

void fragment() {
	vec3 color = texture(scene, SCREEN_UV).rgb;
	vec2 center = (SCREEN_UV - vec2(0.52, 0.48)) * vec2(1.04, 0.83);
	float edge = smoothstep(0.19, 0.66, length(center));
	float noise = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
	color *= 1.0 - edge * vignette;
	color += (noise - 0.5) * grain * smoothstep(0.018, 0.15, max(color.r, max(color.g, color.b)));
	COLOR = vec4(color, 1.0);
}
