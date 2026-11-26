extends RefCounted

# Each material is sampled locally rather than stretching one world-map image.
const MATERIALS := ["spring_grass","summer_grass","autumn_ground","winter_snow","garden_soil","river_water","cliff_rock","stone_path","bridge_wood"]
const TILE_WORLD_SIZE := 256.0
static var textures: Dictionary = {}

static func texture(id: String) -> Texture2D:
	if not textures.has(id): textures[id]=load("res://assets/terrain_kit/materials/"+id+".png") as Texture2D
	return textures[id]

static func patch(canvas: CanvasItem, polygon: PackedVector2Array, id: String, tint:=Color.WHITE) -> void:
	var uv:=PackedVector2Array()
	for point in polygon: uv.append(point/TILE_WORLD_SIZE)
	# Mirroring keeps generated edge differences from producing hard seams.
	canvas.texture_repeat=CanvasItem.TEXTURE_REPEAT_MIRROR
	canvas.draw_polygon(polygon,PackedColorArray([tint]),uv,texture(id))

static func rectangle(canvas: CanvasItem, area: Rect2, id: String, tint:=Color.WHITE) -> void:
	patch(canvas,PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)]),id,tint)

static func ribbon(canvas: CanvasItem, route: PackedVector2Array, width: float, id: String, tint:=Color.WHITE) -> void:
	if route.size()<2: return
	var curve:=Curve2D.new()
	curve.bake_interval=10.0
	for i in route.size():
		var previous=route[maxi(0,i-1)]
		var next=route[mini(route.size()-1,i+1)]
		var tangent=(next-previous)/6.0
		curve.add_point(route[i],-tangent,tangent)
	var points=curve.get_baked_points()
	var left:=PackedVector2Array()
	var right:=PackedVector2Array()
	for i in points.size():
		var direction=(points[mini(points.size()-1,i+1)]-points[maxi(0,i-1)]).normalized()
		var normal=direction.orthogonal()*width*0.5
		left.append(points[i]-normal)
		right.append(points[i]+normal)
	right.reverse()
	left.append_array(right)
	patch(canvas,left,id,tint)

static func river(canvas: CanvasItem, route: PackedVector2Array, width: float) -> void:
	# A separate geological face supplies elevation and bank contact shadow.
	var lower:=PackedVector2Array()
	for point in route: lower.append(point+Vector2(0,28))
	ribbon(canvas,lower,width+88,"cliff_rock",Color("9a927c"))
	ribbon(canvas,route,width+47,"garden_soil",Color("aab098"))
	ribbon(canvas,route,width,"river_water")
	canvas.draw_polyline(route,Color(0.8,0.98,1.0,0.32),2,true)

static func bridge(canvas: CanvasItem, from: Vector2, to: Vector2, width:=86.0) -> void:
	ribbon(canvas,PackedVector2Array([from,to]),width,"bridge_wood")
	var normal=(to-from).normalized().orthogonal()*width*0.52
	for side in [-1,1]:
		canvas.draw_line(from+normal*side,to+normal*side,Color("835531"),7,true)
		for i in 6:
			var foot=from.lerp(to,float(i)/5)+normal*side
			canvas.draw_line(foot,foot-Vector2(0,24),Color("b88048"),8,true)

static func cliff(canvas: CanvasItem, top_edge: PackedVector2Array, height: float, cap_material: String) -> void:
	for i in range(1,top_edge.size()):
		var a=top_edge[i-1];var b=top_edge[i]
		patch(canvas,PackedVector2Array([a,b,b+Vector2(0,height),a+Vector2(0,height)]),"cliff_rock")
	ribbon(canvas,top_edge,24,cap_material)

static func waterfall(canvas: CanvasItem, lip: Vector2, width: float, height: float) -> void:
	var face=PackedVector2Array([lip-Vector2(width*0.5+25,0),lip+Vector2(width*0.5+25,0),lip+Vector2(width*0.6+25,height),lip+Vector2(-width*0.6-25,height)])
	patch(canvas,face,"cliff_rock")
	patch(canvas,PackedVector2Array([lip-Vector2(width*0.5,0),lip+Vector2(width*0.5,0),lip+Vector2(width*0.58,height),lip+Vector2(-width*0.58,height)]),"river_water",Color("c4f5ff"))
	for i in 12:
		var foot=lip+Vector2((float(i)/11.0-0.5)*width*1.15,height)
		canvas.draw_circle(foot,8+float(i%3)*3,Color(0.92,1,1,0.8))

static func animated_water(polygon: PackedVector2Array, direction:=Vector2(0.035,0.07)) -> Polygon2D:
	var surface:=Polygon2D.new()
	surface.polygon=polygon
	surface.texture=texture("river_water")
	surface.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	var uv:=PackedVector2Array()
	for point in polygon: uv.append(point/TILE_WORLD_SIZE*surface.texture.get_size())
	surface.uv=uv
	var flow:=ShaderMaterial.new()
	flow.shader=preload("res://assets/terrain_kit/water_flow.gdshader")
	flow.set_shader_parameter("flow_direction",direction)
	surface.material=flow
	return surface
