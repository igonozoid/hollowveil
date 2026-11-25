extends Node2D

const POSITIONS := [342.0, 735.0, 1150.0, 1560.0, 1995.0]
var elapsed := 0.0

func _draw() -> void:
	for index in POSITIONS.size():
		var x: float = POSITIONS[index]
		var origin := Vector2(x,336)
		var flicker := sin(elapsed*7.0+index)*0.16 + sin(elapsed*13.0+index)*0.09
		for ring in range(13,0,-1):
			draw_circle(origin,ring*9.0,Color(1.0,0.59,0.26,0.012+flicker*0.012),true,-1,true)
		draw_line(origin+Vector2(-10,25),origin+Vector2(10,25),Color("#745434"),3,true)
		draw_rect(Rect2(origin+Vector2(-2,4),Vector2(4,21)),Color("#e3c498"))
		var flame := PackedVector2Array([origin+Vector2(-4,3),origin+Vector2(0,-10-flicker*9),
			origin+Vector2(4,2),origin+Vector2(0,7)])
		draw_colored_polygon(flame,Color("#ffcf85"))
		draw_line(origin+Vector2(0,0),origin+Vector2(0,4),Color("#fff2c9"),2,true)
