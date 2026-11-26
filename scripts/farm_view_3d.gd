extends FarmView

const MODELS = preload("res://scripts/models_3d.gd")
var viewport_3d: SubViewport
var scene_3d: Node3D
var world_models: Node3D
var camera_3d: Camera3D
var farmer: Node3D
var scene_signature := ""
var refresh_timer := 0.0
var ground_mesh: MeshInstance3D
var name_label: Label3D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	reset_camera()
	var display := SubViewportContainer.new()
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.stretch = true
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)
	viewport_3d = SubViewport.new()
	viewport_3d.own_world_3d = true
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	display.add_child(viewport_3d)
	scene_3d = Node3D.new()
	viewport_3d.add_child(scene_3d)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("c6e2e9")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("fff3dc")
	settings.ambient_light_energy = 0.35
	environment.environment = settings
	scene_3d.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-30,0)
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	scene_3d.add_child(sun)
	camera_3d = Camera3D.new()
	camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
	scene_3d.add_child(camera_3d)
	camera_3d.current = true
	ground_mesh = MODELS.shape(scene_3d,"box",Vector3(18,-0.2,14.5),Vector3(42,0.3,35),Color("8fbb73"))
	world_models = Node3D.new()
	scene_3d.add_child(world_models)
	sync_camera()
	rebuild()

func world_point(at: Vector2) -> Vector3:
	return Vector3(at.x/100.0,0,at.y/100.0)

func sync_camera() -> void:
	if camera_3d == null: return
	var target := world_point(camera_center)
	camera_3d.position = target + Vector3(0,16,12)
	camera_3d.look_at(target)
	camera_3d.size = 10.5 / camera_zoom

func screen_to_world(at: Vector2) -> Vector2:
	if camera_3d == null: return super.screen_to_world(at)
	var pixel := at * Vector2(viewport_3d.size) / size
	var origin := camera_3d.project_ray_origin(pixel)
	var direction := camera_3d.project_ray_normal(pixel)
	var hit: Variant = Plane(Vector3.UP,0).intersects_ray(origin,direction)
	return Vector2(hit.x,hit.z)*100 if hit != null else camera_center

func pan_by(movement: Vector2) -> void:
	var center := size * 0.5
	camera_target += screen_to_world(center) - screen_to_world(center + movement)
	clamp_camera_target()

func zoom_at(at: Vector2, new_zoom: float) -> void:
	var before := screen_to_world(at)
	zoom_target = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	camera_zoom = zoom_target
	sync_camera()
	camera_target += before - screen_to_world(at)
	clamp_camera_target()

func _process(delta: float) -> void:
	shimmer += delta
	camera_center = camera_center.lerp(camera_target,minf(1,delta*12))
	camera_zoom = lerpf(camera_zoom,zoom_target,minf(1,delta*12))
	sync_camera()
	update_ujang(delta)
	refresh_timer += delta
	if refresh_timer > 0.3:
		refresh_timer = 0
		var ready_states: Array = []
		for i in game.plots.size(): ready_states.append(game.is_ready(i))
		var signature := JSON.stringify([ready_states, game.plots,game.layout_positions,game.decorations,game.road_tiles.keys(),game.constructions,game.cleared_wild_trees,game.seasonal,selected_plot,edit_mode,drag_key,drag_preview,placement_decoration_key,placement_preview])
		if signature != scene_signature:
			scene_signature = signature
			rebuild()
	if farmer != null:
		farmer.position = world_point(ujang_position)
		farmer.rotation.y = sin(shimmer*0.2)*0.25
		var walk := sin(shimmer*9)*0.3 if ujang_walking else 0.0
		farmer.get_node("LegL").rotation.x = walk
		farmer.get_node("LegR").rotation.x = -walk
		farmer.get_node("ArmL").rotation.x = -walk
		farmer.get_node("ArmR").rotation.x = walk
	queue_redraw()

func place(model: Node3D, at: Vector2, factor := 1.0) -> void:
	world_models.add_child(model)
	model.position = world_point(at)
	model.scale *= factor

