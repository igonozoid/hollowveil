extends Node2D

var elapsed := 0.0
var camera_offset := 0.0

func _draw() -> void:
	for index in 38:
		var x := fposmod(index * 79.87 + elapsed * (4.0 + index % 3) - camera_offset * 1.13, 1380.0) - 50.0
		var y := 180.0 + fposmod(index * 43.6 + sin(elapsed * 0.55 + index) * 18.0, 365.0)
		var alpha := (0.5 + 0.5 * sin(elapsed * 0.77 + index)) * 0.33
		draw_circle(Vector2(x,y), 0.8 + index % 3 * 0.3, Color(0.94,0.78,0.53,alpha), true,-1,true)
	for anchor in [12.0, 1068.0, 2105.0]:
		var x: float = anchor - camera_offset * 1.10
		draw_rect(Rect2(x-17,105,34,553),Color("#10171a"))
		draw_rect(Rect2(x-10,105,5,553),Color("#273135"))
		draw_rect(Rect2(x-25,630,50,28),Color("#161d21"))
