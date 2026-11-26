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
	host.game.save_path = "user://reported_visual_bugs.json"
	host.game.backup_path = "user://reported_visual_bugs_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.skip_onboarding()
	host.game.level = 6
	host.game.ftue.started = true
	host.game.ftue.step = "done"
	host.game.ftue.coop_built = true
	host.game.ftue.cow_built = true
	host.game.constructions["kandang_babi"] = 1
	host.game.constructions["kandang_kambing"] = 1
	host.game.constructions["pabrik_pakan"] = 1
	host.farm.hybrid_controller.data.follow = false
	host.farm.hybrid_controller.set_process(false)
	host.switch_tab("kebun")
	for child in host.get_children():
		if child.get_script() == load("res://scripts/farm_progression.gd"):
			child.set_process(false)
			if is_instance_valid(child.dialog): child.dialog.hide()
		if child is CanvasItem and child != host.farm: child.hide()
	host.farm.camera_zoom = 1.0
	host.farm.zoom_target = 1.0
	host.farm.camera_center = Vector2(1150, 650)
	host.farm.camera_target = host.farm.camera_center
	host.farm.invalidate_scenery()
	await capture("bugfix-kandang-dan-langit")
	var crops = ["kedelai", "stroberi", "", "gandum"]
	for i in crops.size():
		host.game.plots[i].unlocked = true
		host.game.plots[i].crop = crops[i]
		host.game.plots[i].planted_at = host.game.now() - 20
		host.game.plots[i].ready_at = host.game.now() - 1
		host.game.layout_positions["petak_%d" % i] = [850 + i * 170, 900]
	preload("res://scripts/building_upgrades.gd").setup_nodes(host.farm.hybrid_controller)
	host.farm.camera_center = Vector2(1100, 900)
	host.farm.camera_target = host.farm.camera_center
	host.farm.invalidate_scenery()
	await capture("bugfix-petak-siap-panen")
	for i in 4:
		host.game.plots[i].crop = "" if i == 0 else "gandum"
		host.game.plots[i].planted_at = host.game.now() - ([0, 0, 7, 20][i])
		host.game.plots[i].ready_at = host.game.now() + ([0, 20, 13, -1][i])
	host.farm.invalidate_scenery()
	await capture("bugfix-petak-tahap-tumbuh")
	assert(host.farm.WILD_TREES.all(func(at): return at.y >= 650.0))
	for id in ["chicken_coop", "cow_pen", "pig_pen", "goat_pen"]:
		host.farm.farm_art.ensure_reference(id)
		assert(host.farm.farm_art.sprites[id].texture.resource_path.begins_with("res://assets/colorful_garden/"))
	print("REPORTED VISUAL BUGS PASS")
	host.queue_free()
	await process_frame
	quit()
