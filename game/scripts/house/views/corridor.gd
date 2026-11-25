extends "res://scripts/house/view.gd"
## Corredor do 1º andar: longo e estreito, quatro portas laterais e, no fim,
## a porta de Ofélia, com uma luz que tremula por baixo.

var end_glow := Rect2()
var girl_t := -1.0
var girl_at := Vector2()


func _init() -> void:
	id = "corridor"
	title = "Corredor dos quartos"
	music = "quartos"
	grade = "quartos"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.4
	p.fog = Color(0.02, 0.012, 0.03)
	p.fog_start = 4.0
	p.fog_len = 13.0
	var wall := Color(0.28, 0.2, 0.32)
	var ink := Color(0.19, 0.12, 0.22)
	var wood := Color(0.24, 0.12, 0.08)
	var dark := Color(0.13, 0.06, 0.05)
	for z in [3.0, 7.0, 11.0]:
		p.add_light(Vector3(-1.5, 1.9, z), Color(1.0, 0.62, 0.36), 3.0, 0.8, 0.3)
	p.add_light(Vector3(0, 0.1, 15.6), Color(1.0, 0.85, 0.6), 2.0, 0.9, 0.5, 30.0)
	p.floor_plane(-1.6, 1.6, 0.4, 16, 3.2, Color(0.1, 0.06, 0.1), Color(0.05, 0.03, 0.05), "", 16)
	p.back_wall(16, -1.6, 1.6, 0, 3.2, wall)
	for side in [-1.6, 1.6]:
		p.side_wall(side, 0.4, 16, 1.1, 3.2, wall, 24)
		p.wallpaper_side(side, 0.4, 16, 1.1, 3.2, ink, 0.5)
		p.wainscot_side(side, 0.4, 16, 1.1, wood, dark)
	p.floor_plane(-1.6, 1.6, 0.4, 16, 0.0, Color(0.24, 0.13, 0.08), Color(0.12, 0.06, 0.04), "boards", 24)
	# Passadeira roxa
	p.floor_plane(-0.6, 0.6, 0.4, 15.6, 0.006, Color(0.3, 0.08, 0.2), Color(0.2, 0.05, 0.14), "", 20)
	# Arandelas
	for z in [3.0, 7.0, 11.0]:
		p.box(-1.6, -1.5, 1.7, 1.78, z - 0.06, z + 0.06, Color(0.55, 0.42, 0.2))
		p.candle(Vector3(-1.52, 1.78, z), 0.1, true, 3.0, 0.5)
	# Retratos entre as portas (rostos raspados com faca)
	for z2 in [5.2, 9.6]:
		p.poly3([Vector3(1.59, 1.4, z2 - 0.4), Vector3(1.59, 1.4, z2 + 0.4), Vector3(1.59, 2.4, z2 + 0.4), Vector3(1.59, 2.4, z2 - 0.4)], Color(0.55, 0.4, 0.18))
		p.poly3([Vector3(1.58, 1.5, z2 - 0.32), Vector3(1.58, 1.5, z2 + 0.32), Vector3(1.58, 2.3, z2 + 0.32), Vector3(1.58, 2.3, z2 - 0.32)], Color(0.14, 0.1, 0.12))
		var face := p.proj(Vector3(1.58, 2.0, z2))
		var fs := p.scale_at(z2) * 0.12
		for k in 4:
			draw_line(face + Vector2(-fs, -fs + k * fs * 0.6), face + Vector2(fs, -fs * 0.5 + k * fs * 0.6), p.shade(Color(0.7, 0.66, 0.6), Vector3(1.58, 2.0, z2)), 1.0)
	# Portas
	var celeste := p.door_side(-1.6, 4.0, 1.0, 2.3, Color(0.3, 0.12, 0.18), false)
	var bath := p.door_side(-1.6, 8.4, 0.9, 2.2, wood, false)
	var guest_open := State.has("chave_hospedes")
	var guest := p.door_side(1.6, 3.0, 1.0, 2.3, wood, false)
	var nursery := p.door_side(1.6, 12.0, 0.9, 2.2, Color(0.36, 0.3, 0.26), false)
	var ofelia := p.door_back(0, 15.98, 1.0, 2.2, Color(0.2, 0.08, 0.12), false, false)
	end_glow = p.rect_of([Vector3(-0.5, 0.0, 15.97), Vector3(0.5, 0.05, 15.97)])
	girl_at = p.proj(Vector3(0.3, 0.0, 14.8))
	hot(celeste, "walk", "go:celeste_room", "Quarto de Celeste")
	hot(bath, "walk", "go:bathroom", "Banheiro")
	if guest_open:
		hot(guest, "walk", "go:guest_room", "Quarto de hóspedes")
	else:
		hot(guest, "locked", "locked:guest", "Quarto de hóspedes")
	if State.is_solved("caixa"):
		hot(nursery, "walk", "go:nursery", "Berçário")
	else:
		hot(nursery, "locked", "locked:nursery", "Berçário")
	if State.flag("nome_benjamim"):
		hot(ofelia, "walk", "go:ofelia_room", "Quarto de Ofélia")
	else:
		hot(ofelia, "voice", "event:ofelia_door", "Quarto de Ofélia")
	hot_back("go:kitchen", "Descer a escada de serviço")


func paint_live(o: Node2D) -> void:
	# A luz por baixo da porta de Ofélia: alguém anda do outro lado.
	if end_glow.size.x > 0.0:
		var shadow := fmod(t * 0.4, 1.0)
		var a := 0.6 + 0.3 * sin(t * 9.0) * sin(t * 3.1)
		o.draw_rect(Rect2(end_glow.position, Vector2(end_glow.size.x, 1)), Color(1.0, 0.85, 0.55, a))
		if sin(t * 0.9) > 0.3:
			var sx := end_glow.position.x + end_glow.size.x * shadow
			o.draw_rect(Rect2(sx, end_glow.position.y, 3, 1), Color(0, 0, 0))
	# A menina no fim do corredor (só às vezes).
	if girl_t >= 0.0:
		girl_t += get_process_delta_time()
		var al := clampf(1.0 - absf(girl_t - 1.0) / 1.0, 0.0, 1.0) * 0.6
		var c := Color(0.75, 0.95, 0.95, al)
		o.draw_rect(Rect2(girl_at + Vector2(-2, -24), Vector2(4, 4)), c)
		o.draw_colored_polygon(PackedVector2Array([girl_at + Vector2(-3, -20), girl_at + Vector2(3, -20), girl_at + Vector2(5, 0), girl_at + Vector2(-5, 0)]), c)
		o.draw_line(girl_at + Vector2(-2, -23), girl_at + Vector2(-3, -12), Color(0.1, 0.1, 0.12, al), 2.0)
		if girl_t > 2.0:
			girl_t = -1.0


func entered(house) -> void:
	if not State.flag("first_floor"):
		State.set_flag("first_floor")
		girl_t = 0.0
		Audio.play("sting", -8.0, 1.3)
		house.subs.say("DÁLIA", "Uma menina no fim do corredor. Camisola branca. Sumiu na porta.")
		house.subs.say("MORVANT", "Ofélia não recebe visitas. Ela as escuta através das paredes.")
		State.change_sanity(-4.0)
	elif randf() < 0.25 + State.madness() * 0.5:
		girl_t = 0.0
		Audio.play("whisper", -8.0, 1.5)
