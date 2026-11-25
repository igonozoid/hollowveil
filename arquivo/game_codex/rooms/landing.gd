extends Node2D

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#141b20"))
	for i in 18:
		draw_rect(Rect2(0,i*32,1280,32),Color("#283339").lerp(Color("#10161b"), i/18.0))
	var silhouette := PackedVector2Array([
		Vector2(355,595),Vector2(355,335),Vector2(414,243),Vector2(518,155),
		Vector2(621,243),Vector2(680,335),Vector2(680,595)
	])
	draw_colored_polygon(silhouette,Color("#050a0d"))
	draw_polyline(silhouette,Color("#755a4d"),9,true)
	for step in 9:
		var y := 568-step*18
		var width := 310-step*22
		draw_rect(Rect2(518-width/2.0,y,width,18),Color("#34363a").darkened(step*0.08))
		draw_line(Vector2(518-width/2.0,y),Vector2(518+width/2.0,y),Color("#877362").darkened(step*0.08),2)
	draw_rect(Rect2(0,595,1280,125),Color("#201c24"))
	draw_line(Vector2(0,595),Vector2(1280,595),Color("#785b50"),3)
	draw_line(Vector2(0,625),Vector2(1280,625),Color("#443443"),2)
