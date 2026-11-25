extends Node2D

const Geo = preload("../presentation/vector_geometry.gd")
const Candles = preload("../presentation/candlelight.gd")
const FLOOR := 565.0
const LOCATIONS := [150.0, 545.0, 980.0, 1335.0, 1780.0]
const BRASS := Color("#bd9360")
var chapter := 0:
	set(value):
		chapter = value
		queue_redraw()
var unlocked := false:
	set(value):
		unlocked = value
		queue_redraw()
var active := -1:
	set(value):
		if active != value:
			active = value
			queue_redraw()
var candles := Candles.new()
var distance_layer := Node2D.new()

func _ready() -> void:
	add_child(distance_layer)
	distance_layer.z_index = -2
	distance_layer.draw.connect(_draw_distance)
	add_child(candles)

func update_light(elapsed: float, camera_offset: float) -> void:
	candles.elapsed = elapsed
	candles.queue_redraw()
	distance_layer.position.x = camera_offset * 0.24

func _draw_distance() -> void:
	distance_layer.draw_rect(Rect2(-450,100,2780,320),Color("#273c43"))
	for index in range(-4,28):
		var x := 99.0 * index
		var height := 32.0 + 63.0 * (sin(index*16.51)*0.5+0.5)
		distance_layer.draw_colored_polygon(PackedVector2Array([
			Vector2(x-50,310),Vector2(x-50,270),Vector2(x,270-height),Vector2(x+50,270),
			Vector2(x+50,310)
		]),Color("#18252b"))


