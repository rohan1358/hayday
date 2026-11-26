extends Node2D
const KIT=preload("res://scripts/terrain_asset_kit.gd")
var zoom:=1.0
var offset:=Vector2.ZERO
var dragging:=false

func _ready() -> void:
	get_window().size=Vector2i(1200,1000)
	get_window().content_scale_size=Vector2i(1200,1000)
	get_window().title="Cheerful Garden · Terrain Asset Kit · Wheel zoom / drag pan"
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT: dragging=event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var previous=zoom
			zoom=clampf(zoom*(1.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.15),0.4,2.0)
			offset=event.position-(event.position-offset)*zoom/previous
			queue_redraw()
	if event is InputEventMouseMotion and dragging:
		offset+=event.relative
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-5000,-5000,10000,10000),Color("263a34"))
	draw_set_transform(offset,0,Vector2.ONE*zoom)
	var names=["SPRING GRASS","SUMMER GRASS","AUTUMN EARTH","WINTER SNOW","GARDEN SOIL","FLOWING WATER","CLIFF ROCK","STONE PATH","BRIDGE WOOD"]
	var font=ThemeDB.fallback_font
	for i in KIT.MATERIALS.size():
		var area=Rect2(25+(i%3)*390,50+floori(float(i)/3)*230,365,190)
		KIT.rectangle(self,area,KIT.MATERIALS[i])
		draw_string(font,area.position+Vector2(8,-10),names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff4d0"))
	KIT.rectangle(self,Rect2(25,775,1145,205),"spring_grass")
	var route=PackedVector2Array([Vector2(25,900),Vector2(220,850),Vector2(470,920),Vector2(710,865),Vector2(950,910),Vector2(1170,845)])
	KIT.river(self,route,64)
	KIT.ribbon(self,PackedVector2Array([Vector2(80,790),Vector2(330,835),Vector2(590,830),Vector2(900,800),Vector2(1170,810)]),42,"stone_path")
	KIT.bridge(self,Vector2(570,835),Vector2(620,950))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
