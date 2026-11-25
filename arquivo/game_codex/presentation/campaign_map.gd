extends ColorRect

signal closed

const GOLD := Color("#e5c38e")
const MUTED := Color("#9baba8")
const ROOM_NAMES := ["Corredor da Vigília", "Galeria das Lanternas", "Arquivo Submerso"]
const TITLES := [
	["Entrada","Painel","Sala lacrada","Relógio","Porta"],
	["Entrada","Instruções","Vestígio","Lanternas","Saída"],
	["Entrada","Instruções","Vestígio","Selos","Portão"]
]
var chapter := 0
var location := 0.0
var landing := false
var exit_open := false
var back := Button.new()

func _ready() -> void:
	size = Vector2(1280,720)
	color = Color(0.045,0.075,0.083,0.98)
	back.text = "Voltar"
	back.position = Vector2(520,607)
	back.size = Vector2(240,48)
	back.pressed.connect(func(): closed.emit())
	add_child(back)
	hide()

func inspect(stage: int, x: float, on_landing: bool, unlocked: bool) -> void:
	chapter = stage
	location = x
	landing = on_landing
	exit_open = unlocked
	show()
	back.grab_focus()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(88,46,1104,630),Color("#76604a"),false,2)
	_caption("MAPA DA MANSÃO",Vector2(245,104),790,35,GOLD)
	for index in ROOM_NAMES.size():
		var x := 158.0+328.0*index
		var box := Rect2(x,145,308,85)
		draw_rect(box,Color("#28383a") if index == chapter else Color("#172427"))
		draw_rect(box,GOLD if index == chapter else Color("#4e5c56"),false,2)
		_caption(ROOM_NAMES[index],Vector2(x,178),308,20,GOLD if index == chapter else MUTED)
		var status := "Percorrido" if index < chapter else ("Você está aqui" if index == chapter else "Por explorar")
		_caption(status,Vector2(x,208),308,16,MUTED)
	if landing:
		_caption("Patamar",Vector2(290,333),700,30,GOLD)
		_caption("← Galeria das Lanternas                     Corredor da Vigília →",Vector2(200,410),880,24,MUTED)
		return
	var start := 158.0
	var width := 964.0
	var y := 398.0
	draw_line(Vector2(start,y),Vector2(start+width,y),Color("#526865"),6,true)
	var markers := [150.0,545.0,980.0,1335.0,1780.0]
	for index in markers.size():
		var x: float = start+width*markers[index]/2120.0
		var ink := GOLD if index < 4 or exit_open else MUTED
		draw_circle(Vector2(x,y),8,ink,true,-1,true)
		_caption(TITLES[chapter][index],Vector2(x-75,y+43),150,17,ink)
	var player_x := start+width*clampf(location,0.0,2120.0)/2120.0
	draw_line(Vector2(player_x,y-35),Vector2(player_x,y-9),GOLD,2,true)
	draw_circle(Vector2(player_x,y-37),6,GOLD,true,-1,true)
	_caption("Lia",Vector2(player_x-70,y-55),140,18,GOLD)
	_caption("Saída liberada" if exit_open else "Saída bloqueada pelo enigma da ala",
		Vector2(200,514),880,21,MUTED)

func _caption(value: String, at: Vector2, width: int, font_size: int, ink: Color) -> void:
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_CENTER,width,font_size,ink)
