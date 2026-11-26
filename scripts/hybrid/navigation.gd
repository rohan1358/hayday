extends RefCounted
# Cached navigation for both actors and livestock. Static geometry is rasterized
# only after a layout/zone revision; animal circles are queried at movement time.
const CELL = 28.0
const RADIUS = 10.0
var farm
var grid: AStarGrid2D
var rects: Array[Rect2]=[]
var circles: Array[Dictionary]=[]
var diamonds: Array[Vector2]=[]
var revision=""
var build_count=0
static var terrain_cells=PackedVector2Array()
static var terrain_ready=false
static var bridge_signature=""
var dynamic: Array=[]
var fence_segments: Array=[]

func configure(view) -> void:
	farm=view
func signature() -> String:
	var zones: Array=[]
	for zone in farm.game.hybrid.get("zones",[]): zones.append([zone.get("id",0),zone.get("position",[]),zone.get("size",[]),zone.get("gate_open",false),zone.get("gate_edge",1)])
	return str(farm.game.building_upgrades.get("nodes",[]).map(func(n): return n.get("position",[])))+str(farm.game.layout_positions)+str(farm.game.decorations)+str(farm.game.constructions)+str(farm.game.cleared_wild_trees)+str(zones)+str([farm.game.ranch.get("pens",{}).get("ayam",{}).get("tier",1),farm.game.ranch.get("pens",{}).get("sapi",{}).get("tier",1),farm.game.ranch.get("pens",{}).get("babi",{}).get("tier",1),farm.game.ranch.get("pens",{}).get("kambing",{}).get("tier",1)])
func ensure() -> void:
	var current=signature()+str(farm.game.level)+str(farm.game.ftue.get("coop_built",false))+str(farm.game.ftue.get("cow_built",false))
	if grid!=null and current==revision: return
	revision=current
	build_count+=1
	rects.clear()
	fence_segments.clear()
	circles.clear()
	diamonds.clear()
	for rect in farm.ujang_obstacle_rects(): rects.append(rect.grow(RADIUS))
	for node in ([] if preload("res://scripts/first_farm.gd").active(farm.game) else farm.game.building_upgrades.get("nodes",[])): circles.append({"at":Vector2(node.position[0],node.position[1]),"radius":32.0})
	for i in farm.game.plots.size():
		if not preload("res://scripts/first_farm.gd").compact(farm.game) or farm.game.plots[i].unlocked: diamonds.append(farm.plot_center(i))
	for i in farm.WILD_TREES.size():
		if farm.wild_tree_active(i): circles.append({"at":farm.wild_tree_position(i),"radius":farm.UJANG_TREE_RADIUS+RADIUS})
	for i in (1 if preload("res://scripts/first_farm.gd").compact(farm.game) else farm.game.ORCHARD_SIZE): circles.append({"at":farm.orchard_center(i),"radius":farm.UJANG_ORCHARD_RADIUS+RADIUS})
	for key in farm.editable_keys():
		if not key.begins_with("scenery_") and not key.begins_with("dekor_") and not key.begins_with("starter_"): continue
		var half: Vector2=farm.object_half_size(key)
		# Ground footprints, rather than leaves/canopies, block movement.
		rects.append(Rect2(farm.object_position(key)-half,half*2).grow(RADIUS))
	for zone in farm.game.hybrid.get("zones",[]):
		for edge in fence_edges(zone):
			var a: Vector2=edge[0]
			var b: Vector2=edge[1]
			fence_segments.append([a,b])
	grid=AStarGrid2D.new()
	grid.region=Rect2i(Vector2i.ZERO,Vector2i(ceili(farm.WORLD_SIZE.x/CELL),ceili(farm.WORLD_SIZE.y/CELL)))
	grid.cell_size=Vector2.ONE*CELL
	grid.offset=Vector2.ONE*CELL*0.5
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	# The island terrain is immutable; dynamic buildings/trees are rasterized below.
	var bridges=str(preload("res://scripts/reference_terrain.gd").bridge_paths())
	if bridges!=bridge_signature:terrain_ready=false;terrain_cells.clear();bridge_signature=bridges
	if not terrain_ready:
		for y in grid.region.size.y:
			for x in grid.region.size.x:
				var cell=Vector2i(x,y)
				if preload("res://scripts/four_seasons.gd").blocked(farm.game,grid.get_point_position(cell)):terrain_cells.append(Vector2(cell))
		terrain_ready=true
	for cell in terrain_cells:grid.set_point_solid(Vector2i(cell),true)
	for rect in rects: raster(rect,0,{})
	for circle in circles:
		var radius: float=circle.radius
		raster(Rect2(circle.at-Vector2.ONE*radius,Vector2.ONE*radius*2),1,circle)
	for at in diamonds: raster(Rect2(at-Vector2(88,50),Vector2(176,100)),2,{"at":at})
	for edge in fence_segments: raster(Rect2(edge[0].min(edge[1]),(edge[0]-edge[1]).abs()).grow(RADIUS+4),3,{"a":edge[0],"b":edge[1]})
func raster(bounds: Rect2,kind: int,data: Dictionary) -> void:
	var first=Vector2i((bounds.position/CELL).floor()).max(Vector2i.ZERO)
	var last=Vector2i((bounds.end/CELL).ceil()).min(grid.region.size-Vector2i.ONE)
	for y in range(first.y,last.y+1):
		for x in range(first.x,last.x+1):
			var id=Vector2i(x,y)
			var point=grid.get_point_position(id)
			var solid=bounds.grow(CELL*0.3).has_point(point)
			if kind==1: solid=point.distance_to(data.at)<=float(data.radius)+CELL*0.3
			if kind==2:
				var diff: Vector2=(point-data.at).abs()
				solid=diff.x/88.0+diff.y/50.0<1.15
			if kind==3: solid=Geometry2D.get_closest_point_to_segment(point,data.a,data.b).distance_to(point)<=RADIUS+4+CELL*0.3
			if solid: grid.set_point_solid(id,true)
