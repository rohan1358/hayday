extends SubViewportContainer
const MODELS = preload("res://scripts/models_3d.gd")
var kind := "accessory"
var index := 0
var character_data: Dictionary = {}
var model: Node3D
func _ready() -> void:
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x,160),maxf(custom_minimum_size.y,150))
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(240,200)
	viewport.own_world_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("e8efe2")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.7
	env.environment = settings
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-35,0)
	world.add_child(sun)
	if kind == "outfit":
		character_data["outfit"] = index
	model = MODELS.person(character_data) if kind in ["character","outfit"] else MODELS.prop(kind,index)
	world.add_child(model)
	model.rotation.y = -0.4
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.9 if kind in ["character","outfit","equipment"] else 1.8
	var focus := Vector3(0,1.18,0) if kind in ["character","outfit","equipment"] else Vector3(0,0.2,0)
	camera.position = focus+Vector3(0,1.1,3.4)
	world.add_child(camera)
	camera.look_at(focus)
