extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/" + name + ".png"))

func run() -> void:
	root.size = Vector2i(720, 1280)
	var host = load("res://scenes/Main.tscn").instantiate()
	host.game.save_path = "user://resource_visual.json"
	host.game.backup_path = "user://resource_visual_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	for child in host.get_children():
		if child.get_script() == load("res://scripts/first_farm_ui.gd"):
			child.opening.hide()
	host.game.skip_onboarding()
	host.game.ftue.started = true
	host.game.ftue.step = "done"
	host.farm.hybrid_controller.data.follow = false
	host.farm.hybrid_controller.set_process(false)
	host.switch_tab("kebun")
	var upgrades = preload("res://scripts/building_upgrades.gd")
	upgrades.setup_nodes(host.farm.hybrid_controller)
	var nodes: Array = upgrades.prepare(host.game).nodes
	assert(not nodes.is_empty())
	var at = Vector2(nodes[0].position[0], nodes[0].position[1])
	host.farm.camera_center = at
	host.farm.camera_target = at
	host.farm.camera_zoom = 1.0
	host.farm.zoom_target = 1.0
	host.farm.invalidate_scenery()
	await capture("resource-boulder-before")
	nodes[0].ready_at = host.game.now() + 90
	host.farm.invalidate_scenery()
	await capture("resource-boulder-after")
	print("RESOURCE VISUAL PASS")
	host.queue_free()
	await process_frame
	quit()