func _draw() -> void:
	if chapter in [1,2]:
		_draw_wing()
		return
	var windows := [345.0, 755.0, 1540.0, 1990.0]
	var wall := Color("#1b272a")
	draw_rect(Rect2(-60,0,2240,140),wall)
	draw_rect(Rect2(-60,301,2240,121),wall)
	var left := -60.0
	for window_x: float in windows:
		draw_rect(Rect2(left,140,window_x-46-left,161),wall)
		_window(window_x)
		left = window_x+46
	draw_rect(Rect2(left,140,2180-left,161),wall)
	for x in [245.0,665.0,1100.0,1465.0,1885.0]:
		_pillar(x)
	for i in 22:
		var x := i*100.0
		draw_line(Vector2(x,125), Vector2(x,418), Color("#273132"), 1)
	draw_rect(Rect2(0,422,2120,143), Color("#302728"))
	for i in 23:
		var x := i*95.0
		draw_rect(Rect2(x+5,440,82,107), Color("#493738"), false, 2)
		draw_rect(Rect2(x+12,447,68,92), Color("#251d21"))
	draw_rect(Rect2(0,420,2120,8), Color("#71524b"))
	draw_rect(Rect2(0,550,2120,15), Color("#5d4641"))
	draw_rect(Rect2(0,FLOOR,2120,155), Color("#17181b"))
	for i in 3:
		draw_line(Vector2(0,FLOOR+23*i*i), Vector2(2120,FLOOR+23*i*i), Color("#403333"), 2)
	for i in range(-2,24):
		var x := i*100.0
		draw_line(Vector2(x,FLOOR), Vector2(x+58,720), Color("#352e30"), 2)
	draw_rect(Rect2(0,591,2120,36), Color("#482632"))
	draw_line(Vector2(0,594), Vector2(2120,594), Color("#81624d"), 2)
	draw_line(Vector2(0,623), Vector2(2120,623), Color("#81624d"), 2)
	for index in [0,2,4]:
		_door(LOCATIONS[index], index == 4 and unlocked)
	_clock(LOCATIONS[3])
	var plaque := Vector2(LOCATIONS[1], 367)
	draw_rect(Rect2(plaque-Vector2(55,38), Vector2(110,76)), Color("#151a1c"))
	draw_rect(Rect2(plaque-Vector2(55,38), Vector2(110,76)), BRASS, false, 2)
	draw_string(ThemeDB.fallback_font, plaque+Vector2(-37,7), "RONDAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, BRASS)
	if active >= 0:
		var mark := Vector2(LOCATIONS[active], 279)
		draw_arc(mark, 8, 0, TAU, 24, Color("#f4da9d"), 2, true)
		draw_circle(mark, 2.5, Color("#f4da9d"))

func _door(x: float, open: bool) -> void:
	var frame := PackedVector2Array([
		Vector2(x-77,550),Vector2(x-77,349),Vector2(x-64,301),Vector2(x-37,260),
		Vector2(x,225),Vector2(x+37,260),Vector2(x+64,301),Vector2(x+77,349),Vector2(x+77,550)
	])
	draw_colored_polygon(frame, Color("#211b21") if open else Color("#473238"))
	draw_polyline(frame, Color("#816052"), 7, true)
	for i in 3:
		var post := x - 51 + i*38
		draw_rect(Rect2(post,355,25,150), Color("#100e16") if open else Color("#281e26"))
		draw_rect(Rect2(post,355,25,150), Color("#61454a"), false, 2)
		for grain in 4:
			var blade := post + 4.0 + ((grain*31)%18)
			draw_line(Vector2(blade,370+grain*9),Vector2(blade+3,465-grain*5),Color(0.65,0.42,0.37,0.12),1,true)
	draw_arc(Vector2(x,324),37,PI,TAU,24,Color("#977251"),2,true)
	draw_circle(Vector2(x+46,454),5, Color("#d4b774") if open else BRASS)

func _clock(x: float) -> void:
	draw_rect(Rect2(x-43,314,86,231),Color("#251c21"))
	draw_rect(Rect2(x-41,331,82,213),BRASS,false,3)
	draw_circle(Vector2(x,349),37,Color("#211a21"),true,-1,true)
	draw_arc(Vector2(x,349),35,0,TAU,48,BRASS,3,true)
	draw_line(Vector2(x,349),Vector2(x+15,336),BRASS,2,true)
	draw_line(Vector2(x,349),Vector2(x,367),BRASS,2,true)
	draw_rect(Rect2(x-24,398,48,111),Color("#122021") if not unlocked else Color("#080e10"))
	draw_line(Vector2(x,404),Vector2(x,474),BRASS,2,true)
	draw_circle(Vector2(x,478),11,BRASS,true,-1,true)
	if unlocked:
		draw_rect(Rect2(x-18,513,36,14),Color("#e1c49b"))

func _window(x: float) -> void:
	var center := Vector2(x,211)
	for radius in range(100,35,-8):
		draw_colored_polygon(Geo.ellipse(center,Vector2(radius*0.88,radius)),
			Color(0.35,0.57,0.60,0.025))
	var frame := PackedVector2Array([
		Vector2(x-46,301), Vector2(x-46,207), Vector2(x-34,175),
		Vector2(x,140), Vector2(x+34,175), Vector2(x+46,207), Vector2(x+46,301)
	])
	# A máscara cobre os cantos, deixando a paisagem visível por trás do vidro.
	var top := Vector2(x,140)
	var left := PackedVector2Array([Vector2(x-46,140),top,frame[2],frame[1]])
	var right := PackedVector2Array([top,Vector2(x+46,140),frame[5],frame[4]])
	draw_colored_polygon(left,Color("#1b272a"))
	draw_colored_polygon(right,Color("#1b272a"))
	draw_colored_polygon(frame,Color(0.30,0.49,0.55,0.21))
	var trims := frame.duplicate()
	trims.append(frame[0])
	draw_polyline(trims,Color("#536367"),3,true)
	draw_line(Vector2(x,144),Vector2(x,300),Color("#79847d"),2,true)
	for y in [207,244,273]:
		draw_line(Vector2(x-45,y),Vector2(x+45,y),Color("#576969"),2,true)
	draw_arc(Vector2(x,207),30,PI,TAU,28,Color("#79847d"),2,true)


func _pillar(x: float) -> void:
	for band in 10:
		var color := Color("#304043").lerp(Color("#121d21"),float(band)/9)
		draw_rect(Rect2(x-21+band*4,117,4,303),color)
	draw_rect(Rect2(x-27,126,52,10),Color("#48534d"))
	draw_rect(Rect2(x-25,411,48,9),Color("#3e4844"))
	for line in 7:
		var y := 154 + line*35
		draw_line(Vector2(x-21,y),Vector2(x+19,y+2),Color("#192529"),1,true)


func _draw_wing() -> void:
	var gallery := chapter == 1
	var top := Color("#302329") if gallery else Color("#172b29")
	var bottom := Color("#19181d") if gallery else Color("#111f22")
	for band in 24:
		draw_rect(Rect2(-60,band*24,2240,25),top.lerp(bottom,band/23.0))
	for bay in range(180,2100,242):
		var x := float(bay)
		_pillar(x-94)
		if gallery:
			var niche := PackedVector2Array([Vector2(x-65,436),Vector2(x-65,225),Vector2(x,156),Vector2(x+65,225),Vector2(x+65,436)])
			draw_colored_polygon(niche,Color("#18151b"))
			draw_polyline(niche,Color("#6c4b45"),3,true)
			for frame in 3:
				draw_rect(Rect2(x-35+frame*12,251+frame*22,37,58),Color("#927053"),false,3)
				draw_rect(Rect2(x-31+frame*12,255+frame*22,29,50),Color("#402b32"))
		else:
			draw_rect(Rect2(x-70,193,150,283),Color("#172024"))
			for shelf in 5:
				var y := 235+shelf*45
				draw_rect(Rect2(x-73,y,156,6),Color("#605044"))
				for folder in 9:
					var width := 7+(folder*11+shelf*3)%8
					var height := 16+(folder*13+shelf*7)%19
					draw_rect(Rect2(x-63+folder*15,y-height,width,height),
						Color("#695548").lerp(Color("#447071"),float((folder+shelf)%6)/5))
	draw_rect(Rect2(0,522,2120,43),Color("#3a2a2b") if gallery else Color("#263737"))
	draw_rect(Rect2(0,FLOOR,2120,155),Color("#1c181c") if gallery else Color("#132528"))
	for index in 5:
		var y := FLOOR+index*index*8
		draw_line(Vector2(0,y),Vector2(2120,y),Color("#594039") if gallery else Color("#385557"),2)
	for x in [150.0,1780.0]:
		_door(x, x > 1000 and unlocked)
	var plaque := Vector2(545,367)
	draw_rect(Rect2(plaque-Vector2(61,35),Vector2(122,70)),Color("#212028"))
	draw_rect(Rect2(plaque-Vector2(61,35),Vector2(122,70)),BRASS,false,2)
	draw_string(ThemeDB.fallback_font,plaque+Vector2(-51,5),"INSTRUÇÕES",HORIZONTAL_ALIGNMENT_LEFT,-1,16,BRASS)
	var device_x := 1335.0
	draw_rect(Rect2(device_x-70,331,140,205),Color("#352d2d"))
	draw_rect(Rect2(device_x-64,336,128,194),BRASS,false,2)
	for index in (5 if gallery else 3):
		var x := device_x-45.0+index*(22.5 if gallery else 45.0)
		draw_circle(Vector2(x,384),8,BRASS if unlocked else Color("#4d4945"),true,-1,true)
		draw_line(Vector2(x,413),Vector2(x,428),BRASS,2,true)
	if unlocked:
		draw_rect(Rect2(device_x-35,471,70,24),Color("#d4b78b"))
	if active >= 0:
		var mark := Vector2(LOCATIONS[active],299)
		draw_arc(mark,8,0,TAU,24,Color("#f4da9d"),2,true)
		draw_circle(mark,2.5,Color("#f4da9d"))