func tag(model: Node3D, text: String, height := 2.3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 38
	label.pixel_size = 0.006
	label.position.y = height
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	model.add_child(label)

func rebuild() -> void:
	for child in world_models.get_children():
		world_models.remove_child(child)
		child.queue_free()
	farmer = null
	var season := int(game.seasonal.get("preview",-1))
	if season < 0:
		season = int(maxi(0,int(Time.get_unix_time_from_system())-int(game.seasonal.get("epoch",0)))/600)%4
	ground_mesh.material_override = MODELS.material(Color(["90bb78","b4bf78","b7a26e","dee9e5"][season]))
	for index in game.plots.size():
		var at := plot_center(index)
		var patch := Node3D.new()
		place(patch,at)
		var plot: Dictionary = game.plots[index]
		MODELS.shape(patch,"box",Vector3(0,0.01,0),Vector3(1.65,0.15,0.8),Color("6f4c35") if plot.unlocked else Color("a0b684"))
		if index == selected_plot:
			MODELS.shape(patch,"box",Vector3(0,-0.01,0),Vector3(1.78,0.12,0.93),Color("f4d477"))
		var crop := str(plot.get("crop",""))
		if crop != "" and game.CROPS.has(crop):
			var ready: bool = game.is_ready(index)
			for j in 6:
				var x := (j%3-1)*0.43
				var z := (int(j/3)-0.5)*0.36
				var height := 0.65 if ready else 0.25
				MODELS.shape(patch,"cylinder",Vector3(x,height/2+0.1,z),Vector3(0.045,height,0.045),Color("599159"))
				MODELS.shape(patch,"sphere",Vector3(x,height+0.12,z),Vector3(0.23,0.3,0.23),Color(game.CROPS[crop].color) if ready else Color("77a75d"))
			if ready: tag(patch,"PANEN",1.2)
	for key in ["dapur","gudang","pasar","pakan","roti","susu"]:
		if key in ["roti","susu"] and not game.constructions.get(key,false): continue
		var model := MODELS.building(Color("e3bd7c") if key != "gudang" else Color("bd6d58"))
		place(model,object_position(key),0.85)
		tag(model,key.to_upper())
	for key in ["ayam","sapi","babi","kambing"]:
		if key in ["babi","kambing"] and not game.constructions.get(key,false): continue
		var pen := Node3D.new()
		place(pen,object_position(key))
		MODELS.shape(pen,"box",Vector3(0,-0.02,0),Vector3(2.5,0.15,1.8),Color("d5bb80"))
		for j in 4:
			MODELS.shape(pen,"box",Vector3(-1.2+j*0.8,0.35,-0.85),Vector3(0.1,0.7,0.1),Color("a07850"))
		MODELS.shape(pen,"box",Vector3(0,0.45,-0.85),Vector3(2.6,0.09,0.1),Color("d8bd8c"))
		for j in 2:
			var animal := MODELS.animal(key)
			pen.add_child(animal)
			animal.position = Vector3(-0.5+j,0,0)
		tag(pen,key.to_upper(),1.8)
	for index in WILD_TREES.size():
		if index not in game.cleared_wild_trees:
			place(MODELS.tree(season==2),WILD_TREES[index],0.9)
	for i in 2:
		var tree := MODELS.tree(season==2)
		place(tree,orchard_center(i))
		tag(tree,"BUAH",2.5)
	for i in MOVABLE_SCENERY.size():
		var kind: String = MOVABLE_SCENERY[i][0]
		var model: Node3D
		if "fence" in kind:
			model = Node3D.new()
			MODELS.shape(model,"box",Vector3(0,0.3,0),Vector3(1.1,0.1,0.1),Color("e3c59a"))
		elif "water" in kind or "well" in kind or "tower" in kind:
			model = MODELS.prop("equipment",1)
		else:
			model = MODELS.prop("decor",0)
		place(model,object_position("scenery_%d"%i),0.7)
	for decoration in game.decorations:
		var pos: Array = decoration.get("position",[])
		if pos.size()==2: place(MODELS.prop("decor",0),Vector2(pos[0],pos[1]),0.8)
	for tile in game.road_tiles:
		var cell := Vector2.ZERO
		if tile is Vector2i or tile is Vector2: cell = Vector2(tile)
		elif tile is String:
			var parts := str(tile).split(",")
			if parts.size()==2: cell=Vector2(float(parts[0]),float(parts[1]))
		MODELS.shape(world_models,"box",world_point(cell*80+Vector2.ONE*40)+Vector3(0,-0.01,0),Vector3(0.8,0.05,0.8),Color("bc9a6a"))
	for i in 4:
		for kind in ["decor","equipment"]:
			if kind+str(i) in game.seasonal.owned:
				place(MODELS.prop(kind,i),Vector2(540+i*190,1620 if kind=="equipment" else 1780),0.7)
	farmer = MODELS.person(game.seasonal)
	place(farmer,ujang_position,0.8)
	tag(farmer,str(game.seasonal.get("name","Ujang")),2.4)
	if not game.visitor_request.is_empty():
		var visitor := MODELS.person({"gender":"female","outfit":2})
		place(visitor,visitor_world_position(),0.8)
		tag(visitor,"PENGUNJUNG",2.4)

func _draw() -> void:
	pass
