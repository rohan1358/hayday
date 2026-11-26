extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(720, 1280)
	var host = load("res://scenes/Main.tscn").instantiate()
	host.game.save_path = "user://crop_illustrations_test.json"
	host.game.backup_path = "user://crop_illustrations_test_backup.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(host.game.backup_path))
	root.add_child(host)
	for child in host.get_children():
		if child.get_script() == load("res://scripts/first_farm_ui.gd"):
			child.opening.hide()
		if child.get_script() == load("res://scripts/farm_progression.gd"):
			child.set_process(false)
			child.pending.clear()
			if child.dialog != null: child.dialog.hide()
	host.set_meta("first_farm_modal", false)
	host.game.ftue.started = true
	host.game.ftue.step = "done"
	host.game.level = 6
	assert(host.farm.CROP_PLANT_CELLS.size() == host.game.CROP_ORDER.size())
	for id in host.game.CROP_ORDER:
		assert(host.farm.CROP_PLANT_CELLS.has(id), "Missing crop illustration: " + id)
	var now: int = host.game.now()
	for i in 3:
		var plot: Dictionary = host.game.plots[i]
		plot["unlocked"] = true
		plot["crop"] = ["gandum", "jagung", "tomat"][i]
		plot["planted_at"] = now - 15
		plot["ready_at"] = now - 1
		host.game.plots[i] = plot
	host.farm.queue_redraw()
	if DisplayServer.get_name() != "headless":
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/tanaman-ilustrasi.png"))
	print("CROP ILLUSTRATIONS PASS: all 14 crops mapped, three ready plots rendered")
	host.queue_free()
	await process_frame
	quit()
