extends "res://scripts/house/view.gd"
## Banheiro: azulejos encardidos, banheira de pés de leão cheia até a borda
## de algo escuro, pia com espelho embaçado e três frascos na prateleira.

var tub := Rect2()
var mirror := Rect2()


func _init() -> void:
	id = "bathroom"
	title = "Banheiro"
	music = "quartos"
	grade = "quartos"


func paint() -> void:
	p.cy = 150.0
	p.ambient = 0.34
	p.fog = Color(0.02, 0.02, 0.025)
	p.add_light(Vector3(0.4, 2.0, 4.8), Color(0.7, 0.8, 1.0), 4.0, 0.4, 0.0, 100.0)
	p.add_light(Vector3(-1.7, 1.2, 3.4), Color(1.0, 0.64, 0.36), 2.4, 0.8, 0.3, 60.0)
	var tile := Color(0.42, 0.45, 0.38)
	var grout := Color(0.2, 0.21, 0.17)
	p.floor_plane(-2, 2, 0.4, 6, 3.0, Color(0.3, 0.3, 0.28), Color(0.2, 0.2, 0.18), "", 6)
	p.back_wall(6, -2, 2, 0, 3.0, tile)
	p.side_wall(-2, 0.4, 6, 0, 3.0, tile, 12)
	p.side_wall(2, 0.4, 6, 0, 3.0, tile, 12)
	# Rejunte dos azulejos (e a faixa preta no meio da parede)
	for i in 15:
		var y := i * 0.2
		p.line3(Vector3(-2, y, 6), Vector3(2, y, 6), grout, 1.0)
		p.line3(Vector3(-2, y, 0.4), Vector3(-2, y, 6), grout, 1.0)
		p.line3(Vector3(2, y, 0.4), Vector3(2, y, 6), grout, 1.0)
	for i in 21:
		p.line3(Vector3(-2 + i * 0.2, 0, 6), Vector3(-2 + i * 0.2, 3.0, 6), grout, 1.0)
	for side in [-2.0, 2.0]:
		p.poly3([Vector3(side, 1.2, 0.4), Vector3(side, 1.2, 6), Vector3(side, 1.3, 6), Vector3(side, 1.3, 0.4)], Color(0.08, 0.08, 0.1))
	p.poly3([Vector3(-2, 1.2, 6), Vector3(2, 1.2, 6), Vector3(2, 1.3, 6), Vector3(-2, 1.3, 6)], Color(0.08, 0.08, 0.1))
	p.floor_plane(-2, 2, 0.4, 6, 0.0, Color(0.48, 0.48, 0.44), Color(0.08, 0.08, 0.08), "tiles", 12)
	glass.append(p.window_back(0.9, 5.98, 0.7, 1.7, 1.0, Color(0.3, 0.3, 0.3), SKY_TOP, SKY_BOT))
	# Banheira no fundo
	var full := not State.is_solved("banho")
	var enamel := Color(0.6, 0.6, 0.55)
	for fx in [-1.0, 0.4]:
		p.box(fx, fx + 0.1, 0.0, 0.15, 4.6, 4.7, Color(0.6, 0.46, 0.2))
	p.box(-1.1, 0.5, 0.12, 0.7, 4.5, 5.9, enamel.darkened(0.15), enamel)
	var liquid := Color(0.32, 0.0, 0.03) if full else Color(0.55, 0.52, 0.48)
	p.poly3([Vector3(-1.0, 0.69, 4.6), Vector3(0.4, 0.69, 4.6), Vector3(0.4, 0.69, 5.8), Vector3(-1.0, 0.69, 5.8)], liquid)
	if not full:
		var key := p.proj(Vector3(-0.3, 0.7, 5.2))
		draw_rect(Rect2(key - Vector2(4, 1), Vector2(8, 2)), Color(0.75, 0.6, 0.25))
		draw_circle(key + Vector2(-5, 0), 2.0, Color(0.75, 0.6, 0.25))
		if State.gore:
			for i in 6:
				draw_rect(Rect2(p.proj(Vector3(-0.9 + i * 0.22, 0.7, 4.8 + (i % 3) * 0.3)), Vector2(3, 1)), Color(0.4, 0.0, 0.03))
	tub = p.box_rect(-1.1, 0.5, 0.0, 0.75, 4.5, 5.9)
	p.line3(Vector3(-0.3, 0.7, 5.9), Vector3(-0.3, 1.3, 5.95), Color(0.6, 0.58, 0.5), 2.0)
	# Pia e espelho na parede esquerda
	p.box(-2.0, -1.5, 0.0, 0.85, 3.0, 3.8, enamel.darkened(0.2), enamel)
	mirror = p.rect_of([Vector3(-1.99, 1.3, 2.9), Vector3(-1.99, 2.3, 3.9)])
	p.poly3([Vector3(-1.99, 1.25, 2.85), Vector3(-1.99, 1.25, 3.95), Vector3(-1.99, 2.35, 3.95), Vector3(-1.99, 2.35, 2.85)], Color(0.45, 0.36, 0.2))
	p.poly3([Vector3(-1.98, 1.3, 2.9), Vector3(-1.98, 1.3, 3.9), Vector3(-1.98, 2.3, 3.9), Vector3(-1.98, 2.3, 2.9)], Color(0.55, 0.6, 0.62))
	p.candle(Vector3(-1.7, 0.85, 3.6), 0.12, true, 2.0, 0.8)
	# Prateleira com os três frascos (parede direita)
	p.box(1.6, 2.0, 1.2, 1.25, 2.8, 4.2, Color(0.3, 0.18, 0.1))
	var vials := p.box_rect(1.6, 2.0, 1.25, 1.75, 2.8, 4.2)
	for k in 3:
		var z := 3.0 + k * 0.42
		var hgt := 0.5 - k * 0.12
		p.box(1.72, 1.85, 1.25, 1.25 + hgt, z, z + 0.12, Color(0.6, 0.7, 0.72), Color(0.7, 0.8, 0.82))
		if k == 0 and full:
			p.box(1.72, 1.85, 1.25, 1.25 + hgt * 0.9, z, z + 0.12, Color(0.45, 0.0, 0.04))
	if full:
		hot(vials.grow(6), "puzzle", "puzzle:banho", "Três frascos")
		hot(tub, "look", "look:tub", "Banheira")
	else:
		hot(vials.grow(6), "look", "look:vials_after", "Três frascos")
		hot(tub, "look", "look:tub_after", "Banheira")
	hot(mirror, "look", "look:bath_mirror", "Espelho embaçado")
	hot_back("go:corridor", "Voltar ao corredor")


func paint_live(o: Node2D) -> void:
	# No espelho embaçado, um dedo invisível escreve.
	if mirror.size.x > 0.0:
		var k := fmod(t * 0.15, 1.0)
		var letters := "ELA OUVE"
		var shown := int(k * (letters.length() + 4))
		for i in mini(shown, letters.length()):
			var ch := letters[i]
			if ch == " ":
				continue
			var px := mirror.position + Vector2(4 + i * mirror.size.x / 9.0, mirror.size.y * (0.35 + 0.06 * sin(i)))
			o.draw_rect(Rect2(px, Vector2(2, 5)), Color(0.85, 0.9, 0.92, 0.5))
	# Bolhas subindo na banheira cheia.
	if not State.is_solved("banho") and tub.size.x > 0.0:
		for i in 4:
			var bp := Vector2(tub.position.x + tub.size.x * (0.2 + 0.18 * i), tub.position.y + tub.size.y * 0.35)
			var r := 1.0 + absf(sin(t * 1.3 + i * 2.0)) * 2.0
			o.draw_arc(bp, r, 0, TAU, 8, Color(0.6, 0.1, 0.12, 0.8), 1.0)
