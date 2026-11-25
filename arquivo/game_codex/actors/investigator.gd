extends Node2D

const Geo = preload("../presentation/vector_geometry.gd")
const Light = preload("../presentation/vector_light.gd")
const Candles = preload("../presentation/candlelight.gd")

var stride := 0.0
var gait := 0.0
var facing := 1.0
var walking := false
var breath := 0.0
var light := Light.new()

func _process(delta: float) -> void:
	gait = move_toward(gait, float(walking), delta*5.0)
	stride = fposmod(stride+delta*9.5,TAU)
	breath += delta
	queue_redraw()

func set_light(elapsed: float, inside_landing: bool) -> void:
	var closest: float = Candles.POSITIONS[0]
	for candle: float in Candles.POSITIONS:
		if absf(candle-position.x) < absf(closest-position.x):
			closest = candle
	light.position = Vector2((closest-position.x)*facing, -165)
	light.radius = 315.0
	light.ambient = 0.57 if inside_landing else 0.66+sin(elapsed*7.5)*0.04

func oval(at: Vector2, radii: Vector2, color: Color) -> void:
	draw_colored_polygon(Geo.ellipse(at, radii),light.shade(color,0.86,at))

func shape(points: Array, color: Color) -> void:
	var vertices := PackedVector2Array(points)
	draw_colored_polygon(vertices,light.shade(color,0.82,vertices[0]))

func _draw() -> void:
	var swing := sin(stride)*gait
	var bob := absf(cos(stride))*3.5*gait + sin(breath*2.0)*0.65
	draw_colored_polygon(Geo.ellipse(Vector2(1,3),Vector2(38,8)),Color(0.018,0.018,0.022,0.72))
	draw_set_transform(Vector2.ZERO,0.0,Vector2(facing,1))
	_leg(-1,bob,Color("#312c38"))
	_arm(Vector2(-10,-114-bob),-swing,Color("#623647"))
	_leg(1,bob,Color("#51404b"))
	draw_set_transform(Vector2(swing*1.8,-bob),0.0,Vector2(facing,1))
	_coat(swing)
	_head()
	_arm(Vector2(-17,-119),swing,Color("#7e4353"))

func _leg(side: int, bob: float, color: Color) -> void:
	var phase := stride + (PI if side < 0 else 0.0)
	var lift := maxf(0.0, sin(phase))*12.0*gait
	var hip := Vector2(side*11,-65-bob)
	var knee := Vector2(side*10+cos(phase)*9.0*gait,-33-lift*0.8)
	var ankle := Vector2(side*10+cos(phase)*24.0*gait,-8-lift)
	shape([hip+Vector2(-11,0),hip+Vector2(13,0),knee+Vector2(9,0),
		ankle+Vector2(6,0),ankle+Vector2(-6,0),knee+Vector2(-9,4)],color)
	draw_line(knee+Vector2(4,0),ankle+Vector2(3,-2),light.shade(Color("#846572"),0.82,knee),1.2,true)
	shape([ankle+Vector2(-6,-9),ankle+Vector2(5,-9),ankle+Vector2(7,0),
		ankle+Vector2(14,3),ankle+Vector2(14,7),ankle+Vector2(-7,7)],Color("#292026"))
	draw_line(ankle+Vector2(-6,6),ankle+Vector2(13,6),Color("#705457"),1.3,true)

func _coat(swing: float) -> void:
	var hem := swing*5.0
	shape([Vector2(-18,-131),Vector2(10,-131),Vector2(22,-123),Vector2(25,-108),
		Vector2(19,-96),Vector2(20,-86),Vector2(28,-68),Vector2(34+hem,-43),
		Vector2(19,-35),Vector2(-13,-37),Vector2(-34+hem,-48),Vector2(-28,-69),
		Vector2(-20,-88),Vector2(-21,-108)],Color("#793e50"))
	shape([Vector2(8,-128),Vector2(20,-120),Vector2(22,-109),Vector2(14,-97),
		Vector2(19,-81),Vector2(25+hem,-45),Vector2(14,-40),Vector2(8,-67),Vector2(5,-101)],Color("#a56364"))
	shape([Vector2(-17,-126),Vector2(-8,-116),Vector2(-13,-89),Vector2(-15,-70),
		Vector2(-22,-52),Vector2(-31+hem,-48),Vector2(-26,-71),Vector2(-20,-87)],Color("#4f2a40"))
	shape([Vector2(-9,-131),Vector2(9,-132),Vector2(13,-121),Vector2(4,-111),
		Vector2(-7,-120)],Color("#b29274"))
	draw_line(Vector2(-20,-90),Vector2(19,-89),Color("#392832"),5.5,true)
	draw_rect(Rect2(6,-94,8,8),Color("#bb8e5c"),false,1.5)
	draw_polyline(PackedVector2Array([Vector2(6,-111),Vector2(9,-94),Vector2(16,-71),Vector2(19+hem*0.5,-43)]),
		light.shade(Color("#bf8278"),0.73,Vector2(9,-94)),1.5,true)
	for y in [-107,-99,-76,-64]:
		oval(Vector2(12,y),Vector2(1.6,1.6),Color("#cea87a"))

func _head() -> void:
	oval(Vector2(-3,-148),Vector2(18,24),Color("#36272c"))
	shape([Vector2(-3,-153),Vector2(10,-157),Vector2(16,-149),Vector2(17,-142),
		Vector2(23,-137),Vector2(18,-134),Vector2(16,-127),Vector2(10,-124),Vector2(0,-128),
		Vector2(-8,-138)],Color("#d69479"))
	shape([Vector2(-9,-141),Vector2(-1,-139),Vector2(11,-128),Vector2(11,-124),
		Vector2(0,-128),Vector2(-6,-131)],Color("#a75f52"))
	shape([Vector2(-20,-151),Vector2(-16,-163),Vector2(-5,-172),Vector2(10,-167),
		Vector2(16,-158),Vector2(14,-153),Vector2(0,-158),Vector2(-4,-144),
		Vector2(-10,-134),Vector2(-18,-134)],Color("#473138"))
	draw_line(Vector2(-12,-160),Vector2(-1,-165),Color("#8a5953"),1.7,true)
	draw_line(Vector2(9,-145),Vector2(15,-145),Color("#41252f"),1.8,true)
	draw_line(Vector2(12,-132),Vector2(16,-132),Color("#723c3d"),1.2,true)
	oval(Vector2(-1,-136),Vector2(2.5,4),Color("#d39476"))
	oval(Vector2(-1,-130),Vector2(1.5,1.8),Color("#dbb37e"))

func _arm(shoulder: Vector2, swing: float, color: Color) -> void:
	var elbow := shoulder+Vector2(-3-swing*9,23)
	var hand := elbow+Vector2(1-swing*10,21)
	shape([shoulder+Vector2(-7,-2),shoulder+Vector2(7,0),elbow+Vector2(7,0),
		hand+Vector2(5,0),hand+Vector2(-5,0),elbow+Vector2(-6,2)],color)
	draw_line(shoulder+Vector2(4,1),elbow+Vector2(5,0),light.shade(Color("#bc7b7b"),0.75,elbow),1.3,true)
	oval(hand+Vector2(0,4),Vector2(4.5,6),Color("#bc7b66"))
