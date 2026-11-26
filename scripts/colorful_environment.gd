extends RefCounted
# One opaque, world-aligned repeating texture, captured once per scenery chunk.
static var cheerful_grass: Texture2D
static func grass(art: FarmArt) -> Texture2D:
	if cheerful_grass==null and ResourceLoader.exists("res://assets/cheerful/grass.png"): cheerful_grass=load("res://assets/cheerful/grass.png") as Texture2D
	if cheerful_grass!=null: return cheerful_grass
	return art.sprites.get("grass_meadow",{}).get("texture",null) as Texture2D
static func ground(_view: FarmView,_world_size: Vector2) -> bool:
	# Terrain is a native-resolution Sprite2D with local detail textures.
	return true
static func grass_tile(view: FarmView,at: Vector2) -> void:
	var texture=grass(view.farm_art)
	if texture==null: return
	view.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	var points=PackedVector2Array([at+Vector2(0,-40),at+Vector2(74,0),at+Vector2(0,40),at+Vector2(-74,0)])
	var uvs=PackedVector2Array()
	for p in points: uvs.append(p/texture.get_size())
	view.draw_polygon(points,PackedColorArray([Color(1,1,1,0.95)]),uvs,texture)

static func windmill_tower(view: FarmView,at: Vector2) -> void:
	view.ellipse(at+Vector2(0,25),38,14,Color("346e5133"))
	view.poly(PackedVector2Array([at+Vector2(-27,26),at+Vector2(-19,-78),at+Vector2(0,-91),at+Vector2(0,33)]),Color("ffd488"))
	view.poly(PackedVector2Array([at+Vector2(0,33),at+Vector2(0,-91),at+Vector2(21,-76),at+Vector2(30,23)]),Color("ffb268"))
	view.poly(PackedVector2Array([at+Vector2(-32,-76),at+Vector2(0,-111),at+Vector2(34,-76),at+Vector2(0,-67)]),Color("8061cf"))
	view.line(at+Vector2(-29,-77),at+Vector2(0,-107),Color("b7a0f3"),4)
	view.draw_rect(Rect2(at+Vector2(-9,1),Vector2(19,28)),Color("24b2bd"))
	view.draw_rect(Rect2(at+Vector2(-6,-45),Vector2(15,17)),Color("8ee9ff"))
	for x in [-32,29]: view.paint_flower(at+Vector2(x,26),Color("f581c3"))
static func windmill_rotor(view: FarmView,at: Vector2,angle: float) -> void:
	for i in 4:
		var a=angle+i*TAU/4.0
		var d=Vector2.RIGHT.rotated(a)
		var side=d.orthogonal()
		view.line(at,at+d*48,Color("d39746"),5)
		view.poly(PackedVector2Array([at+d*17-side*3,at+d*48-side*3,at+d*47+side*12,at+d*19+side*8]),Color("fff0c7"))
		view.line(at+d*21+side*6,at+d*44+side*8,Color("9e8cdd"),3)
	view.draw_circle(at,7,Color("ffc453"))
	view.draw_circle(at-Vector2(2,2),3,Color("fff3b4"))