func fence_edges(zone: Dictionary,include_gate = false) -> Array:
	var polygon=preload("res://scripts/hybrid/hybrid_state.gd").zone_polygon(zone)
	var edges: Array=[]
	var selected=clampi(int(zone.get("gate_edge",1)),0,3)
	for i in 4:
		var a: Vector2=polygon[i]
		var b: Vector2=polygon[(i+1)%4]
		if i!=selected:
			edges.append([a,b])
			continue
		var middle=(a+b)*0.5
		var along=(b-a).normalized()*minf(56,a.distance_to(b)*0.28)
		edges.append([a,middle-along])
		edges.append([middle+along,b])
		if include_gate or not bool(zone.get("gate_open",false)): edges.append([middle-along,middle+along])
	return edges
func blocked(point: Vector2) -> bool:
	if preload("res://scripts/four_seasons.gd").blocked(farm.game,point): return true
	if not Rect2(Vector2.ONE*12,farm.WORLD_SIZE-Vector2.ONE*24).has_point(point): return true
	for edge in fence_segments:
		if Geometry2D.get_closest_point_to_segment(point,edge[0],edge[1]).distance_to(point)<RADIUS+4: return true
	for value in dynamic:
		if point.distance_to(value.at)<float(value.radius): return true
	for rect in rects:
		if rect.has_point(point): return true
	for circle in circles:
		if point.distance_squared_to(circle.at)<pow(float(circle.radius),2): return true
	for at in diamonds:
		var diff: Vector2=(point-at).abs()
		if diff.x/88.0+diff.y/50.0<1.0: return true
	return false
func clear_segment(a: Vector2,b: Vector2) -> bool:
	for rect in rects:
		if farm.ujang_segment_intersects_rect(a,b,rect): return false
	var steps=maxi(1,ceili(a.distance_to(b)/10))
	for i in range(steps+1):
		if blocked(a.lerp(b,float(i)/steps)): return false
	return true
func cell_at(point: Vector2) -> Vector2i:
	return Vector2i((point/CELL).floor())
func nearest(point: Vector2,limit=112.0) -> Vector2:
	if not blocked(point): return point
	for radius in range(14,int(limit)+1,14):
		for angle in 16:
			var candidate=point+Vector2.from_angle(angle*TAU/16)*radius
			if not blocked(candidate): return candidate
	return Vector2.INF
func nearest_cell(point: Vector2) -> Vector2i:
	var center=cell_at(point)
	for radius in 5:
		var candidates: Array[Vector2i]=[]
		for y in range(center.y-radius,center.y+radius+1):
			for x in range(center.x-radius,center.x+radius+1):
				var id=Vector2i(x,y)
				if grid.region.has_point(id) and not grid.is_point_solid(id) and clear_segment(point,grid.get_point_position(id)): candidates.append(id)
		if not candidates.is_empty():
			candidates.sort_custom(func(a,b): return grid.get_point_position(a).distance_squared_to(point)<grid.get_point_position(b).distance_squared_to(point))
			return candidates[0]
	return Vector2i(-1,-1)
func path(start: Vector2,finish: Vector2,avoid: Array=[]) -> PackedVector2Array:
	var previous=dynamic
	dynamic=avoid
	var result=compute_path(start,finish)
	dynamic=previous
	return result
func compute_path(start: Vector2,finish: Vector2) -> PackedVector2Array:
	ensure()
	if blocked(start) or blocked(finish): return PackedVector2Array()
	if clear_segment(start,finish): return PackedVector2Array([start,finish])
	var source=nearest_cell(start)
	var target=nearest_cell(finish)
	if source.x<0 or target.x<0: return PackedVector2Array()
	var changed: Array[Vector2i]=[]
	for value in dynamic:
		var middle=cell_at(value.at)
		for y in range(middle.y-2,middle.y+3):
			for x in range(middle.x-2,middle.x+3):
				var cell=Vector2i(x,y)
				if cell!=source and cell!=target and grid.region.has_point(cell) and not grid.is_point_solid(cell) and grid.get_point_position(cell).distance_to(value.at)<float(value.radius)+CELL*0.5:
					grid.set_point_solid(cell,true)
					changed.append(cell)
	var ids=grid.get_id_path(source,target)
	for cell in changed: grid.set_point_solid(cell,false)
	if ids.is_empty(): return PackedVector2Array()
	var raw=PackedVector2Array([start])
	for id in ids: raw.append(grid.get_point_position(id))
	raw.append(finish)
	var result=PackedVector2Array([start])
	var cursor=0
	while cursor<raw.size()-1:
		var next=cursor+1
		for j in range(raw.size()-1,cursor,-1):
			if clear_segment(raw[cursor],raw[j]):
				next=j
				break
		if not clear_segment(raw[cursor],raw[next]): return PackedVector2Array()
		result.append(raw[next])
		cursor=next
	return result
func approach(start: Vector2,target: Vector2,reach: float,avoid: Array=[]) -> PackedVector2Array:
	ensure()
	var candidates: Array[Vector2]=[]
	if start.distance_to(target)<=reach and not blocked(start): return PackedVector2Array([start])
	for radius in [reach*0.65,reach*0.9]:
		for i in 16:
			var point: Vector2=target+Vector2.from_angle(i*TAU/16)*radius
			if not blocked(point): candidates.append(point)
	candidates.sort_custom(func(a,b): return a.distance_squared_to(start)<b.distance_squared_to(start))
	for point in candidates:
		var route=path(start,point,avoid)
		if not route.is_empty(): return route
	return PackedVector2Array()
