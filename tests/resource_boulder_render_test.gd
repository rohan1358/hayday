extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size = Vector2i(720, 1280)
	var host = load("res://scenes/Main.tscn").instantiate()
	host.game.save_path = "user://resource_boulder_render_test.json"
	host.game.backup_path = "user://resource_boulder_render_backup.json"
	var original := ProjectSettings.globalize_path("user://kebun_ceria_v1.json")
	if FileAccess.file_exists(original):
		DirAccess.copy_absolute(original, ProjectSettings.globalize_path(host.game.save_path))
	root.add_child(host)
	host.set_meta("first_farm_modal", false)
	host.switch_tab("kebun")
	var farm = host.farm
	var layer = farm.hybrid_controller.boulder_layer
	var boulder = host.game.building_upgrades.get("nodes", [])[0]
	var at := Vector2(float(boulder.position[0]), float(boulder.position[1]))
	assert(farm.farm_art.sprites.has("resource_boulder"), "Clean boulder sprite must load")
	assert(farm.farm_art.sprites["resource_boulder"].texture.resource_path.ends_with("resource_boulder_clean.png"))
	for zoom in [0.8, 1.4]:
		farm.camera_zoom = zoom
		farm.zoom_target = zoom
		farm.camera_target = farm.clamp_camera_center(at, zoom)
		farm.camera_center = farm.camera_target
		for frame in 4: await process_frame
		var scaler: Vector2 = farm.size / farm.get_virtual_size()
		var expected: Vector2 = (farm.get_virtual_size() * 0.5 - farm.camera_center * farm.camera_zoom) * scaler
		assert(layer.position.distance_to(expected) < 0.1, "Boulders must track the current camera")
		assert(layer.scale.distance_to(scaler * farm.camera_zoom) < 0.001, "Boulders must track zoom")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/batu-zoom-%s.png" % str(zoom)))
	# A camera drag must update the rocks on every frame, not on a timed redraw.
	var scaler: Vector2 = farm.size / farm.get_virtual_size()
	for step in 8:
		farm.camera_target = farm.clamp_camera_center(at + Vector2(step * 35.0, step * 22.0), farm.camera_zoom)
		await process_frame
		var expected: Vector2 = (farm.get_virtual_size() * 0.5 - farm.camera_center * farm.camera_zoom) * scaler
		assert(layer.position.distance_to(expected) < 0.1, "Boulders must follow every pan frame")
	print("RESOURCE BOULDER RENDER PASS: clean sprite and camera transform")
	host.queue_free()
	await process_frame
	quit()
