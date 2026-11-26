extends SceneTree

const REGIONS = preload("res://scripts/world_regions.gd")

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	for i in 7:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../outputs/" + name + ".png")
	var result := root.get_texture().get_image().save_png(path)
	print("CAPTURE ", name, " status=", result, " path=", path)

func run() -> void:
	root.size = Vector2i(720, 1600)
	var host = load("res://scenes/Main.tscn").instantiate()
	host.game.save_path = "user://late_districts_visual.json"
	host.game.backup_path = "user://late_districts_visual_backup.json"
	DirAccess.remove_absolute(host.game.save_path)
	DirAccess.remove_absolute(host.game.backup_path)
	root.add_child(host)
	host.game.ftue.started = true
	host.game.ftue.step = "done"
	host.game.level = 50
	host.game.coins = 250000
	for id in ["permukiman", "kafe", "stasiun", "sekolah", "resor_danau", "pelabuhan"]:
		var at: Vector2 = REGIONS.DATA[id].position
		var found := false
		for radius in range(0, 9):
			if found: break
			for dy in range(-radius, radius + 1):
				if found: break
				for dx in range(-radius, radius + 1):
					var candidate: Vector2 = at + Vector2(dx,dy) * 80.0
					if host.farm.can_place("region_" + id, candidate):
						at = candidate
						found = true
						break
		if not found:
			push_error("No visual placement for " + id)
			quit(1)
			return
		print("PLACED ", id, " ", at)
		REGIONS.buy(host.game, id, at)
	for node in host.find_children("*", "", true, false):
		if node.name == "NewPlayerWelcome": node.hide()
		if node.get_script() != null and node.get_script().resource_path == "res://scripts/farm_progression.gd":
			node.set_process(false)
			if is_instance_valid(node.dialog): node.dialog.hide()
	host.set_meta("first_farm_modal", false)
	host.switch_tab("kebun")
	host.refresh_all()
	var farm = host.farm
	farm.hybrid_controller.data.follow = false
	farm.set_process(false)
	farm.invalidate_scenery()
	farm.camera_zoom = 0.52
	farm.zoom_target = 0.52
	farm.camera_target = farm.clamp_camera_center(Vector2(5150, 1850), farm.camera_zoom)
	farm.camera_center = farm.camera_target
	farm.queue_redraw()
	await capture("late-districts-world")
	host.set_meta("selected_region", "permukiman")
	host.switch_tab("kawasan")
	await capture("late-districts-menu")
	print("LATE_DISTRICTS_VISUAL_DONE")
	host.queue_free()
	await process_frame
	quit()
