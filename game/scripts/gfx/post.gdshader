// Pós-processamento: brilho, gradação de sombras/realces, contraste,
// vinheta, grão, distorção da sanidade e Modo VGA (pontilhado + paleta curta).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 shadow_tint : source_color = vec4(0.36, 0.46, 0.38, 1.0);
uniform vec4 highlight_tint : source_color = vec4(1.0, 0.86, 0.66, 1.0);
uniform float grade_amount = 0.4;
uniform float contrast = 1.1;
uniform float saturation = 1.0;
uniform float bloom_threshold = 0.55;
uniform float bloom_strength = 0.75;
uniform float vignette = 0.55;
uniform float grain = 0.03;
uniform float madness = 0.0;
uniform float shock = 0.0;
uniform float flash = 0.0;
uniform float vga = 0.0;
// Batida do coração (0..1) quando a sanidade está baixa.
uniform float heartbeat = 0.0;
// Filme antigo: riscos, poeira e oscilação de brilho (0 desliga).
uniform float film = 0.0;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec3 bright(vec2 uv) {
	vec3 c = textureLod(screen_tex, uv, 1.0).rgb;
	return c * smoothstep(bloom_threshold, 1.0, luma(c));
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[i] / 16.0 - 0.5;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	// Sanidade baixa: a sala respira e as cores se separam.
	float m = madness * madness;
	uv.x += sin(uv.y * 24.0 + TIME * 1.7) * 0.0035 * m;
	uv.y += sin(uv.x * 17.0 + TIME * 1.1) * 0.0025 * m;
	float ab = 2.0 * m + 6.0 * shock;
	vec2 off = (uv - 0.5) * px * ab;
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;

	vec3 glow = vec3(0.0);
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		vec2 d = vec2(cos(a), sin(a)) * px;
		glow += bright(uv + d * 3.0);
		glow += bright(uv + d * 7.0) * 0.6;
	}
	col += glow / 12.8 * bloom_strength;

	float l = luma(col);
	vec3 st = shadow_tint.rgb / max(luma(shadow_tint.rgb), 0.01);
	vec3 ht = highlight_tint.rgb / max(luma(highlight_tint.rgb), 0.01);
	col = mix(col, col * mix(st, ht, smoothstep(0.05, 0.7, l)), grade_amount);
	col = (col - 0.5) * contrast + 0.5;
	col = mix(vec3(luma(col)), col, saturation * (1.0 - 0.4 * m));
	// Vermelho nas bordas quando a mente cede.
	vec2 v = uv - 0.5;
	float edge = dot(v, v) * 2.4;
	col = mix(col, vec3(0.35, 0.0, 0.02), clamp(m * edge * (0.7 + 0.3 * sin(TIME * 3.0)), 0.0, 0.8));
	col *= 1.0 - vignette * smoothstep(0.15, 0.8, dot(v * vec2(1.0, 0.85), v * vec2(1.0, 0.85)) * 2.0);
	// A cada batida, as bordas fecham e avermelham.
	float hb = heartbeat * smoothstep(0.05, 0.6, dot(v, v) * 2.2);
	col = mix(col, col * vec3(0.55, 0.12, 0.12), hb * 0.75);
	if (film > 0.0) {
		float frame = floor(TIME * 18.0);
		// Riscos verticais que aparecem e somem a cada quadro.
		for (int k = 0; k < 2; k++) {
			float sx = hash(vec2(frame, float(k) * 7.1));
			float on = step(0.72, hash(vec2(frame * 1.3, float(k))));
			float d = abs(uv.x - sx);
			col += vec3(0.16) * on * film * (1.0 - smoothstep(0.0, px.x * 1.2, d)) * step(hash(vec2(frame, 3.0)) * 0.6, uv.y);
		}
		// Poeira e fios de cabelo na película.
		float speck = step(0.9993, hash(floor(uv / px / 2.0) + frame * 13.0));
		col = mix(col, vec3(0.02), speck * film);
		col *= 1.0 - film * 0.05 * hash(vec2(frame, 1.0));
	}
	col += (hash(uv * 640.0 + fract(TIME) * 37.0) - 0.5) * grain;
	col += vec3(0.75, 0.8, 1.0) * flash;
	if (vga > 0.5) {
		vec2 cell = floor(SCREEN_UV / px);
		vec3 g = sqrt(clamp(col, 0.0, 1.0));
		g += bayer4(cell) * 0.11;
		g = floor(clamp(g, 0.0, 1.0) * 7.0 + 0.5) / 7.0;
		col = g * g;
	}
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
